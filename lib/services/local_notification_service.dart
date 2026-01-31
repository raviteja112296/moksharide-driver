import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 🔔 Channel ID must match Node.js "channelId"
  static const AndroidNotificationChannel _rideChannel =
      AndroidNotificationChannel(
    'ride_channel_v3', 
    'Ride Requests',
    description: 'Incoming ride alerts',
    importance: Importance.max,
    playSound: true,
    // ⚠️ Make sure 'ride_alert.mp3' exists in android/app/src/main/res/raw/
    // If you don't have a custom sound, remove this line or use standard sound.
    sound: RawResourceAndroidNotificationSound('ride_alert'),
  );

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    // Create the channel on the device
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_rideChannel);
        
    // 🔥 CALL THIS HERE TO START LISTENING
    _setupForegroundListeners();
  }

  // 👂 Listener for Foreground Messages
  static void _setupForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 FOREGROUND NOTIFICATION RECEIVED: ${message.notification?.title}");
      
      // // Show the popup manually
      // showRideAlert(
      //   title: message.notification?.title ?? "New Ride Request",
      //   body: message.notification?.body ?? "Tap to view details",
      // );
    });
  }

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
      // Vibration pattern: [delay, vibrate, pause, vibrate]
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