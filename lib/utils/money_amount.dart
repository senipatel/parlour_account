/// Converts user-entered rupees and stored amounts without floating point math.
/// New Firestore amount values use integer paise. Legacy strings are rupees.
class MoneyAmount {
  MoneyAmount._();

  static final BigInt _maximumPaise = BigInt.from(9223372036854775807);
  static final RegExp _rupeePattern =
      RegExp(r'^(?:\d+(?:\.\d{0,2})?|\.\d{1,2})$');

  static String? validateRupees(String? input, {required String label}) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Please enter $label';
    if (rupeesToPaise(value) == null) {
      return 'Enter a valid non-negative amount with up to 2 decimal places';
    }
    return null;
  }

  /// Parses rupees into integer paise; invalid or overflowing values return null.
  static int? rupeesToPaise(String? input) {
    final value = input?.trim() ?? '';
    if (!_rupeePattern.hasMatch(value)) return null;

    final parts = value.split('.');
    final wholeRupees =
        BigInt.tryParse(parts.first.isEmpty ? '0' : parts.first);
    if (wholeRupees == null) return null;

    final fractionalDigits = parts.length == 1 ? '' : parts[1];
    final paiseDigits = fractionalDigits.padRight(2, '0');
    final paise = wholeRupees * BigInt.from(100) +
        BigInt.from(int.parse(paiseDigits.isEmpty ? '0' : paiseDigits));
    if (paise > _maximumPaise) return null;
    return paise.toInt();
  }

  /// Reads a stored paise integer or a legacy rupee string.
  static int? paiseFromStored(Object? value) {
    if (value is int) return value >= 0 ? value : null;
    if (value is num) {
      if (!value.isFinite || value < 0 || value != value.roundToDouble()) {
        return null;
      }
      return value.toInt();
    }
    if (value is String) return rupeesToPaise(value);
    return null;
  }

  static String formatPaise(int paise) {
    final absolutePaise = paise.abs();
    final rupees = absolutePaise ~/ 100;
    final remainder = (absolutePaise % 100).toString().padLeft(2, '0');
    final sign = paise < 0 ? '-' : '';
    return '$sign$rupees.$remainder';
  }

  /// Formats either a new integer-paise value or a legacy rupee string.
  static String formatStored(Object? value) {
    final paise = paiseFromStored(value);
    return paise == null ? '—' : formatPaise(paise);
  }
}
