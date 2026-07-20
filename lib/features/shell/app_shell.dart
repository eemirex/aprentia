import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import '../auth/local_auth_service.dart';
import '../auth/supabase_auth_service.dart';

import '../practice/practice_page.dart';
import '../courses/courses_page.dart';
import '../achievements/achievements_page.dart';
import '../profile/profile_page.dart';

import '../practice/practice_models.dart';

class AppState extends ChangeNotifier {
  late AuthService _auth;

  AppState() {
    _auth = _isSupabaseReady() ? SupabaseAuthService() : LocalAuthService();
  }

  bool _isSupabaseReady() {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AppUser> _loadAuthUser() async {
    try {
      return await _auth.currentUser() ?? await _auth.signInAnonymously();
    } catch (_) {
      if (_auth is! SupabaseAuthService) rethrow;
      _auth = LocalAuthService();
      return await _auth.currentUser() ?? await _auth.signInAnonymously();
    }
  }

  String userId = '';

  bool _isAnonymous = true;
  String? _email;

  bool get isAnonymous => _isAnonymous;
  String get email => _email ?? '';
  bool get emailOtpSupported => _auth.emailOtpSupported;

  String displayName = 'Guest';
  String goal = 'Improve prompting';
  String skillLevel = 'Beginner';

  int xp = 0;
  int streak = 1;

  static const int maxHearts = 3;
  static const int heartRefillMinutes = 10;
  int hearts = maxHearts;

  String? _lastActiveDay;
  int? _heartAnchorMs;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  final Set<String> completed = {};
  final Set<String> completedCourseLessons = {};
  String? _lastPracticeDay;
  int practiceSessions = 0;

  final Set<String> unlockedBadges = {};
  String? _lastUnlockedBadgeId;

  String lastPracticeJson = '';

  final List<PracticeAttempt> _recentAttempts = [];
  List<PracticeAttempt> get recentAttempts => List.unmodifiable(_recentAttempts);

  final List<String> lessonOrder = const [
    'ai_basics_1',
    'ai_basics_2',
    'verify',
    'workflows',
    'pro',
  ];

  static const _kUserId = 'user_id';
  static const _kDisplayName = 'profile_display_name';
  static const _kGoal = 'profile_goal';
  static const _kSkill = 'profile_skill';

  static const _kXp = 'xp';
  static const _kStreak = 'streak';
  static const _kHearts = 'hearts';
  static const _kLastActiveDay = 'last_active_day';
  static const _kCompleted = 'completed_ids';
  static const _kHeartAnchorMs = 'heart_anchor_ms';

  static const _kCompletedCourseLessons = 'completed_course_lessons';
  static const _kLastPracticeDay = 'last_practice_day';
  static const _kPracticeSessions = 'practice_sessions';

  static const _kUnlockedBadges = 'unlocked_badges';
  static const _kLastPracticeJson = 'last_practice_json';

  static const _kPracticeAttempts = 'practice_attempts_v1';
  static const _kLastUnlockedBadgeId = 'last_unlocked_badge_id';

  String _todayKey() => DateTime.now().toLocal().toIso8601String().substring(0, 10);
  int get _intervalMs => heartRefillMinutes * 60 * 1000;

  String get level {
    if (xp < 200) return 'Beginner';
    if (xp < 600) return 'Intermediate';
    return 'Advanced';
  }

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
    final rr = r.toString().padLeft(2, '0');
    return '$m:$rr';
  }

  bool get isPracticeDoneToday => _lastPracticeDay == _todayKey();
  int get courseLessonsDoneCount => completedCourseLessons.length;

  double progressFraction() {
    final total = lessonOrder.length;
    if (total == 0) return 0;
    final done = completed.length.clamp(0, total);
    return done / total;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final authUser = await _loadAuthUser();
    userId = authUser.id;
    _isAnonymous = authUser.isAnonymous;
    _email = authUser.email;

    final savedUser = prefs.getString(_kUserId);
    if (savedUser == null || savedUser.isEmpty) {
      await prefs.setString(_kUserId, userId);
    }

    displayName = prefs.getString(_kDisplayName) ?? 'Guest';
    goal = prefs.getString(_kGoal) ?? 'Improve prompting';
    skillLevel = prefs.getString(_kSkill) ?? 'Beginner';

    xp = prefs.getInt(_kXp) ?? 0;
    streak = prefs.getInt(_kStreak) ?? 1;
    hearts = prefs.getInt(_kHearts) ?? maxHearts;
    _lastActiveDay = prefs.getString(_kLastActiveDay);
    _heartAnchorMs = prefs.getInt(_kHeartAnchorMs);

    final learnDone = prefs.getStringList(_kCompleted) ?? const <String>[];
    completed
      ..clear()
      ..addAll(learnDone);

    final courseDone = prefs.getStringList(_kCompletedCourseLessons) ?? const <String>[];
    completedCourseLessons
      ..clear()
      ..addAll(courseDone);

    _lastPracticeDay = prefs.getString(_kLastPracticeDay);
    practiceSessions = prefs.getInt(_kPracticeSessions) ?? 0;

    final badges = prefs.getStringList(_kUnlockedBadges) ?? const <String>[];
    unlockedBadges
      ..clear()
      ..addAll(badges);

    lastPracticeJson = prefs.getString(_kLastPracticeJson) ?? '';
    _lastUnlockedBadgeId = prefs.getString(_kLastUnlockedBadgeId);

    final rawAttempts = prefs.getString(_kPracticeAttempts);
    if (rawAttempts != null && rawAttempts.isNotEmpty) {
      try {
        final list = (jsonDecode(rawAttempts) as List)
            .map((e) => PracticeAttempt.fromJson(e as Map<String, dynamic>))
            .toList();
        _recentAttempts
          ..clear()
          ..addAll(list);
      } catch (_) {
        _recentAttempts.clear();
      }
    } else {
      _recentAttempts.clear();
    }

    final changed = _applyHeartRegenInternal(nowMs: DateTime.now().millisecondsSinceEpoch);
    if (changed) await _save(prefs: prefs);

    await ensureBadgesUpToDate();

    _loaded = true;
    notifyListeners();
  }

  Future<void> _save({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();

    await p.setString(_kUserId, userId);
    await p.setString(_kDisplayName, displayName);
    await p.setString(_kGoal, goal);
    await p.setString(_kSkill, skillLevel);

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

    await p.setStringList(_kCompletedCourseLessons, completedCourseLessons.toList());

    if (_lastPracticeDay == null) {
      await p.remove(_kLastPracticeDay);
    } else {
      await p.setString(_kLastPracticeDay, _lastPracticeDay!);
    }

    await p.setInt(_kPracticeSessions, practiceSessions);

    await p.setStringList(_kUnlockedBadges, unlockedBadges.toList());
    await p.setString(_kLastPracticeJson, lastPracticeJson);

    await p.setString(
      _kPracticeAttempts,
      jsonEncode(_recentAttempts.map((a) => a.toJson()).toList()),
    );

    if (_lastUnlockedBadgeId == null) {
      await p.remove(_kLastUnlockedBadgeId);
    } else {
      await p.setString(_kLastUnlockedBadgeId, _lastUnlockedBadgeId!);
    }
  }

  Future<void> updateProfile({
    required String newDisplayName,
    required String newGoal,
    required String newSkillLevel,
  }) async {
    displayName = newDisplayName.trim().isEmpty ? 'Guest' : newDisplayName.trim();
    goal = newGoal.trim().isEmpty ? 'Improve prompting' : newGoal.trim();
    skillLevel = newSkillLevel.trim().isEmpty ? 'Beginner' : newSkillLevel.trim();
    await _save();
    notifyListeners();
  }

  Future<void> setLastPracticeJson(String json) async {
    lastPracticeJson = json;
    await _save();
    notifyListeners();
  }

  Future<void> tick() async {
    if (!_loaded) return;

    final changed = _applyHeartRegenInternal(nowMs: DateTime.now().millisecondsSinceEpoch);
    if (changed) {
      await _save();
      notifyListeners();
      return;
    }

    notifyListeners();
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

    return before != hearts;
  }

  Future<void> spendHeartIfPossible() async {
    _applyHeartRegenInternal(nowMs: DateTime.now().millisecondsSinceEpoch);

    if (hearts <= 0) return;

    hearts -= 1;
    if (hearts < 0) hearts = 0;

    if (hearts < maxHearts && _heartAnchorMs == null) {
      _heartAnchorMs = DateTime.now().millisecondsSinceEpoch;
    }

    await _save();
    notifyListeners();
  }

  Future<void> refillHearts() async {
    hearts = maxHearts;
    _heartAnchorMs = null;
    await _save();
    notifyListeners();
  }

  bool isCourseLessonDone(String lessonId) => completedCourseLessons.contains(lessonId);

  Future<void> completeCourseLesson(String lessonId, {int xpAward = 15}) async {
    if (completedCourseLessons.contains(lessonId)) return;

    completedCourseLessons.add(lessonId);
    xp += xpAward;

    await ensureBadgesUpToDate();
    await _save();
    notifyListeners();
  }

  Future<void> completePracticeSession({int xpAward = 20}) async {
    final today = _todayKey();

    if (_lastActiveDay == null) {
      streak = 1;
    } else if (_lastActiveDay == today) {
    } else {
      final lastParts = _lastActiveDay!.split('-').map(int.parse).toList();
      final todayParts = today.split('-').map(int.parse).toList();

      final lastDate = DateTime(lastParts[0], lastParts[1], lastParts[2]);
      final todayDate = DateTime(todayParts[0], todayParts[1], todayParts[2]);

      final diff = todayDate.difference(lastDate).inDays;
      streak = (diff == 1) ? (streak + 1) : 1;
    }

    _lastActiveDay = today;
    _lastPracticeDay = today;

    practiceSessions += 1;
    xp += xpAward;

    await ensureBadgesUpToDate();
    await _save();
    notifyListeners();
  }

  Future<void> addPracticeAttempt(PracticeAttempt attempt, {int maxItems = 20}) async {
    _recentAttempts.insert(0, attempt);
    if (_recentAttempts.length > maxItems) {
      _recentAttempts.removeRange(maxItems, _recentAttempts.length);
    }
    await _save();
    notifyListeners();
  }

  bool isBadgeUnlocked(String id) => unlockedBadges.contains(id);

  String? consumeLastUnlockedBadgeId() {
    final id = _lastUnlockedBadgeId;
    if (id == null || id.isEmpty) return null;

    _lastUnlockedBadgeId = null;
    _save();
    notifyListeners();
    return id;
  }

  Future<void> ensureBadgesUpToDate() async {
    bool changed = false;

    changed |= _unlockIf('first_steps', xp >= 50);
    changed |= _unlockIf('streak_3', streak >= 3);
    changed |= _unlockIf('streak_7', streak >= 7);
    changed |= _unlockIf('course_3', courseLessonsDoneCount >= 3);
    changed |= _unlockIf('course_10', courseLessonsDoneCount >= 10);
    changed |= _unlockIf('practice_5', practiceSessions >= 5);
    changed |= _unlockIf('practice_20', practiceSessions >= 20);

    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  bool _unlockIf(String id, bool condition) {
    if (!condition) return false;
    if (unlockedBadges.contains(id)) return false;

    unlockedBadges.add(id);
    _lastUnlockedBadgeId = id;
    return true;
  }

  Future<void> sendEmailOtp(String email) async {
    await _auth.sendEmailOtp(email);
  }

  Future<void> verifyEmailOtp({required String email, required String token}) async {
    final u = await _auth.verifyEmailOtp(email: email, token: token);
    userId = u.id;
    _isAnonymous = u.isAnonymous;
    _email = u.email;

    await _save();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final u = await _auth.signInAnonymously();
    userId = u.id;
    _isAnonymous = u.isAnonymous;
    _email = u.email;

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
    completedCourseLessons.clear();

    _lastPracticeDay = null;
    practiceSessions = 0;

    unlockedBadges.clear();
    _lastUnlockedBadgeId = null;

    displayName = 'Guest';
    goal = 'Improve prompting';
    skillLevel = 'Beginner';

    lastPracticeJson = '';
    _recentAttempts.clear();

    await _save();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError(
        'AppScope not found in widget tree. Wrap routes/pages with AppScope(notifier: state, child: ...).',
      );
    }
    return scope.notifier!;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppState _state = AppState();
  int _index = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _state.load();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _state.tick();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          if (!_state.isLoaded) {
            return const Scaffold(
              body: SafeArea(child: Center(child: CircularProgressIndicator())),
            );
          }

          return Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: _index,
                children: [
                  const PracticePage(),
                  const CoursesPage(),
                  const AchievementsPage(),
                  const ProfilePage(),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.bolt_outlined),
                  activeIcon: Icon(Icons.bolt),
                  label: 'Practice',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book),
                  label: 'Courses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events),
                  label: 'Badges',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
