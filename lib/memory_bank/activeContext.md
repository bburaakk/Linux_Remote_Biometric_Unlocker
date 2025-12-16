# Active Context

## Current Focus
The project has successfully implemented the core "System Monitor," "Power Management," and "Wake-on-LAN" features. The current focus is on ensuring all features are stable and well-documented.

## Recent Changes
*   **System Monitor UI:** Completely redesigned `SystemMonitorScreen` with a futuristic, neon-themed glassmorphism UI. Used `percent_indicator` for circular stats.
*   **Performance Optimization:** Optimized `_GlassmorphismCard` by removing `BackdropFilter` to fix lag on mobile devices.
*   **GPU Stats Stability:** Refactored `server.py` to initialize NVML (`pynvml`) once at startup (`init_gpu`) instead of per-request, resolving stability issues.
*   **Unlock Reliability:** Added a `wake_screen()` function in `server.py` to force the screen to wake up (using `xset` or `busctl`) before attempting to unlock, solving issues where the PC wouldn't unlock from a suspended/screen-off state.
*   **Power Management:** Added Shutdown, Reboot, and Suspend commands to both the Python server and the Flutter app (with confirmation dialogs).
*   **Theme Consistency:** Updated `main.dart` and other screens to match the new dark/neon theme.
*   **Wake-on-LAN (WoL):** Implemented the ability to wake the computer from a powered-off state. This was done by manually constructing and sending a UDP "magic packet" from the Flutter app, removing the problematic `wake_on_lan` package dependency.
*   **Device Management:** The device management screen (`paired_devices_management_screen.dart`) and the main screen (`biometric_unlock_screen.dart`) were updated to include a field for the device's MAC address, which is required for WoL.

## Active Decisions
*   **Fan Speed:** Due to hardware limitations on laptops (proprietary EC chips), fan speed reading via `lm-sensors` is often unavailable. We decided to keep the logic in `server.py` to attempt reading it but accept "N/A" as a valid state without breaking the UI.
*   **UI Performance:** Prioritized performance over visual fidelity by removing real-time blur effects (`BackdropFilter`) on mobile.
*   **WoL Implementation:** Chose to implement WoL manually using `dart:io`'s `RawDatagramSocket` to avoid external package issues and ensure maximum control and reliability.

## Next Steps
1.  **Refinement:** Potential addition of a "Media Control" section.
2.  **Documentation:** Ensure `README.md` and all files in the `memory_bank` are fully updated to reflect the new WoL feature and its implementation details.
3.  **Testing:** Comprehensive testing of the Wake-on-LAN feature across different network conditions.
