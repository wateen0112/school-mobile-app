import 'package:flutter/material.dart';

import '../../widgets/shared_widgets.dart';
import '../localization/module_localization.dart';
import '../theme/app_theme.dart';

/// Wraps any [child] so the page supports pull-to-refresh, even when the
/// content is shorter than the viewport (empty/error/loading states).
class RefreshablePage extends StatelessWidget {
  const RefreshablePage({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      edgeOffset: MediaQuery.of(context).padding.top + 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    constraints.maxHeight > 0 ? constraints.maxHeight : 0,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Localized "no data" placeholder with an optional refresh action.
///
/// [compact] renders a smaller card-friendly variant that can be embedded
/// inside list items; otherwise a full illustrated placeholder is shown.
class NoDataWidget extends StatelessWidget {
  const NoDataWidget({
    super.key,
    this.icon = Icons.inbox_rounded,
    this.title,
    this.message,
    this.onRefresh,
    this.actionLabel,
    this.compact = false,
  });

  final IconData icon;
  final String? title;
  final String? message;
  final VoidCallback? onRefresh;
  final String? actionLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isArabic = appIsArabic(context);
    final resolvedTitle = title ?? t(context, 'noData');
    final resolvedMessage =
        message ??
        (isArabic
            ? 'لا توجد بيانات لعرضها هنا بعد.'
            : 'There is no data to show here yet.');
    final resolvedAction = actionLabel ?? t(context, 'refresh');

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 16 : 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (compact)
              Icon(icon, size: 44, color: AppTheme.muted)
            else
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  gradient: AppTheme.promoGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: Colors.white),
              ),
            SizedBox(height: compact ? 10 : 18),
            Text(
              resolvedTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (resolvedMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                resolvedMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.muted),
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(resolvedAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}