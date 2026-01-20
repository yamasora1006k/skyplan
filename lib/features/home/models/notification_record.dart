/// 通知記録モデル
class NotificationRecord {
  final String id;
  final DateTime scheduledAt;
  final DateTime? firedAt;
  final String title;
  final String body;
  final String? relatedCardId;
  final Map<String, dynamic> reasonJson;

  const NotificationRecord({
    required this.id,
    required this.scheduledAt,
    this.firedAt,
    required this.title,
    required this.body,
    this.relatedCardId,
    required this.reasonJson,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) {
    return NotificationRecord(
      id: json['id'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      firedAt:
          json['firedAt'] != null ? DateTime.parse(json['firedAt'] as String) : null,
      title: json['title'] as String,
      body: json['body'] as String,
      relatedCardId: json['relatedCardId'] as String?,
      reasonJson: json['reasonJson'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledAt': scheduledAt.toIso8601String(),
      'firedAt': firedAt?.toIso8601String(),
      'title': title,
      'body': body,
      'relatedCardId': relatedCardId,
      'reasonJson': reasonJson,
    };
  }

  /// 通知タイプを取得
  String get notificationType {
    if (reasonJson.containsKey('morning')) return 'morning';
    if (reasonJson.containsKey('event')) return 'event';
    if (reasonJson.containsKey('weather')) return 'weather';
    return 'general';
  }

  /// 通知アイコンを取得
  String get icon {
    switch (notificationType) {
      case 'morning':
        return '🌅';
      case 'event':
        return '📅';
      case 'weather':
        return '🌤️';
      default:
        return '🔔';
    }
  }
}
