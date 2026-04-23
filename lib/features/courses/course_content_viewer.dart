import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shell/app_shell.dart';
import 'course_models.dart';

class CourseContentViewer extends StatefulWidget {
  final String courseTitle;
  final CourseLesson lesson;

  const CourseContentViewer({
    super.key,
    required this.courseTitle,
    required this.lesson,
  });

  @override
  State<CourseContentViewer> createState() => _CourseContentViewerState();
}

class _CourseContentViewerState extends State<CourseContentViewer> {
  int _page = 0;
  bool _completing = false;

  final List<String> _matchedLeft = [];
  final List<String> _matchedRight = [];
  String? _selectedLeft;
  String? _selectedRight;
  bool _matchSolved = false;

  late final _WordPuzzleData _wordPuzzle = _buildWordPuzzle();

  List<_MatchPair> get _pairs {
    if (widget.lesson.id == 'pf_m1_l1') {
      return const [
        _MatchPair('Goal', 'What outcome you want'),
        _MatchPair('Context', 'Who, what, and why'),
        _MatchPair('Constraints', 'Rules, limits, tone, and length'),
        _MatchPair('Format', 'How the answer should be returned'),
      ];
    }
    return const [];
  }

  int get _pageCount {
    if (widget.lesson.kind == CourseLessonKind.watch) return 2;

    if (widget.lesson.id == 'pf_m1_l1') return 3;
    if (widget.lesson.id == 'sv_m1_l1') return 3;

    return 2;
  }

  Color get _accent {
    switch (widget.lesson.id) {
      case 'pf_m1_l1':
      case 'pf_m1_l2':
        return const Color(0xFF8B5CF6);
      case 'sv_m1_l1':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  Future<void> _openVideo(BuildContext context) async {
    final url = widget.lesson.videoUrl?.trim() ?? '';
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _toast(context, 'Invalid video URL');
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast(context, 'Could not open the video');
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  bool get _isLastPage => _page == _pageCount - 1;

  bool get _canGoNext {
    if (widget.lesson.id == 'pf_m1_l1' && _page == 2) {
      return _matchSolved;
    }
    if (widget.lesson.id == 'sv_m1_l1' && _page == 2) {
      return _wordPuzzle.solved;
    }
    return true;
  }

  Future<void> _completeLesson() async {
    if (_completing) return;

    final state = AppScope.of(context);
    final done = state.isCourseLessonDone(widget.lesson.id);
    if (done) return;

    setState(() => _completing = true);
    await state.completeCourseLesson(widget.lesson.id, xpAward: 15);

    if (!mounted) return;

    setState(() => _completing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson completed +15 XP')),
    );
  }

  void _onLeftTap(String value) {
    if (_matchedLeft.contains(value)) return;
    setState(() {
      _selectedLeft = value;
    });
    _tryValidate();
  }

  void _onRightTap(String value) {
    if (_matchedRight.contains(value)) return;
    setState(() {
      _selectedRight = value;
    });
    _tryValidate();
  }

  void _tryValidate() {
    if (_selectedLeft == null || _selectedRight == null) return;

    final pair = _pairs.where((p) => p.left == _selectedLeft).first;
    final correct = pair.right == _selectedRight;

    if (correct) {
      setState(() {
        _matchedLeft.add(_selectedLeft!);
        _matchedRight.add(_selectedRight!);
        _selectedLeft = null;
        _selectedRight = null;
        _matchSolved = _matchedLeft.length == _pairs.length;
      });
      _toast(context, 'Nice match');
    } else {
      setState(() {
        _selectedLeft = null;
        _selectedRight = null;
      });
      _toast(context, 'Try again');
    }
  }

  _WordPuzzleData _buildWordPuzzle() {
    if (widget.lesson.id != 'sv_m1_l1') {
      return _WordPuzzleData.empty();
    }

    return _WordPuzzleData(
      grid: const [
        ['V', 'E', 'R', 'I', 'F', 'Y'],
        ['A', 'S', 'K', 'Q', 'W', 'T'],
        ['S', 'O', 'U', 'R', 'C', 'E'],
        ['U', 'N', 'C', 'E', 'R', 'T'],
        ['C', 'L', 'A', 'R', 'I', 'F'],
        ['Y', 'F', 'L', 'A', 'G', 'S'],
      ],
      words: const ['VERIFY', 'SOURCE', 'CLARIFY'],
    );
  }

  void _onPuzzleCellTap(int row, int col) {
    if (widget.lesson.id != 'sv_m1_l1') return;
    if (_wordPuzzle.solved) return;

    final char = _wordPuzzle.grid[row][col];

    setState(() {
      _wordPuzzle.selectedCells.add(_Cell(row, col));
      _wordPuzzle.currentWord += char;
    });

    for (final word in _wordPuzzle.words) {
      if (_wordPuzzle.foundWords.contains(word)) continue;

      if (_wordPuzzle.currentWord == word) {
        setState(() {
          _wordPuzzle.foundWords.add(word);
          _wordPuzzle.currentWord = '';
          _wordPuzzle.selectedCells.clear();
          _wordPuzzle.solved = _wordPuzzle.foundWords.length == _wordPuzzle.words.length;
        });
        _toast(context, 'Found $word');
        return;
      }
    }

    final anyStartsWith = _wordPuzzle.words.any(
      (w) => !_wordPuzzle.foundWords.contains(w) && w.startsWith(_wordPuzzle.currentWord),
    );

    if (!anyStartsWith) {
      setState(() {
        _wordPuzzle.currentWord = '';
        _wordPuzzle.selectedCells.clear();
      });
      _toast(context, 'Keep searching');
    }
  }

  Widget _buildStepContent() {
    if (widget.lesson.kind == CourseLessonKind.watch) {
      if (_page == 0) {
        return _LessonIntroCard(
          accent: _accent,
          emoji: '🎬',
          title: widget.lesson.title,
          subtitle: widget.lesson.subtitle,
          kicker: widget.courseTitle,
          body:
              'This is a watch lesson. Open the walkthrough, notice how the structure is used, then continue.',
        );
      }

      return _WatchLessonCard(
        accent: _accent,
        url: widget.lesson.videoUrl ?? '',
        onOpen: () => _openVideo(context),
      );
    }

    if (widget.lesson.id == 'pf_m1_l1') {
      if (_page == 0) {
        return _LessonIntroCard(
          accent: _accent,
          emoji: '🤖',
          title: widget.lesson.title,
          subtitle: widget.lesson.subtitle,
          kicker: widget.courseTitle,
          body:
              'Strong prompts become easier when you follow a clear recipe. Learn the four building blocks, then complete the matching activity.',
        );
      }

      if (_page == 1) {
        return _ConceptCard(
          accent: _accent,
          title: 'The 4-part recipe',
          items: const [
            _ConceptItem('Goal', 'What result you want the model to produce'),
            _ConceptItem('Context', 'Who the answer is for and why it matters'),
            _ConceptItem('Constraints', 'Rules like tone, length, and limits'),
            _ConceptItem('Format', 'The structure of the final answer'),
          ],
        );
      }

      return _MatchingActivityCard(
        accent: _accent,
        pairs: _pairs,
        selectedLeft: _selectedLeft,
        selectedRight: _selectedRight,
        matchedLeft: _matchedLeft,
        matchedRight: _matchedRight,
        onLeftTap: _onLeftTap,
        onRightTap: _onRightTap,
        solved: _matchSolved,
      );
    }

    if (widget.lesson.id == 'sv_m1_l1') {
      if (_page == 0) {
        return _LessonIntroCard(
          accent: _accent,
          emoji: '🧠',
          title: widget.lesson.title,
          subtitle: widget.lesson.subtitle,
          kicker: widget.courseTitle,
          body:
              'Safe prompting means verifying, clarifying, and showing uncertainty honestly. Read the idea, then solve a word puzzle.',
        );
      }

      if (_page == 1) {
        return _MarkdownLessonCard(
          accent: _accent,
          markdown: widget.lesson.markdown ?? '',
        );
      }

      return _WordPuzzleCard(
        accent: _accent,
        puzzle: _wordPuzzle,
        onCellTap: _onPuzzleCellTap,
      );
    }

    if (_page == 0) {
      return _LessonIntroCard(
        accent: _accent,
        emoji: '📘',
        title: widget.lesson.title,
        subtitle: widget.lesson.subtitle,
        kicker: widget.courseTitle,
        body: 'Read the lesson, then continue to complete it.',
      );
    }

    return _MarkdownLessonCard(
      accent: _accent,
      markdown: widget.lesson.markdown ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = state.isCourseLessonDone(widget.lesson.id);
    final progress = (_page + 1) / _pageCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE4DCF8),
                        valueColor: AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ...List.generate(
                    AppState.maxHearts,
                    (i) => Padding(
                      padding: EdgeInsets.only(right: i == AppState.maxHearts - 1 ? 0 : 4),
                      child: Icon(
                        i < state.hearts ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                children: [
                  _buildStepContent(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              color: const Color(0xFFF7F4FF),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _page -= 1;
                          });
                        },
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 7,
                    child: ElevatedButton(
                      onPressed: done
                          ? null
                          : _isLastPage
                              ? (_completing ? null : _completeLesson)
                              : (_canGoNext
                                  ? () {
                                      setState(() {
                                        _page += 1;
                                      });
                                    }
                                  : null),
                      child: Text(
                        done
                            ? 'Completed'
                            : _isLastPage
                                ? (_completing ? 'Saving...' : 'Finish lesson')
                                : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonIntroCard extends StatelessWidget {
  final Color accent;
  final String emoji;
  final String title;
  final String subtitle;
  final String kicker;
  final String body;

  const _LessonIntroCard({
    required this.accent,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.kicker,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 38),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            kicker,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptCard extends StatelessWidget {
  final Color accent;
  final String title;
  final List<_ConceptItem> items;

  const _ConceptCard({
    required this.accent,
    required this.title,
    required this.items,
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in items) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: accent.withValues(alpha: 0.08),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: accent.withValues(alpha: 0.16),
                    ),
                    child: Center(
                      child: Text(
                        item.title.characters.first,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: accent,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkdownLessonCard extends StatelessWidget {
  final Color accent;
  final String markdown;

  const _MarkdownLessonCard({
    required this.accent,
    required this.markdown,
  });

  @override
  Widget build(BuildContext context) {
    final text = markdown.trim().isEmpty ? 'No content yet.' : markdown.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
      ),
      child: MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          h2: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accent),
          p: const TextStyle(fontSize: 17, height: 1.45, fontWeight: FontWeight.w600),
          listBullet: TextStyle(color: accent, fontWeight: FontWeight.w900),
          strong: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _WatchLessonCard extends StatelessWidget {
  final Color accent;
  final String url;
  final VoidCallback onOpen;

  const _WatchLessonCard({
    required this.accent,
    required this.url,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watch lesson',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasUrl ? url : 'No video URL set.',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: hasUrl ? onOpen : null,
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Open video'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withValues(alpha: 0.08),
            ),
            child: const Text(
              'After watching, tap Next and finish the lesson to lock in the progress.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchingActivityCard extends StatelessWidget {
  final Color accent;
  final List<_MatchPair> pairs;
  final String? selectedLeft;
  final String? selectedRight;
  final List<String> matchedLeft;
  final List<String> matchedRight;
  final void Function(String value) onLeftTap;
  final void Function(String value) onRightTap;
  final bool solved;

  const _MatchingActivityCard({
    required this.accent,
    required this.pairs,
    required this.selectedLeft,
    required this.selectedRight,
    required this.matchedLeft,
    required this.matchedRight,
    required this.onLeftTap,
    required this.onRightTap,
    required this.solved,
  });

  @override
  Widget build(BuildContext context) {
    final rightItems = pairs.map((e) => e.right).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match each concept to its description',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            solved
                ? 'Great job. You matched them all.'
                : 'Tap one concept on the left, then its correct meaning on the right.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 600;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ChoiceColumn(
                        title: 'Concepts',
                        items: pairs.map((e) => e.left).toList(),
                        accent: accent,
                        selected: selectedLeft,
                        matched: matchedLeft,
                        onTap: onLeftTap,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ChoiceColumn(
                        title: 'Descriptions',
                        items: rightItems,
                        accent: accent,
                        selected: selectedRight,
                        matched: matchedRight,
                        onTap: onRightTap,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _ChoiceColumn(
                    title: 'Concepts',
                    items: pairs.map((e) => e.left).toList(),
                    accent: accent,
                    selected: selectedLeft,
                    matched: matchedLeft,
                    onTap: onLeftTap,
                  ),
                  const SizedBox(height: 14),
                  _ChoiceColumn(
                    title: 'Descriptions',
                    items: rightItems,
                    accent: accent,
                    selected: selectedRight,
                    matched: matchedRight,
                    onTap: onRightTap,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChoiceColumn extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color accent;
  final String? selected;
  final List<String> matched;
  final void Function(String value) onTap;

  const _ChoiceColumn({
    required this.title,
    required this.items,
    required this.accent,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: accent.withValues(alpha: 0.06),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            _ChoiceTile(
              text: item,
              accent: accent,
              selected: selected == item,
              matched: matched.contains(item),
              onTap: () => onTap(item),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String text;
  final Color accent;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.text,
    required this.accent,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = matched
        ? const Color(0xFF10B981)
        : selected
            ? accent
            : const Color(0xFFE5E7EB);

    final bg = matched
        ? const Color(0xFFDDF8EE)
        : selected
            ? accent.withValues(alpha: 0.12)
            : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: matched ? null : onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color),
          color: bg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: matched ? const Color(0xFF047857) : null,
                  height: 1.25,
                ),
              ),
            ),
            if (matched)
              const Icon(Icons.check_circle, color: Color(0xFF10B981))
            else if (selected)
              Icon(Icons.radio_button_checked, color: accent)
            else
              const Icon(Icons.radio_button_unchecked),
          ],
        ),
      ),
    );
  }
}

class _WordPuzzleCard extends StatelessWidget {
  final Color accent;
  final _WordPuzzleData puzzle;
  final void Function(int row, int col) onCellTap;

  const _WordPuzzleCard({
    required this.accent,
    required this.puzzle,
    required this.onCellTap,
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
          const Text(
            'Word Puzzle: Safety terms',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            puzzle.solved
                ? 'Puzzle solved.'
                : 'Find these words by tapping letters in order.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final word in puzzle.words)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: puzzle.foundWords.contains(word)
                        ? const Color(0xFFDDF8EE)
                        : accent.withValues(alpha: 0.10),
                    border: Border.all(
                      color: puzzle.foundWords.contains(word)
                          ? const Color(0xFF10B981)
                          : accent.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: puzzle.foundWords.contains(word)
                          ? const Color(0xFF047857)
                          : accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            puzzle.currentWord.isEmpty ? 'Current: —' : 'Current: ${puzzle.currentWord}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              for (int r = 0; r < puzzle.grid.length; r++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int c = 0; c < puzzle.grid[r].length; c++) ...[
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: _PuzzleCell(
                          text: puzzle.grid[r][c],
                          accent: accent,
                          selected: puzzle.selectedCells.contains(_Cell(r, c)),
                          onTap: () => onCellTap(r, c),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PuzzleCell extends StatelessWidget {
  final String text;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _PuzzleCell({
    required this.text,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? accent.withValues(alpha: 0.18) : Colors.white,
          border: Border.all(
            color: selected ? accent : const Color(0xFFDADCE5),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: selected ? accent : const Color(0xFF171717),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordPuzzleData {
  final List<List<String>> grid;
  final List<String> words;
  final List<String> foundWords;
  final List<_Cell> selectedCells;
  String currentWord;
  bool solved;

  _WordPuzzleData({
    required this.grid,
    required this.words,
    List<String>? foundWords,
    List<_Cell>? selectedCells,
    this.currentWord = '',
    this.solved = false,
  })  : foundWords = foundWords ?? [],
        selectedCells = selectedCells ?? [];

  factory _WordPuzzleData.empty() {
    return _WordPuzzleData(
      grid: const [],
      words: const [],
    );
  }
}

class _Cell {
  final int row;
  final int col;

  const _Cell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Cell && runtimeType == other.runtimeType && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}

class _MatchPair {
  final String left;
  final String right;

  const _MatchPair(this.left, this.right);
}

class _ConceptItem {
  final String title;
  final String description;

  const _ConceptItem(this.title, this.description);
}