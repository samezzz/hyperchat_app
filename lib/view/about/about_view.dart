import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../common/colo_extension.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = packageInfo;
      });
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: TColor.textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About",
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
              // App Logo and Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: TColor.primaryColor1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: TColor.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _packageInfo?.appName ?? 'HyperChat',
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version ${_packageInfo?.version ?? '1.0.0'} (${_packageInfo?.buildNumber ?? '1'})',
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // App Description
              Text(
                'About HyperChat',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'HyperChat is a comprehensive blood pressure monitoring app designed to help you track and manage your cardiovascular health. With features like real-time measurements, trend analysis, and personalized insights, we aim to empower you to take control of your health journey.',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // Features
              Text(
                'Key Features',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                icon: Icons.favorite,
                title: 'Blood Pressure Monitoring',
                description: 'Track your systolic, diastolic, and heart rate measurements with ease.',
              ),
              _buildFeatureItem(
                icon: Icons.show_chart,
                title: 'Trend Analysis',
                description: 'Visualize your health data with interactive charts and graphs.',
              ),
              _buildFeatureItem(
                icon: Icons.notifications,
                title: 'Smart Reminders',
                description: 'Never miss a measurement with customizable reminders.',
              ),
              _buildFeatureItem(
                icon: Icons.share,
                title: 'Data Export',
                description: 'Export your health data for sharing with healthcare providers.',
              ),
              const SizedBox(height: 30),

              // Contact
              Text(
                'Contact Us',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Have questions or feedback? We\'d love to hear from you!\n\nEmail: support@hyperchat.com\nWebsite: www.hyperchat.com',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // Copyright
              Center(
                child: Text(
                  '© ${DateTime.now().year} HyperChat. All rights reserved.',
                  style: TextStyle(
                    color: TColor.subTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: TColor.primaryColor1,
            size: 24,
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: TColor.subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 