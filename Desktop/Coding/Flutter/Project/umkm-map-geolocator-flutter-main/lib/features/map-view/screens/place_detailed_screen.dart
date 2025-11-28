// File: place_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:umkm_map_geolocater/core/constants/ui_constants.dart';
import 'package:umkm_map_geolocater/core/models/place_result.dart';

class PlaceDetailScreen extends StatelessWidget {
  final PlaceResult place;
  final double distanceMeters;

  // Karena data Overpass di model Anda terbatas, kita gunakan placeholder
  final String imageUrl = 'https://picsum.photos/600/400?random=1';

  const PlaceDetailScreen({
    super.key,
    required this.place,
    required this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    final distanceKm = distanceMeters / 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Image.network(
              imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50),
                    ),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama UMKM
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Deskripsi
                  const Text(
                    'Deskripsi: Ditemukan melalui OpenStreetMap. Detail produk tidak tersedia.',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),

                  // Jarak
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Jarak: **${distanceKm.toStringAsFixed(2)} km**',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(),

                  // Alamat/Lokasi
                  const Text(
                    'Alamat/Tipe Lokasi:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  const Text('Alamat Detail: Tidak tersedia di data saat ini.'),

                  Text(
                    'Koordinat: ${place.location.latitude.toStringAsFixed(5)}, ${place.location.longitude.toStringAsFixed(5)}',
                  ),

                  const SizedBox(height: 30),

                  // Tombol Navigasi (Membutuhkan _navigateToPlace di HomeScreen)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Tutup detail screen dan kembali ke Map, Anda harus menjalankan navigasi rute di HomeScreen atau service.
                      // Di sini kita hanya akan pop kembali. Logika rute harus dijalankan di Home Screen jika Anda ingin melihat rute di peta.
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kembali ke Map. Klik ikon rute di Map Screen untuk navigasi.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Kembali ke Peta Utama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
