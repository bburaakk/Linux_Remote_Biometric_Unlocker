import 'dart:ui';
import 'package:fingerprint/screens/system_monitor_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

// --- Configuration ---
const String DEFAULT_SECRET_KEY = 'S3J5cHRvR2VuZXJhdGVkS2V5MTIzNDU2Nzg5MDEyMzQ=';
// --- End Configuration ---

class PairedDevicesManagementScreen extends StatefulWidget {
  final List<Map<String, dynamic>> devices;

  const PairedDevicesManagementScreen({super.key, required this.devices});

  @override
  State<PairedDevicesManagementScreen> createState() =>
      _PairedDevicesManagementScreenState();
}

class _PairedDevicesManagementScreenState
    extends State<PairedDevicesManagementScreen> {
  late List<Map<String, dynamic>> _devices;

  @override
  void initState() {
    super.initState();
    _devices = widget.devices;
  }

  void _saveDevice({
    required String name,
    required String ip,
    required String mac, // MAC adresi eklendi
    required String secretKey,
    int? index,
  }) {
    setState(() {
      final deviceData = {
        'icon': Icons.devices.codePoint,
        'name': name,
        'ip': ip,
        'mac': mac, // MAC adresi kaydediliyor
        'secretKey': secretKey,
        'status': 'Online',
        'details': 'user@$ip',
        'statusColor': Colors.green.value,
        'isOffline': false,
      };

      if (index != null) {
        _devices[index] = deviceData;
      } else {
        _devices.add(deviceData);
      }
    });
  }

  Future<void> _showDeviceDialog({Map<String, dynamic>? device, int? index}) async {
    final isEditing = device != null;
    final nameController = TextEditingController(text: device?['name'] ?? '');
    final ipController = TextEditingController(text: device?['ip'] ?? '');
    final macController = TextEditingController(text: device?['mac'] ?? ''); // MAC controller
    final keyController = TextEditingController(text: device?['secretKey'] ?? DEFAULT_SECRET_KEY);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF020617).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Text(isEditing ? 'Edit Device' : 'Add New Device'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Device Name', icon: Icon(Icons.computer)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(labelText: 'IP Address', icon: Icon(Icons.wifi)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                // MAC Adresi Alanı
                TextField(
                  controller: macController,
                  decoration: const InputDecoration(labelText: 'MAC Address (for WoL)', icon: Icon(Icons.device_hub)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Secret Key (Base64)',
                    icon: Icon(Icons.vpn_key),
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Save' : 'Add'),
              onPressed: () {
                if (nameController.text.isNotEmpty && 
                    ipController.text.isNotEmpty && 
                    keyController.text.isNotEmpty) {
                  _saveDevice(
                    name: nameController.text, 
                    ip: ipController.text,
                    mac: macController.text, // MAC adresini kaydet
                    secretKey: keyController.text,
                    index: index,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _selectDevice(Map<String, dynamic> device) {
    Navigator.pop(context, {
      'name': device['name'],
      'ip': device['ip'],
      'mac': device['mac'] ?? '',
      'secretKey': device['secretKey'] ?? '',
    });
  }

  void _navigateToMonitor(Map<String, dynamic> device) {
    final secretKey = device['secretKey'] as String? ?? '';
    
    if (secretKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: This device has no Secret Key. Please delete and re-add it.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SystemMonitorScreen(
          deviceName: device['name'],
          ipAddress: device['ip'],
          secretKey: secretKey,
        ),
      ),
    );
  }

  void _deleteDevice(int index) {
    setState(() {
      _devices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDeviceDialog(),
          ),
        ],
      ),
      body: _devices.isEmpty 
          ? Center(child: Text("No devices added yet.", style: theme.textTheme.bodyLarge))
          : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return Dismissible(
                key: Key(device['name'] + device['ip']),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteDevice(index);
                },
                child: _OptimizedGlassCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectDevice(device),
                    onLongPress: () => _showDeviceDialog(device: device, index: index),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.computer, size: 40, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device['name'],
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  device['ip'],
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.monitor_heart_outlined),
                            tooltip: 'System Monitor',
                            onPressed: () => _navigateToMonitor(device),
                            color: Colors.white70,
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}

class _OptimizedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const _OptimizedGlassCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
