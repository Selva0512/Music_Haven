import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Audio Haven colour palette (mirrors index.css)
// Primary  : purple  hsl(262, 83%, 58%) → #7C3AED-ish
// Accent   : pink    hsl(328, 80%, 58%) → #E040A0-ish
// Background: near-black hsl(240, 6%, 7%)
// ──────────────────────────────────────────────

class AppColors {
  AppColors._();

  static const background = Color(0xFF0F0F14);
  static const surface = Color(0xFF17171E);
  static const surfaceElevated = Color(0xFF1E1E28);

  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF9B59F5);
  static const accent = Color(0xFFD63891);

  static const onPrimary = Colors.white;
  static const onSurface = Color(0xFFF2F2F2);
  static const onSurfaceMuted = Color(0xFF7A7A8C);

  static const border = Color(0xFF2A2A38);
  static const destructive = Color(0xFFE53E3E);

  // Gradient used on buttons, album art, progress bars
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          error: AppColors.destructive,
          onSurface: AppColors.onSurface,
          onPrimary: AppColors.onPrimary,
        ),
        fontFamily: 'SF Pro Display', // falls back to system sans-serif
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.onSurface,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceMuted,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xD917171E),
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.primaryLight,
          overlayColor: Color(0x337C3AED),
          trackHeight: 3,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        dividerColor: AppColors.border,
      );
}

// ──────────────────────────────────────────────
// Reusable glass-card decoration (like .glass in CSS)
// ──────────────────────────────────────────────
BoxDecoration glassDecoration({bool strong = false}) => BoxDecoration(
      color: strong
          ? const Color(0xD917171E)
          : const Color(0x9917171E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0x4D2A2A38),
        width: 1,
      ),
    );

// Gradient container decoration
BoxDecoration gradientDecoration({double radius = 12}) => BoxDecoration(
      gradient: AppColors.gradientPrimary,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.35),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ],
    );
