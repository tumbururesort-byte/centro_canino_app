
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primarySeedColor = Colors.redAccent;

  static final TextTheme _appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: _appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF27E5F),
        onPrimary: Colors.white,
        surface: Color(0xFF1C1C1C),
        onSurface: Color(0xFFE8E8E8),
        background: Color(0xFF121212),
        onBackground: Color(0xFFE8E8E8),
      ),
      
      // Para los inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFFF27E5F).withOpacity(0.5),
            width: 2,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFF27E5F),
            width: 2,
          ),
        ),
      ),
    );
}
