import 'dart:io';
import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  Future<void> generateAndShareReport(
    List<DoseLog> logs,
    List<Medication> medications,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();
    final medMap = {for (var m in medications) m.id: m};

    // Calculate stats
    final total = logs.length;
    final taken = logs.where((l) => l.status == 'taken').length;
    final skipped = logs.where((l) => l.status == 'skipped').length;
    final adherence = total > 0 ? (taken / total * 100).toStringAsFixed(1) : '0.0';

    // Load custom font (using standard font for simplicity, can add custom later)
    final theme = pw.ThemeData.withFont(
      base: pw.Font.courier(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('DoseTime History Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('MMM d, yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Doses', '$total'),
                _buildStatItem('Taken', '$taken'),
                _buildStatItem('Skipped', '$skipped'),
                _buildStatItem('Adherence', '$adherence%'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Report Period: ${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}',
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Time', 'Medication', 'Status', 'Taken At'],
            data: logs.map((log) {
              final med = medMap[log.medicationId];
              final name = log.medicationName ?? med?.name ?? 'Unknown';
              final scheduled = DateFormat('MMM d').format(log.scheduledTime);
              final time = DateFormat('HH:mm').format(log.scheduledTime);
              final takenAt = log.takenTime != null ? DateFormat('HH:mm').format(log.takenTime!) : '-';
              
              return [scheduled, time, name, log.status.toUpperCase(), takenAt];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    // Save and Share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/dosetime_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here is my DoseTime medication history report.',
    );
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
