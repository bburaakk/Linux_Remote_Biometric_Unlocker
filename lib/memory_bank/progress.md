# Project Progress

## Phase 1: Core Functionality (Completed)
- [x] **Basic Unlock:** Implement core biometric unlock functionality.
- [x] **Secure Communication:** Encrypt communication with AES.
- [x] **Multi-Device Management:** Add support for managing multiple devices.
- [x] **Persistent Storage:** Save device list using `shared_preferences`.
- [x] **Dynamic Security:** Implement per-device secret keys.

## Phase 2: System Monitor & UI Overhaul (Completed)
- [x] **System Stats (Server):** Python server can gather CPU, RAM, Disk, and GPU stats.
- [x] **System Monitor UI (Flutter):** Create a new screen to display system stats.
- [x] **UI Redesign:** Overhaul the entire app theme to a modern, dark/neon "glassmorphism" style.
- [x] **Performance Optimization:** Fix UI lag by optimizing the glass effect.
- [x] **GPU Stats Fix:** Stabilize NVIDIA GPU data retrieval.

## Phase 3: Feature Expansion (Current)
- [x] **Power Management:** Implement Shutdown, Reboot, and Suspend controls.
- [x] **Unlock Reliability:** Implement a `wake_screen` function to improve unlocking from a screen-off state.
- [ ] **Media Controls:** Add remote controls for media playback (Play/Pause, Volume).
- [ ] **Wake-on-LAN (WoL):** Add the ability to wake the computer from a powered-off state.
- [ ] **Application Launcher:** Add buttons to launch common applications remotely.

## Backlog / Future Ideas
- [ ] **QR Code Pairing:** Simplify device setup by scanning a QR code.
- [ ] **Touchpad/Mouse Control:** Use the phone screen as a remote touchpad.
- [ ] **Terminal Access:** A simple remote terminal interface.
- [ ] **File Transfer:** Basic file transfer between phone and PC.
- [ ] **Home Screen Widgets:** Add a widget to the phone's home screen for quick actions.
