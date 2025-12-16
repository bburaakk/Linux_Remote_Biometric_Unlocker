import socket
import subprocess
import base64
import os
import getpass
import json
import traceback
import sys
import binascii
import re

# --- Fix Environment for Background Service ---
os.environ["PATH"] += os.pathsep + "/usr/local/bin" + os.pathsep + "/usr/bin" + os.pathsep + "/bin" + os.pathsep + "/usr/sbin" + os.pathsep + "/sbin"

# Force unbuffered stdout/stderr
sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

def log(message):
    """Helper to print and flush immediately."""
    print(message, flush=True)

try:
    from Cryptodome.Cipher import AES
    from Cryptodome.Util.Padding import unpad
except ImportError:
    try:
        from Crypto.Cipher import AES
        from Crypto.Util.Padding import unpad
    except ImportError:
        log("Error: Neither Cryptodome nor Crypto module found.")
        sys.exit(1)

# --- System Stats Libraries ---
try:
    import psutil
except ImportError:
    log("Warning: 'psutil' library not found. System stats will be unavailable.")
    psutil = None

try:
    import pynvml
except ImportError:
    log("Warning: 'pynvml' library not found. NVIDIA GPU stats will be unavailable.")
    pynvml = None

# --- Configuration ---
HOST = '0.0.0.0'
PORT = 12345
# Commands
UNLOCK_COMMAND = "unlock"
GET_STATS_COMMAND = "get_stats"
SHUTDOWN_COMMAND = "shutdown"
REBOOT_COMMAND = "reboot"
SUSPEND_COMMAND = "suspend"

# Generated Key (Must match the Flutter app)
SECRET_KEY_B64 = 'S3J5cHRvR2VuZXJhdGVkS2V5MTIzNDU2Nzg5MDEyMzQ=' 
SECRET_KEY = base64.b64decode(SECRET_KEY_B64)
# --- End Configuration ---

# Global NVML Handle
nvml_handle = None

# Full paths for commands
CMD_NVIDIA_SMI = "/usr/bin/nvidia-smi"
CMD_SENSORS = "/usr/bin/sensors"
CMD_LOGINCTL = "/usr/bin/loginctl"
CMD_SYSTEMCTL = "/usr/bin/systemctl"

def init_gpu():
    """Initializes NVML once at startup."""
    global nvml_handle
    if pynvml:
        try:
            pynvml.nvmlInit()
            device_count = pynvml.nvmlDeviceGetCount()
            log(f"NVML Initialized. Found {device_count} devices.")
            if device_count > 0:
                nvml_handle = pynvml.nvmlDeviceGetHandleByIndex(0)
                log(f"Using GPU 0: {pynvml.nvmlDeviceGetName(nvml_handle)}")
        except pynvml.NVMLError as e:
            log(f"Failed to initialize NVML: {e}")
            nvml_handle = None

def get_gpu_stats_fallback():
    """Fallback method using nvidia-smi command directly."""
    stats = {'usage': 0, 'temp': 'N/A', 'fan_speed': 'N/A', 'name': 'NVIDIA GPU (CMD)'}
    try:
        cmd = CMD_NVIDIA_SMI if os.path.exists(CMD_NVIDIA_SMI) else "nvidia-smi"
        result = subprocess.run(
            [cmd, '--query-gpu=utilization.gpu,temperature.gpu,name', '--format=csv,noheader,nounits'],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            output = result.stdout.strip().split(',')
            if len(output) >= 3:
                stats['usage'] = int(output[0].strip())
                stats['temp'] = int(output[1].strip())
                stats['name'] = output[2].strip()
    except Exception as e:
        log(f"Fallback GPU stats failed: {e}")
    return stats

def get_fan_speed_linux():
    """Tries to get fan speed from lm-sensors."""
    try:
        cmd = CMD_SENSORS if os.path.exists(CMD_SENSORS) else "sensors"
        result = subprocess.run([cmd], capture_output=True, text=True)
        if result.returncode != 0:
            return 'N/A'
            
        for line in result.stdout.split('\n'):
            if 'fan' in line.lower() and 'RPM' in line:
                parts = line.split()
                for i, part in enumerate(parts):
                    if part == 'RPM' and i > 0:
                        return f"{parts[i-1]} RPM"
    except Exception:
        pass
    return 'N/A'

def get_system_stats():
    """Gathers CPU, GPU, RAM, and Disk statistics."""
    stats = {
        'cpu': {'usage': 0, 'temp': 'N/A'},
        'gpu': {'usage': 0, 'temp': 'N/A', 'fan_speed': 'N/A', 'name': 'N/A'},
        'ram': {'usage': 0, 'total': 0},
        'disk': {'usage': 0, 'total': 0}
    }

    try:
        # --- CPU ---
        if psutil:
            stats['cpu']['usage'] = psutil.cpu_percent(interval=None)
            if hasattr(psutil, 'sensors_temperatures'):
                try:
                    temps = psutil.sensors_temperatures()
                    for name in ['coretemp', 'k10temp', 'zenpower', 'acpitz']:
                        if name in temps:
                            stats['cpu']['temp'] = temps[name][0].current
                            break
                except Exception:
                    pass

        # --- RAM ---
        if psutil:
            ram = psutil.virtual_memory()
            stats['ram']['usage'] = ram.percent
            stats['ram']['total'] = round(ram.total / (1024**3), 2)

        # --- Disk ---
        if psutil:
            disk = psutil.disk_usage('/')
            stats['disk']['usage'] = disk.percent
            stats['disk']['total'] = round(disk.total / (1024**3), 2)

        # --- GPU (NVIDIA) ---
        gpu_data_found = False
        
        if nvml_handle:
            try:
                name_raw = pynvml.nvmlDeviceGetName(nvml_handle)
                stats['gpu']['name'] = name_raw.decode('utf-8') if isinstance(name_raw, bytes) else str(name_raw)
                util = pynvml.nvmlDeviceGetUtilizationRates(nvml_handle)
                stats['gpu']['usage'] = util.gpu
                stats['gpu']['temp'] = pynvml.nvmlDeviceGetTemperature(nvml_handle, pynvml.NVML_TEMPERATURE_GPU)
                gpu_data_found = True
            except Exception as e:
                log(f"NVML Error during stats: {e}")

        if not gpu_data_found:
            fallback_stats = get_gpu_stats_fallback()
            if fallback_stats['usage'] != 0 or fallback_stats['temp'] != 'N/A':
                stats['gpu'] = fallback_stats
                gpu_data_found = True

        stats['gpu']['fan_speed'] = get_fan_speed_linux()

    except Exception as e:
        log(f"Error gathering stats: {e}")
        traceback.print_exc()
        
    return stats

def get_active_session_id():
    """Finds the active graphical session ID."""
    try:
        user = getpass.getuser()
        cmd = CMD_LOGINCTL if os.path.exists(CMD_LOGINCTL) else "loginctl"
        log(f"Searching session for user: {user} using {cmd}")
        
        result = subprocess.run([cmd, 'list-sessions', '--no-legend'], capture_output=True, text=True)
        if result.returncode == 0:
            for session in result.stdout.strip().split('\n'):
                log(f"Checking session: {session}")
                parts = session.split()
                if len(parts) >= 3 and parts[2] == user:
                    return parts[0].strip()
        else:
            log(f"loginctl failed: {result.stderr}")
    except Exception as e:
        log(f"Error finding session: {e}")
    return None

def unlock_session():
    """Finds the active session and unlocks it."""
    log("Attempting to unlock session...")
    session_id = get_active_session_id()
    
    if not session_id:
        log("No active session found to unlock.")
        return False
        
    log(f"Found session ID: {session_id}. Sending unlock command...")
    try:
        cmd = CMD_LOGINCTL if os.path.exists(CMD_LOGINCTL) else "loginctl"
        
        result = subprocess.run([cmd, 'unlock-session', session_id], capture_output=True, text=True)
        
        if result.returncode == 0:
            log("Unlock command executed successfully.")
            return True
        else:
            log(f"Unlock command failed with code {result.returncode}: {result.stderr}")
            log("Trying fallback: unlock-sessions (all)...")
            subprocess.run([cmd, 'unlock-sessions'], capture_output=True, text=True)
            return True
            
    except Exception as e:
        log(f"Unlock exception: {e}")
        return False

def execute_power_command(command):
    """Executes system power commands."""
    try:
        cmd = CMD_SYSTEMCTL if os.path.exists(CMD_SYSTEMCTL) else "systemctl"
        log(f"Executing power command: {command}")
        if command == SHUTDOWN_COMMAND:
            subprocess.run([cmd, 'poweroff'], check=True)
        elif command == REBOOT_COMMAND:
            subprocess.run([cmd, 'reboot'], check=True)
        elif command == SUSPEND_COMMAND:
            subprocess.run([cmd, 'suspend'], check=True)
        return True
    except Exception as e:
        log(f"Power command failed: {e}")
        return False

def decrypt_message(encrypted_data):
    """Decrypts the message using AES (CBC mode) with aggressive cleaning."""
    try:
        log(f"Received data length: {len(encrypted_data)}")
        
        iv = encrypted_data[:16]
        ciphertext = encrypted_data[16:]
        cipher = AES.new(SECRET_KEY, AES.MODE_CBC, iv)
        decrypted_padded = cipher.decrypt(ciphertext)
        
        try:
            # Try standard unpad
            decrypted = unpad(decrypted_padded, AES.block_size)
            return decrypted.decode('utf-8')
        except ValueError:
            # If padding fails, try aggressive cleaning
            log("Padding error, attempting aggressive clean...")
            decoded = decrypted_padded.decode('utf-8', errors='ignore')
            
            # Keep only alphanumeric characters and underscores
            cleaned = re.sub(r'[^a-zA-Z0-9_]', '', decoded)
            log(f"Cleaned message: '{cleaned}'")
            return cleaned

    except Exception as e:
        log(f"Decryption Exception: {e}")
        return None

def main():
    """Starts the socket server."""
    log("--- Linux Remote Control Server (Debug Mode) ---")
    log(f"Starting server on {HOST}:{PORT}")
    
    init_gpu()
    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen()
        log("Server is listening for connections...")
        
        while True:
            conn, addr = s.accept()
            with conn:
                try:
                    data = conn.recv(4096)
                    if not data:
                        continue
                    
                    message = decrypt_message(data)
                    
                    if message:
                        log(f"Received command: {message}")
                        
                        # Check for exact match OR if the command is contained in the message
                        if message == UNLOCK_COMMAND or UNLOCK_COMMAND in message:
                            if unlock_session():
                                conn.sendall(b"Unlock command successful")
                            else:
                                conn.sendall(b"Unlock command failed")
                        elif message == GET_STATS_COMMAND or GET_STATS_COMMAND in message:
                            stats = get_system_stats()
                            conn.sendall(json.dumps(stats).encode('utf-8'))
                        elif message in [SHUTDOWN_COMMAND, REBOOT_COMMAND, SUSPEND_COMMAND]:
                            execute_power_command(message)
                            conn.sendall(f"Command {message} executed".encode('utf-8'))
                        else:
                            conn.sendall(b"Unknown command")
                    else:
                        log("Error: Decryption failed (Invalid key or corrupted data)")
                        conn.sendall(b"Error: Decryption failed")
                except Exception as e:
                    log(f"Connection Error: {e}")

if __name__ == '__main__':
    main()
