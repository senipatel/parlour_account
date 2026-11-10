import 'package:flutter/foundation.dart';

import 'package:parlour_account/services/firebase/account_data.dart';

class DailyEntryProvider extends ChangeNotifier {
  bool _saving = false;

  bool get isSaving => _saving;

  Future<void> save(Map<String, dynamic> data) async {
    if (_saving) return;
    _saving = true;
    notifyListeners();
    try {
      await AccountData.collection('DailyDataEntry').add(data);
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
