// lib/core/theme/app_theme.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║        TEMA DE LA APLICACIÓN – Material 3 + Kubik Logo      ║
// ║                                                              ║
// ║  Paleta extraída directamente del logo oficial de Kubik:    ║
// ║    Coral   (personaje izq.)  →  #EF665C                    ║
// ║    Azul/Violeta (figura der.) →  #6164B1                    ║
// ║    Texto oscuro               →  #3C3B4D                    ║
// ║                                                              ║
// ║  Regla de uso:                                              ║
// ║    • Acciones primarias, FABs, links  → kubikBlue (#6164B1) ║
// ║    • Alertas urgentes, eliminar       → kubikCoral (#EF665C)║
// ║    • Textos, íconos principales       → kubikDark (#3C3B4D) ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── Colores del logo Kubik ───────────────────────────────────
  static const Color kubikCoral     = Color(0xFFEF665C); // Personaje coral
  static const Color kubikCoralDark = Color(0xFFD4504A); // Coral más oscuro (pressed)
  static const Color kubikCoralLight= Color(0xFFF5918A); // Coral más claro (hover)

  static const Color kubikBlue      = Color(0xFF6164B1); // Figura azul/violeta
  static const Color kubikBlueDark  = Color(0xFF484B8E); // Azul más oscuro (pressed)
  static const Color kubikBlueLight = Color(0xFF8487C8); // Azul más claro (hover)

  static const Color kubikDark      = Color(0xFF3C3B4D); // Texto y fondo oscuro
  static const Color kubikDarkMid   = Color(0xFF5C5B6E); // Texto secundario

  // ─── Colores de prioridad ─────────────────────────────────────
  static const Color priorityLow    = Color(0xFF4CAF82); // Verde
  static const Color priorityMedium = Color(0xFFFFB74D); // Ámbar
  static const Color priorityHigh   = Color(0xFFEF665C); // Coral (= kubikCoral)

  // ─── Colores de estado ────────────────────────────────────────
  static const Color accentGreen    = Color(0xFF4CAF82); // Completado
  static const Color accentAmber    = Color(0xFFFFB74D); // Advertencia

  // ─── Alias semánticos para mantener compatibilidad con widgets ─
  // Mantiene el mismo nombre en el resto del código
  static const Color primaryColor   = kubikBlue;
  static const Color primaryLight   = kubikBlueLight;
  static const Color primaryDark    = kubikBlueDark;
  static const Color secondaryColor = kubikCoral;

  // ─── Superficies Modo Claro ───────────────────────────────────
  static const Color surfaceLight   = Color(0xFFF7F7FC); // Fondo ligeramente azulado
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color dividerLight   = Color(0xFFE8E8F0);

  // ─── Superficies Modo Oscuro ──────────────────────────────────
  static const Color surfaceDark    = Color(0xFF14131F); // Fondo muy oscuro violáceo
  static const Color cardDark       = Color(0xFF1E1D2E);
  static const Color dividerDark    = Color(0xFF2D2C42);

  // ─────────────────────────────────────────────────────────────────────
  // TEMA CLARO
  // ─────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kubikBlue,
      brightness: Brightness.light,
      primary: kubikBlue,
      secondary: kubikCoral,
      tertiary: kubikCoralLight,
      surface: surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kubikDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLight,
      fontFamily: 'Poppins',

      // ── AppBar ─────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: kubikDark,
        ),
        iconTheme: IconThemeData(color: kubikDark),
      ),

      // ── Cards ──────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: dividerLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton → usa kubikBlue ──────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kubikBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── OutlinedButton → borde kubikBlue ───────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kubikBlue,
          side: const BorderSide(color: kubikBlue, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── TextButton → texto kubikBlue ───────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kubikBlue,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FAB → kubikCoral (acción principal destacada) ──────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kubikCoral,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── Inputs ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0FA),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: kubikBlue, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF9E9EAB),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFFBBBBCC),
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Chips (filtros) → kubikBlue cuando seleccionado ────────
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0FA),
        selectedColor: kubikBlue.withValues(alpha: 0.15),
        checkmarkColor: kubikBlue,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        side: const BorderSide(color: dividerLight),
      ),

      // ── Switch → kubikBlue ─────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFFBBBBCC);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kubikBlue;
          return const Color(0xFFE0E0EC);
        }),
      ),

      // ── ProgressIndicator → kubikCoral ─────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kubikCoral,
        linearTrackColor: Color(0xFFFFE8E7),
      ),

      // ── Divider ────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kubikDark,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins', color: Colors.white, fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Texto ──────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge  : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: kubikDark),
        headlineLarge : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 28, color: kubikDark),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22, color: kubikDark),
        headlineSmall : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18, color: kubikDark),
        titleLarge    : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: kubikDark),
        titleMedium   : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: kubikDark),
        bodyLarge     : TextStyle(fontFamily: 'Poppins', fontSize: 15, color: kubikDarkMid),
        bodyMedium    : TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF7C7C90)),
        bodySmall     : TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF9E9EAB)),
        labelLarge    : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: kubikDark),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TEMA OSCURO
  // ─────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kubikBlue,
      brightness: Brightness.dark,
      primary: kubikBlueLight,
      secondary: kubikCoralLight,
      surface: surfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDark,
      fontFamily: 'Poppins',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 20,
          fontWeight: FontWeight.w700, color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: dividerDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kubikBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kubikBlueLight,
          side: const BorderSide(color: kubikBlueLight, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kubikBlueLight,
          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kubikCoral,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1D2E),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: kubikBlueLight, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B6B8A)),
        hintStyle: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF4A4A60), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E1D2E),
        selectedColor: kubikBlue.withValues(alpha: 0.25),
        checkmarkColor: kubikBlueLight,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        side: const BorderSide(color: dividerDark),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return const Color(0xFF5A5A7A);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kubikBlue;
          return const Color(0xFF2D2C42);
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kubikCoral,
      ),

      dividerTheme: const DividerThemeData(
        color: dividerDark, thickness: 1, space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D2C42),
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins', color: Colors.white, fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      textTheme: const TextTheme(
        headlineLarge : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 28, color: Colors.white),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white),
        headlineSmall : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        titleLarge    : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        titleMedium   : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFFE0E0EE)),
        bodyLarge     : TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Color(0xFFB0B0C8)),
        bodyMedium    : TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF8080A0)),
        bodySmall     : TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF5A5A7A)),
        labelLarge    : TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
      ),
    );
  }
}
