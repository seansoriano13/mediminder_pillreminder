import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/medicine_model.dart';
import '../../services/firestore_service.dart';

const List<String> _medicineTypes = [
  'Antibiotic',
  'Antiviral',
  'Analgesic',
  'Antihypertensive',
  'Antihistamine',
  'Supplement',
  'Vitamin',
  'Other',
];

const List<String> _medicineFormsOptions = ['Pill', 'Liquid', 'Injection'];

const List<String> _dayNames = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
];

class AddMedicineScreen extends StatefulWidget {
  final User user;
  final Medicine? existingMedicine;

  const AddMedicineScreen({
    super.key,
    required this.user,
    this.existingMedicine,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _amountController = TextEditingController();
  final _instructionsController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  String _selectedType = _medicineTypes[0];
  String _selectedForm = 'Pill';
  String _scheduleType = 'interval';
  int _intervalHours = 8;
  List<int> _selectedWeeklyDays = [];
  List<TimeOfDay> _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isSaving = false;

  bool get _isEditing => widget.existingMedicine != null;

  @override
  void initState() {
    super.initState();
    _prefillIfEditing();
  }

  void _prefillIfEditing() {
    final medicine = widget.existingMedicine;
    if (medicine == null) {
      return;
    }

    _nameController.text = medicine.name;
    _dosageController.text = medicine.dosage;
    _amountController.text = medicine.amount.toString();
    _instructionsController.text = medicine.instructions;
    _selectedType = medicine.medicineType;
    _selectedForm = medicine.form;
    _scheduleType = medicine.scheduleType;
    _intervalHours = medicine.intervalHours;
    _selectedWeeklyDays = List<int>.from(medicine.weeklyDays);

    final List<TimeOfDay> parsedTimes = [];
    for (final t in medicine.scheduleTimes) {
      final parts = t.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      parsedTimes.add(TimeOfDay(hour: hour, minute: minute));
    }
    if (parsedTimes.isNotEmpty) {
      _scheduleTimes = parsedTimes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _amountController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTimes[index],
    );

    if (picked != null) {
      setState(() {
        _scheduleTimes[index] = picked;
      });
    }
  }

  void _addTime() {
    setState(() {
      _scheduleTimes.add(const TimeOfDay(hour: 8, minute: 0));
    });
  }

  void _removeTime(int index) {
    if (_scheduleTimes.length > 1) {
      setState(() {
        _scheduleTimes.removeAt(index);
      });
    }
  }

  List<String> _buildScheduleTimeStrings() {
    final List<String> result = [];
    for (final t in _scheduleTimes) {
      final hour = t.hour.toString().padLeft(2, '0');
      final minute = t.minute.toString().padLeft(2, '0');
      result.add('$hour:$minute');
    }
    return result;
  }

  Future<void> _save() async {
    debugPrint('[AddMedicine] _save() called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[AddMedicine] Form validation failed');
      return;
    }
    debugPrint('[AddMedicine] Form validation passed');

    if (_scheduleType == 'weekly' && _selectedWeeklyDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    debugPrint('[AddMedicine] isSaving = true, starting Firestore write...');

    try {
      final medicine = Medicine(
        id: _isEditing ? widget.existingMedicine!.id : '',
        userId: widget.user.uid,
        name: _nameController.text.trim(),
        medicineType: _selectedType,
        dosage: _dosageController.text.trim(),
        amount: int.tryParse(_amountController.text.trim()) ?? 0,
        form: _selectedForm,
        instructions: _instructionsController.text.trim(),
        scheduleType: _scheduleType,
        intervalHours: _intervalHours,
        weeklyDays: _selectedWeeklyDays,
        scheduleTimes: _buildScheduleTimeStrings(),
        createdAt: _isEditing
            ? widget.existingMedicine!.createdAt
            : DateTime.now(),
      );
      debugPrint('[AddMedicine] Medicine object built: ${medicine.name}');

      if (_isEditing) {
        debugPrint('[AddMedicine] Calling updateMedicine...');
        await _firestoreService
            .updateMedicine(widget.user.uid, medicine)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception(
                'Request timed out. Check Firestore security rules and internet connection.',
              ),
            );
        debugPrint('[AddMedicine] updateMedicine completed');
      } else {
        debugPrint('[AddMedicine] Calling addMedicine...');
        await _firestoreService
            .addMedicine(widget.user.uid, medicine)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception(
                'Request timed out. Check Firestore security rules and internet connection.',
              ),
            );
        debugPrint('[AddMedicine] addMedicine completed');
      }

      debugPrint('[AddMedicine] Save successful, popping screen');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      debugPrint('[AddMedicine] ERROR: $e');
      debugPrint('[AddMedicine] Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        debugPrint('[AddMedicine] isSaving = false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: 'Basic Information'),
              const SizedBox(height: 12),
              _BasicInfoSection(
                nameController: _nameController,
                dosageController: _dosageController,
                amountController: _amountController,
                selectedType: _selectedType,
                selectedForm: _selectedForm,
                onTypeChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
                onFormChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedForm = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Instructions (Optional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Take with food, avoid sunlight...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Schedule'),
              const SizedBox(height: 12),
              _ScheduleSection(
                scheduleType: _scheduleType,
                intervalHours: _intervalHours,
                scheduleTimes: _scheduleTimes,
                selectedWeeklyDays: _selectedWeeklyDays,
                onScheduleTypeChanged: (val) {
                  setState(() {
                    _scheduleType = val;
                  });
                },
                onIntervalChanged: (val) {
                  setState(() {
                    _intervalHours = val;
                  });
                },
                onPickTime: _pickTime,
                onAddTime: _addTime,
                onRemoveTime: _removeTime,
                onWeeklyDayToggled: (dayIndex) {
                  setState(() {
                    if (_selectedWeeklyDays.contains(dayIndex)) {
                      _selectedWeeklyDays.remove(dayIndex);
                    } else {
                      _selectedWeeklyDays.add(dayIndex);
                    }
                  });
                },
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Add Medicine',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController amountController;
  final String selectedType;
  final String selectedForm;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onFormChanged;

  const _BasicInfoSection({
    required this.nameController,
    required this.dosageController,
    required this.amountController,
    required this.selectedType,
    required this.selectedForm,
    required this.onTypeChanged,
    required this.onFormChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Medicine Name *',
            prefixIcon: Icon(Icons.medication_outlined),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a medicine name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedType,
          decoration: const InputDecoration(
            labelText: 'Type of Medicine *',
            prefixIcon: Icon(Icons.category_outlined),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          items: _medicineTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage *',
                  hintText: 'e.g. 500mg',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  hintText: 'e.g. 30',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Must be a number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormSelector(
          selectedForm: selectedForm,
          onChanged: onFormChanged,
        ),
      ],
    );
  }
}

class _FormSelector extends StatelessWidget {
  final String selectedForm;
  final ValueChanged<String?> onChanged;

  const _FormSelector({required this.selectedForm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Form',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: _medicineFormsOptions.map((form) {
            final bool isSelected = selectedForm == form;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(form),
                selected: isSelected,
                onSelected: (_) => onChanged(form),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final String scheduleType;
  final int intervalHours;
  final List<TimeOfDay> scheduleTimes;
  final List<int> selectedWeeklyDays;
  final ValueChanged<String> onScheduleTypeChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onPickTime;
  final VoidCallback onAddTime;
  final ValueChanged<int> onRemoveTime;
  final ValueChanged<int> onWeeklyDayToggled;

  const _ScheduleSection({
    required this.scheduleType,
    required this.intervalHours,
    required this.scheduleTimes,
    required this.selectedWeeklyDays,
    required this.onScheduleTypeChanged,
    required this.onIntervalChanged,
    required this.onPickTime,
    required this.onAddTime,
    required this.onRemoveTime,
    required this.onWeeklyDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule type toggle
        Row(
          children: [
            Expanded(
              child: _ScheduleTypeButton(
                label: 'Every X Hours',
                icon: Icons.timelapse_rounded,
                isSelected: scheduleType == 'interval',
                onTap: () => onScheduleTypeChanged('interval'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScheduleTypeButton(
                label: 'Days of Week',
                icon: Icons.calendar_today_rounded,
                isSelected: scheduleType == 'weekly',
                onTap: () => onScheduleTypeChanged('weekly'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (scheduleType == 'interval') ...[
          Text(
            'Repeat every $intervalHours hours',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: intervalHours.toDouble(),
            min: 1,
            max: 24,
            divisions: 23,
            label: '${intervalHours}h',
            onChanged: (val) => onIntervalChanged(val.round()),
          ),
          const SizedBox(height: 8),
          _TimesList(
            label: 'Start Time',
            scheduleTimes: scheduleTimes,
            onPickTime: onPickTime,
            onAddTime: null,
            onRemoveTime: null,
            showSingleOnly: true,
          ),
        ] else ...[
          Text(
            'Select days',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(_dayNames.length, (index) {
              final bool isSelected = selectedWeeklyDays.contains(index);
              return FilterChip(
                label: Text(_dayNames[index]),
                selected: isSelected,
                onSelected: (_) => onWeeklyDayToggled(index),
              );
            }),
          ),
          const SizedBox(height: 16),
          _TimesList(
            label: 'Times',
            scheduleTimes: scheduleTimes,
            onPickTime: onPickTime,
            onAddTime: onAddTime,
            onRemoveTime: onRemoveTime,
            showSingleOnly: false,
          ),
        ],
      ],
    );
  }
}

class _ScheduleTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScheduleTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color fgColor;

    if (isSelected) {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: fgColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimesList extends StatelessWidget {
  final String label;
  final List<TimeOfDay> scheduleTimes;
  final ValueChanged<int> onPickTime;
  final VoidCallback? onAddTime;
  final ValueChanged<int>? onRemoveTime;
  final bool showSingleOnly;

  const _TimesList({
    required this.label,
    required this.scheduleTimes,
    required this.onPickTime,
    required this.onAddTime,
    required this.onRemoveTime,
    required this.showSingleOnly,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<TimeOfDay> displayTimes =
        showSingleOnly ? scheduleTimes.take(1).toList() : scheduleTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ...List.generate(displayTimes.length, (index) {
          final time = displayTimes[index];
          final formattedHour = time.hour.toString().padLeft(2, '0');
          final formattedMinute = time.minute.toString().padLeft(2, '0');

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded),
                    label: Text('$formattedHour:$formattedMinute'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => onPickTime(index),
                  ),
                ),
                if (!showSingleOnly && onRemoveTime != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: colorScheme.error),
                    onPressed: () => onRemoveTime!(index),
                  ),
                ],
              ],
            ),
          );
        }),
        if (!showSingleOnly && onAddTime != null)
          TextButton.icon(
            onPressed: onAddTime,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add another time'),
          ),
      ],
    );
  }
}
