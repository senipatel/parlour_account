import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/services/firebase/account_data.dart';
import 'package:parlour_account/models/bill_payment_model.dart';
import 'package:parlour_account/screens/bills/edit_bill_screen.dart';
import 'package:parlour_account/utils/month_period.dart';
import 'package:parlour_account/utils/money_amount.dart';

class ManageBillEntryPage extends StatefulWidget {
  const ManageBillEntryPage({super.key});

  @override
  State<ManageBillEntryPage> createState() => _ManageBillEntryPageState();
}

class _ManageBillEntryPageState extends State<ManageBillEntryPage> {
  List<MonthPeriod> _availablePeriods = [];
  String? _selectedPeriodKey;

  MonthPeriod? get _selectedPeriod {
    for (final period in _availablePeriods) {
      if (period.key == _selectedPeriodKey) return period;
    }
    return null;
  }

  // Fetch available months and years from Firestore
  Future<void> _fetchAvailableMonthsAndYears() async {
    try {
      final querySnapshot =
          await AccountData.collection('BillPaymentEntry').get();

      final periods = MonthPeriod.fromDateStrings(
        querySnapshot.docs.map((doc) => doc.data()['date']?.toString()),
      );
      if (!mounted) return;
      setState(() {
        _availablePeriods = periods;
        if (!_availablePeriods
            .any((period) => period.key == _selectedPeriodKey)) {
          _selectedPeriodKey = periods.isEmpty ? null : periods.first.key;
        }
      });
    } catch (e) {
      print("Error fetching available months and years: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAvailableMonthsAndYears();
  }

  // Confirm deletion dialog
  Future<void> _showDeleteConfirmationDialog(
      String docId, Map<String, dynamic> entryData) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(Icons.delete_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error),
        title: const Text('Delete bill entry?'),
        content: Text(
          'Delete the bill for ${entryData['payee'] ?? 'this vendor'} dated ${entryData['date']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteData(docId);
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  // Delete the data entry from Firestore
  Future<void> _deleteData(String docId) async {
    try {
      await AccountData.collection('BillPaymentEntry').doc(docId).delete();

    } catch (e) {
      print("Error deleting data: $e");
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.error_outline_rounded,
              color: Theme.of(dialogContext).colorScheme.error),
          title: const Text('Could not delete bill'),
          content: const Text('Please try again in a moment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = _selectedPeriod;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bill Entry'),
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 12 : 20),
        child: Column(
          children: [
            // Month and Year Selection Form
            Form(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey<String?>(_selectedPeriodKey),
                    initialValue: _selectedPeriodKey,
                    decoration:
                        const InputDecoration(labelText: 'Select Month'),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriodKey = value;
                      });
                    },
                    items: _availablePeriods.map((period) {
                      return DropdownMenuItem<String>(
                        value: period.key,
                        child: Text(period.label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // StreamBuilder to display data
            Expanded(
              child: selectedPeriod != null
                  ? StreamBuilder<QuerySnapshot>(
                      stream: AccountData.collection('BillPaymentEntry')
                          .where('date',
                              isGreaterThanOrEqualTo: selectedPeriod.startDate)
                          .where('date',
                              isLessThan: selectedPeriod.endDateExclusive)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error loading data'));
                        }

                        final documents = snapshot.data!.docs;

                        if (documents.isEmpty) {
                          return const Center(child: Text('No data found'));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: documents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = documents[index];
                            final data = entry.data() as Map<String, dynamic>;
                            return _BillRecordCard(
                              data: data,
                              onEdit: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditBillPage(
                                    docId: entry.id,
                                    entryData: data,
                                  ),
                                ),
                              ),
                              onDelete: () =>
                                  _showDeleteConfirmationDialog(entry.id, data),
                            );
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        _availablePeriods.isEmpty
                            ? 'No dated entries found'
                            : 'Please select a month',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillRecordCard extends StatelessWidget {
  const _BillRecordCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = BillPaymentModel.statusLabel(
      data['paymentStatus'] as String? ?? 'paid',
    );
    final payee = data['payee']?.toString().trim() ?? '';
    final description = data['description']?.toString().trim() ?? '';
    final dueDate = data['dueDate']?.toString() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payee.isEmpty ? 'Vendor not recorded' : payee,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data['date']?.toString() ?? 'Date not recorded',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _BillStatusTag(status: status),
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'Edit bill',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete bill',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  color: theme.colorScheme.error,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: width,
                      child: _BillValue(
                        label: 'Bill total',
                        amount: BillPaymentModel.totalPaise(data),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _BillValue(
                        label: 'Paid',
                        amount: BillPaymentModel.paidPaise(data),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (dueDate.isNotEmpty) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text('Due $dueDate', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BillValue extends StatelessWidget {
  const _BillValue({
    required this.label,
    required this.amount,
    this.color,
  });

  final String label;
  final int amount;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '\u20B9${MoneyAmount.formatPaise(amount)}',
                style: AppTheme.currencyStat.copyWith(
                  color: color,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
}

class _BillStatusTag extends StatelessWidget {
  const _BillStatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    final color = isPaid ? AppTheme.slateBlue : AppTheme.rose;
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
