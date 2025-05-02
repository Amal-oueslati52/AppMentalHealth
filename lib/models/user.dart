class User {
  final int id;
  final String email;
  final String name;
  final String roleType;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? patient;
  final String? genre;
  final String? age;
  final String? objectif;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.roleType,
    this.doctor,
    this.patient,
    this.genre,
    this.age,
    this.objectif,
    String? speciality,
    String? birthdate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final roleType = (json['roleType'] ?? 'PATIENT').toString().toUpperCase();
    final doctor = json['doctor'];

    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      roleType: roleType,
      doctor: doctor is Map ? Map<String, dynamic>.from(doctor) : null,
      patient: json['patient'],
      genre: json['genre'],
      age: json['age']?.toString(),
      objectif: json['objectif'],
    );
  }

  bool get isApproved {
    if (roleType != 'DOCTOR') return true;
    if (doctor == null) return false;
    return doctor?['isApproved'] ?? false;
  }

  bool get isProfileComplete =>
      roleType == 'DOCTOR' ? doctor != null : patient != null;

  String? get speciality => doctor?['speciality'];
  String? get birthdate => patient?['birthdate'];
  
  // Updated getter to access the doctor ID correctly
  String? get doctorId => doctor?['id']?.toString();

  // New getter for document ID
  String? get documentId => doctor?['documentId']?.toString();
}
