import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng2;

// Variabel untuk Search API (tetap)
const String _nominatimApiUrl = 'https://nominatim.openstreetmap.org/search';

// **VARIABEL BASE URL UNTUK REVERSE GEOCODE**
const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

class NominatimResult {
  final String formattedAddress;
  final latlng2.LatLng location;

  NominatimResult(this.formattedAddress, this.location);
}

class NominatimService {
  // **PERBAIKAN 1: Mengubah nilai kembalian dari PlaceResult? menjadi NominatimResult?**
  Future<NominatimResult?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      '$_nominatimBaseUrl/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'UMKM_App_Geolocator_Reverse_v1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Menambahkan pemeriksaan null untuk lat/lon
        if (data.containsKey('error') ||
            !data.containsKey('display_name') ||
            data['lat'] == null ||
            data['lon'] == null) {
          return null;
        }

        final display_name = data['display_name'] as String;
        final location = latlng2.LatLng(
          double.parse(data['lat']),
          double.parse(data['lon']),
        );

        // **PERBAIKAN 2: Mengembalikan NominatimResult.**
        return NominatimResult(display_name, location);
      } else {
        throw Exception(
          'Gagal melakukan reverse geocode. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Reverse Geocode Error: $e');
      return null;
    }
  }

  // Metode searchLocation tidak berubah, tetap mengembalikan NominatimResult?
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
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
