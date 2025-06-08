import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../common/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/learning_paths_initializer.dart';
import 'edit_profile_view.dart';
import '../../common/colo_extension.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../services/notification_service.dart';
import '../about/about_view.dart';
import '../privacy/privacy_policy_view.dart';
import '../terms/terms_of_service_view.dart';
import '../health/health_support_view.dart';
import '../help/help_support_view.dart';

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
    'None',
  ];

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkNotificationPermission();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUser(user.uid);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        setState(() {
          _dataSharingEnabled = userProvider.user!.dataSharingEnabled;
        });
      }
    }
  }

  Future<void> _checkNotificationPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (mounted) {
      setState(() {
        _notificationsEnabled = isAllowed;
      });
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      final isAllowed = await _notificationService.requestPermissions();
      if (mounted) {
        setState(() {
          _notificationsEnabled = isAllowed;
        });
      }
    } else {
      // Show a dialog to confirm disabling notifications
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Disable Notifications',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to disable notifications? You may miss important reminders for blood pressure checks.',
              style: TextStyle(color: TColor.textColor, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: TColor.subTextColor, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _notificationService.cancelAllReminders();
                  if (mounted) {
                    setState(() {
                      _notificationsEnabled = false;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Disable',
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleDataSharingToggle(bool value) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    if (value) {
      // Show confirmation dialog when enabling data sharing
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Enable Data Sharing',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Enabling data sharing allows you to export your blood pressure measurements. Your data will only be shared when you explicitly choose to export it.',
              style: TextStyle(color: TColor.textColor, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: TColor.subTextColor, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final updatedUser = user.copyWith(dataSharingEnabled: true);
                  await userProvider.updateUser(updatedUser);
                  if (mounted) {
                    setState(() {
                      _dataSharingEnabled = true;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Enable',
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Show confirmation dialog when disabling data sharing
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Disable Data Sharing',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Disabling data sharing will prevent you from exporting your blood pressure measurements. You can enable it again at any time.',
              style: TextStyle(color: TColor.textColor, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: TColor.subTextColor, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final updatedUser = user.copyWith(dataSharingEnabled: false);
                  await userProvider.updateUser(updatedUser);
                  if (mounted) {
                    setState(() {
                      _dataSharingEnabled = false;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Disable',
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
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
          child: CircularProgressIndicator(color: TColor.primaryColor1),
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
                style: TextStyle(color: TColor.textColor, fontSize: 16),
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
          icon: Icon(Icons.arrow_back, color: TColor.textColor),
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

              // Admin Section (only show for admin users)
              if (user.isAdmin) ...[
                _buildSectionTitle("Admin"),
                _buildAdminSection(),
                const SizedBox(height: 30),
              ],

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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  user.basicInfo.fullName.isNotEmpty
                      ? user.basicInfo.fullName[0].toUpperCase()
                      : '?',
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
                icon: Icon(Icons.edit, color: TColor.primaryColor1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, Color? backgroundColor}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDarkMode ? TColor.darkSurface : TColor.cardColor),
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
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
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
                      activeTrackColor: TColor.primaryColor1.withAlpha(
                        77,
                      ), // 0.3 * 255
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildSettingItem(
                icon: Icons.notifications,
                title: "Notifications",
                value: _notificationsEnabled,
                onChanged: _handleNotificationToggle,
              ),
              const Divider(),
              _buildSettingItem(
                icon: Icons.share,
                title: "Data Sharing",
                value: _dataSharingEnabled,
                onChanged: _handleDataSharingToggle,
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
    bool? value,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    Widget content = Row(
      children: [
        Icon(icon, color: TColor.primaryColor1, size: 24),
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
        if (onTap != null)
          Icon(Icons.arrow_forward_ios, color: TColor.subTextColor, size: 16)
        else if (value != null && onChanged != null)
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TColor.primaryColor1,
            activeTrackColor: TColor.primaryColor1.withAlpha(77), // 0.3 * 255
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: onTap != null ? InkWell(onTap: onTap, child: content) : content,
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
          Icon(icon, color: TColor.primaryColor1, size: 24),
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
                  style: TextStyle(color: TColor.subTextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: TColor.subTextColor),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportView()),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.medical_services_outlined,
            title: "Health Resources",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HealthSupportView(),
              ),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: "About",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutView()),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyView(),
              ),
            ),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: "Terms of Service",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsOfServiceView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.school,
            title: "Initialize Learning Paths",
            onTap: () async {
              try {
                final initializer = LearningPathsInitializer();
                await initializer.initializeLearningPaths();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Learning paths initialized successfully!'),
                      backgroundColor: TColor.primaryColor1,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error initializing learning paths: ${e.toString()}',
                      ),
                      backgroundColor: TColor.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: TColor.primaryColor1),
      title: Text(
        title,
        style: TextStyle(
          color: TColor.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(color: TColor.subTextColor);
  }
}
