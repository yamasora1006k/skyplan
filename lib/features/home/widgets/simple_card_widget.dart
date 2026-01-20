import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_plan/app/app_theme.dart';
import 'package:sky_plan/features/home/models/plan_card.dart';

/// シンプルなカードウィジェット
/// 時間・場所・その場所の天気・重要アドバイス表示
class SimpleCardWidget extends StatelessWidget {
  final PlanCard card;
  final VoidCallback? onTap;

  const SimpleCardWidget({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final topReason = card.reasons.isNotEmpty ? card.reasons.first : null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 時間
            SizedBox(
              width: 50,
              child: Text(
                DateFormat('H:mm').format(card.start),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 場所と天気
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 場所名
                  Text(
                    card.placeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // その場所の天気
                  Row(
                    children: [
                      if (card.weatherIcon != null) ...[
                        Text(
                          card.weatherIcon!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (card.temperature != null)
                        Text(
                          '${card.temperature!.toStringAsFixed(0)}°',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (card.precipitationProbability != null && 
                          card.precipitationProbability! >= 30) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${card.precipitationProbability}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: card.precipitationProbability! >= 70 
                                ? AppTheme.riskHigh 
                                : AppTheme.riskMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 重要アドバイス
                  if (topReason != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (topReason.icon != null)
                          Text(
                            topReason.icon!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            topReason.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSub,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFC7C7CC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
