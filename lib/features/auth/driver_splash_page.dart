import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart';
import 'package:moksharide_driver/features/home/driver_home_page.dart';

class DriverSplashPage extends StatefulWidget {
  const DriverSplashPage({super.key});

  @override
  _DriverSplashPageState createState() => _DriverSplashPageState();
}

class _DriverSplashPageState extends State<DriverSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Icon scale animation
    _iconController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconController.forward();

    // Text fade animation
    _textController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textController.forward();

    // Check auth after animation
    _checkAuthStatus();
  }

 Future<void> _checkAuthStatus() async {
  await Future.delayed(const Duration(seconds: 3));

  if (!mounted) return;

  User? currentUser = FirebaseAuth.instance.currentUser;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) =>
          currentUser != null ? DriverHomePage() : DriverSignInPage(),
    ),
  );
}


  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3C72), // dark blue
              Color(0xFF2A5298), // lighter blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated car image with glow
              ScaleTransition(
                scale: _iconAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/car.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: 40),

              // App name with fade animation
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  'AmbaniYatri Driver',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Tagline
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  'Drive with Comfort & Trust',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
