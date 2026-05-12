import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String userId;
  final String name;
  final String medicineType;
  final String dosage;
  final int amount;
  final String form; // 'Pill', 'Liquid', 'Injection'
  final String instructions;
  final String scheduleType; // 'interval' or 'weekly'
  final int intervalHours;
  final List<int> weeklyDays; // 0=Mon, 6=Sun
  final List<String> scheduleTimes; // HH:mm strings
  final DateTime createdAt;

  const Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.medicineType,
    required this.dosage,
    required this.amount,
    required this.form,
    this.instructions = '',
    required this.scheduleType,
    this.intervalHours = 8,
    this.weeklyDays = const [],
    required this.scheduleTimes,
    required this.createdAt,
  });

  factory Medicine.fromMap(String id, Map<String, dynamic> map) {
    final weeklyDaysRaw = map['weeklyDays'] as List<dynamic>? ?? [];
    final List<int> weeklyDaysParsed = [];
    for (final day in weeklyDaysRaw) {
      weeklyDaysParsed.add(day as int);
    }

    final scheduleTimesRaw = map['scheduleTimes'] as List<dynamic>? ?? [];
    final List<String> scheduleTimesParsed = [];
    for (final t in scheduleTimesRaw) {
      scheduleTimesParsed.add(t as String);
    }

    DateTime createdAt;
    final createdAtRaw = map['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return Medicine(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      medicineType: map['medicineType'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      amount: map['amount'] as int? ?? 0,
      form: map['form'] as String? ?? 'Pill',
      instructions: map['instructions'] as String? ?? '',
      scheduleType: map['scheduleType'] as String? ?? 'interval',
      intervalHours: map['intervalHours'] as int? ?? 8,
      weeklyDays: weeklyDaysParsed,
      scheduleTimes: scheduleTimesParsed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'medicineType': medicineType,
      'dosage': dosage,
      'amount': amount,
      'form': form,
      'instructions': instructions,
      'scheduleType': scheduleType,
      'intervalHours': intervalHours,
      'weeklyDays': weeklyDays,
      'scheduleTimes': scheduleTimes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Medicine copyWith({
    String? id,
    String? userId,
    String? name,
    String? medicineType,
    String? dosage,
    int? amount,
    String? form,
    String? instructions,
    String? scheduleType,
    int? intervalHours,
    List<int>? weeklyDays,
    List<String>? scheduleTimes,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      medicineType: medicineType ?? this.medicineType,
      dosage: dosage ?? this.dosage,
      amount: amount ?? this.amount,
      form: form ?? this.form,
      instructions: instructions ?? this.instructions,
      scheduleType: scheduleType ?? this.scheduleType,
      intervalHours: intervalHours ?? this.intervalHours,
      weeklyDays: weeklyDays ?? this.weeklyDays,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
