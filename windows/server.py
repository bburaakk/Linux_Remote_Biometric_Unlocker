import socket
import subprocess
import base64
import os
import json
import traceback
import ctypes
import time
from Cryptodome.Cipher import AES
from Cryptodome.Util.Padding import unpad

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

# Generated Key (Must match the Flutter app)
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
            # Windows usually requires 'OpenHardwareMonitor' or WMI for temps, 
            # psutil often doesn't show temps on Windows directly without help.
            # We will leave it as N/A or try to fetch if available.
            if hasattr(psutil, 'sensors_temperatures'):
                try:
                    temps = psutil.sensors_temperatures()
                    if 'coretemp' in temps:
                        stats['cpu']['temp'] = temps['coretemp'][0].current
                except:
                    pass

        # --- RAM ---
        if psutil:
            ram = psutil.virtual_memory()
            stats['ram']['usage'] = ram.percent
            stats['ram']['total'] = round(ram.total / (1024**3), 2)

        # --- Disk ---
        if psutil:
            disk = psutil.disk_usage('C:\\') # Usually C: on Windows
            stats['disk']['usage'] = disk.percent
            stats['disk']['total'] = round(disk.total / (1024**3), 2)

        # --- GPU (NVIDIA) ---
        if nvml_handle:
            try:
                name_raw = pynvml.nvmlDeviceGetName(nvml_handle)
                if isinstance(name_raw, bytes):
                    stats['gpu']['name'] = name_raw.decode('utf-8')
                else:
                    stats['gpu']['name'] = str(name_raw)
                    
                util = pynvml.nvmlDeviceGetUtilizationRates(nvml_handle)
                stats['gpu']['usage'] = util.gpu
                stats['gpu']['temp'] = pynvml.nvmlDeviceGetTemperature(nvml_handle, pynvml.NVML_TEMPERATURE_GPU)
                
                try:
                    stats['gpu']['fan_speed'] = pynvml.nvmlDeviceGetFanSpeed(nvml_handle)
                except:
                    stats['gpu']['fan_speed'] = 'N/A'

            except Exception as e:
                print(f"GPU Error: {e}")
                init_gpu()

    except Exception as e:
        print(f"Error gathering stats: {e}")
        
    return stats

def wake_screen():
    """Wakes up the screen by simulating a mouse movement."""
    try:
        # Move mouse slightly to wake screen
        ctypes.windll.user32.mouse_event(0x0001, 1, 1, 0, 0)
        time.sleep(0.1)
        ctypes.windll.user32.mouse_event(0x0001, -1, -1, 0, 0)
        print("Screen wake signal sent.")
    except Exception as e:
        print(f"Error waking screen: {e}")

def unlock_session():
    """
    On Windows, programmatically unlocking (typing password) is restricted for security.
    This function will WAKE the screen.
    To actually unlock, you would need to simulate keystrokes which is complex/insecure here.
    For now, we treat 'unlock' as 'Wake Monitor'.
    """
    print("Received Unlock Request - Waking Screen...")
    wake_screen()
    return True

def execute_power_command(command):
    """Executes system power commands for Windows."""
    try:
        if command == SHUTDOWN_COMMAND:
            print("Executing Shutdown...")
            os.system("shutdown /s /t 0")
        elif command == REBOOT_COMMAND:
            print("Executing Reboot...")
            os.system("shutdown /r /t 0")
        elif command == SUSPEND_COMMAND:
            print("Executing Suspend...")
            # Hibernate/Sleep requires admin or specific config, trying standard call
            os.system("rundll32.exe powrprof.dll,SetSuspendState 0,1,0")
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
    print("--- Windows Remote Control Server ---")
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
                            if unlock_session():
                                conn.sendall(b"Unlock command successful")
                            else:
                                conn.sendall(b"Unlock command failed")
                        
                        elif message == GET_STATS_COMMAND:
                            try:
                                stats = get_system_stats()
                                response = json.dumps(stats).encode('utf-8')
                                conn.sendall(response)
                            except Exception as e:
                                print(f"Error sending stats: {e}")
                                conn.sendall(b"Error: Could not gather stats")
                        
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
                    print(f"Connection Error: {e}")

if __name__ == '__main__':
    main()
