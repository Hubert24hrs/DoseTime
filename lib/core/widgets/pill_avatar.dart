import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/core/utils/app_constants.dart';
import 'package:flutter/material.dart';

/// Icon for each medication form, shared by the wizard, lists and alarm.
IconData medicationTypeIcon(MedicationType type) {
  switch (type) {
    case MedicationType.pill:
      return Icons.circle;
    case MedicationType.capsule:
      return Icons.medication;
    case MedicationType.liquid:
      return Icons.local_drink_outlined;
    case MedicationType.injection:
      return Icons.vaccines;
    case MedicationType.inhaler:
      return Icons.air;
    case MedicationType.drops:
      return Icons.water_drop_outlined;
    case MedicationType.cream:
      return Icons.spa_outlined;
    case MedicationType.patch:
      return Icons.crop_square_rounded;
    case MedicationType.other:
      return Icons.medical_services_outlined;
  }
}

/// Unit word used in "Take 1 pill(s)" style labels.
String medicationUnit(MedicationType type) {
  switch (type) {
    case MedicationType.pill:
      return 'pill(s)';
    case MedicationType.capsule:
      return 'capsule(s)';
    case MedicationType.liquid:
      return 'ml';
    case MedicationType.injection:
      return 'injection(s)';
    case MedicationType.inhaler:
      return 'puff(s)';
    case MedicationType.drops:
      return 'drop(s)';
    case MedicationType.cream:
      return 'application(s)';
    case MedicationType.patch:
      return 'patch(es)';
    case MedicationType.other:
      return 'dose(s)';
  }
}

/// Rounded tile showing a medication's form in its colour.
class PillAvatar extends StatelessWidget {
  final Medication medication;
  final double size;

  const PillAvatar({super.key, required this.medication, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final color = Color(medication.color);
    final IconData icon = medication.type == MedicationType.pill && medication.icon != null
        ? AppConstants.iconFor(medication.icon)
        : medicationTypeIcon(medication.type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
