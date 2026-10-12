import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/module_localization.dart';
import '../../core/models/notification_models.dart';
import '../../core/navigation/notification_navigation.dart';
import '../../core/state/session_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class NotificationDropdownMenu extends StatefulWidget {
  const NotificationDropdownMenu({
    super.key,
    required this.session,
    required this.onClose,
  });

  final SessionController session;
  final VoidCallback onClose;

  @override
  State<NotificationDropdownMenu> createState() => _NotificationDropdownMenuState();
}

class _NotificationDropdownMenuState extends State<NotificationDropdownMenu> {
  List<NotificationItem> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndMarkAllRead();
  }

  Future<void> _loadAndMarkAllRead() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Load notifications
      final notifications = await widget.session.notifications.getMyNotifications();
      
      // Mark all unread as read via API
      final unreadNotifications = notifications.where((n) => !n.isRead).toList();
      if (unreadNotifications.isNotEmpty) {
        try {
          await widget.session.notifications.markAllAsRead();
          widget.session.refreshUnreadCount();
        } catch (_) {
          // Silently fail - don't block UI if mark-all fails
        }
      }
      
      if (mounted) {
        setState(() {
          // Show all as read since we just marked them
          _notifications = notifications.map((n) => 
            n.copyWith(isRead: true, readAt: DateTime.now())
          ).take(5).toList();
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isRtl),
            const Divider(height: 1),
            Flexible(
              child: _buildBody(isRtl),
            ),
            const Divider(height: 1),
            _buildFooter(isRtl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isRtl) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            t(context, 'notifications'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          if (widget.session.unreadNotificationCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.coral.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.session.unreadNotificationCount} ${t(context, 'unread')}',
                style: const TextStyle(
                  color: AppTheme.coral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isRtl) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${appIsArabic(context) ? 'خطأ: ' : 'Error: '}$_error',
                style: const TextStyle(fontSize: 12),
              ),
              TextButton(
                onPressed: _loadAndMarkAllRead,
                child: Text(t(context, 'retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            t(context, 'noNotifications'),
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationDropdownItem(
          notification: notification,
          isRtl: isRtl,
          onTap: () {
            widget.onClose();
            openNotification(context, notification);
          },
        );
      },
    );
  }

  Widget _buildFooter(bool isRtl) {
    return InkWell(
      onTap: () {
        widget.onClose();
        context.go('/notifications');
      },
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t(context, 'seeAllNotifications'),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isRtl ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
              size: 16,
              color: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDropdownItem extends StatelessWidget {
  const _NotificationDropdownItem({
    required this.notification,
    required this.isRtl,
    required this.onTap,
  });

  final NotificationItem notification;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: EdgeInsets.only(
                top: 4,
                right: isRtl ? 0 : 12,
                left: isRtl ? 12 : 0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notification.isRead ? AppTheme.muted : AppTheme.coral,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.sentAt),
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
