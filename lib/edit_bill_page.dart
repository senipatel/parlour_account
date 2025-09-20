import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditBillPage extends StatefulWidget {
  final Map<String, dynamic> entryData;
  final String docId;

  const EditBillPage({
    super.key,
    required this.entryData,
    required this.docId,
  });

  @override
  EditBillPageState createState() => EditBillPageState();
}

class EditBillPageState extends State<EditBillPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cashAmountController;
  late TextEditingController _onlineAmountController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.entryData['date']);
    _cashAmountController =
        TextEditingController(text: widget.entryData['billAmountCash']?.toString());
    _onlineAmountController =
        TextEditingController(text: widget.entryData['billAmountOnline']?.toString());
    _descriptionController =
        TextEditingController(text: widget.entryData['description']);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cashAmountController.dispose();
    _onlineAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to update data in Firestore
  Future<void> _updateData() async {
    final updatedData = {
      'date': _dateController.text,
      'billAmountCash': _cashAmountController.text,
      'billAmountOnline': _onlineAmountController.text,
      'description': _descriptionController.text,
    };

    // Check if data has actually changed
    if (updatedData.toString() != widget.entryData.toString()) {
      try {
        await FirebaseFirestore.instance
            .collection('BillPaymentEntry')
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
      setState(() {
        _dateController.text = "${selectedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bill/Payment Entry'),
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
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Bill Amount (Cash) field
              TextFormField(
                controller: _cashAmountController,
                decoration: const InputDecoration(labelText: 'Bill Amount (Cash)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bill amount (Cash)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Bill Amount (Online) field
              TextFormField(
                controller: _onlineAmountController,
                decoration: const InputDecoration(labelText: 'Bill Amount (Online)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bill amount (Online)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
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
