class ChatSession {
  final String id;
  final String caseId;
  final String title; // Possibly first user prompt or custom
  final DateTime createdAt;

  const ChatSession({
    required this.id,
    required this.caseId,
    required this.title,
    required this.createdAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    caseId: json['caseId'] as String? ?? json['case_id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    createdAt:
        DateTime.tryParse(
          json['createdAt'] as String? ?? json['time_created'] as String? ?? '',
        ) ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseId': caseId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
  };
}
