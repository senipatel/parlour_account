import 'package:flutter/material.dart';

Route<T> appRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reducedMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reducedMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.025, .025),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
