import 'package:dose_time/core/services/pdf_export_service.dart';
import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isCalendarView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  int? _selectedMedicationId; // null = all

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(historyLogsProvider);
    final medsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          // View Toggle
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            tooltip: _isCalendarView ? 'Switch to List View' : 'Switch to Calendar View',
            onPressed: () => setState(() => _isCalendarView = !_isCalendarView),
          ),
          // Medication Filter
          medsAsync.when(
            data: (meds) => PopupMenuButton<int?>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by Medication',
              initialValue: _selectedMedicationId,
              onSelected: (id) => setState(() => _selectedMedicationId = id),
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: null,
                  checked: _selectedMedicationId == null,
                  child: const Text('All Medications'),
                ),
                ...meds.map((m) => CheckedPopupMenuItem(
                  value: m.id,
                  checked: _selectedMedicationId == m.id,
                  child: Text(m.name),
                )),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Export Button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onPressed: () => _exportReport(context, logsAsync.value ?? [], medsAsync.value ?? []),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No history available yet.'));
          }
          
          return medsAsync.when(
            data: (meds) {
              final medMap = {for (var m in meds) m.id: m};
              
              // Filter by medication first
              var filteredLogs = logs;
              if (_selectedMedicationId != null) {
                filteredLogs = logs.where((l) => l.medicationId == _selectedMedicationId).toList();
              }

              return Column(
                children: [
                  if (_isCalendarView) ...[
                    _buildCalendar(filteredLogs, medMap),
                    const Divider(),
                  ],
                  Expanded(
                    child: _buildLogList(filteredLogs, medMap),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading medications: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
      ),
    );
  }

  Future<void> _exportReport(BuildContext context, List<DoseLog> allLogs, List<Medication> allMeds) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (range != null) {
      // Filter logs by date range and selected medication
      var reportLogs = allLogs.where((l) {
        return l.scheduledTime.isAfter(range.start.subtract(const Duration(days: 1))) && 
               l.scheduledTime.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

      if (_selectedMedicationId != null) {
        reportLogs = reportLogs.where((l) => l.medicationId == _selectedMedicationId).toList();
      }
      
      // Sort by date
      reportLogs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating PDF report...')),
        );
        
        try {
          await PdfExportService().generateAndShareReport(
            reportLogs, 
            allMeds, 
            range.start, 
            range.end
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to export: $e')),
            );
          }
        }
      }
    }
  }

  Widget _buildCalendar(List<DoseLog> logs, Map<int?, Medication> medMap) {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.month, // Fixed format for simplicity
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      eventLoader: (day) {
        return logs.where((log) => isSameDay(log.scheduledTime, day)).toList();
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markerDecoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          
          // Show dots color-coded by status (green=all taken, red=any missed)
          final dayLogs = events.cast<DoseLog>();
          final hasMissed = dayLogs.any((l) => l.status == 'skipped' || l.status == 'missed');
          
          return Positioned(
            bottom: 1,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasMissed ? Colors.orange : Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogList(List<DoseLog> logs, Map<int?, Medication> medMap) {
    // If in calendar view, only show selected day
    var displayLogs = logs;
    if (_isCalendarView && _selectedDay != null) {
      displayLogs = logs.where((l) => isSameDay(l.scheduledTime, _selectedDay)).toList();
      
      if (displayLogs.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No logs for ${DateFormat('MMM d').format(_selectedDay!)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        );
      }
    }

    // Sort descending by time
    displayLogs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    return ListView.builder(
      itemCount: displayLogs.length,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB if needed
      itemBuilder: (context, index) {
        final log = displayLogs[index];
        final med = medMap[log.medicationId];
        
        final displayName = log.medicationName ?? med?.name ?? 'Unknown Medication';
        final displayColor = log.medicationColor != null ? Color(log.medicationColor!) : (med != null ? Color(med.color) : Colors.grey);
        final dateStr = DateFormat('MMM d, y • HH:mm').format(log.scheduledTime);
        
        IconData icon;
        Color color;
        switch (log.status) {
          case 'taken':
            icon = Icons.check_circle;
            color = Colors.green;
            break;
          case 'skipped':
            icon = Icons.remove_circle;
            color = Colors.grey;
            break;
          default:
            icon = Icons.warning;
            color = Colors.red;
        }

        return Dismissible(
          key: Key('log-${log.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Log?'),
                content: const Text('This will remove this dose entry from your history.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
             // We need a provider/repository to delete the log
             // Assuming repository is available via provider, but we need to check if 'deleteDoseLog' exists
             // For now, simpler to just invalidate or use a controller if available. 
             // Let's assume we can access repository directly here or strict riverpod pattern.
             // We'll need to update the repository to support deleting logs if not present.
             // Checking repository... it has logDose but maybe not deleteLog.
             // Let's check repository first. If missing, I'll add it.
             // PROCEEDING WITH UI ASSUMING PROVIDER EXISTS, WILL VERIFY REPO IN NEXT STEP.
             ref.read(medicationRepositoryProvider).deleteLog(log.id!);
             ref.invalidate(historyLogsProvider);
          },
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Icon(icon, color: color, size: 32),
              title: Text(
                displayName,
                style: TextStyle(color: displayColor, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('$dateStr\n${log.takenTime != null ? "Taken at ${DateFormat('HH:mm').format(log.takenTime!)}" : log.status.toUpperCase()}'),
              isThreeLine: true,
              trailing: med?.icon != null 
                  ? Icon(IconData(med!.icon!, fontFamily: 'MaterialIcons'), color: displayColor.withValues(alpha: 0.5))
                  : null,
            ),
          ),
        );
      },
    );
  }
}

