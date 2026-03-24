import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WritePhoneScreen extends StatefulWidget {
  final bool isAddingRecord;
  const WritePhoneScreen({super.key, this.isAddingRecord = false});

  @override
  State<WritePhoneScreen> createState() => _WritePhoneScreenState();
}

class _WritePhoneScreenState extends State<WritePhoneScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isWriting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 🔹 Pick contact from phone
  Future<void> pickContact() async {
    try {
      PermissionStatus status = await Permission.contacts.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Contacts permission denied")),
          );
        }
        return;
      }

      final contact = await ContactsService.openDeviceContactPicker();
      if (contact != null) {
        setState(() {
          _nameController.text = contact.displayName ?? "";
          _phoneController.text =
              contact.phones!.isNotEmpty ? contact.phones!.first.value ?? "" : "";
        });
      }
    } catch (e, stackTrace) {
      print('Error picking contact: $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error selecting contact: $e")));
      }
    }
  }

  // 🔹 Write contact to NFC tag
  Future<void> writeContact() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number")),
      );
      return;
    }

    String telUri = "tel:$phone";

    if (widget.isAddingRecord) {
      Navigator.pop(context, {
        'type': 'Phone',
        'data': phone,
        'fullData': telUri,
        'size': telUri.length + 5,
      });
      return;
    }

    setState(() => _isWriting = true);

    NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) throw Exception("NDEF not supported on this tag");
          if (!ndef.isWritable) throw Exception("Tag is not writable");

          final message = NdefMessage([NdefRecord.createUri(Uri.parse(telUri))]);

          await ndef.write(message);
          await NfcManager.instance.stopSession();

          if (mounted) {
            setState(() => _isWriting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Phone number written to NFC tag")),
            );
          }
        } catch (e) {
          await NfcManager.instance.stopSession();
          if (mounted) {
            setState(() => _isWriting = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Write Phone Number',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Phone Input Field
            const Text(
              "Mobile Number",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF38BDF8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 Or Pick From Contacts ボタン
            Center(
              child: TextButton.icon(
                onPressed: pickContact,
                icon: const Icon(Icons.contact_page_outlined, color: Color(0xFF38BDF8)),
                label: const Text(
                  "Choose from contacts",
                  style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                ),
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
                onPressed: _isWriting ? null : writeContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isWriting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
