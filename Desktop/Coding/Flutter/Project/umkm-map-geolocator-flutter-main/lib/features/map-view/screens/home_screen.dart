// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// --- OSM/Mapbox Packages ---
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng2;

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
  static const latlng2.LatLng _initialPosition = latlng2.LatLng(
    -6.1650,
    106.7260,
  );

  // final LocationService _locationService = LocationService();
  final OverpassService _overpassService = OverpassService();
  final NominatimService _nominatimService = NominatimService();
  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();

  latlng2.LatLng _currentMapCenter = _initialPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Set<Marker> _umkmMarkers = {};
  List<latlng2.LatLng> _routePolyline = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocationAndShowNearbyUmkm();
    });
  }

  void _navigateToPlace(PlaceResult destination) async {
    if (!mounted) return;
    Navigator.of(context).pop();
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

  Future<void> _getCurrentLocationAndShowNearbyUmkm() async {
    final SnackBar loadingSnackBar = SnackBar(
      content: const Row(
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          SizedBox(width: 15),
          Text("Mencari lokasi dan UMKM terdekat..."),
        ],
      ),
      duration: const Duration(seconds: 10),
      backgroundColor: kPrimaryColor,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(loadingSnackBar);
    }
    try {
      final Position position = await _locationService.getCurrentLocation();
      // TEST PAKE COORDINAT ITPLN
      // final lat = -6.1650;
      // final long = 106.7260;
      final userLocation = latlng2.LatLng(
        position.latitude,
        position.longitude,
      );
      // final userLocation = latlng2.LatLng(lat, long);
      final List<PlaceResult> nearbyUmkm = await _overpassService
          .fetchNearbyUmkm(userLocation);
      _updateUmkmMarkers(nearbyUmkm);
      _mapController.move(userLocation, 15.0);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showNearbyUmkmDialog(nearbyUmkm);
      }
      setState(() {
        _currentMapCenter = userLocation;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal: ${e.toString().split(':')[0]}. Cek koneksi atau izin lokasi.",
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      debugPrint('Error utama: $e');
      if (mounted) {
        _mapController.move(_initialPosition, 10.0);
        setState(() {
          _currentMapCenter = _initialPosition;
        });
      }
    }
  }

  void _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
    });
    try {
      final NominatimResult? result = await _nominatimService.searchLocation(
        query,
      );
      if (result != null) {
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
    Set<Marker> newMarkers = {};
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

  void _showNearbyUmkmDialog(List<PlaceResult> nearbyUmkm) {
    String title;
    List<Widget> content;

    if (nearbyUmkm.isEmpty) {
      title = '❌ Tidak Ada UMKM Terdekat';
      content = [
        Text(
          'Tidak ditemukan tempat/toko/restoran dalam radius $_nearbyRadiusMeters meter.',
          textAlign: TextAlign.center,
        ),
      ];
    } else {
      title = '🎉 Ditemukan ${nearbyUmkm.length} Lokasi Terdekat!';
      content = [
        const Text(
          'Ketuk lokasi untuk melihat rute dari lokasi Anda:', // 💡 Instruksi Baru
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
            onTap: () => _navigateToPlace(place),
            trailing: const Icon(Icons.route, color: kPrimaryColor),
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
          MapSearchBar(
            searchController: _searchController,
            onSearchSubmitted: _searchLocation,
          ),
          SelectLocationButton(
            currentMapCenter: _currentMapCenter,
            primaryColor: kPrimaryColor,
          ),
          Positioned(
            bottom: 170,
            right: 20,
            child: FloatingActionButton(
              onPressed: _getCurrentLocationAndShowNearbyUmkm,
              backgroundColor: kPrimaryColor,
              child: const Icon(Icons.gps_fixed, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
