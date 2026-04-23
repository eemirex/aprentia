/// Keep our own user model to avoid name clashes with Supabase's User.
class AppUser {
  final String id;
  final String? email;

  const AppUser({
    required this.id,
    this.email,
  });

  bool get isAnonymous => (email == null || email!.trim().isEmpty);
}

abstract class AuthService {
  /// True only for providers that support email OTP upgrade (Supabase).
  bool get emailOtpSupported;

  /// Return the currently signed-in user, or null if none.
  Future<AppUser?> currentUser();

  /// Create/return an anonymous user.
  Future<AppUser> signInAnonymously();

  /// Send an email OTP (only meaningful for providers that support it).
  Future<void> sendEmailOtp(String email);

  /// Verify OTP and return the authenticated user.
  Future<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> signOut();
}
