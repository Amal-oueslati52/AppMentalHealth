import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import '../services/doctor_cabinet_service.dart';
import '../services/strapi_auth_service.dart';
import '../user_provider.dart';

class CreateCabinetScreen extends StatefulWidget {
  @override
  _CreateCabinetScreenState createState() => _CreateCabinetScreenState();
}

class _CreateCabinetScreenState extends State<CreateCabinetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openTimeController = TextEditingController();
  final _closeTimeController = TextEditingController();
  final DoctorCabinetService _cabinetService = DoctorCabinetService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation!, 15.0);
      });
    } catch (e) {
      _logger.e('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpenTime) {
          _openTimeController.text = formattedTime;
        } else {
          _closeTimeController.text = formattedTime;
        }
      });
    }
  }

  Future<void> _createCabinet() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Veuillez remplir tous les champs et sélectionner un emplacement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (UserProvider.user == null) {
        throw Exception('Veuillez vous connecter d\'abord');
      }

      final userData = await _authService.getCompleteUserData();
      _logger.d('User data received: ${userData.doctor}');

      // Utiliser le documentId du docteur au lieu de l'id
      final doctorDocumentId = userData.doctor?['documentId'];
      if (doctorDocumentId == null) {
        throw Exception('DocumentId du docteur non trouvé');
      }

      final openingTime = "${_openTimeController.text}:00.000";
      final closingTime = "${_closeTimeController.text}:00.000";

      await _cabinetService.createCabinet(
        title: _titleController.text,
        description: _descriptionController.text,
        openTime: openingTime,
        closeTime: closingTime,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        doctorId: doctorDocumentId, // Passage du documentId
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cabinet créé avec succès')),
        );
      }
    } catch (e) {
      _logger.e('Error creating cabinet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du cabinet: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un Cabinet'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Nom du Cabinet',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openTimeController,
                      decoration: InputDecoration(
                        labelText: 'Heure d\'ouverture',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context, true),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ce champ est requis' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _closeTimeController,
                      decoration: InputDecoration(
                        labelText: 'Heure de fermeture',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(context, false),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ce champ est requis' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                height: 300,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _selectedLocation ?? LatLng(36.8, 10.173),
                        zoom: 13.0,
                        onTap: (tapPosition, point) {
                          setState(() => _selectedLocation = point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 80,
                                height: 80,
                                builder: (context) => Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        onPressed: _getCurrentLocation,
                        child: Icon(Icons.my_location),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (_selectedLocation != null)
                Text(
                  'Position sélectionnée: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _createCabinet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Créer le Cabinet', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    super.dispose();
  }
}
