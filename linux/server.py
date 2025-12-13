import socket
import subprocess
import base64
import os
import getpass
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

# --- Configuration ---
HOST = '0.0.0.0'
PORT = 12345
UNLOCK_COMMAND = "unlock"
SECRET_KEY_B64 = 'MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI='
SECRET_KEY = base64.b64decode(SECRET_KEY_B64)
# --- End Configuration ---

def get_active_session_id():
    """Finds the active graphical session ID."""
    try:
        # Try multiple ways to get the username
        try:
            user = os.getlogin()
        except Exception:
            user = getpass.getuser()
            
        print(f"DEBUG: Detected user: '{user}'")
        
        # Command to list sessions
        result = subprocess.run(
            ['loginctl', 'list-sessions', '--no-legend'],
            capture_output=True, text=True, check=True
        )
        
        print(f"DEBUG: loginctl output:\n{result.stdout}")
        
        sessions = result.stdout.strip().split('\n')
        for session in sessions:
            parts = session.split()
            # Log output format varies by distro/version.
            # Your output: "1 1000 burak seat0 890 user tty1 no -"
            # parts[0]=ID, parts[1]=UID, parts[2]=USER
            
            if len(parts) >= 3:
                # Check if the user matches either the 2nd or 3rd column to be safe
                if parts[1] == user or parts[2] == user:
                    # Also check if it's a graphical session (usually has 'seat0' or similar)
                    # In your log: "seat0" is at parts[3]
                    if 'seat' in session or 'tty' in session:
                        session_id = parts[0].strip()
                        print(f"Found session for user '{user}': {session_id}")
                        return session_id
        
        print(f"No suitable session found for user '{user}'.")
        return None
    except Exception as e:
        print(f"Error finding active session: {e}")
        return None

def unlock_session():
    """Finds the active session and unlocks it."""
    session_id = get_active_session_id()
    if not session_id:
        print("DEBUG: Could not determine session ID.")
        return False
        
    try:
        print(f"Attempting to unlock session {session_id}...")
        # Using --no-ask-password to prevent interactive prompts that might block execution
        cmd = ['loginctl', 'unlock-session', session_id]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"Unlock command for session {session_id} executed successfully.")
            return True
        else:
            print(f"Unlock command failed with code {result.returncode}.")
            print(f"Stderr: {result.stderr}")
            print(f"Stdout: {result.stdout}")
            return False
            
    except FileNotFoundError:
        print("Error: 'loginctl' command not found.")
        return False
    except Exception as e:
        print(f"Error executing unlock command: {e}")
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
    print("--- Linux Remote Unlock Server (AES) - DEBUG MODE ---")
    print(f"Starting server on {HOST}:{PORT}")
    
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen()
        print("Server is listening for connections...")
        
        while True:
            conn, addr = s.accept()
            with conn:
                print(f"\nConnected by {addr}")
                try:
                    data = conn.recv(1024)
                    if not data:
                        continue

                    print(f"Received {len(data)} bytes.")
                    message = decrypt_message(data)
                    
                    if message:
                        print(f"Decrypted message: '{message}'")
                        if message == UNLOCK_COMMAND:
                            if unlock_session():
                                conn.sendall(b"Unlock command successful")
                            else:
                                conn.sendall(b"Unlock command failed")
                        else:
                            conn.sendall(b"Unknown command")
                    else:
                        print("Failed to decrypt message.")
                        conn.sendall(b"Error: Decryption failed")
                
                except Exception as e:
                    print(f"Error with {addr}: {e}")

if __name__ == '__main__':
    main()
