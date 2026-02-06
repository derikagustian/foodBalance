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
    required List<Map<String, dynamic>> items, // Sekarang menerima List
    required DateTime scanTime,
  }) {
    // Kita gunakan List of Controllers agar tiap item bisa diedit
    List<Map<String, TextEditingController>> controllers = items.map((item) {
      return {
        'name': TextEditingController(text: item['name']),
        'calories': TextEditingController(text: item['calories'].toString()),
        'protein': TextEditingController(text: item['protein'].toString()),
        'fat': TextEditingController(text: item['fat'].toString()),
        'carb': TextEditingController(text: item['carb'].toString()),
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        // Tambah StatefulBuilder untuk handle hapus item jika perlu
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Detail Nutrisi Per Item",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                Text(
                  "Jam Makan: ${scanTime.hour}:${scanTime.minute}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(),

                Expanded(
                  child: ListView.builder(
                    itemCount: controllers.length,
                    itemBuilder: (context, index) {
                      final item = controllers[index];
                      return Card(
                        elevation: 0,
                        color: Colors.grey[50],
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: "Nama Item",
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _miniNutrientField(
                                    item['calories']!,
                                    "kkal",
                                    Colors.orange,
                                  ),
                                  _miniNutrientField(
                                    item['protein']!,
                                    "prot",
                                    Colors.blue,
                                  ),
                                  _miniNutrientField(
                                    item['fat']!,
                                    "lemak",
                                    Colors.red,
                                  ),
                                  _miniNutrientField(
                                    item['carb']!,
                                    "karbo",
                                    Colors.green,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => setSheetState(
                                      () => controllers.removeAt(index),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
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
                      final userProv = context.read<UserProvider>();
                      for (var c in controllers) {
                        userProv.addFood(
                          name: c['name']!.text,
                          calories: int.tryParse(c['calories']!.text) ?? 0,
                          protein: int.tryParse(c['protein']!.text) ?? 0,
                          fat: int.tryParse(c['fat']!.text) ?? 0,
                          carb: int.tryParse(c['carb']!.text) ?? 0,
                          manualTime: scanTime,
                        );
                      }
                      userProv.clearPendingFood();
                      Navigator.pop(context);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    child: const Text(
                      "Simpan Semua Makanan",
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
      ),
    );
  }

  // Helper widget untuk input kecil
  static Widget _miniNutrientField(
    TextEditingController ctrl,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 45,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
            ),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
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
        _scanTime = DateTime.now();
        _isLoading = true;
      });

      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
        );

        final imageBytes = await photo.readAsBytes();
        final prompt = TextPart("""
          Analisis gambar makanan ini secara detail. 
          Identifikasi SETIAP komponen makanan yang ada (misal: nasi, ayam goreng, sambal, dll).
          Berikan estimasi nutrisi untuk masing-masing item tersebut.
          
          WAJIB memberikan jawaban HANYA dalam format JSON mentah:
          {
            "items": [
              {
                "name": "nama item 1",
                "calories": 0,
                "protein": 0,
                "fat": 0,
                "carb": 0
              }
            ]
          }
        """);

        final response = await model.generateContent([
          Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
        ]);

        // --- PERBAIKAN DI SINI ---
        final responseText = response.text ?? "";

        // Membersihkan markdown JSON (```json ... ```) jika ada
        final cleanJson = responseText
            .replaceAll(RegExp(r'```json|```'), '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(cleanJson);
        final List<dynamic> itemsList = data['items'] ?? [];

        // Konversi ke format List<Map<String, dynamic>> agar seragam
        List<Map<String, dynamic>> finalItems = itemsList
            .map(
              (e) => {
                'name': e['name']?.toString() ?? "Tanpa Nama",
                'calories': (e['calories'] ?? 0).toInt(),
                'protein': (e['protein'] ?? 0).toInt(),
                'fat': (e['fat'] ?? 0).toInt(),
                'carb': (e['carb'] ?? 0).toInt(),
              },
            )
            .toList();

        // Simpan ke UserProvider sebagai pending
        if (mounted) {
          context.read<UserProvider>().setPendingFood({
            'isMultiItem': true,
            'items': finalItems,
            'scanTime': _scanTime,
          });
        }

        setState(() => _isLoading = false);

        // Tampilkan sheet hasil
        if (mounted) {
          AiScanPage.showResultSheet(
            context: context,
            items: finalItems,
            scanTime: _scanTime!,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("AI gagal mengenali gambar: $e")),
          );
        }
      }
    }
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
