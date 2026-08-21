import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../course_data.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String hashAccessCode(String value) => sha256.convert(utf8.encode(value.trim().toUpperCase())).toString();

  String generateAccessCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String _dayKey(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) => db.collection('users').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> dogsForOwner(String uid) => db.collection('dogs').where('ownerId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allUsers() => db.collection('users').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allDogs() => db.collection('dogs').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> notices() => db.collection('notices').where('active', isEqualTo: true).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> settings() => db.collection('settings').doc('course').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> moduleSettings(String id) => db.collection('courseModules').doc(id).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> skillProgress(String dogId, String moduleId) => db.collection('dogs').doc(dogId).collection('skillProgress').doc(moduleId).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> submissionsForUser(String uid) => db.collection('submissions').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allSubmissions() => db.collection('submissions').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> questionsForUser(String uid) => db.collection('questions').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allQuestions() => db.collection('questions').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trainingLogsForUser(String uid) => db.collection('trainingLogs').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> oneToOnesForUser(String uid) => db.collection('oneToOneRequests').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allOneToOnes() => db.collection('oneToOneRequests').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trophiesForDog(String dogId) => db.collection('dogs').doc(dogId).collection('trophies').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allMerchInterest() => db.collection('merchInterest').snapshots();

  Future<void> createLearner({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String dogName,
    required String breed,
    required String ageText,
    required String dateOfBirth,
    required bool dobEstimated,
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
      'loginStreak': 0,
      'lastLoginDay': '',
      'celebrationSound': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    batch.set(dogRef, {
      'ownerId': uid,
      'name': dogName.trim(),
      'breed': breed.trim(),
      'ageText': ageText.trim(),
      'dateOfBirth': dateOfBirth.trim(),
      'dobEstimated': dobEstimated,
      'experience': experience.trim(),
      'notes': notes.trim(),
      'photoUrl': '',
    });
    await batch.commit();
  }

  Future<void> touch(String uid) => db.collection('users').doc(uid).update({'lastActiveAt': FieldValue.serverTimestamp()});

  Future<void> recordDailyLoginAndAwards({
    required String uid,
    required String dogId,
    required String dogName,
    required String dateOfBirth,
  }) async {
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    final userRef = db.collection('users').doc(uid);

    final streak = await db.runTransaction<int>((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final previousDay = (data['lastLoginDay'] ?? '').toString();
      final previousStreak = (data['loginStreak'] as num?)?.toInt() ?? 0;
      int nextStreak = previousStreak;
      if (previousDay != today) {
        nextStreak = previousDay == yesterday ? previousStreak + 1 : 1;
        tx.update(userRef, {
          'lastLoginDay': today,
          'loginStreak': nextStreak,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
      return nextStreak;
    });

    await _ensureAutomaticTrophy(
      dogId: dogId,
      id: 'first_login',
      title: 'First Steps Aboard',
      description: '$dogName logged into the Academy for the first time.',
      artKey: 'login',
    );
    if (streak >= 7) {
      await _ensureAutomaticTrophy(dogId: dogId, id: 'streak_7', title: 'Seven Days Aboard', description: 'A 7-day Academy login streak.', artKey: 'streak7');
    }
    if (streak >= 14) {
      await _ensureAutomaticTrophy(dogId: dogId, id: 'streak_14', title: 'Sea Legs Streak', description: 'A 14-day Academy login streak.', artKey: 'streak14');
    }
    if (streak >= 30) {
      await _ensureAutomaticTrophy(dogId: dogId, id: 'streak_30', title: 'Month on Deck', description: 'A 30-day Academy login streak.', artKey: 'streak30');
    }

    if (dateOfBirth.trim().isNotEmpty) {
      final dob = DateTime.tryParse(dateOfBirth.trim());
      if (dob != null && dob.month == now.month && dob.day == now.day) {
        await _ensureAutomaticTrophy(
          dogId: dogId,
          id: 'birthday_${now.year}',
          title: 'Birthday Buccaneer',
          description: 'Happy birthday, $dogName! A special trophy from the Academy crew.',
          artKey: 'birthday',
        );
      }
    }
  }

  Future<void> _ensureAutomaticTrophy({
    required String dogId,
    required String id,
    required String title,
    required String description,
    required String artKey,
  }) async {
    final ref = db.collection('dogs').doc(dogId).collection('trophies').doc(id);
    final current = await ref.get();
    if (current.exists) return;
    await ref.set({
      'dogId': dogId,
      'title': title,
      'description': description,
      'reviewerName': 'Menai Muttineers Academy',
      'type': id.startsWith('birthday_') ? 'special' : 'milestone',
      'artKey': artKey,
      'automatic': true,
      'accepted': false,
      'awardedAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
    });
  }

  Future<void> acceptTrophy(String dogId, String trophyId) => db.collection('dogs').doc(dogId).collection('trophies').doc(trophyId).update({
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateCelebrationSound(String uid, bool enabled) => db.collection('users').doc(uid).update({'celebrationSound': enabled});

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

  Future<void> setUserRole(String uid, String role) => db.collection('users').doc(uid).update({'role': role});

  Future<void> updateDog(String dogId, Map<String, dynamic> values) => db.collection('dogs').doc(dogId).update(values);

  Future<void> setLessonStatus({
    required String dogId,
    required String moduleId,
    required String lessonId,
    required String status,
  }) async {
    await db.collection('dogs').doc(dogId).collection('skillProgress').doc(moduleId).set({
      'dogId': dogId,
      'moduleId': moduleId,
      'lessons': {lessonId: status},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (status == 'practised' || status == 'confident') {
      await _ensureAutomaticTrophy(
        dogId: dogId,
        id: 'first_lesson',
        title: 'First Lesson Logged',
        description: 'The first Academy lesson was watched and practised.',
        artKey: 'lesson',
      );
    }
  }

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
      'artKey': module.artKey,
      'videoUrl': videoUrl.trim(),
      'note': note.trim(),
      'status': 'waiting',
      'feedback': '',
      'reviewerName': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
    });
    await _ensureAutomaticTrophy(
      dogId: dogId,
      id: 'first_assessment',
      title: 'Brave Enough to Be Judged',
      description: 'The first Academy skill assessment was submitted.',
      artKey: 'assessment',
    );
  }

  Future<void> reviewSubmission({
    required String submissionId,
    required String dogId,
    required String moduleId,
    required String trophyTitle,
    required String moduleTitle,
    required String artKey,
    required String reviewerName,
    required String feedback,
    required bool passed,
  }) async {
    final firstSkillRef = db.collection('dogs').doc(dogId).collection('trophies').doc('first_skill');
    final firstSkillExists = (await firstSkillRef.get()).exists;
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
        'type': 'skill',
        'artKey': artKey,
        'automatic': false,
        'accepted': false,
        'awardedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'submissionId': submissionId,
      });
      if (!firstSkillExists) {
        batch.set(firstSkillRef, {
          'dogId': dogId,
          'title': 'First Skill Mastered',
          'description': 'The first trainer-verified Academy skill was passed.',
          'reviewerName': reviewerName,
          'type': 'milestone',
          'artKey': 'firstskill',
          'automatic': false,
          'accepted': false,
          'awardedAt': FieldValue.serverTimestamp(),
          'acceptedAt': null,
        });
      }
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

  Future<void> saveLessonVideo(String moduleId, String lessonId, String videoUrl) => db.collection('courseModules').doc(moduleId).set({
        'lessonVideos': {lessonId: videoUrl.trim()},
      }, SetOptions(merge: true));

  Future<void> addNotice(String title, String message, String priority) => db.collection('notices').add({
        'title': title.trim(),
        'message': message.trim(),
        'priority': priority,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> removeNotice(String id) => db.collection('notices').doc(id).update({'active': false});

  Future<void> registerMerchInterest({
    required String uid,
    required String name,
    required List<String> items,
  }) => db.collection('merchInterest').doc(uid).set({
        'userId': uid,
        'name': name,
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
