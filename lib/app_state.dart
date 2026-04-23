import 'package:shared_preferences/shared_preferences.dart';
class AppState extends ChangeNotifier {
  // Core stats
  int xp = 0;
  int streak = 1;

  // Hearts (Duolingo-style regen)
  static const int maxHearts = 3;
  static const int heartRefillMinutes = 10; // 1 heart per 10 minutes
  int hearts = maxHearts;

  // YYYY-MM-DD
  String? _lastActiveDay;

  // Heart regen anchor (epoch ms). When hearts < maxHearts, this marks the start
  // of the current regen window.
  int? _heartAnchorMs;

  bool _loaded = false;

  // Learn-path completion (quizzes)
  final Set<String> completed = {};

  // Course lesson completion (reading/watching)
  final Set<String> _courseLessonsDone = {};

  // Badges
  final Set<String> _unlockedBadges = {};

  final List<String> lessonOrder = const [
    'ai_basics_1',
    'ai_basics_2',
    'verify',
    'workflows',
    'pro',
  ];

  // SharedPrefs keys
  static const _kXp = 'xp';
  static const _kStreak = 'streak';
  static const _kHearts = 'hearts';
  static const _kLastActiveDay = 'last_active_day';
  static const _kCompleted = 'completed_ids';
  static const _kHeartAnchorMs = 'heart_anchor_ms';
  static const _kCourseLessonsDone = 'course_lessons_done_ids';
  static const _kUnlockedBadges = 'unlocked_badges_ids';

  bool get isLoaded => _loaded;

  String _todayKey() => DateTime.now().toLocal().toIso8601String().substring(0, 10);

  int get _intervalMs => heartRefillMinutes * 60 * 1000;

  int get courseLessonsDoneCount => _courseLessonsDone.length;

  // Seconds until next heart (0 when full)
  int get secondsUntilNextHeart {
    if (hearts >= maxHearts) return 0;
    final anchor = _heartAnchorMs ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - anchor;
    final intoWindow = elapsed % _intervalMs;
    final remaining = _intervalMs - intoWindow;
    return (remaining / 1000).ceil();
  }

  String get nextHeartCountdown {
    final s = secondsUntilNextHeart;
    if (s <= 0) return '';
    final m = s ~/ 60;
    final r = s % 60;
    final mm = m.toString();
    final rr = r.toString().padLeft(2, '0');
    return '$mm:$rr';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    xp = prefs.getInt(_kXp) ?? 0;
    streak = prefs.getInt(_kStreak) ?? 1;
    hearts = prefs.getInt(_kHearts) ?? maxHearts;
    _lastActiveDay = prefs.getString(_kLastActiveDay);
    _heartAnchorMs = prefs.getInt(_kHeartAnchorMs);

    final list = prefs.getStringList(_kCompleted) ?? const <String>[];
    completed
      ..clear()
      ..addAll(list);

    final courseDone = prefs.getStringList(_kCourseLessonsDone) ?? const <String>[];
    _courseLessonsDone
      ..clear()
      ..addAll(courseDone);

    final badges = prefs.getStringList(_kUnlockedBadges) ?? const <String>[];
    _unlockedBadges
      ..clear()
      ..addAll(badges);

    // Apply heart regen based on time passed (may change hearts)
    final changedRegen = _applyHeartRegenInternal(nowMs: DateTime.now().millisecondsSinceEpoch);

    // Ensure badges are consistent with current stats
    final changedBadges = _ensureBadgesInternal();

    if (changedRegen || changedBadges) {
      await _save(prefs: prefs);
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();

    await p.setInt(_kXp, xp);
    await p.setInt(_kStreak, streak);
    await p.setInt(_kHearts, hearts);

    if (_lastActiveDay == null) {
      await p.remove(_kLastActiveDay);
    } else {
      await p.setString(_kLastActiveDay, _lastActiveDay!);
    }

    await p.setStringList(_kCompleted, completed.toList());

    if (_heartAnchorMs == null) {
      await p.remove(_kHeartAnchorMs);
    } else {
      await p.setInt(_kHeartAnchorMs, _heartAnchorMs!);
    }

    await p.setStringList(_kCourseLessonsDone, _courseLessonsDone.toList());
    await p.setStringList(_kUnlockedBadges, _unlockedBadges.toList());
  }

  /// Call this periodically from the UI layer (AppShell Timer).
  Future<void> tick() async {
    if (!_loaded) return;

    final changed = _applyHeartRegenInternal(nowMs: DateTime.now().millisecondsSinceEpoch);
    if (changed) {
      await _save();
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  bool _applyHeartRegenInternal({required int nowMs}) {
    if (hearts >= maxHearts) {
      if (_heartAnchorMs != null) {
        _heartAnchorMs = null;
        return true;
      }
      return false;
    }

    final anchor = _heartAnchorMs ?? nowMs;
    _heartAnchorMs ??= anchor;

    final elapsed = nowMs - anchor;
    if (elapsed < _intervalMs) return false;

    final gained = elapsed ~/ _intervalMs;
    if (gained <= 0) return false;

    final before = hearts;
    hearts = (hearts + gained).clamp(0, maxHearts);

    final consumedMs = gained * _intervalMs;
    final newAnchor = anchor + consumedMs;

    if (hearts >= maxHearts) {
      _heartAnchorMs = null;
    } else {
      _heartAnchorMs = newAnchor;
    }

    return before != hearts || _heartAnchorMs != newAnchor;
  }

  // ---------- Learn path unlock rules ----------
  bool isUnlocked(String id) {
    if (id == 'review') return true;

    final idx = lessonOrder.indexOf(id);
    if (idx <= 1) return true; // first two unlocked
    final prev = lessonOrder[idx - 1];
    return completed.contains(prev);
  }

  double progressFraction() {
    final total = lessonOrder.length;
    if (total == 0) return 0;
    final done = completed.length.clamp(0, total);
    return done / total;
  }

  // ---------- Courses progress ----------
  bool isCourseLessonDone(String lessonId) => _courseLessonsDone.contains(lessonId);

  Future<void> completeCourseLesson(
    String lessonId, {
    int xpAward = 15,
  }) async {
    if (_courseLessonsDone.contains(lessonId)) return;

    _courseLessonsDone.add(lessonId);
    xp += xpAward;

    final changedBadges = _ensureBadgesInternal();

    await _save();
    notifyListeners();

    // (Optional later): you can show a snackbar for badge unlocks from the UI layer
    // For now we only persist.
    if (changedBadges) {
      // already saved
    }
  }

  // ---------- Badges ----------
  bool isBadgeUnlocked(String badgeId) => _unlockedBadges.contains(badgeId);

  /// Safe to call from UI (it only saves if something changed).
  Future<void> ensureBadgesUpToDate() async {
    if (!_loaded) return;
    final changed = _ensureBadgesInternal();
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  bool _ensureBadgesInternal() {
    final before = _unlockedBadges.length;

    void unlock(String id) => _unlockedBadges.add(id);

    // Badge rules (must match AchievementsPage definitions)
    if (xp >= 10) unlock('first_steps');
    if (completed.isNotEmpty) unlock('quiz_starter');
    if (_courseLessonsDone.isNotEmpty) unlock('course_starter');
    if (streak >= 3) unlock('streak_3');
    if (xp >= 200) unlock('xp_200');
    if (_courseLessonsDone.length >= 5) unlock('course_5');
    if (completed.contains('ai_basics_1') && completed.contains('ai_basics_2')) unlock('prompting_pair');

    return _unlockedBadges.length != before;
  }

  // ---------- Learn completion ----------
  Future<void> completeLesson(String id, {int xpAward = 30, bool earnHeart = false}) async {
    final today = _todayKey();

    // streak updates only when completing something
    if (_lastActiveDay == null) {
      streak = 1;
    } else if (_lastActiveDay == today) {
      // same day: no change
    } else {
      final lastParts = _lastActiveDay!.split('-').map(int.parse).toList();
      final todayParts = today.split('-').map(int.parse).toList();

      final lastDate = DateTime(lastParts[0], lastParts[1], lastParts[2]);
      final todayDate = DateTime(todayParts[0], todayParts[1], todayParts[2]);

      final diff = todayDate.difference(lastDate).inDays;
      streak = (diff == 1) ? (streak + 1) : 1;
    }

    _lastActiveDay = today;

    // review can be repeated; lessons only award once
    if (id == 'review') {
      xp += xpAward;
      if (earnHeart && hearts < maxHearts) {
        hearts += 1;
        if (hearts >= maxHearts) _heartAnchorMs = null;
      }

      _ensureBadgesInternal();

      await _save();
      notifyListeners();
      return;
    }

    if (!completed.contains(id)) {
      completed.add(id);
      xp += xpAward;

      if (earnHeart && hearts < maxHearts) {
        hearts += 1;
        if (hearts >= maxHearts) _heartAnchorMs = null;
      }

      _ensureBadgesInternal();

      await _save();
      notifyListeners();
    }
  }

  Future<void> loseHeart() async {
    _applyHeartRegenInternal(nowMs: DateTime.now().millisecondsSinceEpoch);

    if (hearts > 0) {
      hearts -= 1;

      if (hearts < maxHearts && _heartAnchorMs == null) {
        _heartAnchorMs = DateTime.now().millisecondsSinceEpoch;
      }

      await _save();
      notifyListeners();
    }
  }

  Future<void> refillHearts() async {
    hearts = maxHearts;
    _heartAnchorMs = null;

    // badges might depend on hearts in the future; keep consistent
    _ensureBadgesInternal();

    await _save();
    notifyListeners();
  }

  Future<void> resetAll() async {
    xp = 0;
    streak = 1;
    hearts = maxHearts;
    _lastActiveDay = null;
    _heartAnchorMs = null;
    completed.clear();
    _courseLessonsDone.clear();
    _unlockedBadges.clear();

    await _save();
    notifyListeners();
  }
}
}

DateTime _dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return DateTime.now();
  final y = int.tryParse(parts[0]) ?? DateTime.now().year;
  final m = int.tryParse(parts[1]) ?? DateTime.now().month;
  final d = int.tryParse(parts[2]) ?? DateTime.now().day;
  return DateTime(y, m, d);
}

int _dayDiffLocal(String fromKey, String toKey) {
  final a = _dateFromKey(fromKey);
  final b = _dateFromKey(toKey);
  return b.difference(a).inDays;
}

