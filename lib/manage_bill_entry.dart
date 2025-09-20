import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_bill_page.dart';

class ManageBillEntryPage extends StatefulWidget {
  const ManageBillEntryPage({super.key});

  @override
  State<ManageBillEntryPage> createState() => _ManageBillEntryPageState();
}

class _ManageBillEntryPageState extends State<ManageBillEntryPage> {
  List<String> _availableMonths = [];
  List<String> _availableYears = [];
  String? _selectedMonth;
  String? _selectedYear;

  // Fetch available months and years from Firestore
  Future<void> _fetchAvailableMonthsAndYears() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('BillPaymentEntry').get();

      Set<String> months = {};
      Set<String> years = {};

      for (var doc in querySnapshot.docs) {
        final date = (doc.data()['date'] as String?) ?? '';
        if (date.isNotEmpty) {
          final parts = date.split('-');
          if (parts.length >= 2) {
            months.add(parts[1]);
            years.add(parts[0]);
          }
        }
      }

      setState(() {
        _availableMonths = months.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        _availableYears = years.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        // Set default values if available
        if (_availableMonths.isNotEmpty && _availableYears.isNotEmpty) {
          _selectedMonth = _availableMonths.first;
          _selectedYear = _availableYears.first;
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
            Text('Bill amount (Cash): ₹${entryData['billAmountCash']}'),
            Text('Bill amount (Online): ₹${entryData['billAmountOnline']}'),
            Text('Description: ${entryData['description']}'),
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
      await FirebaseFirestore.instance.collection('BillPaymentEntry').doc(docId).delete();

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
                    value: _selectedMonth,
                    decoration: const InputDecoration(labelText: 'Select Month'),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                    items: _availableMonths.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Select Year'),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                      });
                    },
                    items: _availableYears.map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
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

            // StreamBuilder to display data
            Expanded(
              child: _selectedMonth != null && _selectedYear != null
                  ? StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('BillPaymentEntry')
                    .where('date', isGreaterThanOrEqualTo: '$_selectedYear-$_selectedMonth-01')
                    .where(
                    'date',
                    isLessThan:
                    '$_selectedYear-${(int.parse(_selectedMonth!) + 1).toString().padLeft(2, '0')}-01')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
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
                          DataColumn(label: Text('Bill Amount (Cash)')),
                          DataColumn(label: Text('Bill Amount (Online)')),
                          DataColumn(label: Text('Description')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: documents.map((entry) {
                          final data = entry.data() as Map<String, dynamic>;
                          final docId = entry.id;
                          return DataRow(
                            cells: [
                              DataCell(Text(data['date'] ?? 'N/A')),
                              DataCell(Text(data['billAmountCash'] ?? '0')),
                              DataCell(Text(data['billAmountOnline'] ?? '0')),
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
                                            builder: (context) =>EditBillPage(docId: docId ,entryData: data,),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(docId, data);
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
                  : const Center(child: Text('Please select a month and year')),
            ),
          ],
        ),
      ),
    );
  }
}
