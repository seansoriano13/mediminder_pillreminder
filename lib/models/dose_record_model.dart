import 'package:cloud_firestore/cloud_firestore.dart';

class DoseRecord {
  final String id;
  final String medicineId;
  final String scheduledDate; // YYYY-MM-DD
  final String scheduledTime; // HH:mm
  final String status; // 'taken' or 'dismissed'
  final DateTime recordedAt;

  const DoseRecord({
    required this.id,
    required this.medicineId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    required this.recordedAt,
  });

  factory DoseRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime recordedAt;
    final recordedAtRaw = map['recordedAt'];
    if (recordedAtRaw is Timestamp) {
      recordedAt = recordedAtRaw.toDate();
    } else {
      recordedAt = DateTime.now();
    }

    return DoseRecord(
      id: id,
      medicineId: map['medicineId'] as String? ?? '',
      scheduledDate: map['scheduledDate'] as String? ?? '',
      scheduledTime: map['scheduledTime'] as String? ?? '',
      status: map['status'] as String? ?? 'taken',
      recordedAt: recordedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'status': status,
      'recordedAt': Timestamp.fromDate(recordedAt),
    };
  }
}
