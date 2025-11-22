import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng2;

const String _nominatimApiUrl = 'https://nominatim.openstreetmap.org/search';

class NominatimResult {
  final String formattedAddress;
  final latlng2.LatLng location;

  NominatimResult(this.formattedAddress, this.location);
}

class NominatimService {
  Future<NominatimResult?> searchLocation(String query) async {
    if (query.isEmpty) return null;
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      '$_nominatimApiUrl?q=$encodedQuery&format=json&limit=1&addressdetails=1',
    );
    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'UMKM_App_Geolocator_v1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          final locationData = data[0];
          final lat = double.tryParse(locationData['lat'] ?? '0.0');
          final lon = double.tryParse(locationData['lon'] ?? '0.0');
          final formattedAddress = locationData['display_name'] ?? query;
          if (lat != null && lon != null) {
            final newPosition = latlng2.LatLng(lat, lon);
            return NominatimResult(formattedAddress, newPosition);
          }
        }
      } else {
        throw Exception('Nominatim HTTP Error: ${response.statusCode}');
      }
      return null; // Lokasi tidak ditemukan atau data tidak valid
    } catch (e) {
      rethrow;
    }
  }
}
