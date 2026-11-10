/// A calendar month used to filter records whose dates are stored as
/// zero-padded `YYYY-MM-DD` strings.
class MonthPeriod implements Comparable<MonthPeriod> {
  const MonthPeriod({required this.year, required this.month});

  final int year;
  final int month;

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  String get label => '${_monthNames[month - 1]} $year';

  String get startDate => '$key-01';

  String get endDateExclusive {
    final nextMonth = DateTime(year, month + 1, 1);
    return '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';
  }

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Parses a date stored as `YYYY-MM-DD`. Invalid or legacy placeholder
  /// strings return null so they cannot create invalid filter options.
  static MonthPeriod? fromDateString(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return MonthPeriod(year: year, month: month);
  }

  /// Returns unique periods in newest-first order.
  static List<MonthPeriod> fromDateStrings(Iterable<String?> values) {
    final periods = <String, MonthPeriod>{};
    for (final value in values) {
      final period = fromDateString(value);
      if (period != null) periods[period.key] = period;
    }
    final result = periods.values.toList()..sort((a, b) => b.compareTo(a));
    return result;
  }

  @override
  int compareTo(MonthPeriod other) {
    final yearComparison = year.compareTo(other.year);
    return yearComparison != 0 ? yearComparison : month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) =>
      other is MonthPeriod && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);
}
