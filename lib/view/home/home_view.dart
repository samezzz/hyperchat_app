import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../profile/profile_view.dart';
import '../../common/colo_extension.dart';
import '../../providers/user_provider.dart';
import '../../services/measurement_service.dart';
import '../../model/measurement.dart';
import 'dart:async';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  final MeasurementService _measurementService = MeasurementService();
  Measurement? _latestMeasurement;
  bool _isLoadingMeasurement = true;
  StreamSubscription? _measurementSubscription;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _fetchLatestMeasurement();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _measurementSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).loadUser(user.uid);
    }
  }

  void _fetchLatestMeasurement() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingMeasurement = false;
      });
      return;
    }

    _measurementSubscription = _measurementService
        .getUserMeasurements(user.uid)
        .listen(
          (measurements) {
            if (mounted) {
              setState(() {
                // Ensure measurements are sorted by timestamp descending just in case the stream order is not guaranteed,
                // although MeasurementService already orders it this way.
                measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                _latestMeasurement = measurements.isNotEmpty
                    ? measurements.first
                    : null;
                _isLoadingMeasurement = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoadingMeasurement = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to fetch latest measurement: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
  }

  List<Map<String, dynamic>> _getLearningModules(BuildContext context) {
    return [
      {
        'icon': '🧂',
        'title': 'Sodium Myths',
        'description': 'Learn the truth about salt and blood pressure',
        'color': TColor.primaryColor2,
      },
      {
        'icon': '🧘',
        'title': 'Breathing Exercises',
        'description': 'Simple techniques to lower your BP naturally',
        'color': TColor.secondaryColor1,
      },
      {
        'icon': '📈',
        'title': 'Understanding Your BP Numbers',
        'description': 'What do your readings really mean?',
        'color': TColor.primaryColor2,
      },
    ];
  }

  List<Map<String, dynamic>> _getLearningPaths(BuildContext context) {
    return [
      {
        'title': 'Hypertension Basics',
        'progress': 15,
        'total': 15,
        'icon': '✅',
        'color': TColor.primaryColor2,
      },
      {
        'title': 'Medication Management',
        'progress': 4,
        'total': 10,
        'icon': '⏳',
        'color': TColor.secondaryColor1,
      },
      {
        'title': 'Healthy Eating for BP',
        'progress': 0,
        'total': 20,
        'icon': '📖',
        'color': TColor.primaryColor2,
      },
    ];
  }

  Widget _buildCard({required Widget child, Color? backgroundColor}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDarkMode
                ? TColor.darkSurface
                : TColor.secondaryColor2.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: TColor.subTextColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildQuickActionCard(
                icon: Icons.alarm,
                title: 'Set Reminder',
                subtitle: 'Add measurement or medication reminders',
                onTap: () {
                  // TODO: Implement reminder setting
                },
              ),
              _buildQuickActionCard(
                icon: Icons.track_changes,
                title: 'My BP Targets',
                subtitle: 'View and set your BP goals',
                onTap: () {
                  // TODO: Implement BP targets
                },
              ),
              _buildQuickActionCard(
                icon: Icons.lightbulb,
                title: "Today's Tip",
                subtitle: 'Daily hypertension tips and facts',
                onTap: () {
                  // TODO: Implement daily tips
                },
              ),
              _buildQuickActionCard(
                icon: Icons.assignment,
                title: 'Track Symptoms',
                subtitle: 'Log headaches, dizziness, etc.',
                onTap: () {
                  // TODO: Implement symptom tracking
                },
              ),
              _buildQuickActionCard(
                icon: Icons.fitness_center,
                title: 'Healthy Habits',
                subtitle: 'Daily wellness suggestions',
                onTap: () {
                  // TODO: Implement healthy habits
                },
              ),
              _buildQuickActionCard(
                icon: Icons.note_alt,
                title: 'My Logs',
                subtitle: 'Write notes and log readings',
                onTap: () {
                  // TODO: Implement personal logs
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? TColor.darkSurface
              : TColor.secondaryColor2.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: TColor.subTextColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColor.primaryColor1.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: TColor.primaryColor1, size: 24),
            ),
            const SizedBox(height: 12),
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
              subtitle,
              style: TextStyle(color: TColor.subTextColor, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourReadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Your Last Reading',
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingMeasurement
            ? Center(
                child: CircularProgressIndicator(color: TColor.primaryColor1),
              )
            : _latestMeasurement == null
            ? Center(
                child: Text(
                  'No measurements recorded yet.',
                  style: TextStyle(color: TColor.subTextColor, fontSize: 16),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildReadingCard(
                      title: 'Blood Pressure',
                      value:
                          '${_latestMeasurement!.systolicBP}/${_latestMeasurement!.diastolicBP}',
                      unit: 'mmHg',
                      icon: Icons.favorite,
                      color: TColor.primaryColor1,
                    ),
                    _buildReadingCard(
                      title: 'Heart Rate',
                      value: _latestMeasurement!.heartRate.toString(),
                      unit: 'bpm',
                      icon: Icons.favorite_border,
                      color: TColor.secondaryColor1,
                      isPulsating: true,
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildReadingCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    bool isPulsating = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return _buildCard(
      backgroundColor: color.withOpacity(0.1),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: TColor.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            isPulsating
                ? ScaleTransition(
                    scale: _heartAnimation,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            Text(
              unit,
              style: TextStyle(color: TColor.subTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    final learningModules = _getLearningModules(context);
    final learningPaths = _getLearningPaths(context);

    return Scaffold(
      backgroundColor: TColor.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: TColor.subTextColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.basicInfo.fullName ?? 'Loading...',
                          style: TextStyle(
                            color: TColor.textColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileView(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDarkMode
                            ? TColor.darkSurface
                            : TColor.secondaryColor2,
                        child: Icon(
                          Icons.person,
                          color: isDarkMode ? Colors.white : TColor.textColor,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: AnimatedBuilder(
                        animation: _heartAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _heartAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    TColor.primaryColor1.withAlpha(
                                      204,
                                    ), // 0.8 * 255
                                    TColor.primaryColor1,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: TColor.primaryColor1.withAlpha(
                                      77,
                                    ), // 0.3 * 255
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: IconButton(
                                  onPressed: () {
                                    // TODO: Navigate to measure view
                                  },
                                  icon: Icon(
                                    Icons.favorite,
                                    color: TColor.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Measure BP',
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        child: Column(
                          children: [
                            Text(
                              'Blood Pressure',
                              style: TextStyle(
                                color: TColor.subTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _isLoadingMeasurement
                                ? CircularProgressIndicator(color: TColor.primaryColor1)
                                : _latestMeasurement == null
                                    ? Text(
                                        'No data',
                                        style: TextStyle(
                                          color: TColor.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Text(
                                        '${_latestMeasurement!.systolicBP}/${_latestMeasurement!.diastolicBP}',
                                        style: TextStyle(
                                          color: TColor.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            Text(
                              'mmHg',
                              style: TextStyle(
                                color: TColor.primaryColor1,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildCard(
                        child: Column(
                          children: [
                            Text(
                              'Heart Rate',
                              style: TextStyle(
                                color: TColor.subTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _isLoadingMeasurement
                                ? CircularProgressIndicator(color: TColor.primaryColor1)
                                : _latestMeasurement == null
                                    ? Text(
                                        'No data',
                                        style: TextStyle(
                                          color: TColor.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Text(
                                        _latestMeasurement!.heartRate.toString(),
                                        style: TextStyle(
                                          color: TColor.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            Text(
                              'BPM',
                              style: TextStyle(
                                color: TColor.primaryColor1,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Learning Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn & Improve',
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: learningModules.length,
                        itemBuilder: (context, index) {
                          final module = learningModules[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 15),
                            child: _buildCard(
                              backgroundColor: isDarkMode
                                  ? TColor.darkSurface
                                  : module['color'] as Color,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module['icon'] as String,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    module['title'] as String,
                                    style: TextStyle(
                                      color: TColor.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    module['description'] as String,
                                    style: TextStyle(
                                      color: TColor.subTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Learning Paths
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learning Paths',
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...learningPaths.map(
                      (path) => Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: _buildCard(
                          backgroundColor: isDarkMode
                              ? TColor.darkSurface
                              : path['color'] as Color,
                          child: Row(
                            children: [
                              Text(
                                path['icon'] as String,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      path['title'] as String,
                                      style: TextStyle(
                                        color: TColor.textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${path['progress']}/${path['total']} completed',
                                      style: TextStyle(
                                        color: TColor.subTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    LinearProgressIndicator(
                                      value:
                                          (path['progress'] as int) /
                                          (path['total'] as int),
                                      backgroundColor: isDarkMode
                                          ? TColor.darkGray
                                          : TColor.secondaryColor2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        TColor.primaryColor1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
