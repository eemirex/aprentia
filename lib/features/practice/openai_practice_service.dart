import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'practice_models.dart';

class OpenAIPracticeService {
  final http.Client _client;

  OpenAIPracticeService({http.Client? client}) : _client = client ?? http.Client();

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];
  String get _model => dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

  Future<PracticeFeedback> gradeAnswer({
    required PracticeItem item,
    required String userAnswer,
  }) async {
    final key = _apiKey;
    if (key == null || key.trim().isEmpty) {
      return const PracticeFeedback(
        score: 0,
        feedback: 'OPENAI_API_KEY is missing. Add it to .env and restart the app.',
        improvedAnswer: '',
      );
    }

    final system = '''
You are a strict but supportive coach for learning prompting.
Return ONLY valid JSON with keys:
score (0-100 integer), feedback (string), improvedAnswer (string).
No extra text. No markdown.
''';

    final user = '''
TASK PROMPT:
${item.prompt}

RUBRIC:
${item.rubric}

USER ANSWER:
$userAnswer

Grade the answer using the rubric and improve it.
Return JSON only.
''';

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final res = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
          'temperature': 0.2,
        }),
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return PracticeFeedback(
          score: 0,
          feedback: 'OpenAI request failed (${res.statusCode}). ${res.body}',
          improvedAnswer: '',
        );
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String;

      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final score = (parsed['score'] as num).toInt();
      final feedback = (parsed['feedback'] ?? '').toString();
      final improved = (parsed['improvedAnswer'] ?? '').toString();

      return PracticeFeedback(
        score: score.clamp(0, 100),
        feedback: feedback,
        improvedAnswer: improved,
      );
    } catch (e) {
      return PracticeFeedback(
        score: 0,
        feedback: 'Error: $e',
        improvedAnswer: '',
      );
    }
  }
}
