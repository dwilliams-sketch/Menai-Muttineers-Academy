import 'package:cloud_functions/cloud_functions.dart';

class AdminFunctionsService {
  final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
    region: 'europe-west2',
  );

  Future<void> refreshVideoStorageStats() async {
    final callable = functions.httpsCallable('refreshVideoStorageStats');
    await callable.call();
  }

  Future<List<Map<String, dynamic>>> listAcademyStoredVideos() async {
    final callable = functions.httpsCallable('listAcademyStoredVideos');
    final result = await callable.call();

    final data = Map<String, dynamic>.from(result.data as Map);
    final raw = (data['videos'] as List?) ?? const [];

    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> deleteAcademyStoredVideo({required String storagePath}) async {
    final callable = functions.httpsCallable('deleteAcademyStoredVideo');

    await callable.call(<String, dynamic>{'storagePath': storagePath});
  }

  Future<void> permanentlyDeleteAcademyAccount({
    required String targetUid,
  }) async {
    final callable = functions.httpsCallable('deleteAcademyAccount');
    await callable.call(<String, dynamic>{'targetUid': targetUid});
  }

  Future<String> translateAdminText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return '';
    final callable = functions.httpsCallable('translateAdminText');
    final result = await callable.call(<String, dynamic>{
      'text': text.trim(),
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['text'] ?? '').toString();
  }

  Future<String> translateAcademyText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return '';
    final callable = functions.httpsCallable('translateAcademyText');
    final result = await callable.call(<String, dynamic>{
      'text': text.trim(),
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['text'] ?? '').toString();
  }
}
