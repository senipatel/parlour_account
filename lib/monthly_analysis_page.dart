import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MonthlyAnalysisPage extends StatefulWidget {
  const MonthlyAnalysisPage({super.key});

  @override
  MonthlyAnalysisPageState createState() => MonthlyAnalysisPageState();
}

class MonthlyAnalysisPageState extends State<MonthlyAnalysisPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the month and year fields
  String? _selectedMonth;
  String? _selectedYear;

  // Variables to hold the fetched data
  final List<Map<String, dynamic>> _dailyDataEntries = [];
  final List<Map<String, dynamic>> _billPaymentEntries = [];
  double totalIncomeCash = 0.0;
  double totalIncomeOnline = 0.0;
  double totalExpenseCash = 0.0;
  double totalExpenseOnline = 0.0;
  double totalBillAmountCash = 0.0;
  double totalBillAmountOnline = 0.0;

  // Available months and years
  List<String> availableMonths = [];
  List<String> availableYears = [];

  // Fetch data from Firebase
  Future<void> _fetchData() async {
    if (_selectedMonth == null || _selectedYear == null) {
      return;
    }

    try {
      final month = _selectedMonth!;
      final year = _selectedYear!;

      // Fetch DailyDataEntry for the given month and year
      final dailyDataQuery = await FirebaseFirestore.instance
          .collection('DailyDataEntry')
          .where('date', isGreaterThanOrEqualTo: '$year-$month-01')
          .where('date', isLessThan: '$year-${(int.parse(month) + 1).toString().padLeft(2, '0')}-01')
          .get();

      final billDataQuery = await FirebaseFirestore.instance
          .collection('BillPaymentEntry')
          .where('date', isGreaterThanOrEqualTo: '$year-$month-01')
          .where('date', isLessThan: '$year-${(int.parse(month) + 1).toString().padLeft(2, '0')}-01')
          .get();

      // Clear previous data
      setState(() {
        _dailyDataEntries.clear();
        _billPaymentEntries.clear();
        totalIncomeCash = 0.0;
        totalIncomeOnline = 0.0;
        totalExpenseCash = 0.0;
        totalExpenseOnline = 0.0;
        totalBillAmountCash = 0.0;
        totalBillAmountOnline = 0.0;
      });

      // Process daily data
      for (var doc in dailyDataQuery.docs) {
        final data = doc.data();
        _dailyDataEntries.add(data);
        totalIncomeCash += double.tryParse(data['incomeCash'] ?? '0') ?? 0.0;
        totalIncomeOnline += double.tryParse(data['incomeOnline'] ?? '0') ?? 0.0;
        totalExpenseCash += double.tryParse(data['expenseCash'] ?? '0') ?? 0.0;
        totalExpenseOnline += double.tryParse(data['expenseOnline'] ?? '0') ?? 0.0;
      }

      // Process bill payment data
      for (var doc in billDataQuery.docs) {
        final data = doc.data();
        _billPaymentEntries.add(data);
        totalBillAmountCash += double.tryParse(data['billAmountCash'] ?? '0') ?? 0.0;
        totalBillAmountOnline += double.tryParse(data['billAmountOnline'] ?? '0') ?? 0.0;
      }

      setState(() {}); // Refresh the UI

    } catch (e) {
      // Handle any errors during fetching data
      print("Error fetching data: $e");
    }
  }

  // Fetch available months and years from Firebase
  Future<void> _fetchAvailableMonthsAndYears() async {
    try {
      final dailyDataQuery = await FirebaseFirestore.instance
          .collection('DailyDataEntry')
          .get();
      final billDataQuery = await FirebaseFirestore.instance
          .collection('BillPaymentEntry')
          .get();

      Set<String> months = {};
      Set<String> years = {};

      // Extract available months and years from DailyDataEntry collection
      for (var doc in dailyDataQuery.docs) {
        final date = (doc.data()['date'] as String?) ?? '';
        if (date.isNotEmpty) {
          final month = date.split('-')[1];
          final year = date.split('-')[0];
          months.add(month);
          years.add(year);
        }
      }

      // Extract available months and years from BillPaymentEntry collection
      for (var doc in billDataQuery.docs) {
        final date = (doc.data()['date'] as String?) ?? '';
        if (date.isNotEmpty) {
          final month = date.split('-')[1];
          final year = date.split('-')[0];
          months.add(month);
          years.add(year);
        }
      }

      setState(() {
        availableMonths = months.toList();
        availableYears = years.toList();
        // Set default selected month and year (optional)
        if (availableMonths.isNotEmpty && availableYears.isNotEmpty) {
          _selectedMonth = availableMonths.first;
          _selectedYear = availableYears.first;
        }
      });
    } catch (e) {
      print("Error fetching months and years: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAvailableMonthsAndYears();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Expense & Income Analysis'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month and Year dropdown selectors
            Form(
              key: _formKey,
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
                    items: availableMonths.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a month';
                      }
                      return null;
                    },
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
                    items: availableYears.map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _fetchData();
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Display the data in a table with horizontal scroll
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display total amounts (Income + Expense + Bill Amount)
                    Text('Total Income (Cash): ₹${totalIncomeCash.toStringAsFixed(2)}'),
                    Text('Total Income (Online): ₹${totalIncomeOnline.toStringAsFixed(2)}'),
                    Text('Total Expense (Cash): ₹${totalExpenseCash.toStringAsFixed(2)}'),
                    Text('Total Expense (Online): ₹${totalExpenseOnline.toStringAsFixed(2)}'),
                    Text('Total Bill Amount (Cash): ₹${totalBillAmountCash.toStringAsFixed(2)}'),
                    Text('Total Bill Amount (Online): ₹${totalBillAmountOnline.toStringAsFixed(2)}'),
                    const SizedBox(height: 20),
                    // Display Daily Data Entries with horizontal scroll
                    _dailyDataEntries.isNotEmpty
                        ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Income (Cash)')),
                          DataColumn(label: Text('Income (Online)')),
                          DataColumn(label: Text('Expense (Cash)')),
                          DataColumn(label: Text('Expense (Online)')),
                          DataColumn(label: Text('Description')),
                        ],
                        rows: _dailyDataEntries.map((data) {
                          return DataRow(
                            cells: [
                              DataCell(Text(data['date'] ?? 'N/A')),
                              DataCell(Text(data['incomeCash'] ?? '0')),
                              DataCell(Text(data['incomeOnline'] ?? '0')),
                              DataCell(Text(data['expenseCash'] ?? '0')),
                              DataCell(Text(data['expenseOnline'] ?? '0')),
                              DataCell(Text(data['description'] ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                        : const Center(child: Text("No Daily Data Found")),
                    const SizedBox(height: 20),
                    // Display Bill Payment Entries with horizontal scroll
                    _billPaymentEntries.isNotEmpty
                        ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Bill Amount (Cash)')),
                          DataColumn(label: Text('Bill Amount (Online)')),
                          DataColumn(label: Text('Description')),
                        ],
                        rows: _billPaymentEntries.map((data) {
                          return DataRow(
                            cells: [
                              DataCell(Text(data['date'] ?? 'N/A')),
                              DataCell(Text(data['billAmountCash'] ?? '0')),
                              DataCell(Text(data['billAmountOnline'] ?? '0')),
                              DataCell(Text(data['description'] ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                        : const Center(child: Text("No Bill Payment Data Found")),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
