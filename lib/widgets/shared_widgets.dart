import 'package:flutter/material.dart';

import '../app/app_strings.dart';
import '../app/design_system.dart';

String t(BuildContext context, String key) => AppStrings.of(context, key);

String displayValue(dynamic value, {String languageCode = 'en'}) {
  if (value == null) {
    return '';
  }
  if (value is Map) {
    final localized = value[languageCode] ?? value['en'] ?? value['ar'];
    if (localized != null) {
      return '$localized';
    }
    if (value['Name'] != null) {
      return displayValue(value['Name'], languageCode: languageCode);
    }
    if (value['name'] != null) {
      return displayValue(value['name'], languageCode: languageCode);
    }
    if (value['title'] != null) {
      return displayValue(value['title'], languageCode: languageCode);
    }
    return value.values
        .map((item) => displayValue(item, languageCode: languageCode))
        .where((item) => item.isNotEmpty)
        .take(2)
        .join(' ');
  }
  if (value is List) {
    return value
        .map((item) => displayValue(item, languageCode: languageCode))
        .join(', ');
  }
  return '$value';
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
          child: child,
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? .6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SchoolGradients.action,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: SchoolColors.secondary.withValues(alpha: .24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
          label: Text(label),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.positive = true});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? SchoolColors.success : SchoolColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: SchoolColors.muted),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(t(context, 'retry')),
            ),
          ],
        ],
      ),
    );
  }
}

class SchoolBagIllustration extends StatelessWidget {
  const SchoolBagIllustration({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SchoolBagPainter()),
    );
  }
}

class _SchoolBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final center = size.center(Offset.zero);
    paint.color = SchoolColors.accent;
    canvas.drawCircle(center, size.width * .43, paint);
    paint.color = const Color(0xff1f3b8f);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * .055;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, -8),
        width: size.width * .7,
        height: size.height * .72,
      ),
      3.4,
      2.6,
      false,
      paint,
    );
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xff1c8bea);
    final bag = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, 18),
        width: size.width * .58,
        height: size.height * .52,
      ),
      const Radius.circular(22),
    );
    canvas.drawRRect(bag, paint);
    paint.color = const Color(0xff006fca);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 58),
          width: size.width * .42,
          height: size.height * .16,
        ),
        const Radius.circular(12),
      ),
      paint,
    );
    paint.color = const Color(0xffff6d4d);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .34,
          size.height * .26,
          size.width * .12,
          size.height * .24,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = const Color(0xff2ecc71);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .46,
          size.height * .22,
          size.width * .12,
          size.height * .28,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = const Color(0xffffc84c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .56,
          size.height * .27,
          size.width * .12,
          size.height * .22,
        ),
        const Radius.circular(6),
      ),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: .55);
    canvas.drawCircle(Offset(size.width * .27, size.height * .18), 8, paint);
    canvas.drawCircle(Offset(size.width * .77, size.height * .35), 6, paint);
    canvas.drawCircle(Offset(size.width * .21, size.height * .75), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
