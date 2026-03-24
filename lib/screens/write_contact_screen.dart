import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WriteContactScreen extends StatefulWidget {
  final bool isAddingRecord;
  const WriteContactScreen({super.key, this.isAddingRecord = false});

  @override
  State<WriteContactScreen> createState() => _WriteContactScreenState();
}

class _WriteContactScreenState extends State<WriteContactScreen> {
  Contact? selectedContact;
  bool _isWriting = false;

  // 🔹 Pick contact from phone
  Future<void> pickContact() async {
    try {
      PermissionStatus status = await Permission.contacts.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contacts permission denied")),
        );
        return;
      }

      final contact = await ContactsService.openDeviceContactPicker();
      if (contact != null) {
        setState(() => selectedContact = contact);
      }
    } catch (e, stackTrace) {
      print('Error picking contact: $e');
      print(stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error selecting contact: $e")));
    }
  }

  // 🔹 Write selected contact to NFC tag
  Future<void> writeContact() async {
    if (selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a contact first")),
      );
      return;
    }

    String name = selectedContact!.displayName ?? "No Name";
    String phone = selectedContact!.phones!.isNotEmpty ? selectedContact!.phones!.first.value ?? "" : "";
    String vCard = "BEGIN:VCARD\nVERSION:3.0\nFN:$name\nTEL:$phone\nEND:VCARD";

    if (widget.isAddingRecord) {
      Navigator.pop(context, {
        'type': 'Contact',
        'data': name,
        'fullData': vCard,
        'size': vCard.length + 10,
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

          String name = selectedContact!.displayName ?? "No Name";
          String phone =
              selectedContact!.phones!.isNotEmpty
                  ? selectedContact!.phones!.first.value ?? ""
                  : "";

          // vCard format
          String vCard = '''
BEGIN:VCARD
VERSION:3.0
FN:$name
TEL:$phone
END:VCARD
''';

          final message = NdefMessage([NdefRecord.createText(vCard)]);

          await ndef.write(message);
          await NfcManager.instance.stopSession();

          setState(() => _isWriting = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Contact written to NFC tag")),
          );
        } catch (e) {
          await NfcManager.instance.stopSession();
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
        title: const Text(
          'Write Contact',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickContact,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedContact == null
                        ? Colors.white12
                        : const Color(0xFF38BDF8).withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedContact == null
                            ? Colors.white12
                            : const Color(0xFF38BDF8).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selectedContact == null ? Icons.person_add : Icons.person,
                        color: selectedContact == null ? Colors.white54 : const Color(0xFF38BDF8),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedContact == null ? 'Select Contact' : 'Selected Contact',
                            style: TextStyle(
                              color: selectedContact == null ? Colors.white54 : const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedContact == null
                                ? 'Tap to choose from phone'
                                : (selectedContact!.displayName ?? 'Unknown Name'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: selectedContact == null ? 16 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (selectedContact != null)
                      const Icon(Icons.check_circle, color: Color(0xFF38BDF8)),
                  ],
                ),
              ),
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
