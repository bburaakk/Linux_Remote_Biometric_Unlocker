import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _addDevice(String name, String ip) {
    setState(() {
      // Gelen listeyi doğrudan güncelliyoruz
      _devices.add({
        // İkonları dinamik olarak atayabiliriz veya sabit bir ikon kullanabiliriz
        'icon': Icons.devices.codePoint, // İkonu codePoint olarak saklıyoruz
        'name': name,
        'ip': ip,
        'status': 'Online',
        'details': 'user@$ip',
        'statusColor': Colors.green.value, // Rengi value olarak saklıyoruz
        'isOffline': false,
      });
    });
  }

  Future<void> _showAddDeviceDialog() async {
    final nameController = TextEditingController();
    final ipController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
              ),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(labelText: 'IP Address'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (nameController.text.isNotEmpty && ipController.text.isNotEmpty) {
                  _addDevice(nameController.text, ipController.text);
                }
                Navigator.of(context).pop();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Devices',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
            Text(
              'Tap a device to select it',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDeviceDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(theme, isDarkMode),
            const SizedBox(height: 24),
            _buildSectionTitle(theme),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return _buildDeviceItem(
                    theme: theme,
                    device: device,
                    onTap: () => _selectDevice(device),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Link Active',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Biometric authentication ready',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.secondary),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Paired Machines',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_devices.length} Devices',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceItem({
    required ThemeData theme,
    required Map<String, dynamic> device,
    required VoidCallback onTap,
  }) {
    final isOffline = device['isOffline'] ?? false;
    // JSON'dan okurken IconData ve Color'ı doğru şekilde oluşturuyoruz
    final icon = IconData(device['icon'], fontFamily: 'MaterialIcons');
    final statusColor = Color(device['statusColor']);

    return Opacity(
      opacity: isOffline ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 40, color: theme.colorScheme.secondary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            device['name'],
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              device['status'],
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['details'],
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
