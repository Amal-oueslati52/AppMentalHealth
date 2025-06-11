import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/cabinet.dart';
import '../services/cabinet_service.dart';
import 'booking_dialog.dart';

// Constantes de l'application
const Duration kFlushbarDuration = Duration(seconds: 3);
const double kDefaultZoom = 12.0;
const double kMinZoom = 4.0;
const double kDetailedZoom = 14.0;
final kDefaultCenter = LatLng(34.0, 9.0); // Centre de la Tunisie

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final CabinetService _cabinetService = CabinetService();

  LatLng? _currentLocation;
  List<Cabinet> _cabinets = [];
  bool _isLoading = true;
  bool _locationError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadCabinets(),
        _initializeLocation(),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeLocation() async {
    try {
      await _requestLocationPermission();
      await _goToMyLocation();
    } catch (e) {
      debugPrint('Location initialization error: $e');
      _showError('Erreur de localisation: veuillez activer la localisation');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Les services de localisation sont désactivés';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Les permissions de localisation sont refusées';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Les permissions de localisation sont définitivement refusées';
      }

      setState(() => _locationError = false);
    } catch (e) {
      setState(() => _locationError = true);
      rethrow;
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationError = false;
      });

      _mapController.move(_currentLocation!, kDetailedZoom);
    } catch (e) {
      setState(() => _locationError = true);
      _showError('Activez la localisation pour voir votre position');
    }
  }

  Future<void> _loadCabinets() async {
    try {
      final loadedCabinets = await _cabinetService.fetchCabinets();
      if (!mounted) return;

      setState(() {
        _cabinets = loadedCabinets;
        _isLoading = false;
      });

      if (_cabinets.isNotEmpty) {
        _centerMapOnCabinets();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (_cabinets.isEmpty) {
        _showError('Impossible de charger les cabinets');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Flushbar(
      message: message,
      duration: kFlushbarDuration,
      backgroundColor: Colors.red,
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  LatLng _getMapCenter() {
    if (_cabinets.isNotEmpty) {
      return _calculateCabinetsCenter();
    }
    return _currentLocation ?? kDefaultCenter;
  }

  LatLng _calculateCabinetsCenter() {
    final avgLat = _cabinets.map((c) => c.latitude).reduce((a, b) => a + b) /
        _cabinets.length;
    final avgLng = _cabinets.map((c) => c.longitude).reduce((a, b) => a + b) /
        _cabinets.length;
    return LatLng(avgLat, avgLng);
  }

  void _centerMapOnCabinets() {
    if (!mounted) return;
    final center = _getMapCenter();
    _mapController.move(center, _cabinets.isNotEmpty ? kDefaultZoom : kMinZoom);
  }

  void _showCabinetDetails(Cabinet cabinet) {
    showDialog(
      context: context,
      builder: (context) => _CabinetDetailsDialog(
        cabinet: cabinet,
        onBooking: () => _showBookingDialog(cabinet),
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
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildLocationButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCA88CD)),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _getMapCenter(),
            zoom: kDefaultZoom,
            minZoom: kMinZoom,
            onMapReady: () {
              if (!mounted) return;
              _centerMapOnCabinets();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCA88CD).withAlpha(76),
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
                ..._cabinets.map(
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
        if (_locationError) _buildLocationError(),
      ],
    );
  }

  Widget _buildLocationError() {
    return const Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Activez la localisation pour voir votre position',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA88CD).withAlpha(76),
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
    );
  }
}

class _CabinetDetailsDialog extends StatelessWidget {
  final Cabinet cabinet;
  final VoidCallback onBooking;
  const _CabinetDetailsDialog({
    required this.cabinet,
    required this.onBooking,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
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
                      overflow: TextOverflow.ellipsis, // Ajout de l'ellipsis
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        _BookingButton(onPressed: () {
          Navigator.pop(context);
          onBooking();
        }),
      ],
    );
  }
}

class _BookingButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BookingButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }
}
