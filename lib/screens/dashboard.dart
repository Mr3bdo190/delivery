import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<void> _getCurrentLocation() async {
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

  void _showAddOrderDialog() {
    TextEditingController feeController = TextEditingController();
    TextEditingController tipController = TextEditingController();
    TextEditingController restaurantController = TextEditingController();
    TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.blueAccent.withOpacity(0.5))),
        title: const Text('شاشة إضافة أوردر جديد', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(restaurantController, 'اسم المطعم/المنطقة'),
              const SizedBox(height: 10),
              _buildDialogTextField(feeController, 'قيمة التوصيل', isNumber: true),
              const SizedBox(height: 10),
              _buildDialogTextField(tipController, 'قيمة التيب/البقشيش', isNumber: true),
              const SizedBox(height: 10),
              _buildDialogTextField(locationController, 'إضافة تفاصيل الأوردر (إحداثيات/رابط)'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () {
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
            child: const Text('إضافة الأوردر', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showArchiveDialog(int totalOrders, double totalEarnings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E212A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.greenAccent.withOpacity(0.5))),
        title: const Text('ترحيل الشفت؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إجمالي أرباح اليوم: $totalEarnings ج.م', style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            Text('إجمالي أوردرات اليوم: $totalOrders', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, minimumSize: const Size(120, 45)),
            onPressed: () {
              Navigator.pop(context);
              _archiveDay();
            },
            child: const Text('تأكيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
      final data = doc.data() as Map<String, dynamic>;
      total += ((data['delivery_fee'] ?? 0) + (data['tip'] ?? 0)).toDouble();
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
              // كارت الأرباح العائم زي التصميم
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('active_orders').snapshots(),
                builder: (context, snapshot) {
                  double total = 0;
                  int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      total += ((data['delivery_fee'] ?? 0) + (data['tip'] ?? 0)).toDouble();
                    }
                  }
                  return GlassBox(
                    borderColor: Colors.greenAccent.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$total ج.م", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                            const SizedBox(width: 10),
                            const Text("الأرباح الحالية:", style: TextStyle(fontSize: 20, color: Colors.white)),
                            const SizedBox(width: 10),
                            const Icon(Icons.monetization_on, color: Colors.greenAccent),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$count", style: const TextStyle(fontSize: 18, color: Colors.white)),
                            const SizedBox(width: 10),
                            const Text("الأوردرات:", style: TextStyle(fontSize: 18, color: Colors.white70)),
                            const SizedBox(width: 10),
                            const Icon(Icons.layers, color: Colors.white54),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('قائمة الأوردرات في الوردية مرتبة جغرافياً', style: TextStyle(color: Colors.white54, fontSize: 14)),
              ),
              const SizedBox(height: 10),
              // القائمة
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
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2D37),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // اليسار: المسافة والأيقونة
                              Column(
                                children: [
                                  Icon(Icons.location_on, color: dist > 0 ? Colors.blueAccent : Colors.greenAccent),
                                  Text(dist > 0 ? "${dist.toStringAsFixed(1)}km" : "---", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              // اليمين: التفاصيل
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(restaurant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.fastfood, color: Colors.orangeAccent, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text("Tip +$tip", style: const TextStyle(color: Colors.yellowAccent, fontSize: 12)),
                                        const SizedBox(width: 15),
                                        Text("Delivery fee $fee", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // الأزرار السفلية
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _getCurrentLocation,
                      child: GlassBox(
                        padding: const EdgeInsets.all(15),
                        borderColor: Colors.blueAccent.withOpacity(0.5),
                        child: Column(
                          children: [
                            _isSorting ? const CircularProgressIndicator(color: Colors.blueAccent) : const Icon(Icons.radar, color: Colors.blueAccent, size: 30),
                            const SizedBox(height: 5),
                            const Text('تفعيل الرادار\n(البوصلة)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('active_orders').snapshots(),
                      builder: (context, snapshot) {
                        return InkWell(
                          onTap: () {
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              double t = 0;
                              for (var d in snapshot.data!.docs) {
                                final map = d.data() as Map<String, dynamic>;
                                t += ((map['delivery_fee'] ?? 0) + (map['tip'] ?? 0)).toDouble();
                              }
                              _showArchiveDialog(snapshot.data!.docs.length, t);
                            }
                          },
                          child: GlassBox(
                            padding: const EdgeInsets.all(15),
                            borderColor: Colors.blueAccent.withOpacity(0.5),
                            child: Column(
                              children: const [
                                Icon(Icons.move_to_inbox, color: Colors.blueAccent, size: 30),
                                SizedBox(height: 5),
                                Text('ترحيل الشفت\n', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          backgroundColor: Colors.greenAccent,
          onPressed: _showAddOrderDialog,
          child: const Icon(Icons.add, color: Colors.black, size: 30),
        ),
      ),
    );
  }
}
