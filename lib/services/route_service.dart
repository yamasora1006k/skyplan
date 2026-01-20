import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum TransportMode {
  walking,
  driving;

  String get osrmProfile {
    switch (this) {
      case TransportMode.walking:
        return 'foot';
      case TransportMode.driving:
        return 'driving';
    }
  }
}

class RouteService {
  static const String _baseUrl = 'http://router.project-osrm.org/route/v1';

  /// 2点間のルートを取得
  Future<List<LatLng>> getRoute(
    LatLng start,
    LatLng end, {
    TransportMode mode = TransportMode.walking,
  }) async {
    final profile = mode.osrmProfile;
    final coordinates =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final url =
        '$_baseUrl/$profile/$coordinates?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final geometry =
              data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
          
          return geometry.map((coord) {
            // GeoJSONは [lng, lat] の順
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();
        }
      }
      // エラーまたはルートが見つからない場合は直線を返す
      return [start, end];
    } catch (e) {
      print('Route fetch error: $e');
      // エラー時は直線を返す
      return [start, end];
    }
  }

  /// 複数の地点を巡回するルート（各区間のルートを結合）
  Future<List<List<LatLng>>> getMultiPointRoutes(
    List<LatLng> points, {
    TransportMode mode = TransportMode.walking,
  }) async {
    if (points.length < 2) return [];

    final routes = <List<LatLng>>[];

    for (var i = 0; i < points.length - 1; i++) {
      final segment = await getRoute(points[i], points[i + 1], mode: mode);
      routes.add(segment);
      // API制限回避のための短いウェイト（デモサーバー利用のため）
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return routes;
  }
}
