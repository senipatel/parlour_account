import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const midnight = Color(0xFF0B1F3A);
  static const slateBlue = Color(0xFF1F3B5C);
  static const steel = Color(0xFFA7B1BE);
  static const mist = Color(0xFFE6E9EF);
  static const graphite = Color(0xFF2B2F36);
  static const canvas = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const outline = Color(0xFFE3E7ED);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: midnight,
      brightness: Brightness.light,
    ).copyWith(
      primary: midnight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE9EEF5),
      onPrimaryContainer: midnight,
      secondary: slateBlue,
      onSecondary: Colors.white,
      tertiary: const Color(0xFF55708F),
      error: const Color(0xFFB42318),
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE4E2),
      onErrorContainer: const Color(0xFF7A271A),
      surface: surface,
      onSurface: graphite,
      surfaceDim: const Color(0xFFE8EBF0),
      surfaceBright: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: const Color(0xFFFAFBFC),
      surfaceContainer: const Color(0xFFF2F4F7),
      surfaceContainerHigh: const Color(0xFFEAEDF2),
      surfaceContainerHighest: const Color(0xFFE3E7ED),
      onSurfaceVariant: slateBlue,
      outline: const Color(0xFF8B95A3),
      outlineVariant: outline,
      shadow: midnight,
      scrim: graphite,
      inverseSurface: graphite,
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFFB8C7D9),
      surfaceTint: midnight,
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: graphite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: graphite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.25,
          fontFamily: 'Roboto',
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: graphite,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
        ),
        headlineSmall: TextStyle(
          color: graphite,
          fontSize: 23,
          fontWeight: FontWeight.w700,
          letterSpacing: -.35,
        ),
        titleLarge: TextStyle(
          color: graphite,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: graphite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: graphite, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: graphite, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: slateBlue, fontSize: 12, height: 1.35),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: midnight, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        labelStyle: const TextStyle(color: slateBlue),
        hintStyle: const TextStyle(color: steel),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          backgroundColor: midnight,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: midnight,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: graphite,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFFE9EEF5),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? midnight
                  : slateBlue,
            )),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
