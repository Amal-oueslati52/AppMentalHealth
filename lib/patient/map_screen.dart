import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/cabinet.dart'; // Modèle pour les cabinets
import '../services/cabinet_service.dart'; // Service pour récupérer les cabinets
import 'booking_dialog.dart'; // Dialog pour la réservation (comme dans la version des complexes)

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
      // Centrer la carte sur la première position des cabinets (si disponibles) ou position par défaut
      _centerMapOnCabinets();
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
      // Après le chargement des cabinets, centrer la carte
      _centerMapOnCabinets();
    } catch (e) {
      print('Error loading cabinets: $e');
    }
  }

  // Fonction pour obtenir la position centrale (soit des cabinets, soit par défaut)
  LatLng _getMapCenter() {
    if (cabinets.isNotEmpty) {
      // Centrer sur le premier cabinet
      return LatLng(cabinets[0].latitude, cabinets[0].longitude);
    } else {
      // Position par défaut (ex. Tunis)
      return LatLng(36.8, 10.173);
    }
  }

  // Centrer la carte sur les cabinets
  void _centerMapOnCabinets() {
    if (cabinets.isNotEmpty) {
      final LatLng center = _getMapCenter();
      mapController.move(center, 12); // Centrer et zoomer sur la position du premier cabinet
    } else {
      mapController.move(LatLng(36.8, 10.173), 12); // Position par défaut si aucun cabinet
    }
  }

  // Afficher les détails d'un cabinet et proposer une réservation
  void _showCabinetDetails(Cabinet cabinet) {
    showDialog(
      barrierColor: Colors.black.withOpacity(0.8),
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cabinet.title),
        content: Text(cabinet.description ?? 'No description available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () => _showBookingDialog(cabinet),
            child: Text('Book'), // Option de réservation
          ),
        ],
      ),
    );
  }

  // Afficher le dialog de réservation pour un cabinet
  void _showBookingDialog(Cabinet cabinet) {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(
        cabinet: cabinet, // Passer le cabinet à la dialog de réservation
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
          center: _getMapCenter(), // Centre dynamique basé sur les cabinets ou une position par défaut
          zoom: 12, // Niveau de zoom plus élevé
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
                      message: '${cabinet.title}\n${cabinet.description ?? ""}', // Infobulle
                      child: Icon(
                        Icons.location_on_sharp,
                        color: const Color.fromARGB(255, 16, 116, 78), // Couleur du marqueur
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ).toList(),
              // Ajouter un marqueur à la position par défaut si aucun cabinet
              if (cabinets.isEmpty)
                Marker(
                  point: LatLng(36.8, 10.173), // Position par défaut (Tunis)
                  width: 80,
                  height: 80,
                  builder: (context) => GestureDetector(
                    onTap: () {
                      // Si on veut gérer le clic sur la position par défaut
                    },
                    child: Tooltip(
                      message: 'Default Location', // Infobulle pour la position par défaut
                      child: Icon(
                        Icons.location_on_sharp,
                        color: Colors.red, // Couleur différente pour la position par défaut
                        size: 50,
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