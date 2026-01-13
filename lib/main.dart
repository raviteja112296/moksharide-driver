import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart';
import 'package:moksharide_driver/features/auth/driver_splash_page.dart';
import 'package:moksharide_driver/features/home/driver_home_page.dart';
import 'package:moksharide_driver/features/map/driver_map_widget.dart';
import 'services/local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp();

  // 🔔 Request notification permission (Android 13+ & iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 🔔 Initialize local notification channel (FOREGROUND use)
  await LocalNotificationService.initialize();

  // 🔥 Register background handler (DO NOT show local notifications there)
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // 🔥 Check if app opened from terminated notification
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,  // ✅ BYPASSES ALL reCAPTCHA
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
      // home: DriverHomePage(
      //   forceOnline: openedFromNotification,
      // ),
      home: DriverSplashPage(),
      // home: DriverMapWidget(),
    );
  }
}

// Widget _checkAuthStatus() {
//   final user = FirebaseAuth.instance.currentUser;
//   print('🔍 App start: User ${user?.uid ?? "NULL"}');
  
//   if (user != null) {
//     return DriverHomePage(); // Auto-login
//   }
//   return DriverSignInPage(); // Show login
// }