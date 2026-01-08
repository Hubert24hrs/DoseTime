import 'package:dose_time/core/utils/app_constants.dart';
import 'package:dose_time/features/medication/presentation/providers/add_medication_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  
  String _frequency = 'Daily';
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  Color _selectedColor = AppConstants.medicationColors.first;
  IconData _selectedIcon = AppConstants.medicationIcons.first;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() {
        _times[index] = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(addMedicationControllerProvider.notifier).saveMedication(
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequency,
        times: _times,
        color: _selectedColor.value,
        icon: _selectedIcon,
      );

      if (success && mounted) {
        context.pop();
      } else if (mounted) {
        // Show error if failed (e.g. limit reached)
        final error = ref.read(addMedicationControllerProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMedicationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medication')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage (e.g. 50mg, 1 pill)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vaccines),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter dosage' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text('Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _frequency,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Daily', 'As Needed']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) => setState(() => _frequency = val!),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reminder Times', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              _times.add(const TimeOfDay(hour: 8, minute: 0));
                            });
                          },
                        ),
                      ],
                    ),
                    ..._times.asMap().entries.map((entry) {
                      final index = entry.key;
                      final time = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectTime(index),
                                child: Text(time.format(context)),
                              ),
                            ),
                            if (_times.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _times.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AppConstants.medicationColors.map((color) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: _selectedColor == color
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                              child: CircleAvatar(backgroundColor: color, radius: 16),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AppConstants.medicationIcons.map((icon) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedIcon == icon ? Colors.grey.shade200 : null,
                                borderRadius: BorderRadius.circular(8),
                                border: _selectedIcon == icon
                                    ? Border.all(color: Colors.teal, width: 2)
                                    : null,
                              ),
                              child: Icon(icon, size: 32, color: Colors.grey.shade800),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Save Medication'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
