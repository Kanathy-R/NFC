import 'package:flutter/material.dart';

class FormatMemoryScreen extends StatelessWidget {
  const FormatMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Format Memory', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'Format Memory functionality Coming Soon',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
