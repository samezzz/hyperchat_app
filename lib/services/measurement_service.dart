import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/measurement.dart';
import 'gemini_service.dart';
import '../models/user_model.dart';

class MeasurementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'measurements';
  final GeminiService geminiService = GeminiService();

  // Add a new measurement
  Future<String> addMeasurement({
    required String userId,
    required int heartRate,
    required int systolicBP,
    required int diastolicBP,
    required String context,
    required HealthBackground healthBackground,
  }) async {
    try {
      // Get AI analysis of the measurement
      final analysis = await geminiService.analyzeMeasurement(
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        heartRate: heartRate,
        context: context,
        healthBackground: healthBackground,
      );

      // Add measurement with AI analysis
      DocumentReference docRef = await _firestore.collection(_collection).add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'heartRate': heartRate,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'context': context,
        'aiAnalysis': analysis,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add measurement: $e');
    }
  }

  // Get all measurements for a user
  Stream<List<Measurement>> getUserMeasurements(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Measurement.fromFirestore(doc)).toList();
    });
  }

  // Delete a measurement
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _firestore.collection(_collection).doc(measurementId).delete();
    } catch (e) {
      throw Exception('Failed to delete measurement: $e');
    }
  }

  // Update a measurement
  Future<void> updateMeasurement({
    required String measurementId,
    required int heartRate,
    required int systolicBP,
    required int diastolicBP,
    required String context,
  }) async {
    try {
      await _firestore.collection(_collection).doc(measurementId).update({
        'heartRate': heartRate,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'context': context,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update measurement: $e');
    }
  }
} 