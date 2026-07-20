import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class EnvLoader {
  static Future<void> loadDotEnvIfPresent() async {
    try {
      await dotenv.dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  static String? get(String key) {
    final fromDefine = _fromDartDefine(key);
    if (fromDefine != null) return fromDefine;

    try {
      final v = dotenv.dotenv.env[key];
      if (v == null) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  static String? _fromDartDefine(String key) {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const practiceApiUrl = String.fromEnvironment('PRACTICE_API_URL');

    final value = switch (key) {
      'SUPABASE_URL' => supabaseUrl,
      'SUPABASE_ANON_KEY' => supabaseAnonKey,
      'PRACTICE_API_URL' => practiceApiUrl,
      _ => '',
    };

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
