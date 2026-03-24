import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteTextScreen extends StatefulWidget {
  final bool isAddingRecord;
  const WriteTextScreen({super.key, this.isAddingRecord = false});

  @override
  State<WriteTextScreen> createState() => _WriteTextScreenState();
}

class _WriteTextScreenState extends State<WriteTextScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isWriting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _writeToNFCTag() async {
    String textToWrite = _textController.text.trim();
    if (textToWrite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter text to write")),
      );
      return;
    }

    if (widget.isAddingRecord) {
      Navigator.pop(context, {
        'type': 'Text',
        'data': textToWrite,
        'size': textToWrite.length + 3, // Basic approximation
      });
      return;
    }

    setState(() {
      _isWriting = true;
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NFC is not available on this device")),
        );
        setState(() => _isWriting = false);
        return;
      }

      await NfcManager.instance.startSession(
        alertMessage: "Hold your phone near the NFC tag",
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) throw Exception("NDEF not supported on this tag");
            if (!ndef.isWritable) throw Exception("Tag is not writable");

            final message = NdefMessage([NdefRecord.createText(textToWrite)]);

            await ndef.write(message);
            await NfcManager.instance.stopSession();

            setState(() => _isWriting = false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Text written to NFC tag successfully!"),
              ),
            );
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            setState(() => _isWriting = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
          }
        },
      );
    } catch (e) {
      setState(() => _isWriting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error starting NFC session: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Write Text', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter text to write:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF38BDF8),
                    Color(0xFF6366F1),
                  ], // Sky Blue to Indigo
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
                onPressed: _isWriting ? null : _writeToNFCTag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child:
                    _isWriting
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : Text(
                            widget.isAddingRecord ? 'OK' : 'Write to NFC Tag',
                            style: const TextStyle(
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
