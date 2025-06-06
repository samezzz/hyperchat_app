import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../model/measurement.dart';

class ExportService {
  Future<void> exportToCSV(List<Measurement> measurements) async {
    try {
      // Create CSV data
      List<List<dynamic>> csvData = [
        // Header row
        [
          'Date',
          'Time',
          'Systolic (mmHg)',
          'Diastolic (mmHg)',
          'Heart Rate (bpm)',
          'Context'
        ],
      ];

      // Add measurement data
      for (var measurement in measurements) {
        final date = DateFormat('yyyy-MM-dd').format(measurement.timestamp);
        final time = DateFormat('HH:mm:ss').format(measurement.timestamp);
        
        csvData.add([
          date,
          time,
          measurement.systolicBP,
          measurement.diastolicBP,
          measurement.heartRate,
          measurement.context,
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/blood_pressure_measurements.csv';
      
      // Write to file
      final File file = File(filePath);
      await file.writeAsString(csv);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Blood Pressure Measurements Export',
      );
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }
} 