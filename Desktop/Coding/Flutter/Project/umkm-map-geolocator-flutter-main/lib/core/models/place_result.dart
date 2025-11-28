import 'package:latlong2/latlong.dart' as latlng2;

class PlaceResult {
  final String name;
  final latlng2.LatLng location;
  final double distance;
  final String address;
  final String category;

  PlaceResult(
    this.name,
    this.location,
    this.distance, {
    this.address = 'Alamat tidak diketahui',
    this.category = 'POI',
  });

  // **TAMBAH FACTORY CONSTRUCTOR INI UNTUK REVERSE GEOCODE**
  factory PlaceResult.fromNominatimReverse(Map<String, dynamic> json) {
    // Nominatim Reverse biasanya mengembalikan 'display_name'
    final String formattedAddress = json['display_name'] ?? 'Lokasi Peta';
    final double lat = double.tryParse(json['lat'] ?? '0.0') ?? 0.0;
    final double lon = double.tryParse(json['lon'] ?? '0.0') ?? 0.0;

    // Asumsi: Karena ini reverse geocode, 'distance' tidak relevan, kita beri 0.
    return PlaceResult(
      formattedAddress, // Menggunakan alamat sebagai nama
      latlng2.LatLng(lat, lon),
      0.0,
      address: formattedAddress,
      category: json['category'] ?? 'Geocode Result',
    );
  }
}
