import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UploadedAcademyVideo {
  final String downloadUrl;
  final String storagePath;
  final String fileName;
  final int sizeBytes;

  const UploadedAcademyVideo({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    required this.sizeBytes,
  });
}

class MediaService {
  final picker = ImagePicker();

  static const int maxAcademyVideoBytes = 100 * 1024 * 1024;

  Future<String?> pickAndUploadProfile({
    required String uid,
    required bool enabled,
  }) async {
    if (!enabled) return null;

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 72,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return _uploadImage(bytes, 'profiles/$uid/profile.jpg');
  }

  Future<String?> pickAndUploadDog({
    required String dogId,
    required bool enabled,
  }) async {
    if (!enabled) return null;

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 72,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return _uploadImage(bytes, 'dogs/$dogId/profile.jpg');
  }

  Future<UploadedAcademyVideo?> chooseAssessmentVideo({required String uid}) =>
      _pickAndUploadAcademyVideo(
        uid: uid,
        videoType: 'assessments',
        source: ImageSource.gallery,
      );

  Future<UploadedAcademyVideo?> recordAssessmentVideo({required String uid}) =>
      _pickAndUploadAcademyVideo(
        uid: uid,
        videoType: 'assessments',
        source: ImageSource.camera,
      );

  Future<UploadedAcademyVideo?> chooseHelpVideo({required String uid}) =>
      _pickAndUploadAcademyVideo(
        uid: uid,
        videoType: 'help',
        source: ImageSource.gallery,
      );

  Future<UploadedAcademyVideo?> recordHelpVideo({required String uid}) =>
      _pickAndUploadAcademyVideo(
        uid: uid,
        videoType: 'help',
        source: ImageSource.camera,
      );

  Future<UploadedAcademyVideo?> _pickAndUploadAcademyVideo({
    required String uid,
    required String videoType,
    required ImageSource source,
  }) async {
    final picked = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 90),
    );

    if (picked == null) return null;

    final size = await picked.length();

    if (size > maxAcademyVideoBytes) {
      throw const AcademyVideoTooLargeException();
    }

    final originalName = picked.name.isEmpty ? 'video.mp4' : picked.name;
    final extension = _safeExtension(originalName);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$stamp.$extension';

    final storagePath = 'academyVideos/$uid/$videoType/$fileName';
    final bytes = await picked.readAsBytes();

    final ref = FirebaseStorage.instance.ref(storagePath);

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: picked.mimeType ?? _videoContentType(extension),
        customMetadata: {
          'ownerUid': uid,
          'videoType': videoType,
          'originalName': originalName,
        },
      ),
    );

    return UploadedAcademyVideo(
      downloadUrl: await ref.getDownloadURL(),
      storagePath: storagePath,
      fileName: fileName,
      sizeBytes: size,
    );
  }

  Future<void> deleteAcademyVideo(String storagePath) async {
    if (!storagePath.startsWith('academyVideos/')) return;
    await FirebaseStorage.instance.ref(storagePath).delete();
  }

  Future<String> _uploadImage(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref(path);

    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=86400',
      ),
    );

    return ref.getDownloadURL();
  }

  String _safeExtension(String fileName) {
    final bits = fileName.toLowerCase().split('.');
    if (bits.length < 2) return 'mp4';

    final ext = bits.last.replaceAll(RegExp(r'[^a-z0-9]'), '');

    switch (ext) {
      case 'mov':
      case 'm4v':
      case 'webm':
      case 'avi':
      case 'mp4':
        return ext;
      default:
        return 'mp4';
    }
  }

  String _videoContentType(String extension) {
    switch (extension) {
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'video/mp4';
    }
  }
}

class AcademyVideoTooLargeException implements Exception {
  const AcademyVideoTooLargeException();

  @override
  String toString() =>
      'This video is too large. Please choose a shorter video under 100 MB.';
}
