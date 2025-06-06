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

class _MeasureViewState extends State<MeasureView> with SingleTickerProviderStateMixin {
  bool isMeasuring = false;
  double measurementProgress = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashlightOn = false;
  bool _showResults = false;
  int _estimatedBPM = 0; // To store the calculated heart rate
  bool _isFingerDetected = false;
  Timer? _fingerDetectionTimer;
  static const int _fingerDetectionThreshold = 5; // Number of consecutive detections needed
  int _consecutiveDetections = 0;

  // Isolate related variables
  Isolate? _processingIsolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  // Timer for measurement duration and progress
  Timer? _measurementTimer;
  static const int _measurementDuration = 15; // Measurement duration in seconds
  int _elapsedSeconds = 0;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required for measurement')),
        );
      }
      return;
    }

    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras available')),
        );
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
      imageFormatGroup: ImageFormatGroup.yuv420, // Use YUV for easier access to color channels
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
        avgBrightness = image.planes[0].bytes.reduce((value, element) => value + element) / image.planes[0].bytes.length;
      }

      // Finger detection logic
      // When finger covers camera, brightness drops significantly
      bool isFingerPresent = avgBrightness < 50; // Adjust threshold as needed

      if (isFingerPresent) {
        _consecutiveDetections++;
        if (_consecutiveDetections >= _fingerDetectionThreshold && !isMeasuring) {
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
      });
    }

    WakelockPlus.enable();

    // Start the isolate first to get the sendPort
    await _startProcessingIsolate();

    // Start the image stream and send images to the isolate
    _startImageStream();

    // Start the measurement timer for progress and completion
    _startMeasurementTimer();
  }

  void _startImageStream() {
     _cameraController!.startImageStream((CameraImage image) {
      // Send image to the isolate for processing
       _sendPort?.send(image);
     });
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
     _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
           setState(() {
              _elapsedSeconds = timer.tick;
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
     _measurementTimer?.cancel(); // Ensure timer is cancelled
     WakelockPlus.disable(); // Allow screen to turn off

     if (mounted) {
       setState(() {
         isMeasuring = false;
         _showResults = true; // Set to true to show results view
       });
     }
  }

  // This function runs in a separate isolate
  static void _imageProcessingEntry(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort); // Send the receive port back to the main isolate

    // --- PPG Processing Variables ---
    List<PpgDataPoint> ppgData = [];
    final int windowSize = 60 * 5; // Process data over 5 seconds (assuming 60 fps)
    final int bufferSize = 60 * 15; // Keep 15 seconds of data in buffer

    // --- Signal Processing and Peak Detection Variables ---
    // Simple moving average filter
    final int filterWindowSize = 5;
    List<double> rawSignalBuffer = [];
    List<double> filteredSignal = [];

    // Peak detection parameters (will need tuning)
    final double peakProminence = 5.0; // Minimum peak prominence
    final double minPeakDistance = 0.5; // Minimum distance between peaks in seconds

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
             avgIntensity = message.planes[0].bytes.reduce((value, element) => value + element) / message.planes[0].bytes.length;
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
            double movingAverage = rawSignalBuffer.sublist(rawSignalBuffer.length - filterWindowSize).reduce((a, b) => a + b) / filterWindowSize;
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
                    if (currentValue > previousValue && previousValue >= previousValue2) {
                       // Consider this a potential peak.
                       // Add filtering for realistic peaks (e.g., minimum distance and prominence)
                       int currentPeakTimestamp = ppgData.last.timestamp; // Use timestamp of the latest data point

                       bool isTooCloseToLastPeak = false;
                       if (peakTimestamps.isNotEmpty) {
                           int timeDiff = currentPeakTimestamp - peakTimestamps.last;
                           if (timeDiff < minPeakDistance * 1000) { // minPeakDistance in milliseconds
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
                             if (peakTimestamps.length > 50) { // Example: Keep last ~50 peaks
                               peakTimestamps.removeAt(0);
                            }


                            // 4. Calculate Heart Rate from NN Intervals (if enough peaks)
                            // Need at least two peaks to calculate an interval. More peaks for a stable average.
                            if (peakTimestamps.length > 5) { // Require a minimum number of peaks for calculation
                                List<int> nnIntervals = [];
                                for (int i = 1; i < peakTimestamps.length; i++) {
                                   nnIntervals.add(peakTimestamps[i] - peakTimestamps[i-1]);
                                }

                                // Basic outlier removal for NN intervals (optional but good practice)
                                // Can implement something like removing intervals significantly different from the median.
                                // For simplicity, skipping outlier removal in this basic implementation.

                                // Calculate average NN interval
                                double averageNN = nnIntervals.reduce((a, b) => a + b) / nnIntervals.length;

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


  void _resetMeasurement() {
    _stopMeasurement(); // Ensure everything is stopped
    if (mounted) {
       setState(() {
         _showResults = false;
         isMeasuring = false;
         measurementProgress = 0.0;
         _estimatedBPM = 0;
         _elapsedSeconds = 0;
       });
    }

     _toggleFlashlight(false); // Turn off flashlight
     
     // Restart finger detection after a short delay
     Future.delayed(const Duration(milliseconds: 500), () {
       if (mounted && !isMeasuring && !_showResults) {
         _startFingerDetection();
       }
     });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _processingIsolate?.kill(); // Ensure isolate is killed on dispose
    _receivePort?.close();
    _measurementTimer?.cancel(); // Ensure timer is cancelled
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
              onSave: _resetMeasurement, // Pass the reset function as the save callback
            )
          : (_isCameraInitialized ? (isMeasuring ? _buildMeasuringView() : _buildSetupView()) : const Center(child: CircularProgressIndicator())),
      ),
    );
  }

  Widget _buildSetupView() {
    return Stack(
      children: [
        // Camera preview
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
        // Overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instruction text
              Text(
                'Place your finger on the camera to start measurement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


 Widget _buildMeasuringView() {
    // This view will show the animation and progress
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: TColor.bgColor, // Or a different background if needed
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsating Heart Animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  Icons.favorite,
                  color: TColor.primaryColor1,
                  size: 120, // Increased size for prominence
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Estimated BPM display
          Text(
            _estimatedBPM > 0 ? '${_estimatedBPM} BPM' : 'Measuring...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 32, // Increased size
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Progress text or instruction
          Text(
             _elapsedSeconds >= _measurementDuration - 3 ?
             'Finishing measurement...' : // Message when nearing completion
             'Hold your finger steady on the camera lens with flash on.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.subTextColor,
              fontSize: 16,
            ),
          ),
           const SizedBox(height: 40),
          // Linear progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: LinearProgressIndicator(
              value: measurementProgress, // Use the state variable for progress
              backgroundColor: TColor.subTextColor.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(TColor.primaryColor1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
           const SizedBox(height: 10),
           // Timer display
           Text(
            '${_elapsedSeconds} / ${_measurementDuration} seconds',
            style: TextStyle(
              color: TColor.subTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}