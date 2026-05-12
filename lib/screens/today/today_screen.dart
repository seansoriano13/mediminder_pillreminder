import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medicine_model.dart';
import '../../models/dose_record_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/dose_card.dart';
import '../../widgets/dose_status_chip.dart';

/// A single dose entry for display in the Today screen.
class _DoseItem {
  final Medicine medicine;
  final String scheduledTime; // HH:mm
  final DoseStatus status;

  const _DoseItem({
    required this.medicine,
    required this.scheduledTime,
    required this.status,
  });
}

class TodayScreen extends StatefulWidget {
  final User user;

  const TodayScreen({super.key, required this.user});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Medicine> _medicines = [];
  List<DoseRecord> _todayRecords = [];
  bool _isLoadingRecords = true;

  String _todayDateString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    _loadTodayRecords();
    NotificationService.registerTickCallback(_onMinuteTick);
  }

  @override
  void dispose() {
    NotificationService.unregisterTickCallback();
    super.dispose();
  }

  void _onMinuteTick() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTodayRecords() async {
    setState(() {
      _isLoadingRecords = true;
    });

    final records = await _firestoreService.getDoseRecordsForDate(
      widget.user.uid,
      _todayDateString(),
    );

    if (mounted) {
      setState(() {
        _todayRecords = records;
        _isLoadingRecords = false;
      });
    }
  }

  Future<void> _markAsTaken(Medicine medicine, String scheduledTime) async {
    final record = DoseRecord(
      id: '',
      medicineId: medicine.id,
      scheduledDate: _todayDateString(),
      scheduledTime: scheduledTime,
      status: 'taken',
      recordedAt: DateTime.now(),
    );

    await _firestoreService.recordDose(widget.user.uid, record);
    await _firestoreService.decrementAmount(
        widget.user.uid, medicine.id, medicine.amount);
    await _loadTodayRecords();
  }

  Future<void> _dismissDose(Medicine medicine, String scheduledTime) async {
    final record = DoseRecord(
      id: '',
      medicineId: medicine.id,
      scheduledDate: _todayDateString(),
      scheduledTime: scheduledTime,
      status: 'dismissed',
      recordedAt: DateTime.now(),
    );

    await _firestoreService.recordDose(widget.user.uid, record);
    await _loadTodayRecords();
  }

  /// Computes all scheduled times for a medicine on today's date.
  List<String> _computeTodayTimes(Medicine medicine) {
    final List<String> times = [];
    final now = DateTime.now();
    final today = now.weekday - 1; // 0=Mon, 6=Sun

    if (medicine.scheduleType == 'interval') {
      if (medicine.scheduleTimes.isEmpty) {
        return times;
      }

      // Parse the starting time.
      final startTimeParts = medicine.scheduleTimes[0].split(':');
      final startHour = int.tryParse(startTimeParts[0]) ?? 0;
      final startMinute = int.tryParse(startTimeParts[1]) ?? 0;

      // Generate all times from start through end of day.
      int currentHour = startHour;
      int currentMinute = startMinute;

      while (currentHour < 24) {
        final hourStr = currentHour.toString().padLeft(2, '0');
        final minuteStr = currentMinute.toString().padLeft(2, '0');
        times.add('$hourStr:$minuteStr');

        currentHour = currentHour + medicine.intervalHours;
      }
    } else {
      // Weekly schedule — only show if today is a selected day.
      final bool todayIsSelected = medicine.weeklyDays.contains(today);

      if (todayIsSelected) {
        for (final t in medicine.scheduleTimes) {
          times.add(t);
        }
      }
    }

    return times;
  }

  DoseStatus _computeStatus(
      Medicine medicine, String scheduledTime, List<DoseRecord> records) {
    // Check if there is a 'taken' record for this dose today.
    for (final record in records) {
      if (record.medicineId == medicine.id &&
          record.scheduledTime == scheduledTime &&
          record.status == 'taken') {
        return DoseStatus.taken;
      }
    }

    // Check if there is a 'dismissed' record for this dose today.
    for (final record in records) {
      if (record.medicineId == medicine.id &&
          record.scheduledTime == scheduledTime &&
          record.status == 'dismissed') {
        return DoseStatus.taken; // Dismissed doses also move out of active view
      }
    }

    // Check if the scheduled time has passed.
    final now = DateTime.now();
    final timeParts = scheduledTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDateTime.isBefore(now)) {
      return DoseStatus.overdue;
    }

    return DoseStatus.upcoming;
  }

  List<_DoseItem> _buildDoseItems() {
    final List<_DoseItem> items = [];

    for (final medicine in _medicines) {
      final List<String> times = _computeTodayTimes(medicine);

      for (final time in times) {
        final DoseStatus status =
            _computeStatus(medicine, time, _todayRecords);

        items.add(_DoseItem(
          medicine: medicine,
          scheduledTime: time,
          status: status,
        ));
      }
    }

    // Sort: overdue first, then upcoming by time, then taken last.
    items.sort((a, b) {
      if (a.status == DoseStatus.overdue && b.status != DoseStatus.overdue) {
        return -1;
      }
      if (a.status != DoseStatus.overdue && b.status == DoseStatus.overdue) {
        return 1;
      }
      if (a.status == DoseStatus.taken && b.status != DoseStatus.taken) {
        return 1;
      }
      if (a.status != DoseStatus.taken && b.status == DoseStatus.taken) {
        return -1;
      }
      return a.scheduledTime.compareTo(b.scheduledTime);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<Medicine>>(
      stream: _firestoreService.getMedicinesStream(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _isLoadingRecords) {
          return const Center(child: CircularProgressIndicator());
        }

        _medicines = snapshot.data ?? [];
        final List<_DoseItem> doseItems = _buildDoseItems();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: Text(
                  "Today's Doses",
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (doseItems.isEmpty)
              SliverFillRemaining(
                child: _EmptyTodayState(colorScheme: colorScheme),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = doseItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DoseCard(
                          medicine: item.medicine,
                          scheduledTime: item.scheduledTime,
                          status: item.status,
                          onMarkTaken: () =>
                              _markAsTaken(item.medicine, item.scheduledTime),
                          onDismiss: () =>
                              _dismissDose(item.medicine, item.scheduledTime),
                        ),
                      );
                    },
                    childCount: doseItems.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyTodayState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyTodayState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 16),
          Text(
            'All clear for today!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No medications scheduled.\nAdd one in My Medicines.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
