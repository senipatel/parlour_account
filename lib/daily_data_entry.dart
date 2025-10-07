import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DailyDataEntryPage extends StatefulWidget {
  const DailyDataEntryPage({super.key});

  @override
  DailyDataEntryPageState createState() => DailyDataEntryPageState();
}

class DailyDataEntryPageState extends State<DailyDataEntryPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;

  // TextEditingController for form fields
  final TextEditingController _incomeCashController = TextEditingController();
  final TextEditingController _incomeOnlineController = TextEditingController();
  final TextEditingController _expenseCashController = TextEditingController();
  final TextEditingController _expenseOnlineController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // Controller for the date field

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _incomeCashController.dispose();
    _incomeOnlineController.dispose();
    _expenseCashController.dispose();
    _expenseOnlineController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Function to handle form submission and store data in Firestore
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Getting the current time as a timestamp for when the data is created
      Timestamp timestamp = Timestamp.now();

      // Creating the data model with actual values from controllers
      var data = {
        'incomeCash':
            _incomeCashController.text, // Use .text to get the value from the controller
        'incomeOnline': _incomeOnlineController.text,
        'expenseCash': _expenseCashController.text,
        'expenseOnline': _expenseOnlineController.text,
        'description': _descriptionController.text,
        'date': _selectedDate?.toLocal().toString().split(' ')[0] ??
            'No date selected',
        'timestamp': timestamp, // Store the date/time when this data was entered
      };

      // Show the preview dialog before saving to Firestore
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Preview Data'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income (Cash): ${_incomeCashController.text}'),
                  Text('Income (Online): ${_incomeOnlineController.text}'),
                  Text('Expense (Cash): ${_expenseCashController.text}'),
                  Text('Expense (Online): ${_expenseOnlineController.text}'),
                  Text(
                      'Date: ${_selectedDate?.toLocal().toString().split(' ')[0] ?? 'No date selected'}'),
                  Text('Description: ${_descriptionController.text}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog (cancel)
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Try to save the data to Firestore
                  try {
                    await FirebaseFirestore.instance
                        .collection('DailyDataEntry')
                        .add(data);

                    // If successful, show success message and navigate back to home page
                    Navigator.pop(context); // Close the preview dialog
                    _showSuccessDialog();
                  } catch (e) {
                    // If an error occurs, show error message
                    Navigator.pop(context); // Close the preview dialog
                    _showErrorDialog();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    }
  }

  // Function to show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data Saved Successfully'),
          content:
              const Text('Your data has been successfully stored in Firestore.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the success dialog
                Navigator.pop(
                    context); // Navigate back to Home screen (pop the DailyDataEntry page)
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to show error dialog if data saving fails
  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to save data. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the error dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now(), // Open picker with selected date or today
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Set the text of the controller to the formatted date
        _dateController.text = _selectedDate!.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Data Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Added SingleChildScrollView to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _incomeCashController,
                  decoration: const InputDecoration(
                    labelText: 'Income (Cash)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter income (cash)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _incomeOnlineController,
                  decoration: const InputDecoration(
                    labelText: 'Income (Online)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter income (online)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _expenseCashController,
                  decoration: const InputDecoration(
                    labelText: 'Expense (Cash)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expense (cash)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _expenseOnlineController,
                  decoration: const InputDecoration(
                    labelText: 'Expense (Online)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expense (online)';
                    }
                    return null;
                  },
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller:
                          _dateController, // Use the controller for the date field
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        hintText: 'Select Date',
                      ),
                      validator: (value) {
                        if (_selectedDate == null) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}