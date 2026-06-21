import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_box.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('شاشة السجل التاريخي للأيام', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('حالة الترحيل', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('صافي الأرباح', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('أوردرات', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('تاريخ اليوم', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('daily_summary').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("لا يوجد سجلات بعد", style: TextStyle(color: Colors.white54)));

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: GlassBox(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                        borderColor: Colors.greenAccent.withOpacity(0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text('تم الترحيل', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                                SizedBox(width: 5),
                                Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                              ],
                            ),
                            Text("${data['total_earnings']}", style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${data['total_orders']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                            Text(data['date'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
