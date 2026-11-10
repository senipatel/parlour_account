import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:parlour_account/services/firebase/account_data.dart';

class CategoryService {
  static const types = <String>['income', 'expense'];
  static const defaults = <String, List<String>>{
    'income': ['Services', 'Products', 'Other income'],
    'expense': ['Rent', 'Supplies', 'Utilities', 'Other expense'],
  };

  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String type) {
    return AccountData.collection('categories')
        .where('type', isEqualTo: type)
        .snapshots();
  }

  Future<void> ensureDefaults() async {
    for (final entry in defaults.entries) {
      final existing = await AccountData.collection('categories')
          .where('type', isEqualTo: entry.key)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) continue;
      final batch = FirebaseFirestore.instance.batch();
      for (final name in entry.value) {
        final reference = AccountData.collection('categories').doc();
        batch.set(reference, {
          'name': name,
          'type': entry.key,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> add(String type, String name) async {
    final normalizedName = _validate(name);
    final duplicate = await AccountData.collection('categories')
        .where('type', isEqualTo: type)
        .get();
    if (duplicate.docs.any((doc) =>
        (doc.data()['name'] as String? ?? '').toLowerCase() ==
        normalizedName.toLowerCase())) {
      throw ArgumentError('A category with this name already exists.');
    }
    await AccountData.collection('categories').add({
      'name': normalizedName,
      'type': type,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rename(String type, String documentId, String name) async {
    final normalizedName = _validate(name);
    final duplicates = await AccountData.collection('categories')
        .where('type', isEqualTo: type)
        .get();
    if (duplicates.docs.any((doc) =>
        doc.id != documentId &&
        (doc.data()['name'] as String? ?? '').toLowerCase() ==
            normalizedName.toLowerCase())) {
      throw ArgumentError('A category with this name already exists.');
    }
    await AccountData.collection('categories').doc(documentId).update({
      'name': normalizedName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(String documentId, bool active) async {
    await AccountData.collection('categories').doc(documentId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String _validate(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError('Enter a category name.');
    if (normalized.length > 40) {
      throw ArgumentError('Category names must be 40 characters or fewer.');
    }
    return normalized;
  }
}
