import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

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
          "Terms of Service",
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
                title: '1. Acceptance of Terms',
                content: 'By accessing and using HyperChat, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this application.',
              ),
              _buildSection(
                title: '2. Use License',
                content: 'Permission is granted to temporarily use HyperChat for personal, non-commercial purposes. This license does not include:\n\n'
                    '• Modifying or copying the app\'s materials\n'
                    '• Using the materials for commercial purposes\n'
                    '• Attempting to reverse engineer any software\n'
                    '• Removing any copyright or proprietary notations',
              ),
              _buildSection(
                title: '3. Medical Disclaimer',
                content: 'HyperChat is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease. The information provided by the app is for general informational purposes only and should not be considered medical advice. Always consult with qualified healthcare professionals for medical advice and treatment.',
              ),
              _buildSection(
                title: '4. User Responsibilities',
                content: 'As a user of HyperChat, you agree to:\n\n'
                    '• Provide accurate and complete information\n'
                    '• Maintain the security of your account\n'
                    '• Use the app in compliance with all applicable laws\n'
                    '• Not misuse or abuse the app\'s features\n'
                    '• Report any security vulnerabilities or issues',
              ),
              _buildSection(
                title: '5. Data Accuracy',
                content: 'While we strive to provide accurate measurements and data analysis, we cannot guarantee the accuracy of all information. Users should verify important measurements and consult healthcare professionals for medical decisions.',
              ),
              _buildSection(
                title: '6. Service Modifications',
                content: 'We reserve the right to modify or discontinue any part of HyperChat without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance of the service.',
              ),
              _buildSection(
                title: '7. Limitation of Liability',
                content: 'In no event shall HyperChat be liable for any damages arising out of the use or inability to use the app, including but not limited to direct, indirect, incidental, or consequential damages.',
              ),
              _buildSection(
                title: '8. Intellectual Property',
                content: 'All content, features, and functionality of HyperChat are owned by us and are protected by international copyright, trademark, and other intellectual property laws.',
              ),
              _buildSection(
                title: '9. Termination',
                content: 'We may terminate or suspend your access to HyperChat immediately, without prior notice, for any breach of these Terms of Service.',
              ),
              _buildSection(
                title: '10. Governing Law',
                content: 'These Terms shall be governed by and construed in accordance with the laws of your jurisdiction, without regard to its conflict of law provisions.',
              ),
              _buildSection(
                title: '11. Changes to Terms',
                content: 'We reserve the right to modify these terms at any time. We will notify users of any changes by updating the "Last Updated" date. Your continued use of the app after such modifications constitutes your acceptance of the new terms.',
              ),
              _buildSection(
                title: '12. Contact Information',
                content: 'If you have any questions about these Terms of Service, please contact us at:\n\n'
                    'Email: legal@hyperchat.com\n'
                    'Website: www.hyperchat.com/terms',
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