import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'db_helper.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key});

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class ParsedNdefRecord {
  final String type;
  final String content;
  final String label;
  final IconData icon;
  final String actionLabel;
  final Future<void> Function()? onAction;

  ParsedNdefRecord({
    required this.type,
    required this.content,
    required this.label,
    required this.icon,
    required this.actionLabel,
    this.onAction,
  });
}

class _ReadScreenState extends State<ReadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<ParsedNdefRecord> parsedRecords = [];
  String tagId = "";
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    startNFCScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> startNFCScan() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      parsedRecords = [];
      tagId = "";
    });

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();

      if (!isAvailable) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("NFC not available")));
        setState(() => isScanning = false);
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          setState(() {
            tagId = tag.handle.toString(); // compatible
          });

          final ndef = Ndef.from(tag);
          List<ParsedNdefRecord> recordsList = [];

          if (ndef != null) {
            try {
              final message = await ndef.read();
              for (var record in message.records) {
                recordsList.add(_parseRecord(record));
              }
            } catch (e) {
              debugPrint("Read error: $e");
            }
          }

          // Save to DB
          try {
            String dbData =
                recordsList.isEmpty
                    ? "No Data"
                    : recordsList
                        .map((r) => "${r.type}: ${r.content}")
                        .join(" | ");

            await DBHelper.insertTag(tag.handle.toString(), dbData);
          } catch (e) {
            debugPrint("DB error: $e");
          }

          setState(() {
            parsedRecords = recordsList;
            isScanning = false;
          });

          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ✅ SAFE URL LAUNCH
  Future<void> _safeLaunch(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint("Cannot launch: $url");
      }
    } catch (e) {
      debugPrint("Launch error: $e");
    }
  }

  ParsedNdefRecord _parseRecord(NdefRecord record) {
    // ✅ FIXED ENUM (for your version)
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
      if (record.type.isEmpty) return _unknown(record);

      final type = String.fromCharCodes(record.type);

      // 🔗 URI RECORD
      if (type == 'U') {
        final payload = record.payload;
        if (payload.isEmpty) return _unknown(record);

        final prefixes = [
          "",
          "http://www.",
          "https://www.",
          "http://",
          "https://",
          "tel:",
          "mailto:",
        ];

        final prefix = payload[0] < prefixes.length ? prefixes[payload[0]] : "";

        final content = prefix + String.fromCharCodes(payload.sublist(1));

        if (content.startsWith("tel:")) {
          return ParsedNdefRecord(
            type: "Phone",
            content: content.replaceFirst("tel:", ""),
            label: "PHONE",
            icon: Icons.phone,
            actionLabel: "CALL",
            onAction: () => _safeLaunch(content),
          );
        } else if (content.startsWith("mailto:")) {
          return ParsedNdefRecord(
            type: "Email",
            content: content.replaceFirst("mailto:", ""),
            label: "EMAIL",
            icon: Icons.email,
            actionLabel: "EMAIL",
            onAction: () => _safeLaunch(content),
          );
        } else {
          return ParsedNdefRecord(
            type: "URL",
            content: content,
            label: "LINK",
            icon: Icons.link,
            actionLabel: "OPEN",
            onAction: () => _safeLaunch(content),
          );
        }
      }

      // 📄 TEXT RECORD
      if (type == 'T') {
        final payload = record.payload;
        if (payload.isEmpty) return _unknown(record);

        final langLength = payload[0] & 0x3F;

        if (payload.length < 1 + langLength) return _unknown(record);

        final content = String.fromCharCodes(payload.sublist(1 + langLength));

        return ParsedNdefRecord(
          type: "Text",
          content: content,
          label: "TEXT",
          icon: Icons.text_fields,
          actionLabel: "COPY",
        );
      }
    }

    // 📩 MEDIA / MIME RECORD (vCard compatibility)
    if (record.typeNameFormat == NdefTypeNameFormat.media) {
      final type = String.fromCharCodes(record.type);
      final payload = String.fromCharCodes(record.payload);

      if (type == 'text/vcard') {
        // Simple FN (Full Name) extraction for display
        String name = "Contact";
        if (payload.contains("FN:")) {
          name = payload.split("FN:")[1].split("\n")[0].trim();
        }
        
        return ParsedNdefRecord(
          type: "Contact",
          content: name,
          label: "CONTACT CARD",
          icon: Icons.person,
          actionLabel: "SAVE",
          // The native OS handles saving, or we could add vCard saving logic here
        );
      }
    }

    return _unknown(record);
  }

  ParsedNdefRecord _unknown(NdefRecord record) {
    return ParsedNdefRecord(
      type: "Unknown",
      content: "Unsupported data",
      label: "DATA",
      icon: Icons.data_object,
      actionLabel: "READ",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
            // 🔵 DYNAMIC SCANNING SECTION
            if (parsedRecords.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 50), // Balance for bottom nav
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildScanningAnimation(),
                      const SizedBox(height: 50),
                      Text(
                        isScanning ? 'SCANNING' : 'READY TO READ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (tagId.isNotEmpty)
                        Text(
                          "SERIAL: $tagId",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          isScanning ? 'Hold tag near phone' : 'Ready to parse records',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white60, letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 100, bottom: 40),
                  child: Column(
                    children: [
                      _buildScanningAnimation(),
                      const SizedBox(height: 30),
                      const Text(
                        'READ COMPLETE',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${parsedRecords.length} Records Found",
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: startNFCScan,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                        label: const Text("SCAN AGAIN", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

            // 📄 RECORDS LIST
            if (!isScanning && parsedRecords.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final record = parsedRecords[index];
                    return _buildRecordCard(record);
                  }, childCount: parsedRecords.length),
                ),
              ),

            // Spacing for Bottom Nav
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder:
              (context, child) => Container(
                width: 280 * _controller.value,
                height: 280 * _controller.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      0.1 * (1 - _controller.value),
                    ),
                    width: 2,
                  ),
                ),
              ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double val = (_controller.value + 0.5) % 1.0;
            return Container(
              width: 240 * val,
              height: 240 * val,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withOpacity(0.15 * (1 - val)),
                  width: 4,
                ),
              ),
            );
          },
        ),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.03),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.2),
                blurRadius: 20,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.nfc, size: 60, color: Colors.white),
                if (isScanning)
                  const SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: Color(0xFF38BDF8),
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(ParsedNdefRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    record.icon,
                    color: const Color(0xFF38BDF8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.label,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (record.onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: record.onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    record.actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
