import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteUrlScreen extends StatefulWidget {
  final bool isAddingRecord;
  const WriteUrlScreen({super.key, this.isAddingRecord = false});

  @override
  State<WriteUrlScreen> createState() => _WriteUrlScreenState();
}

class _WriteUrlScreenState extends State<WriteUrlScreen> {
  final TextEditingController _urlController = TextEditingController();

  final List<String> _protocols = [
    'https://',
    'http://',
    'ftp://',
    'sftp://',
    'smb://',
    'mailto:',
    'tel:',
    'sms:',
  ];

  String _selectedProtocol = 'https://';
  bool _isWriting = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> writeToNFC() async {
    String fullUrl = "$_selectedProtocol${_urlController.text.trim()}";

    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter URL first")));
      return;
    }

    if (widget.isAddingRecord) {
      Navigator.pop(context, {
        'type': 'URL',
        'data': fullUrl,
        'size': fullUrl.length + 1, // Basic approximation
      });
      return;
    }

    setState(() => _isWriting = true);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);

          if (ndef == null || !ndef.isWritable) {
            throw Exception("Tag is not writable");
          }

          NdefMessage message = NdefMessage([
            NdefRecord.createUri(Uri.parse(fullUrl)),
          ]);

          await ndef.write(message);

          NfcManager.instance.stopSession();

          setState(() => _isWriting = false);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("✅ URL Written Successfully")));
        } catch (e) {
          NfcManager.instance.stopSession();

          setState(() => _isWriting = false);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Write URL', style: TextStyle(color: Colors.white)),
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
              'Select protocol & enter web address:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
            const SizedBox(height: 12),

            // 🔗 URL INPUT
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {});
              },
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProtocol,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF38BDF8),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      items:
                          _protocols.map((String protocol) {
                            return DropdownMenuItem<String>(
                              value: protocol,
                              child: Text(protocol),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedProtocol = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: 'example.com',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 12),

            // 🔍 LIVE PREVIEW
            Text(
              'Final URI: $_selectedProtocol${_urlController.text}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 40),

            // 🚀 WRITE BUTTON
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
                onPressed: _isWriting ? null : writeToNFC,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child:
                    _isWriting
                        ? const CircularProgressIndicator(color: Colors.white)
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
