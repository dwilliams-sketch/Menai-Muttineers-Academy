import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  static const String _webVapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
  );

  String _deviceId(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  Future<void> registerForUser(String uid, {required bool enabled}) async {
    try {
      final messaging = FirebaseMessaging.instance;

      if (!enabled) {
        await _removeCurrentDevice(uid, messaging);
        return;
      }

      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        return;
      }

      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (permission.authorizationStatus == AuthorizationStatus.denied ||
          permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        return;
      }

      String? token;

      if (kIsWeb) {
        // Web push requires the public VAPID key configured in Firebase
        // and supplied to the GitHub build as FIREBASE_VAPID_KEY.
        if (_webVapidKey.trim().isEmpty) {
          debugPrint('Academy web push is waiting for FIREBASE_VAPID_KEY.');
          return;
        }

        token = await messaging.getToken(vapidKey: _webVapidKey);
      } else {
        token = await messaging.getToken();
      }

      if (token == null || token.isEmpty) return;

      await db
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(_deviceId(token))
          .set({
            'token': token,
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error) {
      // Push must never prevent Academy access.
      debugPrint('Academy push registration warning: $error');
    }
  }

  Future<void> _removeCurrentDevice(
    String uid,
    FirebaseMessaging messaging,
  ) async {
    try {
      String? token;

      if (kIsWeb) {
        if (_webVapidKey.trim().isEmpty) return;

        token = await messaging.getToken(vapidKey: _webVapidKey);
      } else {
        token = await messaging.getToken();
      }

      if (token == null || token.isEmpty) return;

      await db
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(_deviceId(token))
          .delete();
    } catch (_) {
      // The preference is still saved. Stale invalid tokens are also
      // removed automatically by the push Cloud Function.
    }
  }
}
