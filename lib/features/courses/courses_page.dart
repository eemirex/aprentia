import 'package:flutter/material.dart';
import '../shell/app_shell.dart';
import 'course_detail_page.dart';
import 'course_models.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  List<Course> _courses() {
    return <Course>[
      Course(
        id: 'prompting_foundations',
        title: 'Prompting Foundations',
        subtitle: 'Write prompts that produce reliable output.',
        modules: const [
          CourseModule(
            id: 'pf_m1',
            title: 'Module 1 - The Prompt Recipe',
            subtitle: 'Goal + Context + Constraints + Format',
            lessons: [
              CourseLesson(
                id: 'pf_m1_l1',
                kind: CourseLessonKind.read,
                title: 'Lesson 1: The 4-part prompt',
                subtitle: 'A simple structure that upgrades results.',
                markdown: '''
# The 4-part prompt

A strong prompt usually contains:

- **Goal**: what outcome you want
- **Context**: who/what/why
- **Constraints**: length, tone, rules, limits
- **Output format**: bullets, table, JSON, steps

## Example
**Goal:** Write a pricing email
**Context:** existing customer, renewal
**Constraints:** max 120 words, direct tone
**Format:** 3 options + CTA
''',
              ),
              CourseLesson(
                id: 'pf_m1_l2',
                kind: CourseLessonKind.read,
                title: 'Lesson 2: Improve a weak prompt',
                subtitle: 'Turn a vague request into a useful brief.',
                markdown: '''
# Improve a weak prompt

Start with a vague request:

> Write a launch email.

Add the missing ingredients:

- **Goal:** announce the product launch
- **Context:** existing customers already know the brand
- **Constraints:** warm tone, fewer than 120 words
- **Format:** subject line, short body, one call to action

## Practice habit

Before sending a prompt, check whether another person could produce the result from the same instructions. If not, add the missing context or constraint.
''',
              ),
            ],
          ),
        ],
      ),
      Course(
        id: 'safety_verification',
        title: 'Safety & Verification',
        subtitle: 'Reduce hallucinations and verify confidently.',
        modules: const [
          CourseModule(
            id: 'sv_m1',
            title: 'Module 1 - Safe Answering',
            subtitle: 'Assumptions, sources, uncertainty',
            lessons: [
              CourseLesson(
                id: 'sv_m1_l1',
                kind: CourseLessonKind.read,
                title: 'Verification habits',
                subtitle: 'How to stay accurate when unsure.',
                markdown: '''
# Verification habits

- List assumptions clearly
- Ask one clarifying question when needed
- Add sources/links when possible
- Flag uncertainty instead of guessing

## The payoff
Your answers become trustworthy, repeatable, and client-safe.
''',
              ),
            ],
          ),
        ],
      ),
      Course(
        id: 'email_mastery',
        title: 'Email Prompting',
        subtitle: 'Write sharper emails faster.',
        modules: const [
          CourseModule(
            id: 'em_m1',
            title: 'Module 1 - Better Business Emails',
            subtitle: 'Tone, brevity, CTA',
            lessons: [
              CourseLesson(
                id: 'em_m1_l1',
                kind: CourseLessonKind.read,
                title: 'The ideal email structure',
                subtitle: 'Subject, intent, CTA, tone.',
                markdown: '''
# Better email prompts

Ask for:
- a specific audience
- a target tone
- a word limit
- a clear CTA

## Example
Write a renewal reminder email for a current customer in a direct but warm tone under 120 words with one CTA.
''',
              ),
              CourseLesson(
                id: 'em_m1_l2',
                kind: CourseLessonKind.read,
                title: 'Transform a weak email request',
                subtitle: 'Compare an underspecified prompt with a strong one.',
                markdown: '''
# Transform an email request

**Weak prompt**

> Write an email asking for the report.

**Stronger prompt**

> Write a concise follow-up email to a project partner who missed yesterday's report deadline. Use a calm, professional tone, ask for the report by 2 PM today, and include one sentence offering help. Keep it under 100 words.

The stronger version defines the relationship, situation, deadline, tone, helpful next step, and length.
''',
              ),
            ],
          ),
        ],
      ),
      Course(
        id: 'summaries_briefs',
        title: 'Summaries & Briefs',
        subtitle: 'Turn long text into useful outputs.',
        modules: const [
          CourseModule(
            id: 'sb_m1',
            title: 'Module 1 - Structured Summaries',
            subtitle: 'Bullets, takeaways, next steps',
            lessons: [
              CourseLesson(
                id: 'sb_m1_l1',
                kind: CourseLessonKind.read,
                title: 'Prompting better summaries',
                subtitle: 'Control length and format.',
                markdown: '''
# Prompting better summaries

Good summary prompts specify:
- number of bullets
- target audience
- whether key risks should be included
- the final format

## Example
Summarize this report in 5 bullets for a manager and add 3 action points.
''',
              ),
            ],
          ),
        ],
      ),
      Course(
        id: 'research_workflows',
        title: 'Research Workflows',
        subtitle: 'Ask better, verify faster.',
        modules: const [
          CourseModule(
            id: 'rw_m1',
            title: 'Module 1 - Research in steps',
            subtitle: 'Scope, sources, synthesis',
            lessons: [
              CourseLesson(
                id: 'rw_m1_l1',
                kind: CourseLessonKind.read,
                title: 'Break research into stages',
                subtitle: 'Better than one giant question.',
                markdown: '''
# Research in stages

Instead of one huge prompt:
1. define the scope
2. gather sources
3. compare findings
4. synthesize the result

This produces cleaner, more trustworthy work.
''',
              ),
            ],
          ),
        ],
      ),
      Course(
        id: 'creative_prompting',
        title: 'Creative Prompting',
        subtitle: 'Generate ideas with more originality.',
        modules: const [
          CourseModule(
            id: 'cp_m1',
            title: 'Module 1 - Idea generation',
            subtitle: 'Variation, constraints, surprise',
            lessons: [
              CourseLesson(
                id: 'cp_m1_l1',
                kind: CourseLessonKind.read,
                title: 'Prompt for stronger ideas',
                subtitle: 'Use variation and constraints.',
                markdown: '''
# Better idea generation

Creativity improves when you ask for:
- multiple directions
- different tones
- surprising options
- constraints that force originality

## Example
Give me 10 campaign ideas: 3 bold, 3 emotional, 4 practical.
''',
              ),
            ],
          ),
        ],
      ),
      Course(
        id: 'career_ai',
        title: 'Career with AI',
        subtitle: 'Use prompting in your daily work.',
        modules: const [
          CourseModule(
            id: 'ca_m1',
            title: 'Module 1 - Work smarter',
            subtitle: 'Meetings, reports, planning',
            lessons: [
              CourseLesson(
                id: 'ca_m1_l1',
                kind: CourseLessonKind.read,
                title: 'Everyday work prompts',
                subtitle: 'Use AI for common work tasks.',
                markdown: '''
# Everyday work prompts

AI can help with:
- meeting notes
- task lists
- presentation outlines
- difficult messages
- weekly planning

The stronger your prompt, the less editing you do later.
''',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final courses = _courses();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: _HeartsMini(
                hearts: state.hearts,
                countdown: state.nextHeartCountdown,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _TopHeroCard(
            xp: state.xp,
            streak: state.streak,
            courseLessonsDone: state.courseLessonsDoneCount,
          ),
          const SizedBox(height: 16),
          for (final c in courses) ...[
            _CourseCard(course: c),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _TopHeroCard extends StatelessWidget {
  final int xp;
  final int streak;
  final int courseLessonsDone;

  const _TopHeroCard({
    required this.xp,
    required this.streak,
    required this.courseLessonsDone,
  });

  @override
  Widget build(BuildContext context) {
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
            'Learn with color and momentum',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Short lessons, visible progress, and playful activities.',
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
              _StatChip(label: 'XP', value: '$xp'),
              _StatChip(label: 'Streak', value: '$streak'),
              _StatChip(label: 'Lessons', value: '$courseLessonsDone'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
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

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  Color _accentForCourse() {
    switch (course.id) {
      case 'prompting_foundations':
        return const Color(0xFF8B5CF6);
      case 'safety_verification':
        return const Color(0xFF06B6D4);
      case 'email_mastery':
        return const Color(0xFFF59E0B);
      case 'summaries_briefs':
        return const Color(0xFF10B981);
      case 'research_workflows':
        return const Color(0xFFEC4899);
      case 'creative_prompting':
        return const Color(0xFFEF4444);
      case 'career_ai':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _iconForCourse() {
    switch (course.id) {
      case 'prompting_foundations':
        return Icons.auto_awesome;
      case 'safety_verification':
        return Icons.verified_user;
      case 'email_mastery':
        return Icons.mail;
      case 'summaries_briefs':
        return Icons.summarize;
      case 'research_workflows':
        return Icons.manage_search;
      case 'creative_prompting':
        return Icons.palette;
      case 'career_ai':
        return Icons.rocket_launch;
      default:
        return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final total = course.totalLessons;
    final done = course.allLessons.where((l) => state.isCourseLessonDone(l.id)).length;
    final pct = total == 0 ? 0 : ((done / total) * 100).round();
    final accent = _accentForCourse();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AppScope(
              notifier: state,
              child: CourseDetailPage(course: course),
            ),
          ),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: accent.withValues(alpha: 0.14),
                  ),
                  child: Center(
                    child: Icon(_iconForCourse(), color: accent, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.subtitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (done / total),
                minHeight: 12,
                backgroundColor: accent.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$done / $total lessons',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartsMini extends StatelessWidget {
  final int hearts;
  final String countdown;
  const _HeartsMini({required this.hearts, required this.countdown});

  @override
  Widget build(BuildContext context) {
    final showCountdown = hearts < AppState.maxHearts && countdown.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4DCF8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 6),
          Text(
            '$hearts',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (showCountdown) ...[
            const SizedBox(width: 8),
            Text(
              countdown,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
