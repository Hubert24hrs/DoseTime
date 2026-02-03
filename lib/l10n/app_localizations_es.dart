// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'DoseTime';

  @override
  String get home => 'Inicio';

  @override
  String get medications => 'Medicamentos';

  @override
  String get history => 'Historial';

  @override
  String get settings => 'Configuración';

  @override
  String get addMedication => 'Agregar Medicamento';

  @override
  String get editMedication => 'Editar Medicamento';

  @override
  String get medicationName => 'Nombre del Medicamento';

  @override
  String get dosage => 'Dosis';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get times => 'Horarios de Recordatorio';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get take => 'Tomar';

  @override
  String get skip => 'Omitir';

  @override
  String get taken => 'Tomado';

  @override
  String get skipped => 'Omitido';

  @override
  String get missed => 'Perdido';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get noMedications => 'Sin medicamentos';

  @override
  String get noMedicationsDesc =>
      'Toca el botón + para agregar tu primer medicamento';

  @override
  String get noHistory => 'Sin historial';

  @override
  String get noHistoryDesc => 'Tus registros de dosis aparecerán aquí';

  @override
  String get dailyReminder => 'Recordatorio Diario';

  @override
  String timeToTake(String medication) {
    return 'Hora de tomar $medication';
  }

  @override
  String dosageInfo(String dosage) {
    return '$dosage';
  }

  @override
  String get adherenceRate => 'Tasa de Adherencia';

  @override
  String get streak => 'Racha Actual';

  @override
  String days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get excellent => '¡Excelente!';

  @override
  String get good => 'Bien';

  @override
  String get needsImprovement => 'Necesita mejorar';

  @override
  String get low => 'Adherencia baja';

  @override
  String get permissionsRequired => 'Permisos Requeridos';

  @override
  String get permissionsRationale =>
      'DoseTime necesita permisos de notificación para recordarte tus medicamentos. El permiso de alarma exacta asegura que los recordatorios lleguen a tiempo.';

  @override
  String get grantPermissions => 'Otorgar Permisos';

  @override
  String get maybeLater => 'Quizás Después';

  @override
  String get disclaimer => 'Aviso Médico';

  @override
  String get disclaimerText =>
      'DoseTime es solo una herramienta de recordatorio y NO sustituye el consejo médico profesional. Siempre consulta a tu médico.';

  @override
  String get accept => 'Entiendo';

  @override
  String get upgradeToPro => 'Actualizar a Pro';

  @override
  String get proFeatures =>
      'Desbloquea medicamentos ilimitados, estadísticas de adherencia y exportación en PDF.';

  @override
  String get purchase => 'Comprar';

  @override
  String get restore => 'Restaurar Compra';

  @override
  String get exportData => 'Exportar Datos';

  @override
  String get deleteAllData => 'Eliminar Todos los Datos';

  @override
  String get deleteConfirm =>
      '¿Estás seguro de que quieres eliminar todos tus datos? Esta acción no se puede deshacer.';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get version => 'Versión';

  @override
  String get about => 'Acerca de DoseTime';
}
