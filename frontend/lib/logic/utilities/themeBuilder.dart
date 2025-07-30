// Build themes using passed themes

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData createTheme(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: GoogleFonts.robotoTextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
