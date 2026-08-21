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
  final String experience;
  final String notes;
  final String photoUrl;

  const DogProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.ageText,
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
      experience: d['experience'] ?? '',
      notes: d['notes'] ?? '',
      photoUrl: d['photoUrl'] ?? '',
    );
  }
}
