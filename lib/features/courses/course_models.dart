enum CourseLessonKind { read, watch }

class CourseLesson {
  final String id;
  final CourseLessonKind kind;
  final String title;
  final String subtitle;

  // read
  final String markdown;

  // watch
  final String videoUrl;

  const CourseLesson({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.markdown = '',
    this.videoUrl = '',
  });

  bool get hasContent {
    if (kind == CourseLessonKind.read) return markdown.trim().isNotEmpty;
    return videoUrl.trim().isNotEmpty;
  }
}

class CourseModule {
  final String id;
  final String title;
  final String subtitle;
  final List<CourseLesson> lessons;

  const CourseModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessons,
  });
}

class Course {
  final String id;
  final String title;
  final String subtitle;
  final List<CourseModule> modules;

  const Course({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.modules,
  });

  List<CourseLesson> get allLessons =>
      modules.expand((m) => m.lessons).toList(growable: false);

  int get totalLessons => allLessons.length;
}
