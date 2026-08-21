import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../course_data.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String hashAccessCode(String value) => sha256.convert(utf8.encode(value.trim().toUpperCase())).toString();

  String generateAccessCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) => db.collection('users').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> dogsForOwner(String uid) => db.collection('dogs').where('ownerId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allUsers() => db.collection('users').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allDogs() => db.collection('dogs').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> notices() => db.collection('notices').where('active', isEqualTo: true).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> settings() => db.collection('settings').doc('course').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> moduleSettings(String id) => db.collection('courseModules').doc(id).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> submissionsForUser(String uid) => db.collection('submissions').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allSubmissions() => db.collection('submissions').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> questionsForUser(String uid) => db.collection('questions').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allQuestions() => db.collection('questions').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trainingLogsForUser(String uid) => db.collection('trainingLogs').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> oneToOnesForUser(String uid) => db.collection('oneToOneRequests').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allOneToOnes() => db.collection('oneToOneRequests').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trophiesForDog(String dogId) => db.collection('dogs').doc(dogId).collection('trophies').snapshots();

  Future<void> createLearner({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String dogName,
    required String breed,
    required String ageText,
    required String experience,
    required String notes,
  }) async {
    final batch = db.batch();
    final userRef = db.collection('users').doc(uid);
    final dogRef = db.collection('dogs').doc();
    batch.set(userRef, {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'role': 'learner',
      'paymentStatus': 'unpaid',
      'paymentMethod': '',
      'activated': false,
      'accessCodeHash': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    batch.set(dogRef, {
      'ownerId': uid,
      'name': dogName.trim(),
      'breed': breed.trim(),
      'ageText': ageText.trim(),
      'experience': experience.trim(),
      'notes': notes.trim(),
      'photoUrl': '',
    });
    await batch.commit();
  }

  Future<void> touch(String uid) => db.collection('users').doc(uid).update({'lastActiveAt': FieldValue.serverTimestamp()});

  Future<void> activate(String uid) => db.collection('users').doc(uid).update({
        'activated': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

  Future<String> markPaid(String uid, {String method = 'Manual'}) async {
    final code = generateAccessCode();
    await db.collection('users').doc(uid).update({
      'paymentStatus': 'paid',
      'paymentMethod': method,
      'activated': false,
      'accessCodeHash': hashAccessCode(code),
    });
    return code;
  }

  Future<String> regenerateCode(String uid) async {
    final code = generateAccessCode();
    await db.collection('users').doc(uid).update({
      'activated': false,
      'accessCodeHash': hashAccessCode(code),
    });
    return code;
  }

  Future<void> markComplimentary(String uid) async {
    await db.collection('users').doc(uid).update({
      'paymentStatus': 'complimentary',
      'paymentMethod': 'Complimentary',
      'activated': true,
      'accessCodeHash': '',
    });
  }

  Future<void> markUnpaid(String uid) async {
    await db.collection('users').doc(uid).update({
      'paymentStatus': 'unpaid',
      'paymentMethod': '',
      'activated': false,
      'accessCodeHash': '',
    });
  }

  Future<void> updateDog(String dogId, Map<String, dynamic> values) => db.collection('dogs').doc(dogId).update(values);

  Future<void> submitVideo({
    required String uid,
    required String dogId,
    required CourseModule module,
    required String videoUrl,
    required String note,
    required String learnerName,
    required String dogName,
  }) async {
    await db.collection('submissions').add({
      'userId': uid,
      'dogId': dogId,
      'learnerName': learnerName,
      'dogName': dogName,
      'moduleId': module.id,
      'moduleTitle': module.title,
      'trophyTitle': module.trophyTitle,
      'videoUrl': videoUrl.trim(),
      'note': note.trim(),
      'status': 'waiting',
      'feedback': '',
      'reviewerName': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
    });
  }

  Future<void> reviewSubmission({
    required String submissionId,
    required String dogId,
    required String moduleId,
    required String trophyTitle,
    required String moduleTitle,
    required String reviewerName,
    required String feedback,
    required bool passed,
  }) async {
    final batch = db.batch();
    final submission = db.collection('submissions').doc(submissionId);
    batch.update(submission, {
      'status': passed ? 'passed' : 'practise',
      'feedback': feedback.trim(),
      'reviewerName': reviewerName,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (passed) {
      final trophy = db.collection('dogs').doc(dogId).collection('trophies').doc(moduleId);
      batch.set(trophy, {
        'dogId': dogId,
        'moduleId': moduleId,
        'title': trophyTitle,
        'description': 'Trainer verified: $moduleTitle',
        'reviewerName': reviewerName,
        'awardedAt': FieldValue.serverTimestamp(),
        'submissionId': submissionId,
      });
    }
    await batch.commit();
  }

  Future<void> addTrainingLog({
    required String uid,
    required String dogId,
    required String skill,
    required String result,
    required String note,
  }) => db.collection('trainingLogs').add({
        'userId': uid,
        'dogId': dogId,
        'skill': skill,
        'result': result,
        'note': note.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> askTrainer({
    required String uid,
    required String dogId,
    required String learnerName,
    required String dogName,
    required String category,
    required String question,
    required String videoUrl,
  }) => db.collection('questions').add({
        'userId': uid,
        'dogId': dogId,
        'learnerName': learnerName,
        'dogName': dogName,
        'category': category,
        'question': question.trim(),
        'videoUrl': videoUrl.trim(),
        'status': 'open',
        'answer': '',
        'trainerName': '',
        'createdAt': FieldValue.serverTimestamp(),
        'answeredAt': null,
      });

  Future<void> answerQuestion(String id, String answer, String trainerName) => db.collection('questions').doc(id).update({
        'answer': answer.trim(),
        'trainerName': trainerName,
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });

  Future<void> requestOneToOne({
    required String uid,
    required String dogId,
    required String learnerName,
    required String dogName,
    required String topic,
    required String preferredTrainer,
    required String format,
    required String availability,
    required String note,
  }) => db.collection('oneToOneRequests').add({
        'userId': uid,
        'dogId': dogId,
        'learnerName': learnerName,
        'dogName': dogName,
        'topic': topic,
        'preferredTrainer': preferredTrainer,
        'format': format,
        'availability': availability,
        'note': note.trim(),
        'status': 'requested',
        'trainerName': '',
        'proposedWhen': '',
        'meetUrl': '',
        'trainerNotes': '',
        'homework': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> learnerAcceptOneToOne(String id) => db.collection('oneToOneRequests').doc(id).update({
        'status': 'booked',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> learnerCancelOneToOne(String id) => db.collection('oneToOneRequests').doc(id).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> staffUpdateOneToOne({
    required String id,
    required String status,
    required String trainerName,
    required String proposedWhen,
    required String meetUrl,
    required String trainerNotes,
    required String homework,
  }) => db.collection('oneToOneRequests').doc(id).update({
        'status': status,
        'trainerName': trainerName.trim(),
        'proposedWhen': proposedWhen.trim(),
        'meetUrl': meetUrl.trim(),
        'trainerNotes': trainerNotes.trim(),
        'homework': homework.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> saveCourseSettings({
    required String welcome,
    required String meetWhen,
    required String meetTopic,
    required String meetUrl,
  }) => db.collection('settings').doc('course').set({
        'welcomeMessage': welcome.trim(),
        'meetWhen': meetWhen.trim(),
        'meetTopic': meetTopic.trim(),
        'meetUrl': meetUrl.trim(),
      }, SetOptions(merge: true));

  Future<void> saveModuleVideo(String moduleId, String videoUrl) => db.collection('courseModules').doc(moduleId).set({
        'videoUrl': videoUrl.trim(),
      }, SetOptions(merge: true));

  Future<void> addNotice(String title, String message, String priority) => db.collection('notices').add({
        'title': title.trim(),
        'message': message.trim(),
        'priority': priority,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> removeNotice(String id) => db.collection('notices').doc(id).update({'active': false});
}
