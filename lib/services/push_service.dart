import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class PushService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> registerForUser(String uid, {required bool enabled}) async {
    if (!enabled || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      final id = sha256.convert(utf8.encode(token)).toString();
      await db.collection('users').doc(uid).collection('devices').doc(id).set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Push is an enhancement. The in-app notification centre still works if permission/setup is unavailable.
    }
  }
}
