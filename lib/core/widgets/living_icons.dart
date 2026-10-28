import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn, colorful, gently animated navigation icons.
///
/// No icon-font glyphs are used — every icon is painted from scratch with
/// [CustomPainter] on a gradient bubble, and each one floats softly to feel
/// alive. Unknown icons fall back to a colorful sparkle orb.
class LivingNavIcon extends StatefulWidget {
  const LivingNavIcon({
    super.key,
    required this.icon,
    this.selected = false,
    this.size = 48,
  });

  final IconData icon;
  final bool selected;
  final double size;

  @override
  State<LivingNavIcon> createState() => _LivingNavIconState();
}

class _LivingNavIconState extends State<LivingNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _LivingIconSpec.forIcon(widget.icon);
    final bespoke = _LivingIconSpec.hasBespoke(widget.icon);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final floatY = -1.6 + 3.2 * t;
        final glow = (0.35 + 0.65 * math.sin(t * math.pi)).clamp(0.0, 1.0);
        final scale = 1.0 + 0.06 * math.sin(t * math.pi * 2);
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.32),
              border: widget.selected
                  ? Border.all(color: Colors.white, width: 2.4)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: spec.glowColor.withValues(
                    alpha: (widget.selected ? 0.5 : 0.28) * glow,
                  ),
                  blurRadius: 10 + 8 * glow,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: bespoke
                ? CustomPaint(
                    painter: _LivingIconPainter(
                      spec: spec,
                      glow: glow,
                      selected: widget.selected,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size * 0.32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [spec.colorA, spec.colorB],
                      ),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          widget.icon,
                          size: widget.size * 0.52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _LivingIconSpec {
  const _LivingIconSpec({
    required this.colorA,
    required this.colorB,
    required this.glowColor,
    required this.accent,
    required this.ink,
    required this.draw,
  });

  final Color colorA;
  final Color colorB;
  final Color glowColor;
  final Color accent;
  final Color ink;
  final void Function(Canvas canvas, _LivingIconSpec spec) draw;

  static bool hasBespoke(IconData icon) =>
      _registry.any((entry) => entry.$1 == icon);

  static _LivingIconSpec forIcon(IconData icon) {
    for (final entry in _registry) {
      if (entry.$1 == icon) return entry.$2;
    }
    return _orbs[icon.hashCode.abs() % _orbs.length];
  }

  static final _registry = <(IconData, _LivingIconSpec)>[
    (Icons.directions_bus_rounded, _bus),
    (Icons.calendar_month_rounded, _calendar),
    (Icons.event_note_rounded, _noteCalendar),
    (Icons.child_care_rounded, _child),
    (Icons.event_available_rounded, _check),
    (Icons.payments_rounded, _payments),
    (Icons.grading_rounded, _grading),
    (Icons.feedback_rounded, _feedback),
    (Icons.star_rounded, _star),
    (Icons.assessment_rounded, _assessment),
    (Icons.account_balance_wallet_rounded, _wallet),
  ];

  // ---- palette ----------------------------------------------------------------

  static const _bus = _LivingIconSpec(
    colorA: Color(0xffFFB75E),
    colorB: Color(0xffED7D03),
    glowColor: Color(0xffF59E0B),
    accent: Color(0xffBDE3FF),
    ink: Color(0xff5D3A0E),
    draw: _drawBus,
  );

  static const _calendar = _LivingIconSpec(
    colorA: Color(0xff43E97B),
    colorB: Color(0xff12B5A5),
    glowColor: Color(0xff34D399),
    accent: Color(0xff0B7A63),
    ink: Color(0xff065F46),
    draw: _drawCalendar,
  );

  static const _noteCalendar = _LivingIconSpec(
    colorA: Color(0xff4FACFE),
    colorB: Color(0xff1D6FE0),
    glowColor: Color(0xff38BDF8),
    accent: Color(0xff0C4A9A),
    ink: Color(0xff1E3A8A),
    draw: _drawNoteCalendar,
  );

  static const _child = _LivingIconSpec(
    colorA: Color(0xffFF9AA2),
    colorB: Color(0xffF06292),
    glowColor: Color(0xffFB7185),
    accent: Color(0xffFCE7F3),
    ink: Color(0xff7C2D3E),
    draw: _drawChild,
  );

  static const _check = _LivingIconSpec(
    colorA: Color(0xff6EE7B7),
    colorB: Color(0xff10B981),
    glowColor: Color(0xff34D399),
    accent: Color(0xff047857),
    ink: Color(0xff064E3B),
    draw: _drawCheck,
  );

  static const _payments = _LivingIconSpec(
    colorA: Color(0xffFDE68A),
    colorB: Color(0xffF59E0B),
    glowColor: Color(0xffFBBF24),
    accent: Color(0xffB45309),
    ink: Color(0xff78350F),
    draw: _drawPayments,
  );

  static const _grading = _LivingIconSpec(
    colorA: Color(0xffB79CFF),
    colorB: Color(0xff7C5CE0),
    glowColor: Color(0xffA78BFA),
    accent: Color(0xffFBBF24),
    ink: Color(0xff3B2A78),
    draw: _drawGrading,
  );

  static const _feedback = _LivingIconSpec(
    colorA: Color(0xffFB7AA8),
    colorB: Color(0xffE8436B),
    glowColor: Color(0xffF472B6),
    accent: Color(0xff9D174D),
    ink: Color(0xff831843),
    draw: _drawFeedback,
  );

  static const _star = _LivingIconSpec(
    colorA: Color(0xffFFD66B),
    colorB: Color(0xffF59E0B),
    glowColor: Color(0xffFACC15),
    accent: Color(0xffB45309),
    ink: Color(0xff92400E),
    draw: _drawStar,
  );

  static const _assessment = _LivingIconSpec(
    colorA: Color(0xff5EEAD4),
    colorB: Color(0xff6D5AE0),
    glowColor: Color(0xff818CF8),
    accent: Color(0xff312E81),
    ink: Color(0xff1E1B4B),
    draw: _drawAssessment,
  );

  static const _wallet = _LivingIconSpec(
    colorA: Color(0xff8FA8FF),
    colorB: Color(0xff5B54D6),
    glowColor: Color(0xff818CF8),
    accent: Color(0xffFDE68A),
    ink: Color(0xff312E81),
    draw: _drawWallet,
  );

  /// Colorful sparkle orbs — the fallback for icons without a bespoke glyph.
  /// One spec per hue, chosen deterministically per icon, so every fallback
  /// tile stays visually distinct and colorful.
  static final _orbs = <_LivingIconSpec>[
    _orb(const Color(0xffA5B4FC), const Color(0xff6366F1)), // indigo
    _orb(const Color(0xff6EE7B7), const Color(0xff10B981)), // emerald
    _orb(const Color(0xffFDA4AF), const Color(0xffE11D48)), // rose
    _orb(const Color(0xffFDE68A), const Color(0xffF59E0B)), // amber
    _orb(const Color(0xff7DD3FC), const Color(0xff0284C7)), // sky
    _orb(const Color(0xffC4B5FD), const Color(0xff7C3AED)), // violet
    _orb(const Color(0xffF9A8D4), const Color(0xffDB2777)), // pink
    _orb(const Color(0xff99F6E4), const Color(0xff0D9488)), // teal
  ];

  static _LivingIconSpec _orb(Color colorA, Color colorB) => _LivingIconSpec(
    colorA: colorA,
    colorB: colorB,
    glowColor: colorB,
    accent: Colors.white,
    ink: Colors.white,
    draw: _drawOrb,
  );

  // ---- shared paint helpers (design space is 48x48) ----------------------------

  static Paint _fill(Color color) =>
      Paint()..color = color..style = PaintingStyle.fill;

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static void _bubble(Canvas c, _LivingIconSpec spec, double glow) {
    final rect = Rect.fromLTWH(1.5, 1.5, 45, 45);
    final r = 14.0;
    // glow halo
    c.save();
    c.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r)),
      Paint()
        ..color = spec.glowColor.withValues(alpha: 0.18 + 0.14 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    c.restore();
    // gradient body
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [spec.colorA, spec.colorB],
      ).createShader(rect);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), bg);
    // glossy sheen
    final sheen = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 4.5, 36, 15),
      const Radius.circular(10),
    );
    c.drawRRect(sheen, Paint()..color = Colors.white.withValues(alpha: 0.22));
  }

  static void _sparkle(Canvas c, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx + r,
        center.dy,
      )
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
    c.drawPath(path, _fill(color));
  }

  // ---- glyphs -------------------------------------------------------------------

  static void _drawBus(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // body
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 14, 28, 15), const Radius.circular(5)),
      white,
    );
    // windows
    final win = _fill(spec.accent);
    for (final x in [13.5, 21.0, 28.5]) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 17, 5.5, 5), const Radius.circular(1.8)),
        win,
      );
    }
    // bumper stripe
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10, 25, 28, 2.6), const Radius.circular(1.3)),
      _fill(spec.colorB),
    );
    // wheels
    final wheel = _fill(spec.ink);
    c.drawCircle(const Offset(16.5, 30.5), 3.2, wheel);
    c.drawCircle(const Offset(31.5, 30.5), 3.2, wheel);
    final hub = _fill(Colors.white.withValues(alpha: .85));
    c.drawCircle(const Offset(16.5, 30.5), 1.2, hub);
    c.drawCircle(const Offset(31.5, 30.5), 1.2, hub);
    // roof light
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(21, 11.2, 6, 2.6), const Radius.circular(1.3)),
      _fill(spec.accent),
    );
  }

  static void _drawCalendar(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // page
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(11, 12, 26, 26), const Radius.circular(5.5)),
      white,
    );
    // header band
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(11, 12, 26, 8.5), const Radius.circular(5.5)),
      _fill(spec.colorB),
    );
    c.drawRect(const Rect.fromLTWH(11, 17, 26, 3.5), _fill(spec.colorB));
    // rings
    final ring = _fill(spec.ink);
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(16.5, 8, 2.8, 7), const Radius.circular(1.4)),
      ring,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(28.7, 8, 2.8, 7), const Radius.circular(1.4)),
      ring,
    );
    // dots
    final dot = _fill(spec.accent);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        c.drawCircle(Offset(16.5 + col * 7.5, 27 + row * 6), 1.8, dot);
      }
    }
  }

  static void _drawNoteCalendar(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12, 10.5, 24, 28), const Radius.circular(5)),
      white,
    );
    // folded corner
    final fold = Path()
      ..moveTo(30, 10.5)
      ..lineTo(36, 16.5)
      ..lineTo(30, 16.5)
      ..close();
    c.drawPath(fold, _fill(spec.colorB.withValues(alpha: .45)));
    // note lines
    final line = _fill(spec.accent);
    final widths = [16.0, 12.0, 8.0];
    for (var i = 0; i < widths.length; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(16, 21 + i * 5.5, widths[i], 2.6),
          const Radius.circular(1.3),
        ),
        line,
      );
    }
    _sparkle(c, const Offset(33, 30), 3, spec.colorA.withValues(alpha: .9));
  }

  static void _drawChild(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // ears
    c.drawCircle(const Offset(14.5, 25), 3, white);
    c.drawCircle(const Offset(33.5, 25), 3, white);
    // face
    c.drawCircle(const Offset(24, 25.5), 10, white);
    // hair cap
    c.drawArc(
      Rect.fromCircle(center: const Offset(24, 22.5), radius: 9.5),
      math.pi,
      math.pi,
      true,
      _fill(spec.colorB),
    );
    // eyes
    final eye = _fill(spec.ink);
    c.drawCircle(const Offset(20.5, 26.5), 1.5, eye);
    c.drawCircle(const Offset(27.5, 26.5), 1.5, eye);
    // cheeks
    final cheek = _fill(spec.colorB.withValues(alpha: .4));
    c.drawCircle(const Offset(17.5, 29.5), 1.8, cheek);
    c.drawCircle(const Offset(30.5, 29.5), 1.8, cheek);
    // smile
    c.drawArc(
      Rect.fromCircle(center: const Offset(24, 28.5), radius: 3.6),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      _stroke(spec.ink, 1.6),
    );
    // hair tuft
    _sparkle(
      c,
      const Offset(24, 12.5),
      2.6,
      Colors.white.withValues(alpha: .95),
    );
  }

  static void _drawCheck(Canvas c, _LivingIconSpec spec) {
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 12, 24, 24),
      const Radius.circular(7),
    );
    c.drawRRect(card, _fill(Colors.white));
    c.drawRRect(card.inflate(0.5), _stroke(spec.colorB.withValues(alpha: .5), 1.6));
    // header strip
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(15.5, 15.5, 17, 3), const Radius.circular(1.5)),
      _fill(spec.colorB.withValues(alpha: .55)),
    );
    // big check
    final check = Path()
      ..moveTo(16.5, 27.5)
      ..lineTo(21.5, 32.5)
      ..lineTo(31.5, 21.5);
    c.drawPath(check, _stroke(spec.accent, 3.4));
    _sparkle(c, const Offset(34.5, 14.5), 2.6, Colors.white.withValues(alpha: .9));
  }

  static void _drawPayments(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // banknote
    c.save();
    c.translate(24, 20);
    c.rotate(-0.18);
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -6.5, 24, 13), const Radius.circular(2.6)),
      white,
    );
    c.drawCircle(Offset.zero, 3.4, _stroke(spec.accent, 1.6));
    c.drawRect(const Rect.fromLTWH(-9.5, -3, 4, 6), _fill(spec.colorB.withValues(alpha: .35)));
    c.drawRect(const Rect.fromLTWH(5.5, -3, 4, 6), _fill(spec.colorB.withValues(alpha: .35)));
    c.restore();
    // coin
    c.drawCircle(const Offset(31, 31), 7.5, _fill(spec.accent));
    c.drawCircle(const Offset(31, 31), 5.2, _stroke(Colors.white.withValues(alpha: .9), 1.6));
    c.drawCircle(const Offset(31, 31), 1.6, _fill(Colors.white.withValues(alpha: .95)));
    // small coin
    c.drawCircle(const Offset(17, 33), 4, _fill(Colors.white.withValues(alpha: .92)));
    c.drawCircle(const Offset(17, 33), 2.1, _fill(spec.accent));
  }

  static void _drawGrading(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // sheet
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12, 10.5, 17.5, 26), const Radius.circular(3)),
      white,
    );
    final line = _fill(spec.colorB.withValues(alpha: .6));
    for (var i = 0; i < 3; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(15.5, 15.5 + i * 5.5, 10.5, 2.4),
          const Radius.circular(1.2),
        ),
        line,
      );
    }
    // check on sheet
    final mini = Path()
      ..moveTo(15.5, 30.5)
      ..lineTo(18.5, 33.2)
      ..lineTo(24, 27);
    c.drawPath(mini, _stroke(spec.accent, 2.2));
    // pencil
    c.save();
    c.translate(32, 32);
    c.rotate(-math.pi / 4);
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-2.6, -10, 5.2, 15), const Radius.circular(2.4)),
      _fill(spec.accent),
    );
    final tip = Path()
      ..moveTo(-2.6, 5)
      ..lineTo(2.6, 5)
      ..lineTo(0, 10)
      ..close();
    c.drawPath(tip, _fill(Colors.white));
    c.drawCircle(const Offset(0, 8.6), 1, _fill(spec.ink));
    c.drawRect(const Rect.fromLTWH(-2.6, -10, 5.2, 2.6), _fill(spec.ink));
    c.restore();
  }

  static void _drawFeedback(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // bubble
    final bubble = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10.5, 12.5, 27, 18),
      const Radius.circular(9),
    );
    c.drawRRect(bubble, white);
    final tail = Path()
      ..moveTo(17.5, 29.5)
      ..lineTo(16, 36.5)
      ..lineTo(24, 30.2)
      ..close();
    c.drawPath(tail, white);
    // dots
    final dot = _fill(spec.accent);
    for (final x in [18.0, 24.0, 30.0]) {
      c.drawCircle(Offset(x, 21.5), 2, dot);
    }
    _sparkle(c, const Offset(36.5, 33.5), 3, Colors.white.withValues(alpha: .9));
  }

  static void _drawStar(Canvas c, _LivingIconSpec spec) {
    Offset starPoint(Offset center, double r, double angle) => Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );

    final center = Offset(24, 24.5);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 11.5 : 5.2;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = starPoint(center, r, angle);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    c.drawPath(path, _fill(Colors.white));
    // inner shading
    c.drawPath(
      path,
      Paint()
        ..color = spec.colorB.withValues(alpha: .22)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    // face
    final ink = _stroke(spec.ink, 1.4);
    c.drawArc(
      Rect.fromCircle(center: const Offset(21, 25.5), radius: 1.9),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      ink,
    );
    c.drawArc(
      Rect.fromCircle(center: const Offset(27, 25.5), radius: 1.9),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      ink,
    );
    c.drawArc(
      Rect.fromCircle(center: const Offset(24, 26.5), radius: 3.2),
      0.1 * math.pi,
      0.8 * math.pi,
      false,
      ink,
    );
    _sparkle(c, const Offset(36, 14), 2.6, Colors.white.withValues(alpha: .95));
    _sparkle(c, const Offset(12.5, 35), 2, spec.colorA.withValues(alpha: .95));
  }

  static void _drawAssessment(Canvas c, _LivingIconSpec spec) {
    final bar = _fill(Colors.white);
    final heights = [10.0, 16.0, 22.0];
    for (var i = 0; i < 3; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(13.5 + i * 8.5, 36 - heights[i], 6, heights[i]),
          const Radius.circular(3),
        ),
        bar,
      );
    }
    // rising accent dot + trail
    final trail = Path()
      ..moveTo(15, 22)
      ..quadraticBezierTo(24, 18, 33, 11);
    c.drawPath(trail, _stroke(spec.accent.withValues(alpha: .85), 2.2));
    c.drawCircle(const Offset(33.5, 10.5), 3.4, _fill(spec.accent));
    c.drawCircle(const Offset(33.5, 10.5), 1.3, _fill(Colors.white.withValues(alpha: .9)));
    // baseline
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(12, 36.5, 25, 2.2), const Radius.circular(1.1)),
      _fill(Colors.white.withValues(alpha: .7)),
    );
  }

  static void _drawWallet(Canvas c, _LivingIconSpec spec) {
    final white = _fill(Colors.white);
    // peeking card
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(15, 9.5, 14, 8), const Radius.circular(2.4)),
      _fill(spec.accent),
    );
    // body
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10.5, 15.5, 27, 19), const Radius.circular(5.5)),
      white,
    );
    // flap
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(10.5, 15.5, 27, 7.5), const Radius.circular(5.5)),
      _fill(spec.colorB),
    );
    c.drawRect(const Rect.fromLTWH(10.5, 20, 27, 3), _fill(spec.colorB));
    // clasp
    c.drawCircle(const Offset(30, 27.5), 3.2, _fill(spec.accent));
    c.drawCircle(const Offset(30, 27.5), 1.2, _fill(spec.ink));
    // stitch detail
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(14, 30.5, 9, 1.8), const Radius.circular(0.9)),
      _fill(spec.colorB.withValues(alpha: .45)),
    );
    _sparkle(c, const Offset(13.5, 12), 2.2, Colors.white.withValues(alpha: .9));
  }

  static void _drawOrb(Canvas c, _LivingIconSpec spec) {
    c.drawCircle(const Offset(24, 24), 10, _fill(Colors.white.withValues(alpha: .95)));
    c.drawCircle(const Offset(24, 24), 10, _stroke(spec.colorB.withValues(alpha: .5), 1.6));
    _sparkle(c, const Offset(24, 24), 5, spec.colorB);
    _sparkle(c, const Offset(35, 14.5), 2.6, Colors.white.withValues(alpha: .9));
    _sparkle(c, const Offset(13, 34), 2, Colors.white.withValues(alpha: .75));
  }
}

class _LivingIconPainter extends CustomPainter {
  _LivingIconPainter({
    required this.spec,
    required this.glow,
    required this.selected,
  });

  final _LivingIconSpec spec;
  final double glow;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    if (selected) {
      final ring = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.8, 0.8, 46.4, 46.4),
        const Radius.circular(15),
      );
      canvas.drawRRect(ring, _LivingIconSpec._stroke(Colors.white, 2.6));
    }
    _LivingIconSpec._bubble(canvas, spec, glow);
    spec.draw(canvas, spec);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LivingIconPainter oldDelegate) =>
      oldDelegate.spec != spec ||
      oldDelegate.glow != glow ||
      oldDelegate.selected != selected;
}
