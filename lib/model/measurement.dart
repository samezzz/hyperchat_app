import 'package:cloud_firestore/cloud_firestore.dart';

class Measurement {
  final String id;
  final String userId;
  final DateTime timestamp;
  final int heartRate;
  final int systolicBP;
  final int diastolicBP;
  final String context;

  Measurement({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.heartRate,
    required this.systolicBP,
    required this.diastolicBP,
    required this.context,
  });

  // Create a Measurement from a Firestore document
  factory Measurement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Measurement(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      heartRate: data['heartRate'] ?? 0,
      systolicBP: data['systolicBP'] ?? 0,
      diastolicBP: data['diastolicBP'] ?? 0,
      context: data['context'] ?? 'At rest',
    );
  }

  // Convert a Measurement to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'heartRate': heartRate,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'context': context,
    };
  }
} 