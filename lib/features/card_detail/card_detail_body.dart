import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:sky_plan/app/app_theme.dart';
import '../home/models/plan_card.dart';

/// カード詳細画面 (Simple Version)
/// 標準的なリストUIで情報を整理
class CardDetailBody extends StatelessWidget {
  final PlanCard card;

  const CardDetailBody({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // ヘッダー情報（アイコンとタイトル）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    card.placeType.icon,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  card.placeName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  card.placeType.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSub,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 情報リスト
          _buildInfoGroup(context, '基本情報', [
            _buildInfoRow('日時', _formatDateTime(card.start)),
            _buildInfoRow('終了予定', _formatTime(card.end)),
            _buildInfoRow('結論', card.summary),
          ]),

          if (card.reasons.isNotEmpty)
            _buildInfoGroup(context, '判断の理由', card.reasons.map((r) {
              return _buildInfoRow(r.icon ?? '・', r.message);
            }).toList()),

          _buildInfoGroup(context, '天気・環境', [
            if (card.weatherIcon != null)
               _buildInfoRow('天気', card.weatherIcon!),
            if (card.temperature != null)
               _buildInfoRow('気温', '${card.temperature!.toStringAsFixed(1)}°C'),
            if (card.precipitationProbability != null)
               _buildInfoRow('降水確率', '${card.precipitationProbability}%'),
            _buildInfoRow(
              'リスクレベル',
              '${card.riskScore}/100',
              valueColor: _getRiskColor(),
            ),
          ]),
          
          // デバッグ情報（アコーディオンで隠すなどはせずシンプルに下に）
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Debug Info:\n${const JsonEncoder.withIndent('  ').convert({
                'id': card.id,
                'risk': card.riskLevel,
              })}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSub,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textMain,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? AppTheme.textSub,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('M/d H:mm').format(date);
  }
  
  String _formatTime(DateTime date) {
     return DateFormat('H:mm').format(date);
  }

  Color _getRiskColor() {
    if (card.riskScore >= 60) return AppTheme.riskHigh;
    if (card.riskScore >= 30) return AppTheme.riskMedium;
    return AppTheme.riskLow;
  }
}
