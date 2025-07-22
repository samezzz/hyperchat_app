import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

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
          "Help & Support",
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
                title: "Getting Started",
                children: [
                  _buildHelpCard(
                    title: "Quick Start Guide",
                    description: "Learn the basics of using HyperChat",
                    icon: Icons.rocket_launch,
                    onTap: () => _launchURL("https://www.hyperchat.com/guide"),
                  ),
                  _buildHelpCard(
                    title: "Video Tutorials",
                    description: "Watch step-by-step video guides",
                    icon: Icons.play_circle_outline,
                    onTap: () => _launchURL("https://www.hyperchat.com/tutorials"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: "Common Issues",
                children: [
                  _buildHelpCard(
                    title: "Troubleshooting",
                    description: "Solutions for common problems",
                    icon: Icons.build,
                    onTap: () => _launchURL("https://www.hyperchat.com/troubleshooting"),
                  ),
                  _buildHelpCard(
                    title: "FAQ",
                    description: "Frequently asked questions",
                    icon: Icons.help_outline,
                    onTap: () => _launchURL("https://www.hyperchat.com/faq"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: "Contact Support",
                children: [
                  _buildHelpCard(
                    title: "Email Support",
                    description: "Get help via email",
                    icon: Icons.email_outlined,
                    onTap: () => _launchURL("mailto:support@hyperchat.com"),
                  ),
                  _buildHelpCard(
                    title: "Live Chat",
                    description: "Chat with our support team",
                    icon: Icons.chat_outlined,
                    onTap: () => _launchURL("https://www.hyperchat.com/chat"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: "Feedback",
                children: [
                  _buildHelpCard(
                    title: "Report a Bug",
                    description: "Help us improve the app",
                    icon: Icons.bug_report_outlined,
                    onTap: () => _launchURL("https://www.hyperchat.com/bug-report"),
                  ),
                  _buildHelpCard(
                    title: "Feature Request",
                    description: "Suggest new features",
                    icon: Icons.lightbulb_outline,
                    onTap: () => _launchURL("https://www.hyperchat.com/feature-request"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
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
        ...children,
      ],
    );
  }

  Widget _buildHelpCard({
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