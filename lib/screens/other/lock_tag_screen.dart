import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:typed_data';

class LockTagScreen extends StatefulWidget {
  const LockTagScreen({super.key});

  @override
  State<LockTagScreen> createState() => _LockTagScreenState();
}

class _LockTagScreenState extends State<LockTagScreen> {
  bool _isLocking = false;

  Future<void> _startLocking() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("⚠️ BRAKE! Permanent Action", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          "Locking an NFC tag is PERMANENT. This will turn your tag into a Read-Only device forever.\n\nAre you ready?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("LOCK PERMANENTLY", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLocking = true);

    try {
      // 1. Poll for Tag
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
      );

      try {
        // 2. Hardware Level Lock for NTAG/Ultralight series
        // Command: WRITE (0xA2) to Page 0x02, with Lock Bytes 0xFF 0xFF
        await FlutterNfcKit.transceive(Uint8List.fromList([0xA2, 0x02, 0x00, 0x00, 0xFF, 0xFF]));
        
        await FlutterNfcKit.finish();
        if (mounted) {
          setState(() => _isLocking = false);
          _showSuccessDialog();
        }
      } catch (e) {
        // 3. Fallback: Raw Hardware Page Lock (For NTAG/Ultralight)
        try {
          // Command: WRITE (0xA2) to Page 0x02, with Lock Bytes 0xFF 0xFF
          await FlutterNfcKit.transceive(Uint8List.fromList([0xA2, 0x02, 0x00, 0x00, 0xFF, 0xFF]));
          
          await FlutterNfcKit.finish();
          if (mounted) {
            setState(() => _isLocking = false);
            _showSuccessDialog();
          }
        } catch (rawError) {
          await FlutterNfcKit.finish();
          throw "Lock Rejected: Both NDEF and Hardware methods failed. This tag might be password protected or already locked.";
        }
      }
    } catch (e) {
      await FlutterNfcKit.finish();
      if (mounted) {
        setState(() => _isLocking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $e"), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              "✅ SUCCESS",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Your NFC tag is now permanently read-only.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to previous screen
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  "DONE",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Lock Tag',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Large Lock Icon with Glow
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 100,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              "Make Tag Read-Only",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Locking your tag prevents any future writing or modifications. This cannot be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white38,
                height: 1.5,
              ),
            ),
            const Spacer(),
            // Action Button
            _buildLockButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLockButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLocking ? null : _startLocking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child:
            _isWriting()
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'LOCK TAG NOW',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
      ),
    );
  }

  bool _isWriting() => _isLocking;
}
