import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:parlour_account/app/auth_gate.dart';
import 'package:parlour_account/firebase_options.dart';
import 'package:parlour_account/providers/daily_entry_provider.dart';
import 'package:parlour_account/providers/dashboard_provider.dart';
import 'package:parlour_account/providers/monthly_report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => DailyEntryProvider()),
        ChangeNotifierProvider(create: (_) => MonthlyReportProvider()),
      ],
      child: const AuthGate(),
    ),
  );
}
