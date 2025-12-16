# Technical Context

This document outlines the key technologies, libraries, and architectural patterns used in the Linux Remote Biometric Unlocker project.

## Mobile (Flutter)

*   **Framework:** Flutter
*   **Language:** Dart
*   **State Management:** `StatefulWidget` with `setState`.
*   **Key Packages:**
    *   `local_auth`: For accessing native biometric sensors.
    *   `encrypt`: Handles AES encryption/decryption.
    *   `shared_preferences`: Persists the list of paired devices.
    *   `google_fonts`: For custom typography (`Inter`, `JetBrains Mono`).
    *   `intl`: For formatting timestamps in the connection log.
    *   `percent_indicator`: **(New)** Used for the circular and linear progress bars in the System Monitor UI.

## Desktop (Python Server)

*   **Language:** Python 3
*   **Communication:** Standard TCP socket server.
*   **Key Libraries:**
    *   `pycryptodome`: The underlying library for AES encryption/decryption.
    *   `psutil`: A cross-platform library for retrieving system utilization (CPU, memory, disks, fans).
    *   `pynvml`: Python bindings to the NVIDIA Management Library (NVML) for real-time GPU stats.

## Communication Protocol

*   **Transport:** 
    *   Raw TCP Sockets for commands.
    *   Raw UDP Sockets for Wake-on-LAN.
*   **Security:** End-to-end encryption using **AES-256 in CBC mode** with per-device secret keys for TCP commands.
*   **Commands:**
    *   `unlock`: Unlocks the Linux session.
    *   `get_stats`: Returns a JSON object with system hardware statistics.
    *   `shutdown`: Executes `systemctl poweroff`.
    *   `reboot`: Executes `systemctl reboot`.
    *   `suspend`: Executes `systemctl suspend`.
*   **Wake-on-LAN (WoL):**
    *   The Flutter app constructs a "magic packet" manually.
    *   The packet consists of 6 bytes of `0xFF` followed by 16 repetitions of the target device's MAC address.
    *   This packet is sent via a UDP broadcast using `dart:io`'s `RawDatagramSocket` to port 9.

## Key Implementation Details

*   **GPU Initialization:** `pynvml` is initialized only once when the server starts (`init_gpu`) to ensure stability and prevent repeated init/shutdown calls.
*   **Screen Wake-Up:** Before sending the `loginctl unlock-session` command, the server attempts to wake the display using `xset` (for X11) and `busctl` (for Wayland) to handle cases where the screen is off.
*   **UI Performance:** The "glassmorphism" effect is achieved using semi-transparent solid colors instead of a `BackdropFilter` to ensure smooth performance on mobile devices.
*   **WoL Implementation:** The `wake_on_lan` package was removed due to compilation issues. WoL functionality is now implemented by manually creating and sending the magic packet, providing a more robust and dependency-free solution.
