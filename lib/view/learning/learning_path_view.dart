import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../model/learning_path.dart';
import '../../services/learning_service.dart';
import 'lesson_detail_view.dart';

class LearningPathView extends StatefulWidget {
  final LearningPath path;

  const LearningPathView({Key? key, required this.path}) : super(key: key);

  @override
  State<LearningPathView> createState() => _LearningPathViewState();
}

class _LearningPathViewState extends State<LearningPathView> {
  final LearningService _learningService = LearningService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.bgColor,
      appBar: AppBar(
        backgroundColor: TColor.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TColor.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.path.title,
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Path Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.path.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.path.description,
                    style: TextStyle(
                      color: TColor.subTextColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: widget.path.progress,
                    backgroundColor: TColor.secondaryColor2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(int.parse(widget.path.color.replaceAll('#', '0xFF'))),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.path.completedLessons}/${widget.path.totalLessons} lessons completed',
                    style: TextStyle(
                      color: TColor.subTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Lessons List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Lessons',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.path.lessons.length,
              itemBuilder: (context, index) {
                final lesson = widget.path.lessons[index];
                return _buildLessonCard(lesson);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(LearningLesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: TColor.secondaryColor2,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TColor.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LessonDetailView(
                  lesson: lesson,
                  pathColor: widget.path.color,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(widget.path.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    lesson.isCompleted ? Icons.check : Icons.play_arrow,
                    color: Color(int.parse(widget.path.color.replaceAll('#', '0xFF'))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lesson.duration} min',
                        style: TextStyle(
                          color: TColor.primaryColor2,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (lesson.isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: Color(int.parse(widget.path.color.replaceAll('#', '0xFF'))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 