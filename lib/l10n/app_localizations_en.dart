// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DoseTime';

  @override
  String get home => 'Home';

  @override
  String get medications => 'Medications';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get dosage => 'Dosage';

  @override
  String get frequency => 'Frequency';

  @override
  String get times => 'Reminder Times';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get take => 'Take';

  @override
  String get skip => 'Skip';

  @override
  String get taken => 'Taken';

  @override
  String get skipped => 'Skipped';

  @override
  String get missed => 'Missed';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noMedications => 'No medications yet';

  @override
  String get noMedicationsDesc =>
      'Tap the + button to add your first medication';

  @override
  String get noHistory => 'No history yet';

  @override
  String get noHistoryDesc => 'Your dose logs will appear here';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String timeToTake(String medication) {
    return 'Time to take $medication';
  }

  @override
  String dosageInfo(String dosage) {
    return '$dosage';
  }

  @override
  String get adherenceRate => 'Adherence Rate';

  @override
  String get streak => 'Current Streak';

  @override
  String days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get excellent => 'Excellent!';

  @override
  String get good => 'Good';

  @override
  String get needsImprovement => 'Needs improvement';

  @override
  String get low => 'Low adherence';

  @override
  String get permissionsRequired => 'Permissions Required';

  @override
  String get permissionsRationale =>
      'DoseTime needs notification permissions to remind you about your medications. Exact alarm permission ensures reminders are delivered on time, even in battery-saving mode.';

  @override
  String get grantPermissions => 'Grant Permissions';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get disclaimer => 'Medical Disclaimer';

  @override
  String get disclaimerText =>
      'DoseTime is a reminder tool only and is NOT a substitute for professional medical advice. Always consult your healthcare provider.';

  @override
  String get accept => 'I Understand';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get proFeatures =>
      'Unlock unlimited medications, adherence insights, and PDF exports.';

  @override
  String get purchase => 'Purchase';

  @override
  String get restore => 'Restore Purchase';

  @override
  String get exportData => 'Export Data';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteConfirm =>
      'Are you sure you want to delete all your data? This cannot be undone.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get version => 'Version';

  @override
  String get about => 'About DoseTime';
}
