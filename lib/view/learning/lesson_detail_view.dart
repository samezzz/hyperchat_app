import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../model/learning_path.dart';
import '../../services/tts_service.dart';

class LessonDetailView extends StatefulWidget {
  final LearningLesson lesson;
  final String pathColor;

  const LessonDetailView({
    Key? key,
    required this.lesson,
    required this.pathColor,
  }) : super(key: key);

  @override
  State<LessonDetailView> createState() => _LessonDetailViewState();
}

class _LessonDetailViewState extends State<LessonDetailView> {
  final TTSService _ttsService = TTSService();
  bool _isPlaying = false;

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
          widget.lesson.title,
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Color(int.parse(widget.pathColor.replaceAll('#', '0xFF'))),
            ),
            onPressed: () async {
              if (_isPlaying) {
                await _ttsService.pause();
              } else {
                await _ttsService.speak(widget.lesson.content);
              }
              setState(() {
                _isPlaying = !_isPlaying;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(int.parse(widget.pathColor.replaceAll('#', '0xFF'))).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Color(int.parse(widget.pathColor.replaceAll('#', '0xFF'))),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.lesson.duration} min',
                      style: TextStyle(
                        color: Color(int.parse(widget.pathColor.replaceAll('#', '0xFF'))),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Lesson content
              Text(
                widget.lesson.content,
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              
              if (widget.lesson.resources != null && widget.lesson.resources!.isNotEmpty) ...[
                const SizedBox(height: 30),
                Text(
                  'Additional Resources',
                  style: TextStyle(
                    color: TColor.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.lesson.resources!.map((resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: TColor.primaryColor1,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resource,
                          style: TextStyle(
                            color: TColor.primaryColor1,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 