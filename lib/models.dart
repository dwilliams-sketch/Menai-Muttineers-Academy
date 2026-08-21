import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String paymentStatus;
  final String paymentMethod;
  final bool activated;
  final String accessCodeHash;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final int loginStreak;
  final String lastLoginDay;
  final bool celebrationSound;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.activated,
    required this.accessCodeHash,
    required this.createdAt,
    required this.lastActiveAt,
    required this.loginStreak,
    required this.lastLoginDay,
    required this.celebrationSound,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? 'learner',
      paymentStatus: d['paymentStatus'] ?? 'unpaid',
      paymentMethod: d['paymentMethod'] ?? '',
      activated: d['activated'] ?? false,
      accessCodeHash: d['accessCodeHash'] ?? '',
      createdAt: dateFrom(d['createdAt']),
      lastActiveAt: dateFrom(d['lastActiveAt']),
      loginStreak: (d['loginStreak'] as num?)?.toInt() ?? 0,
      lastLoginDay: d['lastLoginDay'] ?? '',
      celebrationSound: d['celebrationSound'] != false,
    );
  }

  bool get isStaff => role == 'admin' || role == 'trainer';
  bool get isAdmin => role == 'admin';
  bool get isPaid => paymentStatus == 'paid' || paymentStatus == 'complimentary';
}

class DogProfile {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final String ageText;
  final String dateOfBirth;
  final bool dobEstimated;
  final String experience;
  final String notes;
  final String photoUrl;

  const DogProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.ageText,
    required this.dateOfBirth,
    required this.dobEstimated,
    required this.experience,
    required this.notes,
    required this.photoUrl,
  });

  factory DogProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DogProfile(
      id: doc.id,
      ownerId: d['ownerId'] ?? '',
      name: d['name'] ?? '',
      breed: d['breed'] ?? '',
      ageText: d['ageText'] ?? '',
      dateOfBirth: d['dateOfBirth'] ?? '',
      dobEstimated: d['dobEstimated'] == true,
      experience: d['experience'] ?? '',
      notes: d['notes'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
    );
  }
}
