import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverMapWidget extends StatelessWidget {
  final LatLng driverLocation;
  final bool isOnline;
  final double heading;

  final LatLng? pickupLocation;
  final LatLng? dropLocation;

  /// 🔥 OSRM route points
  final List<LatLng> routePoints;

  const DriverMapWidget({
    super.key,
    required this.driverLocation,
    required this.isOnline,
    required this.heading,
    required this.routePoints,
    this.pickupLocation,
    this.dropLocation,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: driverLocation,
        initialZoom: 14,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        /// 🌍 OSM Tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.moksharide.driver',
        ),

        /// 🛣️ ROUTE POLYLINE
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 5,
                color: Colors.blueAccent,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),

        /// 📍 MARKERS
        MarkerLayer(
          markers: [
            /// 🚗 DRIVER
            Marker(
              point: driverLocation,
              width: 70,
              height: 70,
              child: _DriverMarker(
                isOnline: isOnline,
                heading: heading,
              ),
            ),

            /// 📍 PICKUP
            if (pickupLocation != null)
              Marker(
                point: pickupLocation!,
                width: 50,
                height: 50,
                child: const _PickupMarker(),
              ),

            /// 🏁 DROP
            if (dropLocation != null)
              Marker(
                point: dropLocation!,
                width: 50,
                height: 50,
                child: const _DropMarker(),
              ),
          ],
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            DRIVER MARKER (ROTATING)                         */
/* -------------------------------------------------------------------------- */

class _DriverMarker extends StatelessWidget {
  final bool isOnline;
  final double heading;

  const _DriverMarker({
    required this.isOnline,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor =
        isOnline ? const Color(0xFF1DB954) : Colors.grey.shade600;

    final double rotation = heading * (math.pi / 180);

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          width: isOnline ? 52 : 40,
          height: isOnline ? 52 : 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withOpacity(0.15),
          ),
        ),

        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),

        AnimatedRotation(
          turns: rotation / (2 * math.pi),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor,
            ),
            child: const Icon(
              Icons.navigation,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            PICKUP MARKER                                    */
/* -------------------------------------------------------------------------- */

class _PickupMarker extends StatelessWidget {
  const _PickupMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_upward,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        const CircleAvatar(radius: 3, backgroundColor: Colors.green),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              DROP MARKER                                    */
/* -------------------------------------------------------------------------- */

class _DropMarker extends StatelessWidget {
  const _DropMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.flag,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        const CircleAvatar(radius: 3, backgroundColor: Colors.red),
      ],
    );
  }
}
