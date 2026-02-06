import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // Pindahan dari UserProvider: Logika Mood Track
  Future<String> getAiFoodRecommendation(String mood, String tujuan) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    if (apiKey.isEmpty) return "Konfigurasi AI belum siap.";

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
      );

      final prompt =
          """
Role: Ahli Gizi Profesional yang suportif.
Konteks: Pengguna merasa $mood, tujuan: $tujuan.

Tugas:
1. Berikan sapaan (pujian untuk mood 😍🤗😊 atau penyemangat untuk mood 😔☹️).
2. Gunakan kalimat transisi: "Nah, rekomendasi makanan yang cocok untuk boost mood hari ini adalah:"

Format Jawaban (WAJIB ikuti struktur baris ini, tanpa label seperti 'Sapaan:' atau 'Alasan:'):
[Kalimat Sapaan/Penyemangat]
[Kalimat Transisi]

Nama Makanan:
[Sebutkan Nama Makanannya]

Alasan:
[Berikan alasan medis singkat dalam 1-2 kalimat]

Catatan Penting:
- JANGAN gunakan tanda bintang (**), tanda pagar (#), atau format markdown.
- JANGAN gunakan label 'Sapaan:' atau 'Kalimat Transisi:'.
- Gunakan Bahasa Indonesia yang ramah dan profesional.
""";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text?.trim() ?? "Coba makan buah segar ya!";
    } catch (e) {
      debugPrint("Kesalahan AI: $e");
      return "Duh, AI sedang istirahat. Coba lagi nanti ya!";
    }
  }

  // Pindahan dari UserProvider: Logika Weekly AI
  Future<String> fetchAIInsight(String prompt) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? "Gagal mendapatkan analisa.";
    } catch (e) {
      return "AI sedang offline. Periksa koneksi internetmu.";
    }
  }
}
