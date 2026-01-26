import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize push notifications
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');

        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
          debugPrint('FCM Token: $token');
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

        // Set up background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Foreground message received: ${message.notification?.title}');
          // You can show local notification here if needed
        });

        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Notification opened: ${message.notification?.title}');
          // Handle navigation based on notification data
        });
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Save FCM token to Firestore for the current user
  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving token to database: $e');
    }
  }

  /// Schedule reminder notifications for collection days
  /// This would typically be called from a Cloud Function
  Future<void> scheduleCollectionReminders() async {
    // This is a placeholder - actual scheduling should happen server-side
    // using Cloud Functions to send notifications at specific times
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if user has notifications enabled
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final notificationsEnabled = userDoc.data()?['notifications_enabled'] ?? false;
        if (notificationsEnabled) {
          debugPrint('User has notifications enabled - reminders will be sent from server');
        }
      }
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
    }
  }

  /// Send notification when truck is nearby
  /// This should be called from backend when truck location is updated
  Future<void> notifyTruckNearby(String neighborhood) async {
    // This is a server-side operation
    // The actual notification sending would happen via Cloud Functions
    debugPrint('Truck nearby notification triggered for: $neighborhood');
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': FieldValue.delete(),
        'notifications_enabled': false,
      });
      
      await _messaging.deleteToken();
      debugPrint('Unsubscribed from notifications');
    } catch (e) {
      debugPrint('Error unsubscribing: $e');
    }
  }
}
