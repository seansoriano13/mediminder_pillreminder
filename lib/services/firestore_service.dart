import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';
import '../models/dose_record_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medicinesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('medicines');
  }

  CollectionReference<Map<String, dynamic>> _doseRecordsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('doseRecords');
  }

  // ── Medicines ──────────────────────────────────────────────

  Stream<List<Medicine>> getMedicinesStream(String userId) {
    return _medicinesRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      final List<Medicine> medicines = [];
      for (final doc in snapshot.docs) {
        medicines.add(Medicine.fromMap(doc.id, doc.data()));
      }
      return medicines;
    });
  }

  Future<void> addMedicine(String userId, Medicine medicine) async {
    await _medicinesRef(userId).add(medicine.toMap());
  }

  Future<void> updateMedicine(String userId, Medicine medicine) async {
    await _medicinesRef(userId).doc(medicine.id).update(medicine.toMap());
  }

  Future<void> deleteMedicine(String userId, String medicineId) async {
    await _medicinesRef(userId).doc(medicineId).delete();
  }

  Future<void> decrementAmount(String userId, String medicineId, int currentAmount) async {
    if (currentAmount > 0) {
      await _medicinesRef(userId).doc(medicineId).update({
        'amount': currentAmount - 1,
      });
    }
  }

  // ── Dose Records ───────────────────────────────────────────

  Future<void> recordDose(String userId, DoseRecord record) async {
    await _doseRecordsRef(userId).add(record.toMap());
  }

  Future<List<DoseRecord>> getDoseRecordsForDate(
      String userId, String date) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _doseRecordsRef(userId)
            .where('scheduledDate', isEqualTo: date)
            .get();

    final List<DoseRecord> records = [];
    for (final doc in snapshot.docs) {
      records.add(DoseRecord.fromMap(doc.id, doc.data()));
    }
    return records;
  }
}
