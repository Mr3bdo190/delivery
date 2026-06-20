import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseInit = false;
  String errorMessage = '';
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    isFirebaseInit = true;
  } catch (e) {
    // هنا هنمسك الخطأ الحقيقي ونحفظه
    errorMessage = e.toString();
    debugPrint("Firebase init error: $e");
  }
  runApp(DeliveryApp(isFirebaseInit: isFirebaseInit, errorMessage: errorMessage));
}

class DeliveryApp extends StatelessWidget {
  final bool isFirebaseInit;
  final String errorMessage;
  const DeliveryApp({super.key, required this.isFirebaseInit, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Tracker',
      theme: ThemeData(brightness: Brightness.dark, fontFamily: 'Cairo'),
      // لو في خطأ هنعرض الشاشة اللي بتفصل المشكلة
      home: isFirebaseInit ? const MainScreen() : ErrorScreen(error: errorMessage),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: SelectableText(
              "تفاصيل الخطأ البرمجي:\n\n$error",
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              textDirection: TextDirection.ltr, // خليناها إنجليزي عشان الكود يبان صح
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const DashboardScreen(), const HistoryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF3A3A5A), Color(0xFF1E1E2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: _pages[_currentIndex]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الشيفت'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'السجل'),
        ],
      ),
    );
  }
}
