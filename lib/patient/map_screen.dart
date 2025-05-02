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
    try {
      await _requestLocationPermission();
      await Future.wait([
        _loadCabinets(),
        _goToMyLocation(),
      ]);
    } catch (e) {
      _showError('Error initializing map: $e');
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
    if (_locationError) return;

    try {
      final Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
        });
        mapController.move(currentLocation!, 14);
      }
    } catch (e) {
      _showError('Error getting location: $e');
    }
  }

  Future<void> _loadCabinets() async {
    try {
      setState(() => _isLoading = true);
      final loadedCabinets = await _cabinetService.fetchCabinets();

      if (mounted) {
        setState(() {
          cabinets = loadedCabinets;
          _isLoading = false;
        });
        _centerMapOnCabinets();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading cabinets: $e');
      }
    }
  }

  LatLng _getMapCenter() {
    if (currentLocation != null) {
      return currentLocation!;
    } else if (cabinets.isNotEmpty) {
      return LatLng(cabinets[0].latitude, cabinets[0].longitude);
    } else {
      return LatLng(36.8, 10.173); // Default to Tunis
    }
  }

  void _centerMapOnCabinets() {
    final center = _getMapCenter();
    mapController.move(center, 12);
  }

  void _showCabinetDetails(Cabinet cabinet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cabinet.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cabinet.description ?? 'No description available'),
            if (cabinet.openTime != null && cabinet.closeTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Hours: ${cabinet.openTime} - ${cabinet.closeTime}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showBookingDialog(cabinet);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: Text('Book'),
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
        title: const Text('Find a Cabinet'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
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
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
