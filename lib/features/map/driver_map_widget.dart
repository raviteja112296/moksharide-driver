import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DriverMapWidget extends StatelessWidget {
  const DriverMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy driver location (Bangalore example)
    final LatLng driverLocation = LatLng(12.9716, 77.5946);

    return FlutterMap(
      options: MapOptions(
        initialCenter: driverLocation,
        initialZoom: 15,
      ),
      children: [
        // 🌍 OpenStreetMap Tiles (FREE)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.moksharide_driver',
        ),

        // 📍 Driver Marker
        MarkerLayer(
          markers: [
            Marker(
              point: driverLocation,
              width: 50,
              height: 50,
              child: const Icon(
                Icons.local_taxi,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
