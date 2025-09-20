import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditDailyDataPage extends StatefulWidget {
  final Map<String, dynamic> entryData;
  final String docId;

  const EditDailyDataPage({
    super.key,
    required this.entryData,
    required this.docId,
  });

  @override
  EditDailyDataPageState createState() => EditDailyDataPageState();
}

class EditDailyDataPageState extends State<EditDailyDataPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _incomeCashController;
  late TextEditingController _incomeOnlineController;
  late TextEditingController _expenseCashController;
  late TextEditingController _expenseOnlineController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.entryData['date']);
    _incomeCashController =
        TextEditingController(text: widget.entryData['incomeCash']?.toString());
    _incomeOnlineController =
        TextEditingController(text: widget.entryData['incomeOnline']?.toString());
    _expenseCashController =
        TextEditingController(text: widget.entryData['expenseCash']?.toString());
    _expenseOnlineController =
        TextEditingController(text: widget.entryData['expenseOnline']?.toString());
    _descriptionController =
        TextEditingController(text: widget.entryData['description']);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _incomeCashController.dispose();
    _incomeOnlineController.dispose();
    _expenseCashController.dispose();
    _expenseOnlineController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to update data in Firestore
  Future<void> _updateData() async {
    final updatedData = {
      'date': _dateController.text,
      'incomeCash': _incomeCashController.text ,
      'incomeOnline': _incomeOnlineController.text,
      'expenseCash': _expenseCashController.text,
      'expenseOnline': _expenseOnlineController.text,
      'description': _descriptionController.text,
    };

    // Compare if data has actually changed
    if (updatedData.toString() != widget.entryData.toString()) {
      try {
        await FirebaseFirestore.instance
            .collection('DailyDataEntry')
            .doc(widget.docId)
            .update(updatedData);

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Data updated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to previous page
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        print("Error updating data: $e");
        // Show error dialog if update fails
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to update the data. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      // If no changes were made, show error popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Changes'),
          content: const Text('No changes were made to the data.'),
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

  // Function to show Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      // Update the text controller with the selected date
      setState(() {
        _dateController.text = "${selectedDate.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Daily Data Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Date picker
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                readOnly: true,
                onTap: () => _selectDate(context), // Open the date picker when tapped
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              // Income (Cash) field
              TextFormField(
                controller: _incomeCashController,
                decoration: const InputDecoration(labelText: 'Income (Cash)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter income (Cash)';
                  }
                  return null;
                },
              ),
              // Income (Online) field
              TextFormField(
                controller: _incomeOnlineController,
                decoration: const InputDecoration(labelText: 'Income (Online)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter income (Online)';
                  }
                  return null;
                },
              ),
              // Expense (Cash) field
              TextFormField(
                controller: _expenseCashController,
                decoration: const InputDecoration(labelText: 'Expense (Cash)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter expense (Cash)';
                  }
                  return null;
                },
              ),
              // Expense (Online) field
              TextFormField(
                controller: _expenseOnlineController,
                decoration: const InputDecoration(labelText: 'Expense (Online)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter expense (Online)';
                  }
                  return null;
                },
              ),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // If form is valid, submit the data
                    _updateData();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
