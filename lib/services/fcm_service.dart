import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 CALL THIS AFTER DRIVER LOGIN
  Future<void> initFCM() async {
    try {
      // 🔹 Request permission (Android 13+ & iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('❌ FCM: Notification permission denied');
        return;
      }

      print('✅ FCM: Permission granted');

      // 🔹 Save token first time
      await _saveFCMTokenToFirestore();

      // 🔹 Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        print('🔄 FCM: Token refreshed');
        await _saveFCMTokenToFirestore();
      });

      // 🔹 FOREGROUND notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🚕 Ride Notification Received (Foreground)');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
      });

      // 🔹 BACKGROUND / TERMINATED tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📲 Notification tapped');
        print('RideId: ${message.data['rideId']}');
        // Later → Navigate to ride screen
      });
    } catch (e) {
      print('❌ FCM init error: $e');
    }
  }

  /// 🔹 SAVE DRIVER FCM TOKEN TO FIRESTORE
Future<void> _saveFCMTokenToFirestore() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ FCM: No logged-in driver');
      return;
    }

    // Get the current FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print('❌ FCM: Token is null');
      return;
    }

    // Save or update token in Firestore
    final driverRef = FirebaseFirestore.instance.collection('drivers').doc(user.uid);
    await driverRef.set({
      'fcmToken': token,
      'isOnline': true, // Optional: keep driver online status updated
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ FCM: Driver token saved → $token');

    // Optional: Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await driverRef.set({
        'fcmToken': newToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('🔄 FCM: Driver token refreshed → $newToken');
    });

  } catch (e) {
    print('❌ FCM: Failed to save token: $e');
  }
}


  /// 🔹 OPTIONAL: Debug helper
  Future<String?> getCurrentToken() async {
    return await _messaging.getToken();
  }
}
