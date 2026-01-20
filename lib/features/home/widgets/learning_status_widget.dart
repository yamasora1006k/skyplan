import 'package:flutter/material.dart';
import '../models/learned_place.dart';

/// 学習ステータスWidget
class LearningStatusWidget extends StatelessWidget {
  final List<LearnedPlace> places;
  final int runCount;

  const LearningStatusWidget({
    super.key,
    required this.places,
    required this.runCount,
  });

  @override
  Widget build(BuildContext context) {
    final homePlace = places.where((p) => p.type == PlaceType.home).firstOrNull;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '学習ステータス',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '起動 $runCount 回目',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ホームconfidence
          if (homePlace != null) ...[
            _buildConfidenceRow(
              context,
              icon: '🏠',
              label: 'ホーム推定',
              confidence: homePlace.confidence,
              evidenceCount: homePlace.evidenceCount,
            ),
            const SizedBox(height: 8),
          ],
          
          // 学習済み場所数
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '学習済み場所: ${places.length}件',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          
          // 訪問先検出
          if (places.any((p) => p.type == PlaceType.visited)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.new_releases, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '新しい訪問先を検出しました',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceRow(
    BuildContext context, {
    required String icon,
    required String label,
    required double confidence,
    required int evidenceCount,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _getConfidenceColor(confidence),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getConfidenceColor(confidence),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '証拠ポイント: $evidenceCount',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
