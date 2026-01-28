import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:moksharide_driver/features/map/services/get_current_location.dart';
import 'package:moksharide_driver/features/ride/domain/driver_ride_ui_state.dart';
import 'package:moksharide_driver/features/ride/presentation/widgets/driver_ride_sheet.dart';
import 'package:moksharide_driver/services/route_service.dart';
import 'driver_map_widget.dart';

class DriverMapContainer extends StatefulWidget {
  final bool isOnline;
  final String? activeRideId;

  const DriverMapContainer({
    super.key,
    required this.isOnline,
    this.activeRideId,
  });

  @override
  State<DriverMapContainer> createState() => _DriverMapContainerState();
}

class _DriverMapContainerState extends State<DriverMapContainer> {
  // ───────────────── STATE ─────────────────

  DriverRideUIState _rideUIState = DriverRideUIState.idle;
  String? _rideOtp;

  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropLocation;

  List<LatLng> _routePoints = [];

  String? _rideStatus;
  double _heading = 0.0;
  bool _otpVerified = false;

  bool _isRouteLoading = false;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<DocumentSnapshot>? _rideSub;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  DateTime _lastFirestoreUpdate =
      DateTime.fromMillisecondsSinceEpoch(0);


  // ───────────────── LIFECYCLE ─────────────────

  @override
  void initState() {
    super.initState();
    _initLocation();

    if (widget.activeRideId != null) {
      _listenToRide(widget.activeRideId!);
    }
  }

  @override
  void didUpdateWidget(covariant DriverMapContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activeRideId != widget.activeRideId) {
      _rideSub?.cancel();

      if (widget.activeRideId != null) {
        _listenToRide(widget.activeRideId!);
      } else {
        _clearRide();
        setState(() => _rideUIState = DriverRideUIState.idle);
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _rideSub?.cancel();
    super.dispose();
  }

  // ───────────────── OTP & COMPLETE ─────────────────

  Future<void> _verifyOtp() async {
  if (widget.activeRideId == null) return;

  await _firestore
      .collection('ride_requests')
      .doc(widget.activeRideId)
      .update({'status': 'started'});

  setState(() {
    _otpVerified = true;
    _rideStatus = 'started';
  });
}



  Future<void> _completeRide() async {
    if (widget.activeRideId == null) return;

    await _firestore
        .collection('ride_requests')
        .doc(widget.activeRideId)
        .update({'status': 'completed'});
  }

  // ───────────────── LOCATION ─────────────────

  Future<void> _initLocation() async {
    final initial = await GetCurrentLocation.get();
    if (!mounted) return;

    setState(() => _currentLocation = initial);
    _startLiveTracking();
  }

  void _startLiveTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      _currentLocation =
          LatLng(position.latitude, position.longitude);
      _heading = position.heading;

      _syncDriverLocation(position);
      _updateRoute();

      setState(() {});
    });
  }

  // ───────────────── DRIVER LOCATION SYNC ─────────────────

  Future<void> _syncDriverLocation(Position position) async {
    if (!widget.isOnline) return;

    final now = DateTime.now();
    if (now.difference(_lastFirestoreUpdate).inSeconds < 5) return;

    _lastFirestoreUpdate = now;

    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    await _firestore.collection('drivers').doc(driverId).set({
      'isOnline': true,
      'location': {
        'lat': position.latitude,
        'lng': position.longitude,
      },
      'heading': position.heading,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ───────────────── RIDE LISTENER ─────────────────
  

  void _listenToRide(String rideId) {
  _rideSub = _firestore
      .collection('ride_requests')
      .doc(rideId)
      .snapshots()
      .listen((doc) {
    if (!doc.exists) return;

    final data = doc.data()!;
    _rideStatus = data['status'];
    _rideOtp = data['rideOtp']?.toString();
    if (_rideStatus == 'accepted') {
      _pickupLocation = LatLng(
  data['pickupLat'],
  data['pickupLng'],
);
debugPrint("📍 Pickup raw: ${data['pickup']}");
debugPrint("📍 Parsed pickup: $_pickupLocation");

      _dropLocation = null;
      _otpVerified = false;
    }

    if (_rideStatus == 'started') {
      _pickupLocation = LatLng(
  data['pickupLat'],
  data['pickupLng'],
);
      _dropLocation = LatLng(data['dropLat'],data['dropLng'],);
      _otpVerified = true;
    }

    if (_rideStatus == 'completed' || _rideStatus == 'cancelled') {
      _clearRide();
    }

    _updateRoute();
    setState(() {});
  });
}


  // ───────────────── ROUTING ─────────────────

  Future<void> _updateRoute() async {
    if (_isRouteLoading || _currentLocation == null) return;

    LatLng? target;

    if (_rideStatus == 'accepted') {
      target = _pickupLocation;
    } else if (_rideStatus == 'started') {
      target = _dropLocation;
    }

    if (target == null) return;

    _isRouteLoading = true;

    try {
      final points = await RouteService.getRoute(
        start: _currentLocation!,
        end: target,
      );

      _routePoints = points;
    } catch (e) {
      debugPrint("❌ Route error: $e");
    } finally {
      _isRouteLoading = false;
    }
  }

  // ───────────────── HELPERS ─────────────────

  LatLng _parseLatLng(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }
    if (value is Map) {
      return LatLng(value['lat'], value['lng']);
    }
    throw Exception("Invalid location format");
  }

  void _clearRide() {
    _rideUIState = DriverRideUIState.idle;
    _pickupLocation = null;
    _dropLocation = null;
    _routePoints.clear();
    _rideStatus = null;
    setState(() {});
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        DriverMapWidget(
          driverLocation: _currentLocation!,
          heading: _heading,
          isOnline: widget.isOnline,
          pickupLocation: _pickupLocation,
          dropLocation: _dropLocation,
          routePoints: _routePoints,
        ),
  // if (_rideStatus == 'accepted' || _rideStatus == 'started')
  if (_rideStatus != null &&
    widget.activeRideId != null &&
    (_rideStatus == 'accepted' || _rideStatus == 'started'))
  DriverRideSheet(
    rideStatus: _rideStatus!,
    otpVerified: _otpVerified,
    rideId: widget.activeRideId!,
    rideOtp: _rideOtp ?? " ", // from Firestore
    onVerifyOtp: _verifyOtp,
    onCompleteRide: _completeRide,
  ),

      ],
    );
  }
}
