import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تأكد من تهيئة فايربيز هنا - افترضنا وجود الإعدادات
  // await Firebase.initializeApp(); 
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Tracker',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ActiveShiftScreen(),
    );
  }
}

class ActiveShiftScreen extends StatefulWidget {
  const ActiveShiftScreen({super.key});

  @override
  State<ActiveShiftScreen> createState() => _ActiveShiftScreenState();
}

class _ActiveShiftScreenState extends State<ActiveShiftScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> archiveCurrentDay() async {
    final activeOrders = await firestore.collection('active_orders').get();
    if (activeOrders.docs.isEmpty) return;

    double totalEarnings = 0.0;
    for (var doc in activeOrders.docs) {
      totalEarnings += (doc.data()['delivery_fee'] ?? 0.0);
    }

    WriteBatch batch = firestore.batch();
    String todayDate = DateTime.now().toString().split(' ')[0];
    
    DocumentReference summaryRef = firestore.collection('daily_summary').doc(todayDate);
    batch.set(summaryRef, {
      'date': todayDate,
      'total_orders': activeOrders.docs.length,
      'total_earnings': totalEarnings,
      'timestamp': FieldValue.serverTimestamp(),
    });

    for (var doc in activeOrders.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم ترحيل اليوم بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أوردرات اليوم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: archiveCurrentDay,
            tooltip: 'ترحيل اليوم',
          ),
        ],
      ),
      body: const Center(child: Text('هنا هيتم عرض الأوردرات الحالية')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // دالة لإضافة أوردر جديد وهمي للتجربة
          firestore.collection('active_orders').add({
            'delivery_fee': 25.0,
            'timestamp': FieldValue.serverTimestamp(),
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
