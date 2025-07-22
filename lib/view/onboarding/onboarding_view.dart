import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/colo_extension.dart';
import '../main_tab/main_tab_view.dart';
import '../../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  // Health Background
  String? _hypertensionStatus; // Yes, No, Not sure
  DateTime? _diagnosisDate;
  final _medicationsController = TextEditingController();
  bool? _hasFamilyHistory;
  final List<String> _selectedConditions = [];
  String? _smokingHabits;
  String? _drinkingHabits;
  String? _activityLevel;

  // Measurement Context
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  bool? _hasBPCuff;
  String? _preferredHand;
  bool _cameraPermission = false;
  bool _flashlightPermission = false;

  final List<String> _conditions = [
    'Diabetes',
    'Chronic Kidney Disease',
    'Heart Disease',
    'High Cholesterol',
    'Sleep Apnea',
    'Other'
  ];

  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active'
  ];

  final List<String> _habits = [
    'Never',
    'Occasionally',
    'Regularly',
    'Heavily'
  ];

  @override
  void initState() {
    super.initState();
    // Set default values for dropdowns
    _smokingHabits = _habits[0];
    _drinkingHabits = _habits[0];
    _activityLevel = _activityLevels[0];
    _preferredHand = 'Right';
  }

  @override
  void dispose() {
    _medicationsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primaryColor1,
              onPrimary: TColor.white,
              surface: TColor.bgColor,
              onSurface: TColor.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _diagnosisDate) {
      setState(() {
        _diagnosisDate = picked;
      });
    }
  }

  Future<void> _saveQuestionnaireAnswers() async {
    // Parse weight and height values
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    // Validate weight and height
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid weight value',
            style: TextStyle(color: TColor.white),
          ),
          backgroundColor: TColor.primaryColor2,
        ),
      );
      return;
    }

    if (height == null || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid height value',
            style: TextStyle(color: TColor.white),
          ),
          backgroundColor: TColor.primaryColor2,
        ),
      );
      return;
    }

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be logged in to save your information',
            style: TextStyle(color: TColor.white),
          ),
          backgroundColor: TColor.primaryColor2,
        ),
      );
      return;
    }

    try {
      // Get existing user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? existingData;
      if (userDoc.exists) {
        existingData = userDoc.data();
      }

      // Create the user model with the parsed values
      final userModel = UserModel(
        id: user.uid,
        basicInfo: BasicInfo(
          fullName: existingData?['basicInfo']?['fullName'] ?? '',
          dateOfBirth: existingData?['basicInfo']?['dateOfBirth'] != null 
              ? (existingData!['basicInfo']!['dateOfBirth'] as Timestamp).toDate()
              : DateTime.now(),
          gender: existingData?['basicInfo']?['gender'] ?? '',
          email: existingData?['basicInfo']?['email'] ?? '',
          phoneNumber: existingData?['basicInfo']?['phoneNumber'],
          age: existingData?['basicInfo']?['age'] ?? 0,
          weight: weight,
          height: height,
        ),
        healthBackground: HealthBackground(
          hasHypertension: _hypertensionStatus == 'Yes',
          diagnosisDate: _diagnosisDate,
          medications: _medicationsController.text.split(',').map((e) => e.trim()).toList(),
          familyHistory: _hasFamilyHistory ?? false,
          conditions: _selectedConditions,
          smokingHabits: _smokingHabits ?? _habits[0],
          drinkingHabits: _drinkingHabits ?? _habits[0],
          activityLevel: _activityLevel ?? _activityLevels[0],
        ),
        measurementContext: MeasurementContext(
          weight: weight,
          height: height,
          hasBPCuff: _hasBPCuff,
          preferredHand: _preferredHand ?? 'Right',
          cameraPermission: _cameraPermission,
          flashlightPermission: _flashlightPermission,
        ),
        isAdmin: existingData?['isAdmin'] ?? false,
        dataSharingEnabled: existingData?['dataSharingEnabled'] ?? false,
        hasCompletedOnboarding: true,
      );

      // Save to Firestore (now includes hasCompletedOnboarding)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      // Set onboarding completion flag in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedOnboarding', true);
      // (Removed extra merge write for hasCompletedOnboarding)

      // Navigate to main tab view
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainTabView(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save your information: $e',
              style: TextStyle(color: TColor.white),
            ),
            backgroundColor: TColor.primaryColor2,
          ),
        );
      }
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermission = status.isGranted;
    });

    if (status.isGranted) {
      // If camera permission is granted, also request flashlight permission
      final flashlightStatus = await Permission.camera.request();
      setState(() {
        _flashlightPermission = flashlightStatus.isGranted;
      });
    } else {
      // Show a message if permission is denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera permission is required for measurements',
              style: TextStyle(color: TColor.white),
            ),
            backgroundColor: TColor.primaryColor2,
          ),
        );
      }
    }
  }

  Future<void> _requestFlashlightPermission() async {
    // Flashlight permission is tied to camera permission
    final status = await Permission.camera.request();
    setState(() {
      _flashlightPermission = status.isGranted;
      _cameraPermission = status.isGranted; // Update camera permission too
    });

    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera permission is required for flashlight access',
            style: TextStyle(color: TColor.white),
          ),
          backgroundColor: TColor.primaryColor2,
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: TColor.textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuestionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
                  title,
                  style: TextStyle(
          color: TColor.textColor,
                    fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);
    
    return Scaffold(
      backgroundColor: TColor.bgColor,
      appBar: AppBar(
        backgroundColor: TColor.bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Health Questionnaire',
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                'Please answer these questions to help us provide better care.',
            style: TextStyle(
                  color: TColor.subTextColor,
              fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Health Background Section
              _buildSectionTitle('Health Background'),

              // Hypertension Status
              _buildQuestionTitle('Do you have hypertension?'),
              Column(
                children: [
                  RadioListTile<String>(
                      title: Text('Yes', style: TextStyle(color: TColor.textColor)),
                      value: 'Yes',
                      groupValue: _hypertensionStatus,
                      onChanged: (value) {
                        setState(() {
                          _hypertensionStatus = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
                    ),
                  RadioListTile<String>(
                      title: Text('No', style: TextStyle(color: TColor.textColor)),
                      value: 'No',
                      groupValue: _hypertensionStatus,
                      onChanged: (value) {
                        setState(() {
                          _hypertensionStatus = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
                    ),
                  RadioListTile<String>(
                      title: Text('Not sure', style: TextStyle(color: TColor.textColor)),
                      value: 'Not sure',
                      groupValue: _hypertensionStatus,
                      onChanged: (value) {
                        setState(() {
                          _hypertensionStatus = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
          ),
        ],
      ),

              // Diagnosis Date (if Yes)
              if (_hypertensionStatus == 'Yes') ...[
                _buildQuestionTitle('When were you diagnosed?'),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
                        color: TColor.subTextColor.withAlpha(77),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
                          _diagnosisDate == null
                              ? "Select date"
                              : "${_diagnosisDate!.day}/${_diagnosisDate!.month}/${_diagnosisDate!.year}",
            style: TextStyle(
                            color: _diagnosisDate == null
                                ? TColor.subTextColor.withAlpha(128)
                                : TColor.textColor,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: TColor.subTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Medications
              _buildQuestionTitle('Are you on any medications? (Optional)'),
              TextFormField(
                controller: _medicationsController,
                style: TextStyle(color: TColor.textColor),
            decoration: InputDecoration(
                  hintText: "List your medications",
                  hintStyle: TextStyle(color: TColor.subTextColor.withAlpha(128)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                      color: TColor.subTextColor.withAlpha(77),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                      color: TColor.subTextColor.withAlpha(77),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                      color: TColor.primaryColor1,
                  width: 2,
                    ),
                  ),
                ),
              ),

              // Family History
              _buildQuestionTitle('Do you have a family history of hypertension?'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Yes', style: TextStyle(color: TColor.textColor)),
                      value: true,
                      groupValue: _hasFamilyHistory,
                      onChanged: (value) {
                        setState(() {
                          _hasFamilyHistory = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('No', style: TextStyle(color: TColor.textColor)),
                      value: false,
                      groupValue: _hasFamilyHistory,
                      onChanged: (value) {
                        setState(() {
                          _hasFamilyHistory = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
            ),
          ),
        ],
      ),

              // Other Conditions
              _buildQuestionTitle('Do you have any of these conditions?'),
              ..._conditions.map((condition) => CheckboxListTile(
                    title: Text(condition, style: TextStyle(color: TColor.textColor)),
                    value: _selectedConditions.contains(condition),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedConditions.add(condition);
                        } else {
                          _selectedConditions.remove(condition);
                        }
                      });
                    },
                    activeColor: TColor.primaryColor1,
                    checkColor: TColor.white,
                  )),

              // Lifestyle Section
              _buildSectionTitle('Lifestyle'),

              // Smoking Habits
              _buildQuestionTitle('What are your smoking habits?'),
              DropdownButtonFormField<String>(
                value: _smokingHabits ?? _habits[0],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: _habits.map((String habit) {
                  return DropdownMenuItem<String>(
                    value: habit,
                    child: Text(habit, style: TextStyle(color: TColor.textColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _smokingHabits = value;
                    });
                  }
                },
                dropdownColor: TColor.bgColor,
                style: TextStyle(color: TColor.textColor),
              ),

              // Drinking Habits
              _buildQuestionTitle('What are your drinking habits?'),
              DropdownButtonFormField<String>(
                value: _drinkingHabits ?? _habits[0],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: _habits.map((String habit) {
                  return DropdownMenuItem<String>(
                    value: habit,
                    child: Text(habit, style: TextStyle(color: TColor.textColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _drinkingHabits = value;
                    });
                  }
                },
                dropdownColor: TColor.bgColor,
                style: TextStyle(color: TColor.textColor),
              ),

              // Activity Level
              _buildQuestionTitle('What is your activity level?'),
              DropdownButtonFormField<String>(
                value: _activityLevel ?? _activityLevels[0],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: _activityLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level, style: TextStyle(color: TColor.textColor)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _activityLevel = value;
                    });
                  }
                },
                dropdownColor: TColor.bgColor,
                style: TextStyle(color: TColor.textColor),
              ),

              // Measurement Context Section
              _buildSectionTitle('Measurement Context'),

              // Weight
              _buildQuestionTitle('What is your weight? (kg)'),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: TColor.textColor),
                decoration: InputDecoration(
                  hintText: "Enter your weight",
                  hintStyle: TextStyle(color: TColor.subTextColor.withAlpha(128)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TColor.subTextColor.withAlpha(77),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TColor.subTextColor.withAlpha(77),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TColor.primaryColor1,
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Height
              _buildQuestionTitle('What is your height? (cm)'),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: TColor.textColor),
                decoration: InputDecoration(
                  hintText: "Enter your height",
                  hintStyle: TextStyle(color: TColor.subTextColor.withAlpha(128)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TColor.subTextColor.withAlpha(77),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TColor.subTextColor.withAlpha(77),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: TColor.primaryColor1,
                      width: 2,
                    ),
                  ),
                ),
              ),

              // BP Cuff
              _buildQuestionTitle('Do you have access to a BP cuff?'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Yes', style: TextStyle(color: TColor.textColor)),
                      value: true,
                      groupValue: _hasBPCuff,
                      onChanged: (value) {
                        setState(() {
                          _hasBPCuff = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('No', style: TextStyle(color: TColor.textColor)),
                      value: false,
                      groupValue: _hasBPCuff,
                      onChanged: (value) {
                              setState(() {
                          _hasBPCuff = value;
                              });
                            },
                      activeColor: TColor.primaryColor1,
                    ),
                  ),
                ],
              ),

              // Preferred Hand
              _buildQuestionTitle('Which hand do you prefer for BP readings?'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Left', style: TextStyle(color: TColor.textColor)),
                      value: 'Left',
                      groupValue: _preferredHand,
                            onChanged: (value) {
                        setState(() {
                          _preferredHand = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Right', style: TextStyle(color: TColor.textColor)),
                      value: 'Right',
                      groupValue: _preferredHand,
                            onChanged: (value) {
                        setState(() {
                          _preferredHand = value;
                        });
                      },
                      activeColor: TColor.primaryColor1,
                    ),
                  ),
                ],
              ),

              // Permissions
              _buildQuestionTitle('Required Permissions'),
              CheckboxListTile(
                title: Text('Camera Permission', style: TextStyle(color: TColor.textColor)),
                subtitle: Text(
                  'Required for PPG measurements',
                  style: TextStyle(color: TColor.subTextColor),
                ),
                value: _cameraPermission,
                onChanged: (value) async {
                  if (value == true) {
                    await _requestCameraPermission();
                  } else {
                    setState(() {
                      _cameraPermission = false;
                      _flashlightPermission = false; // Disable flashlight if camera is disabled
                    });
                  }
                },
                activeColor: TColor.primaryColor1,
                checkColor: TColor.white,
              ),
              CheckboxListTile(
                title: Text('Flashlight Permission', style: TextStyle(color: TColor.textColor)),
                subtitle: Text(
                  'Required for PPG measurements',
                  style: TextStyle(color: TColor.subTextColor),
                ),
                value: _flashlightPermission,
                onChanged: (value) async {
                  if (value == true) {
                    await _requestFlashlightPermission();
                  } else {
                    setState(() {
                      _flashlightPermission = false;
                    });
                  }
                },
                activeColor: TColor.primaryColor1,
                checkColor: TColor.white,
                          ),

                          const SizedBox(height: 32),

              // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                  onPressed: () {
                    if (_hypertensionStatus == null || _activityLevel == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please fill in all required fields',
                            style: TextStyle(color: TColor.white),
                          ),
                          backgroundColor: TColor.primaryColor2,
                        ),
                      );
                      return;
                    }
                    _saveQuestionnaireAnswers();
                  },
                              style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    foregroundColor: TColor.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete Questionnaire',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
          ),
        ),
      ),
    );
  }
}