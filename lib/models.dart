import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String languageCode;
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
  final bool pirateBackgrounds;
  final String backgroundMode;
  final String backgroundChoice;
  final bool musicEnabled;
  final double musicVolume;
  final bool reducedMotion;
  final String timerSound;
  final bool discoverable;
  final bool shareAchievements;
  final bool pushEnabled;
  final bool photoUploadsEnabled;
  final double academyCredit;
  final String photoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.languageCode,
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
    required this.pirateBackgrounds,
    required this.backgroundMode,
    required this.backgroundChoice,
    required this.musicEnabled,
    required this.musicVolume,
    required this.reducedMotion,
    required this.timerSound,
    required this.discoverable,
    required this.shareAchievements,
    required this.pushEnabled,
    required this.photoUploadsEnabled,
    required this.academyCredit,
    required this.photoUrl,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      name: (d['name'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      languageCode: (d['languageCode'] ?? 'en').toString() == 'cy' ? 'cy' : 'en',
      role: (d['role'] ?? 'learner').toString(),
      paymentStatus: (d['paymentStatus'] ?? 'unpaid').toString(),
      paymentMethod: (d['paymentMethod'] ?? '').toString(),
      activated: d['activated'] == true,
      accessCodeHash: (d['accessCodeHash'] ?? '').toString(),
      createdAt: dateFrom(d['createdAt']),
      lastActiveAt: dateFrom(d['lastActiveAt']),
      loginStreak: (d['loginStreak'] as num?)?.toInt() ?? 0,
      lastLoginDay: (d['lastLoginDay'] ?? '').toString(),
      celebrationSound: d['celebrationSound'] != false,
      pirateBackgrounds: d['pirateBackgrounds'] != false,
      backgroundMode: (d['backgroundMode'] ?? 'rotate').toString(),
      backgroundChoice: (d['backgroundChoice'] ?? 'cove').toString(),
      musicEnabled: d['musicEnabled'] == true,
      musicVolume: ((d['musicVolume'] as num?)?.toDouble() ?? 0.22).clamp(0.0, 1.0).toDouble(),
      reducedMotion: d['reducedMotion'] == true,
      timerSound: (d['timerSound'] ?? 'parrot').toString(),
      discoverable: d['discoverable'] == true,
      shareAchievements: d['shareAchievements'] != false,
      pushEnabled: d['pushEnabled'] != false,
      photoUploadsEnabled: d['photoUploadsEnabled'] == true,
      academyCredit: (d['academyCredit'] as num?)?.toDouble() ?? 0,
      photoUrl: (d['photoUrl'] ?? '').toString(),
    );
  }

  bool get isTrainer => role == 'trainer';
  bool get isAdmin => role == 'admin';
  bool get isCaptain => role == 'captain';
  bool get isStaff => isTrainer || isAdmin || isCaptain;
  bool get canManageAccounts => isAdmin || isCaptain;
  bool get canSeeReports => isCaptain || isAdmin;
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
  final String academyStatus;
  final bool pauseRequested;
  final DateTime? accessUntil;
  final DateTime? activatedAt;
  final bool registered;

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
    required this.academyStatus,
    required this.pauseRequested,
    required this.accessUntil,
    required this.activatedAt,
    required this.registered,
  });

  factory DogProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DogProfile(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '').toString(),
      name: (d['name'] ?? '').toString(),
      breed: (d['breed'] ?? '').toString(),
      ageText: (d['ageText'] ?? '').toString(),
      dateOfBirth: (d['dateOfBirth'] ?? '').toString(),
      dobEstimated: d['dobEstimated'] == true,
      experience: (d['experience'] ?? '').toString(),
      notes: (d['notes'] ?? '').toString(),
      photoUrl: (d['photoUrl'] ?? '').toString(),
      academyStatus: (d['academyStatus'] ?? '').toString(),
      pauseRequested: d['pauseRequested'] == true,
      accessUntil: dateFrom(d['accessUntil']),
      activatedAt: dateFrom(d['activatedAt']),
      registered: d['registered'] != false,
    );
  }

  String effectiveStatus(AppUser owner) {
    if (academyStatus.isNotEmpty) {
      if (academyStatus == 'active' && accessUntil != null && accessUntil!.isBefore(DateTime.now())) {
        return pauseRequested ? 'paused' : 'renewal_due';
      }
      return academyStatus;
    }
    // Legacy V1.2 compatibility: existing activated learners keep access until staff migrate the dog.
    if (owner.activated) return 'active';
    return 'awaiting';
  }

  bool isActive(AppUser owner) => effectiveStatus(owner) == 'active';
  bool isPaused(AppUser owner) => effectiveStatus(owner) == 'paused';
}

class AcademyNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String targetId;
  final bool read;
  final DateTime? createdAt;

  const AcademyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetId,
    required this.read,
    required this.createdAt,
  });

  factory AcademyNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AcademyNotification(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      body: (d['body'] ?? '').toString(),
      type: (d['type'] ?? 'general').toString(),
      targetId: (d['targetId'] ?? '').toString(),
      read: d['read'] == true,
      createdAt: dateFrom(d['createdAt']),
    );
  }
}

class AppLinks {
  final String facebook;
  final String instagram;
  final String tiktok;
  final String youtube;
  final String website;
  final String easyfundraising;
  final String gofundme;
  final String bankName;
  final String accountName;
  final String sortCode;
  final String accountNumber;
  final String directDebitInfo;
  final String paymentNote;

  const AppLinks({
    required this.facebook,
    required this.instagram,
    required this.tiktok,
    required this.youtube,
    required this.website,
    required this.easyfundraising,
    required this.gofundme,
    required this.bankName,
    required this.accountName,
    required this.sortCode,
    required this.accountNumber,
    required this.directDebitInfo,
    required this.paymentNote,
  });

  factory AppLinks.fromMap(Map<String, dynamic> d) => AppLinks(
        facebook: (d['facebook'] ?? '').toString(),
        instagram: (d['instagram'] ?? '').toString(),
        tiktok: (d['tiktok'] ?? '').toString(),
        youtube: (d['youtube'] ?? '').toString(),
        website: (d['website'] ?? '').toString(),
        easyfundraising: (d['easyfundraising'] ?? '').toString(),
        gofundme: (d['gofundme'] ?? '').toString(),
        bankName: (d['bankName'] ?? '').toString(),
        accountName: (d['accountName'] ?? 'Menai Muttineers').toString(),
        sortCode: (d['sortCode'] ?? '').toString(),
        accountNumber: (d['accountNumber'] ?? '').toString(),
        directDebitInfo: (d['directDebitInfo'] ?? '').toString(),
        paymentNote: (d['paymentNote'] ?? 'Please use the payment reference shown in your account.').toString(),
      );
}

class AcademyConfig {
  final double dogPeriodCost;
  final int dogPeriodDays;
  final String oneToOneWording;
  final double oneToOneGuidePrice;
  final int oneToOneGuideMinutes;
  final String paymentReferenceSuffix;
  final String accountClosureWording;

  const AcademyConfig({
    required this.dogPeriodCost,
    required this.dogPeriodDays,
    required this.oneToOneWording,
    required this.oneToOneGuidePrice,
    required this.oneToOneGuideMinutes,
    required this.paymentReferenceSuffix,
    required this.accountClosureWording,
  });

  factory AcademyConfig.fromMap(Map<String, dynamic> d) => AcademyConfig(
        dogPeriodCost: (d['dogPeriodCost'] as num?)?.toDouble() ?? 5.0,
        dogPeriodDays: (d['dogPeriodDays'] as num?)?.toInt() ?? 30,
        oneToOneWording: (d['oneToOneWording'] ??
                '1-to-1 sessions are charged separately from Academy access. The trainer will confirm the length and price for your needs. You can request one whether your dog’s Academy adventure is active or paused.')
            .toString(),
        oneToOneGuidePrice: (d['oneToOneGuidePrice'] as num?)?.toDouble() ?? 30.0,
        oneToOneGuideMinutes: (d['oneToOneGuideMinutes'] as num?)?.toInt() ?? 60,
        paymentReferenceSuffix: (d['paymentReferenceSuffix'] ?? '007').toString(),
        accountClosureWording: (d['accountClosureWording'] ??
                'If you only need a break, pause your dog’s adventure instead. If you leave the Academy, your personal Academy profile and training data will be removed after Admin approves the request.')
            .toString(),
      );

  String priceLabel() => '£${dogPeriodCost.toStringAsFixed(2)}';
  String accessLabel() => '$dogPeriodDays days';
}
