import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  // 1. Inisialisasi controller dengan deteksi otomatis
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    // 2. Memastikan kamera mulai saat masuk halaman
    cameraController.start();
  }

  @override
  void dispose() {
    // 3. Mematikan kamera saat keluar halaman agar tidak berat
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF004D40);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7C3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, MobileScannerState state, child) {
              final bool isTorchOn = state.torchState == TorchState.on;

              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.orange : darkGreen,
                ),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Agar judul rata kiri
          children: [
            // Judul yang sebelumnya terlewat
            const Text(
              "Barcode Scanner",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const Text(
              "Scan packaged food products",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xB3004D40), // Warna hijau dengan opacity
              ),
            ),
            const SizedBox(height: 30),

            // --- AREA KAMERA SCANNER ---
            // --- AREA KAMERA SCANNER ---
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      // Gunakan MobileScanner langsung
                      MobileScanner(
                        controller: cameraController,
                        fit: BoxFit.cover, // Memastikan gambar memenuhi kotak
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            _showResult(barcodes.first.rawValue ?? "Unknown");
                          }
                        },
                      ),
                      _buildFrameCorners(),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Center(
              child: Text(
                "Point the camera at a barcode",
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- INPUT BARCODE MANUAL ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Or enter barcode manually",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white70),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter barcode number",
                              hintStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Search"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- MEAL TYPE SECTION ---
            const Text(
              "Meal type",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildMealItem("Sarapan", Icons.wb_twilight)),
                Expanded(child: _buildMealItem("Makan siang", Icons.wb_sunny)),
                Expanded(
                  child: _buildMealItem("Makan malam", Icons.nightlight_round),
                ),
                Expanded(child: _buildMealItem("Cemilan", Icons.local_pizza)),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(String title, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF004D40),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.orangeAccent, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
          ),
        ),
      ],
    );
  }

  void _showResult(String code) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Barcode terdeteksi: $code"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFrameCorners() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _corner(top: true, left: true),
          ),
          Align(
            alignment: Alignment.topRight,
            child: _corner(top: true, left: false),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: _corner(top: false, left: true),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _corner(top: false, left: false),
          ),
        ],
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Colors.white, width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
