import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../common/colo_extension.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7d';

  final List<Map<String, dynamic>> _readings = [
    {
      'date': '2024-03-20',
      'time': '08:30',
      'systolic': 132,
      'diastolic': 88,
      'heartRate': 78,
      'tag': 'Morning',
    },
    {
      'date': '2024-03-20',
      'time': '12:45',
      'systolic': 128,
      'diastolic': 85,
      'heartRate': 75,
      'tag': 'After lunch',
    },
    {
      'date': '2024-03-20',
      'time': '18:20',
      'systolic': 135,
      'diastolic': 90,
      'heartRate': 82,
      'tag': 'Evening',
    },
    // Add more sample data as needed
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      body: TabBarView(
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
          child: Padding(
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
                    spots: _readings.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['systolic'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: TColor.primaryColor1,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  // Diastolic Line
                  LineChartBarData(
                    spots: _readings.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['diastolic'].toDouble());
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
    
    return SingleChildScrollView(
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
          ..._readings.map((reading) => Container(
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
                        reading['date'],
                        style: TextStyle(
                          color: TColor.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        reading['time'],
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
                    '${reading['systolic']}/${reading['diastolic']}',
                    style: TextStyle(
                      color: TColor.textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    reading['heartRate'].toString(),
                    style: TextStyle(
                      color: TColor.textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    reading['tag'],
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