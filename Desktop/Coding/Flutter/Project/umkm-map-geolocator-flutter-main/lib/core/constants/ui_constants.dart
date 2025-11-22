// --- KONSTANTA DESAIN & API ---
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:umkm_map_geolocater/core/models/place_result.dart';
import 'package:latlong2/latlong.dart' as latlng2;

const Color kPrimaryColor = Color(0xFF1E88E5); // Biru
const Color kAccentColor = Color(0xFFFFC107); // Kuning/Amber

// Placeholder for the single, selected place (Warteg Karisma)
final PlaceResult _mockSelectedWarteg = PlaceResult(
  'Warteg Karisma',
  // Use coordinates near the displayed area (Duri Kosambi)
  const latlng2.LatLng(-6.1670, 106.7265),
  250, // Mock distance
);

// New marker for the mock selected Warteg
final Marker _wartegKarismaMarker = Marker(
  point: _mockSelectedWarteg.location,
  width: 80,
  height: 80,
  child: const Icon(
    Icons.location_on,
    color: Colors.red, // Highlighted marker
    size: 40,
  ),
);
