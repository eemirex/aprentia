import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class EnvLoader {
  static Future<void> loadDotEnvIfPresent() async {
    try {
      await dotenv.dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  static String? get(String key) {
    try {
      final v = dotenv.dotenv.env[key];
      if (v == null) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }
}
