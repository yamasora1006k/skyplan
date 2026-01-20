import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_plan/app/app_theme.dart';
import '../../data/repositories/fake_repository.dart';
import '../../services/home_estimation_service.dart';
import '../../services/plan_card_service.dart';
import '../../services/notification_service.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import 'models/plan_card.dart';
import 'models/weather_hourly.dart';
import 'models/learned_place.dart';
import 'widgets/simple_card_widget.dart';
import 'widgets/map_view.dart';
import '../card_detail/card_detail_body.dart';
import 'ai_assistant_page.dart';

/// ホーム画面 (Simple & Clear)
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final _repository = FakeRepository();
  late final HomeEstimationService _homeEstimationService;
  late final PlanCardService _planCardService;
  late final NotificationService _notificationService;

  final DateTime _demoStart = DateTime(2026, 1, 13);
  final DateTime _demoEnd = DateTime(2026, 1, 26);
  final DateTime _demoToday = DateTime(2026, 1, 20);

  DateTime _selectedDate = DateTime(2026, 1, 20);
  LearnedPlace? _homePlace;
  late final PageController _dialController;
  double _currentDialPage = 0;
  List<PlanCard> _cards = [];
  List<WeatherHourly> _allWeather = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _homeEstimationService = HomeEstimationService(_repository);
    _planCardService = PlanCardService(_repository);
    _notificationService = NotificationService(_repository);
    final initialIndex = _dateToIndex(_selectedDate);
    _dialController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.62,
    );
    _currentDialPage = initialIndex.toDouble();
    _dialController.addListener(_onDialScroll);
    _initializeApp();
  }

  @override
  void dispose() {
    _dialController.removeListener(_onDialScroll);
    _dialController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _isLoading = true);

      await _repository.incrementRunCount();
      await _homeEstimationService.progressLearning();
      _allWeather = await _repository.getWeatherHourly();

      await _notificationService.initialize();
      await _notificationService.requestPermission();

      final places = await _repository.getLearnedPlaces();
      LearnedPlace? foundHome;
      for (final p in places) {
        if (p.type == PlaceType.home) {
          foundHome = p;
          break;
        }
      }
      _homePlace = foundHome ?? (places.isNotEmpty ? places.first : null);

      await _loadCardsForDate(_selectedDate);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadCardsForDate(DateTime date) async {
    final requestedDate = date;
    setState(() {
      _selectedDate = requestedDate;
    });

    final cards = await _planCardService.generateCardsForDate(requestedDate);
    if (!mounted || !_isSameDay(_selectedDate, requestedDate)) return;

    setState(() {
      _cards = cards;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading...'));
    }
    if (_error != null) {
      return Scaffold(
        body: ErrorView(message: _error!, onRetry: _initializeApp),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAiSuggestion,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildWeatherHeader(),
            _buildWeeklyCalendar(),
            Expanded(
              child: _cards.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        return SimpleCardWidget(
                          card: _cards[index],
                          onTap: () => _showCardDetail(_cards[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherHeader() {
    final weather = _getWeatherForDate(_selectedDate);
    final isToday = _isSameDay(_selectedDate, _demoToday);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryBlue.withValues(alpha: 0.05), Colors.white],
        ),
      ),
      child: Column(
        children: [
          // 日付とMapボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isSameDay(_selectedDate, _demoToday)
                  ? const SizedBox(width: 40)
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: AppTheme.primaryBlue,
                      padding: const EdgeInsets.only(left: 4, right: 8),
                      constraints: const BoxConstraints(),
                      onPressed: _goToToday,
                      tooltip: '今日に戻る',
                    ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('M月d日 (E)', 'ja_JP').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Mapボタン
              IconButton(
                icon: const Icon(Icons.map_outlined, size: 24),
                color: AppTheme.primaryBlue,
                onPressed: _showMapView,
                tooltip: '移動経路を見る',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 天気アイコン（大）
          Text(
            weather?.weatherIcon ?? '☀️',
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 12),

          // 気温（大）
          Text(
            weather != null
                ? '${weather.temperature2m.toStringAsFixed(0)}°'
                : '--°',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w200,
              color: AppTheme.textMain,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // 降水確率
          if (weather != null)
            Text(
              '降水確率 ${weather.precipitationProbability}%',
              style: const TextStyle(fontSize: 15, color: AppTheme.textSub),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final days = _demoDays;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Container(
                  width: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: IgnorePointer(
              child: Container(
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PageView.builder(
              controller: _dialController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (index >= 0 && index < days.length) {
                  _loadCardsForDate(days[index]);
                }
              },
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final distance = (index - _currentDialPage).abs();
                final clamped = distance.clamp(0.0, 1.0);
                final scale = 0.88 + (0.08 * (1.0 - clamped));
                final opacity = 0.35 + (0.65 * (1.0 - clamped));
                final isSelected = clamped < 0.5;
                final isToday = _isSameDay(day, _demoToday);
                final weather = _getWeatherForDate(day);

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _animateDialToIndex(index),
                      child: _buildDialDayTile(
                        day,
                        isSelected,
                        isToday,
                        weather,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialDayTile(
    DateTime day,
    bool isSelected,
    bool isToday,
    WeatherHourly? weather,
  ) {
    final textColor = isSelected ? Colors.white : AppTheme.textMain;
    final subColor = isSelected ? Colors.white70 : AppTheme.textSub;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? AppTheme.primaryBlue : Colors.black)
                .withValues(alpha: isSelected ? 0.25 : 0.05),
            blurRadius: isSelected ? 8 : 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E', 'ja_JP').format(day),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${day.month}/${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                weather?.weatherIcon ?? '—',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                weather != null
                    ? '${weather.temperature2m.toStringAsFixed(0)}°'
                    : '--°',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 48, color: AppTheme.textSub),
          SizedBox(height: 16),
          Text('この日の予定はありません', style: TextStyle(color: AppTheme.textSub)),
        ],
      ),
    );
  }

  WeatherHourly? _getWeatherForDate(DateTime date) {
    final noonish = DateTime(date.year, date.month, date.day, 12);
    WeatherHourly? closest;
    int minDiff = 99999999;

    for (final w in _allWeather) {
      if (w.time.year == date.year &&
          w.time.month == date.month &&
          w.time.day == date.day) {
        final diff = (w.time.difference(noonish).inMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closest = w;
        }
      }
    }
    return closest;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> get _demoDays {
    final dayCount = _demoEnd.difference(_demoStart).inDays + 1;
    return List.generate(
      dayCount,
      (index) => _demoStart.add(Duration(days: index)),
    );
  }

  void _onDialScroll() {
    final page = _dialController.page;
    if (page == null) return;
    if ((page - _currentDialPage).abs() < 0.001) return;
    setState(() {
      _currentDialPage = page;
    });
  }

  int _dateToIndex(DateTime date) {
    final maxIndex = _demoEnd.difference(_demoStart).inDays;
    return date.difference(_demoStart).inDays.clamp(0, maxIndex).toInt();
  }

  void _goToToday() {
    final todayIndex = _dateToIndex(_demoToday);
    _animateDialToIndex(todayIndex);
    // 万が一スクロールが発火しなくても即座に同期させる
    if (_dialController.hasClients &&
        _dialController.page != null &&
        (_dialController.page!.round() == todayIndex)) {
      _loadCardsForDate(_demoToday);
    }
  }

  void _animateDialToIndex(int index) {
    if (!_dialController.hasClients || index == _currentDialPage.round()) {
      return;
    }
    _dialController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _showCardDetail(PlanCard card) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CardDetailBody(card: card)));
  }

  void _showMapView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapView(
        selectedDate: _selectedDate,
        cards: _cards,
        homePlace: _homePlace,
      ),
    );
  }



  void _showAiSuggestion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiAssistantPage(
          date: _selectedDate,
          cards: _cards,
        ),
      ),
    );
  }
}
