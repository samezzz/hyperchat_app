import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../common/colo_extension.dart';

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
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlashlight() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      if (_isFlashlightOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashlightOn = !_isFlashlightOn;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flashlight: $e')),
        );
      }
    }
  }

  void _startMeasurement() {
    if (!_isCameraInitialized || !_isFlashlightOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure camera is ready and flashlight is on')),
      );
      return;
    }

    setState(() {
      isMeasuring = true;
      measurementProgress = 0.0;
    });

    // Simulate measurement progress
    Future.delayed(const Duration(milliseconds: 100), () {
      _updateProgress();
    });
  }

  void _updateProgress() {
    if (measurementProgress < 1.0) {
      setState(() {
        measurementProgress += 0.1;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        _updateProgress();
      });
    } else {
      setState(() {
        isMeasuring = false;
        _showResults = true;
      });
    }
  }

  void _resetMeasurement() {
    setState(() {
      _showResults = false;
      isMeasuring = false;
      measurementProgress = 0.0;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
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
          ? _buildResultView() 
          : (isMeasuring ? _buildMeasuringView() : _buildSetupView()),
      ),
    );
  }

  Widget _buildSetupView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Camera preview
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_cameraController!),
        ),
        // Overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Flashlight status
              Icon(
                _isFlashlightOn ? Icons.flash_on : Icons.flash_off,
                color: _isFlashlightOn ? TColor.primaryColor1 : TColor.white,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                _isFlashlightOn ? 'Flashlight is ON' : 'Flashlight is OFF',
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              // Start measurement button
              ElevatedButton(
                onPressed: _isFlashlightOn ? _startMeasurement : _toggleFlashlight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  foregroundColor: TColor.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _isFlashlightOn ? 'Start Measurement' : 'Turn On Flashlight',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasuringView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: TColor.bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Waveform visualization
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: TColor.primaryColor1.withAlpha(128),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TColor.primaryColor1.withAlpha(77),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite,
                          color: TColor.primaryColor1,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Progress text
          Text(
            "Measuring... ${(measurementProgress * 100).toInt()}%",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Hold steady",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.subTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
              // BP Values
              Center(
                child: Column(
                  children: [
                    Text(
                      "132 / 88",
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "mmHg",
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Heart Rate
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: TColor.primaryColor1,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "78 bpm",
                    style: TextStyle(
                      color: TColor.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Feedback
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
                        "Elevated – Consider deep breathing exercises",
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
                    value: "After exercise",
                    items: [
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
                    onChanged: (value) {
                      // TODO: Handle context change
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
                onPressed: () {
                  // TODO: Handle save
                  _resetMeasurement();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  foregroundColor: TColor.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save Measurement",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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