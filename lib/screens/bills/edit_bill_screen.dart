import 'package:flutter/material.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/utils/widgets/category_select_field.dart';
import 'package:parlour_account/utils/money_amount.dart';

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
  late TextEditingController _paidCashController;
  late TextEditingController _paidOnlineController;
  late TextEditingController _payeeController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _dueDateController;
  late TextEditingController _paidDateController;
  String? _expenseCategoryId;
  String? _expenseCategoryName;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.entryData['date']);
    _cashAmountController = TextEditingController(
        text: MoneyAmount.formatStored(widget.entryData['billAmountCash']));
    _onlineAmountController = TextEditingController(
        text: MoneyAmount.formatStored(widget.entryData['billAmountOnline']));
    final legacyRecord = !widget.entryData.containsKey('paidAmountCash') &&
        !widget.entryData.containsKey('paidAmountOnline');
    _paidCashController = TextEditingController(
      text: MoneyAmount.formatStored(legacyRecord
          ? widget.entryData['billAmountCash']
          : widget.entryData['paidAmountCash']),
    );
    _paidOnlineController = TextEditingController(
      text: MoneyAmount.formatStored(legacyRecord
          ? widget.entryData['billAmountOnline']
          : widget.entryData['paidAmountOnline']),
    );
    _payeeController = TextEditingController(
      text: widget.entryData['payee'] as String? ?? '',
    );
    _descriptionController =
        TextEditingController(text: widget.entryData['description']);
    _dueDateController = TextEditingController(
      text: widget.entryData['dueDate'] as String? ?? '',
    );
    _paidDateController = TextEditingController(
      text: widget.entryData['paidDate'] as String? ??
          (legacyRecord ? widget.entryData['date'] as String? ?? '' : ''),
    );
    _expenseCategoryId = widget.entryData['expenseCategoryId'] as String?;
    _expenseCategoryName = widget.entryData['expenseCategoryName'] as String?;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cashAmountController.dispose();
    _onlineAmountController.dispose();
    _paidCashController.dispose();
    _paidOnlineController.dispose();
    _payeeController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _paidDateController.dispose();
    super.dispose();
  }

  // Function to update data in Firestore
  Future<void> _updateData() async {
    final total = _amount(_cashAmountController.text) +
        _amount(_onlineAmountController.text);
    final paid =
        _amount(_paidCashController.text) + _amount(_paidOnlineController.text);
    if (total <= 0 || paid > total) {
      _message(total <= 0
          ? 'Bill total must be greater than zero.'
          : 'Paid amount cannot be more than the bill total.');
      return;
    }
    if (paid < total && _dueDateController.text.isEmpty) {
      _message('Choose a due date for the remaining balance.');
      return;
    }
    final updatedData = {
      'date': _dateController.text,
      'payee': _payeeController.text.trim(),
      'billAmountCash': MoneyAmount.rupeesToPaise(_cashAmountController.text)!,
      'billAmountOnline':
          MoneyAmount.rupeesToPaise(_onlineAmountController.text)!,
      'paidAmountCash': MoneyAmount.rupeesToPaise(_paidCashController.text)!,
      'paidAmountOnline':
          MoneyAmount.rupeesToPaise(_paidOnlineController.text)!,
      'paymentStatus': BillPaymentModel.statusFor(total, paid),
      'dueDate':
          _dueDateController.text.isEmpty ? null : _dueDateController.text,
      'paidDate': paid == 0
          ? null
          : (_paidDateController.text.isEmpty
              ? _dateText(DateTime.now())
              : _paidDateController.text),
      'expenseCategoryId': _expenseCategoryId,
      'expenseCategoryName': _expenseCategoryName,
      'description': _descriptionController.text,
    };

    // Check if data has actually changed
    if (updatedData.toString() != widget.entryData.toString()) {
      try {
        await AccountData.collection('BillPaymentEntry')
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

  Future<void> _selectDueDate() async {
    final picked = await _pickDate(_dueDateController.text);
    if (picked != null) {
      setState(() => _dueDateController.text = _dateText(picked));
    }
  }

  Future<void> _selectPaidDate() async {
    final picked = await _pickDate(_paidDateController.text);
    if (picked != null) {
      setState(() => _paidDateController.text = _dateText(picked));
    }
  }

  Future<DateTime?> _pickDate(String current) => showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(current) ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

  int _amount(String text) => MoneyAmount.rupeesToPaise(text) ?? 0;

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final currentTotal = _amount(_cashAmountController.text) +
        _amount(_onlineAmountController.text);
    final currentPaid =
        _amount(_paidCashController.text) + _amount(_paidOnlineController.text);
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
                decoration:
                    const InputDecoration(labelText: 'Bill Amount (Cash)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => MoneyAmount.validateRupees(
                  value,
                  label: 'bill amount (cash)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Bill Amount (Online) field
              TextFormField(
                controller: _onlineAmountController,
                decoration:
                    const InputDecoration(labelText: 'Bill Amount (Online)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => MoneyAmount.validateRupees(
                  value,
                  label: 'bill amount (online)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text('Amount paid',
                  style: Theme.of(context).textTheme.titleSmall),
              TextFormField(
                controller: _paidCashController,
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
                controller: _paidOnlineController,
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
                  title: Text(BillPaymentModel.statusLabel(
                      BillPaymentModel.statusFor(currentTotal, currentPaid))),
                  subtitle: Text(
                    'Outstanding: ₹${MoneyAmount.formatPaise((currentTotal - currentPaid).clamp(0, 0x7fffffffffffffff).toInt())}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due date (required while balance is due)',
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                readOnly: true,
                onTap: _selectDueDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidDateController,
                decoration: const InputDecoration(
                  labelText: 'Last payment date (optional)',
                  suffixIcon: Icon(Icons.event_available),
                ),
                readOnly: true,
                onTap: _selectPaidDate,
              ),
              const SizedBox(height: 16),
              CategorySelectField(
                type: 'expense',
                value: _expenseCategoryId,
                currentName: _expenseCategoryName,
                onChanged: (category) => setState(() {
                  _expenseCategoryId = category?.id;
                  _expenseCategoryName = category?.name;
                }),
              ),
              const SizedBox(height: 16),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Bill purpose *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter what this bill was for.'
                    : null,
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
