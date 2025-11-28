import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng2;
// Tidak perlu mengimpor home_screen.dart di sini

class SelectLocationButton extends StatelessWidget {
  final latlng2.LatLng currentMapCenter;
  final Color primaryColor;
  // ✅ Tambahkan callback function
  final VoidCallback onSelectLocation;

  const SelectLocationButton({
    super.key,
    required this.currentMapCenter,
    required this.primaryColor,
    required this.onSelectLocation, // ✅ Wajib ada
  });

  @override
  Widget build(BuildContext context) {
    // ❌ Hapus Positioned di sini, karena parent (HomeScreen) sudah membungkusnya dalam Positioned
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 25.0),
        child: ElevatedButton(
          onPressed: onSelectLocation, // ✅ Panggil callback function
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'CARI UMKM DI SEKITAR LOKASI INI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
