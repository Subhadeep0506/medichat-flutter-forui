class AppUser {
  final String id; // maps to user_id
  final String? name;
  final String email;
  final String? accessToken;
  final String? refreshToken;
  final String? phone;
  final String? role;
  final DateTime? createdAt; // optional b/c backend returns string iso
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.accessToken,
    this.refreshToken,
    this.phone,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? accessToken,
    String? refreshToken,
    String? phone,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    phone: phone ?? this.phone,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory AppUser.fromJson(
    Map<String, dynamic> json, {
    String? accessToken,
    String? refreshToken,
  }) {
    return AppUser(
      id: json['user_id'] ?? json['id'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'],
      accessToken: accessToken,
      refreshToken: refreshToken,
      createdAt: _tryParseDate(json['time_created']),
      updatedAt: _tryParseDate(json['time_updated']),
    );
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'time_created': createdAt?.toIso8601String(),
    'time_updated': updatedAt?.toIso8601String(),
  };
}
