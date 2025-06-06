import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../../common/colo_extension.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;

  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late String _selectedGender;
  late bool _hasHypertension;
  late bool _hasFamilyHistory;
  late List<String> _selectedConditions;
  late String _smokingHabits;
  late String _drinkingHabits;
  late String _activityLevel;
  late bool _hasBPCuff;
  late String _preferredHand;
  late bool _cameraPermission;
  late bool _flashlightPermission;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _conditions = [
    'Diabetes',
    'Chronic Kidney Disease',
    'Heart Disease',
    'High Cholesterol',
    'Sleep Apnea',
    'Other'
  ];
  final List<String> _smokingOptions = [
    'Never',
    'Occasionally',
    'Regularly',
    'Heavily'
  ];
  final List<String> _drinkingOptions = [
    'Never',
    'Occasionally',
    'Regularly',
    'Heavily'
  ];
  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkFlashlightPermission();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.user.basicInfo.fullName,
    );
    _emailController = TextEditingController(text: widget.user.basicInfo.email);
    _ageController = TextEditingController(
      text: widget.user.basicInfo.age.toString(),
    );
    _weightController = TextEditingController(
      text: widget.user.basicInfo.weight.toString(),
    );
    _heightController = TextEditingController(
      text: widget.user.basicInfo.height.toString(),
    );
    _selectedGender = widget.user.basicInfo.gender.isEmpty ? _genders[0] : widget.user.basicInfo.gender;
    _hasHypertension = widget.user.healthBackground.hasHypertension;
    _hasFamilyHistory = widget.user.healthBackground.familyHistory;
    _selectedConditions = List<String>.from(
      widget.user.healthBackground.conditions,
    );
    _smokingHabits = widget.user.healthBackground.smokingHabits.isEmpty
        ? _smokingOptions[0]
        : widget.user.healthBackground.smokingHabits;
    _drinkingHabits = widget.user.healthBackground.drinkingHabits.isEmpty
        ? _drinkingOptions[0]
        : widget.user.healthBackground.drinkingHabits;
    _activityLevel = widget.user.healthBackground.activityLevel.isEmpty
        ? _activityLevels[0]
        : widget.user.healthBackground.activityLevel;
    _hasBPCuff = widget.user.measurementContext.hasBPCuff ?? false;
    _preferredHand = widget.user.measurementContext.preferredHand ?? 'Right';
    _cameraPermission = widget.user.measurementContext.cameraPermission;
    _flashlightPermission = widget.user.measurementContext.flashlightPermission;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final updatedUser = widget.user.copyWith(
        basicInfo: widget.user.basicInfo.copyWith(
          fullName: _nameController.text,
          email: _emailController.text,
          age: int.tryParse(_ageController.text) ?? widget.user.basicInfo.age,
          weight:
              double.tryParse(_weightController.text) ??
              widget.user.basicInfo.weight,
          height:
              double.tryParse(_heightController.text) ??
              widget.user.basicInfo.height,
          gender: _selectedGender,
        ),
        healthBackground: widget.user.healthBackground.copyWith(
          hasHypertension: _hasHypertension,
          familyHistory: _hasFamilyHistory,
          conditions: _selectedConditions,
          smokingHabits: _smokingHabits,
          drinkingHabits: _drinkingHabits,
          activityLevel: _activityLevel,
        ),
        measurementContext: MeasurementContext(
          weight: double.tryParse(_weightController.text),
          height: double.tryParse(_heightController.text),
          hasBPCuff: _hasBPCuff,
          preferredHand: _preferredHand,
          cameraPermission: _cameraPermission,
          flashlightPermission: _flashlightPermission,
        ),
      );

      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
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
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: ${e.toString()}',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkFlashlightPermission() async {
    // Check if the device has a camera with flash
    final cameras = await availableCameras();
    final hasCameraWithFlash = cameras.any((camera) => 
      camera.lensDirection == CameraLensDirection.back && 
      camera.sensorOrientation != null
    );

    if (!hasCameraWithFlash) {
      setState(() {
        _flashlightPermission = false;
      });
      return;
    }

    // Check camera permission (required for flashlight)
    final cameraStatus = await Permission.camera.status;
    setState(() {
      _flashlightPermission = cameraStatus.isGranted;
    });
  }

  Future<void> _requestFlashlightPermission() async {
    final cameraStatus = await Permission.camera.request();
    setState(() {
      _flashlightPermission = cameraStatus.isGranted;
    });

    if (!cameraStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for flashlight access'),
          ),
        );
      }
    }
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
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: TColor.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TColor.primaryColor1,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            _buildCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    value: _selectedGender,
                    label: 'Gender',
                    icon: Icons.people_outline,
                    items: _genders,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGender = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('Health Information'),
            _buildCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Hypertension',
                    subtitle: 'Do you have hypertension?',
                    value: _hasHypertension,
                    onChanged: (value) =>
                        setState(() => _hasHypertension = value),
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: 'Family History',
                    subtitle: 'Do you have a family history of hypertension?',
                    value: _hasFamilyHistory,
                    onChanged: (value) =>
                        setState(() => _hasFamilyHistory = value),
                  ),
                  const Divider(),
                  _buildMultiSelect(
                    title: 'Health Conditions',
                    subtitle: 'Select all that apply',
                    selectedItems: _selectedConditions,
                    items: _conditions,
                    onChanged: (value) {
                      setState(() {
                        if (_selectedConditions.contains(value)) {
                          _selectedConditions.remove(value);
                        } else {
                          _selectedConditions.add(value);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    value: _smokingHabits,
                    label: 'Smoking Habits',
                    icon: Icons.smoking_rooms_outlined,
                    items: _smokingOptions,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _smokingHabits = value);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    value: _drinkingHabits,
                    label: 'Drinking Habits',
                    icon: Icons.local_bar_outlined,
                    items: _drinkingOptions,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _drinkingHabits = value);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildDropdown(
                    value: _activityLevel,
                    label: 'Activity Level',
                    icon: Icons.directions_run_outlined,
                    items: _activityLevels,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _activityLevel = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle('Measurement Context'),
            _buildCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'BP Cuff',
                    subtitle: 'Do you have access to a BP cuff?',
                    value: _hasBPCuff,
                    onChanged: (value) => setState(() => _hasBPCuff = value),
                  ),
                  _buildDropdown(
                    value: _preferredHand,
                    label: 'Preferred Hand',
                    icon: Icons.handshake_outlined,
                    items: const ['Left', 'Right'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _preferredHand = value);
                      }
                    },
                  ),
                  _buildSwitchTile(
                    title: 'Camera Permission',
                    subtitle: 'Required for PPG measurements',
                    value: _cameraPermission,
                    onChanged: (value) =>
                        setState(() => _cameraPermission = value),
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    title: 'Flashlight Permission',
                    subtitle: 'Required for PPG measurements',
                    value: _flashlightPermission,
                    onChanged: (value) =>
                        setState(() => _flashlightPermission = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? TColor.darkSurface : TColor.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TColor.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          color: TColor.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: TColor.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: TColor.subTextColor),
        prefixIcon: Icon(icon, color: TColor.primaryColor1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.subTextColor.withAlpha(77)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.subTextColor.withAlpha(77)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.primaryColor1, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: TColor.subTextColor),
        prefixIcon: Icon(icon, color: TColor.primaryColor1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.subTextColor.withAlpha(77)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.subTextColor.withAlpha(77)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TColor.primaryColor1, width: 2),
        ),
      ),
      dropdownColor: TColor.bgColor,
      style: TextStyle(color: TColor.textColor),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: TColor.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: TColor.subTextColor, fontSize: 14),
      ),
      value: value,
      onChanged: (newValue) {
        if (title == 'Flashlight Permission') {
          _requestFlashlightPermission();
        } else {
          onChanged(newValue);
        }
      },
      activeColor: TColor.primaryColor1,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMultiSelect({
    required String title,
    required String subtitle,
    required List<String> selectedItems,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: TColor.subTextColor, fontSize: 14),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              label: Text(
                item,
                style: TextStyle(
                  color: isSelected ? TColor.white : TColor.textColor,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) => onChanged(item),
              backgroundColor: TColor.bgColor,
              selectedColor: TColor.primaryColor1,
              checkmarkColor: TColor.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? TColor.primaryColor1
                      : TColor.subTextColor.withOpacity(0.3),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
