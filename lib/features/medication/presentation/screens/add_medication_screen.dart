import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/core/utils/app_constants.dart';
import 'package:dose_time/core/widgets/pill_avatar.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/add_medication_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step-by-step "add a medication" flow: name → form & strength → how often
/// → dose times → appearance & refills.
class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

enum _Frequency {
  once('Once a day', 1),
  twice('Twice a day', 2),
  three('3 times a day', 3),
  four('4 times a day', 4),
  asNeeded('Only as needed', 0);

  const _Frequency(this.label, this.doses);
  final String label;
  final int doses;
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _instructionsController = TextEditingController();

  int _step = 0;
  MedicationType _type = MedicationType.pill;
  _Frequency _frequency = _Frequency.once;
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  int _editingTime = 0;
  double _quantity = 1;
  bool _trackInventory = false;
  Color _color = AppConstants.medicationColors.first;
  IconData _icon = AppConstants.medicationIcons.first;

  static const _defaultTimes = <int, List<TimeOfDay>>{
    1: [TimeOfDay(hour: 8, minute: 0)],
    2: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    3: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    4: [
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 12, minute: 0),
      TimeOfDay(hour: 16, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
  };

  static const _commonMeds = [
    'Amlodipine', 'Amoxicillin', 'Artemether/Lumefantrine', 'Aspirin', 'Atorvastatin',
    'Azithromycin', 'Calcium', 'Cetirizine', 'Ciprofloxacin', 'Clopidogrel', 'Diclofenac',
    'Folic Acid', 'Glibenclamide', 'Hydrochlorothiazide', 'Ibuprofen', 'Insulin', 'Iron',
    'Levothyroxine', 'Lisinopril', 'Loratadine', 'Losartan', 'Metformin', 'Metronidazole',
    'Multivitamin', 'Nifedipine', 'Omega-3', 'Omeprazole', 'Paracetamol', 'Prednisolone',
    'Salbutamol', 'Simvastatin', 'Vitamin B12', 'Vitamin C', 'Vitamin D', 'Warfarin', 'Zinc',
  ];

  int get _lastStep => _frequency == _Frequency.asNeeded ? 3 : 4;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _strengthController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String get _dosageLabel {
    final qty = _quantity == _quantity.roundToDouble() ? _quantity.toInt().toString() : _quantity.toString();
    final strength = _strengthController.text.trim();
    return '$qty ${medicationUnit(_type)}${strength.isEmpty ? '' : ' · $strength'}';
  }

  String get _headerTitle {
    final name = _nameController.text.trim();
    if (_step == 0 || name.isEmpty) return 'Add Medication';
    final strength = _strengthController.text.trim();
    return strength.isEmpty ? name : '$name, $strength';
  }

  (IconData, String) get _question {
    switch (_step) {
      case 0:
        return (Icons.medication_outlined, 'What med would you like to add?');
      case 1:
        return (Icons.category_outlined, 'What form is the med?');
      case 2:
        return (Icons.repeat, 'How often do you take it?');
      case 3:
        if (_frequency != _Frequency.asNeeded) {
          return (Icons.alarm, 'When do you need to take the dose?');
        }
        return (Icons.palette_outlined, 'Finish up: look & refills');
      default:
        return (Icons.palette_outlined, 'Finish up: look & refills');
    }
  }

  bool get _canContinue {
    if (_step == 0) return _nameController.text.trim().isNotEmpty;
    if (_step == _lastStep && _trackInventory) {
      return double.tryParse(_stockController.text) != null &&
          double.tryParse(_thresholdController.text) != null;
    }
    return true;
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pageController.animateToPage(
      _pageIndexFor(step),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  // As-needed meds skip the dose-time page (page 3).
  int _pageIndexFor(int step) => (_frequency == _Frequency.asNeeded && step >= 3) ? step + 1 : step;

  void _next() {
    HapticFeedback.selectionClick();
    if (_step < _lastStep) {
      _go(_step + 1);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      _go(_step - 1);
    }
  }

  void _setFrequency(_Frequency f) {
    setState(() {
      _frequency = f;
      if (f.doses > 0) {
        _times = List.of(_defaultTimes[f.doses]!);
        _editingTime = 0;
      }
    });
  }

  Future<void> _save() async {
    final controller = ref.read(addMedicationControllerProvider.notifier);
    final instructions = _instructionsController.text.trim();
    final success = await controller.saveMedication(
      name: _nameController.text.trim(),
      dosage: _dosageLabel,
      frequency: _frequency == _Frequency.asNeeded ? 'As Needed' : 'Daily',
      times: _frequency == _Frequency.asNeeded ? const [] : _times,
      color: _color.toARGB32(),
      icon: _icon,
      type: _type,
      instructions: instructions.isEmpty ? null : instructions,
      stockQuantity: _trackInventory ? double.tryParse(_stockController.text) : null,
      refillThreshold: _trackInventory ? double.tryParse(_thresholdController.text) : null,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_nameController.text.trim()} added. We\'ll beep when it\'s time.')),
      );
      context.pop();
    } else {
      final error = ref.read(addMedicationControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error ?? 'Could not save medication'),
        action: (error ?? '').contains('Pro')
            ? SnackBarAction(label: 'Upgrade', onPressed: () => context.push('/upgrade'))
            : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMedicationControllerProvider);
    final (icon, question) = _question;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.headerColor,
        body: Column(
          children: [
            // Blue question header
            Padding(
              padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _headerTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 30),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Align(
                      key: ValueKey(question),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        question,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / (_lastStep + 1),
                      minHeight: 4,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
            // White content sheet
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _nameStep(),
                          _formStep(),
                          _frequencyStep(),
                          _timesStep(),
                          _finishStep(),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: FilledButton(
                          onPressed: _canContinue && !state.isLoading ? _next : null,
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_step == _lastStep ? 'Save' : 'Next'),
                                    const SizedBox(width: 8),
                                    Icon(_step == _lastStep ? Icons.check : Icons.chevron_right),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 0 — name with suggestions
  Widget _nameStep() {
    final query = _nameController.text.trim().toLowerCase();
    final suggestions = query.isEmpty
        ? const <String>[]
        : _commonMeds
            .where((m) => m.toLowerCase().contains(query) && m.toLowerCase() != query)
            .take(8)
            .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _canContinue ? _next() : null,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'e.g. Paracetamol',
            filled: false,
            border: const UnderlineInputBorder(),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            suffixIcon: _nameController.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.close), onPressed: _nameController.clear),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: brandBlue.shade50,
          child: Text('Start typing and choose your med from the list',
              style: TextStyle(color: brandBlue.shade800, fontSize: 13)),
        ),
        for (final s in suggestions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.search, color: Colors.grey),
            title: Text(s),
            onTap: () {
              _nameController.text = s;
              _nameController.selection = TextSelection.collapsed(offset: s.length);
              _next();
            },
          ),
      ],
    );
  }

  // Step 1 — form & strength
  Widget _formStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            for (final t in MedicationType.values)
              _SelectableTile(
                selected: _type == t,
                onTap: () => setState(() => _type = t),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(medicationTypeIcon(t),
                        color: _type == t ? AppTheme.primaryColor : Colors.grey.shade600, size: 28),
                    const SizedBox(height: 8),
                    Text(t.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _type == t ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Strength (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _strengthController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. 500 mg, 5 ml'),
        ),
      ],
    );
  }

  // Step 2 — frequency
  Widget _frequencyStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        for (final f in _Frequency.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableTile(
              selected: _frequency == f,
              onTap: () => _setFrequency(f),
              child: ListTile(
                leading: Icon(
                  f == _Frequency.asNeeded ? Icons.back_hand_outlined : Icons.schedule,
                  color: _frequency == f ? AppTheme.primaryColor : Colors.grey,
                ),
                title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: f == _Frequency.asNeeded ? const Text('No alarms; log it when you take it') : null,
                trailing: _frequency == f
                    ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  // Step 3 — dose times with a wheel picker
  Widget _timesStep() {
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final editing = _times[_editingTime.clamp(0, _times.length - 1)];
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: brandBlue.shade50.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Text('Take', style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                onPressed: _quantity > 0.5 ? () => setState(() => _quantity -= 0.5) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.primaryColor,
              ),
              Text(
                '${_quantity == _quantity.roundToDouble() ? _quantity.toInt() : _quantity} ${medicationUnit(_type)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity += 0.5),
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
        for (int i = 0; i < _times.length; i++)
          ListTile(
            onTap: () => setState(() => _editingTime = i),
            selected: i == _editingTime,
            selectedTileColor: brandBlue.shade50.withValues(alpha: 0.5),
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: i == _editingTime ? AppTheme.primaryColor : Colors.grey.shade200,
              child: Text('${i + 1}',
                  style: TextStyle(
                      color: i == _editingTime ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600)),
            ),
            title: Text('Dose ${i + 1}'),
            trailing: Text(
              _times[i].format(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
            ),
          ),
        SizedBox(
          height: 190,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
              textTheme: const CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(fontSize: 22)),
            ),
            child: CupertinoDatePicker(
              key: ValueKey('time-$_editingTime-${_times.length}'),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: use24h,
              minuteInterval: 5,
              initialDateTime: DateTime(2020, 1, 1, editing.hour, editing.minute - editing.minute % 5),
              onDateTimeChanged: (dt) => setState(() {
                _times[_editingTime] = TimeOfDay(hour: dt.hour, minute: dt.minute);
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.volume_up_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your phone will beep at each dose time until you respond.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 4 — appearance, refills & instructions
  Widget _finishStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      children: [
        Center(
          child: PillAvatar(
            size: 72,
            medication: Medication(
              name: '',
              dosage: '',
              frequency: '',
              times: const [],
              color: _color.toARGB32(),
              icon: _icon.codePoint,
              type: _type,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Colour', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in AppConstants.medicationColors)
              GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _color == c ? c : Colors.transparent, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundColor: c,
                    radius: 15,
                    child: _color == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ),
              ),
          ],
        ),
        if (_type == MedicationType.pill) ...[
          const SizedBox(height: 20),
          const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final i in AppConstants.medicationIcons)
                _SelectableTile(
                  selected: _icon == i,
                  onTap: () => setState(() => _icon = i),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(i, color: _icon == i ? _color : Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        const Text('Instructions (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionsController,
          decoration: const InputDecoration(hintText: 'e.g. After a meal, with water'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Refill reminder', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Warn me when I\'m running low'),
          value: _trackInventory,
          onChanged: (v) => setState(() => _trackInventory = v),
        ),
        if (_trackInventory)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stockController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Current stock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _thresholdController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Remind at'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Card(
          color: brandBlue.shade50.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              _frequency == _Frequency.asNeeded
                  ? '${_nameController.text.trim()} · $_dosageLabel · as needed'
                  : '${_nameController.text.trim()} · $_dosageLabel\n'
                      '${_frequency.label} at ${_times.map((t) => t.format(context)).join(', ')}',
              style: TextStyle(color: brandBlue.shade900),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableTile({required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? brandBlue.shade50 : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
