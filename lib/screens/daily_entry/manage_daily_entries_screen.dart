import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/screens/daily_entry/edit_data_screen.dart';
import 'package:parlour_account/utils/month_period.dart';
import 'package:parlour_account/utils/money_amount.dart';

class EditDailyDataEntryPage extends StatefulWidget {
  const EditDailyDataEntryPage({super.key});

  @override
  EditDailyDataEntryPageState createState() => EditDailyDataEntryPageState();
}

class EditDailyDataEntryPageState extends State<EditDailyDataEntryPage> {
  List<MonthPeriod> _availablePeriods = [];
  String? _selectedPeriodKey;

  MonthPeriod? get _selectedPeriod {
    for (final period in _availablePeriods) {
      if (period.key == _selectedPeriodKey) return period;
    }
    return null;
  }

  // Fetch available months and years from Firestore
  Future<void> _fetchAvailableMonthsAndYears() async {
    try {
      final querySnapshot =
          await AccountData.collection('DailyDataEntry').get();

      final periods = MonthPeriod.fromDateStrings(
        querySnapshot.docs.map((doc) => doc.data()['date']?.toString()),
      );
      if (!mounted) return;
      setState(() {
        _availablePeriods = periods;
        if (!_availablePeriods
            .any((period) => period.key == _selectedPeriodKey)) {
          _selectedPeriodKey = periods.isEmpty ? null : periods.first.key;
        }
      });
    } catch (e) {
      print("Error fetching available months and years: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAvailableMonthsAndYears(); // Fetch available months and years on init
  }

  // Confirm deletion dialog
  Future<void> _showDeleteConfirmationDialog(
      String docId, Map<String, dynamic> entryData) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(Icons.delete_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error),
        title: const Text('Delete daily entry?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${entryData['date']}'),
            Text(
                'Income (Cash): ₹${MoneyAmount.formatStored(entryData['incomeCash'])}'),
            Text(
                'Income (Online): ₹${MoneyAmount.formatStored(entryData['incomeOnline'])}'),
            Text(
                'Expense (Cash): ₹${MoneyAmount.formatStored(entryData['expenseCash'])}'),
            Text(
                'Expense (Online): ₹${MoneyAmount.formatStored(entryData['expenseOnline'])}'),
            Text('Description: ${entryData['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteData(docId); // Delete the data if confirmed
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  // Delete the data entry from Firestore
  Future<void> _deleteData(String docId) async {
    try {
      await AccountData.collection('DailyDataEntry').doc(docId).delete();

    } catch (e) {
      print("Error deleting data: $e");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.error_outline_rounded,
              color: Theme.of(dialogContext).colorScheme.error),
          title: const Text('Could not delete entry'),
          content: const Text('Please try again in a moment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = _selectedPeriod;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Daily Data Entries'),
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 12 : 20),
        child: Column(
          children: [
            // Month and Year input form
            Form(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey<String?>(_selectedPeriodKey),
                    initialValue: _selectedPeriodKey,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriodKey = value;
                      });
                    },
                    items: _availablePeriods.map((period) {
                      return DropdownMenuItem<String>(
                        value: period.key,
                        child: Text(period.label),
                      );
                    }).toList(),
                  ),
                  // const SizedBox(height: 20),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     setState(() {});
                  //   },
                  //   child: const Text('Submit'),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Real-time data stream (conditionally rendered)
            Expanded(
              child: selectedPeriod != null
                  ? StreamBuilder<QuerySnapshot>(
                      stream: AccountData.collection('DailyDataEntry')
                          .where('date',
                              isGreaterThanOrEqualTo: selectedPeriod.startDate)
                          .where('date',
                              isLessThan: selectedPeriod.endDateExclusive)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error loading data'));
                        }

                        final documents = snapshot.data!.docs;

                        if (documents.isEmpty) {
                          return const Center(
                              child: Text(
                                  'No data found for this month and year'));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: documents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = documents[index];
                            final data = entry.data() as Map<String, dynamic>;
                            return _DailyEntryRecordCard(
                              data: data,
                              onEdit: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditDailyDataPage(
                                    entryData: data,
                                    docId: entry.id,
                                  ),
                                ),
                              ),
                              onDelete: () =>
                                  _showDeleteConfirmationDialog(entry.id, data),
                            );
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        _availablePeriods.isEmpty
                            ? 'No dated entries found'
                            : 'Please select a month',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyEntryRecordCard extends StatelessWidget {
  const _DailyEntryRecordCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = data['description']?.toString().trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    data['date']?.toString() ?? 'Date not recorded',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Edit entry',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete entry',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  color: theme.colorScheme.error,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: width,
                      child: _DailyEntryValue(
                          label: 'Income · cash', value: data['incomeCash']),
                    ),
                    SizedBox(
                      width: width,
                      child: _DailyEntryValue(
                          label: 'Income · online', value: data['incomeOnline']),
                    ),
                    SizedBox(
                      width: width,
                      child: _DailyEntryValue(
                          label: 'Expense · cash', value: data['expenseCash']),
                    ),
                    SizedBox(
                      width: width,
                      child: _DailyEntryValue(
                          label: 'Expense · online', value: data['expenseOnline']),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyEntryValue extends StatelessWidget {
  const _DailyEntryValue({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '\u20B9${MoneyAmount.formatStored(value)}',
                style: AppTheme.currencyStat.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      );
}
