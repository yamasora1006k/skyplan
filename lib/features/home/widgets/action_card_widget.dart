import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_plan/app/app_theme.dart';
import 'package:sky_plan/features/home/models/plan_card.dart';

/// アクション提案型カードウィジェット
/// 単なる予定表示ではなく、AIが生成した行動提案を表示
class ActionCardWidget extends StatelessWidget {
  final PlanCard card;
  final VoidCallback? onTap;

  const ActionCardWidget({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRisk = card.riskScore >= 30;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasRisk 
                ? AppTheme.riskMedium.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            width: hasRisk ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 時間と場所
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    DateFormat('H:mm').format(card.start),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card.placeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                ),
                if (card.weatherIcon != null)
                  Text(card.weatherIcon!, style: const TextStyle(fontSize: 20)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // AIアドバイス
            if (card.reasons.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💡', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          'AIアドバイス',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...card.reasons.take(3).map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMain,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reason.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMain,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ] else ...[
              // リスクがない場合
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    card.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSub,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
