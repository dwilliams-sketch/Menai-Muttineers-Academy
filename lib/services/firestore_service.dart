import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../course_data.dart';
import '../i18n.dart';
import '../models.dart';
import 'celebration_service.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String hashAccessCode(String value) =>
      sha256.convert(utf8.encode(value.trim().toUpperCase())).toString();

  String generateAccessCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String initials(String name) {
    final bits = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (bits.isEmpty) return 'XX';
    if (bits.length == 1)
      return bits.first.substring(0, min(2, bits.first.length)).toUpperCase();
    return '${bits.first[0]}${bits.last[0]}'.toUpperCase();
  }

  String paymentReference({
    required String dogName,
    required String memberName,
    String suffix = '007',
  }) {
    final cleaned = dogName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final cleanSuffix = suffix.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    return '${cleaned.isEmpty ? 'DOG' : cleaned}-${initials(memberName)}-${cleanSuffix.isEmpty ? '007' : cleanSuffix}';
  }

  Future<AcademyConfig> getAcademyConfig() async {
    try {
      final snap = await db.collection('settings').doc('academy').get();
      return AcademyConfig.fromMap(snap.data() ?? {});
    } catch (_) {
      return AcademyConfig.fromMap(const {});
    }
  }

  // Streams
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) =>
      db.collection('users').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> dogsForOwner(String uid) =>
      db.collection('dogs').where('ownerId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allUsers() =>
      db.collection('users').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allDogs() =>
      db.collection('dogs').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> notices() =>
      db.collection('notices').where('active', isEqualTo: true).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> settings() =>
      db.collection('settings').doc('course').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> academySettings() =>
      db.collection('settings').doc('academy').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> linkSettings() =>
      db.collection('settings').doc('links').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> featureSettings() =>
      db.collection('settings').doc('features').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> moduleSettings(String id) =>
      db.collection('courseModules').doc(id).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> skillProgress(
    String dogId,
    String moduleId,
  ) => db
      .collection('dogs')
      .doc(dogId)
      .collection('skillProgress')
      .doc(moduleId)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> submissionsForUser(String uid) =>
      db.collection('submissions').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allSubmissions() =>
      db.collection('submissions').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trainingLogsForUser(String uid) =>
      db.collection('trainingLogs').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trainingLogsForDog(
    String dogId,
  ) => db
      .collection('trainingLogs')
      .where('dogId', isEqualTo: dogId)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> oneToOnesForUser(String uid) => db
      .collection('oneToOneRequests')
      .where('userId', isEqualTo: uid)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allOneToOnes() =>
      db.collection('oneToOneRequests').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> trophiesForDog(String dogId) =>
      db.collection('dogs').doc(dogId).collection('trophies').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> handlerTrophies(String uid) =>
      db.collection('users').doc(uid).collection('handlerTrophies').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allMerchInterest() =>
      db.collection('merchInterest').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> notificationsForUser(
    String uid,
  ) => db
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> lessonHelpForUser(String uid) =>
      db.collection('lessonHelp').where('userId', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allLessonHelp() =>
      db.collection('lessonHelp').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> helpMessages(String threadId) =>
      db
          .collection('lessonHelp')
          .doc(threadId)
          .collection('messages')
          .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> paymentRequestsForUser(
    String uid,
  ) => db
      .collection('paymentRequests')
      .where('userId', isEqualTo: uid)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allPaymentRequests() =>
      db.collection('paymentRequests').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> ledgerForUser(String uid) =>
      db.collection('users').doc(uid).collection('ledger').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allRestartRequests() =>
      db.collection('restartRequests').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> crewProfiles() => db
      .collection('crewProfiles')
      .where('discoverable', isEqualTo: true)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> crewRequestsForUser(String uid) =>
      db.collection('crewRequests').where('toUid', isEqualTo: uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> crewLinksForUser(String uid) => db
      .collection('crewLinks')
      .where('members', arrayContains: uid)
      .snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> crewAchievements() =>
      db.collection('crewAchievements').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> kudosForAchievement(
    String achievementId,
  ) => db
      .collection('kudos')
      .where('achievementId', isEqualTo: achievementId)
      .snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> lightStats(String uid) =>
      db.collection('lightStats').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> musicTracks() =>
      db.collection('musicTracks').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> calendarEvents() =>
      db.collection('calendarEvents').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> feedback() =>
      db.collection('feedback').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> auditLog() =>
      db.collection('auditLog').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> staffNotesForDog(String dogId) =>
      db.collection('staffNotes').where('dogId', isEqualTo: dogId).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> captainLog() =>
      db.collection('captainLog').snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> accountDeletionRequest(
    String uid,
  ) => db.collection('accountDeletionRequests').doc(uid).snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> allAccountDeletionRequests() =>
      db.collection('accountDeletionRequests').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> savedReplies() =>
      db.collection('savedReplies').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> staffTasks() =>
      db.collection('staffTasks').snapshots();

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
    String languageCode = 'en',
  }) async {
    final batch = db.batch();
    final userRef = db.collection('users').doc(uid);
    final dogRef = db.collection('dogs').doc();
    batch.set(userRef, {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'languageCode': languageCode == 'cy' ? 'cy' : 'en',
      'role': 'learner',
      'paymentStatus': 'unpaid',
      'paymentMethod': '',
      'activated': false,
      'accessCodeHash': '',
      'academyCredit': 0.0,
      'loginStreak': 0,
      'lastLoginDay': '',
      'celebrationSound': true,
      'pirateBackgrounds': true,
      'backgroundMode': 'rotate',
      'backgroundChoice': 'cove',
      'musicEnabled': false,
      'musicVolume': 0.22,
      'reducedMotion': false,
      'timerSound': 'parrot',
      'discoverable': false,
      'shareAchievements': true,
      'pushEnabled': true,
      'photoUploadsEnabled': false,
      'photoUrl': '',
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
      'registered': true,
      'academyStatus': 'awaiting',
      'pauseRequested': false,
      'accessUntil': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('crewProfiles').doc(uid), {
      'uid': uid,
      'displayName': name.trim(),
      'primaryDogName': dogName.trim(),
      'photoUrl': '',
      'dogPhotoUrl': '',
      'discoverable': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> addDog({
    required String uid,
    required String name,
    required String breed,
    required String dateOfBirth,
    required bool dobEstimated,
  }) => db.collection('dogs').add({
    'ownerId': uid,
    'name': name.trim(),
    'breed': breed.trim(),
    'ageText': '',
    'dateOfBirth': dateOfBirth.trim(),
    'dobEstimated': dobEstimated,
    'experience': '',
    'notes': '',
    'photoUrl': '',
    'registered': true,
    'academyStatus': 'awaiting',
    'pauseRequested': false,
    'accessUntil': null,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> touch(String uid) => db.collection('users').doc(uid).update({
    'lastActiveAt': FieldValue.serverTimestamp(),
  });

  Future<void> activate(String uid) async {
    final dogs = await db
        .collection('dogs')
        .where('ownerId', isEqualTo: uid)
        .get();
    final batch = db.batch();
    batch.update(db.collection('users').doc(uid), {
      'activated': true,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    if (dogs.docs.isNotEmpty) {
      final first = dogs.docs.first;
      final d = first.data();
      if ((d['academyStatus'] ?? '').toString() != 'active') {
        batch.update(first.reference, {
          'academyStatus': 'active',
          'activatedAt': FieldValue.serverTimestamp(),
          'accessUntil': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: academyDoubloonAccessDays)),
          ),
          'pauseRequested': false,
        });
      }
    }
    await batch.commit();
  }

  Future<String> markPaid(String uid, {String method = 'Manual'}) async {
    final code = generateAccessCode();
    await db.collection('users').doc(uid).update({
      'paymentStatus': 'paid',
      'paymentMethod': method,
      'accessCodeHash': hashAccessCode(code),
    });
    await _audit(
      'Initial payment confirmed',
      uid,
      'Access code issued',
      'system',
    );
    return code;
  }

  Future<String> regenerateCode(String uid) async {
    final code = generateAccessCode();
    await db.collection('users').doc(uid).update({
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

  Future<void> setUserRole(String uid, String role, {String actor = ''}) async {
    await db.collection('users').doc(uid).update({'role': role});
    await _audit('Role changed', uid, role, actor);
  }

  Future<void> updateUserPreferences(String uid, Map<String, dynamic> values) =>
      db.collection('users').doc(uid).update(values);
  Future<void> updateDog(String dogId, Map<String, dynamic> values) =>
      db.collection('dogs').doc(dogId).update(values);

  Future<void> updateCrewProfile({
    required AppUser user,
    required DogProfile dog,
  }) async {
    await db.collection('crewProfiles').doc(user.id).set({
      'uid': user.id,
      'displayName': user.name,
      'primaryDogName': dog.name,
      'photoUrl': user.photoUrl,
      'dogPhotoUrl': dog.photoUrl,
      'discoverable': user.discoverable,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Notifications and automatic celebration messages
  Future<void> notifyUser({
    required String uid,
    required String title,
    required String body,
    String type = 'general',
    String targetId = '',
    String? stableId,
  }) async {
    final ref = stableId == null
        ? db.collection('notifications').doc()
        : db.collection('notifications').doc(stableId);
    if (stableId != null && (await ref.get()).exists) return;
    await ref.set({
      'userId': uid,
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> notifyStaff({
    required String title,
    required String body,
    String type = 'staff',
    String targetId = '',
  }) async {
    final users = await db.collection('users').get();
    for (final user in users.docs) {
      final role = (user.data()['role'] ?? 'learner').toString();
      if (role == 'trainer' || role == 'admin' || role == 'captain') {
        await notifyUser(
          uid: user.id,
          title: title,
          body: body,
          type: type,
          targetId: targetId,
        );
      }
    }
  }

  Future<void> markNotificationRead(String id) =>
      db.collection('notifications').doc(id).update({'read': true});

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .get();
    final batch = db.batch();
    for (final d in snap.docs) {
      if (d.data()['read'] != true) batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> ensureDailyCelebrations({
    required AppUser user,
    required List<DogProfile> dogs,
  }) async {
    final now = DateTime.now();
    final day = _dayKey(now);
    for (final message in CelebrationService.forDate(now)) {
      await notifyUser(
        uid: user.id,
        title:
            '${message.emoji} ${tr(message.title, languageCode: user.languageCode)}',
        body: tr(message.body, languageCode: user.languageCode),
        type: 'celebration',
        stableId: 'auto_${user.id}_${day}_${message.id}',
      );
    }
    for (final dog in dogs) {
      final dob = DateTime.tryParse(dog.dateOfBirth);
      if (dob != null && dob.month == now.month && dob.day == now.day) {
        final eligibleForTrophy = dog.isActive(user);
        await notifyUser(
          uid: user.id,
          title: user.languageCode == 'cy'
              ? '🎂 Pen-blwydd Hapus, ${dog.name}!'
              : '🎂 Happy Birthday, ${dog.name}!',
          body: eligibleForTrophy
              ? (user.languageCode == 'cy'
                    ? 'Mae criw yr Academi yn dymuno pen-blwydd hapus iawn i ${dog.name}. Mae tlws Birthday Buccaneer yn aros hefyd!'
                    : 'The Academy crew wishes ${dog.name} a very happy birthday. A Birthday Buccaneer trophy is waiting too!')
              : (user.languageCode == 'cy'
                    ? 'Mae criw yr Academi yn dymuno pen-blwydd hapus iawn i ${dog.name}. Mae antur yr Academi wedi’i hangori ar hyn o bryd, felly ni ddyfernir tlws swyddogol tra bo’r mynediad wedi’i oedi.'
                    : 'The Academy crew wishes ${dog.name} a very happy birthday. Their Academy adventure is currently anchored, so no official trophy is awarded while access is paused.'),
          type: 'birthday',
          targetId: dog.id,
          stableId: 'birthday_${user.id}_${dog.id}_${now.year}',
        );
        if (eligibleForTrophy) {
          await _ensureAutomaticTrophy(
            dogId: dog.id,
            id: 'birthday_${now.year}',
            title: 'Birthday Buccaneer',
            description: 'A special Academy birthday trophy for ${dog.name}.',
            artKey: 'birthday',
          );
        }
      }
    }
    try {
      final custom = await db
          .collection('calendarEvents')
          .where('enabled', isEqualTo: true)
          .get();
      for (final doc in custom.docs) {
        final m = doc.data();
        final month = (m['month'] as num?)?.toInt();
        final dayNum = (m['day'] as num?)?.toInt();
        if (month == now.month && dayNum == now.day) {
          await notifyUser(
            uid: user.id,
            title: (m['title'] ?? 'Academy Day').toString(),
            body: (m['message'] ?? '').toString(),
            type: 'celebration',
            stableId: 'custom_${user.id}_${day}_${doc.id}',
          );
        }
      }
    } catch (_) {}
  }

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
      int next = previousStreak;
      if (previousDay != today) {
        next = previousDay == yesterday ? previousStreak + 1 : 1;
        tx.update(userRef, {
          'lastLoginDay': today,
          'loginStreak': next,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
      return next;
    });
    await _ensureAutomaticTrophy(
      dogId: dogId,
      id: 'first_login',
      title: 'First Steps Aboard',
      description: '$dogName logged into the Academy for the first time.',
      artKey: 'login',
    );
    if (streak >= 7)
      await _ensureAutomaticTrophy(
        dogId: dogId,
        id: 'streak_7',
        title: 'Seven Days Aboard',
        description: 'A 7-day Academy login streak.',
        artKey: 'streak7',
      );
    if (streak >= 14)
      await _ensureAutomaticTrophy(
        dogId: dogId,
        id: 'streak_14',
        title: 'Sea Legs Streak',
        description: 'A 14-day Academy login streak.',
        artKey: 'streak14',
      );
    if (streak >= 30)
      await _ensureAutomaticTrophy(
        dogId: dogId,
        id: 'streak_30',
        title: 'Month on Deck',
        description: 'A 30-day Academy login streak.',
        artKey: 'streak30',
      );
  }

  Future<void> _ensureAutomaticTrophy({
    required String dogId,
    required String id,
    required String title,
    required String description,
    required String artKey,
  }) async {
    final ref = db.collection('dogs').doc(dogId).collection('trophies').doc(id);
    if ((await ref.get()).exists) return;
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
    await _createPublicAchievementForDog(dogId, title, description, artKey);
  }

  Future<void> acceptTrophy(String dogId, String trophyId) => db
      .collection('dogs')
      .doc(dogId)
      .collection('trophies')
      .doc(trophyId)
      .update({'accepted': true, 'acceptedAt': FieldValue.serverTimestamp()});
  Future<void> acceptHandlerTrophy(String uid, String trophyId) => db
      .collection('users')
      .doc(uid)
      .collection('handlerTrophies')
      .doc(trophyId)
      .update({'accepted': true, 'acceptedAt': FieldValue.serverTimestamp()});

  // Course progress and assessment
  Future<void> setLessonStatus({
    required String dogId,
    required String moduleId,
    required String lessonId,
    required String status,
  }) async {
    await db
        .collection('dogs')
        .doc(dogId)
        .collection('skillProgress')
        .doc(moduleId)
        .set({
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
    String storagePath = '',
    String videoSource = 'link',
    int videoSizeBytes = 0,
    required String note,
    required String learnerName,
    required String dogName,
  }) async {
    final cleanStoragePath = storagePath.trim();

    // Academy uploads get a repeat-safe document ID based on the unique
    // Storage object. If the learner taps/retries after the submission has
    // already reached Firestore, we return the existing submission instead
    // of creating a duplicate.
    final submissionRef = cleanStoragePath.isNotEmpty
        ? db
              .collection('submissions')
              .doc(
                'video_${sha256.convert(utf8.encode(cleanStoragePath)).toString().substring(0, 24)}',
              )
        : db.collection('submissions').doc();

    var created = false;

    await db.runTransaction((tx) async {
      final existing = await tx.get(submissionRef);

      if (existing.exists) return;

      tx.set(submissionRef, {
        'userId': uid,
        'dogId': dogId,
        'learnerName': learnerName,
        'dogName': dogName,
        'moduleId': module.id,
        'moduleTitle': module.title,
        'trophyTitle': module.trophyTitle,
        'artKey': module.artKey,
        'videoUrl': videoUrl.trim(),
        'storagePath': cleanStoragePath,
        'videoSource': videoSource,
        'videoSizeBytes': videoSizeBytes,
        'videoArchived': false,
        'videoArchiveRequested': false,
        'note': note.trim(),
        'status': 'waiting',
        'feedback': '',
        'reviewerName': '',
        'assignedTo': '',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
      });

      created = true;
    });

    // A retry of the same uploaded video is already safely submitted.
    if (!created) return;

    // These are useful extras, but failure here must never make the learner
    // think their successfully-saved assessment failed.
    try {
      await _ensureAutomaticTrophy(
        dogId: dogId,
        id: 'first_assessment',
        title: 'Brave Enough to Be Judged',
        description: 'The first Academy skill assessment was submitted.',
        artKey: 'assessment',
      );
    } catch (_) {}

    try {
      await notifyStaff(
        title: '🎥 Assessment waiting',
        body: '$learnerName & $dogName submitted ${module.title}.',
        type: 'staff_assessment',
        targetId: submissionRef.id,
      );
    } catch (_) {}
  }

  Future<void> claimSubmission(String id, String trainerName) =>
      db.collection('submissions').doc(id).update({'assignedTo': trainerName});

  Future<void> setSubmissionVideoArchiveRequested(
    String submissionId,
    bool value,
  ) async {
    final ref = db.collection('submissions').doc(submissionId);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    Timestamp? deleteAfter;

    if (!value) {
      final reviewedAt = data['reviewedAt'] as Timestamp?;

      if (reviewedAt != null) {
        deleteAfter = Timestamp.fromDate(
          reviewedAt.toDate().add(const Duration(days: 30)),
        );
      }
    }

    await ref.update({
      'videoArchiveRequested': value,
      'videoArchiveRequestedAt': value ? FieldValue.serverTimestamp() : null,
      'videoDeleteAfter': value ? null : deleteAfter,
    });
  }

  Future<void> setHelpVideoArchiveRequested({
    required String threadId,
    required String messageId,
    required bool value,
  }) async {
    final threadRef = db.collection('lessonHelp').doc(threadId);
    final messageRef = threadRef.collection('messages').doc(messageId);

    final threadSnap = await threadRef.get();
    final thread = threadSnap.data() ?? {};

    Timestamp? deleteAfter;

    if (!value) {
      final resolvedAt = thread['resolvedAt'] as Timestamp?;

      if (resolvedAt != null) {
        deleteAfter = Timestamp.fromDate(
          resolvedAt.toDate().add(const Duration(days: 30)),
        );
      }
    }

    await messageRef.update({
      'videoArchiveRequested': value,
      'videoArchiveRequestedAt': value ? FieldValue.serverTimestamp() : null,
      'videoDeleteAfter': value ? null : deleteAfter,
    });
  }

  Future<void> markSubmissionVideoArchived(
    String submissionId, {
    String archiveUrl = '',
  }) async {
    final ref = db.collection('submissions').doc(submissionId);
    final snap = await ref.get();
    final data = snap.data() ?? {};

    final reviewed = data['reviewedAt'] != null;

    await ref.update({
      'videoArchived': true,
      'videoArchivedAt': FieldValue.serverTimestamp(),
      'videoArchiveRequested': false,
      'videoArchiveRequestedAt': null,
      'videoArchiveUrl': archiveUrl.trim(),
      'videoDeleteAfter': reviewed
          ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)))
          : null,
    });
  }

  Future<void> markHelpVideoArchived({
    required String threadId,
    required String messageId,
    String archiveUrl = '',
  }) async {
    final threadRef = db.collection('lessonHelp').doc(threadId);
    final messageRef = threadRef.collection('messages').doc(messageId);

    final threadSnap = await threadRef.get();
    final thread = threadSnap.data() ?? {};

    final resolved =
        thread['resolvedAt'] != null ||
        (thread['status'] ?? '').toString() == 'resolved';

    await messageRef.update({
      'videoArchived': true,
      'videoArchivedAt': FieldValue.serverTimestamp(),
      'videoArchiveRequested': false,
      'videoArchiveRequestedAt': null,
      'videoArchiveUrl': archiveUrl.trim(),
      'videoDeleteAfter': resolved
          ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)))
          : null,
    });
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
    final submissionSnap = await db
        .collection('submissions')
        .doc(submissionId)
        .get();
    final sub = submissionSnap.data() ?? {};
    final uid = (sub['userId'] ?? '').toString();
    final firstSkillRef = db
        .collection('dogs')
        .doc(dogId)
        .collection('trophies')
        .doc('first_skill');
    final firstSkillExists = (await firstSkillRef.get()).exists;
    final batch = db.batch();
    final academyUpload =
        (sub['videoSource'] ?? '').toString() == 'academy_upload';
    final archiveRequested = sub['videoArchiveRequested'] == true;
    final archived = sub['videoArchived'] == true;

    Duration? videoRetention;

    if (academyUpload) {
      if (archived) {
        videoRetention = const Duration(days: 7);
      } else if (!archiveRequested) {
        videoRetention = const Duration(days: 30);
      }
    }

    batch.update(db.collection('submissions').doc(submissionId), {
      'status': passed ? 'passed' : 'practise',
      'feedback': feedback.trim(),
      'reviewerName': reviewerName,
      'reviewedAt': FieldValue.serverTimestamp(),
      'videoDeleteAfter': videoRetention == null
          ? null
          : Timestamp.fromDate(DateTime.now().add(videoRetention)),
    });
    if (passed) {
      final trophy = db
          .collection('dogs')
          .doc(dogId)
          .collection('trophies')
          .doc(moduleId);
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
    if (uid.isNotEmpty) {
      await notifyUser(
        uid: uid,
        title: passed
            ? '🏆 Assessment passed!'
            : '💬 Trainer feedback received',
        body: passed
            ? '$moduleTitle has been passed. A new trophy is waiting in the Captain’s Cabin.'
            : 'Your trainer has reviewed $moduleTitle. Open the assessment to see the feedback.',
        type: 'assessment',
        targetId: submissionId,
      );
    }
    if (passed) {
      await _createPublicAchievementForDog(
        dogId,
        trophyTitle,
        'Passed $moduleTitle',
        artKey,
      );
    }
  }

  // Lesson-specific help threads
  Future<String> requestLessonHelp({
    required String uid,
    required String dogId,
    required String learnerName,
    required String dogName,
    required String moduleId,
    required String moduleTitle,
    required String lessonId,
    required String lessonTitle,
    required String message,
    required String videoUrl,
    String storagePath = '',
    String videoSource = 'link',
    int videoSizeBytes = 0,
  }) async {
    final ref = await db.collection('lessonHelp').add({
      'userId': uid,
      'dogId': dogId,
      'learnerName': learnerName,
      'dogName': dogName,
      'moduleId': moduleId,
      'moduleTitle': moduleTitle,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'status': 'new',
      'assignedTo': '',
      'lastMessageBy': 'learner',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await ref.collection('messages').add({
      'senderId': uid,
      'senderName': learnerName,
      'senderRole': 'learner',
      'message': message.trim(),
      'videoUrl': videoUrl.trim(),
      'storagePath': storagePath.trim(),
      'videoSource': videoSource,
      'videoSizeBytes': videoSizeBytes,
      'videoArchived': false,
      'videoArchiveRequested': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await notifyStaff(
      title: '🆘 Training help requested',
      body: '$learnerName & $dogName need help with $lessonTitle.',
      type: 'staff_help',
      targetId: ref.id,
    );
    return ref.id;
  }

  Future<void> sendHelpMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
    String videoUrl = '',
    String learnerUid = '',
  }) async {
    final ref = db.collection('lessonHelp').doc(threadId);
    await ref.collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message.trim(),
      'videoUrl': videoUrl.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.update({
      'status': senderRole == 'learner' ? 'learner_reply' : 'awaiting_learner',
      'lastMessageBy': senderRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (senderRole != 'learner' && learnerUid.isNotEmpty) {
      await notifyUser(
        uid: learnerUid,
        title: '💬 Trainer replied',
        body: '$senderName has replied to your training help request.',
        type: 'lesson_help',
        targetId: threadId,
      );
    } else if (senderRole == 'learner') {
      await notifyStaff(
        title: '💬 Learner replied',
        body: '$senderName replied to a training help conversation.',
        type: 'staff_help',
        targetId: threadId,
      );
    }
  }

  Future<void> claimHelpThread(String threadId, String trainerName) => db
      .collection('lessonHelp')
      .doc(threadId)
      .update({'assignedTo': trainerName, 'status': 'in_progress'});
  Future<void> resolveHelpThread(String threadId) async {
    final ref = db.collection('lessonHelp').doc(threadId);
    final messages = await ref.collection('messages').get();

    final batch = db.batch();

    batch.update(ref, {
      'status': 'resolved',
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    for (final message in messages.docs) {
      final data = message.data();
      final academyUpload =
          (data['videoSource'] ?? '').toString() == 'academy_upload';
      final archiveRequested = data['videoArchiveRequested'] == true;
      final archived = data['videoArchived'] == true;

      Duration? videoRetention;

      if (academyUpload) {
        if (archived) {
          videoRetention = const Duration(days: 7);
        } else if (!archiveRequested) {
          videoRetention = const Duration(days: 30);
        }
      }

      if (videoRetention != null) {
        batch.update(message.reference, {
          'videoDeleteAfter': Timestamp.fromDate(
            DateTime.now().add(videoRetention),
          ),
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
    int minutes = 0,
  }) => db.collection('trainingLogs').add({
    'userId': uid,
    'dogId': dogId,
    'skill': skill,
    'result': result,
    'note': note.trim(),
    'minutes': minutes,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 1-to-1 — available whether Academy dog is active or paused
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
    String videoUrl = '',
  }) async {
    final config = await getAcademyConfig();
    final ref = await db.collection('oneToOneRequests').add({
      'userId': uid,
      'dogId': dogId,
      'learnerName': learnerName,
      'dogName': dogName,
      'topic': topic,
      'preferredTrainer': preferredTrainer,
      'format': format,
      'availability': availability,
      'note': note.trim(),
      'videoUrl': videoUrl.trim(),
      'status': 'requested',
      'trainerName': '',
      'proposedWhen': '',
      'meetUrl': '',
      'trainerNotes': '',
      'homework': '',
      'durationMinutes': config.oneToOneGuideMinutes,
      'quotedPrice': config.oneToOneGuidePrice,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await notifyStaff(
      title: '📅 New 1-to-1 request',
      body: '$learnerName & $dogName requested help with $topic.',
      type: 'staff_one_to_one',
      targetId: ref.id,
    );
  }

  Future<void> learnerAcceptOneToOne(String id) async {
    final ref = db.collection('oneToOneRequests').doc(id);
    await ref.update({
      'status': 'booked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> learnerCancelOneToOne(String id) =>
      db.collection('oneToOneRequests').doc(id).update({
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
    required int durationMinutes,
    required double quotedPrice,
  }) async {
    final ref = db.collection('oneToOneRequests').doc(id);
    final snap = await ref.get();
    final uid = (snap.data()?['userId'] ?? '').toString();
    await ref.update({
      'status': status,
      'trainerName': trainerName.trim(),
      'proposedWhen': proposedWhen.trim(),
      'meetUrl': meetUrl.trim(),
      'trainerNotes': trainerNotes.trim(),
      'homework': homework.trim(),
      'durationMinutes': durationMinutes,
      'quotedPrice': quotedPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (uid.isNotEmpty) {
      await notifyUser(
        uid: uid,
        title: '📅 1-to-1 update',
        body: 'Your 1-to-1 request has been updated by $trainerName.',
        type: 'one_to_one',
        targetId: id,
      );
    }
  }

  // Account credit and dog access
  Future<void> addAcademyCredit({
    required String uid,
    required double amount,
    required String actor,
    String note = '',
  }) async {
    if (amount <= 0) return;
    final userRef = db.collection('users').doc(uid);
    await db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final current = (snap.data()?['academyCredit'] as num?)?.toDouble() ?? 0;
      tx.update(userRef, {'academyCredit': current + amount});
      tx.set(userRef.collection('ledger').doc(), {
        'type': 'credit',
        'amount': amount,
        'description': note.trim().isEmpty ? 'Doubloons added' : note.trim(),
        'actor': actor,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    final doubloons = poundsToDoubloons(amount);
    await notifyUser(
      uid: uid,
      title: '🪙 Doubloons added',
      body:
          '${formatDoubloonNumber(doubloons)} ${doubloons == 1 ? 'Doubloon has' : 'Doubloons have'} been added to your Academy balance.',
      type: 'account',
    );
    await _audit(
      'Doubloons added',
      uid,
      '${formatDoubloonNumber(doubloons)} Doubloons',
      actor,
    );
  }

  /// Admin/Captain shortcut for the V1.4 learner currency.
  /// Firestore continues to store pounds so old balances and accounting stay compatible.
  Future<bool> adjustAcademyDoubloons({
    required String uid,
    required double doubloons,
    required String actor,
    String note = '',
  }) async {
    if (doubloons == 0) return true;
    final amount = doubloonsToPounds(doubloons);
    final userRef = db.collection('users').doc(uid);
    var changed = false;
    await db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final current = (snap.data()?['academyCredit'] as num?)?.toDouble() ?? 0;
      final next = current + amount;
      if (next < -0.0001) return;
      tx.update(userRef, {'academyCredit': next < 0 ? 0.0 : next});
      tx.set(userRef.collection('ledger').doc(), {
        'type': amount > 0 ? 'credit' : 'adjustment',
        'amount': amount,
        'description': note.trim().isEmpty
            ? (amount > 0
                  ? 'Doubloons added by Admin'
                  : 'Doubloons removed by Admin')
            : note.trim(),
        'actor': actor,
        'createdAt': FieldValue.serverTimestamp(),
      });
      changed = true;
    });
    if (!changed) return false;
    final count = formatDoubloonNumber(doubloons.abs());
    await notifyUser(
      uid: uid,
      title: amount > 0 ? '🪙 Doubloons added' : '🪙 Doubloon balance updated',
      body: amount > 0
          ? '$count ${doubloons.abs() == 1 ? 'Doubloon has' : 'Doubloons have'} been added to your Academy balance.'
          : '$count ${doubloons.abs() == 1 ? 'Doubloon has' : 'Doubloons have'} been removed from your Academy balance.',
      type: 'account',
    );
    await _audit(
      'Doubloon balance adjusted',
      uid,
      '${doubloons > 0 ? '+' : ''}${formatDoubloonNumber(doubloons)} Doubloons',
      actor,
    );
    return true;
  }

  Future<bool> activateDogUsingCredit({
    required String uid,
    required String dogId,
    required String actor,
    double? costOverride,
  }) async {
    final cost = costOverride ?? academyDoubloonPounds;
    final userRef = db.collection('users').doc(uid);
    final dogRef = db.collection('dogs').doc(dogId);
    var success = false;
    await db.runTransaction((tx) async {
      final u = await tx.get(userRef);
      final d = await tx.get(dogRef);
      final balance = (u.data()?['academyCredit'] as num?)?.toDouble() ?? 0;
      if (!d.exists || balance + 0.0001 < cost) return;
      tx.update(userRef, {'academyCredit': balance - cost});
      tx.update(dogRef, {
        'academyStatus': 'active',
        'pauseRequested': false,
        'activatedAt': FieldValue.serverTimestamp(),
        'accessUntil': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: academyDoubloonAccessDays)),
        ),
      });
      tx.set(userRef.collection('ledger').doc(), {
        'type': 'debit',
        'amount': -cost,
        'dogId': dogId,
        'description':
            '${d.data()?['name'] ?? 'Dog'} — 1 Doubloon / $academyDoubloonAccessDays days Academy access',
        'actor': actor,
        'createdAt': FieldValue.serverTimestamp(),
      });
      success = true;
    });
    if (success) {
      await notifyUser(
        uid: uid,
        title: '🏴‍☠️ Adventure started!',
        body:
            '1 Doubloon has opened another $academyDoubloonAccessDays days of Academy access.',
        type: 'account',
        targetId: dogId,
      );
      await _audit(
        'Dog access started',
        dogId,
        '1 Doubloon / $academyDoubloonAccessDays days',
        actor,
      );
    }
    return success;
  }

  Future<void> requestDogPause({
    required String uid,
    required String dogId,
  }) async {
    await db.collection('dogs').doc(dogId).update({'pauseRequested': true});
    await notifyUser(
      uid: uid,
      title: '⚓ Pause scheduled',
      body: 'This dog will pause at the end of the current paid access period. You can cancel the pause before then.',
      type: 'account',
      targetId: dogId,
    );
  }

  Future<void> cancelDogPause(String dogId) =>
      db.collection('dogs').doc(dogId).update({'pauseRequested': false});

  Future<int> requestAllDogsPause({
    required String uid,
    required String actor,
  }) async {
    final dogs = await db
        .collection('dogs')
        .where('ownerId', isEqualTo: uid)
        .get();

    final batch = db.batch();
    var changed = 0;

    for (final dog in dogs.docs) {
      final data = dog.data();
      final status = (data['academyStatus'] ?? '').toString();

      if (status == 'active' && data['pauseRequested'] != true) {
        batch.update(dog.reference, {'pauseRequested': true});
        changed++;
      }
    }

    if (changed == 0) return 0;

    await batch.commit();

    await notifyUser(
      uid: uid,
      title: '⚓ Academy pause scheduled',
      body: changed == 1
          ? 'Your active dog will pause when its current paid access period ends.'
          : 'Your $changed active dogs will pause when their current paid access periods end.',
      type: 'account',
    );

    await _audit(
      'All dog pauses scheduled',
      uid,
      '$changed dog${changed == 1 ? '' : 's'}',
      actor,
    );

    return changed;
  }

  Future<int> cancelAllDogPauses({
    required String uid,
    required String actor,
  }) async {
    final dogs = await db
        .collection('dogs')
        .where('ownerId', isEqualTo: uid)
        .get();

    final batch = db.batch();
    var changed = 0;

    for (final dog in dogs.docs) {
      if (dog.data()['pauseRequested'] == true) {
        batch.update(dog.reference, {'pauseRequested': false});
        changed++;
      }
    }

    if (changed == 0) return 0;

    await batch.commit();

    await notifyUser(
      uid: uid,
      title: '🏴‍☠️ Academy pauses cancelled',
      body: changed == 1
          ? 'Your scheduled dog pause has been cancelled.'
          : 'Your $changed scheduled dog pauses have been cancelled.',
      type: 'account',
    );

    await _audit(
      'All dog pauses cancelled',
      uid,
      '$changed dog${changed == 1 ? '' : 's'}',
      actor,
    );

    return changed;
  }

  Future<void> requestRestart({
    required String uid,
    required String dogId,
    required String dogName,
  }) async {
    final existing = await db
        .collection('restartRequests')
        .where('userId', isEqualTo: uid)
        .get();
    final open = existing.docs.where(
      (d) => d.data()['dogId'] == dogId && d.data()['status'] == 'requested',
    );
    if (open.isNotEmpty) return;
    final ref = await db.collection('restartRequests').add({
      'userId': uid,
      'dogId': dogId,
      'dogName': dogName,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await notifyStaff(
      title: '▶️ Restart requested',
      body: '$dogName is ready to restart an Academy adventure.',
      type: 'staff_account',
      targetId: ref.id,
    );
  }

  Future<void> approveRestart({
    required String requestId,
    required String uid,
    required String dogId,
    required String actor,
  }) async {
    final ok = await activateDogUsingCredit(
      uid: uid,
      dogId: dogId,
      actor: actor,
    );
    await db.collection('restartRequests').doc(requestId).update({
      'status': ok ? 'approved' : 'insufficient_credit',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> processDueRenewal({
    required String uid,
    required DogProfile dog,
    required String actor,
  }) async {
    if (dog.pauseRequested) {
      await db.collection('dogs').doc(dog.id).update({
        'academyStatus': 'paused',
      });
      return;
    }
    await activateDogUsingCredit(uid: uid, dogId: dog.id, actor: actor);
  }

  Future<void> submitPaymentNotice({
    required String uid,
    required String dogId,
    required String dogName,
    required String memberName,
    required double amount,
    required String method,
  }) async {
    final config = await getAcademyConfig();
    final ref = await db.collection('paymentRequests').add({
      'userId': uid,
      'dogId': dogId,
      'dogName': dogName,
      'memberName': memberName,
      'amount': amount,
      'method': method,
      'reference': paymentReference(
        dogName: dogName,
        memberName: memberName,
        suffix: config.paymentReferenceSuffix,
      ),
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await notifyStaff(
      title: '💰 Payment to check',
      body:
          '$memberName says £${amount.toStringAsFixed(2)} was paid for $dogName.',
      type: 'staff_account',
      targetId: ref.id,
    );
  }

  /// Returns an access code when this was the learner's first confirmed Academy payment.
  Future<String?> confirmPaymentRequest({
    required String id,
    required String uid,
    required double amount,
    required String actor,
  }) async {
    final paymentRef = db.collection('paymentRequests').doc(id);
    final userRef = db.collection('users').doc(uid);

    String? code;
    var initialPayment = false;
    var creditAdded = 0.0;

    await db.runTransaction((tx) async {
      final payment = await tx.get(paymentRef);

      if (!payment.exists) {
        throw StateError('This payment request could not be found.');
      }

      if ((payment.data()?['status'] ?? '').toString() != 'waiting') {
        throw StateError('This payment has already been confirmed.');
      }

      final user = await tx.get(userRef);

      if (!user.exists) {
        throw StateError('The learner account could not be found.');
      }

      final data = user.data() ?? {};

      initialPayment =
          data['activated'] != true &&
          ![
            'paid',
            'complimentary',
          ].contains((data['paymentStatus'] ?? 'unpaid').toString());

      if (initialPayment && amount + 0.0001 < academyDoubloonPounds) {
        throw StateError(
          'The first payment must cover at least £${academyDoubloonPounds.toStringAsFixed(2)}.',
        );
      }

      if (initialPayment) {
        code = generateAccessCode();

        tx.update(userRef, {
          'paymentStatus': 'paid',
          'paymentMethod': 'Manual bank payment',
          'accessCodeHash': hashAccessCode(code!),
        });

        creditAdded = max(0.0, amount - academyDoubloonPounds);
      } else {
        creditAdded = amount;
      }

      if (creditAdded > 0) {
        final current = (data['academyCredit'] as num?)?.toDouble() ?? 0.0;

        tx.update(userRef, {'academyCredit': current + creditAdded});

        tx.set(userRef.collection('ledger').doc(), {
          'type': 'credit',
          'amount': creditAdded,
          'description': initialPayment
              ? 'Extra Doubloons after first dog access period'
              : 'Payment confirmed',
          'actor': actor,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(paymentRef, {
        'status': 'confirmed',
        'confirmedBy': actor,
        'confirmedAt': FieldValue.serverTimestamp(),
      });
    });

    // Notifications must not make an already-confirmed payment look failed.
    try {
      if (initialPayment) {
        await notifyUser(
          uid: uid,
          title: '✅ Payment confirmed',
          body: 'Your first Academy access is ready. Enter the activation code sent by the Captain/Admin.',
          type: 'account',
        );
      } else if (creditAdded > 0) {
        final doubloons = poundsToDoubloons(creditAdded);

        await notifyUser(
          uid: uid,
          title: '🪙 Payment confirmed',
          body:
              '${formatDoubloonNumber(doubloons)} ${doubloons == 1 ? 'Doubloon has' : 'Doubloons have'} been added to your Academy balance.',
          type: 'account',
        );
      }
    } catch (_) {}

    try {
      await _audit(
        'Payment confirmed',
        uid,
        '£${amount.toStringAsFixed(2)}',
        actor,
      );
    } catch (_) {}

    return code;
  }

  // Links / course / notices
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

  Future<void> saveAcademySettings(Map<String, dynamic> values) => db
      .collection('settings')
      .doc('academy')
      .set(values, SetOptions(merge: true));
  Future<void> saveLinkSettings(Map<String, String> values) => db
      .collection('settings')
      .doc('links')
      .set(values, SetOptions(merge: true));
  Future<void> saveFeatureSettings(Map<String, dynamic> values) => db
      .collection('settings')
      .doc('features')
      .set(values, SetOptions(merge: true));
  Future<void> saveLessonVideo(
    String moduleId,
    String lessonId,
    String videoUrl,
  ) => db.collection('courseModules').doc(moduleId).set({
    'lessonVideos': {lessonId: videoUrl.trim()},
  }, SetOptions(merge: true));

  Future<void> addNotice({
    required String titleEn,
    required String messageEn,
    required String titleCy,
    required String messageCy,
    required String priority,
    String actor = '',
    bool welshReviewed = false,
  }) async {
    final enTitle = titleEn.trim();
    final enMessage = messageEn.trim();
    final cyTitle = titleCy.trim().isEmpty ? enTitle : titleCy.trim();
    final cyMessage = messageCy.trim().isEmpty ? enMessage : messageCy.trim();
    await db.collection('notices').add({
      'title': enTitle,
      'message': enMessage,
      'titleEn': enTitle,
      'messageEn': enMessage,
      'titleCy': cyTitle,
      'messageCy': cyMessage,
      'welshReviewed': welshReviewed,
      'priority': priority,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final learners = await db
        .collection('users')
        .where('role', isEqualTo: 'learner')
        .get();
    for (final u in learners.docs) {
      final cy = (u.data()['languageCode'] ?? 'en').toString() == 'cy';
      await notifyUser(
        uid: u.id,
        title: priority == 'important'
            ? (cy
                  ? '📢 Hysbysiad Pwysig yr Academi'
                  : '📢 Important Academy Notice')
            : (cy ? '📢 Hysbysiad yr Academi' : '📢 Academy Notice'),
        body: cy ? cyTitle : enTitle,
        type: 'notice',
      );
    }
    if (actor.isNotEmpty) await _audit('Notice published', '', enTitle, actor);
  }

  Future<void> removeNotice(String id) =>
      db.collection('notices').doc(id).update({'active': false});

  // Music library and calendar
  Future<void> addMusicTrack({required String title, required String url}) =>
      db.collection('musicTracks').add({
        'title': title.trim(),
        'url': url.trim(),
        'enabled': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
  Future<void> setMusicTrackEnabled(String id, bool enabled) =>
      db.collection('musicTracks').doc(id).update({'enabled': enabled});
  Future<void> deleteMusicTrack(String id) =>
      db.collection('musicTracks').doc(id).delete();

  Future<void> addCalendarEvent({
    required int month,
    required int day,
    required String title,
    required String message,
  }) => db.collection('calendarEvents').add({
    'month': month,
    'day': day,
    'title': title.trim(),
    'message': message.trim(),
    'enabled': true,
  });
  Future<void> deleteCalendarEvent(String id) =>
      db.collection('calendarEvents').doc(id).delete();

  // Treasure Chest
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

  // Crew, friends and kudos
  Future<void> sendCrewRequest({
    required String fromUid,
    required String fromName,
    required String toUid,
  }) async {
    final id = '${fromUid}_$toUid';
    await db.collection('crewRequests').doc(id).set({
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await notifyUser(
      uid: toUid,
      title: '🏴‍☠️ Crew request',
      body: '$fromName would like to add you to their Crew.',
      type: 'crew',
      targetId: id,
    );
  }

  Future<void> respondCrewRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
    required bool accept,
  }) async {
    await db.collection('crewRequests').doc(requestId).update({
      'status': accept ? 'accepted' : 'declined',
    });
    if (accept) {
      final members = [fromUid, toUid]..sort();
      await db.collection('crewLinks').doc('${members[0]}_${members[1]}').set({
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await notifyUser(
        uid: fromUid,
        title: '👏 Crew request accepted',
        body: 'You have a new Crew mate!',
        type: 'crew',
      );
    }
  }

  Future<void> sendKudos({
    required String achievementId,
    required String fromUid,
    required String fromName,
    required String toUid,
    required String message,
  }) async {
    final id = '${achievementId}_$fromUid';
    if ((await db.collection('kudos').doc(id).get()).exists) return;
    await db.collection('kudos').doc(id).set({
      'achievementId': achievementId,
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await notifyUser(
      uid: toUid,
      title: '👏 New Kudos!',
      body: '$fromName sent congratulations: $message',
      type: 'kudos',
      targetId: achievementId,
    );
  }

  Future<void> _createPublicAchievementForDog(
    String dogId,
    String title,
    String description,
    String artKey,
  ) async {
    final dog = await db.collection('dogs').doc(dogId).get();
    if (!dog.exists) return;
    final ownerId = (dog.data()?['ownerId'] ?? '').toString();
    if (ownerId.isEmpty) return;
    final user = await db.collection('users').doc(ownerId).get();
    if (!user.exists ||
        user.data()?['shareAchievements'] == false ||
        user.data()?['discoverable'] != true)
      return;
    await db.collection('crewAchievements').add({
      'userId': ownerId,
      'displayName': (user.data()?['name'] ?? 'Crew mate').toString(),
      'dogId': dogId,
      'dogName': (dog.data()?['name'] ?? 'Dog').toString(),
      'title': title,
      'description': description,
      'artKey': artKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Lights Practice and handler trophies
  Future<Map<String, dynamic>> recordLightAttempt({
    required String uid,
    required double deltaSeconds,
  }) async {
    final ref = db.collection('lightStats').doc(uid);
    var result = <String, dynamic>{};
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final m = snap.data() ?? {};
      final attempts = ((m['attempts'] as num?)?.toInt() ?? 0) + 1;
      final totalRolling = (m['rollingTotal'] as num?)?.toInt() ?? 0;
      final currentStreak = (m['rollingStreak'] as num?)?.toInt() ?? 0;
      final early = (m['early'] as num?)?.toInt() ?? 0;
      final currentNearEarlyStreak =
          (m['nearEarlyStreak'] as num?)?.toInt() ?? 0;
      final isRolling = deltaSeconds >= 0 && deltaSeconds < 0.005;
      final isNearEarly = deltaSeconds < 0 && deltaSeconds > -0.005;
      final streak = isRolling ? currentStreak + 1 : 0;
      final nearEarlyStreak = isNearEarly ? currentNearEarlyStreak + 1 : 0;
      final rolling = totalRolling + (isRolling ? 1 : 0);
      final earlyNext = early + (deltaSeconds < 0 ? 1 : 0);
      final oldBest = (m['bestPositive'] as num?)?.toDouble();
      final best =
          deltaSeconds >= 0 && (oldBest == null || deltaSeconds < oldBest)
          ? deltaSeconds
          : oldBest;
      final sum = (m['sumDelta'] as num?)?.toDouble() ?? 0;
      tx.set(ref, {
        'userId': uid,
        'attempts': attempts,
        'rollingTotal': rolling,
        'rollingStreak': streak,
        'early': earlyNext,
        'nearEarlyStreak': nearEarlyStreak,
        'bestPositive': best,
        'sumDelta': sum + deltaSeconds,
        'lastDelta': deltaSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      result = {
        'attempts': attempts,
        'rollingTotal': rolling,
        'rollingStreak': streak,
        'nearEarlyStreak': nearEarlyStreak,
        'isRolling': isRolling,
      };
    });
    await db.collection('lightAttempts').add({
      'userId': uid,
      'deltaSeconds': deltaSeconds,
      'isRolling': result['isRolling'] == true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final attempts = result['attempts'] as int;
    final rolling = result['rollingTotal'] as int;
    final streak = result['rollingStreak'] as int;
    final nearEarlyStreak = result['nearEarlyStreak'] as int;
    if (attempts >= 1)
      await _ensureHandlerTrophy(
        uid,
        'lights_first',
        'Lantern Lubber',
        'Practised the starting lights for the first time.',
        'lights',
      );
    if (rolling >= 1)
      await _ensureHandlerTrophy(
        uid,
        'rolling_first',
        'Rolling Roger',
        'Hit a rolling start for the first time.',
        'rolling',
      );
    if (streak >= 3)
      await _ensureHandlerTrophy(
        uid,
        'rolling_three',
        'Triple Broadside',
        'Hit three rolling starts in a row.',
        'triple',
      );
    if (rolling >= 10)
      await _ensureHandlerTrophy(
        uid,
        'rolling_10',
        'Start Line Scallywag',
        'Reached 10 rolling starts.',
        'rolling10',
      );
    if (rolling >= 25)
      await _ensureHandlerTrophy(
        uid,
        'rolling_25',
        'Quickdraw Quartermaster',
        'Reached 25 rolling starts.',
        'rolling25',
      );
    if (rolling >= 50)
      await _ensureHandlerTrophy(
        uid,
        'rolling_50',
        'Cannon-Fire Reflexes',
        'Reached 50 rolling starts.',
        'rolling50',
      );
    if (rolling >= 100)
      await _ensureHandlerTrophy(
        uid,
        'rolling_100',
        'Master of the Lights',
        'Reached 100 rolling starts.',
        'rolling100',
      );
    if (nearEarlyStreak >= 3)
      await _ensureHandlerTrophy(
        uid,
        'too_keen',
        'Too Keen, Captain!',
        'Managed three painfully close -0.00 early starts in a row.',
        'too_keen',
      );
    return result;
  }

  Future<void> _ensureHandlerTrophy(
    String uid,
    String id,
    String title,
    String description,
    String artKey,
  ) async {
    final ref = db
        .collection('users')
        .doc(uid)
        .collection('handlerTrophies')
        .doc(id);
    if ((await ref.get()).exists) return;
    await ref.set({
      'title': title,
      'description': description,
      'artKey': artKey,
      'accepted': false,
      'awardedAt': FieldValue.serverTimestamp(),
    });
    await notifyUser(
      uid: uid,
      title: '🏆 Handler Trophy Unlocked!',
      body: '$title is waiting in the Captain’s Cabin.',
      type: 'trophy',
      targetId: id,
    );
  }

  Future<void> migrateLegacyDog({
    required String dogId,
    required String uid,
    required String actor,
  }) async {
    await db.collection('dogs').doc(dogId).update({
      'academyStatus': 'active',
      'pauseRequested': false,
      'registered': true,
      'activatedAt': FieldValue.serverTimestamp(),
      'accessUntil': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: academyDoubloonAccessDays)),
      ),
    });
    await notifyUser(
      uid: uid,
      title: '🏴‍☠️ V1.4 voyage ready',
      body:
          'Your existing Academy dog has been given a fresh $academyDoubloonAccessDays-day Academy access period.',
      type: 'account',
      targetId: dogId,
    );
    await _audit(
      'Legacy dog migrated',
      dogId,
      '$academyDoubloonAccessDays-day V1.4 access granted',
      actor,
    );
  }

  // Feedback, notes, audit, captain log
  Future<void> submitFeedback({
    required String uid,
    required String name,
    required String type,
    required String message,
  }) => db.collection('feedback').add({
    'userId': uid,
    'name': name,
    'type': type,
    'message': message.trim(),
    'status': 'new',
    'createdAt': FieldValue.serverTimestamp(),
  });
  Future<void> updateFeedbackStatus(String id, String status) =>
      db.collection('feedback').doc(id).update({'status': status});
  Future<void> addStaffNote({
    required String dogId,
    required String dogName,
    required String author,
    required String note,
    String skill = '',
  }) => db.collection('staffNotes').add({
    'dogId': dogId,
    'dogName': dogName,
    'author': author,
    'note': note.trim(),
    'skill': skill,
    'createdAt': FieldValue.serverTimestamp(),
  });
  Future<void> addCaptainLog({required String author, required String text}) =>
      db.collection('captainLog').add({
        'author': author,
        'text': text.trim(),
        'done': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
  Future<void> toggleCaptainLog(String id, bool done) =>
      db.collection('captainLog').doc(id).update({'done': done});

  // Account closure / Set Sail on a New Adventure
  Future<void> requestAccountClosure({
    required String uid,
    required String name,
    required String reason,
  }) async {
    await db.collection('accountDeletionRequests').doc(uid).set({
      'userId': uid,
      'name': name,
      'reason': reason.trim(),
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await notifyStaff(
      title: '⛵ Account closure request',
      body: '$name has asked to set sail on a new adventure.',
      type: 'staff_account',
      targetId: uid,
    );
  }

  Future<void> cancelAccountClosure(String uid) =>
      db.collection('accountDeletionRequests').doc(uid).set({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> markAccountClosureProcessing(String uid, String actor) async {
    await db.collection('accountDeletionRequests').doc(uid).set({
      'status': 'processing',
      'processedBy': actor,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _audit(
      'Account closure started',
      uid,
      'Permanent deletion requested',
      actor,
    );
  }

  Future<void> updateAccountClosureStatus(String uid, String status) =>
      db.collection('accountDeletionRequests').doc(uid).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  // Saved trainer replies and follow-up tools
  Future<void> addSavedReply({
    required String title,
    required String text,
    required String actor,
  }) => db.collection('savedReplies').add({
    'title': title.trim(),
    'text': text.trim(),
    'createdBy': actor,
    'createdAt': FieldValue.serverTimestamp(),
  });
  Future<void> deleteSavedReply(String id) =>
      db.collection('savedReplies').doc(id).delete();

  Future<void> createFollowUp({
    required String dogId,
    required String dogName,
    required String learnerUid,
    required String trainerName,
    required int days,
    required String note,
  }) => db.collection('staffTasks').add({
    'type': 'follow_up',
    'dogId': dogId,
    'dogName': dogName,
    'learnerUid': learnerUid,
    'assignedTo': trainerName,
    'note': note.trim(),
    'status': 'open',
    'dueAt': Timestamp.fromDate(DateTime.now().add(Duration(days: days))),
    'createdAt': FieldValue.serverTimestamp(),
  });
  Future<void> completeStaffTask(String id) => db
      .collection('staffTasks')
      .doc(id)
      .update({'status': 'done', 'completedAt': FieldValue.serverTimestamp()});

  Future<void> recommendSkill({
    required String uid,
    required String dogId,
    required String dogName,
    required String moduleId,
    required String moduleTitle,
    required String trainerName,
  }) async {
    await notifyUser(
      uid: uid,
      title: '🎯 Trainer mission for $dogName',
      body: '$trainerName recommends working on $moduleTitle next.',
      type: 'recommendation',
      targetId: moduleId,
    );
    await db.collection('dogs').doc(dogId).set({
      'recommendedModuleId': moduleId,
      'recommendedModuleTitle': moduleTitle,
      'recommendedBy': trainerName,
      'recommendedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _audit(
    String action,
    String targetId,
    String detail,
    String actor,
  ) => db.collection('auditLog').add({
    'action': action,
    'targetId': targetId,
    'detail': detail,
    'actor': actor,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
