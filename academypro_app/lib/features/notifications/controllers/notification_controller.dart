import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_item.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool loading;
  final String? error;
  final String filter; // 'all' or 'unread'

  NotificationState({
    required this.notifications,
    required this.unreadCount,
    required this.loading,
    this.error,
    this.filter = 'all',
  });

  factory NotificationState.initial() => NotificationState(
        notifications: [],
        unreadCount: 0,
        loading: false,
      );

  List<NotificationItem> get filteredNotifications {
    if (filter == 'unread') {
      return notifications.where((n) => !n.isRead).toList();
    }
    return notifications;
  }

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? loading,
    String? error,
    String? filter,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      filter: filter ?? this.filter,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;

  NotificationNotifier(this._apiClient) : super(NotificationState.initial()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final response = await _apiClient.getAndCache('/api/notifications');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final List notifList = data['notifications'] ?? [];
        final List<NotificationItem> items =
            notifList.map((n) => NotificationItem.fromJson(n)).toList();
        final int unread = data['unreadCount'] ?? items.where((i) => !i.isRead).length;

        state = state.copyWith(
          notifications: items,
          unreadCount: unread,
          loading: false,
        );
      } else {
        state = state.copyWith(notifications: [], unreadCount: 0, loading: false);
      }
    } catch (e) {
      state = state.copyWith(notifications: [], unreadCount: 0, loading: false);
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> markAsRead(int id) async {
    final updatedList = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final newUnread = updatedList.where((n) => !n.isRead).length;
    state = state.copyWith(notifications: updatedList, unreadCount: newUnread);

    try {
      await _apiClient.dio.post('/api/notifications/$id/read');
    } catch (_) {
      // Handled silently
    }
  }

  Future<void> markAllAsRead() async {
    final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updatedList, unreadCount: 0);

    try {
      await _apiClient.dio.post('/api/notifications/read-all');
    } catch (_) {
      // Handled silently
    }
  }

  Future<void> deleteNotification(int id) async {
    final updatedList = state.notifications.where((n) => n.id != id).toList();
    final newUnread = updatedList.where((n) => !n.isRead).length;
    state = state.copyWith(notifications: updatedList, unreadCount: newUnread);

    try {
      await _apiClient.dio.post('/api/notifications/$id/delete');
    } catch (_) {
      try {
        await _apiClient.dio.delete('/api/notifications/$id');
      } catch (_) {}
    }
  }

  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async {
    try {
      await _apiClient.dio.post('/api/notifications/send', data: {
        'title': title,
        'body': body,
        'type': type,
      });
      await fetchNotifications();
    } catch (_) {
      // Handled silently
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationNotifier(apiClient);
});
