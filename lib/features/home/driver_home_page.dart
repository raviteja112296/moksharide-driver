// lib/features/home/driver_home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'tabs/home_tab.dart';
import 'tabs/recent_tab.dart';
import 'tabs/profile_tab.dart';
import 'data/driver_ride_repository.dart';
import 'widgets/ride_request_bottom_sheet.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _currentIndex = 0;
  bool _isOnline = false;
  bool _sheetOpen = false;

  /// 🔥 ACTIVE RIDE ID (ONLY AFTER ACCEPT)
  String? _activeRideId;

  late final DriverRideRepository _rideRepo;
  StreamSubscription<DocumentSnapshot>? _activeRideSub;
String? _activeRideStatus;


  @override
  void initState() {
    super.initState();
    _rideRepo = DriverRideRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
     if (_activeRideId != null) {
    _listenToActiveRide(_activeRideId!);
  }
  }

  /* ---------------- ONLINE / OFFLINE ---------------- */

  Future<void> _toggleOnlineStatus() async {
    HapticFeedback.heavyImpact();
    setState(() => _isOnline = !_isOnline);

    if (_isOnline) {
      _rideRepo.listenForRideRequests(onRideFound: _showRideRequestSheet);
    } else {
      _rideRepo.stopListening();
      setState(() => _activeRideId = null);
    }
  }

  /* ---------------- RIDE REQUEST SHEET ---------------- */

  void _showRideRequestSheet(String rideId, Map<String, dynamic> data) {
    if (_sheetOpen || !mounted) return;
    _sheetOpen = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => RideRequestBottomSheet(
        pickup: data['pickupAddress'] ?? 'Unknown',
        drop: data['dropAddress'] ?? 'Unknown',

        /// ❌ REJECT
        onReject: () async {
          await _rideRepo.acceptOrRejectRide(
            rideId: rideId,
            accept: false,
          );
          Navigator.pop(context);
        },

        /// ✅ ACCEPT
        /// ✅ ACCEPT
onAccept: () async {
  await _rideRepo.acceptOrRejectRide(
    rideId: rideId,
    accept: true,
  );

  Navigator.pop(context);

  setState(() {
    _activeRideId = rideId;
  });

  /// 🔥 START LISTENING TO RIDE STATUS
  _listenToActiveRide(rideId);
},

      ),
    ).whenComplete(() => _sheetOpen = false);
  }
void _listenToActiveRide(String rideId) {
  _activeRideSub?.cancel();

  _activeRideSub = FirebaseFirestore.instance
      .collection('ride_requests')
      .doc(rideId)
      .snapshots()
      .listen((doc) {
    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    setState(() {
      _activeRideStatus = data['status'];
    });
  });
}

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(
            isOnline: _isOnline,
            activeRideId: _activeRideId, // 🔥 map controls OTP UI
            activeRideStatus: _activeRideStatus,
            onToggleOnline: _toggleOnlineStatus,

          ),
          RecentTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Recent'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rideRepo.stopListening();
    super.dispose();
  }
}
