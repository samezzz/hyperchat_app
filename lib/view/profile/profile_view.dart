import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../common/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'edit_profile_view.dart';
import '../../common/colo_extension.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _notificationsEnabled = true;
  bool _dataSharingEnabled = false;
  bool _sleepTrackingEnabled = true;
  bool _exerciseTrackingEnabled = true;
  bool _stressTrackingEnabled = false;

  final List<String> _conditions = [
    'Hypertension',
    'Diabetes',
    'Heart Disease',
    'Kidney Disease',
    'None'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Provider.of<UserProvider>(context, listen: false).loadUser(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);
    
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (userProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: TColor.primaryColor1,
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No user data found',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  foregroundColor: TColor.white,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TColor.bgColor,
      appBar: AppBar(
        backgroundColor: TColor.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: TColor.textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Profile",
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(user),
              const SizedBox(height: 30),

              // Settings & Preferences
              _buildSectionTitle("Settings & Preferences"),
              _buildSettingsSection(user),
              const SizedBox(height: 30),

              // Reports & Data
              _buildSectionTitle("Reports & Data"),
              _buildReportsSection(),
              const SizedBox(height: 30),

              // Support & Info
              _buildSectionTitle("Support & Info"),
              _buildSupportSection(),
              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: ${e.toString()}'),
                          backgroundColor: TColor.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.error,
                    foregroundColor: TColor.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(UserModel user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return _buildCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: TColor.primaryColor1,
                child: Text(
                  user.basicInfo.fullName.isNotEmpty ? user.basicInfo.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: TColor.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.basicInfo.fullName,
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.basicInfo.email,
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileView(user: user),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit,
                  color: TColor.primaryColor1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    Color? backgroundColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDarkMode ? TColor.darkSurface : TColor.cardColor),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TColor.black.withAlpha(13), // 0.05 * 255
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

  Widget _buildSettingsSection(UserModel user) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      children: [
        _buildCard(
          child: Column(
            children: [
              // Theme Toggle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: TColor.primaryColor1,
                      size: 24,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Dark Mode',
                        style: TextStyle(
                          color: TColor.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: TColor.primaryColor1,
                      activeTrackColor: TColor.primaryColor1.withAlpha(77), // 0.3 * 255
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildSettingItem(
                icon: Icons.notifications,
                title: "Notifications",
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              const Divider(),
              _buildSettingItem(
                icon: Icons.share,
                title: "Data Sharing",
                value: _dataSharingEnabled,
                onChanged: (value) {
                  setState(() {
                    _dataSharingEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildCard(
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.bedtime,
                title: "Sleep Tracking",
                value: _sleepTrackingEnabled,
                onChanged: (value) {
                  setState(() {
                    _sleepTrackingEnabled = value;
                  });
                },
              ),
              const Divider(),
              _buildSettingItem(
                icon: Icons.fitness_center,
                title: "Exercise Tracking",
                value: _exerciseTrackingEnabled,
                onChanged: (value) {
                  setState(() {
                    _exerciseTrackingEnabled = value;
                  });
                },
              ),
              const Divider(),
              _buildSettingItem(
                icon: Icons.psychology,
                title: "Stress Tracking",
                value: _stressTrackingEnabled,
                onChanged: (value) {
                  setState(() {
                    _stressTrackingEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: TColor.primaryColor1,
            size: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TColor.primaryColor1,
            activeTrackColor: TColor.primaryColor1.withAlpha(77), // 0.3 * 255
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Column(
      children: [
        _buildCard(
          child: Column(
            children: [
              _buildReportItem(
                icon: Icons.assessment,
                title: "Blood Pressure History",
                subtitle: "View your BP trends",
              ),
              const Divider(),
              _buildReportItem(
                icon: Icons.fitness_center,
                title: "Activity Reports",
                subtitle: "Track your progress",
              ),
              const Divider(),
              _buildReportItem(
                icon: Icons.psychology,
                title: "Stress Analysis",
                subtitle: "Monitor your stress levels",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: TColor.primaryColor1,
            size: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
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
                Text(
                  subtitle,
                  style: TextStyle(
                    color: TColor.subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: TColor.subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildCard(
          child: Column(
            children: [
              _buildSupportItem(
                icon: Icons.help_outline,
                title: "Help Center",
                subtitle: "Get support and answers",
              ),
              const Divider(),
              _buildSupportItem(
                icon: Icons.privacy_tip,
                title: "Privacy Policy",
                subtitle: "Read our privacy policy",
              ),
              const Divider(),
              _buildSupportItem(
                icon: Icons.description,
                title: "Terms of Service",
                subtitle: "Read our terms of service",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: TColor.primaryColor1,
            size: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
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
                Text(
                  subtitle,
                  style: TextStyle(
                    color: TColor.subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: TColor.subTextColor,
          ),
        ],
      ),
    );
  }
}
