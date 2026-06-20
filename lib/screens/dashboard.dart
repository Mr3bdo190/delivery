import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_box.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _showAddOrderDialog() {
    TextEditingController feeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('أوردر جديد', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: TextField(
          controller: feeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'قيمة التوصيل (ج.م)',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              if (feeController.text.isNotEmpty) {
                firestore.collection('active_orders').add({
                  'delivery_fee': double.parse(feeController.text),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveDay() async {
    final activeOrders = await firestore.collection('active_orders').get();
    if (activeOrders.docs.isEmpty) return;

    double total = 0.0;
    for (var doc in activeOrders.docs) {
      // التعديل هنا: تعريف نوع البيانات صراحةً
      final data = doc.data() as Map<String, dynamic>;
      total += (data['delivery_fee'] ?? 0.0);
    }

    WriteBatch batch = firestore.batch();
    String today = DateTime.now().toString().split(' ')[0];
    
    batch.set(firestore.collection('daily_summary').doc(today), {
      'date': today,
      'total_orders': activeOrders.docs.length,
      'total_earnings': total,
      'timestamp': FieldValue.serverTimestamp(),
    });

    for (var doc in activeOrders.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم ترحيل اليوم بنجاح!', textDirection: TextDirection.rtl), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الشيفت الحالي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.orangeAccent),
            onPressed: _archiveDay,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GlassBox(
              height: 160,
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('active_orders').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
                  
                  double total = 0;
                  int count = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    // التعديل هنا أيضاً
                    final data = doc.data() as Map<String, dynamic>;
                    total += (data['delivery_fee'] ?? 0.0);
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.motorcycle, size: 40, color: Colors.orangeAccent),
                      const SizedBox(height: 10),
                      Text("إجمالي ($count أوردر)", style: const TextStyle(fontSize: 18, color: Colors.white70), textDirection: TextDirection.rtl),
                      Text("$total ج.م", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white), textDirection: TextDirection.rtl),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GlassBox(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('active_orders').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.docs.isEmpty) return const Center(child: Text("ابدأ الشغل وسجل أول أوردر!", style: TextStyle(color: Colors.white54, fontSize: 16), textDirection: TextDirection.rtl));
                    
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        // التعديل هنا في عرض البيانات
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                          title: Text("${data['delivery_fee']} ج.م", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => doc.reference.delete(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        onPressed: _showAddOrderDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("تسجيل", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
