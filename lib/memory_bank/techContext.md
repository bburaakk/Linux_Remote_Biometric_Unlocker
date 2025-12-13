# Tech Context: Linux Remote Biometric Unlocker

## Core Technologies

### Server Side (Linux PC)
-   **Language:** Python 3
-   **System Service:** `systemd` (for background persistence)
-   **Key Libraries:**
    -   `socket`: For TCP network communication.
    -   `subprocess`: To execute system commands (`loginctl`).
    -   `pycryptodome`: For AES (CBC mode) decryption.
    -   `os` & `getpass`: For user and session detection.
-   **System Commands:**
    -   `loginctl list-sessions`: To find the active graphical session.
    -   `loginctl unlock-session [ID]`: To perform the actual unlock.

### Client Side (Mobile App)
-   **Framework:** Flutter (Dart)
-   **Key Packages:**
    -   `local_auth`: For accessing native biometric hardware (Fingerprint/FaceID).
    -   `encrypt`: For AES (CBC mode) encryption.
    -   `dart:io`: For raw Socket communication.
-   **Configuration:**
    -   `AndroidManifest.xml`: Configured with `USE_BIOMETRIC` permission.
    -   `MainActivity.kt`: Updated to extend `FlutterFragmentActivity` for better compatibility.

## Development Environment
-   **IDE:** VS Code / Android Studio (implied).
-   **OS:** Linux (Server), Android (Client).
-   **Network:** Local Wi-Fi network (Client and Server must be on the same subnet).

## Security Architecture
-   **Encryption:** AES-128/192/256 (CBC Mode) with PKCS7 padding.
-   **Key Management:** Hardcoded shared secret (Base64 encoded) for MVP.
-   **IV (Initialization Vector):** Randomly generated 16-byte IV for each message, sent as a prefix to the ciphertext.
