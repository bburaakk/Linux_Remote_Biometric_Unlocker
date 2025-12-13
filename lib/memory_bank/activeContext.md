# Active Context

**Current Focus:** Deploying the Server as a System Service.

The core functionality of the client and server is working correctly. The next step is to ensure the Python server runs persistently in the background on the Linux machine.

**Recent Activities:**
-   Successfully tested the end-to-end unlock functionality.
-   Resolved issues related to Android permissions and Base64 key formatting.

**Next Steps:**
1.  Create a `systemd` service file to manage the Python server script.
2.  Provide instructions on how to enable and start the service.
3.  Explain how to view logs using `journalctl`.
4.  Update the project's `README.md` with setup and usage instructions.