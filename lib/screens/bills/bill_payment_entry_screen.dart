import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/utils/widgets/entry_form_widgets.dart';

class BillPaymentEntryPage extends StatefulWidget {
  const BillPaymentEntryPage({super.key});

  @override
  BillPaymentEntryPageState createState() => BillPaymentEntryPageState();
}

class BillPaymentEntryPageState extends State<BillPaymentEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _billTotalController = TextEditingController();
  final _paidAmountCashController = TextEditingController(text: '0');
  final _paidAmountOnlineController = TextEditingController(text: '0');
  final _payeeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDate;
  List<String> _suggestedPayees = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = _dateText(_selectedDate!);
    _loadPayeeSuggestions();
  }

  @override
  void dispose() {
    _billTotalController.dispose();
    _paidAmountCashController.dispose();
    _paidAmountOnlineController.dispose();
    _payeeController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadPayeeSuggestions() async {
    try {
      final snapshot = await AccountData.collection('BillPaymentEntry')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      if (!mounted) return;
      final seen = <String>{};
      final suggestions = <String>[];
      for (final doc in snapshot.docs) {
        final payee = (doc.data()['payee'] as String? ?? '').trim();
        if (payee.isNotEmpty && seen.add(payee.toLowerCase())) {
          suggestions.add(payee);
        }
        if (suggestions.length == 4) break;
      }
      setState(() => _suggestedPayees = suggestions);
    } catch (_) {
      // Recent vendors are optional; the form stays usable if loading fails.
    }
  }

  int _amount(String value) => MoneyAmount.rupeesToPaise(value) ?? 0;

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateController.text = _dateText(picked);
    });
  }

  Future<void> _submitForm() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final total = _amount(_billTotalController.text);
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
    final data = <String, dynamic>{
      'payee': _payeeController.text.trim(),
      'billTotal': MoneyAmount.rupeesToPaise(_billTotalController.text)!,
      'paidAmountCash':
          MoneyAmount.rupeesToPaise(_paidAmountCashController.text)!,
      'paidAmountOnline':
          MoneyAmount.rupeesToPaise(_paidAmountOnlineController.text)!,
      'paymentStatus': BillPaymentModel.statusFor(total, paid),
      'paidDate': paid > 0 ? _dateController.text : null,
      'description': _descriptionController.text.trim(),
      'date': _dateController.text,
      'timestamp': Timestamp.now(),
    };

    setState(() => _saving = true);
    try {
      await AccountData.collection('BillPaymentEntry').add(data);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _showErrorDialog();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErrorDialog(
      [String message = 'Failed to save data. Please try again.']) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(Icons.error_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error),
        title: const Text('Could not save bill'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
    final total = _amount(_billTotalController.text);
    final paid = _amount(_paidAmountCashController.text) +
        _amount(_paidAmountOnlineController.text);
    final status = BillPaymentModel.statusFor(total, paid);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bill & payment entry'),
            Text(
              'Record a bill and its payments',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                constraints.maxWidth < 720 ? constraints.maxWidth : 720.0;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                EntryFormSection(
                  title: 'PAYEE / VENDOR *',
                  subtitle: 'Who is this bill from?',
                  icon: Icons.storefront_outlined,
                  children: [
                    TextFormField(
                      controller: _payeeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Enter vendor or supplier',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter who this bill is for.'
                              : null,
                    ),
                    if (_suggestedPayees.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Recent vendors',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          for (final payee in _suggestedPayees)
                            ActionChip(
                              label: Text(payee),
                              onPressed: () => setState(
                                  () => _payeeController.text = payee),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                EntryFormSection(
                  title: 'TOTAL BILL',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    EntryMoneyField(
                      controller: _billTotalController,
                      label: 'Total bill amount',
                      validationLabel: 'bill total',
                      icon: Icons.receipt_long_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EntryFormSection(
                  title: 'PAYMENT STATUS & ALREADY PAID',
                  icon: Icons.payments_outlined,
                  trailing: EntryValuePill(
                    label: 'Due',
                    paise: (total - paid).clamp(0, 0x7fffffffffffffff).toInt(),
                  ),
                  children: [
                    _responsivePair(
                      EntryMoneyField(
                        controller: _paidAmountCashController,
                        label: 'Paid in cash',
                        validationLabel: 'cash paid',
                        icon: Icons.payments_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                      EntryMoneyField(
                        controller: _paidAmountOnlineController,
                        label: 'Paid online',
                        validationLabel: 'online amount paid',
                        icon: Icons.account_balance_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${BillPaymentModel.statusLabel(status)}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                EntryFormSection(
                  title: 'BILL DETAILS',
                  subtitle: 'Bill date and purpose',
                  icon: Icons.event_note_outlined,
                  children: [
                    EntryDateField(
                      label: 'Bill date',
                      value: _dateController.text,
                      onTap: _selectDate,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a date.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Bill purpose *',
                        hintText: 'Supplies, rent, utilities…',
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submitForm,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Saving bill…' : 'Save bill & payment'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
