import 'package:flutter/material.dart';
import '../shell/app_shell.dart';
import 'course_content_viewer.dart';
import 'course_models.dart';

class CourseDetailPage extends StatelessWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

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

    final all = course.allLessons;
    final doneCount = all.where((l) => state.isCourseLessonDone(l.id)).length;
    final total = all.length;
    final progress = total == 0 ? 0.0 : doneCount / total;
    final accent = _accentForCourse();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: 0.85),
                  accent.withValues(alpha: 0.70),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                  ),
                  child: Center(
                    child: Icon(_iconForCourse(), color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$doneCount / $total lessons - ${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final m in course.modules) ...[
            _ModuleCard(
              courseTitle: course.title,
              module: m,
              accent: accent,
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String courseTitle;
  final CourseModule module;
  final Color accent;

  const _ModuleCard({
    required this.courseTitle,
    required this.module,
    required this.accent,
  });

  bool _isLessonUnlocked(AppState state, CourseLesson lesson) {
    final idx = module.lessons.indexWhere((l) => l.id == lesson.id);
    if (idx <= 0) return true;
    final prev = module.lessons[idx - 1];
    return state.isCourseLessonDone(prev.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final total = module.lessons.length;
    final done = module.lessons.where((l) => state.isCourseLessonDone(l.id)).length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            module.subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$done / $total lessons',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 14),
          for (final lesson in module.lessons) ...[
            _LessonTile(
              courseTitle: courseTitle,
              lesson: lesson,
              locked: !_isLessonUnlocked(state, lesson),
              done: state.isCourseLessonDone(lesson.id),
              accent: accent,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final String courseTitle;
  final CourseLesson lesson;
  final bool locked;
  final bool done;
  final Color accent;

  const _LessonTile({
    required this.courseTitle,
    required this.lesson,
    required this.locked,
    required this.done,
    required this.accent,
  });

  IconData _icon() {
    if (done) return Icons.check_circle;
    if (locked) return Icons.lock;
    return lesson.kind == CourseLessonKind.read ? Icons.auto_stories_rounded : Icons.play_circle_fill_rounded;
  }

  String _kindLabel() => lesson.kind == CourseLessonKind.read ? 'Read' : 'Watch';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final icon = _icon();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: locked
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AppScope(
                    notifier: state,
                    child: CourseContentViewer(
                      courseTitle: courseTitle,
                      lesson: lesson,
                    ),
                  ),
                ),
              );
            },
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: done
              ? accent.withValues(alpha: 0.13)
              : locked
                  ? const Color(0xFFF2F2F7)
                  : Colors.white,
          border: Border.all(
            color: done
                ? accent.withValues(alpha: 0.28)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: done
                    ? accent.withValues(alpha: 0.20)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                icon,
                color: done ? accent : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: accent.withValues(alpha: 0.12),
              ),
              child: Text(
                _kindLabel(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
