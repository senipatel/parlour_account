import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/utils/widgets/category_select_field.dart';
import 'package:parlour_account/utils/money_amount.dart';

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
  final TextEditingController _paidAmountCashController =
      TextEditingController(text: '0');
  final TextEditingController _paidAmountOnlineController =
      TextEditingController(text: '0');
  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(); // Controller for date
  final TextEditingController _dueDateController = TextEditingController();

  // DateTime object to hold the selected date
  DateTime? _selectedDate;
  DateTime? _dueDate;
  DateTime? _paidDate;
  String? _expenseCategoryId;
  String? _expenseCategoryName;

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _billAmountCashController.dispose();
    _billAmountOnlineController.dispose();
    _paidAmountCashController.dispose();
    _paidAmountOnlineController.dispose();
    _payeeController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  // Function to handle form submission and store data in Firestore
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final total = _amount(_billAmountCashController.text) +
          _amount(_billAmountOnlineController.text);
      final paid = _amount(_paidAmountCashController.text) +
          _amount(_paidAmountOnlineController.text);
      if (total <= 0) {
        _showErrorDialog('Enter a bill amount greater than zero.');
        return;
      }
      if (paid > total) {
        _showErrorDialog('Amount paid cannot be more than the bill total.');
        return;
      }
      if (paid < total && _dueDate == null) {
        _showErrorDialog('Choose a due date for the remaining balance.');
        return;
      }
      final status = BillPaymentModel.statusFor(total, paid);
      var data = {
        'payee': _payeeController.text.trim(),
        'billAmountCash':
            MoneyAmount.rupeesToPaise(_billAmountCashController.text)!,
        'billAmountOnline':
            MoneyAmount.rupeesToPaise(_billAmountOnlineController.text)!,
        'paidAmountCash':
            MoneyAmount.rupeesToPaise(_paidAmountCashController.text)!,
        'paidAmountOnline':
            MoneyAmount.rupeesToPaise(_paidAmountOnlineController.text)!,
        'paymentStatus': status,
        'dueDate':
            _dueDateController.text.isEmpty ? null : _dueDateController.text,
        'paidDate': paid > 0
            ? (_paidDate ?? _selectedDate ?? DateTime.now())
                .toLocal()
                .toString()
                .split(' ')[0]
            : null,
        'expenseCategoryId': _expenseCategoryId,
        'expenseCategoryName': _expenseCategoryName,
        'description': _descriptionController.text,
        'date': _dateController.text, // Get date from controller
        'timestamp': Timestamp.now(),
      };

      // Store the data in Firestore under the 'BillPaymentEntry' collection
      try {
        await AccountData.collection('BillPaymentEntry').add(data);

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
          content: const Text(
              'Your data has been successfully stored in Firestore.'),
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
  void _showErrorDialog(
      [String message = 'Failed to save data. Please try again.']) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to save'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
        _dateController.text =
            _selectedDate!.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = _dateText(picked);
      });
    }
  }

  Future<void> _selectPaidDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidDate ?? _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _paidDate = picked);
  }

  int _amount(String text) => MoneyAmount.rupeesToPaise(text) ?? 0;

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final currentTotal = _amount(_billAmountCashController.text) +
        _amount(_billAmountOnlineController.text);
    final currentPaid = _amount(_paidAmountCashController.text) +
        _amount(_paidAmountOnlineController.text);
    final currentStatus = BillPaymentModel.statusFor(currentTotal, currentPaid);
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
                  controller: _payeeController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Payee / vendor *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter who this bill is for.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _billAmountCashController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Amount (Cash)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => MoneyAmount.validateRupees(
                    value,
                    label: 'bill amount (cash)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _billAmountOnlineController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Amount (Online)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => MoneyAmount.validateRupees(
                    value,
                    label: 'bill amount (online)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text('Amount already paid',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paidAmountCashController,
                  decoration: const InputDecoration(labelText: 'Paid in cash'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => MoneyAmount.validateRupees(
                    value,
                    label: 'cash paid',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paidAmountOnlineController,
                  decoration: const InputDecoration(labelText: 'Paid online'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => MoneyAmount.validateRupees(
                    value,
                    label: 'online amount paid',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(BillPaymentModel.statusLabel(currentStatus)),
                    subtitle: Text(
                      'Outstanding: ₹${MoneyAmount.formatPaise((currentTotal - currentPaid).clamp(0, 0x7fffffffffffffff).toInt())}',
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Due date'),
                  subtitle: Text(_dueDateController.text.isEmpty
                      ? 'Required while a balance is due'
                      : _dueDateController.text),
                  trailing: IconButton(
                    tooltip: 'Choose due date',
                    onPressed: _selectDueDate,
                    icon: const Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available),
                  title: const Text('Last payment date'),
                  subtitle: Text(_paidDate == null
                      ? 'Defaults to the entry date when an amount is paid'
                      : _dateText(_paidDate!)),
                  trailing: IconButton(
                    tooltip: 'Choose payment date',
                    onPressed: _selectPaidDate,
                    icon: const Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 12),
                CategorySelectField(
                  type: 'expense',
                  value: _expenseCategoryId,
                  onChanged: (category) => setState(() {
                    _expenseCategoryId = category?.id;
                    _expenseCategoryName = category?.name;
                  }),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateController, // Use controller
                      decoration: const InputDecoration(
                        labelText: 'Date',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          // Validate based on controller
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration:
                      const InputDecoration(labelText: 'Bill purpose *'),
                  maxLines: 3,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter what this bill was for.'
                      : null,
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
