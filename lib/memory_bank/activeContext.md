# Active Context

## Current Focus
The project has successfully implemented the core "System Monitor" and "Power Management" features. The current focus is on stabilizing these features, ensuring cross-platform compatibility (specifically GPU stats on Linux), and refining the UI/UX with a modern "Glassmorphism" design.

## Recent Changes
*   **System Monitor UI:** Completely redesigned `SystemMonitorScreen` with a futuristic, neon-themed glassmorphism UI. Used `percent_indicator` for circular stats.
*   **Performance Optimization:** Optimized `_GlassmorphismCard` by removing `BackdropFilter` to fix lag on mobile devices.
*   **GPU Stats Stability:** Refactored `server.py` to initialize NVML (`pynvml`) once at startup (`init_gpu`) instead of per-request, resolving stability issues.
*   **Unlock Reliability:** Added a `wake_screen()` function in `server.py` to force the screen to wake up (using `xset` or `busctl`) before attempting to unlock, solving issues where the PC wouldn't unlock from a suspended/screen-off state.
*   **Power Management:** Added Shutdown, Reboot, and Suspend commands to both the Python server and the Flutter app (with confirmation dialogs).
*   **Theme Consistency:** Updated `main.dart` and other screens to match the new dark/neon theme.

## Active Decisions
*   **Fan Speed:** Due to hardware limitations on laptops (proprietary EC chips), fan speed reading via `lm-sensors` is often unavailable. We decided to keep the logic in `server.py` to attempt reading it but accept "N/A" as a valid state without breaking the UI.
*   **Wake-on-LAN (WoL):** Deferred for now. The current `wake_screen` implementation solves the "unlock from lock screen" issue. True "wake from power off" via WoL is a future enhancement.
*   **UI Performance:** Prioritized performance over visual fidelity by removing real-time blur effects (`BackdropFilter`) on mobile.

## Next Steps
1.  **Testing:** Comprehensive testing of the Power Management features (requires `sudo` or proper permissions on Linux).
2.  **Refinement:** Potential addition of a "Media Control" section.
3.  **Documentation:** Ensure `README.md` reflects all new features and setup requirements (like `pip install psutil pynvml`).
