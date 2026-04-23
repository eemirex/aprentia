class PracticeItem {
  final String id;
  final String title;
  final String prompt;
  final String rubric;
  final String difficulty;
  final List<String> tags;
  final String tip;

  const PracticeItem({
    required this.id,
    required this.title,
    required this.prompt,
    required this.rubric,
    required this.difficulty,
    required this.tags,
    required this.tip,
  });

  factory PracticeItem.fromJson(Map<String, dynamic> json) {
    return PracticeItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      rubric: (json['rubric'] ?? '').toString(),
      difficulty: (json['difficulty'] ?? 'Easy').toString(),
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      tip: (json['tip'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'prompt': prompt,
        'rubric': rubric,
        'difficulty': difficulty,
        'tags': tags,
        'tip': tip,
      };
}

class PracticeFeedback {
  final int score; // 0..100
  final String feedback;
  final String improvedAnswer;

  const PracticeFeedback({
    required this.score,
    required this.feedback,
    required this.improvedAnswer,
  });

  factory PracticeFeedback.fromJson(Map<String, dynamic> json) {
    final s = json['score'];
    final score = (s is num) ? s.toInt() : int.tryParse('$s') ?? 0;

    return PracticeFeedback(
      score: score,
      feedback: (json['feedback'] ?? '').toString(),
      improvedAnswer: (json['improvedAnswer'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'feedback': feedback,
        'improvedAnswer': improvedAnswer,
      };
}

class PracticeAttempt {
  final String id;
  final int atMs; // timestamp (millisecondsSinceEpoch)
  final String itemId;

  final String title;
  final String difficulty;
  final List<String> tags;

  final int score; // 0..100
  final int xpEarned;
  final int answerChars;

  final String feedbackSnippet;
  final String improvedSnippet;

  const PracticeAttempt({
    required this.id,
    required this.atMs,
    required this.itemId,
    required this.title,
    required this.difficulty,
    required this.tags,
    required this.score,
    required this.xpEarned,
    required this.answerChars,
    required this.feedbackSnippet,
    required this.improvedSnippet,
  });

  factory PracticeAttempt.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, int fallback) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? fallback;
    }

    return PracticeAttempt(
      id: (json['id'] ?? '').toString(),
      atMs: parseInt(json['atMs'], DateTime.now().millisecondsSinceEpoch),
      itemId: (json['itemId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      difficulty: (json['difficulty'] ?? '').toString(),
      tags: ((json['tags'] as List?) ?? const []).map((e) => e.toString()).toList(),
      score: parseInt(json['score'], 0).clamp(0, 100),
      xpEarned: parseInt(json['xpEarned'], 0),
      answerChars: parseInt(json['answerChars'], 0),
      feedbackSnippet: (json['feedbackSnippet'] ?? '').toString(),
      improvedSnippet: (json['improvedSnippet'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'atMs': atMs,
        'itemId': itemId,
        'title': title,
        'difficulty': difficulty,
        'tags': tags,
        'score': score,
        'xpEarned': xpEarned,
        'answerChars': answerChars,
        'feedbackSnippet': feedbackSnippet,
        'improvedSnippet': improvedSnippet,
      };
}
