// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// --- OSM/Mapbox Packages ---
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng2;

// Import yang diperlukan (Asumsi file-file ini sudah benar)
import 'package:umkm_map_geolocater/core/constants/coordinate_constants.dart';
import 'package:umkm_map_geolocater/core/constants/ui_constants.dart';
import 'package:umkm_map_geolocater/core/models/place_result.dart';
import 'package:umkm_map_geolocater/features/map-view/services/location_service.dart';
import 'package:umkm_map_geolocater/features/map-view/services/nominatim_service.dart';
import 'package:umkm_map_geolocater/features/map-view/services/overpass_service.dart';
import 'package:umkm_map_geolocater/features/map-view/services/routing_service.dart';
import 'package:umkm_map_geolocater/features/map-view/widgets/map_picker_widget.dart';
import 'package:umkm_map_geolocater/features/map-view/widgets/map_search_bar.dart';
import 'package:umkm_map_geolocater/features/map-view/widgets/select_location_button.dart';

const int _nearbyRadiusMeters = 500;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final CoordinateConstants _firstUmkm = coordinateData.first;

  static final latlng2.LatLng _initialPosition = latlng2.LatLng(
    _firstUmkm.latitude,
    _firstUmkm.longitude,
  );

  final OverpassService _overpassService = OverpassService();
  final NominatimService _nominatimService = NominatimService();
  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();

  bool _isMapInitialized = false;

  late latlng2.LatLng _currentMapCenter;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Set<Marker> _umkmMarkers = {};
  List<latlng2.LatLng> _routePolyline = [];

  @override
  void initState() {
    super.initState();
    _currentMapCenter = _initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDefaultUmkmMarkers();
    });
  }

  // LOGIKA KEMBALI KE LIST SCREEN
  void _backToUmkmList() {
    setState(() {
      _isMapInitialized = false;
      // Hanya pertahankan marker UMKM default (warna ungu)
      _umkmMarkers =
          _umkmMarkers
              .where(
                (marker) =>
                    marker.child is GestureDetector &&
                    (marker.child as GestureDetector).child is Icon &&
                    ((marker.child as GestureDetector).child as Icon).color ==
                        const Color.fromARGB(255, 172, 85, 237),
              )
              .toSet();
      _routePolyline = [];
    });
  }

  // MARKER LOGIC
  void _updateDefaultUmkmMarkers() {
    Set<Marker> defaultUmkmMarkers = {};
    for (var umkm in coordinateData) {
      defaultUmkmMarkers.add(
        Marker(
          point: latlng2.LatLng(umkm.latitude, umkm.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              _handleUmkmSelection(umkm);
            },
            child: const Icon(
              Icons.storefront,
              color: Color.fromARGB(255, 172, 85, 237),
              size: 40,
            ),
          ),
        ),
      );
    }
    setState(() {
      _umkmMarkers = defaultUmkmMarkers;
    });
  }

  // HANDLER UTAMA: Dipanggil dari daftar atau marker di peta
  void _handleUmkmSelection(CoordinateConstants selectedUmkm) {
    if (!_isMapInitialized) {
      setState(() {
        _isMapInitialized = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _mapController.move(
          latlng2.LatLng(selectedUmkm.latitude, selectedUmkm.longitude),
          16.0,
        );
      });
    } else {
      _mapController.move(
        latlng2.LatLng(selectedUmkm.latitude, selectedUmkm.longitude),
        16.0,
      );
    }

    _findNearbyUmkmFromLocation(
      latlng2.LatLng(selectedUmkm.latitude, selectedUmkm.longitude),
      selectedUmkm.nama,
    );
  }

  // FUNGSI PENCARIAN FLEKSIBEL (UMKM OVERPASS)
  Future<void> _findNearbyUmkmFromLocation(
    latlng2.LatLng searchLocation,
    String sourceName,
  ) async {
    final SnackBar loadingSnackBar = SnackBar(
      content: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Mencari UMKM Overpass terdekat dari $sourceName...",
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      duration: const Duration(minutes: 5),
      backgroundColor: kPrimaryColor,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
    }

    try {
      final List<PlaceResult> nearbyUmkm = await _overpassService
          .fetchNearbyUmkm(searchLocation);

      _updateUmkmMarkers(nearbyUmkm);
      _mapController.move(searchLocation, 15.0);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showNearbyUmkmDialog(nearbyUmkm);
      }
      setState(() {
        _currentMapCenter = searchLocation;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal mencari UMKM Overpass: ${e.toString().split(':')[0]}. Cek koneksi atau izin.",
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      debugPrint('Error utama: $e');
      if (mounted) {
        _mapController.move(_currentMapCenter, 10.0);
      }
    }
  }

  // --- START: FUNGSI PENCARIAN ---

  // 1. FUNGSI UNTUK MENCARI DARI PUSAT PETA (DIGUNAKAN OLEH TOMBOL 'PILIH LOKASI INI' dan TOMBOL GPS)
  Future<void> _searchNearbyUmkmFromMapCenter() async {
    if (!_isMapInitialized) {
      setState(() {
        _isMapInitialized = true;
      });
    }

    try {
      final searchLocation = _currentMapCenter;

      // Reverse Geocode untuk mendapatkan nama lokasi pusat peta.
      final nominatimResult = await _nominatimService.reverseGeocode(
        searchLocation.latitude,
        searchLocation.longitude,
      );

      final String sourceName =
          nominatimResult?.formattedAddress ?? "Pusat Peta";

      _findNearbyUmkmFromLocation(searchLocation, sourceName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal mencari UMKM dari Peta: ${e.toString().split(':')[0]}. Cek koneksi.",
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      debugPrint('Error Map Center: $e');
    }
  }

  // Catatan: Fungsi _handleSelectMapCenterLocation yang duplikat telah dihapus.

  // --- END: FUNGSI PENCARIAN ---

  // FUNGSI LAINNYA
  void _navigateToPlace(PlaceResult destination) async {
    if (!mounted) return;
    setState(() {
      _routePolyline = [];
    });
    try {
      final position = await _locationService.getCurrentLocation();
      final userLocation = latlng2.LatLng(
        position.latitude,
        position.longitude,
      );
      final List<latlng2.LatLng> route = await _routingService.getRoute(
        userLocation,
        destination.location,
      );
      if (route.isNotEmpty) {
        setState(() {
          _routePolyline = route;
        });
        final bounds = LatLngBounds.fromPoints(route);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(
              top: 100,
              bottom: 200,
              left: 50,
              right: 50,
            ),
          ),
        );
      } else {
        _mapController.move(destination.location, 16.0);
      }
      setState(() {
        _currentMapCenter = destination.location;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Rute ke ${destination.name} berhasil dibuat!"),
            duration: const Duration(seconds: 4),
            backgroundColor: kAccentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal membuat rute: ${e.toString().split(':')[0]}. Pastikan koneksi internet aktif.",
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
    });
    try {
      final result = await _nominatimService.searchLocation(query);
      if (result != null) {
        if (!_isMapInitialized) {
          setState(() {
            _isMapInitialized = true;
          });
        }
        _mapController.move(result.location, 15.0);
        setState(() {
          _currentMapCenter = result.location;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Pencarian berhasil. Peta berpindah ke: ${result.formattedAddress}",
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lokasi tidak ditemukan."),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error Pencarian: ${e.toString().split(':')[0]}"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
    setState(() {
      _isSearching = false;
    });
  }

  void _updateUmkmMarkers(List<PlaceResult> umkmList) {
    Set<Marker> newMarkers = Set.from(
      _umkmMarkers.where(
        (marker) =>
            marker.child is GestureDetector &&
            (marker.child as GestureDetector).child is Icon &&
            ((marker.child as GestureDetector).child as Icon).color ==
                const Color.fromARGB(255, 172, 85, 237),
      ),
    );

    for (var place in umkmList) {
      newMarkers.add(
        Marker(
          point: place.location,
          width: 80,
          height: 80,
          child: const Icon(
            Icons.store_mall_directory,
            color: Colors.blue,
            size: 35,
          ),
        ),
      );
    }
    setState(() {
      _umkmMarkers = newMarkers;
    });
  }

  // // HANDLER UTAMA: Dipanggil dari daftar atau marker di peta
  // void _handleUmkmSelection(CoordinateConstants selectedUmkm) {
  //   if (!_isMapInitialized) {
  //     setState(() {
  //       _isMapInitialized = true;
  //     });
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       _mapController.move(
  //         latlng2.LatLng(selectedUmkm.latitude, selectedUmkm.longitude),
  //         16.0,
  //       );
  //     });
  //   } else {
  //     _mapController.move(
  //       latlng2.LatLng(selectedUmkm.latitude, selectedUmkm.longitude),
  //       16.0,
  //     );
  //   }

  //   _findNearbyUmkmFromLocation(
  //     latlng2.LatLng(selectedUmkm.latitude, selectedUmkm.longitude),
  //     selectedUmkm.nama,
  //   );
  // }

  // FUNGSI BARU: Menampilkan detail minimal POI Overpass (nama dan jarak)
  void _showPlaceDetailDialog(PlaceResult place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            place.name,
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const Text(
                  'Deskripsi Lokasi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Text(
                  'Jenis Lokasi: ${place.name}',
                ), // Menggunakan nama sebagai deskripsi
                Text('Jarak: ${place.distance.toStringAsFixed(0)} meter'),
                const SizedBox(height: 10),
                const Text('Koordinat:'),
                Text(
                  '${place.location.latitude.toStringAsFixed(5)}, ${place.location.longitude.toStringAsFixed(5)}',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Lihat Rute',
                style: TextStyle(
                  color: kAccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog detail
                _navigateToPlace(place); // Lanjutkan ke navigasi rute
              },
            ),
            TextButton(
              child: const Text(
                'Tutup',
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

  // MODIFIKASI: _showNearbyUmkmDialog
  void _showNearbyUmkmDialog(List<PlaceResult> nearbyUmkm) {
    String title;
    List<Widget> content;

    if (nearbyUmkm.isEmpty) {
      title = '❌ Tidak Ada UMKM Terdekat (Overpass)';
      content = [
        Text(
          'Tidak ditemukan tempat/toko/restoran OpenStreetMap dalam radius $_nearbyRadiusMeters meter.',
          textAlign: TextAlign.center,
        ),
      ];
    } else {
      title = '🎉 Ditemukan ${nearbyUmkm.length} Lokasi Terdekat!';
      content = [
        const Text(
          'Ketuk lokasi untuk melihat deskripsi dan rute:', // <--- INSTRUKSI BARU
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Divider(),
        ...nearbyUmkm.map(
          (place) => ListTile(
            dense: true,
            leading: const Icon(Icons.store, color: kAccentColor),
            title: Text(
              place.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${place.distance.toStringAsFixed(0)} m'),

            // AKSI UTAMA: Pindah ke dialog deskripsi/detail
            onTap: () {
              Navigator.of(context).pop(); // Tutup dialog utama
              _showPlaceDetailDialog(place); // Tampilkan dialog deskripsi
            },

            // Tombol Rute: Tetap sebagai aksi sekunder/terpisah
            trailing: IconButton(
              icon: const Icon(Icons.route, color: kPrimaryColor),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog utama
                _navigateToPlace(place); // Langsung ke navigasi rute
              },
            ),
          ),
        ),
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
            style: const TextStyle(
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

  // WIDGET UTAMA (Screen 1: List UMKM)
  Widget _buildUmkmListScreen() {
    return ListView.builder(
      itemCount: coordinateData.length,
      itemBuilder: (context, index) {
        final umkm = coordinateData[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: const Icon(
              Icons.storefront,
              color: kPrimaryColor,
              size: 30,
            ),
            title: Text(
              umkm.nama,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(umkm.produk),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _handleUmkmSelection(umkm);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMapInitialized ? "Peta Lokasi UMKM" : "AppsNearby UMKM"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        leading:
            _isMapInitialized
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToUmkmList,
                )
                : null,
      ),
      // Conditional Rendering: Tampilkan Daftar (Screen 1) jika belum diinisialisasi, Tampilkan Peta (Screen 2) jika sudah.
      body:
          !_isMapInitialized
              ? _buildUmkmListScreen()
              : Stack(
                children: <Widget>[
                  MapPickerWidget(
                    mapController: _mapController,
                    initialPosition: _currentMapCenter,
                    umkmMarkers: _umkmMarkers,
                    isSearching: _isSearching,
                    routePolyline: _routePolyline,
                    onPositionUpdate: (newCenter) {
                      setState(() {
                        _currentMapCenter = newCenter;
                      });
                    },
                  ),
                  // MapSearchBar harus berada di bagian atas
                  MapSearchBar(
                    searchController: _searchController,
                    onSearchSubmitted: _searchLocation,
                  ),

                  // Positioned( ... )
                  // SelectLocationButton ditempatkan di bagian bawah
                  Positioned(
                    bottom: 10, // Memberi jarak dari bottom agar tidak overflow
                    left: 20,
                    right: 20,
                    child: SelectLocationButton(
                      currentMapCenter: _currentMapCenter,
                      primaryColor: kPrimaryColor,
                      // ✅ Menggunakan fungsi pusat peta (seperti yang diminta untuk marker)
                      onSelectLocation: _searchNearbyUmkmFromMapCenter,
                    ),
                  ),
                ],
              ),
    );
  }
}
