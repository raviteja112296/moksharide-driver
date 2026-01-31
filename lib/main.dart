import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moksharide_driver/features/auth/driver_splash_page.dart'; // Verify this import path
import 'package:moksharide_driver/services/local_notification_service.dart'; // Verify this import path

// 1. 🔥 BACKGROUND HANDLER (Must be outside main)
// This @pragma is the secret to making it work in Release Mode
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🌙 Background Message ID: ${message.messageId}");
  // Note: If the message has a "notification" block, Android system handles the display.
  // We don't need to show a local notification here to avoid duplicates.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 🔥 Initialize Firebase
  await Firebase.initializeApp();

  // 3. 🛡️ Request Permissions (Critical for Android 13+)
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
    criticalAlert: true, // Helps for driver apps
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // 4. 🔔 Initialize Local Notifications (Create Channels)
  await LocalNotificationService.initialize();

  // 5. 🔥 Register Background Handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 6. ⚡ FOREGROUND LISTENER (You were missing this!)
  // This listens for messages while the app is OPEN and showing on screen.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("☀️ Foreground Notification Received: ${message.notification?.title}");

    // Manually trigger the Local Notification so the Driver sees/hears it immediately
    LocalNotificationService.showRideAlert(
      title: message.notification?.title ?? "New Ride Request",
      body: message.notification?.body ?? "Check app for details",
    );
  });

  // 7. 📲 Handle App Opened from Terminated State
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  // ⚠️ WARNING: Remove this line before uploading to Play Store!
  // It allows anyone to log in without real OTPs.
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true, 
  );

  runApp(
    MyApp(
      openedFromNotification: initialMessage != null,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool openedFromNotification;

  const MyApp({super.key, required this.openedFromNotification});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moksha Driver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // If opened from notification, you might want to navigate to a specific page
      // For now, we go to Splash -> Home
      home: const DriverSplashPage(),
    );
  }
}