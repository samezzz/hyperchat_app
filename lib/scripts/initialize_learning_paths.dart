import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_config.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: FirebaseConfig.apiKey,
      authDomain: FirebaseConfig.authDomain,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.messagingSenderId,
      appId: FirebaseConfig.appId,
    ),
  );

  final firestore = FirebaseFirestore.instance;
  final learningPathsRef = firestore.collection('learning_paths');

  // Define learning paths data
  final learningPaths = [
    {
      'title': 'Hypertension Basics',
      'description': 'Learn the fundamentals of managing hypertension',
      'icon': '📚',
      'totalLessons': 5,
      'completedLessons': 0,
      'color': '#4CAF50',
      'lessons': [
        {
          'id': 'lesson1',
          'title': 'Understanding Blood Pressure',
          'content': '''Blood pressure is the force of blood pushing against the walls of your arteries. It's measured in millimeters of mercury (mmHg) and consists of two numbers:
          
• Systolic pressure (top number): The pressure when your heart beats
• Diastolic pressure (bottom number): The pressure when your heart rests between beats

Normal blood pressure is below 120/80 mmHg. Hypertension is diagnosed when readings are consistently above 130/80 mmHg.''',
          'duration': 10,
          'isCompleted': false
        },
        {
          'id': 'lesson2',
          'title': 'Types of Hypertension',
          'content': '''There are two main types of hypertension:

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
          'duration': 8,
          'isCompleted': false
        },
        {
          'id': 'lesson3',
          'title': 'Risk Factors',
          'content': '''Common risk factors for hypertension include:

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
          'duration': 7,
          'isCompleted': false
        },
        {
          'id': 'lesson4',
          'title': 'Symptoms and Complications',
          'content': '''Hypertension is often called the "silent killer" because it may not show symptoms. However, some people may experience:

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
          'duration': 9,
          'isCompleted': false
        },
        {
          'id': 'lesson5',
          'title': 'Diagnosis and Monitoring',
          'content': '''Regular blood pressure monitoring is crucial for diagnosis and management:

• Home monitoring
• 24-hour ambulatory monitoring
• Regular doctor visits
• Keeping a blood pressure log
• Understanding your readings
• When to seek medical attention''',
          'duration': 8,
          'isCompleted': false
        }
      ]
    },
    {
      'title': 'Medication Management',
      'description': 'Learn about hypertension medications and how to manage them effectively',
      'icon': '💊',
      'totalLessons': 5,
      'completedLessons': 0,
      'color': '#2196F3',
      'lessons': [
        {
          'id': 'lesson1',
          'title': 'Common Blood Pressure Medications',
          'content': '''Major classes of blood pressure medications:

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
          'duration': 12,
          'isCompleted': false
        },
        {
          'id': 'lesson2',
          'title': 'Taking Medications Correctly',
          'content': '''Best practices for medication management:

• Take medications at the same time daily
• Follow dosage instructions carefully
• Don't skip doses
• Keep a medication schedule
• Use pill organizers if needed
• Set reminders
• Keep a medication log
• Store medications properly''',
          'duration': 8,
          'isCompleted': false
        },
        {
          'id': 'lesson3',
          'title': 'Side Effects and Interactions',
          'content': '''Common side effects of blood pressure medications:

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
          'duration': 10,
          'isCompleted': false
        },
        {
          'id': 'lesson4',
          'title': 'Medication Adherence',
          'content': '''Tips for maintaining medication adherence:

• Understand why each medication is important
• Create a routine
• Use technology (apps, reminders)
• Keep medications visible
• Plan for refills
• Travel with extra doses
• Communicate with healthcare providers
• Join support groups''',
          'duration': 7,
          'isCompleted': false
        },
        {
          'id': 'lesson5',
          'title': 'When to Call Your Doctor',
          'content': '''Contact your healthcare provider if you experience:

• Severe side effects
• Allergic reactions
• Missed doses
• Changes in blood pressure
• New symptoms
• Questions about medications
• Need for refills
• Changes in other medications''',
          'duration': 6,
          'isCompleted': false
        }
      ]
    },
    {
      'title': 'Healthy Eating for BP',
      'description': 'Discover how to maintain a heart-healthy diet to manage blood pressure',
      'icon': '🥗',
      'totalLessons': 5,
      'completedLessons': 0,
      'color': '#FF9800',
      'lessons': [
        {
          'id': 'lesson1',
          'title': 'DASH Diet Basics',
          'content': '''The DASH (Dietary Approaches to Stop Hypertension) diet:

• Rich in fruits and vegetables
• Low-fat dairy products
• Whole grains
• Lean proteins
• Limited sodium
• Limited sweets and red meat
• Nuts, seeds, and legumes
• Healthy fats''',
          'duration': 10,
          'isCompleted': false
        },
        {
          'id': 'lesson2',
          'title': 'Sodium Management',
          'content': '''Tips for reducing sodium intake:

• Read food labels
• Choose low-sodium options
• Cook at home
• Use herbs and spices
• Limit processed foods
• Rinse canned foods
• Avoid adding salt
• Be aware of hidden sodium''',
          'duration': 8,
          'isCompleted': false
        },
        {
          'id': 'lesson3',
          'title': 'Heart-Healthy Foods',
          'content': '''Foods that help lower blood pressure:

• Leafy greens
• Berries
• Bananas
• Oatmeal
• Fatty fish
• Dark chocolate
• Pistachios
• Olive oil
• Garlic
• Yogurt''',
          'duration': 7,
          'isCompleted': false
        },
        {
          'id': 'lesson4',
          'title': 'Meal Planning',
          'content': '''Effective meal planning strategies:

• Plan weekly menus
• Prepare meals in advance
• Keep healthy snacks handy
• Portion control
• Balanced meals
• Regular meal times
• Hydration
• Mindful eating''',
          'duration': 9,
          'isCompleted': false
        },
        {
          'id': 'lesson5',
          'title': 'Eating Out',
          'content': '''Tips for maintaining healthy eating while dining out:

• Check menus online
• Ask about preparation methods
• Request modifications
• Watch portion sizes
• Choose healthier options
• Limit alcohol
• Skip the salt shaker
• Share desserts''',
          'duration': 6,
          'isCompleted': false
        }
      ]
    },
    {
      'title': 'Exercise and BP',
      'description': 'Learn how physical activity can help manage your blood pressure',
      'icon': '🏃',
      'totalLessons': 5,
      'completedLessons': 0,
      'color': '#9C27B0',
      'lessons': [
        {
          'id': 'lesson1',
          'title': 'Benefits of Exercise',
          'content': '''How exercise helps manage blood pressure:

• Strengthens heart
• Improves circulation
• Reduces stress
• Helps maintain weight
• Improves sleep
• Boosts energy
• Reduces inflammation
• Improves overall health''',
          'duration': 8,
          'isCompleted': false
        },
        {
          'id': 'lesson2',
          'title': 'Safe Exercises',
          'content': '''Recommended exercises for hypertension:

• Walking
• Swimming
• Cycling
• Yoga
• Tai Chi
• Light strength training
• Dancing
• Gardening
• Household chores
• Stretching''',
          'duration': 9,
          'isCompleted': false
        },
        {
          'id': 'lesson3',
          'title': 'Exercise Guidelines',
          'content': '''General exercise recommendations:

• 150 minutes per week
• Moderate intensity
• Start slowly
• Warm up and cool down
• Stay hydrated
• Monitor intensity
• Listen to your body
• Regular schedule''',
          'duration': 7,
          'isCompleted': false
        },
        {
          'id': 'lesson4',
          'title': 'Precautions',
          'content': '''Important safety considerations:

• Consult your doctor
• Monitor blood pressure
• Avoid high-intensity exercise
• Watch for warning signs
• Stay hydrated
• Proper form
• Appropriate clothing
• Weather considerations''',
          'duration': 8,
          'isCompleted': false
        },
        {
          'id': 'lesson5',
          'title': 'Staying Motivated',
          'content': '''Tips for maintaining exercise routine:

• Set realistic goals
• Find enjoyable activities
• Exercise with others
• Track progress
• Reward yourself
• Mix up activities
• Schedule exercise
• Remember benefits''',
          'duration': 6,
          'isCompleted': false
        }
      ]
    },
    {
      'title': 'Stress Management',
      'description': 'Learn effective techniques to manage stress and lower blood pressure',
      'icon': '🧘',
      'totalLessons': 5,
      'completedLessons': 0,
      'color': '#E91E63',
      'lessons': [
        {
          'id': 'lesson1',
          'title': 'Understanding Stress',
          'content': '''How stress affects blood pressure:

• Fight or flight response
• Hormone release
• Increased heart rate
• Blood vessel constriction
• Long-term effects
• Chronic stress
• Stress triggers
• Warning signs''',
          'duration': 9,
          'isCompleted': false
        },
        {
          'id': 'lesson2',
          'title': 'Relaxation Techniques',
          'content': '''Effective relaxation methods:

• Deep breathing
• Progressive muscle relaxation
• Meditation
• Guided imagery
• Yoga
• Tai Chi
• Massage
• Music therapy
• Aromatherapy
• Nature walks''',
          'duration': 10,
          'isCompleted': false
        },
        {
          'id': 'lesson3',
          'title': 'Mindfulness',
          'content': '''Practicing mindfulness:

• Present moment awareness
• Non-judgmental observation
• Mindful breathing
• Body scan
• Mindful eating
• Mindful walking
• Daily mindfulness
• Benefits for BP''',
          'duration': 8,
          'isCompleted': false
        },
        {
          'id': 'lesson4',
          'title': 'Lifestyle Changes',
          'content': '''Stress-reducing lifestyle modifications:

• Regular sleep schedule
• Healthy diet
• Regular exercise
• Social connections
• Time management
• Setting boundaries
• Hobbies and interests
• Work-life balance''',
          'duration': 7,
          'isCompleted': false
        },
        {
          'id': 'lesson5',
          'title': 'Seeking Support',
          'content': '''When and how to get help:

• Professional counseling
• Support groups
• Family support
• Friends and community
• Online resources
• Crisis hotlines
• Healthcare providers
• Self-help strategies''',
          'duration': 6,
          'isCompleted': false
        }
      ]
    }
  ];

  // Add learning paths to Firestore
  for (var path in learningPaths) {
    try {
      await learningPathsRef.add(path);
      print('Added learning path: ${path['title']}');
    } catch (e) {
      print('Error adding learning path ${path['title']}: $e');
    }
  }

  print('Learning paths initialization completed!');
} 