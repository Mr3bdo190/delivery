import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/glass_box.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Position? _currentPosition;
  bool _isSorting = false;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  // ميزة فتح الموقع مباشرة في تطبيق خرائط جوجل
  Future<void> _launchMaps(double lat, double lng) async {
    HapticFeedback.lightImpact();
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _getCurrentLocation() async {
    HapticFeedback.selectionClick();
    setState(() => _isSorting = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentPosition = position;
          _isSorting = false;
        });
      }
    } catch (e) {
      setState(() => _isSorting = false);
    }
  }

  // نافذة تسجيل أوردر جديد
  void _showAddOrderDialog() {
    TextEditingController feeController = TextEditingController();
    TextEditingController tipController = TextEditingController();
    TextEditingController restaurantController = TextEditingController();
    TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل أوردر جديد', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(restaurantController, 'اسم المطعم/المنطقة'),
              const SizedBox(height: 10),
              _buildDialogTextField(feeController, 'قيمة التوصيل (ج.م) *', isNumber: true),
              const SizedBox(height: 10),
              _buildDialogTextField(tipController, 'قيمة التيب/البقشيش (اختياري)', isNumber: true),
              const SizedBox(height: 10),
              _buildDialogTextField(locationController, 'انسخ هنا الإحداثيات أو الرابط'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () {
              HapticFeedback.mediumImpact(); // نبضة اهتزاز عند الإضافة الناجحة
              double? fee = double.tryParse(feeController.text);
              double tip = double.tryParse(tipController.text) ?? 0.0;
              String restaurant = restaurantController.text.trim();
              String locText = locationController.text.trim();
              double lat = 0.0, lng = 0.0;

              RegExp regExp = RegExp(r'([0-9.-]+)\s*,\s*([0-9.-]+)');
              var match = regExp.firstMatch(locText);
              if (match != null) {
                lat = double.parse(match.group(1)!);
                lng = double.parse(match.group(2)!);
              }

              if (fee != null) {
                firestore.collection('active_orders').add({
                  'delivery_fee': fee,
                  'tip': tip,
                  'restaurant': restaurant.isEmpty ? 'أوردر عام' : restaurant,
                  'latitude': lat,
                  'longitude': lng,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // نافذة تسجيل مصروف جديد (بنزين - طعام - زيت إلخ)
  void _showAddExpenseDialog() {
    TextEditingController amountController = TextEditingController();
    TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل مصروفات الوردية', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(titleController, 'نوع المصروف (بنزين، طعام، صيانة)'),
            const SizedBox(height: 10),
            _buildDialogTextField(amountController, 'المبلغ المستهلك (ج.م)', isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
              double? amount = double.tryParse(amountController.text);
              String title = titleController.text.trim();

              if (amount != null) {
                firestore.collection('active_expenses').add({
                  'title': title.isEmpty ? 'مصروف عام' : title,
                  'amount': amount,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ المصروف', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _archiveDay(double totalEarnings, double totalExpenses) async {
    HapticFeedback.heavyImpact(); // اهتزاز قوي عند الترحيل النهائي لليوم
    final activeOrders = await firestore.collection('active_orders').get();
    final activeExpenses = await firestore.collection('active_expenses').get();

    WriteBatch batch = firestore.batch();
    String today = DateTime.now().toString().split(' ')[0];
    
    // حفظ الملخص المالي الكامل في السجل
    batch.set(firestore.collection('daily_summary').doc(today), {
      'date': today,
      'total_orders': activeOrders.docs.length,
      'total_earnings': totalEarnings,
      'total_expenses': totalExpenses,
      'net_profit': totalEarnings - totalExpenses,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // حذف الداتا المؤقتة للوردية الحالية لتصفير العدادات
    for (var doc in activeOrders.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in activeExpenses.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              // كارت الحسابات والمطابقة للموك اب (أرباح - مصاريف - صافي ربح)
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('active_orders').snapshots(),
                builder: (context, orderSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('active_expenses').snapshots(),
                    builder: (context, expenseSnapshot) {
                      double totalEarnings = 0;
                      double totalExpenses = 0;
                      int count = orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;

                      if (orderSnapshot.hasData) {
                        for (var doc in orderSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          totalEarnings += ((data['delivery_fee'] ?? 0) + (data['tip'] ?? 0)).toDouble();
                        }
                      }
                      if (expenseSnapshot.hasData) {
                        for (var doc in expenseSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          totalExpenses += (data['amount'] ?? 0).toDouble();
                        }
                      }

                      double netProfit = totalEarnings - totalExpenses;

                      return GlassBox(
                        borderColor: Colors.greenAccent.withOpacity(0.4),
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text("$netProfit ج.م", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                    const Text("صافي الربح", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text("$totalExpenses i", style: const TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                    const Text("المصاريف", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text("$totalEarnings i", style: const TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                    Text("الإيرادات ($count)", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white12, height: 20),
                            // زر ترحيل الشفت مدمج ذكي
                            InkWell(
                              onTap: () => _archiveDay(totalEarnings, totalExpenses),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text("ترحيل وإنهاء وردية اليوم الحالي", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 10),
                                  Icon(Icons.power_settings_new, color: Colors.greenAccent, size: 18),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redWidget?.withOpacity(0.2) ?? const Color(0xFF331E24), side: const BorderSide(color: Colors.redAccent)),
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.money_off, color: Colors.redAccent, size: 16),
                    label: const Text("تسجيل مصروف", style: TextStyle(color: Colors.redAccent)),
                  ),
                  const Text('الأوردرات الحالية فرز جغرافي', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              // القائمة المتكاملة بالأزرار التفاعلية والخرائط
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('active_orders').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    List<DocumentSnapshot> orders = snapshot.data!.docs;

                    if (_currentPosition != null) {
                      orders.sort((a, b) {
                        final dA = a.data() as Map<String, dynamic>;
                        final dB = b.data() as Map<String, dynamic>;
                        double latA = (dA['latitude'] ?? 0.0).toDouble(), lngA = (dA['longitude'] ?? 0.0).toDouble();
                        double latB = (dB['latitude'] ?? 0.0).toDouble(), lngB = (dB['longitude'] ?? 0.0).toDouble();
                        if (latA == 0.0) return 1; if (latB == 0.0) return -1;
                        return _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, latA, lngA)
                            .compareTo(_calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, latB, lngB));
                      });
                    }

                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var doc = orders[index];
                        final data = doc.data() as Map<String, dynamic>;
                        double fee = (data['delivery_fee'] ?? 0).toDouble();
                        double tip = (data['tip'] ?? 0).toDouble();
                        String restaurant = data['restaurant'] ?? 'أوردر عام';
                        double lat = (data['latitude'] ?? 0).toDouble();
                        double lng = (data['longitude'] ?? 0).toDouble();
                        double dist = (_currentPosition != null && lat != 0) ? _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng) : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E212A),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // اليسار: زر فتح الخريطة ومؤشر المسافة
                              lat != 0.0 
                              ? InkWell(
                                  onTap: () => _launchMaps(lat, lng),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.navigation, color: Colors.blueAccent, size: 26),
                                      Text(dist > 0 ? "${dist.toStringAsFixed(1)}km" : "توجيه", style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              : const Icon(Icons.location_off, color: Colors.white24),
                              // اليمين: تفاصيل ومبالغ الخدمة
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(restaurant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text("Tip: +$tip", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                        const SizedBox(width: 15),
                                        Text("خدمة: $fee ج.م", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redOpacity ?? Colors.redAccent, size: 20),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  doc.reference.delete();
                                },
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // لوحة التحكم وتحديث الرادار السفلي
              const SizedBox(height: 5),
              InkWell(
                onTap: _getCurrentLocation,
                child: GlassBox(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  borderColor: Colors.blueAccent.withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSorting ? const CircularProgressIndicator(color: Colors.blueAccent) : const Icon(Icons.radar, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 10),
                      const Text('تشغيل رادار الفرز الجغرافي (تحديث الموقع الحالي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: FloatingActionButton(
          backgroundColor: Colors.greenAccent,
          onPressed: _showAddOrderDialog,
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        ),
      ),
    );
  }
}
