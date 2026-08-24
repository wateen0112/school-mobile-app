# Notification API - Mobile App Developer Guide

## Overview

This document provides a comprehensive guide for mobile app developers (Flutter/Dart) to integrate the **Notification Service** into the school management mobile application. It covers endpoints, request/response shapes, unread counts, and navigation routes.

---

## Table of Contents

1. [Base Configuration](#base-configuration)
2. [Authentication](#authentication)
3. [Response Format](#response-format)
4. [Get My Notifications (Inbox)](#get-my-notifications-inbox)
5. [Get Unread Notifications Only](#get-unread-notifications-only)
6. [Get Unread Count](#get-unread-count)
7. [Mark Notification as Read](#mark-notification-as-read)
8. [Mark All Notifications as Read](#mark-all-notifications-as-read)
9. [Mark Notification as Unread](#mark-notification-as-unread)
10. [Delete Notification from Inbox](#delete-notification-from-inbox)
11. [Notification Data Models (Dart)](#notification-data-models-dart)
12. [Service Layer (Dart)](#service-layer-dart)
13. [State Management (Provider/Riverpod)](#state-management-providerriverpod)
14. [UI Components](#ui-components)
15. [Navigation Routes](#navigation-routes)
16. [Push Notifications (Firebase)](#push-notifications-firebase)
17. [Error Handling](#error-handling)

---

## Base Configuration

```dart
const String API_BASE_URL = 'https://your-domain.com/api';
const Map<String, String> defaultHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};
```

---

## Authentication

All notification endpoints require a **Bearer Token** in the Authorization header.

```dart
// Add token to headers
Map<String, String> getAuthHeaders(String token) {
  return {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
```

---

## Response Format

Every API response follows this structure:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": [],
  "error": null
}
```

```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonData,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonData(json['data']) : null,
      error: json['error'],
    );
  }
}
```

---

## Get My Notifications (Inbox)

### Endpoint

```
GET /api/my-notifications
```

### Description

Retrieve all notifications for the currently authenticated user (student, teacher, or parent). Returns notifications ordered by newest first.

### Request

```dart
Future<ApiResponse<List<NotificationItem>>> getMyNotifications(String token) async {
  final response = await http.get(
    Uri.parse('$API_BASE_URL/my-notifications'),
    headers: getAuthHeaders(token),
  );

  final json = jsonDecode(response.body);
  return ApiResponse.fromJson(
    json,
    (data) => (data as List).map((e) => NotificationItem.fromJson(e)).toList(),
  );
}
```

### Response Shape (200 OK)

```json
{
  "success": true,
  "message": "My notifications retrieved successfully",
  "data": [
    {
      "id": 1,
      "notification_id": 5,
      "recipient_id": 14,
      "recipient_type": "App\\Models\\Student",
      "is_read": false,
      "read_at": null,
      "created_at": "2026-06-24T10:00:00.000000Z",
      "updated_at": "2026-06-24T10:00:00.000000Z",
      "notification": {
        "id": 5,
        "title": "School Holiday Announcement",
        "body": "School will be closed next Monday for a public holiday.",
        "type": "general",
        "sender_id": 7,
        "sender_type": "App\\User",
        "target_role": null,
        "data": null,
        "created_at": "2026-06-24T10:00:00.000000Z",
        "updated_at": "2026-06-24T10:00:00.000000Z"
      }
    },
    {
      "id": 2,
      "notification_id": 3,
      "recipient_id": 14,
      "recipient_type": "App\\Models\\Student",
      "is_read": true,
      "read_at": "2026-06-24T09:45:00.000000Z",
      "created_at": "2026-06-24T09:30:00.000000Z",
      "updated_at": "2026-06-24T09:45:00.000000Z",
      "notification": {
        "id": 3,
        "title": "Fee Reminder",
        "body": "Please pay the remaining fees before the deadline.",
        "type": "targeted",
        "sender_id": 7,
        "sender_type": "App\\User",
        "target_role": null,
        "data": {
          "targets": [
            { "id": 14, "type": "student" }
          ]
        },
        "created_at": "2026-06-24T09:30:00.000000Z",
        "updated_at": "2026-06-24T09:30:00.000000Z"
      }
    }
  ]
}
```

---

## Get Unread Notifications Only

### Endpoint

```
GET /api/my-notifications?unread_only=1
```

### Description

Filter the inbox to show only unread notifications. Useful for the "Unread" tab in the app.

### Request

```dart
Future<ApiResponse<List<NotificationItem>>> getUnreadNotifications(String token) async {
  final response = await http.get(
    Uri.parse('$API_BASE_URL/my-notifications?unread_only=1'),
    headers: getAuthHeaders(token),
  );

  final json = jsonDecode(response.body);
  return ApiResponse.fromJson(
    json,
    (data) => (data as List).map((e) => NotificationItem.fromJson(e)).toList(),
  );
}
```

---

## Get Unread Count

### Endpoint

There is no dedicated endpoint for unread count. Calculate it client-side from the inbox response, or fetch unread-only notifications and count them.

### Recommended Approach

```dart
// Fetch unread notifications and count them
Future<int> getUnreadCount(String token) async {
  final response = await getUnreadNotifications(token);
  if (response.success && response.data != null) {
    return response.data!.length;
  }
  return 0;
}
```

### Alternative: Store in Local State

```dart
// After fetching all notifications, compute unread count
int unreadCount = notifications.where((n) => !n.isRead).length;
```

---

## Mark Notification as Read

### Endpoint

```
POST /api/my-notifications/{id}/read
```

### Description

Mark a specific notification as read. Call this when the user opens/reads a notification.

### Request

```dart
Future<ApiResponse<NotificationRecipient>> markAsRead(String token, int notificationId) async {
  final response = await http.post(
    Uri.parse('$API_BASE_URL/my-notifications/$notificationId/read'),
    headers: getAuthHeaders(token),
  );

  final json = jsonDecode(response.body);
  return ApiResponse.fromJson(
    json,
    (data) => NotificationRecipient.fromJson(data),
  );
}
```

### Response Shape (200 OK)

```json
{
  "success": true,
  "message": "Notification marked as read",
  "data": {
    "id": 1,
    "notification_id": 5,
    "recipient_id": 14,
    "recipient_type": "App\\Models\\Student",
    "is_read": true,
    "read_at": "2026-06-24T10:30:00.000000Z",
    "notification": {
      "id": 5,
      "title": "School Holiday Announcement",
      "body": "School will be closed next Monday for a public holiday.",
      "type": "general",
      "created_at": "2026-06-24T10:00:00.000000Z"
    }
  }
}
```

---

## Mark All Notifications as Read

### Endpoint

```
POST /api/my-notifications/read-all
```

### Description

Mark all unread notifications as read in one call. Use this for the "Mark all as read" button.

### Request

```dart
Future<ApiResponse<Map<String, dynamic>>> markAllAsRead(String token) async {
  final response = await http.post(
    Uri.parse('$API_BASE_URL/my-notifications/read-all'),
    headers: getAuthHeaders(token),
  );

  final json = jsonDecode(response.body);
  return ApiResponse.fromJson(
    json,
    (data) => data as Map<String, dynamic>,
  );
}
```

### Response Shape (200 OK)

```json
{
  "success": true,
  "message": "All notifications marked as read",
  "count": 5
}
```

---

## Mark Notification as Unread

### Endpoint

```
POST /api/my-notifications/{id}/unread
```

### Description

Mark a notification as unread. Useful if the user wants to revisit it later.

### Request

```dart
Future<ApiResponse<NotificationRecipient>> markAsUnread(String token, int notificationId) async {
  final response = await http.post(
    Uri.parse('$API_BASE_URL/my-notifications/$notificationId/unread'),
    headers: getAuthHeaders(token),
  );

  final json = jsonDecode(response.body);
  return ApiResponse.fromJson(
    json,
    (data) => NotificationRecipient.fromJson(data),
  );
}
```

### Response Shape (200 OK)

```json
{
  "success": true,
  "message": "Notification marked as unread",
  "data": {
    "id": 1,
    "notification_id": 5,
    "recipient_id": 14,
    "recipient_type": "App\\Models\\Student",
    "is_read": false,
    "read_at": null,
    "notification": {
      "id": 5,
      "title": "School Holiday Announcement",
      "body": "School will be closed next Monday for a public holiday.",
      "type": "general",
      "created_at": "2026-06-24T10:00:00.000000Z"
    }
  }
}
```

---

## Delete Notification from Inbox

### Endpoint

```
DELETE /api/my-notifications/{id}
```

### Description

Remove a notification from the user's inbox. This only affects the current user — other recipients still see it.

### Request

```dart
Future<ApiResponse<void>> deleteNotification(String token, int notificationId) async {
  final response = await http.delete(
    Uri.parse('$API_BASE_URL/my-notifications/$notificationId'),
    headers: getAuthHeaders(token),
  );

  final json = jsonDecode(response.body);
  return ApiResponse.fromJson(
    json,
    (data) => null,
  );
}
```

### Response Shape (200 OK)

```json
{
  "success": true,
  "message": "Notification removed from your inbox"
}
```

---

## Notification Data Models (Dart)

### Notification Model

```dart
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type; // 'general', 'targeted', 'role'
  final int? senderId;
  final String? senderType;
  final String? targetRole;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.senderId,
    this.senderType,
    this.targetRole,
    this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      targetRole: json['target_role'],
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'sender_id': senderId,
      'sender_type': senderType,
      'target_role': targetRole,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### NotificationRecipient Model

```dart
class NotificationRecipient {
  final int id;
  final int notificationId;
  final int recipientId;
  final String recipientType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotificationModel? notification;

  NotificationRecipient({
    required this.id,
    required this.notificationId,
    required this.recipientId,
    required this.recipientType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.notification,
  });

  factory NotificationRecipient.fromJson(Map<String, dynamic> json) {
    return NotificationRecipient(
      id: json['id'],
      notificationId: json['notification_id'],
      recipientId: json['recipient_id'],
      recipientType: json['recipient_type'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      notification: json['notification'] != null
          ? NotificationModel.fromJson(json['notification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_id': notificationId,
      'recipient_id': recipientId,
      'recipient_type': recipientType,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notification': notification?.toJson(),
    };
  }
}
```

### NotificationItem (Combined for UI)

```dart
class NotificationItem {
  final int id; // recipient pivot id
  final int notificationId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime receivedAt; // created_at from recipient
  final DateTime sentAt; // created_at from notification

  NotificationItem({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.readAt,
    required this.receivedAt,
    required this.sentAt,
  });

  factory NotificationItem.fromRecipientJson(Map<String, dynamic> json) {
    final notification = json['notification'];
    return NotificationItem(
      id: json['id'],
      notificationId: json['notification_id'],
      title: notification['title'],
      body: notification['body'],
      type: notification['type'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      receivedAt: DateTime.parse(json['created_at']),
      sentAt: DateTime.parse(notification['created_at']),
    );
  }
}
```

---

## Service Layer (Dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final String baseUrl;
  final String token;

  NotificationService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Get all notifications
  Future<ApiResponse<List<NotificationItem>>> getMyNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-notifications'),
      headers: _headers,
    );

    final json = jsonDecode(response.body);
    return ApiResponse.fromJson(
      json,
      (data) => (data as List)
          .map((e) => NotificationItem.fromRecipientJson(e))
          .toList(),
    );
  }

  // Get unread notifications only
  Future<ApiResponse<List<NotificationItem>>> getUnreadNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-notifications?unread_only=1'),
      headers: _headers,
    );

    final json = jsonDecode(response.body);
    return ApiResponse.fromJson(
      json,
      (data) => (data as List)
          .map((e) => NotificationItem.fromRecipientJson(e))
          .toList(),
    );
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final response = await getUnreadNotifications();
    if (response.success && response.data != null) {
      return response.data!.length;
    }
    return 0;
  }

  // Mark as read
  Future<ApiResponse<NotificationRecipient>> markAsRead(int notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/my-notifications/$notificationId/read'),
      headers: _headers,
    );

    final json = jsonDecode(response.body);
    return ApiResponse.fromJson(
      json,
      (data) => NotificationRecipient.fromJson(data),
    );
  }

  // Mark all as read
  Future<ApiResponse<Map<String, dynamic>>> markAllAsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/my-notifications/read-all'),
      headers: _headers,
    );

    final json = jsonDecode(response.body);
    return ApiResponse.fromJson(
      json,
      (data) => data as Map<String, dynamic>,
    );
  }

  // Mark as unread
  Future<ApiResponse<NotificationRecipient>> markAsUnread(int notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/my-notifications/$notificationId/unread'),
      headers: _headers,
    );

    final json = jsonDecode(response.body);
    return ApiResponse.fromJson(
      json,
      (data) => NotificationRecipient.fromJson(data),
    );
  }

  // Delete from inbox
  Future<ApiResponse<void>> deleteNotification(int notificationId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/my-notifications/$notificationId'),
      headers: _headers,
    );

    final json = jsonDecode(response.body);
    return ApiResponse.fromJson(
      json,
      (data) => null,
    );
  }
}
```

---

## State Management (Provider/Riverpod)

### Notification Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final token = ref.watch(authTokenProvider); // Your auth token provider
  return NotificationService(
    baseUrl: API_BASE_URL,
    token: token,
  );
});

// Notifications list state
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<NotificationItem>>>((ref) {
  return NotificationsNotifier(ref.read(notificationServiceProvider));
});

// Unread count state
final unreadCountProvider = StateProvider<int>((ref) => 0);

class NotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final NotificationService _service;

  NotificationsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.getMyNotifications();
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(response.message, StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await _service.markAsRead(notificationId);
      if (response.success) {
        // Update local state
        state.whenData((notifications) {
          final updated = notifications.map((n) {
            if (n.notificationId == notificationId) {
              return NotificationItem(
                id: n.id,
                notificationId: n.notificationId,
                title: n.title,
                body: n.body,
                type: n.type,
                isRead: true,
                readAt: DateTime.now(),
                receivedAt: n.receivedAt,
                sentAt: n.sentAt,
              );
            }
            return n;
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _service.markAllAsRead();
      if (response.success) {
        state.whenData((notifications) {
          final updated = notifications.map((n) {
            return NotificationItem(
              id: n.id,
              notificationId: n.notificationId,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              readAt: DateTime.now(),
              receivedAt: n.receivedAt,
              sentAt: n.sentAt,
            );
          }).toList();
          state = AsyncValue.data(updated);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await _service.deleteNotification(notificationId);
      if (response.success) {
        state.whenData((notifications) {
          final updated = notifications
              .where((n) => n.notificationId != notificationId)
              .toList();
          state = AsyncValue.data(updated);
        });
      }
    } catch (e) {
      // Handle error
    }
  }
}

// Refresh unread count
final refreshUnreadCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(notificationServiceProvider);
  final count = await service.getUnreadCount();
  ref.read(unreadCountProvider.notifier).state = count;
  return count;
});
```

---

## UI Components

### Notification Badge (AppBar)

```dart
class NotificationBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
```

### Notification List Screen

```dart
class NotificationsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
            child: Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(child: Text('No notifications'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationListTile(
                notification: notification,
                onTap: () {
                  if (!notification.isRead) {
                    ref.read(notificationsProvider.notifier).markAsRead(notification.notificationId);
                  }
                  Navigator.pushNamed(
                    context,
                    '/notification-detail',
                    arguments: notification,
                  );
                },
                onDismiss: () {
                  ref.read(notificationsProvider.notifier).deleteNotification(notification.notificationId);
                },
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### Notification List Tile

```dart
class NotificationListTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationListTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: notification.isRead ? Colors.grey : Colors.blue,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTime(notification.sentAt),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
```

### Notification Detail Screen

```dart
class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_unread':
                  // Call markAsUnread
                  break;
                case 'delete':
                  // Call delete
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_unread',
                child: Text('Mark as unread'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Text(
              _formatFullDate(notification.sentAt),
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
```

---

## Navigation Routes

```dart
// routes.dart
class AppRoutes {
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';
}

// main.dart or router configuration
Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.notifications: (context) => NotificationsScreen(),
  AppRoutes.notificationDetail: (context) {
    final notification = ModalRoute.of(context)!.settings.arguments as NotificationItem;
    return NotificationDetailScreen(notification: notification);
  },
};

// Using Navigator 2.0 / GoRouter
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsScreen(),
    ),
    GoRoute(
      path: '/notification-detail',
      builder: (context, state) {
        final notification = state.extra as NotificationItem;
        return NotificationDetailScreen(notification: notification);
      },
    ),
  ],
);
```

---

## Push Notifications (Firebase)

### Setup

1. Add Firebase to your Flutter project:
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.15.0
  firebase_messaging: ^14.6.0
  flutter_local_notifications: ^15.1.0
```

2. Initialize Firebase Messaging:

```dart
class FirebaseNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationService _apiService;

  FirebaseNotificationService(this._apiService);

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        // Send new token to your server
        _sendTokenToServer(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _showLocalNotification(message);

    // Refresh inbox
    // Trigger: ref.read(notificationsProvider.notifier).loadNotifications();
    // Trigger: ref.read(refreshUnreadCountProvider);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
    print('Background message: ${message.notification?.title}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to notification detail
    final notificationId = message.data['notification_id'];
    // Navigator.pushNamed(context, '/notification-detail', arguments: ...);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Show using flutter_local_notifications
  }

  Future<void> _sendTokenToServer(String token) async {
    // POST /api/device-tokens (if you have this endpoint)
  }
}
```

### Notification Payload Shape (from FCM)

```json
{
  "notification": {
    "title": "School Holiday Announcement",
    "body": "School will be closed next Monday for a public holiday."
  },
  "data": {
    "notification_id": "5",
    "type": "general",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

---

## Error Handling

### Common Errors

```dart
class NotificationErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is http.ClientException) {
      return 'Network error. Please check your connection.';
    }
    if (error is FormatException) {
      return 'Invalid response from server.';
    }
    if (error is String) {
      return error;
    }
    return 'An unexpected error occurred.';
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

### Retry Logic

```dart
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      await Future.delayed(initialDelay * attempt);
    }
  }
}
```

---

## Testing Checklist

- [ ] Fetch notifications on app launch
- [ ] Display unread count badge correctly
- [ ] Mark as read when tapping a notification
- [ ] Mark all as read from inbox screen
- [ ] Swipe to delete notification
- [ ] Pull-to-refresh inbox
- [ ] Handle empty state (no notifications)
- [ ] Handle network errors gracefully
- [ ] Receive push notification when app is in foreground
- [ ] Receive push notification when app is in background
- [ ] Tap push notification opens correct detail screen
- [ ] Unread count updates in real-time after mark as read

---

*Last updated: 2026-06-24*
