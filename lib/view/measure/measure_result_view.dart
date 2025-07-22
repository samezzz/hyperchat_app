import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../services/measurement_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class MeasureResultView extends StatefulWidget {
  final int estimatedBPM;
  final String initialContext;
  final VoidCallback onSave;

  const MeasureResultView({
    Key? key,
    required this.estimatedBPM,
    required this.initialContext,
    required this.onSave,
  }) : super(key: key);

  @override
  State<MeasureResultView> createState() => _MeasureResultViewState();
}

class _MeasureResultViewState extends State<MeasureResultView> {
  final MeasurementService _measurementService = MeasurementService();
  bool _isSaving = false;
  // Initialize with default values
  Map<String, int> _calculatedBP = {'systolic': 0, 'diastolic': 0};
  Map<String, dynamic>? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    // Calculate blood pressure once when the view is initialized
    _calculatedBP = _estimateBloodPressure(widget.estimatedBPM);
  }

  // Blood pressure estimation based on heart rate and context
  Map<String, int> _estimateBloodPressure(int heartRate) {
    // Base values adjusted for age and gender (assuming average adult)
    const int baseSystolic = 115;
    const int baseDiastolic = 75;

    // Get the context factor
    double contextFactor = 1.0;
    switch (widget.initialContext) {
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

    return {'systolic': systolic, 'diastolic': diastolic};
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

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) {
        throw Exception('User data not loaded');
      }

      // Start timing the minimum loading duration
      final startTime = DateTime.now();

      // Ensure we have AI analysis before saving
      _aiAnalysis ??= await _measurementService.geminiService
          .analyzeMeasurement(
            systolicBP: _calculatedBP['systolic']!,
            diastolicBP: _calculatedBP['diastolic']!,
            heartRate: widget.estimatedBPM,
            context: widget.initialContext,
            healthBackground: userProvider.user!.healthBackground,
          );

      // Save the measurement with the AI analysis
      await _measurementService.addMeasurement(
        userId: user.uid,
        heartRate: widget.estimatedBPM,
        systolicBP: _calculatedBP['systolic']!,
        diastolicBP: _calculatedBP['diastolic']!,
        context: widget.initialContext,
        healthBackground: userProvider.user!.healthBackground,
        aiAnalysis: _aiAnalysis,
      );

      // Calculate elapsed time and add delay if needed to ensure minimum loading duration
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < const Duration(seconds: 2)) {
        await Future.delayed(const Duration(seconds: 2) - elapsedTime);
      }

      if (mounted) {
        // First call onSave callback
        widget.onSave();

        // Then show success message
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
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Finally, pop back to home view
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
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
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  // Display the actual measured BPM from the measure view
  int get displayBPM {
    return widget.estimatedBPM;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    // Use the stored calculated values instead of recalculating
    final interpretation = _getInterpretation(
      _calculatedBP['systolic']!,
      _calculatedBP['diastolic']!,
      widget.estimatedBPM,
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
                      displayBPM.toString(),
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
                    _calculatedBP['systolic'].toString(),
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
                    _calculatedBP['diastolic'].toString(),
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "mmHg",
                    style: TextStyle(color: TColor.subTextColor, fontSize: 18),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Feedback/Interpretation
              // Container(
              //   padding: const EdgeInsets.all(15),
              //   decoration: BoxDecoration(
              //     color: TColor.primaryColor1.withAlpha(26),
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         Icons.info_outline,
              //         color: TColor.primaryColor1,
              //       ),
              //       const SizedBox(width: 10),
              //       Expanded(
              //         child: Text(
              //           interpretation,
              //           style: TextStyle(
              //             color: TColor.primaryColor1,
              //             fontSize: 16,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Add disclaimer below BP values
              const SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disclaimer: The blood pressure values shown are estimates and are not intended for medical diagnosis or treatment. For accurate blood pressure readings, use a clinically validated BP cuff.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI Analysis Section
              FutureBuilder<Map<String, dynamic>>(
                future: _aiAnalysis != null
                    ? Future.value(_aiAnalysis)
                    : _measurementService.geminiService
                          .analyzeMeasurement(
                            systolicBP: _calculatedBP['systolic']!,
                            diastolicBP: _calculatedBP['diastolic']!,
                            heartRate: widget.estimatedBPM,
                            context: widget.initialContext,
                            healthBackground: Provider.of<UserProvider>(
                              context,
                              listen: false,
                            ).user!.healthBackground,
                          )
                          .then((analysis) {
                            _aiAnalysis = analysis;
                            return analysis;
                          }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Unable to analyze measurement: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    );
                  }

                  final analysis = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Analysis",
                        style: TextStyle(
                          color: TColor.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Interpretation
                      _buildAnalysisCard(
                        "Interpretation",
                        analysis['interpretation'] ??
                            'No interpretation available',
                        Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 10),
                      // Concerns
                      if ((analysis['concerns'] as List?)?.isNotEmpty ?? false)
                        _buildAnalysisCard(
                          "Concerns",
                          (analysis['concerns'] as List).join('\n• '),
                          Icons.warning_amber_rounded,
                          isWarning: true,
                        ),
                      const SizedBox(height: 10),
                      // Recommendations
                      if ((analysis['recommendations'] as List?)?.isNotEmpty ??
                          false)
                        _buildAnalysisCard(
                          "Recommendations",
                          (analysis['recommendations'] as List).join('\n• '),
                          Icons.lightbulb_outline,
                        ),
                      const SizedBox(height: 10),
                      // Measurement Quality
                      _buildAnalysisCard(
                        "Measurement Quality",
                        analysis['measurementQuality'] ?? 'Unknown',
                        Icons.check_circle_outline,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),

              // Save and Retake Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveMeasurement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primaryColor1,
                        foregroundColor: TColor.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Measurement',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onSave();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TColor.primaryColor1,
                        side: BorderSide(color: TColor.primaryColor1, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Retake Measurement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String content,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.orange.withAlpha(26)
            : TColor.primaryColor1.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isWarning ? Colors.orange : TColor.primaryColor1,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isWarning ? Colors.orange[700] : TColor.primaryColor1,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isWarning ? Colors.orange[700] : TColor.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
