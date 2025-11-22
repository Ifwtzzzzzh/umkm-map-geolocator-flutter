import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng2;
import 'package:umkm_map_geolocater/core/models/place_result.dart';
import 'package:umkm_map_geolocater/features/map-view/services/location_service.dart';

const String _overpassApiUrl = 'https://overpass-api.de/api/interpreter';
const int _nearbyRadiusMeters = 500;

class OverpassService {
  Future<List<PlaceResult>> fetchNearbyUmkm(latlng2.LatLng userLocation) async {
    final lat = userLocation.latitude;
    final lon = userLocation.longitude;
    final overpassQuery = '''
  [out:json][timeout:25];
  (
    node(around:$_nearbyRadiusMeters,$lat,$lon)[shop];
    node(around:$_nearbyRadiusMeters,$lat,$lon)[amenity~"restaurant|cafe|fast_food|food_court|bar"];
  );
  out center;
''';
    try {
      final response = await http
          .post(
            Uri.parse(_overpassApiUrl),
            body: overpassQuery,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['elements'] != null) {
          List<PlaceResult> results = [];
          for (var item in data['elements']) {
            final placeName =
                item['tags']['name'] as String? ?? 'UMKM Tanpa Nama';
            final placeLat = item['lat'];
            final placeLon = item['lon'];
            final latLng = latlng2.LatLng(placeLat, placeLon);
            double distance = LocationService.calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              latLng.latitude,
              latLng.longitude,
            );
            results.add(PlaceResult(placeName, latLng, distance));
          }
          return results;
        }
        return [];
      } else {
        throw Exception(
          'Gagal memuat data dari Overpass API (${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
