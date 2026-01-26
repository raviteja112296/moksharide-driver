import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moksharide_driver/features/home/driver_home_page.dart';
import 'package:moksharide_driver/features/auth/data/auth_service.dart';

class DriverSignInPage extends StatefulWidget {
  const DriverSignInPage({super.key});

  @override
  State<DriverSignInPage> createState() => _DriverSignInPageState();
}

class _DriverSignInPageState extends State<DriverSignInPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Button animation
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  // Hero animations
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Hero animations
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _buttonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ----------------------
/// EMAIL LOGIN (Fixed)
/// ----------------------
Future<void> _loginWithEmail() async {
  setState(() => _isLoading = true);

  try {
    // Validate input first
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      throw Exception("Please enter email and password");
    }

    await _authService.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // Token save (your fixed version)
    await _saveFCMTokenToFirestore();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomePage()),
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMsg = _getUserFriendlyError(e.code);
    _showError(errorMsg);
  } catch (e) {
    _showError(e.toString());
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

// 🔥 Add this helper method
String _getUserFriendlyError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No account found with this email';
    case 'wrong-password':
      return 'Wrong password. Try again';
    case 'invalid-email':
      return 'Invalid email format';
    case 'user-disabled':
      return 'Account disabled. Contact support';
    case 'too-many-requests':
      return 'Too many attempts. Try again later';
    default:
      return 'Login failed: $code';
  }
}

  /// ----------------------
  /// GOOGLE LOGIN
  /// ----------------------
Future<void> _loginWithGoogle() async {
  setState(() => _isLoading = true);

  try {
    // 1️⃣ Sign in & get UserCredential
    UserCredential userCredential = await _authService.signInWithGoogle();

    // 2️⃣ Extract User
    User? user = userCredential.user;
    if (user == null) throw Exception("Google login failed");

    // 3️⃣ Get FCM token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) throw Exception("FCM token is null");

    // 4️⃣ Save token to Firestore
    await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
      'fcmToken': fcmToken,
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ FCM: Token saved for ${user.uid}');

    // 5️⃣ Navigate to home
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHomePage()),
      );
    }
  } catch (e) {
    print('❌ Login error: $e');
    _showError(e.toString());
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  /// ----------------------
  /// SAVE FCM TOKEN
  /// ----------------------
  Future<void> _saveFCMTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ FCM: No logged-in driver');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('❌ FCM: Token is null');
        return;
      }

      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
        'fcmToken': token,
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ FCM: Driver token saved');
    } catch (e) {
      print('❌ FCM: Failed to save token: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onButtonTapDown(TapDownDetails details) {
    if (!_isLoading) _buttonController.forward();
  }

  void _onButtonTapUp(TapUpDetails details) {
    if (!_isLoading) _buttonController.reverse();
  }

  void _onButtonTapCancel() {
    if (!_isLoading) _buttonController.reverse();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: _heroController,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                // Logo / car image
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 24,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/car.jpg',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'AmbaniYatri Driver',
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Drive with Comfort & Trust',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Glassmorphism card for inputs
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 32,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.email, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.lock, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login button
                            GestureDetector(
                              onTapDown: _onButtonTapDown,
                              onTapUp: _onButtonTapUp,
                              onTapCancel: _onButtonTapCancel,
                              child: AnimatedBuilder(
                                animation: _buttonScaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _buttonScaleAnimation.value,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _loginWithEmail,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white54)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white54)),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Google Sign-In button
                            GestureDetector(
                              onTapDown: _onButtonTapDown,
                              onTapUp: _onButtonTapUp,
                              onTapCancel: _onButtonTapCancel,
                              child: AnimatedBuilder(
                                animation: _buttonScaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _buttonScaleAnimation.value,
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading ? null : _loginWithGoogle,
                                      icon: Image.asset(
                                        'assets/images/google_logo.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      label: Text(
                                        _isLoading ? 'Signing in...' : 'Continue with Google',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.white70),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
