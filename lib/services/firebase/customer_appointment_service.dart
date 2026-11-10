import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:parlour_account/services/firebase/account_data.dart';

class CustomerAppointmentService {
  CollectionReference<Map<String, dynamic>> get customers =>
      AccountData.collection('customers');

  CollectionReference<Map<String, dynamic>> get appointments =>
      AccountData.collection('appointments');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomers() =>
      customers.snapshots();

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      activeCustomers() async {
    final snapshot = await customers.get();
    final result = snapshot.docs
        .where((doc) => doc.data()['active'] != false)
        .toList(growable: false);
    result.sort((a, b) => _name(a.data()).compareTo(_name(b.data())));
    return result;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      customersForAppointment(
    String? includeCustomerId,
  ) async {
    final snapshot = await customers.get();
    final result = snapshot.docs
        .where((doc) =>
            doc.data()['active'] != false || doc.id == includeCustomerId)
        .toList();
    result.sort((a, b) => _name(a.data()).compareTo(_name(b.data())));
    return result;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUpcomingAppointments() {
    return appointments
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('startAt')
        .limit(100)
        .snapshots();
  }

  Future<void> saveCustomer({String? id, required Map<String, dynamic> data}) {
    final reference = id == null ? customers.doc() : customers.doc(id);
    return reference.set({
      ...data,
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setCustomerActive(String id, bool active) {
    return customers.doc(id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAppointment(
      {String? id, required Map<String, dynamic> data}) {
    final reference = id == null ? appointments.doc() : appointments.doc(id);
    return reference.set({
      ...data,
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setAppointmentStatus(String id, String status) {
    return appointments.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String _name(Map<String, dynamic> data) =>
      (data['name'] as String? ?? '').toLowerCase();
}
