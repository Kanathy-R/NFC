import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteWifiScreen extends StatefulWidget {
  final bool isAddingRecord;
  const WriteWifiScreen({super.key, this.isAddingRecord = false});

  @override
  State<WriteWifiScreen> createState() => _WriteWifiScreenState();
}

class _WriteWifiScreenState extends State<WriteWifiScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSecure = true;
  bool _isWriting = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> writeWifiToNfc() async {
    String ssid = _ssidController.text.trim();
    String password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SSID cannot be empty")));
      return;
    }

    if (widget.isAddingRecord) {
      String wifiData = "WIFI:T:WPA;S:$ssid;P:$password;;";
      Navigator.pop(context, {
        'type': 'WiFi',
        'data': ssid,
        'fullData': wifiData,
        'size': wifiData.length + 5,
      });
      return;
    }

    setState(() => _isWriting = true);

    try {
      bool available = await NfcManager.instance.isAvailable();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("NFC is not available on this device")),
        );
        setState(() => _isWriting = false);
        return;
      }

      // NFC session
      await NfcManager.instance.startSession(
        alertMessage: "Hold your phone near the NFC tag",
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) throw Exception("NDEF not supported on this tag");
            if (!ndef.isWritable) throw Exception("Tag is not writable");

            // WiFi NDEF payload
            String wifiData = "WIFI:T:WPA;S:$ssid;P:$password;;";

            final message = NdefMessage([NdefRecord.createText(wifiData)]);

            await ndef.write(message);
            await NfcManager.instance.stopSession();
            setState(() => _isWriting = false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ WiFi credentials written to NFC tag"),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ NFC Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Add WiFi Network',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'Network Name (SSID)',
                'Enter WiFi Name',
                _ssidController,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                'Password',
                'Enter WiFi Password',
                _passwordController,
                obscure: _isSecure,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: !_isSecure,
                    onChanged: (val) {
                      setState(() {
                        _isSecure = !(val ?? false);
                      });
                    },
                    activeColor: const Color(0xFF38BDF8),
                  ),
                  const Text(
                    'Show Password',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)], // Sky Blue to Indigo
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
                  onPressed: _isWriting ? null : writeWifiToNfc,
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
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
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
        ),
      ],
    );
  }
}
