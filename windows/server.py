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
    psutil = None

try:
    import pynvml
except ImportError:
    print("Warning: 'pynvml' library not found. NVIDIA GPU stats will be unavailable.")
    pynvml = None

try:
    import wmi
except ImportError:
    # print("Warning: 'wmi' library not found. CPU temp might be unavailable on Windows.")
    wmi = None

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
wmi_obj = None

def init_hardware():
    """Initializes hardware monitors."""
    global nvml_handle, wmi_obj
    
    # Init NVIDIA GPU
    if pynvml:
        try:
            pynvml.nvmlInit()
            nvml_handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            print("NVML Initialized successfully.")
        except Exception as e:
            print(f"NVML Init Failed: {e}")
            nvml_handle = None

    # Init WMI for Windows CPU Temp
    if wmi:
        try:
            wmi_obj = wmi.WMI(namespace="root\\wmi")
        except Exception:
            wmi_obj = None

def get_cpu_temp_windows():
    """Attempts to get CPU temperature on Windows using WMI."""
    if not wmi_obj:
        return 'N/A'
    try:
        temperature_info = wmi_obj.MSAcpi_ThermalZoneTemperature()
        if temperature_info:
            # Kelvin to Celsius: (K - 273.2)
            temp_kelvin = temperature_info[0].CurrentTemperature
            temp_celsius = (temp_kelvin / 10.0) - 273.15
            return round(temp_celsius, 1)
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
            stats['cpu']['temp'] = get_cpu_temp_windows()

        # --- RAM ---
        if psutil:
            ram = psutil.virtual_memory()
            stats['ram']['usage'] = ram.percent
            stats['ram']['total'] = round(ram.total / (1024**3), 2)

        # --- Disk ---
        if psutil:
            try:
                disk = psutil.disk_usage('C:\\')
                stats['disk']['usage'] = disk.percent
                stats['disk']['total'] = round(disk.total / (1024**3), 2)
            except:
                pass

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
                    # Try to get fan speed in %
                    speed = pynvml.nvmlDeviceGetFanSpeed(nvml_handle)
                    stats['gpu']['fan_speed'] = f"{speed}%"
                except:
                    stats['gpu']['fan_speed'] = 'N/A'

            except Exception as e:
                print(f"GPU Error: {e}")
                # Re-init might be needed if driver crashed
                pass

    except Exception as e:
        print(f"Error gathering stats: {e}")
        
    return stats

def wake_screen():
    """Wakes up the screen."""
    try:
        ctypes.windll.user32.mouse_event(0x0001, 1, 1, 0, 0)
        time.sleep(0.1)
        ctypes.windll.user32.mouse_event(0x0001, -1, -1, 0, 0)
    except:
        pass

def unlock_session():
    print("Received Unlock Request - Waking Screen...")
    wake_screen()
    return True

def execute_power_command(command):
    try:
        if command == SHUTDOWN_COMMAND:
            os.system("shutdown /s /t 0")
        elif command == REBOOT_COMMAND:
            os.system("shutdown /r /t 0")
        elif command == SUSPEND_COMMAND:
            os.system("rundll32.exe powrprof.dll,SetSuspendState 0,1,0")
        return True
    except:
        return False

def decrypt_message(encrypted_data):
    try:
        iv = encrypted_data[:16]
        ciphertext = encrypted_data[16:]
        cipher = AES.new(SECRET_KEY, AES.MODE_CBC, iv)
        decrypted_padded = cipher.decrypt(ciphertext)
        decrypted = unpad(decrypted_padded, AES.block_size)
        return decrypted.decode('utf-8')
    except:
        return None

def main():
    print("--- Windows Remote Control Server ---")
    print(f"Starting server on {HOST}:{PORT}")
    
    init_hardware()
    
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
                            unlock_session()
                            conn.sendall(b"Unlock command successful")
                        elif message == GET_STATS_COMMAND:
                            stats = get_system_stats()
                            conn.sendall(json.dumps(stats).encode('utf-8'))
                        elif message in [SHUTDOWN_COMMAND, REBOOT_COMMAND, SUSPEND_COMMAND]:
                            execute_power_command(message)
                            conn.sendall(f"Command {message} executed".encode('utf-8'))
                        else:
                            conn.sendall(b"Unknown command")
                    else:
                        conn.sendall(b"Error: Decryption failed")
                except Exception as e:
                    print(f"Connection Error: {e}")

if __name__ == '__main__':
    main()
