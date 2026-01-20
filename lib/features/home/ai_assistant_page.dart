import 'package:flutter/material.dart';
import 'package:sky_plan/app/app_theme.dart';
import 'models/plan_card.dart';
import 'widgets/ai_analysis_tab.dart';
import 'widgets/ai_planning_tab.dart';

class AiAssistantPage extends StatelessWidget {
  final DateTime date;
  final List<PlanCard> cards;

  const AiAssistantPage({
    super.key,
    required this.date,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('AIアシスタント'),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppTheme.textMain),
          titleTextStyle: const TextStyle(
            color: AppTheme.textMain,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          bottom: const TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSub,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(text: '分析レポート', icon: Icon(Icons.analytics_outlined)),
              Tab(text: 'プラン作成', icon: Icon(Icons.edit_calendar_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AiAnalysisTab(date: date, cards: cards),
            AiPlanningTab(date: date, cards: cards),
          ],
        ),
      ),
    );
  }
}
