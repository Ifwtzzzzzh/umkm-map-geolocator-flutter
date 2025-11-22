// routing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng2;
import 'package:flutter/foundation.dart';

// OSRM Public Demo Server
const String _osrmApiUrl = 'https://router.project-osrm.org/route/v1/driving';

class RoutingService {
  Future<List<latlng2.LatLng>> getRoute(
    latlng2.LatLng origin,
    latlng2.LatLng destination,
  ) async {
    final originStr = '${origin.longitude},${origin.latitude}';
    final destinationStr = '${destination.longitude},${destination.latitude}';

    // Query OSRM untuk mendapatkan rute mengemudi (driving)
    final url = Uri.parse(
      '$_osrmApiUrl/$originStr;$destinationStr?geometries=geojson&overview=full',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          if (geometry['coordinates'] != null) {
            List<latlng2.LatLng> polylinePoints = [];

            // Koordinat dari OSRM dalam format [longitude, latitude]
            for (var coord in geometry['coordinates']) {
              // Penting: ubah dari [lon, lat] menjadi LatLng(lat, lon)
              final lat = coord[1];
              final lon = coord[0];
              polylinePoints.add(latlng2.LatLng(lat, lon));
            }
            return polylinePoints;
          }
        }
        throw Exception('Rute tidak ditemukan untuk koordinat ini.');
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Unknown OSRM Error';
        debugPrint(
          'OSRM HTTP Error: ${response.statusCode}, Detail: $errorMessage',
        );
        throw Exception(
          'Gagal memuat rute dari OSRM API (${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      // Jika error, kembalikan list kosong
      debugPrint('Routing Catch Error: $e');
      return [];
    }
  }
}
