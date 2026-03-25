import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class ReadMemoryScreen extends StatefulWidget {
  const ReadMemoryScreen({super.key});

  @override
  State<ReadMemoryScreen> createState() => _ReadMemoryScreenState();
}

class _ReadMemoryScreenState extends State<ReadMemoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, dynamic>? _tagData;
  bool _isScanning = false;
  String _status = 'APPROACH TAG';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _status = 'SCANNING MEMORY';
      _tagData = null;
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        setState(() { _status = 'NFC UNAVAILABLE'; _isScanning = false; });
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          Map<String, dynamic> data = {
            'id': tag.handle.toString(),
            'technologies': tag.data.keys.join(", ").toUpperCase(),
          };

          if (ndef != null) {
            data['maxSize'] = '${ndef.maxSize} Bytes';
            data['isWritable'] = ndef.isWritable ? 'Yes' : 'No (Locked)';
            try {
              final message = await ndef.read();
              data['currentSize'] = '${message.byteLength} Bytes';
              
              List<String> types = [];
              for (var record in message.records) {
                if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
                  final type = String.fromCharCodes(record.type);
                  if (type == 'U') types.add('URL');
                  else if (type == 'T') types.add('TEXT');
                  else types.add('WELL-KNOWN');
                } else if (record.typeNameFormat == NdefTypeNameFormat.media) {
                  final type = String.fromCharCodes(record.type);
                  if (type == 'text/vcard') types.add('CONTACT');
                  else types.add('MIME');
                } else {
                  types.add('UNKNOWN');
                }
              }
              
              String typeString = types.isEmpty ? "None" : (types.length > 2 ? "${types.take(2).join(", ")} +..." : types.join(", "));
              data['recordCount'] = '${message.records.length} ($typeString)';
            } catch (_) {
              data['currentSize'] = '0 Bytes';
              data['recordCount'] = '0 Records';
            }
          } else {
            data['maxSize'] = 'Not Supported';
            data['isWritable'] = 'Unsupported';
            data['currentSize'] = '0 Bytes';
            data['recordCount'] = 'None';
          }

          await NfcManager.instance.stopSession();
          if (mounted) {
            setState(() {
              _tagData = data;
              _isScanning = false;
              _status = 'MEMORY READ';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() { _status = 'ERROR'; _isScanning = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('MEMORY ANALYSIS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3.0)),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_tagData == null) ...[
                      _buildScanningAnimation(),
                      const SizedBox(height: 50),
                      Text(_status, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4.0)),
                      const SizedBox(height: 12),
                      const Text('Hold tag near phone for analysis', style: TextStyle(color: Colors.white38)),
                    ] else ...[
                      _buildInfoCard(),
                      const SizedBox(height: 40),
                      TextButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                        label: const Text("ANALYZE AGAIN", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _buildDetailRow("IDENTIFIER", _tagData!['id'], Icons.fingerprint),
          const Divider(color: Colors.white10, height: 32),
          _buildDetailRow("TECHNOLOGIES", _tagData!['technologies'], Icons.memory),
          const Divider(color: Colors.white10, height: 32),
          _buildDetailRow("MAX CAPACITY", _tagData!['maxSize'], Icons.storage),
          const Divider(color: Colors.white10, height: 32),
          _buildDetailRow("USED SPACE", _tagData!['currentSize'], Icons.pie_chart_outline),
          const Divider(color: Colors.white10, height: 32),
          _buildDetailRow("RECORDS FOUND", _tagData!['recordCount'], Icons.list_alt_rounded),
          const Divider(color: Colors.white10, height: 32),
          _buildDetailRow("WRITABLE", _tagData!['isWritable'], Icons.edit_note),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
            ],
          ),
        ),
      ],
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
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.1 * (1 - _controller.value)), width: 2),
            ),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.03),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          child: const Center(child: Icon(Icons.analytics_outlined, size: 70, color: Colors.white)),
        ),
      ],
    );
  }
}
