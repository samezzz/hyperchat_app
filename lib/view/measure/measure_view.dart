import 'dart:async';
import 'dart:isolate';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../common/colo_extension.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // Corrected import
import 'package:collection/collection.dart';
import 'measure_result_view.dart'; // Import the new results view
import 'package:image/image.dart' as img;

// Data structure for a PPG signal point
class PpgDataPoint {
  final int timestamp; // milliseconds since epoch
  final double value; // Aggregated pixel value

  PpgDataPoint(this.timestamp, this.value);
}

// Add this helper class for a simple IIR bandpass filter
class SimpleBandpassFilter {
  final double lowCut;
  final double highCut;
  final double sampleRate;
  double _prevInput = 0.0;
  double _prevOutput = 0.0;
  double _prevInput2 = 0.0;
  double _prevOutput2 = 0.0;

  SimpleBandpassFilter({
    required this.lowCut,
    required this.highCut,
    required this.sampleRate,
  });

  // Second-order bandpass (biquad) filter coefficients
  // This is a simple implementation for demonstration; for production, use a DSP library
  double process(double input) {
    // Butterworth bandpass coefficients (approximate)
    // You can tune these for your actual sample rate
    final double w0 = 2 * 3.141592653589793 * ((lowCut + highCut) / 2) / sampleRate;
    final double bw = (highCut - lowCut) / sampleRate;
    final double alpha = (bw / 2) * (1 / (2 * 3.141592653589793));
    final double cosw0 = math.cos(w0);
    final double a0 = 1 + alpha;
    final double a1 = -2 * cosw0;
    final double a2 = 1 - alpha;
    final double b0 = alpha;
    final double b1 = 0;
    final double b2 = -alpha;

    double output = (b0 / a0) * input + (b1 / a0) * _prevInput + (b2 / a0) * _prevInput2
      - (a1 / a0) * _prevOutput - (a2 / a0) * _prevOutput2;
    _prevInput2 = _prevInput;
    _prevInput = input;
    _prevOutput2 = _prevOutput;
    _prevOutput = output;
    return output;
  }
}

// Custom painter for the signal graph
class _SignalGraphPainter extends CustomPainter {
  final List<double> values;
  _SignalGraphPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Subtract mean for visualization to center the graph
    final mean = values.reduce((a, b) => a + b) / values.length;
    final centered = values.map((v) => v - mean).toList();
    final minVal = centered.reduce(math.min);
    final maxVal = centered.reduce(math.max);
    final scaleY = maxVal > minVal ? (size.height / (maxVal - minVal)) : 1.0;
    final dx = size.width / (centered.length - 1);
    final path = Path();
    for (int i = 0; i < centered.length; i++) {
      final x = i * dx;
      final y = size.height - ((centered[i] - minVal) * scaleY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MeasureView extends StatefulWidget {
  const MeasureView({super.key});

  @override
  State<MeasureView> createState() => _MeasureViewState();
}

class _MeasureViewState extends State<MeasureView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
  double _fingerDetectionThresholdValue = 120.0;
  static const int _fingerDetectionConsecutive =
      5; // Number of consecutive detections needed
  int _consecutiveDetections = 0;
  bool _fingerDetectedReadyToStart = false;

  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  // For debug info
  double? _lastAvgBrightness;
  double? _lastAvgRedness;
  double _rednessThreshold = 126.0; // Adjustable threshold for redness
  bool _showDebugInfo = true; // Always show debug info for troubleshooting

  // Debounce for measurement finger detection
  static const int _measurementFingerDetectionConsecutive = 5;
  int _measurementFingerMissingCount = 0;
  int _measurementFingerPresentCount = 0;
  bool _isMeasurementStreamRunning = false;

  // For auto-calibration
  bool _hasAutoCalibrated = false;
  List<double> _autoCalibBrightness = [];
  List<double> _autoCalibRedness = [];
  bool _isFingerDetectionStreamRunning = false;

  // --- Additions for heatmap and graph preview ---
  List<double> _recentRedValues = [];
  static const int _signalBufferLength = 200;
  Uint8List? _lastHeatmapImage;

  // Add a counter for heatmap update throttling
  int _heatmapFrameCounter = 0;
  static const int _heatmapUpdateInterval = 3; // Update every 3 frames
  Isolate? _heatmapIsolate;
  ReceivePort? _heatmapReceivePort;

  // --- Additions for filtered signal plot ---
  List<double> _filteredSignalBuffer = [];
  static const int _filteredSignalBufferLength = 200;

  // Add adaptive measurement constants
  static const int maxMeasurementDuration = 60; // seconds
  static const int minGoodIntervals = 23;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Always turn off flashlight when app is not in foreground
      _toggleFlashlight(false);
    }
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
        // Turn on flashlight immediately after camera is initialized
        await _toggleFlashlight(true);
        // Auto-calibrate thresholds on first entry
        _hasAutoCalibrated = false;
        _autoCalibBrightness.clear();
        _autoCalibRedness.clear();
        _startFingerDetection(autoCalibrate: true);
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

  Future<void> _stopFingerDetectionStream() async {
    if (_isFingerDetectionStreamRunning) {
      try {
        print('[Camera] Stopping finger detection stream...');
        await _cameraController?.stopImageStream();
      } catch (e) {
        print('[Camera] Error stopping finger detection stream: $e');
      }
      _isFingerDetectionStreamRunning = false;
    }
  }

  Future<void> _startFingerDetection({bool autoCalibrate = false}) async {
    if (_cameraController == null || !_isCameraInitialized) return;
    if (_isFingerDetectionStreamRunning) return;
    _isFingerDetectionStreamRunning = true;
    int autoCalibFrames = 0;
    print('[Camera] Starting finger detection stream...');
    await Future.delayed(const Duration(milliseconds: 300));
    _cameraController!.startImageStream((CameraImage image) {
      if (isMeasuring) {
        // Do not interfere with measurement stream
        return;
      }
      // Calculate average brightness from Y plane
      double avgBrightness = 0;
      if (image.planes.isNotEmpty) {
        avgBrightness =
            image.planes[0].bytes.reduce((value, element) => value + element) /
            image.planes[0].bytes.length;
      }
      double avgRedness = 0;
      if (image.planes.length >= 3) {
        avgRedness = image.planes[2].bytes.reduce((a, b) => a + b) / image.planes[2].bytes.length;
      }
      _lastAvgBrightness = avgBrightness;
      _lastAvgRedness = avgRedness;
      if (mounted) {
        setState(() {});
      }
      if (!_isFlashlightOn) {
        _consecutiveDetections = 0;
        if (_isFingerDetected) {
          setState(() {
            _isFingerDetected = false;
          });
        }
        return;
      }
      // Auto-calibration logic
      if (autoCalibrate && !_hasAutoCalibrated) {
        _autoCalibBrightness.add(avgBrightness);
        _autoCalibRedness.add(avgRedness);
        autoCalibFrames++;
        if (autoCalibFrames >= 10) {
          double avgB = _autoCalibBrightness.reduce((a, b) => a + b) / _autoCalibBrightness.length;
          double avgR = _autoCalibRedness.reduce((a, b) => a + b) / _autoCalibRedness.length;
          setState(() {
            _fingerDetectionThresholdValue = (avgB - 5).clamp(50.0, 600.0);
            _rednessThreshold = avgR + 5;
            _hasAutoCalibrated = true;
            _isFingerDetected = false;
          });
          // Schedule stopImageStream outside the callback
          Future.microtask(() async {
            try {
              print('[Camera] Stopping finger detection stream after auto-calibration...');
              await _cameraController?.stopImageStream();
            } catch (e) {
              print('[Camera] Error stopping finger detection stream after auto-calibration: $e');
            }
            _isFingerDetectionStreamRunning = false;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Finger detection calibrated for your environment.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            // Start normal finger detection after a delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !isMeasuring) _startFingerDetection();
            });
          });
        }
        return;
      }
      bool isFingerPresent = avgBrightness < _fingerDetectionThresholdValue && avgRedness > _rednessThreshold;
      if (isFingerPresent) {
        _consecutiveDetections++;
        if (_consecutiveDetections >= _fingerDetectionConsecutive && !isMeasuring) {
          if (!_isFingerDetected) {
            setState(() {
              _isFingerDetected = true;
            });
          }
        }
      } else {
        _consecutiveDetections = 0;
        if (_isFingerDetected) {
          setState(() {
            _isFingerDetected = false;
          });
        }
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

    // Stop finger detection stream before starting measurement
    await _stopFingerDetectionStream();

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
        _filteredSignalBuffer.clear();
        _recentRedValues.clear();
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

  Future<void> _startImageStream() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    if (_isMeasurementStreamRunning) return;
    _isMeasurementStreamRunning = true;
    print('[Camera] Starting measurement stream...');
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _cameraController!.startImageStream((CameraImage image) async {
        if (isMeasuring) {
          // Calculate average brightness from Y plane for finger detection
          double avgBrightness = 0;
          if (image.planes.isNotEmpty) {
            avgBrightness =
                image.planes[0].bytes.reduce((value, element) => value + element) /
                image.planes[0].bytes.length;
          }
          double avgRedness = 0;
          if (image.planes.length >= 3) {
            avgRedness = image.planes[2].bytes.reduce((a, b) => a + b) / image.planes[2].bytes.length;
          }
          // --- Update signal buffer for graph and debug info ---
          setState(() {
            _recentRedValues.add(avgRedness);
            if (_recentRedValues.length > _signalBufferLength) {
              _recentRedValues.removeAt(0);
            }
            _lastAvgBrightness = avgBrightness;
            _lastAvgRedness = avgRedness;
          });
          // --- Throttle and move heatmap generation to isolate ---
          _heatmapFrameCounter++;
          if (_heatmapFrameCounter % _heatmapUpdateInterval == 0) {
            // Compute mean and stddev for normalization
            final yPlane = image.planes[0].bytes;
            double mean = yPlane.reduce((a, b) => a + b) / yPlane.length;
            double sqSum = yPlane.fold(0.0, (sum, v) => sum + (v - mean) * (v - mean));
            double stddev = math.sqrt(sqSum / yPlane.length);
            double minVal = mean - 2 * stddev;
            double maxVal = mean + 2 * stddev;
            // Kill previous isolate if running
            _heatmapIsolate?.kill(priority: Isolate.immediate);
            _heatmapReceivePort?.close();
            _heatmapReceivePort = ReceivePort();
            _heatmapIsolate = await Isolate.spawn(
              _heatmapIsolateEntry,
              {
                'image': image,
                'sendPort': _heatmapReceivePort!.sendPort,
                'minVal': minVal,
                'maxVal': maxVal,
              },
            );
            _heatmapReceivePort!.listen((data) {
              if (mounted) {
                setState(() {
                  _lastHeatmapImage = data as Uint8List;
                });
              }
            });
          }
          // Use combined checks: brightness low, redness high
          bool isFingerPresent = avgBrightness < _fingerDetectionThresholdValue && avgRedness > _rednessThreshold;
          // Debounce logic for pausing/resuming
          if (isFingerPresent) {
            _measurementFingerPresentCount++;
            _measurementFingerMissingCount = 0;
            if (_measurementFingerPresentCount >= _measurementFingerDetectionConsecutive && _isPaused) {
              // Resume measurement
              if (_lastPauseTime != null) {
                final pauseDuration = DateTime.now().difference(_lastPauseTime!);
                _totalPausedMilliseconds += pauseDuration.inMilliseconds;
              }
              setState(() {
                _isPaused = false;
                _lastPauseTime = null;
                _isFingerDetected = true;
              });
              _startMeasurementTimer();
            }
          } else {
            _measurementFingerMissingCount++;
            _measurementFingerPresentCount = 0;
            if (_measurementFingerMissingCount >= _measurementFingerDetectionConsecutive && !_isPaused) {
              // Pause measurement
            setState(() {
              _isPaused = true;
              _lastPauseTime = DateTime.now();
                _isFingerDetected = false;
            });
            _measurementTimer?.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Measurement paused - Place your finger back on the camera to continue'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            }
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
      } else if (message is Map && message.containsKey('filteredSignal')) {
        if (mounted) {
          setState(() {
            _filteredSignalBuffer = List<double>.from(message['filteredSignal']);
          });
        }
      } else if (message is String && message == 'finish_early') {
        if (mounted) {
          _measurementTimer?.cancel();
          _stopMeasurement();
        }
      }
    });
  }

  Future<void> _startMeasurementTimer() {
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
          measurementProgress = _elapsedSeconds / maxMeasurementDuration;
          if (_elapsedSeconds >= maxMeasurementDuration) {
            _measurementTimer?.cancel();
            _stopMeasurement();
          }
        });
      }
    });
    return Future.value();
  }

  Future<void> _stopMeasurementStream() async {
    if (_isMeasurementStreamRunning) {
      try {
        print('[Camera] Stopping measurement stream...');
        await _cameraController?.stopImageStream();
      } catch (e) {
        print('[Camera] Error stopping measurement stream: $e');
      }
      _isMeasurementStreamRunning = false;
    }
  }

  void _stopMeasurement() async {
    await _toggleFlashlight(false);
    await _stopFingerDetectionStream();
    await _stopMeasurementStream();
    _processingIsolate?.kill();
    _receivePort?.close();
    _measurementTimer?.cancel();
    WakelockPlus.disable();

    // Only show results if we have a valid measurement
    if (mounted) {
      setState(() {
        isMeasuring = false;
        _showResults = true;
      });
    }
    // Restart finger detection after measurement
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !isMeasuring && !_showResults) {
          _startFingerDetection();
        }
      });
    }
    // Reset debounce counters
    _measurementFingerMissingCount = 0;
    _measurementFingerPresentCount = 0;
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
    final int dcWindowSize = 60; // Sliding window mean for DC removal
    List<double> rawSignalBuffer = [];
    List<double> filteredSignal = [];

    // --- Signal Processing and Peak Detection Variables ---
    // Simple moving average filter
    final int filterWindowSize = 2;

    // Peak detection parameters (will need tuning)
    final double peakProminence = 5.0; // Minimum peak prominence (not used in current logic)
    final double minPeakDistance = 0.77; // Minimum distance between peaks in seconds (targeting up to ~78 BPM)

    // --- Heart Rate Calculation Variables ---
    List<int> peakTimestamps = []; // Timestamps of detected peaks

    // Place this near your signal processing variables
    final double sampleRate = 30.0; // Adjust if your frame rate is different
    final SimpleBandpassFilter bandpassFilter = SimpleBandpassFilter(
      lowCut: 0.8, // Hz
      highCut: 3.0, // Hz
      sampleRate: sampleRate,
    );

    List<int> bpmBuffer = [];

    receivePort.listen((message) {
      if (message is CameraImage) {
        int timestamp = DateTime.now().millisecondsSinceEpoch;

        // 1. Extract Red Channel Intensity (plane 2)
        double avgIntensity = 0;
        if (message.planes.length >= 3) {
          avgIntensity = message.planes[2].bytes.reduce((a, b) => a + b) / message.planes[2].bytes.length;
        } else {
          // Handle case where planes are missing
          return;
        }

        // --- Sliding window mean for DC removal ---
        rawSignalBuffer.add(avgIntensity);
        if (rawSignalBuffer.length > dcWindowSize) {
          rawSignalBuffer.removeAt(0);
        }
        double slidingMean = rawSignalBuffer.reduce((a, b) => a + b) / rawSignalBuffer.length;
        double centeredSignal = avgIntensity - slidingMean;
        double amplifiedSignal = centeredSignal * 60.0;
        // --- Debug output for raw and processed values ---
        if (filteredSignal.length % 30 == 0) {
          print('[PPG] Raw red: $avgIntensity, Centered: $centeredSignal, Amplified: $amplifiedSignal');
        }
        ppgData.add(PpgDataPoint(timestamp, amplifiedSignal));
        if (ppgData.length > bufferSize) {
          ppgData.removeAt(0);
        }

        // 2. Apply Simple Moving Average Filter
        if (ppgData.length >= filterWindowSize) {
          double movingAverage =
              ppgData
                  .sublist(ppgData.length - filterWindowSize)
                  .map((e) => e.value)
                  .reduce((a, b) => a + b) /
              filterWindowSize;

          filteredSignal.add(movingAverage);
          // Debug: print filtered signal value
          if (filteredSignal.length % 30 == 0) {
            print('[PPG] Filtered signal sample: $movingAverage');
          }
        }

        // 3. Peak Detection (Derivative-based approach)
            if (filteredSignal.length > 2) {
              int lastIndex = filteredSignal.length - 1;
          double prevValue2 = filteredSignal[lastIndex - 2];
          double prevValue1 = filteredSignal[lastIndex - 1];
          double currValue = filteredSignal[lastIndex];

          double derivPrev = prevValue1 - prevValue2;
          double derivCurr = currValue - prevValue1;

          // Detect a maximum: derivative changes from positive to negative
          bool isMaxPeak = (derivPrev > 0 && derivCurr < 0);
          // Detect a minimum: derivative changes from negative to positive
          bool isMinPeak = (derivPrev < 0 && derivCurr > 0);

          print('[PPG] Deriv-based peak check: prev2=$prevValue2, prev1=$prevValue1, curr=$currValue, derivPrev=$derivPrev, derivCurr=$derivCurr, isMaxPeak=$isMaxPeak, isMinPeak=$isMinPeak');

          if (isMaxPeak) {
            int currentPeakTimestamp = ppgData[ppgData.length - 2].timestamp;
                bool isTooCloseToLastPeak = false;
                if (peakTimestamps.isNotEmpty) {
                  int timeDiff = currentPeakTimestamp - peakTimestamps.last;
                  if (timeDiff < minPeakDistance * 1000) {
                    isTooCloseToLastPeak = true;
                  }
                }
            if (!isTooCloseToLastPeak) {
                  peakTimestamps.add(currentPeakTimestamp);
              print('[PPG] Deriv-based MAX peak detected at $currentPeakTimestamp, total peaks: ${peakTimestamps.length}');
              // Keep peakTimestamps buffer size in check
                  if (peakTimestamps.length > 50) {
                    peakTimestamps.removeAt(0);
                  }
                  // 4. Calculate Heart Rate from NN Intervals (if enough peaks)
                  if (peakTimestamps.length > 5) {
                // Signal quality check: require variance above threshold
                double variance = 0;
                if (filteredSignal.length > 1) {
                  double mean = filteredSignal.reduce((a, b) => a + b) / filteredSignal.length;
                  variance = filteredSignal.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / (filteredSignal.length - 1);
                }
                const double minVarianceThreshold = 0.1;
                print('[PPG] Signal variance: $variance');
                if (variance < minVarianceThreshold) {
                  print('[PPG] Variance below threshold ($variance < $minVarianceThreshold), skipping BPM calculation.');
                  return;
                }
                    List<int> nnIntervals = [];
                    for (int i = 1; i < peakTimestamps.length; i++) {
                      nnIntervals.add(
                        peakTimestamps[i] - peakTimestamps[i - 1],
                      );
                    }
                print('[PPG] NN intervals: $nnIntervals');
                // Stricter outlier removal: keep only intervals within 0.7x–1.3x the median and between 770ms–1030ms
                if (nnIntervals.isNotEmpty) {
                  List<int> sortedNN = List.from(nnIntervals)..sort();
                  double median = sortedNN.length % 2 == 1
                      ? sortedNN[sortedNN.length ~/ 2].toDouble()
                      : (sortedNN[sortedNN.length ~/ 2 - 1] + sortedNN[sortedNN.length ~/ 2]) / 2.0;
                  nnIntervals = nnIntervals.where((v) => v > 0.5 * median && v < 1.5 * median && v >= 770 && v <= 1030).toList();
                }
                // Use the median of the filtered intervals for BPM calculation
                // Smooth the BPM using a moving average of the last 5 BPM values
                if (nnIntervals.length >= 5) {
                  List<int> sortedNN = List.from(nnIntervals)..sort();
                  double medianNN = sortedNN.length % 2 == 1
                      ? sortedNN[sortedNN.length ~/ 2].toDouble()
                      : (sortedNN[sortedNN.length ~/ 2 - 1] + sortedNN[sortedNN.length ~/ 2]) / 2.0;
                  // Calculate BPM: 60 seconds / median NN interval in seconds
                  if (medianNN > 0) {
                    int calculatedBPM = (60000 / medianNN).round();
                      if (calculatedBPM > 30 && calculatedBPM < 180) {
                      // Moving average buffer for BPM
                      bpmBuffer.add(calculatedBPM);
                      if (bpmBuffer.length > 5) bpmBuffer.removeAt(0);
                      int smoothedBPM = (bpmBuffer.reduce((a, b) => a + b) / bpmBuffer.length).round();
                      sendPort.send(smoothedBPM);
                    }
                  }
                }
                // If enough good intervals, finish early (adaptive measurement)
                if (nnIntervals.length >= minGoodIntervals) {
                  sendPort.send('finish_early');
                }
              }
            }
          if (isMinPeak) {
            int currentMinTimestamp = ppgData[ppgData.length - 2].timestamp;
            print('[PPG] Deriv-based MIN peak detected at $currentMinTimestamp');
          }
        }
      }
    }});
  }

  Future<void> _resetMeasurement() async {
    // Stop all ongoing processes
    await _toggleFlashlight(false);
    await _stopFingerDetectionStream();
    await _stopMeasurementStream();
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
        _isFingerDetected = false;
        _filteredSignalBuffer.clear();
        _recentRedValues.clear();
      });
      _cameraSizeController.reverse();
    }

    // Re-initialize camera and auto-calibrate as on first entry
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted && !isMeasuring && !_showResults) {
          await _initializeCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    _toggleFlashlight(false); // Turn off flashlight when leaving the view
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
                onSave: () async => _resetMeasurement(), // Pass the reset function as the save callback
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
        Container(
          width: double.infinity,
          height: double.infinity,
          color: TColor.bgColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40), // Top padding
        // Camera preview in circle
                if (_cameraController != null &&
                    _cameraController!.value.isInitialized)
                  Center(
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
                const SizedBox(height: 40), // Space between camera and context
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
                              items:
                                  const [
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
                              style: TextStyle(color: TColor.textColor),
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
                    const SizedBox(height: 8),
                    Text(
                      'Keep your finger flat and steady on the camera and flash for best results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 14,
                      ),
                      ),
                      const SizedBox(height: 32),
                      // Threshold sliders for finger detection
                      // Calibrate button OUTSIDE the collapsible
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.tune),
                          label: const Text('Calibrate Thresholds'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              if (_lastAvgBrightness != null) {
                                _fingerDetectionThresholdValue = (_lastAvgBrightness! - 2).clamp(50.0, 600.0);
                              }
                              if (_lastAvgRedness != null) {
                                _rednessThreshold = _lastAvgRedness! + 2;
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Calibrated! Brightness: ${_fingerDetectionThresholdValue.toStringAsFixed(1)}, Redness: ${_rednessThreshold.toStringAsFixed(1)}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // COLLAPSIBLE for all other settings
                      Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: Container(
                          color: Colors.transparent,
                          child: ExpansionTile(
                            initiallyExpanded: true,
                            backgroundColor: Colors.transparent,
                            collapsedBackgroundColor: Colors.transparent,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            maintainState: true,
                            title: Text(
                              'Finger Detection Settings',
                              style: TextStyle(
                                color: TColor.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Brightness Threshold',
                                style: TextStyle(
                                  color: TColor.subTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Slider(
                                value: _fingerDetectionThresholdValue.clamp(50.0, 600.0),
                                min: 50,
                                max: 600,
                                divisions: 550,
                                label: _fingerDetectionThresholdValue.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _fingerDetectionThresholdValue = value;
                                  });
                                },
                              ),
                              Text(
                                'Current: ${_fingerDetectionThresholdValue.round()}',
                                style: TextStyle(
                                  color: TColor.subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Redness Threshold',
                                style: TextStyle(
                                  color: TColor.subTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Slider(
                                value: _rednessThreshold,
                                min: 0,
                                max: 255,
                                divisions: 255,
                                label: _rednessThreshold.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _rednessThreshold = value;
                                  });
                                },
                              ),
                              Text(
                                'Current: ${_rednessThreshold.round()}',
                                style: TextStyle(
                                  color: TColor.subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Debug info - always visible for troubleshooting
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: TColor.primaryColor1.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: TColor.primaryColor1.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Debug Info (Real-time)',
                                          style: TextStyle(
                                            color: TColor.textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          Icons.info_outline,
                                          color: TColor.primaryColor1,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Brightness: ${_lastAvgBrightness?.toStringAsFixed(1) ?? "---"}',
                                      style: TextStyle(
                                        color: TColor.subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Redness: ${_lastAvgRedness?.toStringAsFixed(1) ?? "---"}',
                                      style: TextStyle(
                                        color: TColor.subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Flashlight: ${_isFlashlightOn ? "ON" : "OFF"}',
                                      style: TextStyle(
                                        color: TColor.subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Consecutive Detections: $_consecutiveDetections',
                                      style: TextStyle(
                                        color: TColor.subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Detection Status: ${_isFlashlightOn && _lastAvgBrightness != null && _lastAvgRedness != null ? (_lastAvgBrightness! < _fingerDetectionThresholdValue && _lastAvgRedness! > _rednessThreshold ? "FINGER DETECTED" : "NO FINGER") : "CHECKING..."}',
                                      style: TextStyle(
                                        color: _isFlashlightOn && _lastAvgBrightness != null && _lastAvgRedness != null
                                            ? (_lastAvgBrightness! < _fingerDetectionThresholdValue && _lastAvgRedness! > _rednessThreshold
                                                ? Colors.green
                                                : Colors.red)
                                            : TColor.subTextColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                ),
              ),
            ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32), // Add bottom padding for scroll
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Finger detection popup overlay
        if (_isFingerDetected && !isMeasuring && _hasAutoCalibrated && _isFingerDetectionStreamRunning)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Theme.of(context).brightness == Brightness.dark
                    ? TColor.darkSurface
                    : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Finger detected! Ready to start measurement.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFingerDetected = false;
                            });
                            _startMeasurement();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Measurement',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        'info':
            'The camera detects subtle changes in light absorption as blood flows through your finger. This is the foundation of photoplethysmography (PPG), a non-invasive way to measure blood flow.',
      },
      {
        'range': [15, 35],
        'title': 'Step 2: Signal Stabilization',
        'info':
            'The system is now analyzing the stability of your blood flow pattern. A steady signal is crucial for accurate measurements, as it helps filter out any movement artifacts.',
      },
      {
        'range': [35, 65],
        'title': 'Step 3: Heart Rate Analysis',
        'info':
            'Your heart rate is being calculated by analyzing the time between consecutive heartbeats. This interval, known as the RR interval, is key to understanding your cardiovascular health.',
      },
      {
        'range': [65, 85],
        'title': 'Step 4: Blood Pressure Estimation',
        'info':
            'Using your heart rate and signal characteristics, the system is estimating your blood pressure. This is done through advanced algorithms that correlate pulse wave characteristics with blood pressure.',
      },
      {
        'range': [85, 100],
        'title': 'Step 5: Final Analysis',
        'info':
            'The system is now performing final calculations and validating the measurements to ensure accuracy. This includes cross-checking all parameters and applying calibration factors.',
      },
    ];

    // Find current step based on percentage
    final currentStep = steps.firstWhere(
      (step) =>
          percentage >= (step['range'] as List<int>)[0] &&
          percentage <= (step['range'] as List<int>)[1],
      orElse: () => steps.last,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: TColor.bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera preview in circle with overlays (no toggle)
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            AnimatedBuilder(
              animation: _cameraSizeAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                  width: _cameraSizeAnimation.value,
                  height: _cameraSizeAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                        border: Border.all(color: TColor.primaryColor1, width: 2),
                  ),
                  child: ClipOval(
                    child: CameraPreview(_cameraController!),
                  ),
                    ),
                    // Always show signal graph overlay
                    _buildSignalGraphOverlay(),
                  ],
                );
              },
            ),
          // Heatmap preview below the camera preview
          if (_lastHeatmapImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: SizedBox(
                width: _cameraSizeAnimation.value,
                height: _cameraSizeAnimation.value * 0.6, // 60% of preview height
                child: _buildHeatmapPreview(),
              ),
            ),
          // Filtered signal plot below the heatmap
          _buildFilteredSignalPlot(),
          const SizedBox(height: 40),
          // Estimated BPM display or paused state
          Text(
            _isPaused
                ? 'Measurement Paused'
                : (_estimatedBPM > 0 ? '${_estimatedBPM} BPM' : 'Measuring...'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isPaused ? Colors.orange : TColor.textColor,
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
            style: TextStyle(
              color: _isPaused ? Colors.orange : TColor.subTextColor,
              fontSize: 16,
              fontWeight: _isPaused ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 40),
          // Progress bar container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                // Linear progress indicator
                LinearProgressIndicator(
                  value: measurementProgress,
                  backgroundColor: TColor.subTextColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isPaused ? Colors.orange : TColor.primaryColor1,
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
                        color: _isPaused ? Colors.orange : TColor.primaryColor1,
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
                    style: TextStyle(color: TColor.textColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Map value to heatmap color (simple blue-green-yellow-red)
  Color _heatmapColor(double value, double min, double max) {
    final norm = ((value - min) / (max - min)).clamp(0.0, 1.0);
    if (norm < 0.25) {
      // Blue to Green
      return Color.lerp(Colors.blue, Colors.green, norm / 0.25)!;
    } else if (norm < 0.5) {
      // Green to Yellow
      return Color.lerp(Colors.green, Colors.yellow, (norm - 0.25) / 0.25)!;
    } else if (norm < 0.75) {
      // Yellow to Orange
      return Color.lerp(Colors.yellow, Colors.orange, (norm - 0.5) / 0.25)!;
    } else {
      // Orange to Red
      return Color.lerp(Colors.orange, Colors.red, (norm - 0.75) / 0.25)!;
    }
  }

  // Helper: Generate heatmap image from red channel values
  Future<Uint8List> _generateHeatmapImage(CameraImage image) async {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0].bytes;
    double mean = yPlane.reduce((a, b) => a + b) / yPlane.length;
    double sqSum = yPlane.fold(0.0, (sum, v) => sum + (v - mean) * (v - mean));
    double stddev = math.sqrt(sqSum / yPlane.length);
    double minVal = mean - 2 * stddev;
    double maxVal = mean + 2 * stddev;

    // Create an image buffer using the image package
    final img.Image heatmapImg = img.Image(width: width, height: height);

    for (int i = 0; i < yPlane.length; i++) {
      final y = yPlane[i].toDouble();
      final color = _heatmapColor(y, minVal, maxVal);
      heatmapImg.setPixelRgba(
        i % width,
        i ~/ width,
        color.red,
        color.green,
        color.blue,
        255,
      );
    }

    // Encode as PNG
    return Uint8List.fromList(img.encodePng(heatmapImg));
  }

  // Widget: Heatmap preview
  Widget _buildHeatmapPreview() {
    if (_lastHeatmapImage == null || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final width = _cameraController!.value.previewSize?.width ?? 160;
    final height = _cameraController!.value.previewSize?.height ?? 120;
    return Image.memory(
      _lastHeatmapImage!,
      width: _cameraSizeAnimation.value,
      height: _cameraSizeAnimation.value,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }

  // Widget: Real-time signal graph overlay
  Widget _buildSignalGraphOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SizedBox(
        height: 40,
        child: AnimatedOpacity(
          opacity: (_recentRedValues.length / _signalBufferLength).clamp(0.0, 1.0),
          duration: Duration(milliseconds: 500),
          child: CustomPaint(
            painter: _SignalGraphPainter(_recentRedValues),
            size: Size(_cameraSizeAnimation.value, 40),
          ),
        ),
      ),
    );
  }

  // Widget: Filtered signal plot
  Widget _buildFilteredSignalPlot() {
    if (_filteredSignalBuffer.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: SizedBox(
        width: _cameraSizeAnimation.value,
        height: 60,
        child: AnimatedOpacity(
          opacity: (_filteredSignalBuffer.length / _filteredSignalBufferLength).clamp(0.0, 1.0),
          duration: Duration(milliseconds: 500),
          child: CustomPaint(
            painter: _SignalGraphPainter(_filteredSignalBuffer),
            size: Size(_cameraSizeAnimation.value, 60),
          ),
        ),
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

  // Helper for isolate entry
  static void _heatmapIsolateEntry(Map<String, dynamic> args) async {
    final CameraImage image = args['image'];
    final SendPort sendPort = args['sendPort'];
    final double minVal = args['minVal'];
    final double maxVal = args['maxVal'];
    final int width = image.width;
    final int height = image.height;
    final yPlane = image.planes[0].bytes;
    final img.Image heatmapImg = img.Image(width: width, height: height);
    for (int i = 0; i < yPlane.length; i++) {
      final y = yPlane[i].toDouble();
      // Use a simple blue-green-yellow-red mapping
      Color color;
      final norm = ((y - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
      if (norm < 0.25) {
        color = Color.lerp(Colors.blue, Colors.green, norm / 0.25)!;
      } else if (norm < 0.5) {
        color = Color.lerp(Colors.green, Colors.yellow, (norm - 0.25) / 0.25)!;
      } else if (norm < 0.75) {
        color = Color.lerp(Colors.yellow, Colors.orange, (norm - 0.5) / 0.25)!;
      } else {
        color = Color.lerp(Colors.orange, Colors.red, (norm - 0.75) / 0.25)!;
      }
      heatmapImg.setPixelRgba(
        i % width,
        i ~/ width,
        color.red,
        color.green,
        color.blue,
        255,
      );
    }
    final pngBytes = Uint8List.fromList(img.encodePng(heatmapImg));
    sendPort.send(pngBytes);
  }
}
