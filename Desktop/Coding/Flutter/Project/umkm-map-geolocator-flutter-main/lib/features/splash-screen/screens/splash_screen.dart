import 'package:flutter/material.dart';
import 'package:umkm_map_geolocater/view/screen/home_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk berpindah ke halaman utama setelah beberapa detik
    _navigateToHome();
  }

  // Fungsi untuk berpindah halaman (simulasi loading)
  _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3000), () {}); // Tahan selama 3 detik


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );

    // Untuk tujuan contoh ini, kita hanya mencetak pesan
    print("Splash Screen selesai, siap pindah ke halaman utama.");
  }

  @override
  Widget build(BuildContext context) {
    // Warna latar belakang yang mirip dengan gambar (biru muda)
    const Color primaryBlue = Color(0xFF4FC3F7); // Contoh warna biru muda

    return const Scaffold(
      // Atur warna latar belakang Scaffold
      backgroundColor: primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.location_on, // Placeholder untuk bentuk ikon map
              color: Colors.white,
              size: 100.0,
            ),

            // --- Spasi antara Ikon dan Teks ---
            SizedBox(height: 20),

            // --- Bagian Teks Utama (uMap) ---
            Text(
              'uMap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            // --- Spasi antara Teks Utama dan Sub Teks ---
            SizedBox(height: 8),

            // --- Bagian Sub Teks (See UMKM Nearby) ---
            Text(
              'See UMKM Nearby',
              style: TextStyle(
                color: Colors.white70, // Sedikit lebih pudar
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}