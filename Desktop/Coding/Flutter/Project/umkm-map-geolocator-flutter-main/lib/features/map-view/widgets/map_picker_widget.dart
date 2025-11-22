import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng2;

class MapPickerWidget extends StatelessWidget {
  final MapController mapController;
  final latlng2.LatLng initialPosition;
  final Set<Marker> umkmMarkers;
  final Function(latlng2.LatLng newCenter) onPositionUpdate;
  final bool isSearching;
  final List<latlng2.LatLng> routePolyline;

  const MapPickerWidget({
    super.key,
    required this.mapController,
    required this.initialPosition,
    required this.umkmMarkers,
    required this.onPositionUpdate,
    required this.isSearching,
    required this.routePolyline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: initialPosition,
            initialZoom: 15,
            onPositionChanged: (position, hasGesture) {
              if (!isSearching) {
                onPositionUpdate(position.center);
              }
            },
            onMapReady: () {},
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.umkm_map_geolocater',
              maxZoom: 18,
            ),
            PolylineLayer(
              polylines: [
                if (routePolyline.isNotEmpty)
                  Polyline(
                    points: routePolyline,
                    strokeWidth: 5.0,
                    color: Colors.blue.shade700,
                  ),
              ],
            ),
            MarkerLayer(markers: umkmMarkers.toList()),
          ],
        ),
        const Positioned(
          top: 0,
          bottom: 40,
          left: 0,
          right: 0,
          child: Icon(Icons.location_on_sharp, size: 48, color: Colors.red),
        ),
      ],
    );
  }
}
