import 'package:flutter/material.dart';
import 'package:sky_plan/app/app_theme.dart';
import 'package:intl/intl.dart';
import 'models/plan_card.dart';

class AiSuggestionPage extends StatelessWidget {
  final DateTime date;
  final List<PlanCard> cards;

  const AiSuggestionPage({
    super.key,
    required this.date,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    // 雨予報かどうか（降水確率50%以上）
    final isRainy = cards.any((c) => (c.precipitationProbability ?? 0) >= 50);
    // アウトドア予定があるか
    final outdoorPlans = cards.where((c) => c.isOutdoor).toList();
    final hasOutdoorPlan = outdoorPlans.isNotEmpty;

    // AIの提案が必要な状況か判定
    final needsSuggestion = isRainy && hasOutdoorPlan;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI分析レポート'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textMain),
        titleTextStyle: const TextStyle(
          color: AppTheme.textMain,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAnalysisSection(needsSuggestion, outdoorPlans),
              const SizedBox(height: 32),
              if (needsSuggestion) ...[
                const Text(
                  '代替プランの提案',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSuggestionCard(
                  '鎌倉・江ノ島',
                  '千葉は雨予報ですが、鎌倉方面は晴れの予報です☀️ 海沿いの散歩や神社巡りが楽しめます。',
                  'sunny',
                  '晴れ・観光',
                ),
                _buildSuggestionCard(
                  '川越（小江戸）',
                  '埼玉方面も天候は安定しています。古い町並みの散策や食べ歩きにおすすめです。',
                  'sunny',
                  '晴れ・観光',
                ),
                _buildSuggestionCard(
                  'ららぽーとTOKYO-BAY',
                  '近くで済ませるなら、雨の影響を受けない大型ショッピングモールも選択肢です。',
                  'shopping_bag',
                  '屋内・ショッピング',
                ),
              ] else ...[
                 Center(
                   child: Column(
                     children: [
                       const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.primaryBlue),
                       const SizedBox(height: 16),
                       const Text(
                         '予定通りで問題なさそうです！✨',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                           color: AppTheme.textMain,
                         ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         isRainy ? '雨予報ですが、屋内の予定が中心ですね。' : '天候も良好で、絶好のお出かけ日和です！',
                         style: const TextStyle(color: AppTheme.textSub),
                       ),
                     ],
                   ),
                 ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(bool needsSuggestion, List<PlanCard> outdoorPlans) {
    if (needsSuggestion) {
      final planName = outdoorPlans.first.placeName;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('☔️', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '予定の見直しを推奨',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('M/d').format(date)}の「$planName」は、雨予報のため決行が難しいかもしれません。屋内での代替プランを提案します。',
                    style: const TextStyle(
                      height: 1.5,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('🤖', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI分析完了',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '現在のスケジュールに大きな問題点は見つかりませんでした。',
                    style: TextStyle(color: AppTheme.textMain),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSuggestionCard(String title, String description, String iconName, String tag) {
    IconData iconData;
    switch (iconName) {
      case 'sunny':
        iconData = Icons.wb_sunny_outlined;
        break;
      case 'shopping_bag':
        iconData = Icons.shopping_bag_outlined;
        break;
      case 'museum':
        iconData = Icons.museum_outlined;
        break;
      case 'movie':
        iconData = Icons.movie_outlined;
        break;
      default:
        iconData = Icons.place_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSub),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
