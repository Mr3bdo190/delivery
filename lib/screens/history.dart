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
        title: const Text('سجل الأيام', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('daily_summary').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("مفيش أيام مترحلة لسه", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: GlassBox(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${data['total_earnings']} ج.م", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent), textDirection: TextDirection.rtl),
                          Text("${data['total_orders']} أوردرات", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Text(data['date'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
