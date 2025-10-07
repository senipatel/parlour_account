import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BillPaymentEntryPage extends StatefulWidget {
  const BillPaymentEntryPage({super.key});

  @override
  BillPaymentEntryPageState createState() => BillPaymentEntryPageState();
}

class BillPaymentEntryPageState extends State<BillPaymentEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the form fields
  final TextEditingController _billAmountCashController =
      TextEditingController();
  final TextEditingController _billAmountOnlineController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // Controller for date

  // DateTime object to hold the selected date
  DateTime? _selectedDate;

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _billAmountCashController.dispose();
    _billAmountOnlineController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Function to handle form submission and store data in Firestore
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var data = {
        'billAmountCash': _billAmountCashController.text,
        'billAmountOnline': _billAmountOnlineController.text,
        'description': _descriptionController.text,
        'date': _dateController.text, // Get date from controller
        'timestamp': Timestamp.now(),
      };

      // Store the data in Firestore under the 'BillPaymentEntry' collection
      try {
        await FirebaseFirestore.instance
            .collection('BillPaymentEntry')
            .add(data);

        // Show success dialog
        _showSuccessDialog();
      } catch (e) {
        // print('Error saving data: $e');
        _showErrorDialog();
      }
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
                    context); // Navigate back to Home screen (pop the BillPaymentEntry page)
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

  // Function to open the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Set the text of the controller
        _dateController.text = _selectedDate!.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill/Payment Entry'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _billAmountCashController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Amount (Cash)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bill amount (cash)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _billAmountOnlineController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Amount (Online)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bill amount (online)';
                    }
                    return null;
                  },
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateController, // Use controller
                      decoration: const InputDecoration(
                        labelText: 'Date',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) { // Validate based on controller
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
                    labelText: 'Description (Optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
