import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

import 'package:parlour_account/services/firebase/account_data.dart';

class ProfileService {
  final FirebaseStorage _storage;

  ProfileService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Stream<Map<String, dynamic>?> watchProfile() {
    return AccountData.document('profile', 'settings')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Future<void> saveName(String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }
    await AccountData.document('profile', 'settings').set({
      'displayName': normalizedName,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    await FirebaseAuth.instance.currentUser?.updateDisplayName(normalizedName);
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in before uploading a profile photo.');
    }
    if (bytes.isEmpty) throw ArgumentError('The selected image is empty.');
    if (bytes.lengthInBytes >= 5 * 1024 * 1024) {
      throw ArgumentError('Choose an image smaller than 5 MB.');
    }

    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final contentType =
        lookupMimeType(fileName, headerBytes: bytes) ?? 'image/jpeg';
    final reference =
        _storage.ref('users/${user.uid}/profile/avatar.$extension');
    await reference.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final photoUrl = await reference.getDownloadURL();
    await user.updatePhotoURL(photoUrl);
    await AccountData.document('profile', 'settings').set({
      'photoUrl': photoUrl,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    return photoUrl;
  }
}
