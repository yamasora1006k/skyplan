import 'package:flutter/material.dart';

class AppTheme {
  // アクセントカラー（iOSライクなブルー）
  static const Color primaryBlue = Color(0xFF007AFF);
  
  // 背景色
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Colors.white;

  // テキストカラー
  static const Color textMain = Color(0xFF000000);
  static const Color textSub = Color(0xFF8E8E93);

  // リスクカラー（彩度を抑えた色）
  static const Color riskHigh = Color(0xFFFF3B30);
  static const Color riskMedium = Color(0xFFFF9500);
  static const Color riskLow = Color(0xFF34C759);

  // グラデーション等は廃止し、単色メインで構成

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // カラー設定
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surface,
        onSurface: textMain,
        error: riskHigh,
        brightness: Brightness.light,
      ),
      
      scaffoldBackgroundColor: background,
      
      // AppBar設定
      appBarTheme: const AppBarTheme(
        backgroundColor: background, // 背景色と同じにして境界をなくす
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      
      // テキスト設定（可読性重視）
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textMain,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textMain,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          color: textMain,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: textMain,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: textSub,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSub,
          letterSpacing: 0.5,
        ),
      ),
      
      // ボタン等は標準スタイルを使用
    );
  }

  static ThemeData get darkTheme {
    // シンプル化のため、一旦ライトテーマベースで定義（必要に応じて拡張）
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        surface: Color(0xFF1C1C1E),
        onSurface: Colors.white,
      ),
    );
  }
}
