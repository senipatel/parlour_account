import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:parlour_account/app/app.dart';
import 'package:parlour_account/screens/auth/sign_in_page.dart';
import 'package:parlour_account/screens/navigation/main_navigation_shell.dart';
import 'package:parlour_account/services/firebase/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ParlourApp(
            home: Scaffold(
              body: Center(child: Text('Unable to check sign-in status.')),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ParlourApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.data == null) {
          return ParlourApp(home: SignInPage(authService: AuthService()));
        }
        return const ParlourApp(home: MainNavigationShell());
      },
    );
  }
}
