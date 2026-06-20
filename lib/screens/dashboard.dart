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

  // دالة لحساب المسافة بين نقطتين جغرافيين (بالكيلومتر)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  // دالة جلب موقع السائق الحالي بالـ GPS
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث موقعك وترتيب الأوردرات حسب الأقرب!', textDirection: TextDirection.rtl), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      setState(() => _isSorting = false);
      debugPrint("GPS Error: $e");
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
        backgroundColor: const Color(0xFF2C2C44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل أوردر جديد', style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: restaurantController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'اسم المطعم / المنطقة', hintStyle: TextStyle(color: Colors.white54)),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'قيمة التوصيل (ج.م) *', hintStyle: TextStyle(color: Colors.white54)),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tipController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'البقشيش / التيب (اختياري)', hintStyle: TextStyle(color: Colors.white54)),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'انسخ هنا الرابط أو الإحداثيات (اختياري)', hintStyle: TextStyle(color: Colors.white54)),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              double? fee = double.tryParse(feeController.text);
              double tip = double.tryParse(tipController.text) ?? 0.0;
              String restaurant = restaurantController.text.trim();
              String locText = locationController.text.trim();

              double lat = 0.0;
              double lng = 0.0;

              // سكريبت ذكي لاستخراج الإحداثيات لو نسخ رابط أو أرقام مباشرة
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
                  'location_url': locText.startsWith('http') ? locText : 'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                  'latitude': lat,
                  'longitude': lng,
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
            icon: _isSorting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)) : const Icon(Icons.location_searching, color: Colors.blueAccent),
            onPressed: _getCurrentLocation,
            tooltip: 'ترتيب حسب موقعي الحالي',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // كارت الإحصائيات الإجمالي
            GlassBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('active_orders').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  double total = 0;
                  int count = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    total += ((data['delivery_fee'] ?? 0) + (data['tip'] ?? 0)).toDouble();
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("إجمالي ($count أوردر)", style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      Text("$total ج.م", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // قائمة الأوردرات المرتبة جغرافيًا
            Expanded(
              child: GlassBox(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('active_orders').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.docs.isEmpty) return const Center(child: Text("سجل أول أوردر لبدء الشيفت!", style: TextStyle(color: Colors.white54)));

                    // تحويل البيانات لقائمة محلية عشان نقدر نرتبها بالـ GPS
                    List<DocumentSnapshot> orders = snapshot.data!.docs;

                    if (_currentPosition != null) {
                      orders.sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>;
                        final dataB = b.data() as Map<String, dynamic>;

                        double latA = (dataA['latitude'] ?? 0.0).toDouble();
                        double lngA = (dataA['longitude'] ?? 0.0).toDouble();
                        double latB = (dataB['latitude'] ?? 0.0).toDouble();
                        double lngB = (dataB['longitude'] ?? 0.0).toDouble();

                        if (latA == 0.0 || lngA == 0.0) return 1;
                        if (latB == 0.0 || lngB == 0.0) return -1;

                        double distA = _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, latA, lngA);
                        double distB = _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, latB, lngB);

                        return distA.compareTo(distB); // ترتيب تصاعدي (من الأقرب للأبعد)
                      });
                    }

                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var doc = orders[index];
                        final data = doc.data() as Map<String, dynamic>;

                        double fee = (data['delivery_fee'] ?? 0.0).toDouble();
                        double tip = (data['tip'] ?? 0.0).toDouble();
                        String restaurant = data['restaurant'] ?? 'أوردر عام';
                        double lat = (data['latitude'] ?? 0.0).toDouble();
                        double lng = (data['longitude'] ?? 0.0).toDouble();

                        double distance = 0.0;
                        if (_currentPosition != null && lat != 0.0 && lng != 0.0) {
                          distance = _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: distance > 0 ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            child: Icon(distance > 0 ? Icons.navigation : Icons.check_circle, color: distance > 0 ? Colors.blueAccent : Colors.greenAccent),
                          ),
                          title: Text(restaurant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                          subtitle: Text(
                            distance > 0 
                                ? "توصيل: $fee ج.م | يبعد: ${distance.toStringAsFixed(1)} كم"
                                : "توصيل: $fee ج.م | تيب: $tip ج.م",
                            style: const TextStyle(color: Colors.white70),
                            textDirection: TextDirection.rtl,
                          ),
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
        label: const Text("تسجيل أوردر", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
