import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

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
          "Privacy Policy",
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
              _buildSection(
                title: 'Introduction',
                content: 'At HyperChat, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our blood pressure monitoring application.',
              ),
              _buildSection(
                title: 'Information We Collect',
                content: 'We collect the following types of information:\n\n'
                    '• Personal Information: Name, email address, age, gender, and other demographic information you provide during registration.\n'
                    '• Health Data: Blood pressure readings, heart rate measurements, and related health metrics.\n'
                    '• Device Information: Device type, operating system, and unique device identifiers.\n'
                    '• Usage Data: How you interact with the app, features used, and time spent on different sections.',
              ),
              _buildSection(
                title: 'How We Use Your Information',
                content: 'We use your information to:\n\n'
                    '• Provide and maintain the app\'s functionality\n'
                    '• Track and analyze your health metrics\n'
                    '• Send you notifications and reminders\n'
                    '• Improve our services and user experience\n'
                    '• Generate reports and insights about your health\n'
                    '• Communicate with you about updates and features',
              ),
              _buildSection(
                title: 'Data Sharing and Disclosure',
                content: 'We may share your information in the following circumstances:\n\n'
                    '• With your explicit consent\n'
                    '• With healthcare providers you choose to share data with\n'
                    '• To comply with legal obligations\n'
                    '• To protect our rights and safety\n\n'
                    'We do not sell your personal information to third parties.',
              ),
              _buildSection(
                title: 'Data Security',
                content: 'We implement appropriate security measures to protect your information:\n\n'
                    '• Encryption of data in transit and at rest\n'
                    '• Regular security assessments\n'
                    '• Access controls and authentication\n'
                    '• Secure data storage and backup procedures',
              ),
              _buildSection(
                title: 'Your Rights',
                content: 'You have the right to:\n\n'
                    '• Access your personal information\n'
                    '• Correct inaccurate data\n'
                    '• Request deletion of your data\n'
                    '• Export your health data\n'
                    '• Opt-out of data sharing\n'
                    '• Withdraw consent at any time',
              ),
              _buildSection(
                title: 'Data Retention',
                content: 'We retain your information for as long as necessary to provide our services and comply with legal obligations. You can request deletion of your data at any time.',
              ),
              _buildSection(
                title: 'Children\'s Privacy',
                content: 'Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
              ),
              _buildSection(
                title: 'Changes to This Policy',
                content: 'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
              ),
              _buildSection(
                title: 'Contact Us',
                content: 'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                    'Email: privacy@hyperchat.com\n'
                    'Website: www.hyperchat.com/privacy',
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                  style: TextStyle(
                    color: TColor.subTextColor,
                    fontSize: 14,
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

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 