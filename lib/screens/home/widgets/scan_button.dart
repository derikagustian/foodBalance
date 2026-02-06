import 'package:flutter/material.dart';

import 'package:foodbalance/screens/scan/ai_scan_screen.dart';

/* =====================================================
  SCAN BUTTONS SECTION
===================================================== */

class ScanButtonsSection extends StatelessWidget {
  const ScanButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tombol 1: AI Scan
        _buildScanButton(
          text: "Scan Makanan dengan AI",
          icon: Icons.auto_awesome,
          color: Colors.white,
          textColor: Colors.black87,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiScanPage()),
          ),
        ),
      ],
    );
  }

  // Fungsi Helper untuk membuat tombol
  Widget _buildScanButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        30,
      ), // Agar efek ripple mengikuti bentuk
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
