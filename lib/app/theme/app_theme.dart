import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const midnight = Color(0xFF121A26);
  static const slateBlue = Color(0xFF0D5E4E);
  static const steel = Color(0xFF756F6B);
  static const mist = Color(0xFFF5F2EC);
  static const graphite = Color(0xFF1F1B18);
  static const rose = Color(0xFFC87D65);
  static const canvas = Color(0xFFFBF9F7);
  static const surface = Color(0xFFFFFFFF);
  static const outline = Color(0xFFE8E4DC);
  static const currencyStat = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -.48,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: midnight,
      brightness: Brightness.light,
    ).copyWith(
      primary: midnight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF141C28),
      onPrimaryContainer: const Color(0xFFE9E1DC),
      secondary: slateBlue,
      onSecondary: Colors.white,
      tertiary: rose,
      error: const Color(0xFFB42318),
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE4E2),
      onErrorContainer: const Color(0xFF7A271A),
      surface: surface,
      onSurface: graphite,
      surfaceDim: const Color(0xFFE1D8D3),
      surfaceBright: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: const Color(0xFFFBF2ED),
      surfaceContainer: const Color(0xFFF5ECE7),
      surfaceContainerHigh: const Color(0xFFEFE6E1),
      surfaceContainerHighest: const Color(0xFFE9E1DC),
      onSurfaceVariant: steel,
      outline: steel,
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
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: graphite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: TextStyle(
          color: graphite,
          fontFamily: 'Epilogue',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -.25,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: graphite,
          fontFamily: 'Epilogue',
          fontSize: 32,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -.64,
        ),
        headlineSmall: TextStyle(
          color: graphite,
          fontFamily: 'Epilogue',
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: -.24,
        ),
        titleLarge: TextStyle(
          color: graphite,
          fontFamily: 'Epilogue',
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: graphite,
          fontSize: 18,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: graphite,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: .13,
        ),
        bodyLarge: TextStyle(color: graphite, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: graphite, fontSize: 14, height: 1.43),
        bodySmall: TextStyle(color: steel, fontSize: 12, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(
          color: steel,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .33,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline),
        ),
        shadowColor: const Color(0x0A1C1814),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        floatingLabelStyle: const TextStyle(
          color: midnight,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: midnight,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: midnight,
          side: const BorderSide(color: outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: graphite,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: outline),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Epilogue',
          color: graphite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(color: graphite, fontSize: 14),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: midnight,
        textColor: graphite,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(mist),
        headingTextStyle: const TextStyle(
          color: graphite,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: const TextStyle(color: graphite, fontSize: 13),
        dividerThickness: 1,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: midnight,
        collapsedIconColor: steel,
        textColor: graphite,
        collapsedTextColor: graphite,
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.only(bottom: 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outline),
        ),
        textStyle: const TextStyle(color: graphite, fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: slateBlue,
        linearTrackColor: mist,
        circularTrackColor: mist,
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xF2FFFFFF),
        indicatorColor: mist,
        elevation: 2,
        height: 76,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? midnight : steel,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? midnight : steel,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: canvas,
        indicatorColor: midnight,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: steel),
        selectedLabelTextStyle: const TextStyle(
          color: midnight,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(color: steel),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: midnight,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: midnight,
        unselectedLabelColor: steel,
        indicatorColor: slateBlue,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
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
