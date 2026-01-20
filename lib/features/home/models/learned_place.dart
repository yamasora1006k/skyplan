/// 場所タイプ
enum PlaceType {
  home,
  work,
  school,
  juku,
  visited,
  unknown;

  String get displayName {
    switch (this) {
      case PlaceType.home:
        return '自宅';
      case PlaceType.work:
        return '職場';
      case PlaceType.school:
        return '学校';
      case PlaceType.juku:
        return '塾';
      case PlaceType.visited:
        return '訪問先';
      case PlaceType.unknown:
        return '不明';
    }
  }

  String get icon {
    switch (this) {
      case PlaceType.home:
        return '🏠';
      case PlaceType.work:
        return '🏢';
      case PlaceType.school:
        return '🏫';
      case PlaceType.juku:
        return '📚';
      case PlaceType.visited:
        return '📍';
      case PlaceType.unknown:
        return '❓';
    }
  }
}

/// 学習済み場所モデル
class LearnedPlace {
  final PlaceType type;
  final double lat;
  final double lng;
  final double confidence;
  final int evidenceCount;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final String? name;

  const LearnedPlace({
    required this.type,
    required this.lat,
    required this.lng,
    required this.confidence,
    required this.evidenceCount,
    required this.firstSeen,
    required this.lastSeen,
    this.name,
  });

  factory LearnedPlace.fromJson(Map<String, dynamic> json) {
    return LearnedPlace(
      type: PlaceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PlaceType.unknown,
      ),
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      confidence: json['confidence'] as double,
      evidenceCount: json['evidenceCount'] as int,
      firstSeen: DateTime.parse(json['firstSeen'] as String),
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'lat': lat,
      'lng': lng,
      'confidence': confidence,
      'evidenceCount': evidenceCount,
      'firstSeen': firstSeen.toIso8601String(),
      'lastSeen': lastSeen.toIso8601String(),
      'name': name,
    };
  }

  /// confidence更新版のコピーを作成
  LearnedPlace copyWith({
    PlaceType? type,
    double? lat,
    double? lng,
    double? confidence,
    int? evidenceCount,
    DateTime? firstSeen,
    DateTime? lastSeen,
    String? name,
  }) {
    return LearnedPlace(
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      confidence: confidence ?? this.confidence,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      name: name ?? this.name,
    );
  }
}
