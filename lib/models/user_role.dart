enum UserRole {
  patient('PATIENT'),
  doctor('DOCTOR');

  final String value;
  const UserRole(this.value);

  @override
  String toString() => value;
}
