/// GPS位置ログモデル
class LocationPoint {
  final DateTime timestamp;
  final double lat;
  final double lng;
  final double? accuracyM;
  final double? speedMps;

  const LocationPoint({
    required this.timestamp,
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.speedMps,
  });

  factory LocationPoint.fromCsv(List<dynamic> row) {
    return LocationPoint(
      timestamp: DateTime.parse(row[0] as String),
      lat: double.parse(row[1].toString()),
      lng: double.parse(row[2].toString()),
      accuracyM: row.length > 3 ? double.tryParse(row[3].toString()) : null,
      speedMps: row.length > 4 ? double.tryParse(row[4].toString()) : null,
    );
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      lat: json['lat'] as double,
      lng: json['lng'] as double,
      accuracyM: json['accuracyM'] as double?,
      speedMps: json['speedMps'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'accuracyM': accuracyM,
      'speedMps': speedMps,
    };
  }

  /// 2点間の距離を計算（簡易版、メートル単位）
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371000; // メートル
    final dLat = _toRadians(other.lat - lat);
    final dLng = _toRadians(other.lng - lng);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat)) * _cos(_toRadians(other.lat)) *
        _sin(dLng / 2) * _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double deg) => deg * 3.141592653589793 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 1.5707963267948966);
  double _sqrt(double x) => x > 0 ? _newtonSqrt(x) : 0;
  double _atan2(double y, double x) => _approxAtan2(y, x);

  double _taylorSin(double x) {
    // Normalize x to [-π, π]
    while (x > 3.141592653589793) x -= 6.283185307179586;
    while (x < -3.141592653589793) x += 6.283185307179586;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }

  double _newtonSqrt(double x) {
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _approxAtan2(double y, double x) {
    if (x > 0) return _approxAtan(y / x);
    if (x < 0 && y >= 0) return _approxAtan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _approxAtan(y / x) - 3.141592653589793;
    if (y > 0) return 1.5707963267948966;
    if (y < 0) return -1.5707963267948966;
    return 0;
  }

  double _approxAtan(double x) {
    if (x > 1) return 1.5707963267948966 - _approxAtan(1 / x);
    if (x < -1) return -1.5707963267948966 - _approxAtan(1 / x);
    final x2 = x * x;
    return x * (1 - x2 / 3 * (1 - x2 / 5 * (1 - x2 / 7)));
  }
}
