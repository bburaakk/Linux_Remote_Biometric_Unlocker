# System Patterns: Linux Remote Biometric Unlocker

## Architecture: Client-Server Model

The system follows a simple client-server architecture operating on a local network.

-   **Server (Linux PC):** A Python script will run as a background service. It will open a TCP socket and listen for incoming connections from the client.
-   **Client (Mobile App):** A Flutter application will initiate a connection to the server's IP address and port.

## Communication Flow (MVP)

1.  **Discovery/Pairing (Manual):** For the MVP, the user will manually enter the PC's local IP address into the mobile app.
2.  **Authentication Request:**
    -   The user opens the mobile app.
    -   The app prompts for biometric authentication (fingerprint/FaceID) using the `local_auth` package.
3.  **Secure Signal:**
    -   Upon successful biometric authentication, the mobile app sends a pre-defined, encrypted "unlock" payload to the PC over the local network.
4.  **Server Action:**
    -   The Python server receives the payload.
    -   It decrypts and verifies the payload.
    -   If the payload is valid, the server executes a command to unlock the Linux session (e.g., using `loginctl unlock-session` or by interacting with the PAM system).

## Security Pattern
-   **Encryption:** A shared secret (pre-configured during setup) will be used to encrypt and decrypt the messages between the client and server to ensure that only the trusted device can issue the unlock command.