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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isWriting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
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
          _companyController.text = contact.company ?? "";
          _addressController.text = contact.postalAddresses?.isNotEmpty == true
              ? "${contact.postalAddresses!.first.street ?? ""}, ${contact.postalAddresses!.first.city ?? ""}"
              : "";
          _phoneController.text = contact.phones?.isNotEmpty == true ? contact.phones!.first.value ?? "" : "";
          _emailController.text = contact.emails?.isNotEmpty == true ? contact.emails!.first.value ?? "" : "";
          // Note: Website is not always available in basic contact picker, but many have it.
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _handleSave() async {
    String name = _nameController.text.trim();
    String company = _companyController.text.trim();
    String address = _addressController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String website = _websiteController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a name")));
      return;
    }

    // Build vCard 3.0 string
    String vCard = "BEGIN:VCARD\nVERSION:3.0\n";
    vCard += "FN:$name\n";
    if (company.isNotEmpty) vCard += "ORG:$company\n";
    if (address.isNotEmpty) vCard += "ADR:;;$address\n";
    if (phone.isNotEmpty) vCard += "TEL:$phone\n";
    if (email.isNotEmpty) vCard += "EMAIL:$email\n";
    if (website.isNotEmpty) vCard += "URL:$website\n";
    vCard += "END:VCARD";

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

          final message = NdefMessage([NdefRecord.createText(vCard)]);

          await ndef.write(message);
          await NfcManager.instance.stopSession();

          if (mounted) {
            setState(() => _isWriting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Contact written to NFC tag")),
            );
          }
        } catch (e) {
          await NfcManager.instance.stopSession();
          if (mounted) {
            setState(() => _isWriting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
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
        title: const Text('Add a record', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Subheader
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.black38,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white10,
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Enter your contact",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.contact_page_outlined, color: Color(0xFF38BDF8)),
                  onPressed: _pickContact,
                  tooltip: "Pick from contacts",
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildField("Contact name :", _nameController, Icons.person_outline),
                  _buildField("Company :", _companyController, Icons.business_outlined),
                  _buildField("Address :", _addressController, Icons.location_on_outlined),
                  _buildField("Phone :", _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  _buildField("Mail :", _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _buildField("Website :", _websiteController, Icons.language_outlined, keyboardType: TextInputType.url),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildBottomButton(
                    onTap: () => Navigator.pop(context),
                    icon: Icons.close,
                    label: "Cancel",
                    color: Colors.white12,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBottomButton(
                    onTap: _isWriting ? null : _handleSave,
                    icon: Icons.check,
                    label: "OK",
                    color: const Color(0xFF38BDF8).withOpacity(0.2),
                    borderColor: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({required VoidCallback? onTap, required IconData icon, required String label, required Color color, Color? borderColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: borderColor != null ? Border.all(color: borderColor) : Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
