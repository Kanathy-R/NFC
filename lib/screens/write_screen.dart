import 'package:flutter/material.dart';

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write Data',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the type of record you want to write to your NFC tag.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildActionCard(
                  icon: Icons.link,
                  title: 'Add URL',
                  subtitle: 'Write a web address link',
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  icon: Icons.text_fields,
                  title: 'Add Text',
                  subtitle: 'Write a simple text message',
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  icon: Icons.contact_phone,
                  title: 'Add Contact',
                  subtitle: 'Write vCard information',
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  icon: Icons.wifi,
                  title: 'WiFi Network',
                  subtitle: 'Share WiFi configuration',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1,
            ),
          ),
          child: Icon(icon, color: const Color(0xFF38BDF8)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF38BDF8), size: 16),
        onTap: () {},
      ),
    );
  }
}
