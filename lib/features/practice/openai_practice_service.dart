import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../env_loader.dart';
import 'practice_models.dart';

class OpenAIPracticeService {
  final http.Client _client;

  OpenAIPracticeService({http.Client? client}) : _client = client ?? http.Client();

  Uri get _endpoint {
    final configured = EnvLoader.get('PRACTICE_API_URL');
    return Uri.base.resolve(configured ?? '/api/grade-answer');
  }

  Future<PracticeFeedback> gradeAnswer({
    required PracticeItem item,
    required String userAnswer,
  }) async {
    try {
      final res = await _client.post(
        _endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'item': item.toJson(),
          'userAnswer': userAnswer,
        }),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return PracticeFeedback(
          score: 0,
          feedback: 'Practice grading failed (${res.statusCode}). ${res.body}',
          improvedAnswer: '',
        );
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PracticeFeedback.fromJson(data);
    } catch (e) {
      return PracticeFeedback(
        score: 0,
        feedback:
            'Could not reach the practice grading service. On Netlify, make sure the /api/grade-answer function is deployed. Error: $e',
        improvedAnswer: '',
      );
    }
  }
}
