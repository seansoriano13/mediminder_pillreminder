import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medicine_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/medicine_card.dart';
import 'add_medicine_screen.dart';

class MedicinesScreen extends StatelessWidget {
  final User user;

  const MedicinesScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<Medicine>>(
      stream: firestoreService.getMedicinesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<Medicine> medicines = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'My Medicines',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (medicines.isEmpty)
                SliverFillRemaining(
                  child: _EmptyMedicinesState(colorScheme: colorScheme),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final medicine = medicines[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MedicineCard(
                            medicine: medicine,
                            onEdit: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddMedicineScreen(
                                    user: user,
                                    existingMedicine: medicine,
                                  ),
                                ),
                              );
                            },
                            onDelete: () {
                              _confirmDelete(
                                  context, firestoreService, medicine);
                            },
                          ),
                        );
                      },
                      childCount: medicines.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.large(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddMedicineScreen(user: user),
                ),
              );
            },
            tooltip: 'Add Medicine',
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, FirestoreService service, Medicine medicine) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Delete Medicine'),
          content: Text(
              'Remove "${medicine.name}" from your medicines? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await service.deleteMedicine(user.uid, medicine.id);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyMedicinesState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyMedicinesState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_rounded,
            size: 80,
            color: colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 16),
          Text(
            'No medicines yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add\nyour first medication.',
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
