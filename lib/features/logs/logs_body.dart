import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sky_plan/app/app_theme.dart';
import '../../data/repositories/fake_repository.dart';
import '../home/models/learned_place.dart';
import '../home/models/notification_record.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';

/// ログ画面 (Simple Version)
class LogsBody extends StatefulWidget {
  const LogsBody({super.key});

  @override
  State<LogsBody> createState() => _LogsBodyState();
}

class _LogsBodyState extends State<LogsBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = FakeRepository();

  List<LearnedPlace> _learnedPlaces = [];
  List<NotificationRecord> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _learnedPlaces = await _repository.getLearnedPlaces();
      _notifications = await _repository.getNotificationLogs();
      _notifications.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(7),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '場所'),
                Tab(text: '履歴'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingView(message: '読み込み中...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadData)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLearnedPlacesList(),
                    _buildNotificationsList(),
                  ],
                ),
    );
  }

  Widget _buildLearnedPlacesList() {
    if (_learnedPlaces.isEmpty) {
      return const Center(child: Text('学習済みの場所はありません'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _learnedPlaces.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _learnedPlaces[index];
        return _buildPlaceItem(place);
      },
    );
  }

  Widget _buildPlaceItem(LearnedPlace place) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              shape: BoxShape.circle,
            ),
            child: Text(place.type.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name ?? place.type.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(
                  'Confidence: ${(place.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                ),
              ],
            ),
          ),
          _buildConfidenceBadge(place.confidence),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('通知履歴はありません'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationRecord notification) {
    final dateFormat = DateFormat('M/d HH:mm');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    Text(
                      dateFormat.format(notification.scheduledAt),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSub),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color;
    String text;
    
    if (confidence >= 0.7) {
      color = Colors.green;
      text = 'High';
    } else if (confidence >= 0.4) {
      color = Colors.orange;
      text = 'Mid';
    } else {
      color = Colors.grey;
      text = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
