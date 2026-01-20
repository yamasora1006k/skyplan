import '../data/repositories/i_repository.dart';
import '../features/home/models/plan_card.dart';
import '../features/home/models/weather_hourly.dart';

/// インサイト（AIアドバイス）モデル
class Insight {
  final String id;
  final String icon;
  final String title;
  final String description;
  final InsightPriority priority;

  const Insight({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
  });
}

enum InsightPriority {
  critical, // 傘必須など
  important, // 早めの出発推奨など
  info, // 快適な条件など
}

/// インサイト生成サービス
/// 予定と天気から「今日のあなたへ」のアドバイスを生成
class InsightService {
  final IRepository _repository;

  InsightService(this._repository);

  /// 今日のインサイトを生成
  Future<List<Insight>> generateTodayInsights(List<PlanCard> cards) async {
    final insights = <Insight>[];
    
    // 1. 雨予報チェック
    final rainInsight = _checkRainRisk(cards);
    if (rainInsight != null) insights.add(rainInsight);
    
    // 2. 外出予定の早期出発推奨
    final departureInsight = _checkDepartureTime(cards);
    if (departureInsight != null) insights.add(departureInsight);
    
    // 3. 混雑予測
    final crowdInsight = _checkCrowding(cards);
    if (crowdInsight != null) insights.add(crowdInsight);
    
    // 4. 気温による服装アドバイス
    final clothingInsight = _checkClothing(cards);
    if (clothingInsight != null) insights.add(clothingInsight);
    
    // 5. 快適な条件（ポジティブフィードバック）
    if (insights.isEmpty) {
      insights.add(const Insight(
        id: 'comfortable',
        icon: '✨',
        title: '快適な一日になりそうです',
        description: '天候に問題なし。いつも通りの予定で大丈夫です。',
        priority: InsightPriority.info,
      ));
    }
    
    return insights;
  }

  Insight? _checkRainRisk(List<PlanCard> cards) {
    // 屋外予定で降水確率が高い場合
    final outdoorCards = cards.where((c) => 
      c.reasons.any((r) => r.type == 'rain' || r.icon == '☔' || r.icon == '🌂')
    ).toList();
    
    if (outdoorCards.isEmpty) return null;
    
    final maxPrecip = outdoorCards
        .map((c) => c.precipitationProbability ?? 0)
        .reduce((a, b) => a > b ? a : b);
    
    if (maxPrecip >= 70) {
      return const Insight(
        id: 'rain_critical',
        icon: '☔',
        title: '傘必須',
        description: '降水確率85%。折りたたみ傘も持参推奨。',
        priority: InsightPriority.critical,
      );
    } else if (maxPrecip >= 40) {
      return const Insight(
        id: 'rain_caution',
        icon: '🌂',
        title: '傘があると安心',
        description: '午後から雨の可能性。折りたたみ傘を。',
        priority: InsightPriority.important,
      );
    }
    
    return null;
  }

  Insight? _checkDepartureTime(List<PlanCard> cards) {
    // 雨天時の外出予定がある場合、早めの出発を推奨
    final morningCards = cards.where((c) {
      final hour = c.start.hour;
      return hour >= 8 && hour <= 11 && c.riskScore >= 50;
    }).toList();
    
    if (morningCards.isEmpty) return null;
    
    return const Insight(
      id: 'early_departure',
      icon: '🚃',
      title: '早めの出発を推奨',
      description: '雨天時は電車遅延の可能性。いつもより20分早く出発しましょう。',
      priority: InsightPriority.important,
    );
  }

  Insight? _checkCrowding(List<PlanCard> cards) {
    // 渋谷・新宿など主要駅への訪問がある場合
    final crowdedAreas = ['渋谷', '新宿', '新橋', '品川'];
    final visitingCrowdedArea = cards.any((c) =>
      crowdedAreas.any((area) => c.placeName.contains(area))
    );
    
    if (!visitingCrowdedArea) return null;
    
    return const Insight(
      id: 'crowd_warning',
      icon: '📍',
      title: '混雑予測エリアあり',
      description: '渋谷は混雑が予想されます。時間に余裕を持って移動しましょう。',
      priority: InsightPriority.info,
    );
  }

  Insight? _checkClothing(List<PlanCard> cards) {
    // 気温による服装アドバイス
    final temps = cards
        .where((c) => c.temperature != null)
        .map((c) => c.temperature!)
        .toList();
    
    if (temps.isEmpty) return null;
    
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    
    if (avgTemp < 5) {
      return const Insight(
        id: 'cold_warning',
        icon: '🧥',
        title: '防寒対策を',
        description: '今日は冷え込みます。コートやマフラーを忘れずに。',
        priority: InsightPriority.important,
      );
    }
    
    return null;
  }
}
