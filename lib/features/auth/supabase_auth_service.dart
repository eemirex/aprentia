import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SupabaseAuthService extends AuthService {
  SupabaseClient get _client => Supabase.instance.client;
  User? get _sbUser => _client.auth.currentUser;

  @override
  bool get emailOtpSupported => true;

  @override
  Future<AppUser?> currentUser() async {
    final u = _sbUser;
    if (u == null) return null;
    return AppUser(id: u.id, email: u.email);
  }

  @override
  Future<AppUser> signInAnonymously() async {
    final res = await _client.auth.signInAnonymously();
    final u = res.user ?? _client.auth.currentUser;
    if (u == null) {
      throw Exception('Supabase anonymous sign-in failed (no user returned).');
    }
    return AppUser(id: u.id, email: u.email);
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  @override
  Future<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );

    final u = _client.auth.currentUser;
    if (u == null) {
      throw Exception('OTP verified but no user session found.');
    }
    return AppUser(id: u.id, email: u.email);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
