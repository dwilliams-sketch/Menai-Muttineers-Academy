import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  final picker = ImagePicker();

  Future<String?> pickAndUploadProfile({required String uid, required bool enabled}) async {
    if (!enabled) return null;
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 72,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return _upload(bytes, 'profiles/$uid/profile.jpg');
  }

  Future<String?> pickAndUploadDog({required String dogId, required bool enabled}) async {
    if (!enabled) return null;
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 72,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return _upload(bytes, 'dogs/$dogId/profile.jpg');
  }

  Future<String> _upload(Uint8List bytes, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg', cacheControl: 'public,max-age=86400'));
    return ref.getDownloadURL();
  }
}
