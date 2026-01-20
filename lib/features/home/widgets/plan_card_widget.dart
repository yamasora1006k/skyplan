import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_plan/app/app_theme.dart';
import 'package:sky_plan/features/home/models/plan_card.dart';

/// プランカードWidget
/// シンプルで情報を絞ったデザイン
class PlanCardWidget extends StatelessWidget {
  final PlanCard card;
  final VoidCallback? onTap;

  const PlanCardWidget({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 重要度を示すカラーライン
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _getRiskColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              
              // メインコンテンツ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 時間
                    Row(
                      children: [
                         Text(
                          _formatTimeRange(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSub,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        // 天気アイコン（あれば）
                        if (card.weatherIcon != null) ...[
                          const SizedBox(width: 8),
                          Text(card.weatherIcon!, style: const TextStyle(fontSize: 14)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 場所とアイコン
                    Row(
                      children: [
                        Text(
                          card.placeName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // サマリー（短い結論）
                    Text(
                      card.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMain,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 右端の矢印
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC7C7CC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange() {
    final start = DateFormat('H:mm').format(card.start);
    final end = DateFormat('H:mm').format(card.end);
    return '$start - $end';
  }

  Color _getRiskColor() {
    // リスクがない場合はメインカラー、あれば警告色
    if (card.riskScore >= 60) return AppTheme.riskHigh;
    if (card.riskScore >= 30) return AppTheme.riskMedium;
    return AppTheme.primaryBlue;
  }
}
