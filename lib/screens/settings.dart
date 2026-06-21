import 'package:flutter/material.dart';
import '../widgets/glass_box.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات والملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassBox(
            padding: const EdgeInsets.all(15),
            borderColor: Colors.greenAccent.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('كابتن عبدالله', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('حالة الإعدادات الشخصية', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                  ],
                ),
                const SizedBox(width: 15),
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 35, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassBox(
            padding: const EdgeInsets.all(15),
            borderColor: Colors.greenAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('متصل (توهج أخضر)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text('حالة المزامنة: ', style: TextStyle(color: Colors.white)),
                    Icon(Icons.sync, color: Colors.greenAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _buildSettingsTile('تفضيلات الخريطة', Icons.map_outlined),
          const SizedBox(height: 15),
          _buildSettingsTile('سمات التطبيق', Icons.color_lens_outlined),
          const SizedBox(height: 15),
          _buildSettingsTile('السجل الكامل', Icons.history_edu),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon) {
    return GlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 16),
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(width: 15),
              Icon(icon, color: Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }
}
