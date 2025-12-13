import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/constants/city_constants.dart';
import 'package:travel_hackathon/core/services/city_service.dart';

class CitySearchSheet extends StatefulWidget {
  final Function(String) onCitySelected;
  const CitySearchSheet({super.key, required this.onCitySelected});

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allCities = [];
  List<String> _filteredCities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCities() async {
    final cities = await CityService().getIndianCities();
    if (mounted) {
      setState(() {
        _allCities = cities;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _allCities
          .where((city) => city.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.isNotEmpty;
    final displayCities = isSearching ? _filteredCities : kSupportedCities.map((c) => c['name'] as String).toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search city...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey[200]),
          if (_isLoading && isSearching)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: displayCities.length,
              itemBuilder: (context, index) {
                final cityName = displayCities[index];
                final isPopular = !isSearching;
                return ListTile(
                  leading: Icon(
                    isPopular ? Icons.star : Icons.location_city,
                    color: isPopular ? Colors.amber : Colors.grey,
                  ),
                  title: Text(cityName, style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: isPopular ? FontWeight.bold : FontWeight.normal,
                  )),
                  subtitle: isPopular ? const Text('Popular Destination') : null,
                  onTap: () => widget.onCitySelected(cityName),
                );
              },
            ),
          ),
          if (isSearching && _filteredCities.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No cities found', style: GoogleFonts.lato(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
