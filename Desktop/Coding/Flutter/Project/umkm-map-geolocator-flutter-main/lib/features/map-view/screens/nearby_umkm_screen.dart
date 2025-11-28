// File: nearby_umkm_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// Import yang diperlukan
import 'package:umkm_map_geolocater/core/constants/coordinate_constants.dart';
import '../../../core/constants/ui_constants.dart'; // Asumsi kPrimaryColor dan kAccentColor ada di sini

class NearbyUmkmScreen extends StatelessWidget {
  final CoordinateConstants centerUmkm;
  final List<CoordinateConstants> nearbyUmkmList;

  const NearbyUmkmScreen({
    super.key,
    required this.centerUmkm,
    required this.nearbyUmkmList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UMKM dalam 500m dari ${centerUmkm.nama}'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          nearbyUmkmList.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 60,
                        color: kAccentColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '❌ Tidak ditemukan UMKM lain dalam radius 500 meter dari ${centerUmkm.nama}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                itemCount: nearbyUmkmList.length,
                itemBuilder: (context, index) {
                  final umkm = nearbyUmkmList[index];

                  // Menghitung Jarak
                  final distanceMeters = Geolocator.distanceBetween(
                    centerUmkm.latitude,
                    centerUmkm.longitude,
                    umkm.latitude,
                    umkm.longitude,
                  );
                  final distanceKm = distanceMeters / 1000.0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      // Foto
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(umkm.imageUrl),
                        backgroundColor: kAccentColor.withOpacity(0.2),
                      ),
                      // Keterangan/Nama UMKM
                      title: Text(
                        umkm.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Deskripsi & Jarak
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Produk: ${umkm.produk}', // Deskripsi Produk
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Jarak
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${distanceKm.toStringAsFixed(2)} km', // Jarak dalam KM
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Aksi Kontak
                      trailing:
                          umkm.noKontak.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: kAccentColor,
                                ),
                                onPressed: () {
                                  // TODO: Implementasi logic untuk melakukan panggilan telepon/Whatsapp
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Simulasi: Menghubungi ${umkm.noKontak}',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              )
                              : null,
                      onTap: () {
                        // TODO: Implementasi Navigasi ke peta utama atau detail UMKM
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Detail UMKM ${umkm.nama}'),
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
