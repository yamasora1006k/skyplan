import 'package:sky_plan/features/home/models/calendar_event.dart';
import 'package:sky_plan/features/home/models/location_point.dart';
import 'package:sky_plan/features/home/models/learned_place.dart';
import 'package:sky_plan/features/home/models/weather_hourly.dart';
import 'package:sky_plan/features/home/models/plan_card.dart';
import 'package:sky_plan/features/home/models/notification_record.dart';

/// リポジトリ抽象インターフェース
/// 将来のAPI接続用に設計
abstract class IRepository {
  // カレンダーイベント
  Future<List<CalendarEvent>> getCalendarEvents();
  Future<List<CalendarEvent>> getTodayEvents();
  Future<List<CalendarEvent>> getEventsForDate(DateTime date);
  
  // 位置履歴
  Future<List<LocationPoint>> getLocationHistory();
  Future<List<LocationPoint>> getNightLocations(); // 23:00〜06:00
  
  // 学習済み場所
  Future<List<LearnedPlace>> getLearnedPlaces();
  Future<void> updateLearnedPlace(LearnedPlace place);
  Future<void> addLearnedPlace(LearnedPlace place);
  
  // 天気
  Future<List<WeatherHourly>> getWeatherHourly();
  Future<WeatherHourly?> getWeatherAt(DateTime time);
  
  // プランカード
  Future<List<PlanCard>> getTodayPlanCards();
  Future<void> savePlanCards(List<PlanCard> cards);
  
  // 通知
  Future<List<NotificationRecord>> getNotificationLogs();
  Future<void> addNotificationLog(NotificationRecord record);
  
  // 状態管理
  Future<int> getRunCount();
  Future<void> incrementRunCount();
  Future<DateTime?> getLastRunTime();
  Future<void> updateLastRunTime();
}
