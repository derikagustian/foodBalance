import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Mendukung Sinkronisasi Profil (Berat, Tinggi, Tujuan, dll)
  Future<void> syncProfile(Map<String, dynamic> profileData) async {
    if (userId == null) return;
    try {
      await _db.collection('users').doc(userId).set({
        'profile': profileData,
        'last_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error Sync Profile: $e");
    }
  }

  // Mendukung Backup Data Makanan
  Future<void> backupFoodItem(Map<String, dynamic> foodData) async {
    if (userId == null) return;
    try {
      await _db.collection('users').doc(userId).collection('food_diary').add({
        ...foodData,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error Backup Food: $e");
    }
  }

  // Reset Data di Cloud saat User Logout/Reset
  Future<void> deleteUserEntirely() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await deleteUserCloudData();

    await user.delete();
  }

  Future<void> deleteUserCloudData() async {
    if (userId == null) return;
    try {
      final foodDiaryRef = _db
          .collection('users')
          .doc(userId)
          .collection('food_diary');
      final snapshots = await foodDiaryRef.get();

      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      await _db.collection('users').doc(userId).delete();

      debugPrint("Semua data cloud untuk user $userId telah dihapus.");
    } catch (e) {
      debugPrint("Gagal menghapus data cloud: $e");
    }
  }
}
