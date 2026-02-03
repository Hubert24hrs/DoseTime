import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdherenceInsightsScreen extends ConsumerWidget {
  const AdherenceInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(historyLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adherence Insights'),
        centerTitle: false,
      ),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return _buildEmptyState();
          }
          
          // Calculate stats
          final taken = logs.where((l) => l.status == 'taken').length;
          final skipped = logs.where((l) => l.status == 'skipped').length;
          final total = taken + skipped;
          final adherenceRate = total > 0 ? (taken / total * 100) : 0.0;

          // Group by last 7 days
          final now = DateTime.now();
          final weekData = <DateTime, _DayStats>{};
          for (int i = 6; i >= 0; i--) {
            final date = DateTime(now.year, now.month, now.day - i);
            weekData[date] = _DayStats();
          }
          
          for (final log in logs) {
            final logDate = DateTime(
              log.scheduledTime.year,
              log.scheduledTime.month,
              log.scheduledTime.day,
            );
            if (weekData.containsKey(logDate)) {
              if (log.status == 'taken') {
                weekData[logDate]!.taken++;
              } else if (log.status == 'skipped') {
                weekData[logDate]!.skipped++;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Stats Card
                _buildOverallStatsCard(adherenceRate, taken, skipped, context),
                const SizedBox(height: 24),
                
                // Weekly Chart
                Text(
                  'Last 7 Days',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildWeeklyChart(weekData, context),
                const SizedBox(height: 24),
                
                // Streak info
                _buildStreakCard(logs, context),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No data yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging doses to see insights',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard(
    double adherenceRate,
    int taken,
    int skipped,
    BuildContext context,
  ) {
    Color rateColor;
    String rateLabel;
    IconData rateIcon;

    if (adherenceRate >= 90) {
      rateColor = Colors.green;
      rateLabel = 'Excellent!';
      rateIcon = Icons.celebration;
    } else if (adherenceRate >= 75) {
      rateColor = Colors.teal;
      rateLabel = 'Good';
      rateIcon = Icons.thumb_up;
    } else if (adherenceRate >= 50) {
      rateColor = Colors.orange;
      rateLabel = 'Needs improvement';
      rateIcon = Icons.trending_up;
    } else {
      rateColor = Colors.red;
      rateLabel = 'Low adherence';
      rateIcon = Icons.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adherence Rate',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${adherenceRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: rateColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(rateIcon, color: rateColor, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  rateLabel,
                                  style: TextStyle(color: rateColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 0,
                      sections: [
                        PieChartSectionData(
                          value: taken.toDouble(),
                          color: Colors.green,
                          radius: 40,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: skipped.toDouble(),
                          color: Colors.grey.shade300,
                          radius: 40,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(Icons.check_circle, 'Taken', taken, Colors.green),
                const SizedBox(width: 16),
                _buildStatChip(Icons.remove_circle, 'Skipped', skipped, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text('$count $label', style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Map<DateTime, _DayStats> weekData, BuildContext context) {
    final entries = weekData.entries.toList();
    
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: entries.map((e) => (e.value.taken + e.value.skipped).toDouble()).fold(1.0, (a, b) => a > b ? a : b) + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(entries[index].key),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            final index = e.key;
            final stats = e.value.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (stats.taken + stats.skipped).toDouble(),
                  color: Colors.teal,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  rodStackItems: [
                    BarChartRodStackItem(0, stats.taken.toDouble(), Colors.green),
                    BarChartRodStackItem(
                      stats.taken.toDouble(),
                      (stats.taken + stats.skipped).toDouble(),
                      Colors.grey.shade300,
                    ),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStreakCard(List logs, BuildContext context) {
    // Calculate current streak
    int streak = 0;
    final now = DateTime.now();
    
    for (int i = 0; i < 30; i++) {
      final checkDate = DateTime(now.year, now.month, now.day - i);
      final dayLogs = logs.where((l) {
        final logDate = DateTime(
          l.scheduledTime.year,
          l.scheduledTime.month,
          l.scheduledTime.day,
        );
        return logDate == checkDate;
      }).toList();
      
      if (dayLogs.isEmpty) {
        if (i > 0) break; // No logs for today is okay
      } else {
        final allTaken = dayLogs.every((l) => l.status == 'taken');
        if (allTaken) {
          streak++;
        } else {
          break;
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$streak ${streak == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStats {
  int taken = 0;
  int skipped = 0;
}
