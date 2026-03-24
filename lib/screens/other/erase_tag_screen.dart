import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class EraseTagScreen extends StatefulWidget {
  const EraseTagScreen({super.key});

  @override
  State<EraseTagScreen> createState() => _EraseTagScreenState();
}

class _EraseTagScreenState extends State<EraseTagScreen> {
  String _status = 'Tap "Erase Tag" and place your device near the NFC tag';

  Future<void> _eraseTag() async {
    setState(() {
      _status = 'Scanning for NFC tag...';
    });

    try {
      // Poll for a tag
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
      );

      setState(() {
        _status = 'Tag found! Erasing...';
      });

      // Check if NDEF is available
      if (tag.ndefAvailable ?? false) {
        // Write an empty NDEF message to erase content
        await FlutterNfcKit.writeNDEFRecords([]);
        setState(() {
          _status = 'Tag erased successfully ✅';
        });
      } else {
        setState(() {
          _status = 'This tag does not support NDEF ❌';
        });
      }

      // Finish NFC session
      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Erase Tag', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _eraseTag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Erase Tag',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
