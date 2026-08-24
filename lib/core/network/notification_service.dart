import '../models/notification_models.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService({required ApiService api}) : _api = api;

  final ApiService _api;

  Future<List<NotificationItem>> getMyNotifications() async {
    try {
      final body = await _api.get('/my-notifications');
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => NotificationItem.fromRecipientJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<List<NotificationItem>> getUnreadNotifications() async {
    try {
      final body = await _api.get('/my-notifications', query: {'unread_only': '1'});
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => NotificationItem.fromRecipientJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final body = await _api.get('/my-notifications/count');
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return (data['count'] as int?) ?? 0;
      }
      return 0;
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<NotificationRecipient> markAsRead(int notificationId) async {
    try {
      final body = await _api.post('/my-notifications/$notificationId/read');
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return NotificationRecipient.fromJson(data);
      }
      throw ApiFailure('Invalid response format');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final body = await _api.post('/my-notifications/read-all');
      return body;
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<NotificationRecipient> markAsUnread(int notificationId) async {
    try {
      final body = await _api.post('/my-notifications/$notificationId/unread');
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return NotificationRecipient.fromJson(data);
      }
      throw ApiFailure('Invalid response format');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await _api.delete('/my-notifications/$notificationId');
    } catch (error) {
      throw ApiService.failureFrom(error);
    }
  }
}
