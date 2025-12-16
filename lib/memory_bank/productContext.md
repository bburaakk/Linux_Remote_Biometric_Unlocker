# Product Context

This document defines the product vision, target audience, and core features of the Linux Remote Biometric Unlocker.

## Vision

To create a fast, secure, and convenient mobile application that acts as a remote companion for a Linux desktop/server. The application should go beyond a single utility and provide a suite of useful remote management and monitoring tools with a polished, modern user interface.

## Target Audience

*   Linux desktop users (developers, power users, enthusiasts).
*   Home server owners who want quick, secure access and monitoring.
*   Users who prioritize security and prefer solutions that do not rely on third-party cloud services.

## Core Features

### Implemented

1.  **Remote Biometric Unlock:**
    *   Securely unlock a Linux session using a smartphone's biometric sensors.
    *   Includes a `wake_screen` function to improve reliability when the screen is off.

2.  **System Hardware Monitor:**
    *   Displays real-time hardware statistics from the remote Linux machine.
    *   **Metrics:** CPU (Usage/Temp), RAM (Usage/Total), Disk (Usage/Total), and NVIDIA GPU (Name/Usage/Temp/Fan).
    *   Features a futuristic, "glassmorphism" UI design.

3.  **Power Management:**
    *   Remote controls to **Shutdown**, **Reboot**, and **Suspend** the Linux machine, with confirmation dialogs.

4.  **Wake-on-LAN (WoL):**
    *   Wake up a sleeping or powered-off computer over the network by sending a "magic packet".
    *   Requires the device's MAC address to be configured in the app.

5.  **Multi-Device Management:**
    *   Add, save, and manage multiple Linux machines.
    *   Device list is persisted locally on the phone.

6.  **Dynamic Security:**
    *   Per-device, user-defined secret keys for AES encryption.

7.  **Connection Logging:**
    *   An in-app log viewer shows the status of connections, authentication, and errors.

### Planned

1.  **Media Controls:**
    *   Remote controls for media playback (Play/Pause, Volume).

2.  **Application Launcher:**
    *   Add buttons to launch common applications remotely.
