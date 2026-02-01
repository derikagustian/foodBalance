import 'package:flutter/material.dart';

import 'package:foodbalance/screens/scan/ai_scan_screen.dart';
import 'package:foodbalance/screens/scan/barcodeScan_screen.dart';

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
          color: const Color(0xFF2E7D32),
          textColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiScanPage()),
          ),
        ),

        const SizedBox(height: 10),

        // Tombol 2: Barcode Scan
        _buildScanButton(
          text: "Scan Barcode Produk",
          icon: Icons.qr_code_scanner,
          color: Colors.white,
          textColor: Colors.black87,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BarcodeScanPage()),
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

/* =====================================================
  SINGLE SCAN BUTTON
===================================================== */

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
