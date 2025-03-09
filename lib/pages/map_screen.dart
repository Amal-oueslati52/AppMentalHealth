import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/cabinet.dart'; // 
import '../services/cabinet_service.dart'; 

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController mapController = MapController();
  LatLng? currentLocation;
  List<Cabinet> cabinets = []; 
  final CabinetService _cabinetService = CabinetService(); // Service pour charger les cabinets

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // Demander la permission de localisation
    _loadCabinets(); // Charger les cabinets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _goToMyLocation(); // Optionnel : Aller à la position de l'utilisateur après le chargement
    });
  }

  // Demander la permission de localisation
  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
  }

  // Aller à la position de l'utilisateur
  Future<void> _goToMyLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      mapController.move(currentLocation!, 14); // Centrer la carte sur la position de l'utilisateur
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Charger les cabinets depuis le service
  Future<void> _loadCabinets() async {
    try {
      final loadedCabinets = await _cabinetService.fetchCabinets();
      setState(() {
        cabinets = loadedCabinets;
      });
    } catch (e) {
      print('Error loading cabinets: $e');
    }
  }

  // Afficher les détails d'un cabinet
  void _showCabinetDetails(Cabinet cabinet) {
    showDialog(
      barrierColor: Colors.black.withOpacity(0.8),
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cabinet.name),
        content: Text(cabinet.description ?? 'No description available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cabinets Map')), // Titre de l'écran
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: LatLng(0, 0), // Centre initial de la carte
          zoom: 2, // Niveau de zoom initial
        ),
        children: [
          // Couche des tuiles (carte)
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'], // Sous-domaines pour les tuiles
            userAgentPackageName: 'com.example.app',
            tileProvider: NetworkTileProvider(),
            maxZoom: 19,
            keepBuffer: 5, // Améliorer les performances
          ),
          // Couche des marqueurs
          MarkerLayer(
            markers: [
              // Marqueur pour la position de l'utilisateur
              if (currentLocation != null)
                Marker(
                  point: currentLocation!,
                  width: 80,
                  height: 80,
                  builder: (context) => Icon(
                    Icons.my_location_rounded,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              // Marqueurs pour les cabinets
              ...cabinets.map(
                (cabinet) => Marker(
                  point: LatLng(cabinet.latitude, cabinet.longitude),
                  width: 80,
                  height: 80,
                  builder: (context) => GestureDetector(
                    onTap: () => _showCabinetDetails(cabinet), // Afficher les détails du cabinet
                    child: Tooltip(
                      message: '${cabinet.name}\n${cabinet.description ?? ""}', // Infobulle
                      child: Icon(
                        Icons.location_on_sharp,
                        color: const Color.fromARGB(255, 16, 116, 78), // Couleur du marqueur
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // Bouton pour aller à la position de l'utilisateur
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}