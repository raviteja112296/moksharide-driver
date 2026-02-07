import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math; // Required for Snap Math
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Required for distance calculations

class DriverMapWidget extends StatefulWidget {
  final LatLng driverLocation;
  final bool isOnline;
  final double heading;
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final List<LatLng> routePoints;

  const DriverMapWidget({
    super.key,
    required this.driverLocation,
    required this.isOnline,
    required this.heading,
    this.pickupLocation,
    this.dropLocation,
    required this.routePoints,
  });

  @override
  State<DriverMapWidget> createState() => _DriverMapWidgetState();
}

class _DriverMapWidgetState extends State<DriverMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  @override
  void didUpdateWidget(covariant DriverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 FIX 1: Animate Camera SMOOTHLY without resetting Zoom
    if (widget.driverLocation != oldWidget.driverLocation) {
      // We calculate the snapped position for the camera too, so it centers on the road
      LatLng targetPos = _getSnappedPosition();
      _animateCamera(targetPos);
    }
  }

  // 🎥 FIX 1: The Camera Logic
  Future<void> _animateCamera(LatLng pos) async {
    final GoogleMapController controller = await _controller.future;
    
    // Use newLatLng to KEEP the user's current zoom level
    controller.animateCamera(
      CameraUpdate.newLatLng(pos),
    );
  }

  // 🧮 FIX 2: The "Snap-to-Road" Math Engine
  LatLng _getSnappedPosition() {
    // If no route exists, we can't snap. Return raw GPS.
    if (widget.routePoints.isEmpty) return widget.driverLocation;

    return _getProjectedPointOnPolyline(widget.driverLocation, widget.routePoints);
  }

  LatLng _getProjectedPointOnPolyline(LatLng pos, List<LatLng> polyline) {
    if (polyline.length < 2) return pos;

    double minDist = double.infinity;
    LatLng snappedPos = pos;

    // Optimization: Only check closest 20 points (Driver is usually near the start/middle)
    // You can increase this if routes are very complex
    int searchLimit = math.min(polyline.length - 1, 50);

    for (int i = 0; i < searchLimit; i++) {
      LatLng p1 = polyline[i];
      LatLng p2 = polyline[i + 1];
      
      LatLng projection = _projectPointOnSegment(pos, p1, p2);
      double distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, 
        projection.latitude, projection.longitude
      );

      if (distance < minDist) {
        minDist = distance;
        snappedPos = projection;
      }
    }

    // ⚠️ Safety: If driver is > 40 meters away from road, assume they are off-route.
    // Don't snap them, show raw location.
    if (minDist > 40) {
      return pos; 
    }

    return snappedPos;
  }

  LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    double apX = p.latitude - a.latitude;
    double apY = p.longitude - a.longitude;
    double abX = b.latitude - a.latitude;
    double abY = b.longitude - a.longitude;

    double ab2 = abX * abX + abY * abY;
    double apAb = apX * abX + apY * abY;
    double t = apAb / ab2;

    if (t < 0) return a;
    if (t > 1) return b;
    return LatLng(a.latitude + abX * t, a.longitude + abY * t);
  }

  // 🎨 Custom Marker Builder
  Future<void> _loadCustomMarker() async {
    final icon = await _createArrowMarker();
    setState(() {
      _driverIcon = icon;
    });
  }

  Future<BitmapDescriptor> _createArrowMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 70.0; // Slightly larger for visibility
    
    final Paint paint = Paint()
      ..color = Colors.blue[700]! 
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.moveTo(size / 2, 0);          
    path.lineTo(size, size);           
    path.lineTo(size / 2, size * 0.75); 
    path.lineTo(0, size);             
    path.close();

    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, paint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Calculate the clean position once per build
    final LatLng displayPosition = _getSnappedPosition();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.driverLocation,
        zoom: 16.0,
      ),
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      trafficEnabled: false, // Turn off traffic to reduce visual noise

      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },

      polylines: _buildPolylines(),
      markers: _buildMarkers(displayPosition), // Pass snapped pos
    );
  }

  Set<Polyline> _buildPolylines() {
    if (widget.routePoints.isNotEmpty) {
      return {
        Polyline(
          polylineId: const PolylineId('road_path'),
          points: widget.routePoints,
          color: Colors.blue,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    // Fallback Line
    List<LatLng> straightLinePoints = [];
    if (widget.pickupLocation != null) {
      straightLinePoints.add(widget.driverLocation);
      straightLinePoints.add(widget.pickupLocation!);
      if (widget.dropLocation != null) {
        straightLinePoints.add(widget.dropLocation!);
      }
    }

    if (straightLinePoints.isNotEmpty) {
      return {
        Polyline(
          polylineId: const PolylineId('direct_line'),
          points: straightLinePoints,
          color: Colors.grey, 
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)], 
        ),
      };
    }
    return {};
  }

  Set<Marker> _buildMarkers(LatLng displayPos) {
    Set<Marker> markers = {};

    // 🚗 DRIVER MARKER (Uses Snapped Position)
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: displayPos, // 👈 KEY CHANGE: Using snapped position
        rotation: widget.heading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndex: 100, // Top most
        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // 🟢 PICKUP
    if (widget.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "Pickup"),
        ),
      );
    }

    // 🔴 DROP
    if (widget.dropLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: widget.dropLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Drop"),
        ),
      );
    }

    return markers;
  }
}