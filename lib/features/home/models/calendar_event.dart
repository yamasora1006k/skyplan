/// カレンダーイベントモデル
class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final double? lat;
  final double? lng;
  final String? locationName;
  final List<String> tags;
  final bool isOutdoor;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.lat,
    this.lng,
    this.locationName,
    this.tags = const [],
    this.isOutdoor = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
      locationName: json['locationName'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isOutdoor: json['isOutdoor'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'locationName': locationName,
      'tags': tags,
      'isOutdoor': isOutdoor,
    };
  }
}
