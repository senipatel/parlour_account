import 'package:flutter/material.dart';

import 'package:parlour_account/screens/bills/manage_bills_screen.dart';
import 'package:parlour_account/screens/customers/customer_appointment_screen.dart';
import 'package:parlour_account/screens/daily_entry/manage_daily_entries_screen.dart';
import 'package:parlour_account/screens/profile/profile_screen.dart';
import 'package:parlour_account/screens/reports/monthly_analysis_screen.dart';
import 'package:parlour_account/utils/app_navigation.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(appRoute<void>(page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('More'),
        //   actions: [
        //     IconButton(
        //       tooltip: 'Profile and settings',
        //       icon: const Icon(Icons.account_circle_outlined),
        //       onPressed: () => _open(context, const ProfilePage()),
        //     ),
        //     const SizedBox(width: 8),
        //   ],
        // ),
        body: LayoutBuilder(
          builder: (context, constraints) => ListView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth > 640 ? 32 : 20,
              8,
              constraints.maxWidth > 640 ? 32 : 20,
              28,
            ),
            children: [
              Text('Your workspace', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Customers, analysis, and account settings.',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 22),
              _MenuSection(
                title: 'Business tools',
                children: [
                  _MenuTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Customers and appointments',
                    subtitle: 'Manage clients and bookings',
                    onTap: () =>
                        _open(context, const CustomerAppointmentPage()),
                  ),
                  _MenuTile(
                    icon: Icons.calendar_view_month_outlined,
                    title: 'Monthly analysis',
                    subtitle: 'Review activity by month',
                    onTap: () => _open(context, const MonthlyAnalysisPage()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MenuSection(
                title: 'Manage records',
                children: [
                  _MenuTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Manage daily entries',
                    subtitle: 'Review or edit saved daily records',
                    onTap: () => _open(context, const EditDailyDataEntryPage()),
                  ),
                  _MenuTile(
                    icon: Icons.receipt_outlined,
                    title: 'Manage bills',
                    subtitle: 'Review paid and outstanding balances',
                    onTap: () => _open(context, const ManageBillEntryPage()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Profile and settings'),
                  subtitle: const Text('Update your name, photo, or sign out'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(context, const ProfilePage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 9),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const Divider(indent: 18,endIndent: 18, height: 2,thickness: 2,),
              ],
            ]),
          ),
        ],
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
