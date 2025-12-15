import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fingerprint/screens/paired_devices_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

// --- Configuration ---
const String SECRET_KEY_STRING = 'MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=';
const int SERVER_PORT = 12345;
const String UNLOCK_COMMAND = "unlock";
// --- End Configuration ---

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _macController = TextEditingController();
  String _deviceName = 'No Device';
  String _status = 'Please select or add a device.';
  bool _isUnlocking = false;

  final List<Map<String, dynamic>> _devices = [];
  final List<Map<String, String>> _logs = []; // Bağlantı logları için liste

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ipController.dispose();
    _macController.dispose();
    super.dispose();
  }

  void _addLog(String title, String message, {bool isError = false}) {
    setState(() {
      _logs.insert(0, {
        'title': title,
        'message': message,
        'time': DateFormat('HH:mm:ss').format(DateTime.now()),
        'isError': isError.toString(),
      });
      if (_logs.length > 10) { // Listeyi çok uzatmamak için
        _logs.removeLast();
      }
    });
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? devicesString = prefs.getString('devices');
    if (devicesString != null) {
      final List<dynamic> decodedDevices = jsonDecode(devicesString);
      setState(() {
        _devices.clear();
        _devices.addAll(decodedDevices.cast<Map<String, dynamic>>());
        if (_devices.isNotEmpty) {
          _deviceName = _devices.first['name'];
          _ipController.text = _devices.first['ip'];
          _macController.text = _devices.first['mac'] ?? '';
          _status = 'Selected device: $_deviceName';
          _addLog('App Started', 'Loaded ${_devices.length} devices.');
        } else {
          _addLog('App Started', 'No saved devices found.');
        }
      });
    } else {
      _addLog('App Started', 'Welcome! Please add a device.');
    }
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedDevices = jsonEncode(_devices);
    await prefs.setString('devices', encodedDevices);
  }

  Future<void> _sendWakeOnLanPacket() async {
    if (_macController.text.isEmpty || _ipController.text.isEmpty) {
      _addLog('WoL Failed', 'MAC or IP address is missing.', isError: true);
      setState(() {
        _status = 'MAC or IP address is missing for WoL.';
      });
      return;
    }

    setState(() {
      _status = 'Sending Wake-on-LAN packet to $_deviceName...';
    });
    _addLog('WoL', 'Sending magic packet to ${_macController.text}');

    try {
      // Clean MAC address
      String macClean = _macController.text.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');
      if (macClean.length != 12) {
        throw FormatException('Invalid MAC address format');
      }

      // Convert MAC to bytes
      List<int> macBytes = [];
      for (int i = 0; i < 12; i += 2) {
        macBytes.add(int.parse(macClean.substring(i, i + 2), radix: 16));
      }

      // Construct Magic Packet
      // 6 bytes of 0xFF
      List<int> packet = List.filled(6, 0xFF, growable: true);
      // 16 repetitions of MAC address
      for (int i = 0; i < 16; i++) {
        packet.addAll(macBytes);
      }

      // Send packet via UDP
      RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
        socket.broadcastEnabled = true;
        
        // Send to the specific IP provided
        socket.send(packet, InternetAddress(_ipController.text), 9);
        
        // Also try to send to broadcast address if possible (simple assumption)
        // Assuming /24 subnet for simplicity: replace last octet with 255
        try {
            List<String> parts = _ipController.text.split('.');
            if (parts.length == 4) {
                parts[3] = '255';
                String broadcastIp = parts.join('.');
                socket.send(packet, InternetAddress(broadcastIp), 9);
            }
        } catch (e) {
            // Ignore broadcast calculation errors
        }
        
        socket.close();
      });

      _addLog('WoL', 'Magic packet sent successfully!');
      setState(() {
        _status = 'Wake-on-LAN packet sent!';
      });
    } catch (e) {
      _addLog('WoL Error', 'Failed to send magic packet: $e', isError: true);
      setState(() {
        _status = 'Error sending WoL packet.';
      });
    }
  }

  Future<void> _sendUnlockSignal() async {
    if (_ipController.text.isEmpty) {
      _addLog('Unlock Failed', 'No device selected.', isError: true);
      setState(() {
        _status = 'Please select a device first.';
      });
      return;
    }

    setState(() {
      _isUnlocking = true;
      _status = 'Sending unlock signal to $_deviceName...';
    });
    _addLog('Connection', 'Handshake initiated with ${_ipController.text}');

    try {
      final key = encrypt.Key.fromBase64(SECRET_KEY_STRING);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(UNLOCK_COMMAND, iv: iv);
      final payload = Uint8List.fromList(iv.bytes + encrypted.bytes);

      final socket = await Socket.connect(
        _ipController.text,
        SERVER_PORT,
        timeout: const Duration(seconds: 5),
      );
      socket.add(payload);
      await socket.flush();
      socket.close();

      _addLog('Connection', 'Unlock signal sent successfully!');
      setState(() {
        _status = 'Unlock signal sent successfully!';
      });
    } catch (e) {
      _addLog('Connection Error', 'Could not connect to $_deviceName.', isError: true);
      setState(() {
        _status = 'Error: Could not connect to server.';
      });
    } finally {
      setState(() {
        _isUnlocking = false;
      });
    }
  }

  Future<void> _authenticateAndUnlock() async {
    if (_isUnlocking) return;
    bool authenticated = false;
    try {
      _addLog('Authentication', 'Biometric challenge for UNLOCK initiated.');
      setState(() {
        _status = 'Authenticating for Unlock...';
      });
      authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or use FaceID to unlock $_deviceName',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } on PlatformException catch (e) {
      _addLog('Authentication Error', e.message ?? 'An unknown error occurred.', isError: true);
      setState(() {
        _status = 'Auth Error: ${e.message}';
      });
      return;
    }
    if (!mounted) return;

    if (authenticated) {
      _addLog('Authentication', 'Session verified successfully.');
      await _sendUnlockSignal();
    } else {
      _addLog('Authentication Failed', 'User did not authenticate.', isError: true);
      setState(() {
        _status = 'Authentication Failed.';
      });
    }
  }

  Future<void> _authenticateAndWake() async {
    if (_isUnlocking) return; // Prevent multiple operations
    bool authenticated = false;
    try {
      _addLog('Authentication', 'Biometric challenge for WAKE-ON-LAN initiated.');
      setState(() {
        _status = 'Authenticating for Wake-on-LAN...';
      });
      authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or use FaceID to wake up $_deviceName',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
    } on PlatformException catch (e) {
      _addLog('Authentication Error', e.message ?? 'An unknown error occurred.', isError: true);
      setState(() {
        _status = 'Auth Error: ${e.message}';
      });
      return;
    }
    if (!mounted) return;

    if (authenticated) {
      _addLog('Authentication', 'Session verified successfully.');
      await _sendWakeOnLanPacket();
    } else {
      _addLog('Authentication Failed', 'User did not authenticate.', isError: true);
      setState(() {
        _status = 'Authentication Failed.';
      });
    }
  }

  Future<void> _navigateToDeviceManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PairedDevicesManagementScreen(devices: _devices),
      ),
    );

    await _saveDevices();
    if (result != null && result is Map) {
      setState(() {
        _deviceName = result['name'] as String;
        _ipController.text = result['ip'] as String;
        _macController.text = result['mac'] as String? ?? '';
        _status = 'Selected device: $_deviceName';
        _addLog('Device Selected', 'Switched to $_deviceName.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Icon(Icons.lock_open, color: theme.colorScheme.primary),
        ),
        title: Text('Biometric Unlock', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices),
            tooltip: 'Manage Devices',
            onPressed: _navigateToDeviceManagement,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatusCard(theme),
            const SizedBox(height: 24),
            _buildUnlockButton(theme),
            const SizedBox(height: 24),
            _buildWakeOnLanButton(theme),
            const SizedBox(height: 24),
            _buildConnectionLog(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ipController.text.isNotEmpty ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _ipController.text.isNotEmpty ? 'SELECTED' : 'NO DEVICE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _deviceName,
                  style: GoogleFonts.spaceGrotesk(
                    textStyle: theme.textTheme.titleLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'IP: ${_ipController.text}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                 const SizedBox(height: 4),
                Text(
                  'MAC: ${_macController.text}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.desktop_windows, size: 40, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildUnlockButton(ThemeData theme) {
    return Column(
      children: [
        GestureDetector(
          onTap: _authenticateAndUnlock,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(1 - _pulseAnimation.value / 1.5),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.fingerprint, color: Colors.white, size: 64),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _ipController.text.isNotEmpty ? 'Unlock $_deviceName' : 'No Device Selected',
          style: GoogleFonts.spaceGrotesk(
            textStyle: theme.textTheme.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _status,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWakeOnLanButton(ThemeData theme) {
    bool canWake = _macController.text.isNotEmpty;
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: canWake ? _authenticateAndWake : null,
          icon: const Icon(Icons.power_settings_new),
          label: Text('Wake Up $_deviceName'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: canWake ? Colors.green : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (!canWake)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'MAC address not set for this device.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionLog(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection Log',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No logs yet.',
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                final isError = log['isError'] == 'true';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, right: 12.0),
                        child: Icon(
                          isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: isError ? Colors.red : Colors.green,
                          size: 16,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log['title']!,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  log['time']!,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              log['message']!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
