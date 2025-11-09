class Patient {
  final String id; // patient_id
  final String name;
  final int? age;
  final String? gender;
  final String? dob;
  final String? height;
  final String? weight;
  final String? medicalHistory;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Patient({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.dob,
    this.height,
    this.weight,
    this.medicalHistory,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  Patient copyWith({
    String? name,
    int? age,
    String? gender,
    String? dob,
    String? height,
    String? weight,
    String? medicalHistory,
    List<String>? tags,
    DateTime? updatedAt,
  }) => Patient(
    id: id,
    name: name ?? this.name,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    dob: dob ?? this.dob,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    medicalHistory: medicalHistory ?? this.medicalHistory,
    tags: tags ?? this.tags,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['patient_id'] ?? json['id'],
    name: json['name'] ?? '',
    age: json['age'],
    gender: json['gender'],
    dob: json['dob'],
    height: json['height'],
    weight: json['weight'],
    medicalHistory: json['medical_history'],
    tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    createdAt: _parse(json['time_created']),
    updatedAt: _parse(json['time_updated']),
  );

  Map<String, dynamic> toJson() => {
    'patient_id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'dob': dob,
    'height': height,
    'weight': weight,
    'medical_history': medicalHistory,
    'tags': tags,
    'time_created': createdAt?.toIso8601String(),
    'time_updated': updatedAt?.toIso8601String(),
  };

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
