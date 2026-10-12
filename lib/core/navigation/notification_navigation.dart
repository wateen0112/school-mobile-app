import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/notification_models.dart';

/// Resolve the navigation action for a notification, falling back to
/// inspecting the raw payload keys (quizze_id / student_installment_id) for
/// backward compatibility.
String? notificationActionFor(NotificationItem notification) {
  final action = notification.action;
  if (action != null && action.isNotEmpty) return action;

  final data = notification.data;
  if (data != null) {
    if (data['type'] == 'transportation') return 'transportation';
    if (data['quizze_id'] != null) return 'exam';
    if (data['student_installment_id'] != null) return 'installment_reminder';
  }
  return null;
}

/// Resolve the target entity id for a notification's action.
int? notificationActionIdFor(NotificationItem notification) {
  final id = notification.actionId;
  if (id != null) return id;

  final data = notification.data;
  if (data != null) {
    final quizzeId = data['quizze_id'];
    if (quizzeId != null) {
      final parsed = int.tryParse('$quizzeId');
      if (parsed != null) return parsed;
    }
    final installmentId = data['student_installment_id'];
    if (installmentId != null) {
      final parsed = int.tryParse('$installmentId');
      if (parsed != null) return parsed;
    }
  }
  return null;
}

/// Build the target route (path + optional extra) from a raw notification
/// payload map (FCM `data` or local-notification payload).
(String, Object?)? routeForNotificationPayload(Map<String, dynamic> payload) {
  final action = '${payload['action'] ?? payload['type'] ?? ''}';
  final id = _firstInt(payload, const ['action_id', 'quizze_id', 'student_installment_id']);

  if (action == 'exam' && id != null) {
    return ('/student/exams/$id/start', null);
  }
  if (action == 'installment_reminder' || action == 'installment_overdue') {
    return ('/my-installments', id);
  }
  if (action == 'schedule_update') {
    return ('/schedule', null);
  }
  if (action == 'transportation') {
    // Transportation alerts deep-link: parents open the bus screen,
    // drivers open their home (active trip lives there).
    return (payload['role'] == 'driver' ? '/driver/home' : '/parent/transport', null);
  }
  return ('/notifications', null);
}

/// Open the page that matches a notification's content. Falls back to the
/// notification detail screen when no deep-link action is present.
void openNotification(BuildContext context, NotificationItem notification) {
  switch (notificationActionFor(notification)) {
    case 'exam':
      final id = notificationActionIdFor(notification);
      if (id != null) {
        context.push('/student/exams/$id/start');
        return;
      }
      break;
    case 'installment_reminder':
    case 'installment_overdue':
      context.push('/my-installments', extra: notificationActionIdFor(notification));
      return;
    case 'schedule_update':
      context.push('/schedule');
      return;
    case 'transportation':
      context.push('/parent/transport');
      return;
  }
  context.push('/notification-detail', extra: notification);
}

int? _firstInt(Map<String, dynamic> payload, List<String> keys) {
  for (final key in keys) {
    final value = payload[key];
    if (value == null) continue;
    if (value is num) return value.toInt();
    final parsed = int.tryParse('$value');
    if (parsed != null) return parsed;
  }
  return null;
}