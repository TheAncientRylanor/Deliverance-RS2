import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:deliverance_desktop/models/app_notification.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:deliverance_desktop/utils/notification_hub_client.dart';
import 'package:http/http.dart' as http;

class NotificationProvider extends BaseProvider<AppNotification> {
  static const _pageSize = 20;

  static const _retryInterval = Duration(seconds: 30);

  List<AppNotification> items = [];
  int unreadCount = 0;
  bool hasLoadError = false;

  late final _hub = NotificationHubClient(
    onCreated: _handleCreated,
    onReconnected: load,
  );
  Timer? _retryTimer;
  bool _isActive = false;

  NotificationProvider() : super("Notification") {
    AuthProvider.instance.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  AppNotification fromJson(data) => AppNotification.fromJson(data);

  void _onAuthChanged() {
    final isLoggedIn = AuthProvider.instance.isAuthenticated;
    if (isLoggedIn == _isActive) return;
    _isActive = isLoggedIn;
    if (isLoggedIn) {
      _retryTimer = Timer.periodic(_retryInterval, (_) => _connect());
      _connect();
    } else {
      _disconnect();
    }
  }

  Future<void> _connect() async {
    if (!_hub.isDisconnected) return;
    try {
      await _hub.start();
      if (!_isActive) await _hub.stop();
    } catch (_) {
    }
    await load();
  }

  void _disconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _hub.stop();
    items = [];
    unreadCount = 0;
    hasLoadError = false;
    notifyListeners();
  }

  Future<void> load() async {
    if (!_isActive) return;
    try {
      final result = await get(filter: {'PageSize': _pageSize});
      final count = await _getUnreadCount();
      if (!_isActive) return;
      items = result.items ?? [];
      unreadCount = count;
      hasLoadError = false;
    } catch (_) {
      if (!_isActive) return;
      hasLoadError = true;
    }
    notifyListeners();
  }

  Future<int> _getUnreadCount() async {
    final response = await sendWithRetry(
      () => http.get(_uri("UnreadCount"), headers: createHeaders()),
    );
    return jsonDecode(response.body) as int;
  }

  void _handleCreated(AppNotification notification) {
    if (items.any((x) => x.id == notification.id)) return;
    items = [notification, ...items].take(_pageSize).toList();
    unreadCount++;
    notifyListeners();
  }

  Future<void> markAsRead(int id) async {
    final notification = items.where((x) => x.id == id).firstOrNull;
    if (notification == null || notification.isRead) return;

    await sendWithRetry(
      () => http.put(_uri("Read/$id"), headers: createHeaders()),
    );
    notification.isRead = true;
    unreadCount = max(0, unreadCount - 1);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await sendWithRetry(
      () => http.put(_uri("ReadAll"), headers: createHeaders()),
    );
    for (final notification in items) {
      notification.isRead = true;
    }
    unreadCount = 0;
    notifyListeners();
  }

  Uri _uri(String path) => Uri.parse("${BaseProvider.baseUrl}$endpoint/$path");

  @override
  void dispose() {
    AuthProvider.instance.removeListener(_onAuthChanged);
    _retryTimer?.cancel();
    _hub.stop();
    super.dispose();
  }
}
