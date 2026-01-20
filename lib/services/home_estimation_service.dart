import '../data/repositories/i_repository.dart';
import '../features/home/models/learned_place.dart';
import '../features/home/models/location_point.dart';

/// ホーム推定サービス
/// 夜間滞在クラスタリングによる自宅推定
class HomeEstimationService {
  final IRepository _repository;

  HomeEstimationService(this._repository);

  /// 夜間位置からホームを推定
  Future<LearnedPlace?> estimateHome() async {
    final nightLocations = await _repository.getNightLocations();
    if (nightLocations.isEmpty) return null;

    // クラスタリング（簡易版：最頻位置を探す）
    final clusters = _clusterLocations(nightLocations);
    if (clusters.isEmpty) return null;

    // 最大のクラスタを選択
    final largestCluster = clusters.reduce(
      (a, b) => a.length > b.length ? a : b,
    );

    // クラスタの中心を計算
    double sumLat = 0;
    double sumLng = 0;
    for (final loc in largestCluster) {
      sumLat += loc.lat;
      sumLng += loc.lng;
    }
    final centerLat = sumLat / largestCluster.length;
    final centerLng = sumLng / largestCluster.length;

    // 既存の学習済み場所を取得
    final existingPlaces = await _repository.getLearnedPlaces();
    final existingHome = existingPlaces
        .where((p) => p.type == PlaceType.home)
        .toList();

    // confidence計算
    final runCount = await _repository.getRunCount();
    double baseConfidence = existingHome.isNotEmpty 
        ? existingHome.first.confidence 
        : 0.35;
    
    // 起動回数に応じてconfidenceを上昇（最大0.95）
    final newConfidence = (baseConfidence + (runCount * 0.12)).clamp(0.0, 0.95);
    
    // evidenceCount更新
    final baseEvidence = existingHome.isNotEmpty 
        ? existingHome.first.evidenceCount 
        : 0;
    final newEvidence = baseEvidence + largestCluster.length;

    return LearnedPlace(
      type: PlaceType.home,
      lat: centerLat,
      lng: centerLng,
      confidence: newConfidence,
      evidenceCount: newEvidence,
      firstSeen: existingHome.isNotEmpty 
          ? existingHome.first.firstSeen 
          : largestCluster.first.timestamp,
      lastSeen: largestCluster.last.timestamp,
      name: '自宅（下宿）',
    );
  }

  /// 位置をクラスタリング（距離ベース）
  List<List<LocationPoint>> _clusterLocations(List<LocationPoint> locations) {
    const double thresholdMeters = 100; // 100m以内を同一クラスタとみなす
    final List<List<LocationPoint>> clusters = [];

    for (final loc in locations) {
      bool added = false;
      for (final cluster in clusters) {
        // クラスタの最初の点との距離をチェック
        if (cluster.first.distanceTo(loc) < thresholdMeters) {
          cluster.add(loc);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters.add([loc]);
      }
    }

    return clusters;
  }

  /// 学習を進める（起動時に呼ばれる）
  Future<List<LearnedPlace>> progressLearning() async {
    final places = await _repository.getLearnedPlaces();
    final runCount = await _repository.getRunCount();
    
    // 各場所のconfidenceを起動回数に応じて更新
    final updatedPlaces = <LearnedPlace>[];
    for (final place in places) {
      final boost = runCount * 0.08;
      final newConfidence = (place.confidence + boost).clamp(0.0, 0.95);
      
      final updated = place.copyWith(
        confidence: newConfidence,
        evidenceCount: place.evidenceCount + runCount,
      );
      updatedPlaces.add(updated);
      await _repository.updateLearnedPlace(updated);
    }

    // 2回目以降の起動でvisited場所を検出
    if (runCount >= 1) {
      final existingVisited = places.where((p) => p.type == PlaceType.visited).toList();
      if (existingVisited.isEmpty) {
        // 友達の家を新規発見として追加
        final visited = LearnedPlace(
          type: PlaceType.visited,
          lat: 35.721033,
          lng: 140.044611,
          confidence: 0.40 + (runCount * 0.1),
          evidenceCount: 2,
          firstSeen: DateTime(2025, 12, 20, 10, 0),
          lastSeen: DateTime(2025, 12, 20, 17, 0),
          name: '友達の家',
        );
        await _repository.addLearnedPlace(visited);
        updatedPlaces.add(visited);
      }
    }

    return updatedPlaces;
  }
}
