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
        title: const Text('Créer un Cabinet',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8E9F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Nom du Cabinet',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _openTimeController,
                        label: 'Heure d\'ouverture',
                        icon: Icons.access_time,
                        readOnly: true,
                        onTap: () => _selectTime(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _closeTimeController,
                        label: 'Heure de fermeture',
                        icon: Icons.access_time,
                        readOnly: true,
                        onTap: () => _selectTime(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCA88CD).withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: _selectedLocation ??  LatLng(36.8, 10.173),
                            zoom: 13.0,
                            onTap: (tapPosition, point) {
                              setState(() => _selectedLocation = point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            if (_selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    width: 80,
                                    height: 80,
                                    builder: (context) => const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFCA88CD),
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
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: FloatingActionButton(
                              onPressed: _getCurrentLocation,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: const Icon(Icons.my_location, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Position: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: Color(0xFF8B94CD),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                _buildGradientButton(
                  onPressed: _isLoading ? null : _createCabinet,
                  label: 'Créer le Cabinet',
                  icon: Icons.add_business,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA88CD).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF8B94CD)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Ce champ est requis' : null,
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? [Colors.grey, Colors.grey]
              : [const Color(0xFFCA88CD), const Color(0xFF8B94CD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA88CD).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
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
