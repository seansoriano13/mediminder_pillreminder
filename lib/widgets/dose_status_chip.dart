import 'package:flutter/material.dart';

enum DoseStatus { upcoming, taken, overdue }

class DoseStatusChip extends StatelessWidget {
  final DoseStatus status;

  const DoseStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    String label;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (status == DoseStatus.upcoming) {
      label = 'Upcoming';
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      icon = Icons.schedule_rounded;
    } else if (status == DoseStatus.taken) {
      label = 'Taken';
      backgroundColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
      icon = Icons.check_circle_outline_rounded;
    } else {
      label = 'Overdue';
      backgroundColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
