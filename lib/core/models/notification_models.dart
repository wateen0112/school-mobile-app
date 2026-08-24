class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
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

  /// Navigation action attached to this notification (e.g. 'exam',
  /// 'installment_reminder', 'installment_overdue'), if any.
  String? get action {
    final value = data?['action'];
    final text = '$value';
    return text.isNotEmpty ? text : null;
  }

  /// Id of the entity the notification points to (e.g. quiz/exam id).
  int? get actionId {
    final value = data?['action_id'];
    if (value is num) return value.toInt();
    final text = '$value';
    return int.tryParse(text);
  }
}

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

class NotificationItem {
  final int id;
  final int notificationId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? readAt;
  final DateTime receivedAt;
  final DateTime sentAt;
  final Map<String, dynamic>? data;

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
    this.data,
  });

  factory NotificationItem.fromRecipientJson(Map<String, dynamic> json) {
    // Handle both formats:
    // 1. /my-notifications -> {id, notification_id, notification: {...}, is_read, ...}
    // 2. /notifications -> {id, title, body, type, ...} (direct NotificationModel)
    final notification = json['notification'];
    if (notification != null) {
      // Format 1: wrapped in NotificationRecipient
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
        data: notification['data'] != null
            ? Map<String, dynamic>.from(notification['data'])
            : null,
      );
    } else {
      // Format 2: direct NotificationModel (from /notifications index)
      return NotificationItem(
        id: json['id'],
        notificationId: json['id'],
        title: json['title'],
        body: json['body'],
        type: json['type'],
        isRead: json['is_read'] == 1 || json['is_read'] == true,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
        receivedAt: DateTime.parse(json['created_at']),
        sentAt: DateTime.parse(json['created_at']),
        data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      );
    }
  }

  /// Navigation action attached to this notification (e.g. 'exam',
  /// 'installment_reminder', 'installment_overdue'), if any.
  String? get action {
    final value = data?['action'];
    final text = '$value';
    return text.isNotEmpty ? text : null;
  }

  /// Id of the entity the notification points to (e.g. quiz/exam id).
  int? get actionId {
    final value = data?['action_id'];
    if (value is num) return value.toInt();
    final text = '$value';
    return int.tryParse(text);
  }

  NotificationItem copyWith({
    int? id,
    int? notificationId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? readAt,
    DateTime? receivedAt,
    DateTime? sentAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      receivedAt: receivedAt ?? this.receivedAt,
      sentAt: sentAt ?? this.sentAt,
      data: data ?? this.data,
    );
  }
}
