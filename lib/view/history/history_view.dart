import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../common/colo_extension.dart';
import '../../services/measurement_service.dart';
import '../../model/measurement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7d';
  final MeasurementService _measurementService = MeasurementService();
  List<Measurement> _measurements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Listen to measurements stream
      _measurementService.getUserMeasurements(user.uid).listen((measurements) {
        if (mounted) {
          setState(() {
            _measurements = measurements;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load measurements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Measurement> _getFilteredMeasurements() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case '24h':
        return _measurements.where((m) => 
          m.timestamp.isAfter(now.subtract(const Duration(hours: 24)))
        ).toList();
      case '7d':
        return _measurements.where((m) => 
          m.timestamp.isAfter(now.subtract(const Duration(days: 7)))
        ).toList();
      case '30d':
        return _measurements.where((m) => 
          m.timestamp.isAfter(now.subtract(const Duration(days: 30)))
        ).toList();
      case 'All':
      default:
        return _measurements;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(
          'History & Trends',
          style: TextStyle(
            color: TColor.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: TColor.primaryColor1,
          unselectedLabelColor: TColor.subTextColor,
          indicatorColor: TColor.primaryColor1,
          tabs: const [
            Tab(text: '📊 Trends'),
            Tab(text: '📄 Table'),
            Tab(text: '📤 Export'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendsTab(),
                _buildTableTab(),
                _buildExportTab(),
              ],
            ),
    );
  }

  Widget _buildTrendsTab() {
    final filteredMeasurements = _getFilteredMeasurements();
    
    return Column(
      children: [
        // Time Range Selector
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeRangeButton('24h'),
              _buildTimeRangeButton('7d'),
              _buildTimeRangeButton('30d'),
              _buildTimeRangeButton('All'),
            ],
          ),
        ),
        // Chart
        Expanded(
          child: filteredMeasurements.isEmpty
              ? Center(
                  child: Text(
                    'No measurements available for selected time range',
                    style: TextStyle(
                      color: TColor.subTextColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: TColor.subTextColor.withAlpha(51),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: TColor.subTextColor.withAlpha(51),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: TColor.textColor,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: TColor.textColor,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: TColor.subTextColor.withAlpha(51),
                        ),
                      ),
                      lineBarsData: [
                        // Systolic Line
                        LineChartBarData(
                          spots: filteredMeasurements.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.systolicBP.toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: TColor.primaryColor1,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                        // Diastolic Line
                        LineChartBarData(
                          spots: filteredMeasurements.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.diastolicBP.toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: TColor.secondaryColor1,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTableTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredMeasurements = _getFilteredMeasurements();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');
    
    return filteredMeasurements.isEmpty
        ? Center(
            child: Text(
              'No measurements available for selected time range',
              style: TextStyle(
                color: TColor.subTextColor,
                fontSize: 16,
              ),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? TColor.darkSurface : TColor.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.black.withAlpha(13),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date & Time',
                          style: TextStyle(
                            color: TColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'BP',
                          style: TextStyle(
                            color: TColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'HR',
                          style: TextStyle(
                            color: TColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Tag',
                          style: TextStyle(
                            color: TColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Table Rows
                ...filteredMeasurements.map((measurement) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? TColor.darkSurface : TColor.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.black.withAlpha(13),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(measurement.timestamp),
                              style: TextStyle(
                                color: TColor.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              timeFormat.format(measurement.timestamp),
                              style: TextStyle(
                                color: TColor.subTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${measurement.systolicBP}/${measurement.diastolicBP}',
                          style: TextStyle(
                            color: TColor.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          measurement.heartRate.toString(),
                          style: TextStyle(
                            color: TColor.textColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          measurement.context,
                          style: TextStyle(
                            color: TColor.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          );
  }

  Widget _buildExportTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.file_download,
            size: 64,
            color: TColor.primaryColor1,
          ),
          const SizedBox(height: 16),
          Text(
            'Export your data',
            style: TextStyle(
              color: TColor.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download your blood pressure history in CSV format',
            style: TextStyle(
              color: TColor.subTextColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement export functionality
            },
            icon: const Icon(Icons.download),
            label: const Text('Export Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primaryColor1,
              foregroundColor: TColor.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String range) {
    final isSelected = _selectedTimeRange == range;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedTimeRange = range;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? TColor.primaryColor1
              : (isDarkMode ? TColor.darkSurface : TColor.white),
          foregroundColor: isSelected
              ? TColor.white
              : TColor.textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? TColor.primaryColor1
                  : TColor.subTextColor.withAlpha(77),
            ),
          ),
        ),
        child: Text(range),
      ),
    );
  }
} 