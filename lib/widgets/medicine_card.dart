import 'package:flutter/material.dart';
import '../models/medicine_model.dart';

/// Card used in the My Medicines tab to display a medicine's details.
class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _FormIconBadge(form: medicine.form),
              const SizedBox(width: 16),
              Expanded(
                child: _MedicineInfo(
                  medicine: medicine,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ),
              _AmountBadge(amount: medicine.amount, colorScheme: colorScheme),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: colorScheme.error),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormIconBadge extends StatelessWidget {
  final String form;

  const _FormIconBadge({required this.form});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    if (form == 'Pill') {
      icon = Icons.medication_rounded;
    } else if (form == 'Liquid') {
      icon = Icons.water_drop_outlined;
    } else {
      icon = Icons.vaccines_outlined;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 26),
    );
  }
}

class _MedicineInfo extends StatelessWidget {
  final Medicine medicine;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _MedicineInfo({
    required this.medicine,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    String scheduleLabel;
    if (medicine.scheduleType == 'interval') {
      scheduleLabel = 'Every ${medicine.intervalHours}h';
    } else {
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final List<String> selectedDayNames = [];
      for (final day in medicine.weeklyDays) {
        selectedDayNames.add(dayNames[day]);
      }
      scheduleLabel = selectedDayNames.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medicine.name,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${medicine.dosage} · ${medicine.form}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.schedule_rounded,
                size: 12, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              scheduleLabel,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmountBadge extends StatelessWidget {
  final int amount;
  final ColorScheme colorScheme;

  const _AmountBadge({required this.amount, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;

    if (amount == 0) {
      badgeColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
    } else if (amount <= 5) {
      badgeColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;
    } else {
      badgeColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$amount',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'left',
            style: TextStyle(color: textColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
