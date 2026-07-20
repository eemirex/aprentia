import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../shell/app_shell.dart';
import 'openai_practice_service.dart';
import 'practice_models.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final OpenAIPracticeService _service = OpenAIPracticeService();

  List<PracticeItem> _items = const [];
  PracticeItem? _selected;

  final _answerCtrl = TextEditingController();
  bool _loading = true;
  bool _grading = false;

  PracticeFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _loadPractice();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPractice() async {
    setState(() => _loading = true);

    try {
      final raw = await rootBundle.loadString('assets/practice_items.json');
      final decoded = jsonDecode(raw) as List;

      final List<PracticeItem> items = decoded
          .map((e) => PracticeItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _items = items;
        _selected = items.isNotEmpty ? items.first : null;
        _loading = false;
      });
    } catch (_) {
      final fallback = <PracticeItem>[
        const PracticeItem(
          id: 'p1',
          title: 'Rewrite an email',
          prompt:
              'Rewrite this email to be clearer and shorter: "Hello Sir, I am writing..."',
          rubric: 'Score higher for clarity, brevity, and a clear CTA.',
          difficulty: 'Easy',
          tags: ['writing', 'clarity'],
          tip: 'Start with the goal, then add only essential context.',
        ),
        const PracticeItem(
          id: 'p2',
          title: 'Summarize with format',
          prompt:
              'Summarize the following text in 5 bullets and add a 1-line takeaway.',
          rubric:
              'Score higher for accurate bullets and a meaningful takeaway.',
          difficulty: 'Medium',
          tags: ['summary', 'format'],
          tip: 'Request a fixed bullet count and a labeled takeaway.',
        ),
      ];

      setState(() {
        _items = fallback;
        _selected = fallback.first;
        _loading = false;
      });
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Color _cardAccent(PracticeItem item) {
    if (item.tags.contains('writing')) return const Color(0xFF8B5CF6);
    if (item.tags.contains('summary')) return const Color(0xFF06B6D4);
    return const Color(0xFF8B5CF6);
  }

  Future<void> _grade() async {
    final state = AppScope.of(context);
    if (_selected == null) return;

    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write an answer first')),
      );
      return;
    }

    if (state.hearts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.nextHeartCountdown.isEmpty
                ? 'No hearts left. Come back soon.'
                : 'No hearts left. Next heart in ${state.nextHeartCountdown}.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _grading = true;
      _feedback = null;
    });

    final fb = await _service.gradeAnswer(
      item: _selected!,
      userAnswer: answer,
    );

    if (!mounted) return;

    final gradingUnavailable = fb.score == 0 &&
        fb.improvedAnswer.trim().isEmpty &&
        (fb.feedback.startsWith('Could not reach') ||
            fb.feedback.startsWith('Practice grading failed'));

    if (gradingUnavailable) {
      setState(() {
        _feedback = fb;
        _grading = false;
      });
      return;
    }

    int xpEarned = 0;
    if (fb.score >= 85) {
      xpEarned = 20;
      await state.completePracticeSession(xpAward: xpEarned);
    } else if (fb.score >= 65) {
      xpEarned = 12;
      await state.completePracticeSession(xpAward: xpEarned);
    } else {
      xpEarned = 0;
      await state.spendHeartIfPossible();
    }

    final attempt = PracticeAttempt(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      atMs: DateTime.now().millisecondsSinceEpoch,
      itemId: _selected!.id,
      title: _selected!.title,
      difficulty: _selected!.difficulty,
      tags: _selected!.tags,
      score: fb.score,
      xpEarned: xpEarned,
      answerChars: answer.length,
      feedbackSnippet: fb.feedback.length > 110
          ? '${fb.feedback.substring(0, 110)}...'
          : fb.feedback,
      improvedSnippet: fb.improvedAnswer.length > 110
          ? '${fb.improvedAnswer.substring(0, 110)}...'
          : fb.improvedAnswer,
    );

    await state.addPracticeAttempt(attempt);

    setState(() {
      _feedback = fb;
      _grading = false;
    });

    if (fb.score < 65) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Low score this round - 1 heart used')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Practice',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
        children: [
          _PracticeHero(
            xp: state.xp,
            streak: state.streak,
            hearts: state.hearts,
            countdown: state.nextHeartCountdown,
          ),
          const SizedBox(height: 16),
          if (selected != null) ...[
            _PromptCard(
              item: selected,
              accent: _cardAccent(selected),
              difficultyColor: _difficultyColor(selected.difficulty),
            ),
            const SizedBox(height: 14),
            if (_items.length > 1)
              _PromptSelector(
                items: _items,
                selectedId: selected.id,
                colorForItem: _cardAccent,
                onSelected: (item) {
                  setState(() {
                    _selected = item;
                    _answerCtrl.clear();
                    _feedback = null;
                  });
                },
              ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Your answer',
              child: Column(
                children: [
                  TextField(
                    controller: _answerCtrl,
                    minLines: 6,
                    maxLines: 14,
                    decoration: InputDecoration(
                      hintText: 'Write your answer here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _grading ? null : _grade,
                      child: Text(_grading ? 'Grading...' : 'Grade with AI'),
                    ),
                  ),
                ],
              ),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 14),
              _FeedbackCard(
                feedback: _feedback!,
                accent: _cardAccent(selected),
              ),
            ],
            const SizedBox(height: 14),
            _RecentAttemptsCard(attempts: state.recentAttempts),
          ],
        ],
      ),
    );
  }
}

class _PracticeHero extends StatelessWidget {
  final int xp;
  final int streak;
  final int hearts;
  final String countdown;

  const _PracticeHero({
    required this.xp,
    required this.streak,
    required this.hearts,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final showCountdown = hearts < AppState.maxHearts && countdown.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
            Color(0xFFC084FC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Practice and level up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Train your prompting with feedback, points, and streaks.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(label: 'XP', value: '$xp'),
              _HeroChip(label: 'Streak', value: '$streak'),
              _HeroChip(
                label: 'Hearts',
                value: showCountdown ? '$hearts - $countdown' : '$hearts',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final PracticeItem item;
  final Color accent;
  final Color difficultyColor;

  const _PromptCard({
    required this.item,
    required this.accent,
    required this.difficultyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.auto_awesome, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                text: item.difficulty,
                bg: difficultyColor.withValues(alpha: 0.14),
                fg: difficultyColor,
              ),
              for (final t in item.tags)
                _TagChip(
                  text: t,
                  bg: accent.withValues(alpha: 0.12),
                  fg: accent,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MiniPanel(
            title: 'Tip',
            child: Text(
              item.tip,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
          const SizedBox(height: 12),
          _MiniPanel(
            title: 'Prompt',
            child: Text(
              item.prompt,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          _MiniPanel(
            title: 'Rubric',
            child: Text(
              item.rubric,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptSelector extends StatelessWidget {
  final List<PracticeItem> items;
  final String selectedId;
  final Color Function(PracticeItem item) colorForItem;
  final void Function(PracticeItem item) onSelected;

  const _PromptSelector({
    required this.items,
    required this.selectedId,
    required this.colorForItem,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Choose a prompt',
      child: Column(
        children: [
          for (final item in items) ...[
            _PromptOptionTile(
              item: item,
              selected: item.id == selectedId,
              accent: colorForItem(item),
              onTap: () => onSelected(item),
            ),
            if (item != items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PromptOptionTile extends StatelessWidget {
  final PracticeItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _PromptOptionTile({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? accent.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(
            color: selected ? accent : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.bolt, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.difficulty,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right_rounded,
              color: selected ? accent : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _MiniPanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF6F3FF),
        border: Border.all(color: const Color(0xFFE7E0FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final PracticeFeedback feedback;
  final Color accent;

  const _FeedbackCard({
    required this.feedback,
    required this.accent,
  });

  Color _scoreColor() {
    if (feedback.score >= 85) return const Color(0xFF10B981);
    if (feedback.score >= 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        border: Border.all(color: scoreColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: scoreColor.withValues(alpha: 0.12),
                ),
                child: Text(
                  'Score: ${feedback.score}/100',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MiniPanel(
            title: 'Feedback',
            child: Text(
              feedback.feedback,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
          const SizedBox(height: 12),
          _MiniPanel(
            title: 'Improved answer',
            child: Text(
              feedback.improvedAnswer.isEmpty ? '(empty)' : feedback.improvedAnswer,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAttemptsCard extends StatelessWidget {
  final List<PracticeAttempt> attempts;

  const _RecentAttemptsCard({
    required this.attempts,
  });

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final shown = attempts.take(8).toList();

    return _SectionCard(
      title: 'Recent attempts',
      child: shown.isEmpty
          ? Text(
              'No attempts yet.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < shown.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shown[i].title,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: _scoreColor(shown[i].score).withValues(alpha: 0.12),
                              ),
                              child: Text(
                                '${shown[i].score}',
                                style: TextStyle(
                                  color: _scoreColor(shown[i].score),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SmallPill(text: shown[i].difficulty),
                            _SmallPill(text: '+${shown[i].xpEarned} XP'),
                            _SmallPill(text: '${shown[i].answerChars} chars'),
                          ],
                        ),
                        if (shown[i].feedbackSnippet.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            shown[i].feedbackSnippet,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (i != shown.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String text;

  const _SmallPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFFF3F4F6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _TagChip({
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
