import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:sky_plan/app/app_theme.dart';
import '../../../services/route_service.dart';
import '../models/plan_card.dart';
import '../models/learned_place.dart';

/// 地図ビュー（ルート検索・モード選択機能付き）
class MapView extends StatefulWidget {
  final DateTime selectedDate;
  final List<PlanCard> cards;
  final LearnedPlace? homePlace;

  const MapView({
    super.key,
    required this.selectedDate,
    required this.cards,
    this.homePlace,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // 複数選択用にSetに変更
  final Set<int> _selectedIndices = {};
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();
  
  TransportMode _currentMode = TransportMode.walking;
  List<List<LatLng>> _routes = [];
  List<LatLng> _allRoutePoints = [];
  LatLng? _homePosition;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.homePlace != null) {
      _homePosition = LatLng(widget.homePlace!.lat, widget.homePlace!.lng);
    }
    // 初期状態は未選択（ユーザー選択待ち）
    _determineInitialMode();
    _fetchRoutes();
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.homePlace?.lat != widget.homePlace?.lat ||
        oldWidget.homePlace?.lng != widget.homePlace?.lng) {
      _homePosition = widget.homePlace != null
          ? LatLng(widget.homePlace!.lat, widget.homePlace!.lng)
          : null;
    }
  }
  
  void _determineInitialMode() {
    final hasRain = widget.cards.any((card) => (card.precipitationProbability ?? 0) >= 50);
    setState(() {
      _currentMode = hasRain ? TransportMode.driving : TransportMode.walking;
    });
  }

  Future<void> _fetchRoutes() async {
    // 選択された地点のみを取得（インデックス順にソート）
    final sortedIndices = _selectedIndices.toList()..sort();
    final points = <LatLng>[];
    if (_homePosition != null) {
      points.add(_homePosition!);
    }
    points.addAll(sortedIndices.map((i) {
      final card = widget.cards[i];
      return LatLng(card.lat, card.lng);
    }));

    if (points.length < 2) {
      if (mounted) {
        setState(() {
          _routes = [];
          _allRoutePoints = [];
        });
      }
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      // 選択されたカードのみを抽出
      final routes = await _routeService.getMultiPointRoutes(
        points,
        mode: _currentMode,
      );

      final flattened = routes.expand((element) => element).toList();

      if (mounted) {
        setState(() {
          _routes = routes;
          _allRoutePoints = flattened;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
        print('Route error: $e');
      }
    }
  }

  void _toggleMode(TransportMode mode) {
    if (_currentMode == mode) return;
    setState(() {
      _currentMode = mode;
    });
    _fetchRoutes();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        // 選択解除（ただし最低1つは残すなどの制約はUX次第だが、一旦0個も許容）
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
        // 追加時はその場所にフォーカス
        final card = widget.cards[index];
        _mapController.move(
          LatLng(card.lat, card.lng),
          14.0,
        );
      }
    });
    // ルート再計算
    _fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: Text(
            'この日の予定はありません',
            style: TextStyle(color: AppTheme.textSub),
          ),
        ),
      );
    }

    // マーカー生成
    final markers = <Marker>[];
    final usedPositions = <LatLng>[];

    // まず自宅マーカー
    if (_homePosition != null) {
      usedPositions.add(_homePosition!);
      markers.add(
        Marker(
          point: _homePosition!,
          width: 74,
          height: 100,
          child: _buildMarkerContent(
            labelText: '1',
            isSelected: true,
            isHome: true,
            weatherIcon: '',
            temperature: '',
            timeText: '',
          ),
        ),
      );
    }

    // 選択されたカードのみを表示対象にするか、
    // 全て表示して選択状態を変えるか。
    // 「その経路のみを表示」という要望なので、マーカー自体は全てあってもいいが、
    // ルートは選択されたものだけ。
    // 選択されていないマーカーは薄くするなどの表現が良い。

    for (var i = 0; i < widget.cards.length; i++) {
      final card = widget.cards[i];
      var position = LatLng(card.lat, card.lng);
      final weatherIcon = card.weatherIcon ?? '';
      final tempText = card.temperature != null ? '${card.temperature!.toStringAsFixed(0)}°' : '';
      
      var offset = 0;
      while (usedPositions.any((p) => 
        (p.latitude - position.latitude).abs() < 0.0001 && 
        (p.longitude - position.longitude).abs() < 0.0001
      )) {
        offset++;
        final distance = 0.0005 * offset;
        position = LatLng(
          card.lat + distance * (offset % 2 == 1 ? 1 : -1),
          card.lng + distance * (offset < 3 ? 1 : -1),
        );
      }
      
      usedPositions.add(position);
      final isSelected = _selectedIndices.contains(i);

      markers.add(
        Marker(
          point: position,
          width: 74,
          height: 100,
          child: GestureDetector(
            onTap: () => _toggleSelection(i),
            child: _buildMarkerContent(
              labelText: '${i + 1}',
              isSelected: isSelected,
              isHome: false,
              weatherIcon: weatherIcon,
              temperature: tempText,
              timeText: DateFormat('H:mm').format(card.start),
            ),
          ),
        ),
      );
    }

    // 中心計算（選択された地点のみを対象にする）
    LatLng center = const LatLng(35.6895, 139.6917);
    double zoom = 11.0;
    
    // 選択された地点の座標リスト（選択がある場合のみ自宅を先頭に含める）
    final selectedPositions = <LatLng>[];
    for (var i = 0; i < widget.cards.length; i++) {
      if (_selectedIndices.contains(i)) {
        selectedPositions.add(LatLng(widget.cards[i].lat, widget.cards[i].lng));
      }
    }
    final activePositions = (selectedPositions.isNotEmpty && _homePosition != null)
        ? <LatLng>[_homePosition!, ...selectedPositions]
        : selectedPositions;

    // 選択がない場合は全地点を表示範囲とする
    final pointsForZoom = activePositions.isNotEmpty ? activePositions : usedPositions;

    if (pointsForZoom.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      double minLat = 90.0;
      double maxLat = -90.0;
      double minLng = 180.0;
      double maxLng = -180.0;

      for (var point in pointsForZoom) {
        sumLat += point.latitude;
        sumLng += point.longitude;
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      center = LatLng(sumLat / pointsForZoom.length, sumLng / pointsForZoom.length);
      
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      if (maxDiff < 0.01) zoom = 14.0;
      else if (maxDiff < 0.05) zoom = 12.0;
      else if (maxDiff < 0.1) zoom = 11.0;
      else zoom = 10.0;
    }

    // APIルートがあればそれ、なければ直線（ただし2点以上選択時のみ）
    final displayPoints = _allRoutePoints.isNotEmpty 
        ? _allRoutePoints 
        : (activePositions.length >= 2 ? activePositions : <LatLng>[]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // タイトル & モード選択
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('M月d日', 'ja_JP').format(widget.selectedDate)}の移動',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // モード切り替えバー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildModeButton(TransportMode.walking)),
                  Expanded(child: _buildModeButton(TransportMode.driving)),
                ],
              ),
            ),
          ),

          // 地図エリア
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: zoom,
                      minZoom: 10,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.skyplan.skyPlan',
                      ),
                      // ルート線
                      if (displayPoints.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: displayPoints,
                              strokeWidth: 4.0,
                              color: _currentMode == TransportMode.walking 
                                  ? AppTheme.primaryBlue 
                                  : AppTheme.riskHigh,
                            ),
                          ],
                        ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
                // ローディング中インジケータ
                if (_isLoadingRoute)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('再計算中...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  
                // ズームボタン
                Positioned(
                  left: 16,
                  top: 16,
                  child: Column(
                    children: [
                      _buildZoomButton(Icons.add, () {
                        final z = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, z + 1);
                      }, isTop: true),
                      const SizedBox(height: 1),
                      _buildZoomButton(Icons.remove, () {
                        final z = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, z - 1);
                      }, isTop: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 経路リスト
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  final card = widget.cards[index];
                  final isSelected = _selectedIndices.contains(index);
                  
                  return GestureDetector(
                    onTap: () => _toggleSelection(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 番号
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryBlue : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 時間
                          Text(
                            DateFormat('H:mm').format(card.start),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.grey,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 場所と天気
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.placeName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.black : Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (card.weatherIcon != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(card.weatherIcon!, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      if (card.temperature != null)
                                        Text(
                                          '${card.temperature!.toStringAsFixed(0)}°',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSub,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(TransportMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => _toggleMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == TransportMode.walking ? Icons.directions_walk : Icons.directions_car,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSub,
            ),
            const SizedBox(width: 8),
            Text(
              mode == TransportMode.walking ? '徒歩' : '車',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textSub,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerContent({
    required String labelText,
    required bool isSelected,
    required bool isHome,
    required String weatherIcon,
    required String temperature,
    required String timeText,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (weatherIcon.isNotEmpty || temperature.isNotEmpty || timeText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 1,
              children: [
                if (timeText.isNotEmpty)
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                if (weatherIcon.isNotEmpty)
                  Text(weatherIcon, style: const TextStyle(fontSize: 15)),
                if (temperature.isNotEmpty)
                  Text(
                    temperature,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSub,
                    ),
                  ),
              ],
            ),
          ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.65,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isHome
                  ? Colors.white
                  : (isSelected ? AppTheme.primaryBlue : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                color: isHome
                    ? AppTheme.primaryBlue
                    : (isSelected ? AppTheme.primaryBlue : Colors.grey),
                width: isHome ? 3 : (isSelected ? 2.5 : 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                labelText,
                style: TextStyle(
                  color: isHome
                      ? AppTheme.primaryBlue
                      : (isSelected ? Colors.white : Colors.grey),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildZoomButton(IconData icon, VoidCallback onTap, {required bool isTop}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(8) : Radius.zero,
          bottom: !isTop ? const Radius.circular(8) : Radius.zero,
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}
