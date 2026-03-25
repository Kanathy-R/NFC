import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:typed_data';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

class WriteWifiScreen extends StatefulWidget {
  final bool isAddingRecord;
  const WriteWifiScreen({super.key, this.isAddingRecord = false});

  @override
  State<WriteWifiScreen> createState() => _WriteWifiScreenState();
}

class _WriteWifiScreenState extends State<WriteWifiScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _authType = 'WPA/WPA2-Personal';
  String _encryption = 'AES/TKIP';
  bool _isWriting = false;

  final List<String> _authTypes = [
    'WPA/WPA2-Personal',
    'WPA-Personal',
    'WEP',
    'Open (No Security)',
  ];

  final List<String> _encryptionTypes = ['AES/TKIP', 'AES', 'TKIP', 'None'];

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Scan nearby Wi-Fi networks
  Future<void> _scanWifi() async {
    bool canScan = await Permission.location.request().isGranted;
    if (!canScan) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission required to scan WiFi"),
          ),
        );
      return;
    }

    final result = await WiFiScan.instance.startScan();
    if (result != CanStartScan.yes) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Cannot start scan: $result")));
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
    final accessPoints = await WiFiScan.instance.getScannedResults();

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text(
                "Select WiFi",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accessPoints.length,
                  itemBuilder: (context, index) {
                    final ap = accessPoints[index];
                    return ListTile(
                      title: Text(
                        ap.ssid,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Strength: ${ap.level} dBm",
                        style: const TextStyle(color: Colors.white38),
                      ),
                      onTap: () {
                        setState(() => _ssidController.text = ap.ssid);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
      );
    }
  }

  // Build Wi-Fi payload for NFC
  Uint8List _buildWscPayload(
    String ssid,
    String password,
    String auth,
    String encr,
  ) {
    BytesBuilder builder = BytesBuilder();
    builder.add([0x10, 0x4A, 0x00, 0x01, 0x10]); // Version
    BytesBuilder credBuilder = BytesBuilder();
    credBuilder.add([0x10, 0x26, 0x00, 0x01, 0x01]); // Index
    List<int> ssidBytes = ssid.codeUnits;
    credBuilder.add([0x10, 0x45, 0x00, ssidBytes.length, ...ssidBytes]);

    int authVal = 0x0022;
    if (auth.contains('Open'))
      authVal = 0x0001;
    else if (auth == 'WEP')
      authVal = 0x0002;
    credBuilder.add([
      0x10,
      0x03,
      0x00,
      0x02,
      (authVal >> 8) & 0xFF,
      authVal & 0xFF,
    ]);

    int encrVal = 0x000C;
    if (encr == 'None')
      encrVal = 0x0001;
    else if (encr == 'AES')
      encrVal = 0x0008;
    else if (encr == 'TKIP')
      encrVal = 0x0004;
    credBuilder.add([
      0x10,
      0x0F,
      0x00,
      0x02,
      (encrVal >> 8) & 0xFF,
      encrVal & 0xFF,
    ]);

    List<int> passBytes = password.codeUnits;
    credBuilder.add([0x10, 0x27, 0x00, passBytes.length, ...passBytes]);
    credBuilder.add([
      0x10,
      0x20,
      0x00,
      0x06,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
      0xFF,
    ]);

    Uint8List credData = credBuilder.toBytes();
    builder.add([0x10, 0x0E, 0x00, credData.length, ...credData]);
    return builder.toBytes();
  }

  Future<void> writeWifiToNfc() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SSID cannot be empty")));
      return;
    }

    final wifiPayload = _buildWscPayload(ssid, password, _authType, _encryption);

    // If just adding record to batch writing list, return immediately!
    if (widget.isAddingRecord) {
      Navigator.pop(context, {
        'type': 'WiFi',
        'data': ssid,
        'payload': wifiPayload,
        'size': wifiPayload.length,
      });
      return;
    }

    // Otherwise, start NFC session to write directly to tag
    setState(() => _isWriting = true);
    
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) throw Exception("NFC not available");

      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable)
              throw Exception("Tag not writable");

            await ndef.write(
              NdefMessage([
                NdefRecord.createMime('application/vnd.wfa.wsc', wifiPayload),
              ]),
            );
            await NfcManager.instance.stopSession();

            if (mounted) {
              setState(() => _isWriting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ WiFi Configured!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            if (mounted) setState(() => _isWriting = false);
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isWriting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Wi-Fi network',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildDropdown(
              'Authentication',
              _authType,
              _authTypes,
              (val) => setState(() => _authType = val!),
            ),
            const SizedBox(height: 20),
            _buildDropdown(
              'Encryption',
              _encryption,
              _encryptionTypes,
              (val) => setState(() => _encryption = val!),
            ),
            const SizedBox(height: 20),
            _buildSSIDField(),
            const SizedBox(height: 20),
            if (_authType != 'Open (No Security)')
              _buildTextField(
                'Password',
                'Enter network password',
                _passwordController,
                Icons.lock_outline,
                isPassword: true,
              ),
            const SizedBox(height: 50),
            _buildWriteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSSIDField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SSID',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ssidController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Your SSID',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _scanWifi,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              items:
                  items
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWriteButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [const Color(0xFF38BDF8), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isWriting ? null : writeWifiToNfc,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child:
            _isWriting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
      ),
    );
  }
}
