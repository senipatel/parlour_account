import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:parlour_account/services/firebase/customer_appointment_service.dart';

class CustomerAppointmentPage extends StatefulWidget {
  const CustomerAppointmentPage({super.key});

  @override
  State<CustomerAppointmentPage> createState() =>
      _CustomerAppointmentPageState();
}

class _CustomerAppointmentPageState extends State<CustomerAppointmentPage>
    with SingleTickerProviderStateMixin {
  final _service = CustomerAppointmentService();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_tabChanged);
  }

  void _tabChanged() {
    if (!_tabController.indexIsChanging && mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addCustomer() async {
    final result = await showDialog<_CustomerDraft>(
      context: context,
      builder: (_) => const _CustomerFormDialog(),
    );
    if (result == null) return;
    try {
      await _service.saveCustomer(data: result.toMap());
    } catch (_) {
      _message('Could not save the customer. Try again.');
    }
  }

  Future<void> _editCustomer(
    QueryDocumentSnapshot<Map<String, dynamic>> customer,
  ) async {
    final result = await showDialog<_CustomerDraft>(
      context: context,
      builder: (_) => _CustomerFormDialog(data: customer.data()),
    );
    if (result == null) return;
    try {
      await _service.saveCustomer(id: customer.id, data: result.toMap());
    } catch (_) {
      _message('Could not update the customer. Try again.');
    }
  }

  Future<void> _addAppointment() async {
    final customerDocs = await _loadCustomersForAppointment();
    if (!mounted) return;
    if (customerDocs.isEmpty) {
      _message('Add an active customer before booking an appointment.');
      _tabController.animateTo(0);
      return;
    }
    await _editAppointmentDialog(customers: customerDocs);
  }

  Future<void> _editAppointmentDialog({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> customers,
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final result = await showDialog<_AppointmentDraft>(
      context: context,
      builder: (_) => _AppointmentFormDialog(
        customers: customers,
        initial: data,
      ),
    );
    if (result == null) return;
    try {
      await _service.saveAppointment(id: id, data: result.toMap());
    } catch (_) {
      _message('Could not save the appointment. Try again.');
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadCustomersForAppointment() async {
    try {
      return await _service.activeCustomers();
    } catch (_) {
      _message('Could not load customers. Check your connection and retry.');
      return [];
    }
  }

  Future<void> _changeAppointmentStatus(String id, String status) async {
    try {
      await _service.setAppointmentStatus(id, status);
    } catch (_) {
      _message('Could not update the appointment. Try again.');
    }
  }

  Future<void> _openHistory(
    QueryDocumentSnapshot<Map<String, dynamic>> customer,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _CustomerHistoryPage(
          customerId: customer.id,
          customerName: customer.data()['name'] as String? ?? 'Customer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomersTab = _tabController.index == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers and appointments'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [Tab(text: 'Customers'), Tab(text: 'Appointments')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CustomerList(
            service: _service,
            onAdd: _addCustomer,
            onEdit: _editCustomer,
            onHistory: _openHistory,
            onArchive: (id, active) async {
              try {
                await _service.setCustomerActive(id, active);
              } catch (_) {
                _message('Could not update the customer. Try again.');
              }
            },
          ),
          _AppointmentList(
            service: _service,
            onAdd: _addAppointment,
            onEdit: (doc) async {
              final data = doc.data();
              List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
              try {
                docs = await _service.customersForAppointment(
                  data['customerId'] as String?,
                );
              } catch (_) {
                _message(
                    'Could not load customers. Check your connection and retry.');
                return;
              }
              if (docs.isEmpty && mounted) {
                _message(
                    'Add an active customer before editing this appointment.');
                return;
              }
              await _editAppointmentDialog(
                customers: docs,
                id: doc.id,
                data: data,
              );
            },
            onStatus: _changeAppointmentStatus,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isCustomersTab ? _addCustomer : _addAppointment,
        icon: const Icon(Icons.add),
        label: Text(isCustomersTab ? 'Add customer' : 'Book appointment'),
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.service,
    required this.onAdd,
    required this.onEdit,
    required this.onHistory,
    required this.onArchive,
  });

  final CustomerAppointmentService service;
  final VoidCallback onAdd;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>>)
      onEdit;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>>)
      onHistory;
  final Future<void> Function(String id, bool active) onArchive;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.watchCustomers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load customers.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) =>
            (a.data()['name'] as String? ?? '').toLowerCase().compareTo(
                  (b.data()['name'] as String? ?? '').toLowerCase(),
                ));
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No customers yet.'),
                TextButton(
                    onPressed: onAdd, child: const Text('Add a customer')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final active = data['active'] != false;
            final phone = data['phone'] as String? ?? '';
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(data['name'] as String? ?? 'Unnamed customer'),
              subtitle: Text([
                if (phone.isNotEmpty) phone,
                if (!active) 'Archived',
              ].join(' • ')),
              onTap: () => onHistory(doc),
              trailing: PopupMenuButton<String>(
                onSelected: (choice) {
                  if (choice == 'edit') onEdit(doc);
                  if (choice == 'history') onHistory(doc);
                  if (choice == 'toggle') onArchive(doc.id, !active);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'history', child: Text('History')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(active ? 'Archive' : 'Restore'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.service,
    required this.onAdd,
    required this.onEdit,
    required this.onStatus,
  });

  final CustomerAppointmentService service;
  final VoidCallback onAdd;
  final Future<void> Function(QueryDocumentSnapshot<Map<String, dynamic>>)
      onEdit;
  final Future<void> Function(String id, String status) onStatus;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.watchUpcomingAppointments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load appointments.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No upcoming appointments.'),
                TextButton(onPressed: onAdd, child: const Text('Book one')),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final date = (data['startAt'] as Timestamp?)?.toDate();
            final status = data['status'] as String? ?? 'booked';
            final isBooked = status == 'booked';
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.event_available)),
              title: Text(data['customerName'] as String? ?? 'Customer'),
              subtitle: Text(
                '${data['service'] ?? 'Service'} • ${date == null ? 'Date not set' : _formatDateTime(context, date)} • ${_statusLabel(status)}',
              ),
              isThreeLine: true,
              onTap: () => onEdit(doc),
              trailing: PopupMenuButton<String>(
                onSelected: (choice) {
                  if (choice == 'edit') onEdit(doc);
                  if (choice == 'complete') onStatus(doc.id, 'completed');
                  if (choice == 'cancel') onStatus(doc.id, 'cancelled');
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (isBooked) ...[
                    const PopupMenuItem(
                      value: 'complete',
                      child: Text('Mark complete'),
                    ),
                    const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _formatDateTime(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final day = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
  );
  return '$day at $time';
}

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Booked';
  }
}

class _CustomerDraft {
  const _CustomerDraft({required this.name, this.phone = '', this.notes = ''});

  final String name;
  final String phone;
  final String notes;

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'notes': notes,
        'active': true,
      };
}

class _CustomerFormDialog extends StatefulWidget {
  const _CustomerFormDialog({this.data});

  final Map<String, dynamic>? data;

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _notes;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data?['name'] as String? ?? '');
    _phone =
        TextEditingController(text: widget.data?['phone'] as String? ?? '');
    _notes =
        TextEditingController(text: widget.data?['notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.data == null ? 'Add customer' : 'Edit customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a customer name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Phone (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CustomerDraft(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                notes: _notes.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AppointmentDraft {
  const _AppointmentDraft({
    required this.customerId,
    required this.customerName,
    required this.service,
    required this.startAt,
    required this.status,
    required this.notes,
  });

  final String customerId;
  final String customerName;
  final String service;
  final DateTime startAt;
  final String status;
  final String notes;

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'service': service,
        'startAt': Timestamp.fromDate(startAt),
        'status': status,
        'notes': notes,
      };
}

class _AppointmentFormDialog extends StatefulWidget {
  const _AppointmentFormDialog({required this.customers, this.initial});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> customers;
  final Map<String, dynamic>? initial;

  @override
  State<_AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<_AppointmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _service;
  late final TextEditingController _notes;
  late DateTime _startAt;
  late String? _customerId;
  late String _status;

  @override
  void initState() {
    super.initState();
    final existingDate = (widget.initial?['startAt'] as Timestamp?)?.toDate();
    _startAt = existingDate ?? DateTime.now().add(const Duration(hours: 1));
    _customerId = widget.initial?['customerId'] as String? ??
        (widget.customers.isEmpty ? null : widget.customers.first.id);
    _status = widget.initial?['status'] as String? ?? 'booked';
    _service = TextEditingController(
      text: widget.initial?['service'] as String? ?? '',
    );
    _notes = TextEditingController(
      text: widget.initial?['notes'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _service.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selected != null && mounted) {
      setState(() {
        _startAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _startAt.hour,
          _startAt.minute,
        );
      });
    }
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (selected != null && mounted) {
      setState(() {
        _startAt = DateTime(
          _startAt.year,
          _startAt.month,
          _startAt.day,
          selected.hour,
          selected.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerItems = widget.customers;
    final matchingCustomers =
        customerItems.where((customer) => customer.id == _customerId);
    final currentCustomer =
        matchingCustomers.isEmpty ? null : matchingCustomers.first;
    return AlertDialog(
      title: Text(
          widget.initial == null ? 'Book appointment' : 'Edit appointment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: currentCustomer?.id,
                decoration: const InputDecoration(labelText: 'Customer *'),
                items: [
                  for (final customer in customerItems)
                    DropdownMenuItem(
                      value: customer.id,
                      child: Text(
                          customer.data()['name'] as String? ?? 'Customer'),
                    ),
                ],
                onChanged: (value) => setState(() => _customerId = value),
                validator: (value) =>
                    value == null ? 'Choose a customer.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _service,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Service *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the service.'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _chooseDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(MaterialLocalizations.of(context)
                          .formatMediumDate(_startAt)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _chooseTime,
                    icon: const Icon(Icons.schedule),
                    label:
                        Text(MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(_startAt),
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'booked', child: Text('Booked')),
                  DropdownMenuItem(
                      value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(
                      value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final customer =
                customerItems.firstWhere((item) => item.id == _customerId);
            Navigator.pop(
              context,
              _AppointmentDraft(
                customerId: customer.id,
                customerName: customer.data()['name'] as String? ?? 'Customer',
                service: _service.text.trim(),
                startAt: _startAt,
                status: _status,
                notes: _notes.text.trim(),
              ),
            );
          },
          child: const Text('Save appointment'),
        ),
      ],
    );
  }
}

class _CustomerHistoryPage extends StatelessWidget {
  const _CustomerHistoryPage(
      {required this.customerId, required this.customerName});

  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final stream = CustomerAppointmentService()
        .appointments
        .where('customerId', isEqualTo: customerId)
        .limit(200)
        .snapshots();
    return Scaffold(
      appBar: AppBar(title: Text('$customerName history')),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Could not load customer history.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aDate =
                (a.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bDate =
                (b.data()['startAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bDate.compareTo(aDate);
          });
          if (docs.isEmpty) {
            return const Center(
                child: Text('No appointments for this customer yet.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final date = (data['startAt'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(data['service'] as String? ?? 'Service'),
                subtitle: Text(
                  '${date == null ? 'Date not set' : _formatDateTime(context, date)} • ${_statusLabel(data['status'] as String? ?? 'booked')}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
