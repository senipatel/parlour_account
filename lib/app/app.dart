import 'package:flutter/material.dart';

import 'package:parlour_account/app/theme/app_theme.dart';

class ParlourApp extends StatelessWidget {
  const ParlourApp({required this.home, super.key});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parlour Account Management',
      theme: AppTheme.light,
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeInOutCubic,
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}
