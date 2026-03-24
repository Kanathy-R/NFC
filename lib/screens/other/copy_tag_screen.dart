import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class CopyTagScreen extends StatefulWidget {
  const CopyTagScreen({super.key});

  @override
  State<CopyTagScreen> createState() => _CopyTagScreenState();
}

class _CopyTagScreenState extends State<CopyTagScreen> {
  String status = "Ready to Copy";
  bool _isCopying = false;
  NdefMessage? _cachedMessage;

  Future<void> _startCopy() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NFC is not available on this device")),
      );
      return;
    }

    setState(() {
      _isCopying = true;
      status = "Step 1: Scan Source Tag";
    });

    try {
      // Step 1: Read Source Tag
      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession(errorMessage: "Tag not NDEF compatible");
            setState(() {
              status = "Source tag is not NDEF compatible";
              _isCopying = false;
            });
            return;
          }

          _cachedMessage = await ndef.read();
          await NfcManager.instance.stopSession();

          setState(() {
            status = "Step 2: Scan Target Tag";
          });

          // Step 2: Write to Target Tag
          await Future.delayed(const Duration(milliseconds: 500));
          await _writeToTarget();
        },
      );
    } catch (e) {
      setState(() {
        _isCopying = false;
        status = "Error: $e";
      });
    }
  }

  Future<void> _writeToTarget() async {
    await NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            await NfcManager.instance.stopSession(errorMessage: "Tag not writable");
            setState(() {
              status = "Target tag is not writable";
              _isCopying = false;
            });
            return;
          }

          if (_cachedMessage != null) {
            await ndef.write(_cachedMessage!);
            await NfcManager.instance.stopSession();
            setState(() {
              status = "✅ Successfully copied!";
              _isCopying = false;
              _cachedMessage = null;
            });
          }
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: e.toString());
          setState(() {
            _isCopying = false;
            status = "Error writing: $e";
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Copy Tag', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCopying ? Icons.sensors : Icons.copy_all,
              size: 80,
              color: const Color(0xFF38BDF8),
            ),
            const SizedBox(height: 24),
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              "Place the source tag first, then replace it with the target tag.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 60),
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
                onPressed: _isCopying ? null : _startCopy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isCopying
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'Start Copy Process',
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
