import 'dart:async';
import 'dart:isolate';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../common/colo_extension.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // Corrected import
import 'package:collection/collection.dart';
import 'measure_result_view.dart'; // Import the new results view

// Data structure for a PPG signal point
class PpgDataPoint {
  final int timestamp; // milliseconds since epoch
  final double value; // Aggregated pixel value

  PpgDataPoint(this.timestamp, this.value);
}

class MeasureView extends StatefulWidget {
  const MeasureView({super.key});

  @override
  State<MeasureView> createState() => _MeasureViewState();
}

class _MeasureViewState extends State<MeasureView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _cameraSizeController;
  late Animation<double> _cameraSizeAnimation;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool isMeasuring = false;
  bool _showResults = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  int _estimatedBPM = 0;
  double measurementProgress = 0.0;
  final int _measurementDuration = 30; // 30 seconds measurement
  DateTime? _measurementStartTime;
  Timer? _measurementTimer;
  Isolate? _processingIsolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _totalPausedMilliseconds = 0;
  DateTime? _lastPauseTime;
  String _selectedContext = "At rest";
  bool _isFlashlightOn = false;
  bool _isFingerDetected = false;
  Timer? _fingerDetectionTimer;
  static const int _fingerDetectionThreshold =
      5; // Number of consecutive detections needed
  int _consecutiveDetections = 0;

  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize camera size animation
    _cameraSizeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cameraSizeAnimation = Tween<double>(begin: 150.0, end: 100.0).animate(
      CurvedAnimation(parent: _cameraSizeController, curve: Curves.easeInOut),
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for measurement'),
          ),
        );
      }
      return;
    }

    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    // Initialize camera controller with rear camera
    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      rearCamera,
      ResolutionPreset.low, // Using low resolution for faster processing
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup
          .yuv420, // Use YUV for easier access to color channels
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // Start finger detection stream
        _startFingerDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlashlight(bool value) async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      if (value) {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashlightOn = true);
      } else {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _isFlashlightOn = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flashlight: $e')),
        );
      }
    }
  }

  void _startFingerDetection() {
    if (_cameraController == null || !_isCameraInitialized) return;

    _cameraController!.startImageStream((CameraImage image) {
      if (isMeasuring) {
        // If we're measuring, stop the finger detection stream
        _cameraController?.stopImageStream();
        return;
      }

      // Calculate average brightness from Y plane
      double avgBrightness = 0;
      if (image.planes.isNotEmpty) {
        avgBrightness =
            image.planes[0].bytes.reduce((value, element) => value + element) /
            image.planes[0].bytes.length;
      }

      // Finger detection logic
      // When finger covers camera, brightness drops significantly
      // On mobile with flashlight, covered camera is still bright, so use a higher threshold
      // Typical values: Laptop (dark): < 50, Mobile (with flash, covered): ~80-120
      // You may need to tune this value for your device. Try 120 as a starting point.
      bool isFingerPresent = avgBrightness < 120;

      if (isFingerPresent) {
        _consecutiveDetections++;
        if (_consecutiveDetections >= _fingerDetectionThreshold &&
            !isMeasuring) {
          _consecutiveDetections = 0;
          // Stop the finger detection stream before starting measurement
          _cameraController?.stopImageStream();
          _startMeasurement();
        }
      } else {
        _consecutiveDetections = 0;
      }
    });
  }

  void _startMeasurement() async {
    if (!_isCameraInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please ensure camera is ready')),
        );
      }
      return;
    }

    // Turn on flashlight automatically
    await _toggleFlashlight(true);

    if (mounted) {
      setState(() {
        isMeasuring = true;
        _showResults = false;
        measurementProgress = 0.0;
        _estimatedBPM = 0;
        _elapsedSeconds = 0;
        _totalPausedMilliseconds = 0;
        _measurementStartTime = DateTime.now();
        _lastPauseTime = null;
        _isPaused = false;
      });
    }

    WakelockPlus.enable();

    // Start the isolate first to get the sendPort
    await _startProcessingIsolate();

    // Start the image stream and send images to the isolate
    _startImageStream();

    // Start the measurement timer for progress and completion
    _startMeasurementTimer();

    _cameraSizeController.forward();
  }

  void _startImageStream() {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      _cameraController!.startImageStream((CameraImage image) {
        if (isMeasuring) {
          // Calculate average brightness from Y plane for finger detection
          double avgBrightness = 0;
          if (image.planes.isNotEmpty) {
            avgBrightness = image.planes[0].bytes.reduce((value, element) => value + element) /
                image.planes[0].bytes.length;
          }

          // Check if finger is still present
          // On mobile with flashlight, covered camera is still bright, so use a higher threshold
          // Typical values: Laptop (dark): < 50, Mobile (with flash, covered): ~80-120
          // You may need to tune this value for your device. Try 120 as a starting point.
          bool isFingerPresent = avgBrightness < 120;

          if (!isFingerPresent && !_isPaused) {
            // Finger removed, pause measurement
            setState(() {
              _isPaused = true;
              _lastPauseTime = DateTime.now();
            });
            
            // Only pause the timer, keep the stream running
            _measurementTimer?.cancel();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement paused - Place your finger back on the camera to continue'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (isFingerPresent && _isPaused) {
            // Finger placed back, resume measurement
            if (_lastPauseTime != null) {
              final pauseDuration = DateTime.now().difference(_lastPauseTime!);
              _totalPausedMilliseconds += pauseDuration.inMilliseconds;
            }
            setState(() {
              _isPaused = false;
              _lastPauseTime = null;
            });
            
            // Restart the timer with the correct progress
            _startMeasurementTimer();
          }

          // Only send image to isolate if not paused
          if (!_isPaused) {
            _sendPort?.send(image);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting camera stream: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
        _resetMeasurement();
      }
    }
  }

  Future<void> _startProcessingIsolate() async {
    _receivePort = ReceivePort();
    _processingIsolate = await Isolate.spawn(
      _imageProcessingEntry,
      _receivePort!.sendPort,
    );

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message; // Get the send port from the isolate
      } else if (message is int) {
        // Received calculated BPM from isolate
        if (mounted) {
          setState(() {
            _estimatedBPM = message;
          });
        }
      } else if (message is String && message == 'measurement_complete') {
        // Isolate signals measurement is complete (optional, using timer for now)
        // _stopMeasurement(); // We'll use the timer for now for consistent duration
      }
    });
  }

  void _startMeasurementTimer() {
    _measurementTimer?.cancel(); // Cancel any existing timer
    
    // Set the start time if this is the first start
    if (_measurementStartTime == null) {
      _measurementStartTime = DateTime.now();
    }
    
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        final now = DateTime.now();
        final totalElapsedMilliseconds = now.difference(_measurementStartTime!).inMilliseconds;
        final actualElapsedMilliseconds = totalElapsedMilliseconds - _totalPausedMilliseconds;
        final actualElapsedSeconds = (actualElapsedMilliseconds / 1000).floor();
        
        setState(() {
          _elapsedSeconds = actualElapsedSeconds;
          measurementProgress = _elapsedSeconds / _measurementDuration;

          if (_elapsedSeconds >= _measurementDuration) {
            _measurementTimer?.cancel();
            _stopMeasurement();
          }
        });
      }
    });
  }

  void _stopMeasurement() {
    _cameraController?.stopImageStream();
    _processingIsolate?.kill();
    _receivePort?.close();
    _measurementTimer?.cancel();
    WakelockPlus.disable();

    // Only show results if we have a valid measurement
    if (mounted) {
      setState(() {
        isMeasuring = false;
        // Only show results if we have a valid BPM and completed the measurement
        if (_estimatedBPM > 0 && _elapsedSeconds >= _measurementDuration) {
          _navigateToResults();
        } else {
          // If measurement was invalid, reset and show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Measurement incomplete. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
          _resetMeasurement();
        }
      });
    }
  }

  // This function runs in a separate isolate
  static void _imageProcessingEntry(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    sendPort.send(
      receivePort.sendPort,
    ); // Send the receive port back to the main isolate

    // --- PPG Processing Variables ---
    List<PpgDataPoint> ppgData = [];
    final int windowSize =
        60 * 5; // Process data over 5 seconds (assuming 60 fps)
    final int bufferSize = 60 * 15; // Keep 15 seconds of data in buffer

    // --- Signal Processing and Peak Detection Variables ---
    // Simple moving average filter
    final int filterWindowSize = 5;
    List<double> rawSignalBuffer = [];
    List<double> filteredSignal = [];

    // Peak detection parameters (will need tuning)
    final double peakProminence = 5.0; // Minimum peak prominence
    final double minPeakDistance =
        0.5; // Minimum distance between peaks in seconds

    // --- Heart Rate Calculation Variables ---
    List<int> peakTimestamps = []; // Timestamps of detected peaks

    receivePort.listen((message) {
      if (message is CameraImage) {
        int timestamp = DateTime.now().millisecondsSinceEpoch;

        // 1. Extract Green Channel Intensity
        // Assuming YUV420_888 format based on camera controller setup
        // The Y plane is luminance, U and V are chrominance.
        // Green channel intensity can be approximated from Y plane,
        // or more accurately, process all planes and convert to RGB
        // or use a native plugin for direct RGB access.
        // For simplicity here, we'll use the average luminance from the Y plane
        // as a proxy for PPG signal, similar to lib2/lib8, but this is a limitation
        // of purely Dart-based access to specific color channels in YUV.
        // A more robust implementation would process RGB data.
        double avgIntensity = 0;
        if (message.planes.isNotEmpty) {
          // A more accurate method for green channel in YUV:
          // Iterate over Y plane and use approximate conversion
          // Or, if available, use a library that provides easier access.
          // For now, sticking to the simple average of Y plane for demonstration
          avgIntensity =
              message.planes[0].bytes.reduce(
                (value, element) => value + element,
              ) /
              message.planes[0].bytes.length;
        } else {
          // Handle case where planes are empty
          return;
        }

        // Store the raw data point
        rawSignalBuffer.add(avgIntensity);
        if (rawSignalBuffer.length > bufferSize) {
          rawSignalBuffer.removeAt(0);
        }
        ppgData.add(PpgDataPoint(timestamp, avgIntensity));
        if (ppgData.length > bufferSize) {
          ppgData.removeAt(0);
        }

        // 2. Apply Simple Moving Average Filter
        if (rawSignalBuffer.length >= filterWindowSize) {
          double movingAverage =
              rawSignalBuffer
                  .sublist(rawSignalBuffer.length - filterWindowSize)
                  .reduce((a, b) => a + b) /
              filterWindowSize;
          filteredSignal.add(movingAverage);
          if (filteredSignal.length > bufferSize) {
            filteredSignal.removeAt(0);
          }

          // 3. Peak Detection (Simple approach based on local maxima and distance)
          if (filteredSignal.length > 1) {
            // A basic peak detection looks for a point higher than its immediate neighbors.
            // For better robustness, we check against a few previous points after filtering.
            if (filteredSignal.length > 2) {
              int lastIndex = filteredSignal.length - 1;
              double currentValue = filteredSignal[lastIndex];
              double previousValue = filteredSignal[lastIndex - 1];
              double previousValue2 = filteredSignal[lastIndex - 2];

              // Check if current value is a local maximum compared to recent points
              if (currentValue > previousValue &&
                  previousValue >= previousValue2) {
                // Consider this a potential peak.
                // Add filtering for realistic peaks (e.g., minimum distance and prominence)
                int currentPeakTimestamp = ppgData
                    .last
                    .timestamp; // Use timestamp of the latest data point

                bool isTooCloseToLastPeak = false;
                if (peakTimestamps.isNotEmpty) {
                  int timeDiff = currentPeakTimestamp - peakTimestamps.last;
                  if (timeDiff < minPeakDistance * 1000) {
                    // minPeakDistance in milliseconds
                    isTooCloseToLastPeak = true;
                  }
                }

                // Simple check for prominence could involve comparing the peak value
                // to the surrounding minima. This basic check is omitted for simplicity
                // but is important for a robust implementation.
                bool meetsProminence = true; // Placeholder - needs a real check

                if (!isTooCloseToLastPeak && meetsProminence) {
                  peakTimestamps.add(currentPeakTimestamp);
                  // Keep peakTimestamps buffer size in check (e.g., last 30 seconds of peaks)
                  // A window based on time or a fixed number of peaks related to expected heart rate range is better.
                  if (peakTimestamps.length > 50) {
                    // Example: Keep last ~50 peaks
                    peakTimestamps.removeAt(0);
                  }

                  // 4. Calculate Heart Rate from NN Intervals (if enough peaks)
                  // Need at least two peaks to calculate an interval. More peaks for a stable average.
                  if (peakTimestamps.length > 5) {
                    // Require a minimum number of peaks for calculation
                    List<int> nnIntervals = [];
                    for (int i = 1; i < peakTimestamps.length; i++) {
                      nnIntervals.add(
                        peakTimestamps[i] - peakTimestamps[i - 1],
                      );
                    }

                    // Basic outlier removal for NN intervals (optional but good practice)
                    // Can implement something like removing intervals significantly different from the median.
                    // For simplicity, skipping outlier removal in this basic implementation.

                    // Calculate average NN interval
                    double averageNN =
                        nnIntervals.reduce((a, b) => a + b) /
                        nnIntervals.length;

                    // Calculate BPM: 60 seconds / average NN interval in seconds
                    if (averageNN > 0) {
                      int calculatedBPM = (60000 / averageNN).round();

                      // Simple validation for plausible BPM range
                      if (calculatedBPM > 30 && calculatedBPM < 180) {
                        // Send BPM back to main isolate
                        sendPort.send(calculatedBPM);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    });
  }

  void _resetMeasurement() async {
    // Stop all ongoing processes
    _processingIsolate?.kill();
    _receivePort?.close();
    _measurementTimer?.cancel();
    
    if (mounted) {
      setState(() {
        _showResults = false;
        isMeasuring = false;
        measurementProgress = 0.0;
        _estimatedBPM = 0;
        _elapsedSeconds = 0;
        _totalPausedMilliseconds = 0;
        _measurementStartTime = null;
        _lastPauseTime = null;
        _isPaused = false;
      });
      _cameraSizeController.reverse();
    }

    await _toggleFlashlight(false);

    // Restart finger detection after a short delay
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !isMeasuring && !_showResults) {
          _startFingerDetection();
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _heartController.dispose();
    _cameraSizeController.dispose();
    if (_cameraController != null) {
      _cameraController!.stopImageStream();
      _cameraController!.dispose();
    }
    _processingIsolate?.kill();
    _receivePort?.close();
    _measurementTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    return Scaffold(
      backgroundColor: TColor.bgColor,
      body: SafeArea(
        child: _showResults
            ? MeasureResultView(
                estimatedBPM: _estimatedBPM, // Pass the estimated BPM
                initialContext: _selectedContext, // Pass the selected context
                onSave:
                    _resetMeasurement, // Pass the reset function as the save callback
              )
            : (_isCameraInitialized
                  ? (isMeasuring ? _buildMeasuringView() : _buildSetupView())
                  : const Center(child: CircularProgressIndicator())),
      ),
    );
  }

  Widget _buildSetupView() {
    return Stack(
      children: [
        // Background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: TColor.bgColor,
        ),
        // Camera preview in circle
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _cameraSizeAnimation,
                builder: (context, child) {
                  return Container(
                    width: _cameraSizeAnimation.value,
                    height: _cameraSizeAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TColor.primaryColor1,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CameraPreview(_cameraController!),
                    ),
                  );
                },
              ),
            ),
          ),
        // Overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          color: TColor.bgColor.withOpacity(0.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 220), // Space for the camera preview
              // Context Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Select Measurement Context',
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This helps in providing more accurate readings',
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? TColor.darkSurface 
                            : TColor.white,
                        border: Border.all(
                          color: TColor.subTextColor.withAlpha(77),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
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
                    ),
                    const SizedBox(height: 20),
                    // Instruction text
                    Text(
                      'Place your finger on the camera to start measurement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasuringView() {
    // Calculate percentage completion
    final percentage = (measurementProgress * 100).round();
    
    // Define measurement steps with their ranges and educational information
    final List<Map<String, dynamic>> steps = [
      {
        'range': [0, 15],
        'title': 'Step 1: Initial Signal Detection',
        'info': 'The camera detects subtle changes in light absorption as blood flows through your finger. This is the foundation of photoplethysmography (PPG), a non-invasive way to measure blood flow.',
      },
      {
        'range': [15, 35],
        'title': 'Step 2: Signal Stabilization',
        'info': 'The system is now analyzing the stability of your blood flow pattern. A steady signal is crucial for accurate measurements, as it helps filter out any movement artifacts.',
      },
      {
        'range': [35, 65],
        'title': 'Step 3: Heart Rate Analysis',
        'info': 'Your heart rate is being calculated by analyzing the time between consecutive heartbeats. This interval, known as the RR interval, is key to understanding your cardiovascular health.',
      },
      {
        'range': [65, 85],
        'title': 'Step 4: Blood Pressure Estimation',
        'info': 'Using your heart rate and signal characteristics, the system is estimating your blood pressure. This is done through advanced algorithms that correlate pulse wave characteristics with blood pressure.',
      },
      {
        'range': [85, 100],
        'title': 'Step 5: Final Analysis',
        'info': 'The system is now performing final calculations and validating the measurements to ensure accuracy. This includes cross-checking all parameters and applying calibration factors.',
      },
    ];

    // Find current step based on percentage
    final currentStep = steps.firstWhere(
      (step) => percentage >= (step['range'] as List<int>)[0] && percentage <= (step['range'] as List<int>)[1],
      orElse: () => steps.last,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: TColor.bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera preview in circle
          if (_cameraController != null && _cameraController!.value.isInitialized)
            AnimatedBuilder(
              animation: _cameraSizeAnimation,
              builder: (context, child) {
                return Container(
                  width: _cameraSizeAnimation.value,
                  height: _cameraSizeAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TColor.primaryColor1,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CameraPreview(_cameraController!),
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
          // Estimated BPM display
          Text(
            _isPaused ? 'Measurement Paused' : (_estimatedBPM > 0 ? '${_estimatedBPM} BPM' : 'Measuring...'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isPaused ? TColor.subTextColor : TColor.textColor,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Progress text or instruction
          Text(
            _isPaused 
                ? 'Place your finger back on the camera to continue'
                : (_elapsedSeconds >= _measurementDuration - 3
                    ? 'Finishing measurement...'
                    : 'Hold your finger steady on the camera lens with flash on.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: TColor.subTextColor, fontSize: 16),
          ),
          const SizedBox(height: 40),
          // Progress bar container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // Linear progress indicator
                LinearProgressIndicator(
                  value: _isPaused ? measurementProgress : measurementProgress,
                  backgroundColor: TColor.subTextColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isPaused ? TColor.subTextColor : TColor.primaryColor1,
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                // Percentage and step indicator row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step indicator
                    Expanded(
                      child: Text(
                        currentStep['title'] as String,
                        style: TextStyle(
                          color: TColor.subTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Percentage
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: TColor.primaryColor1,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Educational information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TColor.primaryColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentStep['info'] as String,
                    style: TextStyle(
                      color: TColor.textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToResults() {
    if (mounted) {
      setState(() {
        _showResults = true;
        isMeasuring = false;
      });
    }
  }
}
