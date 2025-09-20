import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_data_page.dart';

class EditDailyDataEntryPage extends StatefulWidget {
  const EditDailyDataEntryPage({super.key});

  @override
  EditDailyDataEntryPageState createState() => EditDailyDataEntryPageState();
}

class EditDailyDataEntryPageState extends State<EditDailyDataEntryPage> {
  List<String> _availableMonths = [];
  List<String> _availableYears = [];
  String? _selectedMonth;
  String? _selectedYear;

  // Fetch available months and years from Firestore
  Future<void> _fetchAvailableMonthsAndYears() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('DailyDataEntry').get();

      Set<String> months = {};
      Set<String> years = {};

      for (var doc in querySnapshot.docs) {
        final date = (doc.data()['date'] as String?) ?? '';
        if (date.isNotEmpty) {
          final parts = date.split('-');
          if (parts.length >= 2) {
            months.add(parts[1]); // Month is in the second position
            years.add(parts[0]); // Year is in the first position
          }
        }
      }

      setState(() {
        _availableMonths = months.toList();
        _availableYears = years.toList();

        // Sort months numerically
        _availableMonths.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        // Sort years numerically
        _availableYears.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        // Set default values for month and year (optional)
        if (_availableMonths.isNotEmpty && _availableYears.isNotEmpty) {
          _selectedMonth = _availableMonths.first;
          _selectedYear = _availableYears.first;
        } else {
          // Set fallback values in case no months or years are available
          _selectedMonth = '01'; // Default to January
          _selectedYear = '2023'; // Default to a reasonable year
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
            Text('Income (Cash): ₹${entryData['incomeCash']}'),
            Text('Income (Online): ₹${entryData['incomeOnline']}'),
            Text('Expense (Cash): ₹${entryData['expenseCash']}'),
            Text('Expense (Online): ₹${entryData['expenseOnline']}'),
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
      await FirebaseFirestore.instance
          .collection('DailyDataEntry')
          .doc(docId)
          .delete();

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
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                    ),
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
                  DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                    ),
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

            // Real-time data stream (conditionally rendered)
            Expanded(
              child: _selectedMonth != null && _selectedYear != null
                  ? StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('DailyDataEntry')
                    .where('date', isGreaterThanOrEqualTo: '$_selectedYear-$_selectedMonth-01')
                    .where('date', isLessThan: '$_selectedYear-${(int.parse(_selectedMonth!) + 1).toString().padLeft(2, '0')}-01')
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
                    return const Center(child: Text('No data found for this month and year'));
                  }

                  // Inside the StreamBuilder, replace the DataTable widget with this:

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,  // This enables horizontal scrolling
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
                              final data = entry.data() as Map<String, dynamic>;
                              final docId = entry.id;
                              return DataRow(
                                cells: [
                                  DataCell(Text(data['date'] ?? 'N/A')),
                                  DataCell(Text(data['incomeCash'] ?? '0')),
                                  DataCell(Text(data['incomeOnline'] ?? '0')),
                                  DataCell(Text(data['expenseCash'] ?? '0')),
                                  DataCell(Text(data['expenseOnline'] ?? '0')),
                                  DataCell(Text(data['description'] ?? '')),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditDailyDataPage(
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
                                          _showDeleteConfirmationDialog(docId, data);
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
                  : const Center(child: Text('Please select a valid month and year')),
            ),
          ],
        ),
      ),
    );
  }
}
