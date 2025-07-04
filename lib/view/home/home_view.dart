import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../profile/profile_view.dart';
import '../../common/colo_extension.dart';
import '../../providers/user_provider.dart';
import '../../services/measurement_service.dart';
import '../../model/measurement.dart';
import '../../services/tip_service.dart';
import 'dart:async';
import '../../services/learning_service.dart';
import '../../model/learning_path.dart';
import '../learning/learning_path_view.dart';
import '../dialogs/set_reminder_dialog.dart';
import '../measure/measure_view.dart';

class HomeView extends StatefulWidget {
  final void Function()? onMeasureTabRequested;
  const HomeView({super.key, this.onMeasureTabRequested});

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
  final TipService _tipService = TipService();
  bool _isLoadingTip = false;
  final LearningService _learningService = LearningService();

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

    _measurementSubscription?.cancel(); // Cancel any existing subscription
    _measurementSubscription = _measurementService
        .getUserMeasurements(user.uid)
        .listen(
          (measurements) {
            if (mounted) {
              setState(() {
                // Ensure measurements are sorted by timestamp descending
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

  void _showDailyTip() async {
    setState(() {
      _isLoadingTip = true;
    });

    final tip = await _tipService.getDailyTip();

    if (!mounted) return;

    setState(() {
      _isLoadingTip = false;
    });

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: TColor.primaryColor1.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: TColor.primaryColor1,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Today's Tip",
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  foregroundColor: TColor.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Got it!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
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
                  showDialog(
                    context: context,
                    builder: (context) => const SetReminderDialog(),
                  );
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
                onTap: _showDailyTip,
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
    return Container(
      width: 160,
      height: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TColor.secondaryColor2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: TColor.primaryColor1, size: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: TColor.subTextColor,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildLearningPaths() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<LearningPath>>(
      stream: _learningService.getLearningPaths(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading learning paths',
              style: TextStyle(color: TColor.subTextColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // If no data in Firestore, use default learning paths
          final defaultPaths = _learningService.getDefaultLearningPaths();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Learning Paths',
                  style: TextStyle(
                    color: TColor.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ...defaultPaths.map(
                (path) => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: _buildCard(
                    backgroundColor: isDarkMode
                        ? TColor.darkSurface.withOpacity(0.1)
                        : Color(
                            int.parse(path.color.replaceAll('#', '0xFF')),
                          ).withOpacity(0.1),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LearningPathView(path: path),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              path.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    path.title,
                                    style: TextStyle(
                                      color: TColor.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${path.completedLessons}/${path.totalLessons} completed',
                                    style: TextStyle(
                                      color: TColor.subTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: path.progress,
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
                ),
              ),
            ],
          );
        }

        final paths = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Learning Paths',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 15),
            ...paths.map(
              (path) => Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: _buildCard(
                  backgroundColor: Color(
                    int.parse(path.color.replaceAll('#', '0xFF')),
                  ).withOpacity(0.1),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningPathView(path: path),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(path.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  path.title,
                                  style: TextStyle(
                                    color: TColor.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${path.completedLessons}/${path.totalLessons} completed',
                                  style: TextStyle(
                                    color: TColor.subTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: path.progress,
                                  backgroundColor: isDarkMode
                                      ? TColor.darkGray.withOpacity(0.5)
                                      : TColor.secondaryColor2.withOpacity(0.5),
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

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
                                    if (widget.onMeasureTabRequested != null) {
                                      widget.onMeasureTabRequested!();
                                    }
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
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Reading',
                      style: TextStyle(
                        color: TColor.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                                    ? CircularProgressIndicator(
                                        color: TColor.primaryColor1,
                                      )
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
                                          fontWeight: FontWeight.w900,
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
                                    ? CircularProgressIndicator(
                                        color: TColor.primaryColor1,
                                      )
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
                                        _latestMeasurement!.heartRate
                                            .toString(),
                                        style: TextStyle(
                                          color: TColor.textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
