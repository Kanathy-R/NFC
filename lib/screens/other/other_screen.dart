import 'package:flutter/material.dart';
import 'copy_tag_screen.dart';
import 'erase_tag_screen.dart';
import 'lock_tag_screen.dart';
import 'read_memory_screen.dart';
import 'format_memory_screen.dart';
import 'set_password_screen.dart';
import 'remove_password_screen.dart';
import 'advanced_nfc_screen.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> otherOptions = [
      {
        'title': 'Copy tag',
        'icon': Icons.copy,
        'color': const Color(0xFF38BDF8),
        'screen': const CopyTagScreen(),
      },
      {
        'title': 'Erase tag',
        'icon': Icons.delete_outline,
        'color': const Color(0xFFF472B6),
        'screen': const EraseTagScreen(),
      },
      {
        'title': 'Lock tag',
        'icon': Icons.lock_outline,
        'color': const Color(0xFFFBBF24),
        'screen': const LockTagScreen(),
      },
      {
        'title': 'Read memory',
        'icon': Icons.layers_outlined,
        'color': const Color(0xFF34D399),
        'screen': const ReadMemoryScreen(),
      },
      {
        'title': 'Format memory',
        'icon': Icons.storage,
        'color': const Color(0xFFA78BFA),
        'screen': const FormatMemoryScreen(),
      },
      {
        'title': 'Set password',
        'icon': Icons.vpn_key_outlined,
        'color': const Color(0xFFFB923C),
        'screen': const SetPasswordScreen(),
      },
      {
        'title': 'Remove password',
        'icon': Icons.no_encryption_outlined,
        'color': const Color(0xFFF87171),
        'screen': const RemovePasswordScreen(),
      },
      {
        'title': 'Advanced NFC commands',
        'icon': Icons.memory,
        'color': const Color(0xFF9CA3AF),
        'screen': const AdvancedNfcScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Background managed by HomePage
      body: ListView.builder(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 100,
        ),
        itemCount: otherOptions.length,
        itemBuilder: (context, index) {
          final option = otherOptions[index];
          return _buildOtherOptionCard(
            context,
            option['title'] as String,
            option['icon'] as IconData,
            option['color'] as Color,
            option['screen'] as Widget,
          );
        },
      ),
    );
  }

  Widget _buildOtherOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    Widget screen,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
