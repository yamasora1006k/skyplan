import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';

import '../../features/home/models/calendar_event.dart';
import '../../features/home/models/location_point.dart';
import '../../features/home/models/learned_place.dart';
import '../../features/home/models/weather_hourly.dart';
import '../../features/home/models/plan_card.dart';
import '../../features/home/models/notification_record.dart';
import 'i_repository.dart';

/// Fakeリポジトリ
/// assets + ローカルstateから読み書き（プロトタイプ用）
class FakeRepository implements IRepository {
  List<CalendarEvent>? _cachedEvents;
  List<LocationPoint>? _cachedLocations;
  List<WeatherHourly>? _cachedWeather;
  List<LearnedPlace>? _cachedPlaces;
  List<PlanCard>? _cachedPlanCards;
  List<NotificationRecord>? _cachedNotifications;
  
  // ローカルストレージのパスを取得
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  
  Future<File> _getLocalFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }
  
  // ===================
  // カレンダーイベント
  // ===================
  
  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    if (_cachedEvents != null) return _cachedEvents!;
    
    final jsonString = await rootBundle.loadString(
      'assets/demo/businessman_calendar_20260113_20260126.json'
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> events = data['events'];
    
    _cachedEvents = events
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return _cachedEvents!;
  }
  
  @override
  Future<List<CalendarEvent>> getTodayEvents() async {
    // デモ用：1/20を「今日」として扱う
    final demoToday = DateTime(2026, 1, 20);
    return getEventsForDate(demoToday);
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final events = await getCalendarEvents();
    
    return events.where((e) {
      return e.start.year == date.year &&
             e.start.month == date.month &&
             e.start.day == date.day;
    }).toList();
  }
  
  // ===================
  // 位置履歴
  // ===================
  
  @override
  Future<List<LocationPoint>> getLocationHistory() async {
    if (_cachedLocations != null) return _cachedLocations!;
    
    final csvString = await rootBundle.loadString(
      'assets/demo/examlife_location_history_20251215_20251228.csv'
    );
    
    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
    
    // ヘッダーをスキップ
    _cachedLocations = rows.skip(1).map((row) => LocationPoint.fromCsv(row)).toList();
    
    return _cachedLocations!;
  }
  
  @override
  Future<List<LocationPoint>> getNightLocations() async {
    final locations = await getLocationHistory();
    
    return locations.where((loc) {
      final hour = loc.timestamp.hour;
      return hour >= 23 || hour < 6; // 23:00〜06:00
    }).toList();
  }
  
  // ===================
  // 学習済み場所
  // ===================
  
  @override
  Future<List<LearnedPlace>> getLearnedPlaces() async {
    if (_cachedPlaces != null) return _cachedPlaces!;
    
    // まずローカルstate JSONを確認
    try {
      final file = await _getLocalFile('state_learned_places.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> places = data['places'];
        _cachedPlaces = places
            .map((e) => LearnedPlace.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cachedPlaces!;
      }
    } catch (e) {
      // ローカルファイルがなければ初期データを使用
    }
    
    // 初期データを読み込み
    final jsonString = await rootBundle.loadString(
      'assets/demo/businessman_learned_places.json'
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> places = data['places'];
    
    _cachedPlaces = places
        .map((e) => LearnedPlace.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return _cachedPlaces!;
  }
  
  @override
  Future<void> updateLearnedPlace(LearnedPlace place) async {
    final places = await getLearnedPlaces();
    final index = places.indexWhere((p) => p.type == place.type);
    
    if (index >= 0) {
      places[index] = place;
    } else {
      places.add(place);
    }
    
    _cachedPlaces = places;
    await _saveLearnedPlaces();
  }
  
  @override
  Future<void> addLearnedPlace(LearnedPlace place) async {
    final places = await getLearnedPlaces();
    places.add(place);
    _cachedPlaces = places;
    await _saveLearnedPlaces();
  }
  
  Future<void> _saveLearnedPlaces() async {
    if (_cachedPlaces == null) return;
    
    final file = await _getLocalFile('state_learned_places.json');
    final data = {
      'places': _cachedPlaces!.map((p) => p.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(json.encode(data));
  }
  
  // ===================
  // 天気
  // ===================
  
  @override
  Future<List<WeatherHourly>> getWeatherHourly() async {
    if (_cachedWeather != null) return _cachedWeather!;
    
    final jsonString = await rootBundle.loadString(
      'assets/demo/businessman_weather_hourly_20260113_20260126.json'
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> hourly = data['hourly'];
    
    _cachedWeather = hourly
        .map((e) => WeatherHourly.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return _cachedWeather!;
  }
  
  @override
  Future<WeatherHourly?> getWeatherAt(DateTime time) async {
    final weather = await getWeatherHourly();
    
    // 最も近い時間の天気を探す
    WeatherHourly? closest;
    int minDiff = 99999999;
    
    for (final w in weather) {
      final diff = (w.time.difference(time).inMinutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = w;
      }
    }
    
    return closest;
  }
  
  // ===================
  // プランカード
  // ===================
  
  @override
  Future<List<PlanCard>> getTodayPlanCards() async {
    if (_cachedPlanCards != null) return _cachedPlanCards!;
    
    try {
      final file = await _getLocalFile('state_plan_cards.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> cards = data['cards'];
        _cachedPlanCards = cards
            .map((e) => PlanCard.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cachedPlanCards!;
      }
    } catch (e) {
      // ファイルがなければ空リスト
    }
    
    return [];
  }
  
  @override
  Future<void> savePlanCards(List<PlanCard> cards) async {
    _cachedPlanCards = cards;
    final file = await _getLocalFile('state_plan_cards.json');
    final data = {
      'cards': cards.map((c) => c.toJson()).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(json.encode(data));
  }
  
  // ===================
  // 通知ログ
  // ===================
  
  @override
  Future<List<NotificationRecord>> getNotificationLogs() async {
    if (_cachedNotifications != null) return _cachedNotifications!;
    
    try {
      final file = await _getLocalFile('state_notification_log.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> logs = data['logs'];
        _cachedNotifications = logs
            .map((e) => NotificationRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return _cachedNotifications!;
      }
    } catch (e) {
      // ファイルがなければ空リスト
    }
    
    return [];
  }
  
  @override
  Future<void> addNotificationLog(NotificationRecord record) async {
    final logs = await getNotificationLogs();
    logs.add(record);
    _cachedNotifications = logs;
    
    final file = await _getLocalFile('state_notification_log.json');
    final data = {
      'logs': logs.map((l) => l.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(json.encode(data));
  }
  
  // ===================
  // 状態管理
  // ===================
  
  @override
  Future<int> getRunCount() async {
    try {
      final file = await _getLocalFile('state_last_run.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = json.decode(jsonString);
        return data['runCount'] as int? ?? 0;
      }
    } catch (e) {
      // ファイルがなければ0
    }
    return 0;
  }
  
  @override
  Future<void> incrementRunCount() async {
    final count = await getRunCount();
    final lastRun = DateTime.now();
    
    final file = await _getLocalFile('state_last_run.json');
    final data = {
      'runCount': count + 1,
      'lastRun': lastRun.toIso8601String(),
    };
    await file.writeAsString(json.encode(data));
  }
  
  @override
  Future<DateTime?> getLastRunTime() async {
    try {
      final file = await _getLocalFile('state_last_run.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = json.decode(jsonString);
        final lastRun = data['lastRun'] as String?;
        return lastRun != null ? DateTime.parse(lastRun) : null;
      }
    } catch (e) {
      // ファイルがなければnull
    }
    return null;
  }
  
  @override
  Future<void> updateLastRunTime() async {
    await incrementRunCount();
  }
}
