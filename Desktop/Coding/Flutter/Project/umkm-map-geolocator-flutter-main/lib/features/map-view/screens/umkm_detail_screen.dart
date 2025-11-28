// File: umkm_coordinate_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:umkm_map_geolocater/core/constants/coordinate_constants.dart';
import 'package:umkm_map_geolocater/core/constants/ui_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class UmkmCoordinateDetailScreen extends StatelessWidget {
  final CoordinateConstants umkm;
  final double distanceKm;

  const UmkmCoordinateDetailScreen({
    super.key,
    required this.umkm,
    required this.distanceKm,
  });

  // Fungsi untuk membuka Google Maps/aplikasi navigasi
  Future<void> _launchMaps() async {
    final lat = umkm.latitude;
    final lon = umkm.longitude;
    final appUrl = 'google.navigation:q=$lat,$lon';
    final webUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';

    final uriApp = Uri.parse(appUrl);

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp);
    } else {
      final uriWeb = Uri.parse(webUrl);
      if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps for coordinates $lat,$lon');
      }
    }
  }

  // Fungsi untuk membuka kontak (WhatsApp/Dial)
  Future<void> _launchContact() async {
    final phone = umkm.noKontak;
    // Coba WhatsApp terlebih dahulu (asumsi nomor kontak adalah nomor WA)
    final whatsappUrl = "whatsapp://send?phone=$phone";
    final whatsappUri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      // Fallback ke dial
      final telUrl = "tel:$phone";
      final telUri = Uri.parse(telUrl);
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        throw Exception('Could not launch phone dial for $phone');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(umkm.nama),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar (Menggunakan imageUrl dari CoordinateConstants)
            Image.network(
              umkm.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder:
                  (_, __, ___) => Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.black54,
                      ),
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
                    umkm.nama,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Deskripsi Produk
                  Text(
                    'Produk Utama: ${umkm.produk}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Jarak
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Jarak dari titik pusat: **${distanceKm.toStringAsFixed(2)} km**',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(),

                  // Detail Kontak & Lokasi
                  const Text(
                    'Informasi Kontak & Lokasi:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Kontak
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Kontak: ${umkm.noKontak.isNotEmpty ? umkm.noKontak : "Tidak Tersedia"}',
                      ),
                    ],
                  ),

                  // Koordinat
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Koordinat: ${umkm.latitude.toStringAsFixed(5)}, ${umkm.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Tombol Navigasi
                  ElevatedButton.icon(
                    onPressed: _launchMaps,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigasi ke Lokasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),

                  if (umkm.noKontak.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // Tombol Kontak (WhatsApp/Dial)
                    ElevatedButton.icon(
                      onPressed: _launchContact,
                      icon: const Icon(Icons.phone),
                      label: const Text('Hubungi via WhatsApp/Telepon'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
