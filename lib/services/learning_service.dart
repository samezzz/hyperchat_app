import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/learning_path.dart';

class LearningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'learning_paths';

  // Get all learning paths
  Stream<List<LearningPath>> getLearningPaths() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return LearningPath(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          icon: data['icon'] ?? '📚',
          totalLessons: data['totalLessons'] ?? 0,
          completedLessons: data['completedLessons'] ?? 0,
          lessons: _parseLessons(data['lessons'] ?? []),
          color: data['color'] ?? '#4CAF50',
        );
      }).toList();
    });
  }

  // Get a specific learning path
  Future<LearningPath?> getLearningPath(String pathId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(pathId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return LearningPath(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        icon: data['icon'] ?? '📚',
        totalLessons: data['totalLessons'] ?? 0,
        completedLessons: data['completedLessons'] ?? 0,
        lessons: _parseLessons(data['lessons'] ?? []),
        color: data['color'] ?? '#4CAF50',
      );
    } catch (e) {
      print('Error getting learning path: $e');
      return null;
    }
  }

  // Mark a lesson as completed
  Future<void> completeLesson(String pathId, String lessonId) async {
    try {
      final pathRef = _firestore.collection(_collection).doc(pathId);
      final path = await pathRef.get();

      if (!path.exists) return;

      final data = path.data()!;
      final lessons = List<Map<String, dynamic>>.from(data['lessons'] ?? []);

      // Find and update the lesson
      for (var i = 0; i < lessons.length; i++) {
        if (lessons[i]['id'] == lessonId) {
          lessons[i]['isCompleted'] = true;
          break;
        }
      }

      // Update completed lessons count
      final completedCount = lessons
          .where((l) => l['isCompleted'] == true)
          .length;

      await pathRef.update({
        'lessons': lessons,
        'completedLessons': completedCount,
      });
    } catch (e) {
      print('Error completing lesson: $e');
      throw Exception('Failed to complete lesson');
    }
  }

  // Helper method to parse lessons from Firestore data
  List<LearningLesson> _parseLessons(List<dynamic> lessonsData) {
    return lessonsData.map((lesson) {
      return LearningLesson(
        id: lesson['id'] ?? '',
        title: lesson['title'] ?? '',
        content: lesson['content'] ?? '',
        videoUrl: lesson['videoUrl'],
        resources: lesson['resources'] != null
            ? List<String>.from(lesson['resources'])
            : null,
        isCompleted: lesson['isCompleted'] ?? false,
        duration: lesson['duration'] ?? 0,
      );
    }).toList();
  }

  // Get default learning paths (used when Firestore is empty)
  List<LearningPath> getDefaultLearningPaths() {
    return [
      LearningPath(
        id: 'hypertension_basics',
        title: 'Hypertension Basics',
        description: 'Learn the fundamentals of managing hypertension',
        icon: '📚',
        totalLessons: 5,
        completedLessons: 0,
        color: '#4CAF50',
        lessons: [
          LearningLesson(
            id: 'lesson1',
            title: 'Understanding Blood Pressure',
            content:
                '''Blood pressure is the force of blood pushing against the walls of your arteries. It's measured in millimeters of mercury (mmHg) and consists of two numbers:

• Systolic pressure (top number): The pressure when your heart beats
• Diastolic pressure (bottom number): The pressure when your heart rests between beats

Normal blood pressure is below 120/80 mmHg. Hypertension is diagnosed when readings are consistently above 130/80 mmHg.''',
            duration: 10,
          ),
          LearningLesson(
            id: 'lesson2',
            title: 'Types of Hypertension',
            content: '''There are two main types of hypertension:

1. Primary (Essential) Hypertension
• Most common type
• Develops gradually over time
• No identifiable cause
• Often related to lifestyle factors

2. Secondary Hypertension
• Caused by an underlying condition
• Appears suddenly
• Usually higher blood pressure
• Can be caused by:
  - Kidney problems
  - Thyroid disorders
  - Sleep apnea
  - Certain medications''',
            duration: 8,
          ),
          LearningLesson(
            id: 'lesson3',
            title: 'Risk Factors',
            content: '''Common risk factors for hypertension include:

• Age (risk increases with age)
• Family history
• Being overweight or obese
• Physical inactivity
• High sodium diet
• Low potassium diet
• Excessive alcohol consumption
• Stress
• Smoking
• Chronic conditions (diabetes, kidney disease)''',
            duration: 7,
          ),
          LearningLesson(
            id: 'lesson4',
            title: 'Symptoms and Complications',
            content:
                '''Hypertension is often called the "silent killer" because it may not show symptoms. However, some people may experience:

• Headaches
• Shortness of breath
• Nosebleeds
• Dizziness
• Chest pain

Untreated hypertension can lead to serious complications:
• Heart attack
• Stroke
• Heart failure
• Kidney damage
• Vision problems
• Memory issues''',
            duration: 9,
          ),
          LearningLesson(
            id: 'lesson5',
            title: 'Diagnosis and Monitoring',
            content:
                '''Regular blood pressure monitoring is crucial for diagnosis and management:

• Home monitoring
• 24-hour ambulatory monitoring
• Regular doctor visits
• Keeping a blood pressure log
• Understanding your readings
• When to seek medical attention''',
            duration: 8,
          ),
        ],
      ),
      LearningPath(
        id: 'medication_management',
        title: 'Medication Management',
        description:
            'Learn about hypertension medications and how to manage them effectively',
        icon: '💊',
        totalLessons: 5,
        completedLessons: 0,
        color: '#2196F3',
        lessons: [
          LearningLesson(
            id: 'lesson1',
            title: 'Common Blood Pressure Medications',
            content: '''Major classes of blood pressure medications:

1. Diuretics
• Help kidneys remove sodium and water
• Reduce blood volume
• Examples: Hydrochlorothiazide, Furosemide

2. ACE Inhibitors
• Relax blood vessels
• Block formation of angiotensin II
• Examples: Lisinopril, Enalapril

3. ARBs (Angiotensin II Receptor Blockers)
• Block effects of angiotensin II
• Relax blood vessels
• Examples: Losartan, Valsartan

4. Calcium Channel Blockers
• Prevent calcium from entering heart and artery cells
• Relax blood vessels
• Examples: Amlodipine, Diltiazem

5. Beta Blockers
• Reduce heart rate and output
• Block effects of adrenaline
• Examples: Metoprolol, Atenolol''',
            duration: 12,
          ),
          LearningLesson(
            id: 'lesson2',
            title: 'Taking Medications Correctly',
            content: '''Best practices for medication management:

• Take medications at the same time daily
• Follow dosage instructions carefully
• Don't skip doses
• Keep a medication schedule
• Use pill organizers if needed
• Set reminders
• Keep a medication log
• Store medications properly''',
            duration: 8,
          ),
          LearningLesson(
            id: 'lesson3',
            title: 'Side Effects and Interactions',
            content: '''Common side effects of blood pressure medications:

• Dizziness
• Fatigue
• Headaches
• Dry cough (ACE inhibitors)
• Swelling (Calcium channel blockers)
• Frequent urination (Diuretics)

Important interactions to be aware of:
• Over-the-counter medications
• Herbal supplements
• Food interactions
• Alcohol
• Other prescription medications''',
            duration: 10,
          ),
          LearningLesson(
            id: 'lesson4',
            title: 'Medication Adherence',
            content: '''Tips for maintaining medication adherence:

• Understand why each medication is important
• Create a routine
• Use technology (apps, reminders)
• Keep medications visible
• Plan for refills
• Travel with extra doses
• Communicate with healthcare providers
• Join support groups''',
            duration: 7,
          ),
          LearningLesson(
            id: 'lesson5',
            title: 'When to Call Your Doctor',
            content: '''Contact your healthcare provider if you experience:

• Severe side effects
• Allergic reactions
• Missed doses
• Changes in blood pressure
• New symptoms
• Questions about medications
• Need for refills
• Changes in other medications''',
            duration: 6,
          ),
        ],
      ),
    ];
  }
}
