// lib/features/home/driver_home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:moksharide_driver/features/home/tabs/ride_request_bottom_sheet.dart';
import 'tabs/home_tab.dart';
import 'tabs/recent_tab.dart';
import 'tabs/profile_tab.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentIndex = 0;
  bool _isOnline = false;
  bool _sheetOpen = false;
  StreamSubscription<QuerySnapshot>? _rideSub;

  // 🔥 Toggle ONLINE / OFFLINE
  Future<void> _toggleOnlineStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    HapticFeedback.heavyImpact();

    final newStatus = !_isOnline;

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .set({
          'isOnline': newStatus,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    setState(() => _isOnline = newStatus);

    print('🔥 Driver status: $_isOnline');

    if (_isOnline) {
      await Future.delayed(const Duration(milliseconds: 400));
      _listenForRideRequests();
    } else {
      _rideSub?.cancel();
      _rideSub = null;
      print('🔥 Ride listener STOPPED');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'Now ONLINE! 🚗' : 'Now OFFLINE'),
        backgroundColor: _isOnline ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🔥 Firestore listener
  void _listenForRideRequests() {
    print('🚗 === STARTING RIDE LISTENER ===');

    _rideSub?.cancel();

    _rideSub = FirebaseFirestore.instance
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending')
        // .where('assignedDriverId', isNull: true)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        print('🚗 Pending rides found: ${snapshot.docs.length}');

        if (!_sheetOpen && mounted && snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          print('🚗 NEW RIDE: ${data['pickup']} → ${data['dropoff']}');
          _showRideRequestSheet(doc.id, data);
        }
      },
      onError: (e) => print('🚗 Listener ERROR: $e'),
    );

    print('🚗 Listener ACTIVE');
  }

  // 🔥 Bottom Sheet
  void _showRideRequestSheet(String rideId, Map<String, dynamic> data) {
    if (_sheetOpen || !mounted) return;

    _sheetOpen = true;
    print('🚀 === SHOWING BOTTOM SHEET ===');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => RideRequestBottomSheet(
        rideId: rideId,
        data: data,
        onIgnore: () async {
          await FirebaseFirestore.instance
              .collection('ride_requests')
              .doc(rideId)
              .update({'status': 'ignored'});
          _sheetOpen = false;
          Navigator.pop(context);
        },
        onAccept: () async {
          final user = FirebaseAuth.instance.currentUser;
          await FirebaseFirestore.instance
              .collection('ride_requests')
              .doc(rideId)
              .update({
            'status': 'accepted',
            'assignedDriverId': user?.uid,
          });
          print('🚗 Ride ACCEPTED: $rideId');
          _sheetOpen = false;
          Navigator.pop(context);
        },
      ),
    ).whenComplete(() {
      _sheetOpen = false;
      print('🚀 Bottom sheet CLOSED');
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 REBUILD tabs so HomeTab always gets latest state
    final tabs = [
      HomeTab(
        isOnline: _isOnline,
        onToggleOnline: _toggleOnlineStatus,
      ),
      RecentTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 ? _buildFAB() : null,
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      onTap: (i) => setState(() => _currentIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Recent'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: _isOnline ? Colors.red : Colors.green,
      foregroundColor: Colors.white,
      onPressed: _toggleOnlineStatus,
      child: Icon(
        _isOnline ? Icons.power_off : Icons.power_settings_new,
      ),
    );
  }

  @override
  void dispose() {
    _rideSub?.cancel();
    super.dispose();
  }
}
