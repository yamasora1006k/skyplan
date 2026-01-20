import 'learned_place.dart';

/// 予定カードの理由
class PlanReason {
  final String type;
  final String message;
  final String? value;
  final String? icon;

  const PlanReason({
    required this.type,
    required this.message,
    this.value,
    this.icon,
  });

  factory PlanReason.fromJson(Map<String, dynamic> json) {
    return PlanReason(
      type: json['type'] as String,
      message: json['message'] as String,
      value: json['value'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'value': value,
      'icon': icon,
    };
  }
}

/// タイムラインカードモデル
class PlanCard {
  final String id;
  final DateTime start;
  final DateTime end;
  final PlaceType placeType;
  final String placeName;
  final double lat;
  final double lng;
  final String summary;
  final List<PlanReason> reasons;
  final int riskScore;
  final String? weatherIcon;
  final double? temperature;
  final int? precipitationProbability;
  final bool isOutdoor;

  const PlanCard({
    required this.id,
    required this.start,
    required this.end,
    required this.placeType,
    required this.placeName,
    required this.lat,
    required this.lng,
    required this.summary,
    required this.reasons,
    required this.riskScore,
    this.weatherIcon,
    this.temperature,
    this.precipitationProbability,
    required this.isOutdoor,
  });

  factory PlanCard.fromJson(Map<String, dynamic> json) {
    return PlanCard(
      id: json['id'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      placeType: PlaceType.values.firstWhere(
        (e) => e.name == json['placeType'],
        orElse: () => PlaceType.unknown,
      ),
      placeName: json['placeName'] as String,
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      summary: json['summary'] as String,
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((e) => PlanReason.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      riskScore: json['riskScore'] as int,
      weatherIcon: json['weatherIcon'] as String?,
      temperature: json['temperature'] as double?,
      precipitationProbability: json['precipitationProbability'] as int?,
      isOutdoor: json['isOutdoor'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'placeType': placeType.name,
      'placeName': placeName,
      'lat': lat,
      'lng': lng,
      'summary': summary,
      'reasons': reasons.map((e) => e.toJson()).toList(),
      'riskScore': riskScore,
      'weatherIcon': weatherIcon,
      'temperature': temperature,
      'precipitationProbability': precipitationProbability,
      'isOutdoor': isOutdoor,
    };
  }

  /// リスクレベルを取得
  String get riskLevel {
    if (riskScore >= 60) return 'high';
    if (riskScore >= 30) return 'medium';
    return 'low';
  }

  /// リスクに応じたアドバイスを取得
  String get advice {
    if (reasons.isEmpty) return '特に注意事項はありません';
    return reasons.map((r) => r.message).join(' / ');
  }
}
