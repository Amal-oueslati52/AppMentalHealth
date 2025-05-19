import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/cabinet.dart';
import '../services/cabinet_service.dart';
import 'booking_dialog.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  LatLng? currentLocation;
  List<Cabinet> cabinets = [];
  final CabinetService _cabinetService = CabinetService();
  bool _isLoading = true;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await _loadCabinets();
      await _requestLocationPermission();
      await _goToMyLocation();
    } catch (e) {
      // Continue même si la localisation échoue
      print('Location error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      Flushbar(
        message: message,
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = true);
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = true);
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationError = true);
        throw 'Location permissions are permanently denied';
      }
    } catch (e) {
      _showError('Location permission error: $e');
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
          _locationError = false;
        });
        mapController.move(currentLocation!, 14);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = true);
        _showError('Activez la localisation pour voir votre position');
      }
    }
  }

  Future<void> _loadCabinets() async {
    try {
      setState(() => _isLoading = true);
      final loadedCabinets = await _cabinetService.fetchCabinets();

      if (mounted && loadedCabinets.isNotEmpty) {
        setState(() {
          cabinets = loadedCabinets;
          _isLoading = false;
        });
        _centerMapOnCabinets();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          cabinets = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Afficher le message d'erreur uniquement si aucun cabinet n'a été chargé
        if (cabinets.isEmpty) {
          _showError('Impossible de charger les cabinets');
        }
      }
    }
  }

  LatLng _getMapCenter() {
    if (cabinets.isNotEmpty) {
      // Priorité aux cabinets disponibles
      double avgLat = cabinets.map((c) => c.latitude).reduce((a, b) => a + b) /
          cabinets.length;
      double avgLng = cabinets.map((c) => c.longitude).reduce((a, b) => a + b) /
          cabinets.length;
      return LatLng(avgLat, avgLng);
    }
    if (currentLocation != null) {
      return currentLocation!;
    }
    // Vue par défaut centrée sur la Tunisie
    return LatLng(34.0, 9.0);
  }

  void _centerMapOnCabinets() {
    final center = _getMapCenter();
    mapController.move(center, cabinets.isNotEmpty ? 8 : 6);
  }

  void _showCabinetDetails(Cabinet cabinet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        // Utilisation de Expanded pour le texte
                        child: Text(
                          cabinet.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow:
                              TextOverflow.ellipsis, // Ajout de l'ellipsis
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cabinet.description?.isNotEmpty ?? false)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          width: double
                              .infinity, // Assure que le container prend toute la largeur
                          child: Text(
                            cabinet.description ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      if (cabinet.openTime != null && cabinet.closeTime != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E9F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF8B94CD),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                // Utilisation de Expanded pour le texte
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Horaires d\'ouverture',
                                      style: TextStyle(
                                        color: Color(0xFF8B94CD),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${cabinet.openTime} - ${cabinet.closeTime}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCA88CD).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBookingDialog(cabinet);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Réserver',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(Cabinet cabinet) {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(cabinet: cabinet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rechercher un Cabinet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCA88CD)),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: _getMapCenter(),
                    zoom: 12,
                    minZoom: 4,
                    maxZoom: 18,
                    keepAlive: true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (currentLocation != null)
                          Marker(
                            point: currentLocation!,
                            width: 40,
                            height: 40,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFCA88CD),
                                    Color(0xFF8B94CD)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFCA88CD)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ...cabinets.map(
                          (cabinet) => Marker(
                            point: LatLng(cabinet.latitude, cabinet.longitude),
                            width: 40,
                            height: 40,
                            builder: (context) => GestureDetector(
                              onTap: () => _showCabinetDetails(cabinet),
                              child: Tooltip(
                                message: cabinet.title,
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.teal,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_locationError)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.location_off,
                            color: Color(0xFFCA88CD),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Localisation désactivée',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCA88CD).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _goToMyLocation,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }
}
