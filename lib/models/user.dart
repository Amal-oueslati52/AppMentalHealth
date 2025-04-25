class User {
  final int id;
  final String email;
  final String name;
  final String genre;
  final String age;
  final String objectif;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.genre,
    required this.age,
    required this.objectif,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      age: json['age']?.toString() ?? '',  // Ensure age is always a string
      objectif: json['objectif']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'genre': genre,
      'age': age,
      'objectif': objectif,
    };
  }
}
