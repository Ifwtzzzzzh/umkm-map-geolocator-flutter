import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchSubmitted;

  const MapSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context) {
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
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Warteg',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                  onPressed: () {},
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
              ),
              onSubmitted: (query) {
                onSearchSubmitted(query);
                // Menampilkan snackbar untuk aksi pencarian sederhana
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Mencari: $query')));
              },
            ),
          ),
        ),
      ),
    );
  }
}
