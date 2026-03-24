import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'db_helper.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  String tagData = "Waiting for NFC tag...";
  bool isScanning = false;

  @override
  void initState() {
    super.initState();

    // 🔵 Animated circle controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 🔥 Auto scan start
    startNFCScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> startNFCScan() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      tagData = "Ready to Scan";
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() {
          tagData = "NFC not available";
          isScanning = false;
        });
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          String result = "Tag ID: ${tag.handle}\n";
          final ndef = Ndef.from(tag);

          if (ndef != null) {
            final message = await ndef.read();
            for (var record in message.records) {
              final payload = String.fromCharCodes(record.payload);
              result += "\nPayload: $payload";
            }
          } else {
            result += "\nNDEF not available";
          }

          // Save to DB
          await DBHelper.insertTag(tag.handle.toString(), result);

          setState(() {
            tagData = result;
            isScanning = false;
          });
          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      setState(() {
        tagData = "Error: $e";
        isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF0F172A),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔵 Layered Animated Scanning Circles
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 280 * _controller.value,
                      height: 280 * _controller.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1 * (1 - _controller.value)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                // Middle Pulse
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double val = (_controller.value + 0.5) % 1.0;
                    return Container(
                      width: 240 * val,
                      height: 240 * val,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withOpacity(0.15 * (1 - val)),
                          width: 4,
                        ),
                      ),
                    );
                  },
                ),
                // Core Circle
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.nfc,
                          size: 60,
                          color: Colors.white,
                        ),
                        if (isScanning)
                          const SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              color: Color(0xFF38BDF8),
                              minHeight: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            Text(
              isScanning ? 'SCANNING' : 'READY TO READ',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4.0,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Hold tag near phone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ✅ Display tag data
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                tagData,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
