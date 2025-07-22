import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final BasicInfo basicInfo;
  final HealthBackground healthBackground;
  final MeasurementContext measurementContext;
  final bool isAdmin;
  final bool dataSharingEnabled;
  final bool hasCompletedOnboarding;

  UserModel({
    required this.id,
    required this.basicInfo,
    required this.healthBackground,
    required this.measurementContext,
    this.isAdmin = false,
    this.dataSharingEnabled = false,
    this.hasCompletedOnboarding = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      basicInfo: BasicInfo.fromMap(data['basicInfo'] ?? {}),
      healthBackground: HealthBackground.fromMap(data['healthBackground'] ?? {}),
      measurementContext: MeasurementContext.fromMap(data['measurementContext'] ?? {}),
      isAdmin: data['isAdmin'] ?? false,
      dataSharingEnabled: data['dataSharingEnabled'] ?? false,
      hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basicInfo': basicInfo.toMap(),
      'healthBackground': healthBackground.toMap(),
      'measurementContext': measurementContext.toMap(),
      'isAdmin': isAdmin,
      'dataSharingEnabled': dataSharingEnabled,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  UserModel copyWith({
    String? id,
    BasicInfo? basicInfo,
    HealthBackground? healthBackground,
    MeasurementContext? measurementContext,
    bool? isAdmin,
    bool? dataSharingEnabled,
    bool? hasCompletedOnboarding,
  }) {
    return UserModel(
      id: id ?? this.id,
      basicInfo: basicInfo ?? this.basicInfo,
      healthBackground: healthBackground ?? this.healthBackground,
      measurementContext: measurementContext ?? this.measurementContext,
      isAdmin: isAdmin ?? this.isAdmin,
      dataSharingEnabled: dataSharingEnabled ?? this.dataSharingEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class BasicInfo {
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String email;
  final String? phoneNumber;
  final int age;
  final double weight;
  final double height;

  BasicInfo({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.email,
    this.phoneNumber,
    required this.age,
    required this.weight,
    required this.height,
  });

  factory BasicInfo.fromMap(Map<String, dynamic> map) {
    return BasicInfo(
      fullName: map['fullName'] ?? '',
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      gender: map['gender'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      age: map['age'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'email': email,
      'phoneNumber': phoneNumber,
      'age': age,
      'weight': weight,
      'height': height,
    };
  }

  BasicInfo copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? email,
    String? phoneNumber,
    int? age,
    double? weight,
    double? height,
  }) {
    return BasicInfo(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
    );
  }
}

class HealthBackground {
  final bool hasHypertension;
  final DateTime? diagnosisDate;
  final List<String> medications;
  final bool familyHistory;
  final List<String> conditions;
  final String smokingHabits;
  final String drinkingHabits;
  final String activityLevel;

  HealthBackground({
    required this.hasHypertension,
    this.diagnosisDate,
    required this.medications,
    required this.familyHistory,
    required this.conditions,
    required this.smokingHabits,
    required this.drinkingHabits,
    required this.activityLevel,
  });

  factory HealthBackground.fromMap(Map<String, dynamic> map) {
    return HealthBackground(
      hasHypertension: map['hasHypertension'] ?? false,
      diagnosisDate: map['diagnosisDate'] != null 
          ? (map['diagnosisDate'] as Timestamp).toDate() 
          : null,
      medications: List<String>.from(map['medications'] ?? []),
      familyHistory: map['familyHistory'] ?? false,
      conditions: List<String>.from(map['conditions'] ?? []),
      smokingHabits: map['smokingHabits'] ?? '',
      drinkingHabits: map['drinkingHabits'] ?? '',
      activityLevel: map['activityLevel'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasHypertension': hasHypertension,
      'diagnosisDate': diagnosisDate != null 
          ? Timestamp.fromDate(diagnosisDate!) 
          : null,
      'medications': medications,
      'familyHistory': familyHistory,
      'conditions': conditions,
      'smokingHabits': smokingHabits,
      'drinkingHabits': drinkingHabits,
      'activityLevel': activityLevel,
    };
  }

  HealthBackground copyWith({
    bool? hasHypertension,
    DateTime? diagnosisDate,
    List<String>? medications,
    bool? familyHistory,
    List<String>? conditions,
    String? smokingHabits,
    String? drinkingHabits,
    String? activityLevel,
  }) {
    return HealthBackground(
      hasHypertension: hasHypertension ?? this.hasHypertension,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      medications: medications ?? this.medications,
      familyHistory: familyHistory ?? this.familyHistory,
      conditions: conditions ?? this.conditions,
      smokingHabits: smokingHabits ?? this.smokingHabits,
      drinkingHabits: drinkingHabits ?? this.drinkingHabits,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}

class MeasurementContext {
  double? weight;
  double? height;
  bool? hasBPCuff;
  String? preferredHand;
  bool cameraPermission;
  bool flashlightPermission;

  MeasurementContext({
    this.weight,
    this.height,
    this.hasBPCuff,
    this.preferredHand,
    required this.cameraPermission,
    required this.flashlightPermission,
  });

  factory MeasurementContext.fromMap(Map<String, dynamic> map) {
    return MeasurementContext(
      weight: map['weight']?.toDouble(),
      height: map['height']?.toDouble(),
      hasBPCuff: map['hasBPCuff'],
      preferredHand: map['preferredHand'],
      cameraPermission: map['cameraPermission'] ?? false,
      flashlightPermission: map['flashlightPermission'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'height': height,
      'hasBPCuff': hasBPCuff,
      'preferredHand': preferredHand,
      'cameraPermission': cameraPermission,
      'flashlightPermission': flashlightPermission,
    };
  }

  MeasurementContext copyWith({
    double? weight,
    double? height,
    bool? hasBPCuff,
    String? preferredHand,
    bool? cameraPermission,
    bool? flashlightPermission,
  }) {
    return MeasurementContext(
      weight: weight ?? this.weight,
      height: height ?? this.height,
      hasBPCuff: hasBPCuff ?? this.hasBPCuff,
      preferredHand: preferredHand ?? this.preferredHand,
      cameraPermission: cameraPermission ?? this.cameraPermission,
      flashlightPermission: flashlightPermission ?? this.flashlightPermission,
    );
  }
} 