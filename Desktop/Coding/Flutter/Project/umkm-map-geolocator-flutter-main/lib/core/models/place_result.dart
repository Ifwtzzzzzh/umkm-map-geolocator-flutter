import 'package:latlong2/latlong.dart' as latlng2;

class PlaceResult {
  final String name;
  final latlng2.LatLng location; // Menggunakan LatLng dari latlong2
  final double distance; // Jarak dari lokasi pengguna (dalam meter)
  PlaceResult(this.name, this.location, this.distance);
}
