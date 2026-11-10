import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlour_account/services/firebase/auth_service.dart';

void main() {
  group('AuthService.errorMessage', () {
    test('returns useful email and password errors', () {
      expect(
        AuthService.errorMessage(FirebaseAuthException(code: 'invalid-email')),
        'Enter a valid email address.',
      );
      expect(
        AuthService.errorMessage(
            FirebaseAuthException(code: 'email-already-in-use')),
        'An account already exists for this email.',
      );
      expect(
        AuthService.errorMessage(FirebaseAuthException(code: 'weak-password')),
        'Choose a stronger password with at least 6 characters.',
      );
    });

    test('explains missing provider configuration and network failures', () {
      expect(
        AuthService.errorMessage(
            FirebaseAuthException(code: 'operation-not-allowed')),
        'This sign-in method is not enabled in Firebase yet.',
      );
      expect(
        AuthService.errorMessage(
            FirebaseAuthException(code: 'network-request-failed')),
        'Check your internet connection and try again.',
      );
    });
  });
}
