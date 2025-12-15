import 'package:flutter/material.dart';
import 'package:fingerprint/screens/biometric_unlock_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// --- New Futurist Theme Colors ---
const Color bgColor = Color(0xFF020617); // Deepest midnight blue
const Color glassColor = Color.fromRGBO(30, 41, 59, 0.4);
const Color neonCyan = Color(0xFF00F0FF);
// --- End Theme Colors ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Yeni temamız için fontları tanımlıyoruz
    final textTheme = Theme.of(context).textTheme;
    final darkTextTheme = GoogleFonts.interTextTheme(textTheme).apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white,
    );

    return MaterialApp(
      title: 'Linux Remote Unlocker',
      debugShowCheckedModeBanner: false,
      
      // Sadece yeni koyu temayı kullanıyoruz
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        primaryColor: neonCyan,
        
        // Fontları ayarla
        textTheme: darkTextTheme,
        
        // AppBar Teması
        appBarTheme: AppBarTheme(
          backgroundColor: bgColor.withOpacity(0.8),
          elevation: 0,
          titleTextStyle: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: const IconThemeData(color: Colors.white70),
        ),

        // Diğer UI elemanları
        colorScheme: const ColorScheme.dark(
          primary: neonCyan,
          secondary: neonCyan,
          surface: glassColor,
          background: bgColor,
        ),
      ),

      // Temayı koyu moda sabitliyoruz
      themeMode: ThemeMode.dark, 
      
      home: const BiometricUnlockScreen(),
    );
  }
}
