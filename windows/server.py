import socket
import subprocess
import base64
import os
import getpass
import json
import traceback
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

# --- System Stats Libraries ---
try:
    import psutil
except ImportError:
    print("Warning: 'psutil' library not found. System stats will be unavailable.")
    print("Install it using: pip install psutil")
    psutil = None

try:
    import pynvml
except ImportError:
    print("Warning: 'pynvml' library not found. NVIDIA GPU stats will be unavailable.")
    print("Install it using: pip install pynvml")
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

# IMPORTANT: This key must match the one in your mobile app
SECRET_KEY_B64 = 'S3J5cHRvR2VuZXJhdGVkS2V5MTIzNDU2Nzg5MDEyMzQ=' 
SECRET_KEY = base64.b64decode(SECRET_KEY_B64)
# --- End Configuration ---

# Global NVML Handle
nvml_handle = None

def init_gpu():
    """Initializes NVML once at startup."""
    global nvml_handle
    if pynvml:
        try:
            pynvml.nvmlInit()
            nvml_handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            print("NVML Initialized successfully.")
        except pynvml.NVMLError as e:
            print(f"Failed to initialize NVML: {e}")
            nvml_handle = None

def get_system_stats():
    """Gathers CPU, GPU, RAM, and Disk statistics for Windows."""
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
            # CPU temp on Windows is not standardized via psutil

        # --- RAM ---
        if psutil:
            ram = psutil.virtual_memory()
            stats['ram']['usage'] = ram.percent
            stats['ram']['total'] = round(ram.total / (1024**3), 2)

        # --- Disk ---
        if psutil:
            disk = psutil.disk_usage('C:\\')
            stats['disk']['usage'] = disk.percent
            stats['disk']['total'] = round(disk.total / (1024**3), 2)

        # --- GPU (NVIDIA) ---
        if nvml_handle:
            try:
                name_raw = pynvml.nvmlDeviceGetName(nvml_handle)
                stats['gpu']['name'] = name_raw.decode('utf-8') if isinstance(name_raw, bytes) else str(name_raw)
                util = pynvml.nvmlDeviceGetUtilizationRates(nvml_handle)
                stats['gpu']['usage'] = util.gpu
                stats['gpu']['temp'] = pynvml.nvmlDeviceGetTemperature(nvml_handle, pynvml.NVML_TEMPERATURE_GPU)
                try:
                    stats['gpu']['fan_speed'] = pynvml.nvmlDeviceGetFanSpeed(nvml_handle)
                except pynvml.NVMLError:
                    stats['gpu']['fan_speed'] = 'N/A'

            except pynvml.NVMLError as e:
                print(f"NVML Runtime Error: {e}")
                init_gpu() # Try to re-init
            except Exception as e:
                print(f"GPU General Error: {e}")
                traceback.print_exc()

    except Exception as e:
        print(f"Error gathering stats: {e}")
        traceback.print_exc()
        
    return stats

def unlock_session():
    """Unlocking is not supported on Windows via simple commands."""
    print("Unlock command received, but it's not supported on Windows.")
    return False

def execute_power_command(command):
    """Executes system power commands on Windows."""
    try:
        if command == SHUTDOWN_COMMAND:
            print("Executing Shutdown...")
            subprocess.run(['shutdown', '/s', '/t', '0'], check=True)
        elif command == REBOOT_COMMAND:
            print("Executing Reboot...")
            subprocess.run(['shutdown', '/r', '/t', '0'], check=True)
        elif command == SUSPEND_COMMAND:
            print("Executing Suspend...")
            # Using rundll32 for suspend/sleep
            subprocess.run(['rundll32.exe', 'powrprof.dll,SetSuspendState', '0,1,0'], check=True)
        return True
    except Exception as e:
        print(f"Error executing power command '{command}': {e}")
        return False

def decrypt_message(encrypted_data):
    """Decrypts the message using AES (CBC mode)."""
    try:
        iv = encrypted_data[:16]
        ciphertext = encrypted_data[16:]
        cipher = AES.new(SECRET_KEY, AES.MODE_CBC, iv)
        decrypted_padded = cipher.decrypt(ciphertext)
        decrypted = unpad(decrypted_padded, AES.block_size)
        return decrypted.decode('utf-8')
    except Exception as e:
        print(f"Decryption error: {e}")
        return None

def main():
    """Starts the socket server."""
    print("--- Windows Remote Control & Stats Server ---")
    print(f"Starting server on {HOST}:{PORT}")
    
    init_gpu()
    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen()
        print("Server is listening for connections...")
        
        while True:
            conn, addr = s.accept()
            with conn:
                try:
                    data = conn.recv(1024)
                    if not data:
                        continue

                    message = decrypt_message(data)
                    
                    if message:
                        if message == UNLOCK_COMMAND:
                            conn.sendall(b"Unlock not supported on Windows")
                        
                        elif message == GET_STATS_COMMAND:
                            stats = get_system_stats()
                            response = json.dumps(stats).encode('utf-8')
                            conn.sendall(response)
                        
                        elif message in [SHUTDOWN_COMMAND, REBOOT_COMMAND, SUSPEND_COMMAND]:
                            if execute_power_command(message):
                                conn.sendall(f"Command {message} executed".encode('utf-8'))
                            else:
                                conn.sendall(f"Command {message} failed".encode('utf-8'))
                            
                        else:
                            conn.sendall(b"Unknown command")
                    else:
                        conn.sendall(b"Error: Decryption failed")
                
                except Exception as e:
                    print(f"Connection Error with {addr}: {e}")
                    traceback.print_exc()

if __name__ == '__main__':
    main()
