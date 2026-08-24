import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/notification_models.dart';
import '../../core/navigation/notification_navigation.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/refreshable_content.dart';
import '../../widgets/shared_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<SessionController>();
      final notifications = await session.notifications.getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loading = false;
        });
      }
      session.refreshUnreadCount();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final session = context.read<SessionController>();
      await session.notifications.markAsRead(notificationId);
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.notificationId == notificationId) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList();
      });
      session.refreshUnreadCount();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      final session = context.read<SessionController>();
      await session.notifications.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }).toList();
      });
      session.refreshUnreadCount();
    } catch (_) {}
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final session = context.read<SessionController>();
      await session.notifications.deleteNotification(notificationId);
      setState(() {
        _notifications = _notifications
            .where((n) => n.notificationId != notificationId)
            .toList();
      });
      session.refreshUnreadCount();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 72,
          title: Text(
            t(context, 'notifications'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (_notifications.any((n) => !n.isRead))
              TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  t(context, 'markAllRead'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return RefreshablePage(
        onRefresh: _loadNotifications,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return RefreshablePage(
        onRefresh: _loadNotifications,
        child: NoDataWidget(
          icon: Icons.error_outline_rounded,
          title: _error!,
          onRefresh: _loadNotifications,
        ),
      );
    }
    if (_notifications.isEmpty) {
      return RefreshablePage(
        onRefresh: _loadNotifications,
        child: NoDataWidget(
          icon: Icons.notifications_off_outlined,
          title: t(context, 'noNotifications'),
          message: t(context, 'noDataMessage'),
          onRefresh: _loadNotifications,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.notificationId);
            }
            openNotification(context, notification);
          },
          onDismiss: () => _deleteNotification(notification.notificationId),
        );
      },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.coral,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.softPanel(radius: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: notification.isRead ? AppTheme.muted : AppTheme.coral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.sentAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 72,
          title: Text(
            t(context, 'notification'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppTheme.softPanel(radius: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatFullDate(notification.sentAt),
                      style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      notification.body,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
