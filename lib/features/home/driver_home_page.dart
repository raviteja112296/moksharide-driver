import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart';
import 'package:moksharide_driver/features/ride/driver_ride_repository.dart';
import 'package:moksharide_driver/features/ride/ride_status_screen.dart';
import 'package:moksharide_driver/main.dart';
import 'package:moksharide_driver/services/local_notification_service.dart';
import 'driver_status_service.dart';
import '../../services/fcm_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DriverHomePage extends StatefulWidget {
  final bool forceOnline;

  const DriverHomePage({
    super.key,
    this.forceOnline = false,
  });

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}


class _DriverHomePageState extends State<DriverHomePage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isOnline = true;
  bool _isLoading = false;
  bool _isDialogOpen = false;
  bool _hasActiveRideRequest = false; // NEW: Track active dialog state

  StreamSubscription? _rideSubscription;

  final DriverStatusService _statusService = DriverStatusService();
  final DriverRideRepository _rideRepo = DriverRideRepository();
  final FCMService _fcmService = FCMService();

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _statusController;

  Future<void> requestPermissions() async {
    // Android 13+ notification permission
    await Permission.notification.request();

    // Location (when you need it)
    await Permission.locationWhenInUse.request();
  }
  Future<void> _logout() async {
  // 1. Set driver offline
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
      'isOnline': false,
      'fcmToken': FieldValue.delete(),
    });
  }
  
  // 2. Firebase + Google logout
  await FirebaseAuth.instance.signOut();
  await GoogleSignIn().signOut();
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  
  // 3. RESTART APP (kills cached state)
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(builder: (_) => MyApp(openedFromNotification: initialMessage != null,))
  );
}


 @override
@override
void initState() {
  super.initState();

  // 1️⃣ Initialize FCM
  _fcmService.initFCM();

  // 2️⃣ Request necessary permissions (notification + location)
  requestPermissions();

  // 3️⃣ Save FCM token to Firestore
  _saveFCMTokenToFirestore();

  // 4️⃣ Listen for foreground messages
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('📲 FCM Foreground message received: ${message.data}');
    LocalNotificationService.showRideAlert(
      title: message.notification?.title ?? '🚕 New Ride Request',
      body: message.notification?.body ?? 'Tap to accept the ride',
    );
  });

  // 5️⃣ Listen for when user taps notification from background/terminated state
  FirebaseMessaging.onMessageOpenedApp.listen((message) async {
    debugPrint('📲 Notification tapped (background)');

    setState(() => _isOnline = true);
    await _statusService.setOnlineStatus(true);
    _startListeningRides();
  });

  // 6️⃣ Animation controllers
  _pulseController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);

  _statusController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  // 7️⃣ Force online if opened from notification
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (widget.forceOnline) {
      debugPrint('🚀 App opened from notification → forcing ONLINE');

      setState(() => _isOnline = true);
      await _statusService.setOnlineStatus(true);
      _startListeningRides();
    }
  });
}

/// 🔹 SAVE DRIVER FCM TOKEN
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

    final driverRef =
        FirebaseFirestore.instance.collection('drivers').doc(user.uid);

    await driverRef.set({
      'fcmToken': token,
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ FCM: Driver token saved → $token');

    // Listen for token refresh
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



  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning, Driver';
    } else if (hour < 17) {
      return 'Good Afternoon, Driver';
    } else if (hour < 21) {
      return 'Good Evening, Driver';
    } else {
      return 'Good Night, Driver';
    }
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _pulseController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  /* ---------------- FIXED RIDE LISTENER LOGIC ---------------- */
void _startListeningRides() {
  _rideSubscription?.cancel();
  print('🔥 DRIVER LISTENER STARTED - Online: $_isOnline'); // DEBUG
  _rideSubscription = _rideRepo.getPendingRides().listen((rides) {
    print('📱 GOT RIDES: ${rides.length} | Dialog: $_isDialogOpen | Active: $_hasActiveRideRequest'); // DEBUG
    
    if (!_isOnline || rides.isEmpty || _isDialogOpen || _hasActiveRideRequest) {
      print('🚫 BLOCKED by conditions'); // DEBUG
      return;
    }

    final rideDoc = rides.first;
    final data = rideDoc.data() as Map<String, dynamic>;
    print('🎉 SHOWING DIALOG for ride: ${rideDoc.id}'); // DEBUG

    setState(() {
      _isDialogOpen = true;
      _hasActiveRideRequest = true;
    });

    _showRideDialog(rideDoc.id, data);
  });
}


  void _stopListeningRides() {
    _rideSubscription?.cancel();
    _rideSubscription = null;
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _statusService.setOnlineStatus(value);
      setState(() => _isOnline = value);

      if (value) {
        _startListeningRides();
      } else {
        _stopListeningRides();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // FIXED: Properly reset dialog state after accept/ignore
  void _resetDialogState() {
    if (mounted) {
      setState(() {
        _isDialogOpen = false;
        _hasActiveRideRequest = false;
      });
    }
  }

void _showRideDialog(String rideId, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // 🔒 LOCK BOTTOM SHEET - NO SWIPE DISMISSAL
    isDismissible: false,        // Block tap outside
    enableDrag: false,           // Block swipe down
    builder: (_) => RideRequestBottomSheet(
      rideId: rideId,
      data: data,
      onIgnore: () {
        Navigator.pop(context);
        _resetDialogState();
        _rideRepo.ignoreRide(rideId);
      },
      onAccept: () {
        Navigator.pop(context);
        _resetDialogState();
        _rideRepo.acceptRide(rideId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride Accepted ✓'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    ),
  ).then((_) => _resetDialogState());
}


  // UPDATED: Complete Production-Ready Logout Function
  Future<void> _handleLogout() async {
    try {
      // 1. Show loading confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will stop receiving ride requests.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay Online'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _logout(),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      // 2. Exit if user cancelled
      if (shouldLogout != true || !mounted) return;

      // 3. Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 4. Set driver offline (stop receiving rides)
      await _statusService.setOnlineStatus(false);
      
      // 5. Cancel all Firestore listeners
      _stopListeningRides();

      // 6. Sign out from Firebase Auth (Google Sign-In)
      await FirebaseAuth.instance.signOut();

      // 7. Close loading dialog
      if (mounted) Navigator.pop(context);

      // 8. Navigate to Sign-In screen (clear entire navigation stack)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DriverSignInPage()),
          (route) => false, // Remove ALL previous routes
        );
      }

      // 9. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged out successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

    } catch (e) {
      // Handle any errors gracefully
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildRidesTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // HOME TAB: Real Map Image (Easy Google Maps replacement)
  Widget _buildHomeTab() {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // MAP IMAGE: Replace with GoogleMap() later
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/map_preview.jpg'), // Add your map image here
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),
        
        // Center Location Pin (Works with real map too)
        const Positioned(
          top: 45,
          left: 50,
          child: Icon(
            Icons.location_pin,
            size: 48,
            color: Colors.red,
            shadows: [
              Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),

        // Map Preview Label
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🗺️ Map Preview (Replace with Google Maps)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Top Status Overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.95),
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getGreeting(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _isOnline ? 'Receiving requests' : 'No rides yet today',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
  onTap: _isLoading ? null : () => _toggleOnlineStatus(!_isOnline),
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _isOnline
            ? [Colors.green.shade500, Colors.green.shade700]
            : [Colors.grey.shade400, Colors.grey.shade600],
      ),
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: (_isOnline ? Colors.green : Colors.grey).withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            _isOnline ? Icons.wifi_tethering : Icons.wifi_off,
            key: ValueKey(_isOnline),
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _isLoading
              ? 'PLEASE WAIT'
              : (_isOnline ? 'ONLINE' : 'OFFLINE'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Colors.white,
          ),
        ),
      ],
    ),
  ),
),

                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Floating Action Buttons (Same positions as real map apps)
        Positioned(
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 100,
          child: Column(
            children: [
              // My Location Button
              FloatingActionButton(
                mini: false,
                heroTag: 'location',
                onPressed: () {},
                elevation: 8,
                backgroundColor: Colors.white,
                foregroundColor: Colors.green[600],
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 16),
              // Online Status Badge (Pulsing when online)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isOnline ? _pulseController.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[500]!, Colors.green[600]!],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRidesTab() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Recent Rides',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '🚕 No rides yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completed rides will appear here',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final player = AudioPlayer();
                            await player.play(AssetSource('ride_alert.mp3'));
                          },
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Test Ride Alert Sound'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/images/driver_avatar.png',
                      width: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'John Driver',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Swift Dzire - KA01AB1234',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSettingsCard(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {},
            ),
            _buildSettingsCard(
              icon: Icons.logout,
              title: 'Logout',
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: Colors.green[600],
      unselectedItemColor: Colors.grey[500],
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Rides',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

// FIXED Ride Request Bottom Sheet
class RideRequestBottomSheet extends StatelessWidget {
  final String rideId;
  final Map<String, dynamic> data;
  final VoidCallback onIgnore;
  final VoidCallback onAccept;

  const RideRequestBottomSheet({
    super.key,
    required this.rideId,
    required this.data,
    required this.onIgnore,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 32)],
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                height: 4,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[600]!, Colors.orange[400]!],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'New Ride Request',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.location_on, 'Pickup', data['pickup']),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_off, 'Dropoff', data['dropoff']),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow(Icons.straighten, 'Distance', '${data['distance']} km')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInfoRow(Icons.payments, 'Price', '₹${data['price']}')),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onIgnore,
                        icon: const Icon(Icons.close),
                        label: const Text('IGNORE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.check),
                        label: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
