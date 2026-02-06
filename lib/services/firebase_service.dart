import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<void> syncProfile(Map<String, dynamic> profileData) async {
    if (userId == null) return;
    try {
      await _db.collection('users').doc(userId).set({
        'profile': profileData,
        'last_sync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error Sync Profile: $e");
    }
  }

  Future<String?> backupFoodItem(Map<String, dynamic> foodMap) async {
    if (userId == null) return null;

    try {
      final dataToUpload = Map<String, dynamic>.from(foodMap);
      dataToUpload.remove('id');
      dataToUpload['updated_at'] = FieldValue.serverTimestamp();

      DocumentReference docRef = _db
          .collection('users')
          .doc(userId)
          .collection('food_diary')
          .doc();

      await docRef.set(dataToUpload);
      return docRef.id;
    } catch (e) {
      debugPrint("Error backup ke Firebase: $e");
      return null;
    }
  }

  Future<void> deleteFoodItem(String docId) async {
    if (userId == null) return;
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('food_diary')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint("Error hapus cloud item: $e");
    }
  }

  Future<void> deleteUserCloudData() async {
    if (userId == null) return;
    try {
      final snapshots = await _db
          .collection('users')
          .doc(userId)
          .collection('food_diary')
          .get();

      WriteBatch batch = _db.batch();

      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_db.collection('users').doc(userId));

      await batch.commit();
      debugPrint("Semua data cloud berhasil dihapus.");
    } catch (e) {
      throw Exception("Gagal menghapus data: $e");
    }
  }

  Future<void> reauthenticateAndDelete(String password) async {
    final user = _auth.currentUser;
    if (user == null) return;

    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await deleteUserCloudData();
      await user.delete();
    } catch (e) {
      debugPrint("Re-autentikasi gagal: $e");
      rethrow;
    }
  }
}
