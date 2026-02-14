import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DriverMapWidget extends StatefulWidget {
  final LatLng driverLocation;
  final double heading; 
  final List<LatLng> routePoints; 
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final bool isOnline;
  
  // 🆕 NEW: Callback when driver goes off-route
  final VoidCallback? onOffRoute; 

  const DriverMapWidget({
    super.key,
    required this.driverLocation,
    required this.heading,
    required this.routePoints,
    this.pickupLocation,
    this.dropLocation,
    required this.isOnline,
    this.onOffRoute,
  });

  @override
  State<DriverMapWidget> createState() => _DriverMapWidgetState();
}

class _DriverMapWidgetState extends State<DriverMapWidget> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  
  // 🎨 Assets
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;

  // 🎥 Animation Engine
  late AnimationController _animController;
  late Animation<double> _latAnim;
  late Animation<double> _lngAnim;
  late Animation<double> _bearingAnim;
  
  // State tracking for smooth transitions
  LatLng _currentDisplayPos = const LatLng(0, 0);
  double _currentDisplayBearing = 0.0;
  int _lastClosestIndex = 0;
  int _offRouteCounter = 0; // To debounce off-route triggers

  // 📍 Navigation Constants
  static const double kNavZoomLevel = 18.5; 
  static const double kNavTilt = 56.0;      

  @override
  void initState() {
    super.initState();
    // Initialize starting position
    _currentDisplayPos = widget.driverLocation;
    _currentDisplayBearing = widget.heading;

    // 🆕 Setup Animation Controller (1 second duration for smooth sliding)
    // We assume GPS updates come roughly every 1-2 seconds.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), 
    )..addListener(() {
      setState(() {
        // Update the visual marker position every frame
        _currentDisplayPos = LatLng(_latAnim.value, _lngAnim.value);
        _currentDisplayBearing = _bearingAnim.value;
      });
      // Sync camera with the animated car
      _moveCameraFrame();
    });

    _loadCustomMarkers();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DriverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only animate if location actually changed
    if (widget.driverLocation != oldWidget.driverLocation) {
      _animateToNewLocation();
    }
  }

  // ---------------------------------------------------------------------------
  // 🎬 STEP 1: CALCULATE TARGETS & START ANIMATION
  // ---------------------------------------------------------------------------
  void _animateToNewLocation() {
    // 1. Calculate Snapped Target
    _SnapResult snapResult;
    
    if (widget.routePoints.isNotEmpty) {
      snapResult = _calculateSnapToRoute(
        widget.driverLocation,
        widget.routePoints,
        _lastClosestIndex,
      );
    } else {
      snapResult = _SnapResult(widget.driverLocation, 0, false);
    }

    final LatLng targetPos = snapResult.snappedPoint;
    _lastClosestIndex = snapResult.index;

    // 2. Calculate Smart Target Bearing
    double targetBearing = widget.heading;
    
    // Logic: If snapped (on road) and moving forward, use road bearing
    if (snapResult.isOnRoute && _lastClosestIndex < widget.routePoints.length - 1) {
       double roadBearing = Geolocator.bearingBetween(
        widget.routePoints[_lastClosestIndex].latitude, 
        widget.routePoints[_lastClosestIndex].longitude,
        widget.routePoints[_lastClosestIndex + 1].latitude, 
        widget.routePoints[_lastClosestIndex + 1].longitude,
      );
      
      // Determine if we should use Road Bearing or GPS Heading
      double diff = (widget.heading - roadBearing).abs();
      if (diff > 180) diff = 360 - diff;
      
      // If aligned (< 60 deg diff), use smooth road bearing. Else (U-turn), use GPS.
      if (diff < 60) {
        targetBearing = roadBearing;
      }
    }

    // 3. Handle Off-Route Trigger
    if (!snapResult.isOnRoute) {
      _offRouteCounter++;
      // If off-route for 3 consecutive updates, trigger callback
      if (_offRouteCounter > 3 && widget.onOffRoute != null) {
        widget.onOffRoute!();
        _offRouteCounter = 0; // Reset
      }
    } else {
      _offRouteCounter = 0; // Reset if back on route
    }

    // 4. Setup Tweens for Interpolation
    _latAnim = Tween<double>(begin: _currentDisplayPos.latitude, end: targetPos.latitude)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.linear)); // Linear is best for tracking
    
    _lngAnim = Tween<double>(begin: _currentDisplayPos.longitude, end: targetPos.longitude)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.linear));

    // Fix Rotation Loop (350 -> 10 should be +20, not -340)
    double startBearing = _currentDisplayBearing;
    double endBearing = targetBearing;
    double rotDiff = endBearing - startBearing;
    if (rotDiff > 180) endBearing -= 360;
    if (rotDiff < -180) endBearing += 360;

    _bearingAnim = Tween<double>(begin: startBearing, end: endBearing)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // 5. Play Animation
    _animController.reset();
    _animController.forward();
  }

  // ---------------------------------------------------------------------------
  // 🎥 STEP 2: CAMERA SYNC (Called every frame)
  // ---------------------------------------------------------------------------
  Future<void> _moveCameraFrame() async {
    if (!_controller.isCompleted) return;
    final GoogleMapController controller = await _controller.future;
    
    controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentDisplayPos, // Use the ANIMATED position
          bearing: _currentDisplayBearing, 
          tilt: kNavTilt,        
          zoom: kNavZoomLevel,   
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🧠 STEP 3: SNAPPING MATH
  // ---------------------------------------------------------------------------
  _SnapResult _calculateSnapToRoute(LatLng rawPos, List<LatLng> route, int startIndex) {
    double minDistance = double.infinity;
    LatLng bestSnap = rawPos;
    int bestIndex = startIndex;

    int startSearch = math.max(0, startIndex - 10);
    int endSearch = math.min(route.length - 1, startIndex + 20);

    for (int i = startSearch; i < endSearch; i++) {
      LatLng p1 = route[i];
      LatLng p2 = route[i + 1];
      LatLng projection = _projectPointOnSegment(rawPos, p1, p2);
      double dist = Geolocator.distanceBetween(
        rawPos.latitude, rawPos.longitude,
        projection.latitude, projection.longitude,
      );

      if (dist < minDistance) {
        minDistance = dist;
        bestSnap = projection;
        bestIndex = i;
      }
    }

    // ⚠️ OFF-ROUTE DETECTION THRESHOLD (40 meters)
    if (minDistance > 40) {
      return _SnapResult(rawPos, bestIndex, false); // False = Off Route
    }

    return _SnapResult(bestSnap, bestIndex, true); // True = On Route
  }

  LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    double apX = p.latitude - a.latitude;
    double apY = p.longitude - a.longitude;
    double abX = b.latitude - a.latitude;
    double abY = b.longitude - a.longitude;
    double ab2 = abX * abX + abY * abY;
    double apAb = apX * abX + apY * abY;
    double t = (ab2 == 0) ? 0 : apAb / ab2;
    if (t < 0) return a;
    if (t > 1) return b;
    return LatLng(a.latitude + abX * t, a.longitude + abY * t);
  }

  // ---------------------------------------------------------------------------
  // 🎨 STEP 4: UI RENDERING
  // ---------------------------------------------------------------------------
  
  // (Keep your existing _loadCustomMarkers and _createNavigationArrow here)
  Future<void> _loadCustomMarkers() async {
      final carIcon = await _createNavigationArrow();
      if(mounted) setState(() => _carIcon = carIcon);
  }
  
  Future<BitmapDescriptor> _createNavigationArrow() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0; 
    final double center = size / 2;
    final Paint fillPaint = Paint()..color = const Color(0xFF4285F4); 
    final Paint borderPaint = Paint()..color = Colors.white..strokeWidth = 5.0..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    final Path path = Path();
    path.moveTo(center, 15); path.lineTo(size - 25, size - 20); path.lineTo(center, size - 35); path.lineTo(25, size - 20); path.close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.4), 6.0, true);
    canvas.drawPath(path, fillPaint); canvas.drawPath(path, borderPaint);
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.driverLocation,
        zoom: kNavZoomLevel,
        tilt: kNavTilt,
      ),
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: false, 
      tiltGesturesEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: false, 
      padding: const EdgeInsets.only(top: 0, bottom: 180),

      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        if (widget.isOnline) {
          controller.setMapStyle(_mapStyle);
        }
      },

      polylines: {
        if (widget.routePoints.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('nav_route'),
            points: widget.routePoints,
            color: const Color(0xFF4285F4),
            width: 8,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            zIndex: 1,
          ),
      },
      
      markers: {
        // 🚗 ANIMATED DRIVER MARKER
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentDisplayPos, // 🔥 USES ANIMATED POSITION
          rotation: _currentDisplayBearing, // 🔥 USES ANIMATED BEARING
          icon: _carIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5), 
          flat: true,
          zIndex: 100,
        ),
      if (widget.pickupLocation != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: widget.pickupLocation!,
            icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            anchor: const Offset(0.5, 1.0), // Pin point at bottom
            infoWindow: const InfoWindow(title: "Pickup Point"),
          ),

        // 🔴 DROP LOCATION
        if (widget.dropLocation != null)
          Marker(
            markerId: const MarkerId('drop'),
            position: widget.dropLocation!,
            icon: _dropIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            anchor: const Offset(0.5, 1.0), // Pin point at bottom
            infoWindow: const InfoWindow(title: "Drop Location"),
          ),
      },
    );
  }
}

class _SnapResult {
  final LatLng snappedPoint;
  final int index;
  final bool isOnRoute;
  _SnapResult(this.snappedPoint, this.index, this.isOnRoute);
}

const String _mapStyle = '''
[
  { "featureType": "poi", "elementType": "labels", "stylers": [{ "visibility": "off" }] },
  { "featureType": "transit", "elementType": "labels", "stylers": [{ "visibility": "off" }] }
]
''';