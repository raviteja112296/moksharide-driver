import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui; // 1. Needed for drawing the custom arrow
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverMapWidget extends StatefulWidget {
  final LatLng driverLocation;
  final bool isOnline;
  final double heading;
  final LatLng? pickupLocation;
  final LatLng? dropLocation;

  // 🔥 We accept points from parent, or we will calculate a straight line below
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
  BitmapDescriptor? _driverIcon; // 2. Store the custom icon

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // 3. Build the icon when app starts
  }

  @override
  void didUpdateWidget(covariant DriverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate Camera if Driver Moves
    if (widget.driverLocation != oldWidget.driverLocation) {
      _animateCamera(widget.driverLocation, widget.heading);
    }
  }

  Future<void> _animateCamera(LatLng pos, double heading) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 17.0,
          bearing: heading,
          tilt: 45.0,
        ),
      ),
    );
  }

  // 🎨 4. CREATE THE PROFESSIONAL ARROW MARKER
  Future<void> _loadCustomMarker() async {
    final icon = await _createArrowMarker();
    setState(() {
      _driverIcon = icon;
    });
  }

  Future<BitmapDescriptor> _createArrowMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Size of the marker (60x60 is a good size for high-res screens)
    const double size = 60.0;
    
    final Paint paint = Paint()
      ..color = Colors.blueAccent // The main arrow color
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Draw the Navigation Arrow Shape (Triangle)
    final Path path = Path();
    path.moveTo(size / 2, 0);          // Top Center (Tip)
    path.lineTo(size, size);           // Bottom Right
    path.lineTo(size / 2, size * 0.7); // Bottom Center (Indented)
    path.lineTo(0, size);              // Bottom Left
    path.close();

    // Draw White Border (for contrast on map)
    canvas.drawPath(path, borderPaint);
    // Draw Blue Fill
    canvas.drawPath(path, paint);

    // Convert Canvas to Image
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.driverLocation,
        zoom: 15.0,
      ),
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      trafficEnabled: widget.isOnline,

      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },

      polylines: _buildPolylines(),
      markers: _buildMarkers(),
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

    // FALLBACK: Straight Line Logic
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
          color: Colors.blue, 
          width: 5,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)], 
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }
    return {};
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // 🚗 DRIVER MARKER (Using Custom Arrow)
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: widget.driverLocation,
        rotation: widget.heading,
        flat: true, // Makes it lie flat on the map like a real car/arrow
        anchor: const Offset(0.5, 0.5), // Center point of rotation
        zIndex: 2, // Always on top
        // Use custom icon if loaded, otherwise fallback to blue dot
        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // 🟢 PICKUP MARKER
    if (widget.pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: "Pickup Here"),
        ),
      );
    }

    // 🔴 DROP MARKER
    if (widget.dropLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: widget.dropLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "Drop Here"),
        ),
      );
    }

    return markers;
  }
}