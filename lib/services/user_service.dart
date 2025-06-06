import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or update user data
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update basic info
  Future<void> updateBasicInfo(String userId, BasicInfo basicInfo) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'basicInfo': basicInfo.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update basic info: $e');
    }
  }

  // Update health background
  Future<void> updateHealthBackground(String userId, HealthBackground healthBackground) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'healthBackground': healthBackground.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update health background: $e');
    }
  }

  // Update measurement context
  Future<void> updateMeasurementContext(String userId, MeasurementContext measurementContext) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'measurementContext': measurementContext.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update measurement context: $e');
    }
  }

  // Delete user data
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
} 