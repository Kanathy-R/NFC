import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'write_url_screen.dart';
import 'write_text_screen.dart';
import 'write_phone_screen.dart';
import 'write_contact_screen.dart';
import 'write_wifi_screen.dart';
import 'record_selection_screen.dart';
import 'dart:typed_data';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final List<Map<String, dynamic>> _records = [];
  bool _isWriting = false;

  void _addRecord(Map<String, dynamic> record) {
    setState(() {
      _records.add(record);
    });
  }

  void _removeRecord(int index) {
    setState(() {
      _records.removeAt(index);
    });
  }

  Future<void> _writeAllToNfc() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one record first")),
      );
      return;
    }

    setState(() => _isWriting = true);

    // Show a bottom sheet or dialog to indicate that the phone is ready to write
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.contactless_outlined, size: 80, color: Color(0xFF38BDF8)),
              const SizedBox(height: 24),
              const Text(
                "READY TO WRITE",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                "Approach an NFC Tag to start writing.",
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await NfcManager.instance.stopSession();
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _isWriting = false);
                    }
                  },
                  child: const Text("CANCEL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        if (mounted) Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NFC not available on this device")),
        );
        setState(() => _isWriting = false);
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw Exception("Tag is not writable or doesn't support NDEF");
            }

            List<NdefRecord> ndefRecords = [];
            for (var rec in _records) {
              final type = rec['type'];
              final data = rec['data'];
              final fullData = rec['fullData'] ?? data;

              if (type == 'Text') {
                ndefRecords.add(NdefRecord.createText(data));
              } else if (type == 'URL') {
                ndefRecords.add(NdefRecord.createUri(Uri.parse(fullData)));
              } else if (type == 'Phone') {
                ndefRecords.add(NdefRecord.createUri(Uri.parse(fullData)));
              } else if (type == 'WiFi') {
                if (rec.containsKey('payload')) {
                  ndefRecords.add(NdefRecord.createMime('application/vnd.wfa.wsc', rec['payload'] as Uint8List));
                } else {
                  ndefRecords.add(NdefRecord.createText(fullData));
                }
              } else if (type == 'Contact') {
                // vCard format - use MIME type for universal native support
                ndefRecords.add(NdefRecord.createMime('text/vcard', Uint8List.fromList(fullData.codeUnits)));
              }
            }

            await ndef.write(NdefMessage(ndefRecords));
            await NfcManager.instance.stopSession();

            if (mounted) {
              Navigator.pop(context); // Close bottom sheet
              setState(() => _isWriting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("✅ Successfully written to NFC tag!"),
                    backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            if (mounted) {
              Navigator.pop(context); // Close bottom sheet
              setState(() => _isWriting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.redAccent),
              );
            }
          }
        },
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close bottom sheet
      setState(() => _isWriting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error starting NFC: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BATCH WRITING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF38BDF8),
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'NFC Tag Composer',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          // Main Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildPrimaryAction(
                  icon: Icons.add_rounded,
                  label: "ADD RECORD",
                  color: const Color(0xFF38BDF8),
                  textColor: Colors.white,
                  onTap: () => _showAddRecordOptions(context),
                  isGlass: true,
                ),
              ),
              if (_records.isNotEmpty) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPrimaryAction(
                    icon: Icons.flash_on_rounded,
                    label: "WRITE TAG",
                    color: const Color(0xFF6366F1),
                    textColor: Colors.white,
                    onTap: _isWriting ? null : _writeAllToNfc,
                    isGlass: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _buildSizeIndicator(),
          const SizedBox(height: 32),
          const Text(
            'ACTIVE RECORDS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 2.0),
          ),
          const SizedBox(height: 16),
          // List of records
          Expanded(
            child: _records.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final rec = _records[index];
                      return _buildRecordTile(rec, index);
                    },
                  ),
          ),
          const SizedBox(height: 100), // Spacing for Bottom Bar
        ],
      ),
    );
  }

  Widget _buildPrimaryAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
    required bool isGlass,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isGlass ? Colors.white.withOpacity(0.05) : color,
          borderRadius: BorderRadius.circular(20),
          border: isGlass ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            if (!isGlass)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isGlass ? color : textColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isGlass ? Colors.white : textColor,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeIndicator() {
    int size = _calculateSize();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Memory Forecast:", style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            "$size Bytes Used",
            style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text(
            "Composition is empty",
            style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> rec, int index) {
    IconData icon;
    switch (rec['type']) {
      case 'URL': icon = Icons.link_rounded; break;
      case 'Text': icon = Icons.text_fields_rounded; break;
      case 'Contact': icon = Icons.person_rounded; break;
      case 'Phone': icon = Icons.phone_rounded; break;
      case 'WiFi': icon = Icons.wifi_password_rounded; break;
      default: icon = Icons.token_rounded;
    }

    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (rec['type'] == 'Phone' ? 'Phone Number' : rec['type']).toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                ),
                Text(
                  rec['data'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
            onPressed: () => _removeRecord(index),
          ),
        ],
      ),
    );
  }

  int _calculateSize() {
    int size = 0;
    for (var r in _records) {
      size += (r['size'] as int);
    }
    return size;
  }

  void _showAddRecordOptions(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordSelectionScreen()),
    );

    if (result != null && mounted) {
      _addRecord(result as Map<String, dynamic>);
    }
  }

  Widget _buildModalOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF38BDF8)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

