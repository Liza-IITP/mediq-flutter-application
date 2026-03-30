class Clinic {
  final String id;
  final String name;

  Clinic({required this.id, required this.name});

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
