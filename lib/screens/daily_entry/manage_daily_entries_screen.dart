import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
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
              Navigator.pop(context); // Close the dialog
              _deleteData(docId); // Delete the data if confirmed
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Delete the data entry from Firestore
  Future<void> _deleteData(String docId) async {
    try {
      await AccountData.collection('DailyDataEntry').doc(docId).delete();

      // Show success confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Data deleted successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error deleting data: $e");
      // Show failure confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to delete the data. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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
        padding: const EdgeInsets.all(16.0),
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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

                        // Inside the StreamBuilder, replace the DataTable widget with this:

                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis
                                    .horizontal, // This enables horizontal scrolling
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Income (Cash)')),
                                    DataColumn(label: Text('Income (Online)')),
                                    DataColumn(label: Text('Expense (Cash)')),
                                    DataColumn(label: Text('Expense (Online)')),
                                    DataColumn(label: Text('Description')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: documents.map((entry) {
                                    final data =
                                        entry.data() as Map<String, dynamic>;
                                    final docId = entry.id;
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(data['date'] ?? 'N/A')),
                                        DataCell(Text(MoneyAmount.formatStored(
                                            data['incomeCash']))),
                                        DataCell(Text(MoneyAmount.formatStored(
                                            data['incomeOnline']))),
                                        DataCell(Text(MoneyAmount.formatStored(
                                            data['expenseCash']))),
                                        DataCell(Text(MoneyAmount.formatStored(
                                            data['expenseOnline']))),
                                        DataCell(
                                            Text(data['description'] ?? '')),
                                        DataCell(Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditDailyDataPage(
                                                      entryData: data,
                                                      docId: docId,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                _showDeleteConfirmationDialog(
                                                    docId, data);
                                              },
                                            ),
                                          ],
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
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
