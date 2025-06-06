import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../services/measurement_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeasureResultView extends StatefulWidget {
  final int estimatedBPM;
  final VoidCallback onSave;

  const MeasureResultView({Key? key, required this.estimatedBPM, required this.onSave}) : super(key: key);

  @override
  State<MeasureResultView> createState() => _MeasureResultViewState();
}

class _MeasureResultViewState extends State<MeasureResultView> {
  String _selectedContext = "At rest";
  final MeasurementService _measurementService = MeasurementService();
  bool _isSaving = false;
  // Initialize with default values
  Map<String, int> _calculatedBP = {'systolic': 0, 'diastolic': 0};

  @override
  void initState() {
    super.initState();
    // Calculate blood pressure once when the view is initialized
    _calculatedBP = _estimateBloodPressure(widget.estimatedBPM);
  }

  // Blood pressure estimation based on heart rate and context
  // This is an improved model but still should not be used for medical purposes
  Map<String, int> _estimateBloodPressure(int heartRate) {
    // Base values adjusted for age and gender (assuming average adult)
    const int baseSystolic = 115;
    const int baseDiastolic = 75;
    
    // Get the context factor
    double contextFactor = 1.0;
    switch (_selectedContext) {
      case "After exercise":
        contextFactor = 1.15; // Higher BP expected after exercise
        break;
      case "At rest":
        contextFactor = 1.0; // Normal baseline
        break;
      case "After medication":
        contextFactor = 0.95; // Slightly lower BP expected after medication
        break;
      case "Before sleep":
        contextFactor = 0.9; // Lower BP expected before sleep
        break;
    }

    // Calculate heart rate factor using a sigmoid-like function for smoother transitions
    double heartRateFactor = 1.0;
    if (heartRate > 80) {
      // For elevated heart rates, use a logarithmic scale
      heartRateFactor = 1.0 + (0.015 * (heartRate - 80));
    } else if (heartRate < 60) {
      // For lower heart rates, use a different scale
      heartRateFactor = 1.0 - (0.01 * (60 - heartRate));
    }

    // Calculate final values with all factors
    int systolic = (baseSystolic * contextFactor * heartRateFactor).round();
    int diastolic = (baseDiastolic * contextFactor * heartRateFactor).round();

    // Ensure values stay within reasonable ranges
    systolic = systolic.clamp(90, 160);
    diastolic = diastolic.clamp(60, 100);

    // Add small random variation (±2) to make readings more realistic
    // This simulates the natural variation in BP measurements
    systolic += (DateTime.now().millisecondsSinceEpoch % 5) - 2;
    diastolic += ((DateTime.now().millisecondsSinceEpoch + 1000) % 5) - 2;

    // Final range check
    systolic = systolic.clamp(90, 160);
    diastolic = diastolic.clamp(60, 100);

    return {
      'systolic': systolic,
      'diastolic': diastolic,
    };
  }

  // Get interpretation based on blood pressure and heart rate
  String _getInterpretation(int systolic, int diastolic, int heartRate) {
    if (systolic >= 180 || diastolic >= 120) {
      return "High blood pressure crisis. Please consult a healthcare provider immediately.";
    } else if (systolic >= 140 || diastolic >= 90) {
      return "High blood pressure (Stage 2). Consider consulting a healthcare provider.";
    } else if (systolic >= 130 || diastolic >= 80) {
      return "High blood pressure (Stage 1). Consider lifestyle changes and monitoring.";
    } else if (systolic >= 120 || diastolic >= 80) {
      return "Elevated blood pressure. Consider lifestyle changes.";
    } else if (systolic < 90 || diastolic < 60) {
      return "Low blood pressure. Consider consulting a healthcare provider if symptoms persist.";
    } else {
      return "Normal blood pressure range. Continue maintaining a healthy lifestyle.";
    }
  }

  Future<void> _saveMeasurement() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      await _measurementService.addMeasurement(
        userId: user.uid,
        heartRate: widget.estimatedBPM,
        systolicBP: _calculatedBP['systolic']!,
        diastolicBP: _calculatedBP['diastolic']!,
        context: _selectedContext,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Measurement saved successfully',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: TColor.primaryColor1,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save measurement: $e',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    // Use the stored calculated values instead of recalculating
    final interpretation = _getInterpretation(
      _calculatedBP['systolic']!,
      _calculatedBP['diastolic']!,
      widget.estimatedBPM
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: TColor.bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              // Display Estimated BPM in results
              Center(
                child: Column(
                  children: [
                    Text(
                      "Estimated Heart Rate",
                       style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                     Text(
                      "${widget.estimatedBPM}", // Display the calculated BPM
                      style: TextStyle(
                        color: TColor.primaryColor1,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                     Text(
                      "bpm",
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Blood Pressure Display
              Text(
                "Estimated Blood Pressure",
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${_calculatedBP['systolic']}",
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    " / ",
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "${_calculatedBP['diastolic']}",
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "mmHg",
                    style: TextStyle(
                      color: TColor.subTextColor,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Feedback/Interpretation
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: TColor.primaryColor1.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: TColor.primaryColor1,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        interpretation,
                        style: TextStyle(
                          color: TColor.primaryColor1,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Context Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: isDarkMode ? TColor.darkSurface : TColor.white,
                  border: Border.all(
                    color: TColor.subTextColor.withAlpha(77),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedContext,
                    items: const [
                      "After exercise",
                      "At rest",
                      "After medication",
                      "Before sleep",
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: TColor.textColor,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedContext = value;
                        });
                      }
                    },
                    style: TextStyle(
                      color: TColor.textColor,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: TColor.textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  foregroundColor: TColor.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Save Measurement",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 20), // Add some space at the bottom
            ],
          ),
        ),
      ),
    );
  }
} 