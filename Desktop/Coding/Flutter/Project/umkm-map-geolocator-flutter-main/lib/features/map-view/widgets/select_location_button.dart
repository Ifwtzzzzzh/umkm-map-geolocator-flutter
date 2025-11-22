import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng2;

class SelectLocationButton extends StatelessWidget {
  final latlng2.LatLng currentMapCenter;
  final Color primaryColor;

  const SelectLocationButton({
    super.key,
    required this.currentMapCenter,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 25.0),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Lokasi Dipilih:\nLat: ${currentMapCenter.latitude.toStringAsFixed(6)}, Lng: ${currentMapCenter.longitude.toStringAsFixed(6)}',
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'PILIH LOKASI INI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
