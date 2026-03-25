import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';

class EraseTagScreen extends StatefulWidget {
  const EraseTagScreen({super.key});

  @override
  State<EraseTagScreen> createState() => _EraseTagScreenState();
}

class _EraseTagScreenState extends State<EraseTagScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _status = 'APPROACH TAG';
  String _hint = 'Hold tag near phone to erase';
  bool _isWriting = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startEraseSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startEraseSession() async {
    if (_isWriting) return;
    setState(() {
      _isWriting = true;
      _status = 'APPROACH TAG';
      _hint = 'Hold tag near phone to erase';
      _success = false;
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() {
          _status = 'NFC UNAVAILABLE';
          _isWriting = false;
        });
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              setState(() => _hint = 'Tag not supported');
              throw Exception("Tag is not NDEF compatible");
            }
            if (!ndef.isWritable) {
              setState(() => _hint = 'Tag is read-only');
              throw Exception("Tag is not writable");
            }

            // To erase, we write a single empty NDEF record
            // Some platforms require at least one record
            final emptyMessage = NdefMessage([
              NdefRecord(
                typeNameFormat: NdefTypeNameFormat.empty,
                type: Uint8List(0),
                payload: Uint8List(0),
                identifier: Uint8List(0),
              ),
            ]);
            await ndef.write(emptyMessage);
            
            await NfcManager.instance.stopSession();
            if (mounted) {
              setState(() {
                _status = 'ERASE COMPLETE';
                _hint = 'Tag is now empty';
                _isWriting = false;
                _success = true;
              });
            }
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            if (mounted) {
              setState(() {
                _status = 'ERASE FAILED';
                _hint = e.toString();
                _isWriting = false;
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'ERROR';
          _hint = e.toString();
          _isWriting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ERASE TAG', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.5,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScanningAnimation(),
            const SizedBox(height: 60),
            Text(
              _status,
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: _success ? Colors.greenAccent : (_status == 'ERASE FAILED' ? Colors.redAccent : Colors.white), 
                letterSpacing: 4.0
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
              child: Text(
                _hint,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white60, letterSpacing: 1.0),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            if (!_isWriting)
              TextButton.icon(
                onPressed: _startEraseSession,
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                label: const Text("TRY AGAIN", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
            width: 260 * _controller.value,
            height: 260 * _controller.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: (_success ? Colors.greenAccent : const Color(0xFF38BDF8)).withOpacity(0.1 * (1 - _controller.value)), width: 2),
            ),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.03),
            boxShadow: [
              BoxShadow(color: (_success ? Colors.greenAccent : Colors.white).withOpacity(0.05), blurRadius: 40, spreadRadius: 5),
              BoxShadow(color: (_success ? Colors.greenAccent : const Color(0xFF38BDF8)).withOpacity(0.1), blurRadius: 20),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          child: Center(
            child: Icon(
              _success ? Icons.check_circle_outline : Icons.auto_delete_outlined, 
              size: 70, 
              color: _success ? Colors.greenAccent : Colors.white
            ),
          ),
        ),
      ],
    );
  }
}
