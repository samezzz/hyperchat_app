class LearningPath {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int totalLessons;
  final int completedLessons;
  final List<LearningLesson> lessons;
  final String color;

  LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.totalLessons,
    required this.completedLessons,
    required this.lessons,
    required this.color,
  });

  double get progress => completedLessons / totalLessons;
}

class LearningLesson {
  final String id;
  final String title;
  final String content;
  final String? videoUrl;
  final List<String>? resources;
  final bool isCompleted;
  final int duration; // in minutes

  LearningLesson({
    required this.id,
    required this.title,
    required this.content,
    this.videoUrl,
    this.resources,
    this.isCompleted = false,
    required this.duration,
  });
} 