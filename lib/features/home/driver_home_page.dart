import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// INTERNAL IMPORTS
import 'tabs/home_tab.dart';     // ✅ Restored HomeTab usage
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
  bool _isOnline = true;
  bool _sheetOpen = false;

  /// 🔥 ACTIVE RIDE ID (ONLY AFTER ACCEPT)
  String? _activeRideId;
  String? _activeRideStatus;

  late final DriverRideRepository _rideRepo;
  StreamSubscription<DocumentSnapshot>? _activeRideSub;
  
  // 📍 LOCATION STREAM SUBSCRIPTION
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _rideRepo = DriverRideRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    // If we have an active ride stored or persisting, you might want to load it here
  }

  /* ---------------- ONLINE / OFFLINE ---------------- */

  Future<void> _toggleOnlineStatus() async {
    HapticFeedback.heavyImpact();
    
    // 1. Check Permissions before going online
    if (!_isOnline) {
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) return; // Stop if permission denied
    }

    setState(() => _isOnline = !_isOnline);
    final user = FirebaseAuth.instance.currentUser;
    if (_isOnline) {
      // 🟢 GOING ONLINE
      _rideRepo.listenForRideRequests(onRideFound: _showRideRequestSheet);
      _startLocationUpdates(); // 👈 START TRACKING
      // Update Firestore to offline
      if (user != null) {
         FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({'isOnline': true});
      }
    } else {
      // 🔴 GOING OFFLINE
      _rideRepo.stopListening();
      _stopLocationUpdates();  // 👈 STOP TRACKING
      
      // Update Firestore to offline
      // final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({'isOnline': false});
      }
    }
  }

  /* ---------------- 📍 LOCATION LOGIC ---------------- */

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  void _startLocationUpdates() {
    // Update location every 10 meters
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, 
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updateLocationToFirestore(position);
    });
  }

  void _stopLocationUpdates() {
    _positionStream?.cancel();
  }

  Future<void> _updateLocationToFirestore(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Updates the 'drivers' collection for User App tracking
    await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
      'location': GeoPoint(position.latitude, position.longitude),
      'heading': position.heading,
      'isOnline': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
        // price: '40',
        price: (data['estimatedPrice'] ?? 0.0).toString(),
        

        /// ❌ REJECT
        onReject: () async {
          await _rideRepo.acceptOrRejectRide(
            rideId: rideId,
            accept: false,
          );
          Navigator.pop(context);
        },

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
      
      // Logic to clear active ride if cancelled or completed
      if (data['status'] == 'completed' || data['status'] == 'cancelled') {
         if (data['status'] == 'cancelled') {
            setState(() => _activeRideId = null);
         }
      }
    });
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // ✅ Restored HomeTab Usage
          HomeTab(
            isOnline: _isOnline,
            activeRideId: _activeRideId,
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
    _stopLocationUpdates(); // 👈 CLEANUP
    super.dispose();
  }
}