import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/core/utils/app_constants.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditMedicationScreen extends ConsumerStatefulWidget {
  final int medicationId;
  
  const EditMedicationScreen({super.key, required this.medicationId});

  @override
  ConsumerState<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends ConsumerState<EditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _frequency = 'Daily';
  bool _trackInventory = false;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  Color _selectedColor = AppConstants.medicationColors.first;
  IconData _selectedIcon = AppConstants.medicationIcons.first;
  MedicationType _selectedType = MedicationType.pill;
  
  Medication? _originalMedication;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  Future<void> _loadMedication() async {
    final repository = ref.read(medicationRepositoryProvider);
    final medication = await repository.getMedication(widget.medicationId);
    
    if (medication != null && mounted) {
      setState(() {
        _originalMedication = medication;
        _nameController.text = medication.name;
        _dosageController.text = medication.dosage;
        _frequency = medication.frequency;
        _selectedColor = Color(medication.color);
        _selectedIcon = medication.icon != null 
            ? IconData(medication.icon!, fontFamily: 'MaterialIcons') 
            : AppConstants.medicationIcons.first;
        _selectedType = medication.type;
        _instructionsController.text = medication.instructions ?? '';
        
        // Parse times
        _times = medication.times.map((timeStr) {
          final parts = timeStr.split(':');
          return TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }).toList();
        
        // Inventory tracking
        if (medication.stockQuantity != null) {
          _trackInventory = true;
          _stockController.text = medication.stockQuantity.toString();
          _thresholdController.text = medication.refillThreshold?.toString() ?? '';
        }
        
        _isLoading = false;
      });
    } else if (mounted) {
      // Medication not found, go back
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _instructionsController.dispose();
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

  bool _hasSignificantChanges() {
    if (_originalMedication == null) return false;
    
    return _frequency != _originalMedication!.frequency ||
           _dosageController.text != _originalMedication!.dosage ||
           _times.length != _originalMedication!.times.length;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check for significant changes
    if (_hasSignificantChanges()) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Changes'),
          content: const Text(
            'You are changing the dosage schedule. This will update your notifications. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(medicationRepositoryProvider);
      final notificationService = NotificationService();
      
      // Cancel existing notifications
      final medId = widget.medicationId;
      for (int i = 0; i < 20; i++) {
        await notificationService.cancelNotification((medId * 1000) + (i * 10));
      }

      // Build updated medication
      final updatedMedication = Medication(
        id: widget.medicationId,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        times: _times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList(),
        color: _selectedColor.toARGB32(),
        icon: _selectedIcon.codePoint,
        type: _selectedType,
        instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
        stockQuantity: _trackInventory ? double.tryParse(_stockController.text) : null,
        refillThreshold: _trackInventory ? double.tryParse(_thresholdController.text) : null,
        isArchived: _originalMedication?.isArchived ?? false,
        startDate: _originalMedication?.startDate,
        endDate: _originalMedication?.endDate,
        imagePath: _originalMedication?.imagePath,
      );

      await repository.updateMedication(updatedMedication);

      // Schedule new notifications for daily medications
      if (_frequency == 'Daily') {
        for (int i = 0; i < _times.length; i++) {
          final time = _times[i];
          await notificationService.scheduleDailyNotification(
            id: (medId * 1000) + (i * 10),
            title: 'Time for ${_nameController.text}',
            body: 'Take ${_dosageController.text}',
            time: time,
          );
        }
      }

      // Invalidate providers
      ref.invalidate(medicationListProvider);
      ref.invalidate(todaysScheduleProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating medication: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Medication')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Medication')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication Type
              const Text('Medication Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MedicationType>(
                    value: _selectedType,
                    isDense: true,
                    isExpanded: true,
                    items: MedicationType.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g. 50mg, 1 pill)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vaccines),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter dosage' : null,
              ),
              const SizedBox(height: 16),
              
              // Instructions
              TextFormField(
                controller: _instructionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Instructions (optional)',
                  hintText: 'e.g., Take with food',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _frequency,
                    isDense: true,
                    isExpanded: true,
                    items: ['Daily', 'As Needed']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) => setState(() => _frequency = val!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              SwitchListTile(
                title: const Text('Track Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Alert when pills are running low'),
                value: _trackInventory,
                onChanged: (val) => setState(() => _trackInventory = val),
              ),
              if (_trackInventory) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Current Stock',
                          border: OutlineInputBorder(),
                          suffixText: 'units',
                        ),
                        validator: (value) => _trackInventory && (value == null || value.isEmpty) 
                          ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Alert at',
                          border: OutlineInputBorder(),
                          suffixText: 'left',
                        ),
                        validator: (value) => _trackInventory && (value == null || value.isEmpty) 
                          ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
              ],
              if (_frequency == 'Daily') ...[
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
                          child: ThreeDButton(
                            height: 40,
                            color: Colors.white,
                            onPressed: () => _selectTime(index),
                            child: Text(time.format(context), style: const TextStyle(color: Colors.teal)),
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
                }),
              ],
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
              ThreeDButton(
                onPressed: _submit,
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
