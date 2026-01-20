import 'package:flutter/material.dart';
import 'package:sky_plan/app/app_theme.dart';
import '../models/plan_card.dart';

class AiPlanningTab extends StatefulWidget {
  final DateTime date;
  final List<PlanCard> cards;

  const AiPlanningTab({
    super.key,
    required this.date,
    required this.cards,
  });

  @override
  State<AiPlanningTab> createState() => _AiPlanningTabState();
}

class _AiPlanningTabState extends State<AiPlanningTab> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _wishController = TextEditingController();
  bool _isGenerating = false;
  List<Widget> _chatBubbles = [];

  @override
  void dispose() {
    _moodController.dispose();
    _wishController.dispose();
    super.dispose();
  }

  void _generatePlan() async {
    if (_moodController.text.isEmpty && _wishController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      // ユーザーの入力をチャットに追加
      if (_moodController.text.isNotEmpty) {
        _chatBubbles.add(_buildUserBubble('気分: ${_moodController.text}'));
      }
      if (_wishController.text.isNotEmpty) {
        _chatBubbles.add(_buildUserBubble('要望: ${_wishController.text}'));
      }
    });

    // AIの思考中をシミュレート
    await Future.delayed(const Duration(seconds: 2));

    String suggestionTitle;
    String suggestionDesc;
    String iconName;

    // 空き時間の計算
    final freeSlot = _findFreeSlot(widget.cards);
    
    // 天気情報の取得（簡易的に降水確率で判定）
    final maxPrecip = widget.cards.isNotEmpty
        ? widget.cards.map((c) => c.precipitationProbability ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    final isRainy = maxPrecip >= 50;

    // 簡易ロジック（キーワード + 天気連動 + 時間提案）
    final input = '${_moodController.text} ${_wishController.text}';
    
    if (input.contains('肉') || input.contains('食べたい')) {
      suggestionTitle = '極上の焼肉ディナー';
      suggestionDesc = '六本木の人気焼肉店「Beef Garden」がおすすめです。個室でゆっくり極上のお肉を楽しめます。移動時間はタクシーで15分ほどです。';
      if (freeSlot != null) {
        suggestionDesc += '\n\n💡 ${freeSlot.start.hour}:${freeSlot.start.minute.toString().padLeft(2, '0')}〜が空いているので、その時間に合わせて予約できそうです！';
      }
      iconName = 'restaurant';
    } else if (input.contains('静か') || input.contains('本') || input.contains('読書')) {
      suggestionTitle = '隠れ家ブックカフェ';
      suggestionDesc = '代官山の「森の図書室」はいかがでしょう？ 静かな空間で読書に没頭できます。美味しいコーヒーと共にリラックスした時間を。';
      if (freeSlot != null) {
        suggestionDesc += '\n\n💡 ${freeSlot.start.hour}:${freeSlot.start.minute.toString().padLeft(2, '0')}頃から向かうのがスムーズでおすすめです。';
      }
      iconName = 'book';
    } else {
      // 天気に応じたデフォルト提案
      if (isRainy) {
        suggestionTitle = '雨の日を楽しむアート展';
        suggestionDesc = '今日はあいにくの雨ですが、近くの美術館で開催中の現代アート展が話題です。屋内でも感性を刺激する素晴らしい体験になるでしょう☔️';
        if (freeSlot != null) {
          suggestionDesc += '\n\n💡 ${freeSlot.start.hour}:${freeSlot.start.minute.toString().padLeft(2, '0')}〜の時間帯なら比較的空いているかもしれません。';
        }
        iconName = 'museum';
      } else {
        suggestionTitle = '晴れた日の絶景パーク散策';
        suggestionDesc = '今日は天気が良いので、少し足を伸ばして「海浜公園」はいかがですか？☀️ 青空の下でのんびり過ごすとリフレッシュできますよ。';
        if (freeSlot != null) {
          suggestionDesc += '\n\n💡 ${freeSlot.start.hour}:${freeSlot.start.minute.toString().padLeft(2, '0')}頃に出発すると、ちょうど良い陽気の中で楽しめそうです。';
        }
        iconName = 'sunny';
      }
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _chatBubbles.add(_buildAiBubble(suggestionTitle, suggestionDesc, iconName));
        // 入力をクリア
        _moodController.clear();
        _wishController.clear();
      });
    }
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAiBubble(String title, String desc, String iconName) {
    IconData icon;
    switch (iconName) {
      case 'restaurant':
        icon = Icons.restaurant;
        break;
      case 'book':
        icon = Icons.menu_book;
        break;
      case 'sunny':
        icon = Icons.wb_sunny;
        break;
      default:
        icon = Icons.museum_outlined;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(color: AppTheme.textMain),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('プランに追加する'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 初期メッセージ
              if (_chatBubbles.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      '今の気分やご要望をお聞かせください。\nあなたにぴったりのプランをご提案します🤖',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSub),
                    ),
                  ),
                ),
              ..._chatBubbles,
              if (_isGenerating)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _moodController,
                decoration: InputDecoration(
                  labelText: '今の気分は？',
                  hintText: '例: リラックスしたい、ワイワイ騒ぎたい',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _wishController,
                decoration: InputDecoration(
                  labelText: 'やりたいことは？',
                  hintText: '例: 読書、焼肉、映画鑑賞',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generatePlan,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('プランを作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DateTimeRange? _findFreeSlot(List<PlanCard> cards) {
    if (cards.isEmpty) {
      // 予定がない場合は現在時刻から
      final now = DateTime.now();
      return DateTimeRange(start: now, end: now.add(const Duration(hours: 2)));
    }

    // 予定を時系列にソート
    final sortedCards = List<PlanCard>.from(cards)
      ..sort((a, b) => a.start.compareTo(b.start));

    // 09:00 - 21:00 の間で空きを探す（簡易実装）
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day, 9);
    final dayEnd = DateTime(widget.date.year, widget.date.month, widget.date.day, 21);

    // 最初の予定までの空き
    if (sortedCards.first.start.isAfter(dayStart)) {
      if (sortedCards.first.start.difference(dayStart).inMinutes >= 60) {
        return DateTimeRange(start: dayStart, end: sortedCards.first.start);
      }
    }

    // 予定間の空き
    for (int i = 0; i < sortedCards.length - 1; i++) {
      final end = sortedCards[i].end;
      final nextStart = sortedCards[i + 1].start;

      if (nextStart.difference(end).inMinutes >= 60) {
        return DateTimeRange(start: end, end: nextStart);
      }
    }

    // 最後の予定以降の空き
    if (sortedCards.last.end.isBefore(dayEnd)) {
      if (dayEnd.difference(sortedCards.last.end).inMinutes >= 60) {
        return DateTimeRange(start: sortedCards.last.end, end: dayEnd);
      }
    }

    return null;
  }
}
