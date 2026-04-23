class PracticeItem {
  final String id;
  final String title;
  final String prompt;
  final String rubric;
  final String difficulty; // "Easy" | "Medium" | "Hard"
  final List<String> tags;

  const PracticeItem({
    required this.id,
    required this.title,
    required this.prompt,
    required this.rubric,
    this.difficulty = 'Easy',
    this.tags = const [],
  });
}

class PracticeFeedback {
  final int score; // 0-100
  final String feedback;
  final String improvedAnswer;

  const PracticeFeedback({
    required this.score,
    required this.feedback,
    required this.improvedAnswer,
  });

  factory PracticeFeedback.fallback() {
    return const PracticeFeedback(
      score: 0,
      feedback: 'Feedback service not available yet.',
      improvedAnswer: '',
    );
  }
}
