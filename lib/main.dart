import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'bill_payment_entry.dart';
import 'manage_bill_entry.dart';
import 'firebase_options.dart';
import 'daily_data_entry.dart';
import 'monthly_analysis_page.dart';
import "manage_daily_data_entry.dart";



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parlor Account Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the Daily Data Entry page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DailyDataEntryPage()),
                );
              },
              child: const Text('Daily Data Entry'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Bill/Payment Entry page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BillPaymentEntryPage()),
                );
              },
              child: const Text('Bill/Payment Entry'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonthlyAnalysisPage(),
                  ),
                );
              },
              child: const Text('Monthly Expense & Income Analysis'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Edit Daily Data Entry page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>const EditDailyDataEntryPage()),
                );
              },
              child: const Text('Edit Daily Data Entry'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>const ManageBillEntryPage()),
                );
              },
              child: const Text('Edit Bill/Payment Entry'),
            ),
          ],
        ),
      ),
    );
  }
}