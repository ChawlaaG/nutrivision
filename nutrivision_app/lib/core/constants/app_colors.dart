import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF007AFF); // iOS Blue
  static const Color secondary = Color(0xFF5856D6); // iOS Indigo
  static const Color accent = Color(0xFFFF2D55); // iOS Pink

  // Backgrounds
  static const Color background = Color(0xFFF2F2F7); // iOS System Gray 6
  static const Color surface = Colors.white;
  
  // Text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93); // iOS System Gray

  // Functional
  static const Color success = Color(0xFF34C759); // iOS Green
  static const Color warning = Color(0xFFFFCC00); // iOS Yellow
  static const Color error = Color(0xFFFF3B30); // iOS Red

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
