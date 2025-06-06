import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/theme_provider.dart';
import '../profile/profile_view.dart';
import '../../common/colo_extension.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

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
          'More',
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Settings',
              [
                _buildSettingItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {
                    // TODO: Navigate to language settings
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs, contact support',
                  onTap: () {
                    // TODO: Navigate to help & support
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Health Tools',
              [
                _buildSettingItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Reminders',
                  subtitle: 'Set up medication and measurement reminders',
                  onTap: () {
                    // TODO: Navigate to reminders
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'Health Reports',
                  subtitle: 'Generate and share health reports',
                  onTap: () {
                    // TODO: Navigate to health reports
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Account',
              [
                _buildSettingItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Manage your profile information',
                  onTap: () {
                    // TODO: Navigate to profile
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.security_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Manage your privacy settings',
                  onTap: () {
                    // TODO: Navigate to privacy settings
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.logout_outlined,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  onTap: () {
                    // TODO: Implement sign out
                  },
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'About',
              [
                _buildSettingItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About HyperChat',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    // TODO: Show about dialog
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: 'Read our terms of service',
                  onTap: () {
                    // TODO: Show terms of service
                  },
                ),
                _buildSettingItem(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    // TODO: Show privacy policy
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: TColor.subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? TColor.darkSurface : TColor.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: TColor.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDestructive ? TColor.error : TColor.primaryColor1,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? TColor.error : TColor.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: TColor.subTextColor,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: TColor.subTextColor,
        ),
      ),
    );
  }
} 