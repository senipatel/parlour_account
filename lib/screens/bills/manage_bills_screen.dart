import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/screens/bills/edit_bill_screen.dart';
import 'package:parlour_account/utils/month_period.dart';
import 'package:parlour_account/utils/money_amount.dart';

class ManageBillEntryPage extends StatefulWidget {
  const ManageBillEntryPage({super.key});

  @override
  State<ManageBillEntryPage> createState() => _ManageBillEntryPageState();
}

class _ManageBillEntryPageState extends State<ManageBillEntryPage> {
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
          await AccountData.collection('BillPaymentEntry').get();

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
    _fetchAvailableMonthsAndYears();
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
            Text('Payee: ${entryData['payee'] ?? 'Not recorded'}'),
            Text(
                'Bill amount (Cash): ₹${MoneyAmount.formatStored(entryData['billAmountCash'])}'),
            Text(
                'Bill amount (Online): ₹${MoneyAmount.formatStored(entryData['billAmountOnline'])}'),
            Text('Description: ${entryData['description']}'),
            Text(
                'Status: ${BillPaymentModel.statusLabel(entryData['paymentStatus'] as String? ?? 'paid')}'),
            Text(
                'Outstanding: ₹${MoneyAmount.formatPaise(BillPaymentModel.outstandingPaise(entryData))}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteData(docId);
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
      await AccountData.collection('BillPaymentEntry').doc(docId).delete();

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = _selectedPeriod;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bill Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month and Year Selection Form
            Form(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey<String?>(_selectedPeriodKey),
                    initialValue: _selectedPeriodKey,
                    decoration:
                        const InputDecoration(labelText: 'Select Month'),
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // StreamBuilder to display data
            Expanded(
              child: selectedPeriod != null
                  ? StreamBuilder<QuerySnapshot>(
                      stream: AccountData.collection('BillPaymentEntry')
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
                          return const Center(child: Text('No data found'));
                        }

                        // Scrollable DataTable
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Payee')),
                                DataColumn(label: Text('Bill Amount (Cash)')),
                                DataColumn(label: Text('Bill Amount (Online)')),
                                DataColumn(label: Text('Paid')),
                                DataColumn(label: Text('Outstanding')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Due date')),
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
                                    DataCell(Text(data['payee'] ?? '—')),
                                    DataCell(Text(MoneyAmount.formatStored(
                                        data['billAmountCash']))),
                                    DataCell(Text(MoneyAmount.formatStored(
                                        data['billAmountOnline']))),
                                    DataCell(Text(MoneyAmount.formatPaise(
                                        BillPaymentModel.paidPaise(data)))),
                                    DataCell(Text(MoneyAmount.formatPaise(
                                        BillPaymentModel.outstandingPaise(
                                            data)))),
                                    DataCell(Text(BillPaymentModel.statusLabel(
                                        data['paymentStatus'] as String? ??
                                            'paid'))),
                                    DataCell(Text(data['dueDate'] ?? '—')),
                                    DataCell(Text(data['description'] ?? '')),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditBillPage(
                                                    docId: docId,
                                                    entryData: data,
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
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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
