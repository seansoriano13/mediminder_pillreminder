import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import 'dose_status_chip.dart';

/// Card used in the Today tab to display a single scheduled dose.
class DoseCard extends StatelessWidget {
  final Medicine medicine;
  final String scheduledTime;
  final DoseStatus status;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onDismiss;

  const DoseCard({
    super.key,
    required this.medicine,
    required this.scheduledTime,
    required this.status,
    this.onMarkTaken,
    this.onDismiss,
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
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoseCardHeader(
                medicine: medicine,
                scheduledTime: scheduledTime,
                status: status,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
              if (medicine.instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InstructionsRow(
                  instructions: medicine.instructions,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
              if (status == DoseStatus.overdue) ...[
                const SizedBox(height: 12),
                _OverdueActions(
                  medicine: medicine,
                  onMarkTaken: onMarkTaken,
                  onDismiss: onDismiss,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DoseCardHeader extends StatelessWidget {
  final Medicine medicine;
  final String scheduledTime;
  final DoseStatus status;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _DoseCardHeader({
    required this.medicine,
    required this.scheduledTime,
    required this.status,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${medicine.dosage} · ${medicine.form}',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DoseStatusChip(status: status),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 3),
                Text(
                  scheduledTime,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _InstructionsRow extends StatelessWidget {
  final String instructions;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _InstructionsRow({
    required this.instructions,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            instructions,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OverdueActions extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onDismiss;

  const _OverdueActions({
    required this.medicine,
    required this.onMarkTaken,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = medicine.amount <= 0;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isOutOfStock ? null : onMarkTaken,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(isOutOfStock ? 'Out of Stock' : 'Mark as Taken'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: onDismiss,
          child: const Text('Dismiss'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          ),
        ),
      ],
    );
  }
}
