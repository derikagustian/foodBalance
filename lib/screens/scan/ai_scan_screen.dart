import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:foodbalance/providers/user_provider.dart';

class AiScanPage extends StatefulWidget {
  const AiScanPage({super.key});

  static void showResultSheet({
    required BuildContext context,
    required String name,
    required int cal,
    required int prot,
    required int fat,
    required int carb,
    required DateTime scanTime, // Tambahkan parameter waktu asli scan
  }) {
    final nameCtrl = TextEditingController(text: name);
    final calCtrl = TextEditingController(text: cal.toString());
    final protCtrl = TextEditingController(text: prot.toString());
    final fatCtrl = TextEditingController(text: fat.toString());
    final carbCtrl = TextEditingController(text: carb.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
              // Tambahkan info waktu agar user tahu ini dicatat di jam scan
              Text(
                "Waktu Makan: ${scanTime.hour.toString().padLeft(2, '0')}:${scanTime.minute.toString().padLeft(2, '0')} (Klik untuk edit)",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              TextField(
                controller: nameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Nama Makanan",
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _staticBuildEditableNutrient(
                    "Kalori",
                    calCtrl,
                    "kkal",
                    Colors.orange,
                  ),
                  _staticBuildEditableNutrient(
                    "Protein",
                    protCtrl,
                    "g",
                    Colors.blue,
                  ),
                  _staticBuildEditableNutrient(
                    "Lemak",
                    fatCtrl,
                    "g",
                    Colors.red,
                  ),
                  _staticBuildEditableNutrient(
                    "Karbo",
                    carbCtrl,
                    "g",
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Simpan data dengan waktu asli scan
                    context.read<UserProvider>().addFood(
                      name: nameCtrl.text,
                      calories: int.tryParse(calCtrl.text) ?? cal,
                      protein: int.tryParse(protCtrl.text) ?? prot,
                      fat: int.tryParse(fatCtrl.text) ?? fat,
                      carb: int.tryParse(carbCtrl.text) ?? carb,
                      manualTime: scanTime,
                    );

                    // Hapus data pending dari provider karena sudah disimpan
                    context.read<UserProvider>().clearPendingFood();

                    Navigator.pop(context); // Tutup sheet
                    // Cek jika sedang di halaman scan, maka kembali ke home
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
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
      ),
    );
  }

  // Fungsi helper nutrisi versi static agar bisa dipanggil fungsi static di atas
  static Widget _staticBuildEditableNutrient(
    String label,
    TextEditingController ctrl,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(
          width: 60,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
            ),
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  State<AiScanPage> createState() => _AiScanPageState();
}

class _AiScanPageState extends State<AiScanPage> {
  File? _image;
  DateTime? _scanTime;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  void _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _scanTime = DateTime.now(); // 1. Waktu scan dikunci di sini
        _isLoading = true;
      });

      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
        final model = GenerativeModel(
          model: 'gemini-2.5-flash-lite',
          apiKey: apiKey,
        );

        final imageBytes = await photo.readAsBytes();
        final prompt = TextPart("""
    Analisis gambar makanan ini. Berikan estimasi nutrisi.
    WAJIB memberikan jawaban HANYA dalam format JSON mentah:
    {
      "name": "nama makanan",
      "calories": 0,
      "protein": 0,
      "fat": 0,
      "carb": 0
    }
  """);

        final response = await model.generateContent([
          Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
        ]);

        final responseText = response.text ?? "";
        final cleanJson = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);

        context.read<UserProvider>().setPendingFood({
          'name': data['name'] ?? "Tidak Terdeteksi",
          'calories': (data['calories'] ?? 0).toInt(),
          'protein': (data['protein'] ?? 0).toInt(),
          'fat': (data['fat'] ?? 0).toInt(),
          'carb': (data['carb'] ?? 0).toInt(),
          'scanTime': _scanTime, // Sertakan waktu scan asli
        });

        setState(() => _isLoading = false);

        // 3. Tampilkan sheet (User bisa simpan atau tutup)
        AiScanPage.showResultSheet(
          context: context,
          name: data['name'] ?? "Tidak Terdeteksi",
          cal: (data['calories'] ?? 0).toInt(),
          prot: (data['protein'] ?? 0).toInt(),
          fat: (data['fat'] ?? 0).toInt(),
          carb: (data['carb'] ?? 0).toInt(),
          scanTime: _scanTime!,
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI gagal mengenali gambar: $e")),
        );
      }
    }
  }

  // Diubah menjadi static agar bisa dipanggil dari HomePage (untuk fitur Pending Scan)

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
