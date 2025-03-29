import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: const Center(
        child: Text(
          'شاشة الإعدادات (سيتم التنفيذ لاحقاً)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
