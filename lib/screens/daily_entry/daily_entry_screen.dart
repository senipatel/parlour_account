import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/providers/daily_entry_provider.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/utils/widgets/section_header.dart';

class DailyDataEntryPage extends StatefulWidget {
  const DailyDataEntryPage({super.key});

  @override
  State<DailyDataEntryPage> createState() => _DailyDataEntryPageState();
}

class _DailyDataEntryPageState extends State<DailyDataEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeCashController = TextEditingController();
  final _incomeOnlineController = TextEditingController();
  final _expenseCashController = TextEditingController();
  final _expenseOnlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _incomeCashController.dispose();
    _incomeOnlineController.dispose();
    _expenseCashController.dispose();
    _expenseOnlineController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

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
      _dateController.text = _dateKey(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'incomeCash': MoneyAmount.rupeesToPaise(_incomeCashController.text)!,
      'incomeOnline': MoneyAmount.rupeesToPaise(_incomeOnlineController.text)!,
      'expenseCash': MoneyAmount.rupeesToPaise(_expenseCashController.text)!,
      'expenseOnline':
          MoneyAmount.rupeesToPaise(_expenseOnlineController.text)!,
      'description': _descriptionController.text.trim(),
      'date': _dateKey(_selectedDate!),
      'timestamp': Timestamp.now(),
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review daily entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewLine('Income · cash', _incomeCashController.text),
            _PreviewLine('Income · online', _incomeOnlineController.text),
            _PreviewLine('Expenses · cash', _expenseCashController.text),
            _PreviewLine('Expenses · online', _expenseOnlineController.text),
            _PreviewLine('Date', _dateController.text),
            if (_descriptionController.text.trim().isNotEmpty)
              _PreviewLine('Note', _descriptionController.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save entry'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<DailyEntryProvider>().save(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Daily entry saved.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the entry. Try again.')),
      );
    }
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<DailyEntryProvider>().isSaving;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily data entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('Record today’s numbers',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text('Enter cash and online totals for the selected day.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SectionHeader(title: 'Income'),
                    _amountField(_incomeCashController, 'Cash income',
                        Icons.payments_outlined, 'income (cash)'),
                    const SizedBox(height: 12),
                    _amountField(_incomeOnlineController, 'Online income',
                        Icons.account_balance_outlined, 'income (online)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SectionHeader(title: 'Expenses'),
                    _amountField(_expenseCashController, 'Cash expenses',
                        Icons.payments_outlined, 'expense (cash)'),
                    const SizedBox(height: 12),
                    _amountField(_expenseOnlineController, 'Online expenses',
                        Icons.account_balance_outlined, 'expense (online)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(title: 'Entry details'),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        hintText: 'Choose a date',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                        suffixIcon: Icon(Icons.expand_more_rounded),
                      ),
                      validator: (_) =>
                          _selectedDate == null ? 'Please select a date' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isSaving ? null : _submit,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSaving
                    ? const SizedBox(
                        key: ValueKey('saving'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.mist),
                      )
                    : const Icon(Icons.check_rounded, key: ValueKey('ready')),
              ),
              label: Text(isSaving ? 'Saving…' : 'Review and save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountField(
    TextEditingController controller,
    String label,
    IconData icon,
    String validationLabel,
  ) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixText: '₹ ',
          prefixIcon: Icon(icon, color: AppTheme.slateBlue),
        ),
        validator: (value) => MoneyAmount.validateRupees(
          value,
          label: validationLabel,
        ),
      );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(value.isEmpty ? '0' : value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
      );
}
