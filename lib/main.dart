import 'package:flutter/material.dart';
import 'package:fingerprint/screens/biometric_unlock_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Theme Colors from HTML ---
const Color primaryColor = Color(0xFF0D59F2);
const Color backgroundLight = Color(0xFFF5F6F8);
const Color backgroundDark = Color(0xFF101622);
const Color surfaceLight = Color(0xFFFFFFFF);
const Color surfaceDark = Color(0xFF1B1F27);
const Color textSecondaryLight = Color(0xFF64748B);
const Color textSecondaryDark = Color(0xFF9CA6BA);
// --- End Theme Colors ---

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using GoogleFonts package for 'Space Grotesk' and 'Noto Sans'
    final textTheme = Theme.of(context).textTheme;
    final darkTextTheme = Theme.of(context).primaryTextTheme;

    return MaterialApp(
      title: 'Biometric Unlock',
      debugShowCheckedModeBanner: false,
      
      // --- Light Theme ---
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          surface: surfaceLight,
          background: backgroundLight,
          secondary: textSecondaryLight,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundLight,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            textStyle: textTheme.headlineSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
      ),

      // --- Dark Theme ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          surface: surfaceDark,
          background: backgroundDark,
          secondary: textSecondaryDark,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(darkTextTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundDark,
          elevation: 0,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            textStyle: darkTextTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),

      // Use system setting for theme mode
      themeMode: ThemeMode.system, 
      
      home: const BiometricUnlockScreen(),
    );
  }
}
