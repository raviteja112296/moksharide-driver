import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ----------------------------------
/// LOCAL NOTIFICATION SERVICE
/// ----------------------------------
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _rideChannel =
      AndroidNotificationChannel(
    'ride_channel', // MUST match server android_channel_id
    'Ride Requests',
    description: 'Incoming ride alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('ride_alert'),
  );

  /// Call this ONCE in main()
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_rideChannel);
  }

  /// ✅ Use ONLY when app is in FOREGROUND
  static Future<void> showRideAlert({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _rideChannel.id,
      _rideChannel.name,
      channelDescription: _rideChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: _rideChannel.sound,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 1000, 500]),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}

/// ----------------------------------
/// FCM CONFIGURATION
/// ----------------------------------

/// ❌ DO NOT show local notifications here
/// Background & killed state MUST rely on SERVER sound
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty
}

/// Foreground FCM listener (SAFE)
// void setupFCMListeners() {
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     LocalNotificationService.showRideAlert(
//       title: message.notification?.title ?? "🚕 New Ride Request",
//       body: message.notification?.body ?? "Tap to accept the ride",
//     );
//   });
// }
