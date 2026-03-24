import 'package:flutter/material.dart';

class AdvancedNfcScreen extends StatelessWidget {
  const AdvancedNfcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Advanced NFC Commands', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'Advanced NFC Commands functionality Coming Soon',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
