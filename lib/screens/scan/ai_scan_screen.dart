import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:foodbalance/providers/user_provider.dart';

class AiScanPage extends StatefulWidget {
  const AiScanPage({super.key});

  @override
  State<AiScanPage> createState() => _AiScanPageState();
}

class _AiScanPageState extends State<AiScanPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  void _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _isLoading = true;
      });
      // Lanjutkan proses analisis AI...
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);
      _showResultSheet("Nasi Goreng Ayam", 450, 25, 15, 45);
    }
  }

  // --- SIMULASI LOGIKA API ---
  Future<void> _scanImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _isLoading = true;
      });

      // Simulasi jeda waktu kirim data ke API (2 detik)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      // Tampilkan hasil deteksi AI dalam Bottom Sheet
      _showResultSheet("Nasi Goreng Ayam", 450, 25, 15, 45);
    }
  }

  void _showResultSheet(String name, int cal, int prot, int fat, int carb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "AI Berhasil Mengenali!",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),

            // Grid Nutrisi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientInfo("Kalori", "$cal", "kkal", Colors.orange),
                _buildNutrientInfo("Protein", "$prot", "g", Colors.blue),
                _buildNutrientInfo("Lemak", "$fat", "g", Colors.red),
                _buildNutrientInfo("Karbo", "$carb", "g", Colors.green),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Tetap menjadi child dari SizedBox
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  // Logika Provider masuk di sini
                  context.read<UserProvider>().addFood(
                    name: name,
                    calories: cal,
                    protein: prot,
                    fat: fat,
                    carb: carb,
                  );

                  Navigator.pop(context); // Tutup sheet
                  Navigator.pop(context); // Kembali ke Home
                },
                child: const Text(
                  "Tambahkan ke Diary",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "AI Food Scanner",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: _image == null
                ? const Text(
                    "Kamera Belum Aktif",
                    style: TextStyle(color: Colors.white70),
                  )
                : Image.file(_image!),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 20),
                    Text(
                      "AI sedang menganalisis makanan...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Tombol Shutter di bawah
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        ListTile(
                          leading: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF2E7D32),
                          ),
                          title: const Text("Ambil Foto Kamera"),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.photo_library,
                            color: Color(0xFF2E7D32),
                          ),
                          title: const Text("Pilih dari Galeri"),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF2E7D32),
                      size: 35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
