import 'package:flutter/material.dart';
import 'package:sky_plan/app/app_theme.dart';
import 'package:sky_plan/services/insight_service.dart';

/// 今日のインサイト（AIアドバイス）表示ウィジェット
class TodayInsightsWidget extends StatelessWidget {
  final List<Insight> insights;

  const TodayInsightsWidget({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🤖',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                '今日のあなたへ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Insight insight) {
    Color priorityColor;
    switch (insight.priority) {
      case InsightPriority.critical:
        priorityColor = AppTheme.riskHigh;
        break;
      case InsightPriority.important:
        priorityColor = AppTheme.riskMedium;
        break;
      case InsightPriority.info:
        priorityColor = AppTheme.primaryBlue;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMain,
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
