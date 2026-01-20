import '../data/repositories/i_repository.dart';
import '../features/home/models/calendar_event.dart';
import '../features/home/models/learned_place.dart';
import '../features/home/models/plan_card.dart';
import '../features/home/models/weather_hourly.dart';

/// PlanCard生成サービス
/// 予定×推定場所×天気からカードを生成
class PlanCardService {
  final IRepository _repository;

  PlanCardService(this._repository);

  /// 今日のプランカードを生成
  Future<List<PlanCard>> generateTodayCards() async {
    // デモ用：今日＝1/20
    final demoToday = DateTime(2026, 1, 20);
    final cards = await generateCardsForDate(demoToday);
    
    // 今日のカードだけは保存しておく（次回起動時のキャッシュ用）
    await _repository.savePlanCards(cards);
    
    return cards;
  }

  /// 指定日のプランカードを生成
  Future<List<PlanCard>> generateCardsForDate(DateTime date) async {
    final events = await _repository.getEventsForDate(date);
    final learnedPlaces = await _repository.getLearnedPlaces();
    // 天気は全期間取得済み（デモ用）なのでそのまま
    // 実運用では getHourlyWeather(date) が必要になる
    
    final cards = <PlanCard>[];

    for (final event in events) {
      // イベントの時間帯の天気を取得
      final eventWeather = await _repository.getWeatherAt(event.start);
      
      // 場所タイプを推定
      final placeType = _estimatePlaceType(event, learnedPlaces);
      
      // 理由を生成
      final reasons = _generateReasons(event, eventWeather);
      
      // リスクスコアを計算
      final riskScore = _calculateRiskScore(event, eventWeather);

      final card = PlanCard(
        id: 'card_${event.id}',
        start: event.start,
        end: event.end,
        placeType: placeType,
        placeName: event.locationName ?? event.title,
        lat: event.lat ?? 35.6895, // デフォルト: 東京
        lng: event.lng ?? 139.6917,
        summary: _generateSummary(event, eventWeather, riskScore),
        reasons: reasons,
        riskScore: riskScore,
        weatherIcon: eventWeather?.weatherIcon,
        temperature: eventWeather?.temperature2m,
        precipitationProbability: eventWeather?.precipitationProbability,
        isOutdoor: event.isOutdoor,
      );
      
      cards.add(card);
    }

    return cards;
  }

  /// イベントから場所タイプを推定
  PlaceType _estimatePlaceType(CalendarEvent event, List<LearnedPlace> places) {
    // タグから判定
    if (event.tags.contains('school')) return PlaceType.school;
    if (event.tags.contains('juku')) return PlaceType.juku;
    if (event.tags.contains('home')) return PlaceType.home;
    if (event.tags.contains('friend')) return PlaceType.visited;
    
    // 座標から判定
    if (event.lat != null && event.lng != null) {
      for (final place in places) {
        final distance = _calculateDistance(
          event.lat!, event.lng!, place.lat, place.lng
        );
        if (distance < 200) { // 200m以内
          return place.type;
        }
      }
    }
    
    return PlaceType.unknown;
  }

  /// 理由を生成
  List<PlanReason> _generateReasons(CalendarEvent event, WeatherHourly? weather) {
    final reasons = <PlanReason>[];

    if (weather != null) {
      // 降水確率
      if (weather.precipitationProbability >= 70) {
        reasons.add(PlanReason(
          type: 'rain',
          message: '☔ 傘をお持ちください',
          value: '降水確率 ${weather.precipitationProbability}%',
          icon: '☔',
        ));
      } else if (weather.precipitationProbability >= 40) {
        reasons.add(PlanReason(
          type: 'rain',
          message: '🌂 折りたたみ傘があると安心',
          value: '降水確率 ${weather.precipitationProbability}%',
          icon: '🌂',
        ));
      }

      // 気温
      if (weather.apparentTemperature < 5) {
        reasons.add(PlanReason(
          type: 'cold',
          message: '🧥 防寒対策を',
          value: '体感 ${weather.apparentTemperature.toStringAsFixed(1)}°C',
          icon: '🧥',
        ));
      } else if (weather.apparentTemperature < 0) {
        reasons.add(PlanReason(
          type: 'freeze',
          message: '🥶 厚着必須！',
          value: '体感 ${weather.apparentTemperature.toStringAsFixed(1)}°C',
          icon: '🥶',
        ));
      }

      // 風速
      if (weather.windSpeed10m > 10) {
        reasons.add(PlanReason(
          type: 'wind',
          message: '💨 風が強いです',
          value: '風速 ${weather.windSpeed10m.toStringAsFixed(1)}m/s',
          icon: '💨',
        ));
      }
    }

    // 屋外イベント
    if (event.isOutdoor) {
      reasons.add(PlanReason(
        type: 'outdoor',
        message: '🏃 屋外活動あり',
        value: null,
        icon: '🏃',
      ));
    }

    return reasons;
  }

  /// リスクスコアを計算
  int _calculateRiskScore(CalendarEvent event, WeatherHourly? weather) {
    int score = 0;

    if (weather != null) {
      score += weather.riskScore;
    }

    if (event.isOutdoor) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// サマリーを生成
  String _generateSummary(CalendarEvent event, WeatherHourly? weather, int riskScore) {
    final parts = <String>[];

    if (weather != null) {
      parts.add('${weather.weatherIcon} ${weather.temperature2m.toStringAsFixed(0)}°C');
    }

    if (riskScore >= 60) {
      parts.add('⚠️ 注意が必要');
    } else if (riskScore >= 30) {
      parts.add('📌 準備をお忘れなく');
    } else {
      parts.add('✨ 快適な条件');
    }

    return parts.join(' / ');
  }

  /// 2点間の距離（メートル）
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) {
    while (x > 3.141592653589793) x -= 6.283185307179586;
    while (x < -3.141592653589793) x += 6.283185307179586;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }
  double _cos(double x) => _sin(x + 1.5707963267948966);
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) guess = (guess + x / guess) / 2;
    return guess;
  }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (y > 0) return 1.5707963267948966;
    if (y < 0) return -1.5707963267948966;
    return 0;
  }
  double _atan(double x) {
    if (x > 1) return 1.5707963267948966 - _atan(1 / x);
    if (x < -1) return -1.5707963267948966 - _atan(1 / x);
    final x2 = x * x;
    return x * (1 - x2 / 3 * (1 - x2 / 5 * (1 - x2 / 7)));
  }
}
