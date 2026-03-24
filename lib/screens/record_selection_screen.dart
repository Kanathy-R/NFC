import 'package:flutter/material.dart';
import 'write_url_screen.dart';
import 'write_text_screen.dart';
import 'write_contact_screen.dart';
import 'write_wifi_screen.dart';

class RecordSelectionScreen extends StatelessWidget {
  const RecordSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Add a Record', style: TextStyle(color: Colors.white)),
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
              'Select the type of record to add:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSelectionCard(
                    context,
                    icon: Icons.link,
                    title: 'URL',
                    subtitle: 'Web address (https://...)',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WriteUrlScreen(isAddingRecord: true)),
                      );
                      if (context.mounted && result != null) Navigator.pop(context, result);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSelectionCard(
                    context,
                    icon: Icons.text_fields,
                    title: 'Text',
                    subtitle: 'Simple text record',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WriteTextScreen(isAddingRecord: true)),
                      );
                      if (context.mounted && result != null) Navigator.pop(context, result);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSelectionCard(
                    context,
                    icon: Icons.contact_phone,
                    title: 'Contact',
                    subtitle: 'vCard contact info',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WriteContactScreen(isAddingRecord: true)),
                      );
                      if (context.mounted && result != null) Navigator.pop(context, result);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSelectionCard(
                    context,
                    icon: Icons.wifi,
                    title: 'WiFi',
                    subtitle: 'Sharing network details',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WriteWifiScreen(isAddingRecord: true)),
                      );
                      if (context.mounted && result != null) Navigator.pop(context, result);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: const Color(0xFF38BDF8), size: 30),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }
}
