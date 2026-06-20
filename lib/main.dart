import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseInit = false;
  try {
    await Firebase.initializeApp();
    // تفعيل وضع الأوفلاين والمزامنة التلقائية لفايربيز
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
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
      ),
      // لو فايربيز مش مربوط صح، هيعرض شاشة الخطأ بدل الشاشة البيضاء
      home: isFirebaseInit ? const DashboardScreen() : const ErrorScreen(),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E1E2C),
      body: Center(
        child: Text(
          "لم يتم العثور على ملف google-services.json\nبرجاء إضافته ليعمل التطبيق",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // أداة بناء الشكل الزجاجي (Glassmorphism)
  Widget _glassContainer({required Widget child, double width = double.infinity, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  void _addDummyOrder() {
    // إضافة أوردر للتجربة - فايربيز هيحفظه أوفلاين ويرفعه لما يلقط نت
    firestore.collection('active_orders').add({
      'delivery_fee': 25.0, // مكسب افتراضي
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تسجيل الأوردر (أوفلاين/أونلاين)', textDirection: TextDirection.rtl),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('أوردرات شيفت اليوم', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.white),
            onPressed: () {}, // دالة الترحيل هتتضاف هنا
            tooltip: 'ترحيل اليوم',
          ),
        ],
      ),
      // خلفية التدرج اللوني عشان تبرز التأثير الزجاجي
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF3A3A5A), Color(0xFF1E1E2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // كارت الإحصائيات الزجاجي
                _glassContainer(
                  height: 160,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('active_orders').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
                      }
                      
                      double total = 0;
                      int count = snapshot.data!.docs.length;
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        total += (data['delivery_fee'] ?? 0).toDouble();
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 40, color: Colors.orangeAccent),
                          const SizedBox(height: 10),
                          Text(
                            "إجمالي ($count أوردر)",
                            style: const TextStyle(fontSize: 18, color: Colors.white70),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            "$total ج.م",
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // قائمة الأوردرات (ممكن نطورها بعدين تعرض تفاصيل كل أوردر)
                Expanded(
                  child: _glassContainer(
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delivery_dining, size: 80, color: Colors.white24),
                          SizedBox(height: 15),
                          Text(
                            "الأوردرات المسجلة هتظهر هنا\n(التطبيق يدعم العمل بدون إنترنت)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.5),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        onPressed: _addDummyOrder,
        icon: const Icon(Icons.motorcycle, color: Colors.white),
        label: const Text("أوردر جديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
