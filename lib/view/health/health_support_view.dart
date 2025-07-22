import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthSupportView extends StatelessWidget {
  const HealthSupportView({super.key});

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
          "Health Resources",
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
                title: "Health Resources",
                children: [
                  _buildResourceCard(
                    title: "Understanding Blood Pressure",
                    description: "Learn about blood pressure readings, what they mean, and how to maintain healthy levels.",
                    icon: Icons.favorite,
                    onTap: () => _launchURL("https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"),
                  ),
                  _buildResourceCard(
                    title: "Healthy Lifestyle Tips",
                    description: "Get tips on diet, exercise, and stress management for better blood pressure control.",
                    icon: Icons.fitness_center,
                    onTap: () => _launchURL("https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure"),
                  ),
                  _buildResourceCard(
                    title: "Emergency Guidelines",
                    description: "Know when to seek emergency medical attention for blood pressure concerns.",
                    icon: Icons.emergency,
                    onTap: () => _launchURL("https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: "Medical Disclaimer",
                content: "HyperChat is not a medical device and is not intended to diagnose, treat, cure, or prevent any disease. The information provided by the app is for general informational purposes only and should not be considered medical advice. Always consult with qualified healthcare professionals for medical advice and treatment.",
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: "Emergency Contact",
                content: "In case of a medical emergency, please call your local emergency services immediately. Do not rely on this app for emergency medical assistance.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (content != null)
          Text(
            content,
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 16,
              height: 1.5,
            ),
          )
        else if (children != null)
          ...children,
      ],
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: TColor.cardColor,
      child: InkWell(
        onTap: null, // Deactivated
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColor.primaryColor1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: TColor.primaryColor1,
                  size: 24,
                ),
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
                        fontWeight: FontWeight.w600,
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
              Icon(
                Icons.arrow_forward_ios,
                color: TColor.subTextColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
} 