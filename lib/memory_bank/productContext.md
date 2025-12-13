# Product Context: Linux Remote Biometric Unlocker

## Problem
Linux users currently lack a convenient, integrated way to unlock their desktops or grant privileged access using a trusted remote device. Typing passwords repeatedly is inefficient and can be a security risk in public spaces. This project addresses the need for a faster, more secure, and seamless authentication experience.

## Solution
The project will consist of two main components:
1.  **A Linux desktop application (Server):** A background service that listens for secure signals on the local network.
2.  **A mobile application (Client):** An app that uses the phone's native biometric capabilities to authenticate the user and sends a secure "unlock" signal to the desktop application.

## User Experience Goals
-   **Seamless:** The unlocking process should be quick and require minimal user interaction on the desktop.
-   **Secure:** Communication between the mobile device and the PC must be encrypted to prevent unauthorized access.
-   **Simple:** The initial setup and pairing process should be straightforward for the user.