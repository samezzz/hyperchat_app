import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;

  const EditProfileView({
    super.key,
    required this.user,
  });

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
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _conditions = [
    'Hypertension',
    'Diabetes',
    'Heart Disease',
    'Kidney Disease',
    'None'
  ];
  final List<String> _smokingOptions = [
    'Never smoked',
    'Former smoker',
    'Occasional smoker',
    'Regular smoker'
  ];
  final List<String> _drinkingOptions = [
    'Never drink',
    'Occasional drinker',
    'Regular drinker',
    'Heavy drinker'
  ];
  final List<String> _activityLevels = [
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Extremely active'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.user.basicInfo.fullName);
    _emailController = TextEditingController(text: widget.user.basicInfo.email);
    _ageController = TextEditingController(text: widget.user.basicInfo.age.toString());
    _weightController = TextEditingController(text: widget.user.basicInfo.weight.toString());
    _heightController = TextEditingController(text: widget.user.basicInfo.height.toString());
    _selectedGender = widget.user.basicInfo.gender;
    _hasHypertension = widget.user.healthBackground.hasHypertension;
    _hasFamilyHistory = widget.user.healthBackground.familyHistory;
    _selectedConditions = List<String>.from(widget.user.healthBackground.conditions);
    _smokingHabits = widget.user.healthBackground.smokingHabits;
    _drinkingHabits = widget.user.healthBackground.drinkingHabits;
    _activityLevel = widget.user.healthBackground.activityLevel;
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
          weight: double.tryParse(_weightController.text) ?? widget.user.basicInfo.weight,
          height: double.tryParse(_heightController.text) ?? widget.user.basicInfo.height,
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
      );

      await Provider.of<UserProvider>(context, listen: false).updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
          ),
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
                      color: colorScheme.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: colorScheme.primary,
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
            const SizedBox(height: 30),

            _buildSectionTitle('Health Information'),
            _buildSwitchTile(
              title: 'Hypertension',
              subtitle: 'Do you have hypertension?',
              value: _hasHypertension,
              onChanged: (value) => setState(() => _hasHypertension = value),
            ),
            _buildSwitchTile(
              title: 'Family History',
              subtitle: 'Do you have a family history of hypertension?',
              value: _hasFamilyHistory,
              onChanged: (value) => setState(() => _hasFamilyHistory = value),
            ),
            const SizedBox(height: 15),
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: colorScheme.onSurfaceVariant,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelect({
    required String title,
    required String subtitle,
    required List<String> selectedItems,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(item),
                selected: isSelected,
                onSelected: (_) => onChanged(item),
                backgroundColor: colorScheme.surfaceVariant,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 