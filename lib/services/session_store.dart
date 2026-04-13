import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores daily study-minute data and Phase 5 Gamification logic.
class SessionStore extends ChangeNotifier {
  static const _key = 'dahih_sessions';

  /// date-string → minutes  (e.g. "2026-03-19" → 90)
  final Map<String, int> _data = {};

  // Session tracking
  int _continuousMinutes = 0;
  int get continuousMinutes => _continuousMinutes;

  int dailyGoalMinutes;

  // Gamification (Phase 5)
  int _totalXp = 0;
  int _longestSession = 0;
  int _currentStreak = 0;
  final Set<String> _badges = {};

  int get totalXp => _totalXp;
  int get longestSession => _longestSession;
  int get currentStreak => _currentStreak;
  List<String> get badges => _badges.toList();

  static const ranks = [
    (0, 'مُبتدئ'),
    (500, 'مُكافح'),
    (1500, 'فارس الفجر'),
    (3000, 'نخبة الطلاب'),
    (6000, 'أوائل المملكة'),
  ];

  String get currentRank => ranks.lastWhere((r) => _totalXp >= r.$1).$2;
  int get nextRankXp => ranks.firstWhere((r) => r.$1 > _totalXp, orElse: () => ranks.last).$1;

  SessionStore({this.dailyGoalMinutes = 240});

  // ── Persistence ─────────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _data
        ..clear()
        ..addAll(map.map((k, v) => MapEntry(k, (v as num).toInt())));
    }
    dailyGoalMinutes = prefs.getInt('dahih_daily_goal') ?? 240;
    _totalXp         = prefs.getInt('dahih_total_xp') ?? 0;
    _longestSession  = prefs.getInt('dahih_longest_session') ?? 0;
    _currentStreak   = _calculateStreak();
    _badges.addAll(prefs.getStringList('dahih_badges') ?? []);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_data));
    await prefs.setInt('dahih_total_xp', _totalXp);
    await prefs.setInt('dahih_longest_session', _longestSession);
    await prefs.setStringList('dahih_badges', _badges.toList());
  }

  Future<void> setDailyGoal(int minutes) async {
    dailyGoalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dahih_daily_goal', minutes);
    notifyListeners();
  }

  // ── Data access ──────────────────────────────────────────────────────────────
  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get todayMinutes => _data[_today()] ?? 0;
  double get todayProgress => (todayMinutes / dailyGoalMinutes).clamp(0.0, 1.0);
  bool get milestoneReached => continuousMinutes >= 240; // 4 hours

  List<MapEntry<String, int>> recentDays(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final d = now.subtract(Duration(days: days - 1 - i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return MapEntry(key, _data[key] ?? 0);
    });
  }

  int _calculateStreak() {
    int streak = 0;
    final now = DateTime.now();
    // Check backwards from today. If today is 0, check yesterday.
    // If yesterday is 0, streak is broken.
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final mins = _data[key] ?? 0;
      if (mins > 0) {
        streak++;
      } else if (i > 0) {
        // missed a day (i=0 is today, allowed to be 0 early in the day)
        break;
      }
    }
    return streak;
  }

  // ── Mutation ─────────────────────────────────────────────────────────────────
  Future<void> addMinute() async {
    final today = _today();
    _data[today] = (_data[today] ?? 0) + 1;
    _continuousMinutes++;
    
    // XP Calculation (10 XP per minute + streak bonus)
    final streakBonus = min(_currentStreak, 10); // up to +10 XP/min for holding a 10-day streak
    _totalXp += (10 + streakBonus);

    _longestSession = max(_longestSession, _continuousMinutes);

    // Badges logic
    final hour = DateTime.now().hour;
    if (hour == 4 || hour == 5) _badges.add('فارس الفجر'); // Dawn Warrior
    if (_continuousMinutes >= 240) _badges.add('أسطورة التركيز'); // Focus Legend

    _currentStreak = _calculateStreak();
    notifyListeners();
    await _save();
  }

  void breakContinuity() {
    _continuousMinutes = 0;
    notifyListeners();
  }
}
