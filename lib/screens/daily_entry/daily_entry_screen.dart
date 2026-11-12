import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/providers/daily_entry_provider.dart';
import 'package:parlour_account/utils/money_amount.dart';
import 'package:parlour_account/utils/widgets/entry_form_widgets.dart';

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
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = _dateKey(_selectedDate!);
  }

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

  int _amount(TextEditingController controller) =>
      MoneyAmount.rupeesToPaise(controller.text) ?? 0;

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Widget _responsivePair(Widget first, Widget second) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DailyEntryProvider>();
    final income =
        _amount(_incomeCashController) + _amount(_incomeOnlineController);
    final expenses =
        _amount(_expenseCashController) + _amount(_expenseOnlineController);
    final net = income - expenses;

    return Scaffold(
      appBar: AppBar(
        // toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Daily entry'),
            Text(
              'Record income and operating expenses',
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
                      title: 'INCOME',
                      subtitle: 'Cash and online service income',
                      icon: Icons.south_west_rounded,
                      trailing: EntryValuePill(label: 'Total', paise: income),
                      children: [
                        _responsivePair(
                          EntryMoneyField(
                            controller: _incomeCashController,
                            label: 'Cash income',
                            validationLabel: 'income (cash)',
                            icon: Icons.payments_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                          EntryMoneyField(
                            controller: _incomeOnlineController,
                            label: 'Online income',
                            validationLabel: 'income (online)',
                            icon: Icons.account_balance_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    EntryFormSection(
                      title: 'EXPENSES',
                      subtitle: 'Daily cash and online outflow',
                      icon: Icons.north_east_rounded,
                      trailing: EntryValuePill(label: 'Total', paise: expenses),
                      children: [
                        _responsivePair(
                          EntryMoneyField(
                            controller: _expenseCashController,
                            label: 'Cash expenses',
                            validationLabel: 'expense (cash)',
                            icon: Icons.payments_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                          EntryMoneyField(
                            controller: _expenseOnlineController,
                            label: 'Online expenses',
                            validationLabel: 'expense (online)',
                            icon: Icons.account_balance_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.midnight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: Color(0xFFA9F1DB)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('NET FOR THIS DAY',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.white70)),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '\u20B9${MoneyAmount.formatPaise(net)}',
                              key: ValueKey(net),
                              style: AppTheme.currencyStat.copyWith(
                                color: net < 0
                                    ? AppTheme.rose
                                    : const Color(0xFFA9F1DB),
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EntryFormSection(
                      title: 'ENTRY DETAILS',
                      subtitle: 'Choose the date and add an optional note',
                      icon: Icons.event_note_outlined,
                      children: [
                        EntryDateField(
                          label: 'Entry date',
                          value: _dateController.text,
                          onTap: _selectDate,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please select a date.'
                              : null,
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
                  onPressed: provider.isSaving ? null : _submit,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: provider.isSaving
                        ? const SizedBox(
                            key: ValueKey('saving'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded,
                            key: ValueKey('ready')),
                  ),
                  label: Text(provider.isSaving ? 'Saving…' : 'Review & save'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
