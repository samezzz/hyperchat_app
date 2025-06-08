import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/theme_provider.dart';
import '../profile/profile_view.dart';
import '../../common/colo_extension.dart';
import '../../services/learning_service.dart';
import '../../model/learning_path.dart';
import '../learning/learning_path_view.dart';

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  final LearningService _learningService = LearningService();

  List<Map<String, dynamic>> _getLearningModules(BuildContext context) {
    return [
      {
        'icon': '🧂',
        'title': 'Sodium Myths',
        'description': 'Learn the truth about salt and blood pressure',
        'color': TColor.primaryColor2.withOpacity(0.1),
      },
      {
        'icon': '🧘',
        'title': 'Breathing Exercises',
        'description': 'Simple techniques to lower your BP naturally',
        'color': TColor.secondaryColor1.withOpacity(0.1),
      },
      {
        'icon': '📈',
        'title': 'Understanding Your BP Numbers',
        'description': 'What do your readings really mean?',
        'color': TColor.primaryColor2.withOpacity(0.1),
      },
    ];
  }

  Widget _buildCard({required Widget child, Color? backgroundColor}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDarkMode
                ? TColor.darkSurface
                : TColor.secondaryColor2.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: TColor.subTextColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildLearningPaths() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<LearningPath>>(
      stream: _learningService.getLearningPaths(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading learning paths',
              style: TextStyle(color: TColor.subTextColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // If no data in Firestore, use default learning paths
          final defaultPaths = _learningService.getDefaultLearningPaths();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Learning Paths',
                  style: TextStyle(
                    color: TColor.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ...defaultPaths.map(
                (path) => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: _buildCard(
                    backgroundColor: isDarkMode
                        ? TColor.darkSurface.withOpacity(0.1)
                        : Color(int.parse(path.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LearningPathView(path: path),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              path.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    path.title,
                                    style: TextStyle(
                                      color: TColor.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${path.completedLessons}/${path.totalLessons} completed',
                                    style: TextStyle(
                                      color: TColor.subTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: path.progress,
                                    backgroundColor: isDarkMode
                                        ? TColor.darkGray
                                        : TColor.secondaryColor2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      TColor.primaryColor1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final paths = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Learning Paths',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 15),
            ...paths.map(
              (path) => Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: _buildCard(
                  backgroundColor: Color(int.parse(path.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningPathView(path: path),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(path.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  path.title,
                                  style: TextStyle(
                                    color: TColor.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${path.completedLessons}/${path.totalLessons} completed',
                                  style: TextStyle(
                                    color: TColor.subTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: path.progress,
                                  backgroundColor: isDarkMode
                                      ? TColor.darkGray.withOpacity(0.5)
                                      : TColor.secondaryColor2.withOpacity(0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    TColor.primaryColor1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    final learningModules = _getLearningModules(context);

    return Scaffold(
      backgroundColor: TColor.bgColor,
      appBar: AppBar(
        backgroundColor: TColor.bgColor,
        elevation: 0,
        title: Text(
          'Insights',
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
            // Learning Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn & Improve',
                    style: TextStyle(
                      color: TColor.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: learningModules.length,
                      itemBuilder: (context, index) {
                        final module = learningModules[index];
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 15),
                          child: _buildCard(
                            backgroundColor: module['color'] as Color,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  module['icon'] as String,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  module['title'] as String,
                                  style: TextStyle(
                                    color: TColor.textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  module['description'] as String,
                                  style: TextStyle(
                                    color: TColor.subTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Learning Paths
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildLearningPaths(),
            ),
          ],
        ),
      ),
    );
  }
} 