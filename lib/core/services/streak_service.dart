import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dose_time/features/medication/domain/repositories/medication_repository.dart';

/// Service for tracking medication adherence streaks and gamification
class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLongestStreak = 'longest_streak';
  static const String _keyLastCompletedDate = 'last_completed_date';
  static const String _keyTotalDosesTaken = 'total_doses_taken';
  static const String _keyAchievements = 'achievements';

  SharedPreferences? _prefs;

  /// Initialize the streak service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the current streak (consecutive days with 100% adherence)
  int get currentStreak => _prefs?.getInt(_keyCurrentStreak) ?? 0;

  /// Get the longest streak ever achieved
  int get longestStreak => _prefs?.getInt(_keyLongestStreak) ?? 0;

  /// Get total doses taken all-time
  int get totalDosesTaken => _prefs?.getInt(_keyTotalDosesTaken) ?? 0;

  /// Get the last date when all doses were completed
  DateTime? get lastCompletedDate {
    final dateStr = _prefs?.getString(_keyLastCompletedDate);
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  /// Get earned achievements
  List<String> get achievements {
    return _prefs?.getStringList(_keyAchievements) ?? [];
  }

  /// Calculate adherence percentage for a given date range
  Future<double> calculateAdherencePercentage({
    required MedicationRepository repository,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    int totalDoses = 0;
    int takenDoses = 0;

    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      final logs = await repository.getLogsForDate(current);
      for (final log in logs) {
        totalDoses++;
        if (log.status == 'taken') {
          takenDoses++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    if (totalDoses == 0) return 100.0; // No doses = 100% adherence
    return (takenDoses / totalDoses) * 100;
  }

  /// Check and update streak after taking a dose
  Future<StreakUpdateResult> updateStreakAfterDoseTaken({
    required MedicationRepository repository,
  }) async {
    if (_prefs == null) await initialize();

    // Increment total doses taken
    final newTotal = totalDosesTaken + 1;
    await _prefs?.setInt(_keyTotalDosesTaken, newTotal);

    // Check if all doses for today are completed
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final logs = await repository.getLogsForDate(today);
    
    final medications = await repository.getAllMedications();
    int expectedDoses = 0;
    for (final med in medications) {
      if (med.frequency == 'Daily') {
        expectedDoses += med.times.length;
      }
    }
    
    final takenToday = logs.where((l) => l.status == 'taken').length;
    
    if (takenToday >= expectedDoses && expectedDoses > 0) {
      // All doses taken today!
      return await _handleDayCompleted(todayStart);
    }

    return StreakUpdateResult(
      currentStreak: currentStreak,
      newAchievements: [],
      isNewRecord: false,
    );
  }

  Future<StreakUpdateResult> _handleDayCompleted(DateTime date) async {
    final lastDate = lastCompletedDate;
    final yesterday = date.subtract(const Duration(days: 1));
    
    int newStreak;
    if (lastDate != null && 
        lastDate.year == yesterday.year && 
        lastDate.month == yesterday.month && 
        lastDate.day == yesterday.day) {
      // Continuing streak
      newStreak = currentStreak + 1;
    } else if (lastDate != null &&
        lastDate.year == date.year &&
        lastDate.month == date.month &&
        lastDate.day == date.day) {
      // Already completed today
      newStreak = currentStreak;
    } else {
      // New streak
      newStreak = 1;
    }

    await _prefs?.setInt(_keyCurrentStreak, newStreak);
    await _prefs?.setString(_keyLastCompletedDate, date.toIso8601String());

    // Check for new record
    bool isNewRecord = false;
    if (newStreak > longestStreak) {
      await _prefs?.setInt(_keyLongestStreak, newStreak);
      isNewRecord = true;
    }

    // Check for new achievements
    final newAchievements = await _checkAchievements(newStreak);

    return StreakUpdateResult(
      currentStreak: newStreak,
      newAchievements: newAchievements,
      isNewRecord: isNewRecord,
    );
  }

  Future<List<Achievement>> _checkAchievements(int streak) async {
    final earned = achievements;
    final newAchievements = <Achievement>[];

    final milestones = {
      'streak_3': Achievement(id: 'streak_3', title: 'Getting Started!', description: '3-day streak', icon: '🌱'),
      'streak_7': Achievement(id: 'streak_7', title: 'One Week Strong!', description: '7-day streak', icon: '🔥'),
      'streak_14': Achievement(id: 'streak_14', title: 'Two Weeks!', description: '14-day streak', icon: '⭐'),
      'streak_30': Achievement(id: 'streak_30', title: 'Monthly Master!', description: '30-day streak', icon: '🏆'),
      'streak_60': Achievement(id: 'streak_60', title: 'Consistency King!', description: '60-day streak', icon: '👑'),
      'streak_100': Achievement(id: 'streak_100', title: 'Century Club!', description: '100-day streak', icon: '💯'),
      'streak_365': Achievement(id: 'streak_365', title: 'Year of Health!', description: '365-day streak', icon: '🎉'),
    };

    final checkpoints = [3, 7, 14, 30, 60, 100, 365];
    for (final checkpoint in checkpoints) {
      final achievementId = 'streak_$checkpoint';
      if (streak >= checkpoint && !earned.contains(achievementId)) {
        final achievement = milestones[achievementId]!;
        newAchievements.add(achievement);
        earned.add(achievementId);
      }
    }

    if (newAchievements.isNotEmpty) {
      await _prefs?.setStringList(_keyAchievements, earned);
    }

    return newAchievements;
  }

  /// Reset streak (for when a day is missed)
  Future<void> resetStreak() async {
    if (_prefs == null) await initialize();
    await _prefs?.setInt(_keyCurrentStreak, 0);
  }

  /// Get motivational message based on current streak
  String getMotivationalMessage() {
    final streak = currentStreak;
    if (streak == 0) {
      return "Let's start a new streak today! 💪";
    } else if (streak < 3) {
      return "Great start! Keep it going! 🌱";
    } else if (streak < 7) {
      return "You're building a habit! $streak days strong! 🔥";
    } else if (streak < 30) {
      return "Incredible! $streak days! You're on fire! ⭐";
    } else if (streak < 100) {
      return "Amazing dedication! $streak days! 🏆";
    } else {
      return "Legendary! $streak days of perfect adherence! 👑";
    }
  }
}

/// Result of a streak update
class StreakUpdateResult {
  final int currentStreak;
  final List<Achievement> newAchievements;
  final bool isNewRecord;

  StreakUpdateResult({
    required this.currentStreak,
    required this.newAchievements,
    required this.isNewRecord,
  });
}

/// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}
