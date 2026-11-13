import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/utils/widgets/entry_form_widgets.dart';

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

  late TextEditingController _billTotalController;
  late TextEditingController _paidCashController;
  late TextEditingController _paidOnlineController;
  late TextEditingController _payeeController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.entryData['date']);
    _billTotalController = TextEditingController(
      text: MoneyAmount.formatPaise(BillPaymentModel.totalPaise(widget.entryData)),
    );
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
  }

  @override
  void dispose() {
    _dateController.dispose();
    _billTotalController.dispose();
    _paidCashController.dispose();
    _paidOnlineController.dispose();
    _payeeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to update data in Firestore
  Future<void> _updateData() async {
    final total = _amount(_billTotalController.text);
    final paid =
        _amount(_paidCashController.text) + _amount(_paidOnlineController.text);
    if (total <= 0 || paid > total) {
      _message(total <= 0
          ? 'Bill total must be greater than zero.'
          : 'Paid amount cannot be more than the bill total.');
      return;
    }
    final updatedData = {
      'date': _dateController.text,
      'payee': _payeeController.text.trim(),
      'billTotal': MoneyAmount.rupeesToPaise(_billTotalController.text)!,
      'paidAmountCash': MoneyAmount.rupeesToPaise(_paidCashController.text)!,
      'paidAmountOnline':
          MoneyAmount.rupeesToPaise(_paidOnlineController.text)!,
      'paymentStatus': BillPaymentModel.statusFor(total, paid),
      'paidDate': paid > 0 ? _dateController.text : FieldValue.delete(),
      'billAmountCash': FieldValue.delete(),
      'billAmountOnline': FieldValue.delete(),
      'dueDate': FieldValue.delete(),
      'expenseCategoryId': FieldValue.delete(),
      'expenseCategoryName': FieldValue.delete(),
      'description': _descriptionController.text,
    };

    // Check if data has actually changed
    if (updatedData.toString() != widget.entryData.toString()) {
      try {
        await AccountData.collection('BillPaymentEntry')
            .doc(widget.docId)
            .update(updatedData);

        if (mounted) Navigator.pop(context);
      } catch (e) {
        print("Error updating data: $e");
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            icon: Icon(Icons.error_outline_rounded,
                color: Theme.of(dialogContext).colorScheme.error),
            title: const Text('Could not update bill'),
            content: const Text('Failed to update the data. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } else {
      Navigator.pop(context);
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
        _dateController.text = _dateText(selectedDate);
      });
    }
  }

  int _amount(String text) => MoneyAmount.rupeesToPaise(text) ?? 0;

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _responsivePair(Widget first, Widget second) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 440) {
            return Column(
              children: [first, const SizedBox(height: 12), second],
            );
          }
          return Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 10),
              Expanded(child: second),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final currentTotal = _amount(_billTotalController.text);
    final currentPaid =
        _amount(_paidCashController.text) + _amount(_paidOnlineController.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit bill'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 720
                  ? constraints.maxWidth
                  : 720.0;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      EntryFormSection(
                        title: 'VENDOR DETAILS',
                        icon: Icons.storefront_outlined,
                        children: [
                          TextFormField(
                            controller: _payeeController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Payee / vendor *',
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter who this bill is for.'
                                    : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EntryFormSection(
                        title: 'BILL DETAILS',
                        icon: Icons.receipt_long_outlined,
                        children: [
                          TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: const InputDecoration(
                              labelText: 'Bill date',
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Please select a date.'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          EntryMoneyField(
                            controller: _billTotalController,
                            label: 'Total bill amount',
                            validationLabel: 'bill total',
                            icon: Icons.receipt_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Bill purpose *',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter what this bill was for.'
                                    : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EntryFormSection(
                        title: 'PAYMENT DETAILS',
                        icon: Icons.payments_outlined,
                        children: [
                          _responsivePair(
                            EntryMoneyField(
                              controller: _paidCashController,
                              label: 'Paid in cash',
                              validationLabel: 'cash paid',
                              icon: Icons.payments_outlined,
                              onChanged: (_) => setState(() {}),
                            ),
                            EntryMoneyField(
                              controller: _paidOnlineController,
                              label: 'Paid online / UPI',
                              validationLabel: 'online amount paid',
                              icon: Icons.account_balance_outlined,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.payments_outlined),
                              title: Text(BillPaymentModel.statusLabel(
                                  BillPaymentModel.statusFor(
                                      currentTotal, currentPaid))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _updateData();
                          }
                        },
                        child: const Text('Save changes'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
