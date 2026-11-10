import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Returns the signed-in user's private Firestore collection.
class AccountData {
  AccountData._();

  static CollectionReference<Map<String, dynamic>> collection(String name) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to access account data.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(name);
  }

  static DocumentReference<Map<String, dynamic>> document(
    String collectionName,
    String documentId,
  ) {
    return collection(collectionName).doc(documentId);
  }
}
