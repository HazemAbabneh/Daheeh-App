import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  const SettingsPage({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('تبديل الوضع (Dark/Light)'),
              onTap: toggleTheme,
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('المطور: حازم'),
            ),
          ],
        ),
      ),
    );
  }
}
