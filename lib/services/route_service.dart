import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteService {
  static Future<List<LatLng>> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route');
    }

    final data = jsonDecode(response.body);

    final coordinates =
        data['routes'][0]['geometry']['coordinates'] as List;

    return coordinates
        .map((point) => LatLng(point[1], point[0]))
        .toList();
  }
}
