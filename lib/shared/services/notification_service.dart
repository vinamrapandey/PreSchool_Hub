import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/firebase_constants.dart';

/// Top-level background message handler for FCM.
/// Must be annotated with [pragma] to ensure it isn't stripped.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Print message details; notifications are automatically shown by the system OS when in the background.
  debugPrint("Handling background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._firestore);

  /// Initializes FCM and local notifications for the authenticated user.
  Future<void> initialize(String userUid) async {
    // 1. Request notification permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions.');
    }

    // 2. Get FCM device token
    final token = await _fcm.getToken();
    if (token != null) {
      await _updateFcmTokenInFirestore(userUid, token);
    }

    // 3. Listen to token refreshes
    _fcm.onTokenRefresh.listen((newToken) async {
      await _updateFcmTokenInFirestore(userUid, newToken);
    });

    // 4. Initialize Local Notifications Plugin for Foreground Display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap when foreground
      },
    );
  }

  /// Updates the FCM token for the user document in Firestore.
  Future<void> _updateFcmTokenInFirestore(String userUid, String token) async {
    try {
      await _firestore
          .collection(FirebaseConstants.kColUsers)
          .doc(userUid)
          .update({'fcmToken': token});
      debugPrint('FCM token successfully saved to users/$userUid');
    } catch (e) {
      debugPrint('Error updating FCM token: ${e.toString()}');
    }
  }

  /// Configures the message listener to show banners while the app is in the foreground.
  Future<void> setupForegroundHandler() async {
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for class updates and notice broadcasts.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });
  }

  /// Sets up app-open navigations when tapping notifications.
  void handleNotificationTap(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'];
      debugPrint("Notification tapped of type: $type");
      
      // Redirect based on message type
      if (type == 'notice') {
        context.go('/role-check');
      } else if (type == 'activity') {
        context.go('/role-check');
      } else {
        context.go('/role-check');
      }
    });
  }
}

/// Provider for [NotificationService] enabling Riverpod dependency injection.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance);
});
