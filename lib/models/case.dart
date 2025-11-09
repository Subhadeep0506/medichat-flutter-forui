class MedicalCase {
  final String id; // case_id
  final String patientId;
  final String title; // case_name
  final String description;
  final List<String>? tags;
  final String? priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalCase({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    this.tags,
    this.priority,
    this.createdAt,
    this.updatedAt,
  });

  MedicalCase copyWith({
    String? title,
    String? description,
    List<String>? tags,
    String? priority,
    DateTime? updatedAt,
  }) => MedicalCase(
    id: id,
    patientId: patientId,
    title: title!,
    description: description ?? this.description,
    tags: tags ?? this.tags,
    priority: priority ?? this.priority,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory MedicalCase.fromJson(Map<String, dynamic> json) => MedicalCase(
    id: json['case_id'] ?? json['id'],
    patientId: json['patient_id'] ?? '',
    title: json['case_name'] ?? json['name'] ?? '',
    description: json['description'] ?? '',
    tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
    priority: json['priority'],
    createdAt: _parse(json['time_created']),
    updatedAt: _parse(json['time_updated']),
  );

  Map<String, dynamic> toJson() => {
    'case_id': id,
    'patient_id': patientId,
    'case_name': title,
    'description': description,
    'tags': tags,
    'priority': priority,
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
