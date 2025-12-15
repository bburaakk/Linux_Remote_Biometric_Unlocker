import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:percent_indicator/percent_indicator.dart';

// --- Configuration ---
const int SERVER_PORT = 12345;
const String GET_STATS_COMMAND = "get_stats";
// Power Commands
const String SHUTDOWN_COMMAND = "shutdown";
const String REBOOT_COMMAND = "reboot";
const String SUSPEND_COMMAND = "suspend";

// --- New Theme Colors from HTML ---
const Color bgColor = Color(0xFF020617);
const Color neonCyan = Color(0xFF00F0FF);
const Color neonPurple = Color(0xFFB026FF);
const Color neonOrange = Color(0xFFFF7A00);
const Color neonGreen = Color(0xFF00FF94);
// --- End Theme Colors ---

class SystemMonitorScreen extends StatefulWidget {
  final String deviceName;
  final String ipAddress;
  final String secretKey;

  const SystemMonitorScreen({
    super.key,
    required this.deviceName,
    required this.ipAddress,
    required this.secretKey,
  });

  @override
  State<SystemMonitorScreen> createState() => _SystemMonitorScreenState();
}

class _SystemMonitorScreenState extends State<SystemMonitorScreen> {
  Timer? _timer;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendCommand(String command) async {
    try {
      final key = encrypt.Key.fromBase64(widget.secretKey);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(command, iv: iv);
      final payload = Uint8List.fromList(iv.bytes + encrypted.bytes);

      final socket = await Socket.connect(
        widget.ipAddress,
        SERVER_PORT,
        timeout: const Duration(seconds: 2),
      );
      
      socket.add(payload);
      await socket.flush();
      socket.close();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Command "$command" sent successfully!')),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending command: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showConfirmationDialog(String command) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF020617).withOpacity(0.9), // Koyu arka plan
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.2)), // İnce beyaz kenarlık
          ),
          title: Text(
            'Confirm Action: ${command.toUpperCase()}',
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to ${command.toLowerCase()} the device?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                command.toUpperCase(), 
                style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _sendCommand(command);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchStats() async {
    try {
      final key = encrypt.Key.fromBase64(widget.secretKey);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(GET_STATS_COMMAND, iv: iv);
      final payload = Uint8List.fromList(iv.bytes + encrypted.bytes);

      final socket = await Socket.connect(
        widget.ipAddress,
        SERVER_PORT,
        timeout: const Duration(seconds: 1),
      );
      
      socket.add(payload);
      await socket.flush();

      final responseBytes = await socket.first;
      socket.destroy();

      if (responseBytes.isNotEmpty) {
        final responseStr = String.fromCharCodes(responseBytes);
        final stats = jsonDecode(responseStr);
        
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
            _errorMessage = '';
          });
        }
      }
    } catch (e) {
      if (mounted && _stats == null) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withOpacity(0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: neonGreen,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: neonGreen, blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SYS_MONITOR',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: neonCyan))
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildStatsDashboard(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Connection Error', style: GoogleFonts.inter(fontSize: 22, color: Colors.white)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _fetchStats();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OptimizedGlassCard(
                  child: _buildCircularStat(
                    title: 'CPU',
                    icon: Icons.memory,
                    percent: (_stats?['cpu']['usage'] ?? 0.0) / 100.0,
                    centerText: '${(_stats?['cpu']['usage'] ?? 0.0).toStringAsFixed(1)}%',
                    footerText: '${_stats?['cpu']['temp'] ?? 'N/A'}°C',
                    color: neonCyan,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptimizedGlassCard(
                  child: _buildCircularStat(
                    title: 'RAM',
                    icon: Icons.dns,
                    percent: (_stats?['ram']['usage'] ?? 0.0) / 100.0,
                    centerText: '${(_stats?['ram']['usage'] ?? 0.0).toStringAsFixed(1)}%',
                    footerText: '${_stats?['ram']['total'] ?? 0} GB',
                    color: neonPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OptimizedGlassCard(child: _buildGpuStat()),
          const SizedBox(height: 16),
          _OptimizedGlassCard(child: _buildDiskStat()),
          const SizedBox(height: 24),
          _buildPowerControls(),
        ],
      ),
    );
  }

  Widget _buildCircularStat({
    required String title,
    required IconData icon,
    required double percent,
    required String centerText,
    required String footerText,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        CircularPercentIndicator(
          radius: 50.0,
          lineWidth: 8.0,
          percent: percent,
          center: Text(centerText, style: GoogleFonts.jetBrainsMono(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          progressColor: color,
          backgroundColor: color.withOpacity(0.1),
          circularStrokeCap: CircularStrokeCap.round,
          animateFromLastPercent: true,
          animation: true,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(footerText, style: GoogleFonts.jetBrainsMono(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildGpuStat() {
    final gpu = _stats?['gpu'];
    if (gpu == null || gpu['name'] == 'N/A') {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.sports_esports, color: neonGreen),
            const SizedBox(width: 8),
            Text('GPU', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(gpu['name'], style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularPercentIndicator(
              radius: 50.0,
              lineWidth: 8.0,
              percent: (gpu['usage'] ?? 0.0) / 100.0,
              center: Text('${gpu['usage']}%', style: GoogleFonts.jetBrainsMono(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              progressColor: neonGreen,
              backgroundColor: neonGreen.withOpacity(0.1),
              circularStrokeCap: CircularStrokeCap.round,
              animateFromLastPercent: true,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Temp: ${gpu['temp']}°C', style: GoogleFonts.jetBrainsMono(color: Colors.white)),
                const SizedBox(height: 8),
                Text('Fan: ${gpu['fan_speed']}', style: GoogleFonts.jetBrainsMono(color: Colors.white70)),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildDiskStat() {
    final disk = _stats?['disk'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storage, color: neonOrange),
            const SizedBox(width: 8),
            Text('STORAGE', style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        LinearPercentIndicator(
          percent: (disk?['usage'] ?? 0.0) / 100.0,
          lineHeight: 10.0,
          barRadius: const Radius.circular(5),
          progressColor: neonOrange,
          backgroundColor: neonOrange.withOpacity(0.1),
          animateFromLastPercent: true,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${disk?['usage']}% Used', style: GoogleFonts.jetBrainsMono(color: Colors.white70)),
            Text('Total: ${disk?['total']} GB', style: GoogleFonts.jetBrainsMono(color: Colors.white70)),
          ],
        )
      ],
    );
  }

  Widget _buildPowerControls() {
    return _OptimizedGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power Controls',
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _PowerButton(
                icon: Icons.power_settings_new,
                label: 'Shutdown',
                color: Colors.red,
                onTap: () => _showConfirmationDialog(SHUTDOWN_COMMAND),
              ),
              _PowerButton(
                icon: Icons.refresh,
                label: 'Reboot',
                color: Colors.orange,
                onTap: () => _showConfirmationDialog(REBOOT_COMMAND),
              ),
              _PowerButton(
                icon: Icons.bedtime,
                label: 'Suspend',
                color: Colors.blue,
                onTap: () => _showConfirmationDialog(SUSPEND_COMMAND),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptimizedGlassCard extends StatelessWidget {
  final Widget child;
  const _OptimizedGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _PowerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PowerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
