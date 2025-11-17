import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// --- OSM/Mapbox Packages ---
import 'package:flutter_map/flutter_map.dart'; // Widget Peta OSM
import 'package:latlong2/latlong.dart' as latlng2;
import 'package:umkm_map_geolocater/core/constants/ui_constants.dart';
import 'package:umkm_map_geolocater/core/models/place_result.dart'; // Ganti LatLng dari Google Maps

// API Key Google tidak digunakan lagi, tapi konstanta tetap ada untuk Geocoding (jika mau)
// const String _googleApiKey = 'AIzaSyButCVSMn70yhIpSRItWpqikgC53QFZO9k';
const String _overpassApiUrl = 'https://overpass-api.de/api/interpreter';
const Duration _searchDelay = Duration(milliseconds: 1000);
const int _nearbyRadiusMeters = 500; // Radius pencarian UMKM (500 meter)
const String _nominatimApiUrl = 'https://nominatim.openstreetmap.org/search';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Koordinat Jakarta Barat sebagai posisi awal (menggunakan latlong2.LatLng)
  static const latlng2.LatLng _initialPosition = latlng2.LatLng(
    -6.1650,
    106.7260,
  );

  // State untuk menyimpan koordinat pusat peta saat ini
  latlng2.LatLng _currentMapCenter = _initialPosition;
  final MapController _mapController =
      MapController(); // Controller untuk Flutter Map

  // Controller untuk input teks pencarian
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Set<Marker> _umkmMarkers =
      {}; // Marker untuk menampilkan UMKM hasil pencarian

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocationAndShowNearbyUmkm();
    });
  }

  // --- FUNGSI MENGAMBIL DATA TEMPAT TERDEKAT DARI OVERPASS API (OSM) ---
  Future<List<PlaceResult>> _fetchNearbyUmkmFromOverpass(
    latlng2.LatLng userLocation,
  ) async {
    final lat = -6.168309;
    final lon = 106.726458;

    // Overpass Query: Cari node/way/relation dengan tag "shop" atau "amenity=restaurant"
    // dalam radius 500m dari lokasi pengguna.
    // --- GANTI DENGAN INI ---

    final overpassQuery = '''
  [out:json][timeout:25]; // Menambahkan batas waktu 25 detik di sisi server
  (
    // 1. Ambil semua node yang memiliki tag 'shop' (ini mencakup bakery, supermarket, dll.)
    node(around:${_nearbyRadiusMeters},$lat,$lon)[shop];
    
    // 2. Ambil semua node dengan tag amenity spesifik (restoran, kafe, dll.)
    node(around:${_nearbyRadiusMeters},$lat,$lon)[amenity~"restaurant|cafe|fast_food|food_court|bar"];
  );
  out center;
''';

    // --- SAMPAI DI SINI ---

    try {
      final response = await http
          .post(
            Uri.parse(_overpassApiUrl),
            body: overpassQuery,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['elements'] != null) {
          List<PlaceResult> results = [];
          for (var item in data['elements']) {
            final placeName =
                item['tags']['name'] as String? ?? 'UMKM Tanpa Nama';
            final placeLat = item['lat'];
            final placeLon = item['lon'];
            final latLng = latlng2.LatLng(placeLat, placeLon);

            // Hitung jarak menggunakan Geolocator (atau latlong2.Distance, keduanya bisa)
            double distance = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              latLng.latitude,
              latLng.longitude,
            );

            results.add(PlaceResult(placeName, latLng, distance));
          }
          return results;
        }
        return [];
      } else {
        debugPrint(
          'Overpass HTTP Error: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception(
          'Gagal memuat data dari Overpass API (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Overpass Catch Error: $e');
      rethrow;
    }
  }

  // --- FUNGSI MENDAPATKAN LOKASI PENGGUNA DAN MENAMPILKAN UMKM TERDEKAT ---
  Future<void> _getCurrentLocationAndShowNearbyUmkm() async {
    // [LOGIKA IZIN LOKASI SAMA]
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Izin lokasi diperlukan untuk mencari UMKM terdekat.",
              ),
            ),
          );
        }
        return;
      }
    }

    final SnackBar loadingSnackBar = SnackBar(
      content: const Row(
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          SizedBox(width: 15),
          Text("Mencari UMKM terdekat ..."),
        ],
      ),
      duration: const Duration(seconds: 10),
      backgroundColor: kPrimaryColor,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
    }

    try {
      // 2. Dapatkan posisi pengguna saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLocation = latlng2.LatLng(
        position.latitude,
        position.longitude,
      );

      // 3. Ambil data UMKM terdekat dari Overpass API
      final List<PlaceResult> nearbyUmkm = await _fetchNearbyUmkmFromOverpass(
        userLocation,
      );

      // 4. Update Marker dan Pindahkan peta ke lokasi pengguna
      _updateUmkmMarkers(nearbyUmkm);
      _mapController.move(
        userLocation,
        15.0,
      ); // Menggunakan move() dari MapController OSM

      // 5. Bersihkan SnackBar loading setelah berhasil
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // 6. Tampilkan hasilnya dalam AlertDialog
      if (mounted) {
        _showNearbyUmkmDialog(nearbyUmkm);
      }

      // 7. Perbarui pusat peta
      setState(() {
        _currentMapCenter = userLocation;
      });
    } catch (e) {
      // [PENANGANAN ERROR SAMA]
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal mendapatkan lokasi atau data UMKM. Cek koneksi & Perangkat GPS Anda. Detail: ${e.toString().split(':')[0]}",
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      debugPrint('Error utama: $e');
    }
  }

  // --- FUNGSI UPDATE MARKER (KHUSUS UNTUK FLUTTER MAP) ---
  void _updateUmkmMarkers(List<PlaceResult> umkmList) {
    Set<Marker> newMarkers = {};
    for (var place in umkmList) {
      newMarkers.add(
        Marker(
          point: place.location,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.store_mall_directory,
            color: Colors.green, // UMKM di OSM sering diwakili warna hijau
            size: 35,
          ),
        ),
      );
    }
    setState(() {
      _umkmMarkers = newMarkers;
    });
  }

  // --- WIDGET DIALOG UNTUK MENAMPILKAN HASIL PENCARIAN UMKM (TETAP SAMA) ---
  void _showNearbyUmkmDialog(List<PlaceResult> nearbyUmkm) {
    String title;
    List<Widget> content;

    if (nearbyUmkm.isEmpty) {
      title = '❌ Tidak Ada UMKM Terdekat';
      content = [
        Text(
          'Tidak ditemukan tempat/toko/restoran dalam radius ${_nearbyRadiusMeters} meter.',
          textAlign: TextAlign.center,
        ),
      ];
    } else {
      title = '🎉 Ditemukan ${nearbyUmkm.length} Lokasi Terdekat!';
      content = [
        const Text(
          'Berikut daftar lokasi yang berada dalam radius 500m:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Divider(),
        ...nearbyUmkm
            .map(
              (place) => ListTile(
                dense: true,
                leading: const Icon(Icons.store, color: kAccentColor),
                title: Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${place.distance.toStringAsFixed(0)} m'),
              ),
            )
            .toList(),
      ];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(child: ListBody(children: content)),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI PENCARIAN PRESISI DENGAN NOMINATIM API (PENGGANTI GOOGLE GEOCODING) ---
  void _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
    });

    try {
      final encodedQuery = Uri.encodeComponent(query);

      // URL Nominatim API (format JSON, limit 1 hasil, dan sertakan tag)
      final url = Uri.parse(
        '$_nominatimApiUrl?q=$encodedQuery&format=json&limit=1&addressdetails=1',
      );

      // PENTING: Nominatim memerlukan header User-Agent yang valid.
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

          if (lat != null && lon != null) {
            final newPosition = latlng2.LatLng(lat, lon);

            // Pindahkan kamera peta ke lokasi baru
            _mapController.move(newPosition, 15.0);

            // Dapatkan alamat yang diformat dari Nominatim
            final formattedAddress = locationData['display_name'] ?? query;

            setState(() {
              _currentMapCenter = newPosition;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Pencarian berhasil. Peta berpindah ke: $formattedAddress",
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Format koordinat tidak valid dari Nominatim."),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lokasi tidak ditemukan oleh Nominatim."),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error Nominatim HTTP: ${response.statusCode}"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error Jaringan saat Pencarian: $e"),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    await Future.delayed(_searchDelay);
    setState(() {
      _isSearching = false;
    });
  }

  // --- WIDGET PEMBENTUK (Builder Functions) ---
  Widget _buildMapPicker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Ganti GoogleMap dengan FlutterMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialPosition,
            initialZoom: 15,
            onPositionChanged: (position, hasGesture) {
              if (!_isSearching) {
                // Update pusat peta ketika pengguna menggeser
                setState(() {
                  _currentMapCenter = position.center;
                });
                debugPrint(
                  'Lokasi Terpilih (Tengah Peta): ${_currentMapCenter.latitude}, ${_currentMapCenter.longitude}',
                );
              }
            },
            onMapReady: () {
              // Initial update setelah peta siap
            },
          ),
          children: [
            // 1a. Tile Layer (Tampilan Peta OSM)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.umkm_map_geolocater',
              maxZoom: 18,
            ),

            // 1b. Marker Layer (Menampilkan hasil UMKM terdekat)
            MarkerLayer(markers: _umkmMarkers.toList()),
          ],
        ),

        // 2. Ikon Pin di tengah layar sebagai visual picker
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

  // Fungsi _buildSearchBar dan _buildCustomBottomButton tetap sama

  Widget _buildSearchBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Icon(
                    Icons.store_mall_directory,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                ),

                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari alamat atau lokasi UMKM...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),

                _isSearching
                    ? Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kPrimaryColor,
                          ),
                        ),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.search, color: Colors.grey),
                      onPressed: () => _searchLocation(_searchController.text),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomButton() {
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
                    'Lokasi Dipilih:\nLat: ${_currentMapCenter.latitude.toStringAsFixed(6)}, Lng: ${_currentMapCenter.longitude.toStringAsFixed(6)}',
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: kPrimaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AppsNearby UMKM"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: <Widget>[
          // 1. --- Peta OSM (FlutterMap) ---
          _buildMapPicker(),

          // 2. --- Search Bar Kustom ---
          _buildSearchBar(),

          // 4. --- Tombol Bawah Kustom ("PILIH LOKASI INI") ---
          _buildCustomBottomButton(),
        ],
      ),
    );
  }
}
