import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../features/home/home_body.dart';

class SkyPlanApp extends StatelessWidget {
  const SkyPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyPlan',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const HomeBody(), // ナビゲーション削除、ホーム画面のみ
    );
  }
}
