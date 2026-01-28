import 'dart:async';
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
    required this.routePoints, // Ensure this is passed from parent
  });

  @override
  State<DriverMapWidget> createState() => _DriverMapWidgetState();
}

class _DriverMapWidgetState extends State<DriverMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  void didUpdateWidget(covariant DriverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. Animate Camera if Driver Moves
    if (widget.driverLocation != oldWidget.driverLocation) {
      _animateCamera(widget.driverLocation, widget.heading);
    }
    
    // Note: We removed _fetchRoadRoute() because you don't want routing services.
    // The line will update automatically in build() below.
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
    // 1. If the parent passed specific points (e.g. from OSRM), use them.
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

    // 2. FALLBACK: If no route points provided, draw a STRAIGHT LINE.
    // This ensures a blue line always shows up, even without API/Internet.
    List<LatLng> straightLinePoints = [];
    
    if (widget.pickupLocation != null) {
      // Line: Driver -> Pickup
      straightLinePoints.add(widget.driverLocation);
      straightLinePoints.add(widget.pickupLocation!);
      
      // If we also have a drop, extend line: Pickup -> Drop
      if (widget.dropLocation != null) {
        straightLinePoints.add(widget.dropLocation!);
      }
    }

    if (straightLinePoints.isNotEmpty) {
      return {
        Polyline(
          polylineId: const PolylineId('direct_line'),
          points: straightLinePoints,
          color: Colors.blue, // Google Blue
          width: 5,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)], // Dashed line for direct path
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

    // 🚗 DRIVER MARKER
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: widget.driverLocation,
        rotation: widget.heading,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          widget.isOnline ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueOrange,
        ),
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