import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 状態管理サービス
/// ローカルstate JSONの読み書き
class StateService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  /// 起動回数を取得
  Future<int> getRunCount() async {
    try {
      final file = await _getLocalFile('state_last_run.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;
        return data['runCount'] as int? ?? 0;
      }
    } catch (e) {
      // エラー時は0を返す
    }
    return 0;
  }

  /// 起動回数をインクリメント
  Future<void> incrementRunCount() async {
    final count = await getRunCount();
    await _saveRunState(count + 1);
  }

  /// 最終起動日時を取得
  Future<DateTime?> getLastRunTime() async {
    try {
      final file = await _getLocalFile('state_last_run.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;
        final lastRun = data['lastRun'] as String?;
        return lastRun != null ? DateTime.parse(lastRun) : null;
      }
    } catch (e) {
      // エラー時はnullを返す
    }
    return null;
  }

  /// 起動状態を保存
  Future<void> _saveRunState(int count) async {
    final file = await _getLocalFile('state_last_run.json');
    final data = {
      'runCount': count,
      'lastRun': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(json.encode(data));
  }

  /// ユーザープロファイルを取得
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final file = await _getLocalFile('state_user_profile.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return json.decode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      // エラー時はnullを返す
    }
    return null;
  }

  /// ユーザープロファイルを保存
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final file = await _getLocalFile('state_user_profile.json');
    await file.writeAsString(json.encode(profile));
  }

  /// デモシナリオを取得
  Future<String> getDemoScenario() async {
    final profile = await getUserProfile();
    return profile?['demoScenario'] as String? ?? 'ExamLife_20251215_1228';
  }

  /// 初回起動かどうか
  Future<bool> isFirstRun() async {
    final count = await getRunCount();
    return count == 0;
  }

  /// 全状態をリセット（デバッグ用）
  Future<void> resetAllState() async {
    final files = [
      'state_last_run.json',
      'state_learned_places.json',
      'state_notification_log.json',
      'state_plan_cards.json',
      'state_user_profile.json',
    ];

    for (final filename in files) {
      try {
        final file = await _getLocalFile(filename);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // 削除失敗は無視
      }
    }
  }
}
