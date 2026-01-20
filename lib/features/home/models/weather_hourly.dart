/// 時間別天気データモデル
class WeatherHourly {
  final DateTime time;
  final double temperature2m;
  final double apparentTemperature;
  final int precipitationProbability;
  final double precipitation;
  final double windSpeed10m;
  final int relativeHumidity2m;
  final int weatherCode;

  const WeatherHourly({
    required this.time,
    required this.temperature2m,
    required this.apparentTemperature,
    required this.precipitationProbability,
    required this.precipitation,
    required this.windSpeed10m,
    required this.relativeHumidity2m,
    this.weatherCode = 0,
  });

  factory WeatherHourly.fromJson(Map<String, dynamic> json) {
    return WeatherHourly(
      time: DateTime.parse(json['time'] as String),
      temperature2m: (json['temperature_2m'] as num).toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      precipitationProbability: json['precipitation_probability'] as int,
      precipitation: (json['precipitation'] as num).toDouble(),
      windSpeed10m: (json['wind_speed_10m'] as num).toDouble(),
      relativeHumidity2m: json['relative_humidity_2m'] as int,
      weatherCode: json['weather_code'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'temperature_2m': temperature2m,
      'apparent_temperature': apparentTemperature,
      'precipitation_probability': precipitationProbability,
      'precipitation': precipitation,
      'wind_speed_10m': windSpeed10m,
      'relative_humidity_2m': relativeHumidity2m,
      'weather_code': weatherCode,
    };
  }

  /// 天気アイコンを取得
  String get weatherIcon {
    if (precipitationProbability >= 70) return '🌧️';
    if (precipitationProbability >= 40) return '🌦️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '🌨️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌧️';
    if (weatherCode >= 95) return '⛈️';
    if (weatherCode <= 3) return '☀️';
    return '⛅';
  }

  /// 天気の説明を取得
  String get weatherDescription {
    if (precipitationProbability >= 70) return '雨が降りそう';
    if (precipitationProbability >= 40) return '雨の可能性あり';
    if (temperature2m < 5) return '寒い';
    if (temperature2m > 30) return '暑い';
    if (windSpeed10m > 10) return '風が強い';
    return '快適';
  }

  /// リスクスコアを計算（0-100）
  int get riskScore {
    int score = 0;
    
    // 降水確率
    if (precipitationProbability >= 70) score += 40;
    else if (precipitationProbability >= 40) score += 20;
    
    // 気温
    if (temperature2m < 0) score += 20;
    else if (temperature2m < 5) score += 10;
    else if (temperature2m > 35) score += 20;
    else if (temperature2m > 30) score += 10;
    
    // 風速
    if (windSpeed10m > 15) score += 20;
    else if (windSpeed10m > 10) score += 10;
    
    return score.clamp(0, 100);
  }
}
