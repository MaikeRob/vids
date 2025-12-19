import 'package:flutter/material.dart';

class AppColors {
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backgrounds
  static const Color backgroundDark = Color(0xFF0F0F23);
  static const Color backgroundLight = Color(0xFF1A1A2E);

  // Accents
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentGreen = Color(0xFF00FF88);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}
