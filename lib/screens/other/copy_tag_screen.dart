import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class CopyTagScreen extends StatefulWidget {
  const CopyTagScreen({super.key});

  @override
  State<CopyTagScreen> createState() => _CopyTagScreenState();
}

class _CopyTagScreenState extends State<CopyTagScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _status = 'READY TO COPY';
  String _hint = 'Tap button to start';
  int _step = 0; // 0: Idle, 1: Reading Source, 2: Writing Target, 3: Success
  bool _isProcessing = false;
  NdefMessage? _cachedMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startCopyProcess() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _step = 1;
      _status = 'STEP 1: READING';
      _hint = 'Hold the ORIGIN tag near phone';
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() {
          _status = 'NFC UNAVAILABLE';
          _isProcessing = false;
          _step = 0;
        });
        return;
      }

      // --- STEP 1: READ ---
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await NfcManager.instance.stopSession(errorMessage: "Tag not supported");
            setState(() {
              _status = 'TAG NOT SUPPORTED';
              _isProcessing = false;
              _step = 0;
            });
            return;
          }

          _cachedMessage = await ndef.read();
          await NfcManager.instance.stopSession();
          
          if (mounted) {
            setState(() {
              _step = 2;
              _status = 'STEP 2: WRITING';
              _hint = 'Now hold the TARGET tag near phone';
            });
            
            // Short delay before starting next session
            await Future.delayed(const Duration(milliseconds: 1000));
            _startWritingProcess();
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() { _status = 'ERROR'; _hint = e.toString(); _isProcessing = false; _step = 0; });
    }
  }

  Future<void> _startWritingProcess() async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            await NfcManager.instance.stopSession(errorMessage: "Target tag not writable");
            setState(() { _status = 'WRITE FAILED'; _hint = 'Tag is not writable'; _isProcessing = false; _step = 0; });
            return;
          }

          if (_cachedMessage != null) {
            await ndef.write(_cachedMessage!);
            await NfcManager.instance.stopSession();
            
            if (mounted) {
              setState(() {
                _step = 3;
                _status = 'COPY SUCCESSFUL';
                _hint = 'Tag has been cloned';
                _isProcessing = false;
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() { _status = 'WRITE ERROR'; _hint = e.toString(); _isProcessing = false; _step = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('CLONE TAG', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3.0)),
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
            _buildVisualState(),
            const SizedBox(height: 60),
            Text(
              _status,
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: _step == 3 ? Colors.greenAccent : (_step == 0 && _status.contains('FAILED') ? Colors.redAccent : Colors.white), 
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
            const SizedBox(height: 60),
            if (!_isProcessing)
              _buildMainButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualState() {
    IconData icon;
    Color color;
    switch(_step) {
      case 1: icon = Icons.download_rounded; color = const Color(0xFF38BDF8); break;
      case 2: icon = Icons.upload_rounded; color = Colors.orangeAccent; break;
      case 3: icon = Icons.check_circle_outline; color = Colors.greenAccent; break;
      default: icon = Icons.copy_all_rounded; color = Colors.white24;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isProcessing)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Container(
              width: 260 * _controller.value,
              height: 260 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.1 * (1 - _controller.value)), width: 2),
              ),
            ),
          ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.05), blurRadius: 40, spreadRadius: 5),
            ],
          ),
          child: Center(
            child: Icon(icon, size: 70, color: _step == 0 ? Colors.white38 : color),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: 220,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: _step == 3 ? [Colors.green, Colors.teal] : [const Color(0xFF38BDF8), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _startCopyProcess,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          _step == 3 ? 'COPY ANOTHER' : 'START CLONING',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
