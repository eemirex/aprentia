import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class LocalAuthService extends AuthService {
  static const _kLocalUserId = 'local_auth_user_id';

  AppUser? _cached;

  @override
  bool get emailOtpSupported => false;

  @override
  Future<AppUser?> currentUser() async {
    if (_cached != null) return _cached;

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kLocalUserId);
    if (id == null || id.isEmpty) return null;

    _cached = AppUser(id: id, email: null);
    return _cached;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(_kLocalUserId);
    if (existing != null && existing.isNotEmpty) {
      _cached = AppUser(id: existing, email: null);
      return _cached!;
    }

    final newId = 'local_${_rand(24)}';
    await prefs.setString(_kLocalUserId, newId);

    _cached = AppUser(id: newId, email: null);
    return _cached!;
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    throw UnsupportedError('LocalAuthService does not support email OTP.');
  }

  @override
  Future<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    throw UnsupportedError('LocalAuthService does not support email OTP.');
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalUserId);
    _cached = null;
  }

  String _rand(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
