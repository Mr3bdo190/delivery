import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart';
import 'screens/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseInit = false;
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    isFirebaseInit = true;
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(DeliveryApp(isFirebaseInit: isFirebaseInit));
}

class DeliveryApp extends StatelessWidget {
  final bool isFirebaseInit;
  const DeliveryApp({super.key, required this.isFirebaseInit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A), // لون الخلفية الداكن المطابق للتصميم
      ),
      home: isFirebaseInit ? const MainScreen() : const Scaffold(body: Center(child: Text('خطأ في الاتصال'))),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // جعل الشاشة الرئيسية هي المفتوحة افتراضياً
  final List<Widget> _pages = [
    const HistoryScreen(),
    const DashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E2836), Color(0xFF0F111A)],
            center: Alignment.center,
            radius: 1.5,
          ),
        ),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF151720),
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'السجل'),
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
