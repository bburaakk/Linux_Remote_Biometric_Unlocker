# System Design Patterns

This document describes the high-level architectural patterns and data flow within the application.

## 1. Client-Server Architecture (Local Network)

The entire system operates on a classic client-server model confined to the user's local network.

*   **Client:** The Flutter mobile application. It initiates all requests.
*   **Server:** The Python script running on the Linux machine. It listens for commands and responds.

This pattern ensures that no data leaves the local network, which is a core security and privacy feature.

## 2. Secure Command Dispatcher

The primary interaction model is a secure command-response pattern.

1.  **Action:** The user performs an action in the mobile app (e.g., taps "Unlock", "Shutdown", or requests stats).
2.  **Encryption:** The app constructs a simple command string (e.g., `"unlock"`, `"shutdown"`, `"get_stats"`). This string is then encrypted using AES with the specific Secret Key stored for the target device.
3.  **Transmission:** The encrypted payload is sent over a TCP socket to the server's IP and port.
4.  **Decryption & Execution:** The server receives the payload, decrypts it, and validates the command.
5.  **Execution:** The server executes the corresponding local action (e.g., runs `loginctl`, `systemctl`, or gathers system stats).
6.  **Response:** The server sends a response back to the client (e.g., a simple confirmation string or a JSON object with data).

## 3. Per-Device Configuration Persistence

The app manages multiple servers by storing a unique configuration for each.

*   **Storage:** `shared_preferences` is used as a simple key-value store.
*   **Data Structure:** A list of device `Map` objects is serialized into a JSON string and stored under a single key (`'devices'`).
*   **Data Points per Device:** Each device map contains its `name`, `ip`, and unique `secretKey`.

## 4. UI/UX Patterns

*   **Optimized Glassmorphism:** The UI uses a "glassmorphism" style, but for performance reasons, it avoids real-time blurring (`BackdropFilter`). Instead, it uses semi-transparent solid colors (`Color.fromRGBO`) to achieve a similar aesthetic without the high GPU cost on mobile devices.
*   **Stateful Data Polling:** The `SystemMonitorScreen` uses a `Timer.periodic` to poll the server for new data at a fixed interval (e.g., every 1 second). The UI is updated via `setState`, which is efficient for this number of data points.

## 5. Server-Side Resource Management

*   **Singleton Initialization:** To avoid performance issues and instability with external libraries, resources are initialized only once. For example, `pynvml` (the NVIDIA library) is initialized once when the server starts and its handle is reused for all subsequent requests, rather than being initialized and shut down on every call.
