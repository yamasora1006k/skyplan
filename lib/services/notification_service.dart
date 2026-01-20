import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../data/repositories/i_repository.dart';
import '../features/home/models/notification_record.dart';
import '../features/home/models/plan_card.dart';

/// 通知サービス
/// ローカル通知のスケジュールとログ保存
class NotificationService {
  final IRepository _repository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  NotificationService(this._repository)
      : _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 初期化
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  /// 権限リクエスト
  Future<bool> requestPermission() async {
    final result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }

  /// 朝の通知をスケジュール（07:00）
  Future<void> scheduleMorningNotification(List<PlanCard> cards) async {
    if (cards.isEmpty) return;

    // 最もリスクの高いカードをピックアップ
    final highRiskCards = cards.where((c) => c.riskScore >= 30).toList();
    
    String title = '☀️ おはようございます';
    String body;
    
    if (highRiskCards.isNotEmpty) {
      final topCard = highRiskCards.reduce((a, b) => a.riskScore > b.riskScore ? a : b);
      body = '今日の注意：${topCard.summary}';
    } else {
      body = '今日も良い一日を！特に注意事項はありません。';
    }

    // 通知をスケジュール
    await _scheduleNotification(
      id: 1,
      title: title,
      body: body,
      scheduledTime: _getNextMorning(),
    );

    // ログに保存
    final record = NotificationRecord(
      id: 'notif_morning_${DateTime.now().millisecondsSinceEpoch}',
      scheduledAt: _getNextMorning(),
      title: title,
      body: body,
      reasonJson: {
        'morning': true,
        'cardCount': cards.length,
        'highRiskCount': highRiskCards.length,
      },
    );
    await _repository.addNotificationLog(record);
  }

  /// イベント前通知をスケジュール
  Future<void> scheduleEventNotifications(List<PlanCard> cards) async {
    int notifId = 100;

    for (final card in cards) {
      if (card.riskScore >= 30) {
        // 30分前に通知
        final notifTime = card.start.subtract(const Duration(minutes: 30));
        
        if (notifTime.isAfter(DateTime.now())) {
          final title = '📅 ${card.placeName}まであと30分';
          final body = card.advice;

          await _scheduleNotification(
            id: notifId++,
            title: title,
            body: body,
            scheduledTime: notifTime,
          );

          // ログに保存
          final record = NotificationRecord(
            id: 'notif_event_${card.id}',
            scheduledAt: notifTime,
            title: title,
            body: body,
            relatedCardId: card.id,
            reasonJson: {
              'event': true,
              'cardId': card.id,
              'riskScore': card.riskScore,
              'reasons': card.reasons.map((r) => r.toJson()).toList(),
            },
          );
          await _repository.addNotificationLog(record);
        }
      }
    }
  }

  /// 通知をスケジュール
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'skyplan_channel',
      'SkyPlan通知',
      channelDescription: '天気と予定のお知らせ',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 次の朝7時を取得
  DateTime _getNextMorning() {
    final now = DateTime.now();
    var morning = DateTime(now.year, now.month, now.day, 7, 0);
    
    if (morning.isBefore(now)) {
      morning = morning.add(const Duration(days: 1));
    }
    
    return morning;
  }

  /// 全通知をキャンセル
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 通知ログを取得
  Future<List<NotificationRecord>> getNotificationLogs() async {
    return await _repository.getNotificationLogs();
  }
}
