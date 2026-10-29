import 'dart:math' as math;

import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:flutter/material.dart';

/// Clock-style wheel split into the four parts of the day. Each dose appears
/// as a capsule in its quadrant; the current part of the day is highlighted.
///
/// Layout (clockwise from the top-right): Morning, Afternoon, Evening, Night.
class DoseWheel extends StatelessWidget {
  final List<DoseScheduleItem> items;
  final DosePeriod? currentPeriod;
  final DosePeriod? selectedPeriod;
  final ValueChanged<DosePeriod> onPeriodTap;

  const DoseWheel({
    super.key,
    required this.items,
    required this.currentPeriod,
    required this.selectedPeriod,
    required this.onPeriodTap,
  });

  static const List<DosePeriod> _clockwise = [
    DosePeriod.morning,
    DosePeriod.afternoon,
    DosePeriod.evening,
    DosePeriod.night,
  ];

  @override
  Widget build(BuildContext context) {
    final scheduled = items.where((i) => !i.isAsNeeded).toList();
    final taken = scheduled.where((i) => i.isTaken).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final size = math.min(constraints.maxWidth - 48, 300.0);
      return SizedBox(
        width: size + 48,
        height: size + 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(top: 0, left: 0, child: _label(DosePeriod.night, CrossAxisAlignment.start)),
            Positioned(top: 0, right: 0, child: _label(DosePeriod.morning, CrossAxisAlignment.end)),
            Positioned(bottom: 0, left: 0, child: _label(DosePeriod.evening, CrossAxisAlignment.start)),
            Positioned(bottom: 0, right: 0, child: _label(DosePeriod.afternoon, CrossAxisAlignment.end)),
            GestureDetector(
              onTapUp: (d) {
                final c = Offset(size / 2, size / 2);
                final v = d.localPosition - c;
                if (v.distance > size / 2) return;
                // atan2: 0 at 3 o'clock, clockwise positive in screen coords.
                var a = math.atan2(v.dy, v.dx);
                if (a < -math.pi / 2) a += 2 * math.pi; // normalise to [-90°, 270°)
                final index = ((a + math.pi / 2) / (math.pi / 2)).floor().clamp(0, 3);
                onPeriodTap(_clockwise[index]);
              },
              child: CustomPaint(
                size: Size.square(size),
                painter: _WheelPainter(
                  items: scheduled,
                  currentPeriod: currentPeriod,
                  selectedPeriod: selectedPeriod,
                  isDark: isDark,
                ),
                child: SizedBox.square(
                  dimension: size,
                  child: Center(
                    child: Container(
                      width: size * 0.3,
                      height: size * 0.3,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            scheduled.isEmpty ? '–' : '$taken/${scheduled.length}',
                            style: TextStyle(
                              fontSize: size * 0.075,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text('taken',
                              style: TextStyle(fontSize: size * 0.04, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _label(DosePeriod p, CrossAxisAlignment align) {
    final active = p == selectedPeriod || (selectedPeriod == null && p == currentPeriod);
    final color = active ? AppTheme.primaryColor : Colors.grey.shade500;
    return GestureDetector(
      onTap: () => onPeriodTap(p),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(p.icon, size: 22, color: color),
            Text(p.label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<DoseScheduleItem> items;
  final DosePeriod? currentPeriod;
  final DosePeriod? selectedPeriod;
  final bool isDark;

  _WheelPainter({
    required this.items,
    required this.currentPeriod,
    required this.selectedPeriod,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r - 4);

    // Outer ring
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..color = brandBlue.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final quadrantColor = isDark ? brandBlue.shade700 : AppTheme.primaryColor;
    final currentColor = isDark ? const Color(0xFF2B3B4E) : const Color(0xFFEFF5FB);

    for (int q = 0; q < 4; q++) {
      final period = DoseWheel._clockwise[q];
      final start = -math.pi / 2 + q * math.pi / 2;
      final isCurrent = period == currentPeriod;
      canvas.drawArc(
        rect.deflate(4),
        start,
        math.pi / 2,
        true,
        Paint()..color = isCurrent ? currentColor : quadrantColor,
      );
      if (period == selectedPeriod) {
        canvas.drawArc(
          rect.deflate(1),
          start + 0.04,
          math.pi / 2 - 0.08,
          false,
          Paint()
            ..color = AppTheme.secondaryColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
      }
      _paintDoses(canvas, c, r, start, items.where((i) => i.period == period).toList());
    }

    // Separators between quadrants
    final sep = Paint()
      ..color = isDark ? AppTheme.scaffoldDark : Colors.white
      ..strokeWidth = 5;
    canvas.drawLine(Offset(c.dx, c.dy - r + 4), Offset(c.dx, c.dy + r - 4), sep);
    canvas.drawLine(Offset(c.dx - r + 4, c.dy), Offset(c.dx + r - 4, c.dy), sep);
  }

  void _paintDoses(Canvas canvas, Offset c, double r, double start, List<DoseScheduleItem> doses) {
    if (doses.isEmpty) return;
    // Up to 4 capsules on an outer arc, the rest on an inner arc.
    final outer = doses.take(4).toList();
    final inner = doses.skip(4).take(4).toList();
    _paintArc(canvas, c, r * 0.68, start, outer, r);
    _paintArc(canvas, c, r * 0.46, start, inner, r);
  }

  void _paintArc(Canvas canvas, Offset c, double radius, double start, List<DoseScheduleItem> doses, double r) {
    for (int i = 0; i < doses.length; i++) {
      final a = start + (i + 1) * (math.pi / 2) / (doses.length + 1);
      final pos = c + Offset(math.cos(a), math.sin(a)) * radius;
      _paintCapsule(canvas, pos, a, doses[i], r);
    }
  }

  void _paintCapsule(Canvas canvas, Offset pos, double angle, DoseScheduleItem item, double r) {
    final w = r * 0.2;
    final h = r * 0.09;
    final color = item.isSkipped ? Colors.grey : Color(item.medication.color);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle + math.pi / 2);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    // Two-tone capsule: coloured left half, lighter right half.
    canvas.save();
    canvas.clipRRect(rrect.deflate(1.5));
    canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w / 2, h), Paint()..color = color);
    canvas.drawRect(Rect.fromLTWH(0, -h / 2, w / 2, h), Paint()..color = color.withValues(alpha: 0.55));
    canvas.restore();
    canvas.restore();

    if (item.isTaken || item.isMissed) {
      final badge = pos + Offset(w * 0.45, -h * 0.9);
      canvas.drawCircle(badge, h * 0.62, Paint()..color = Colors.white);
      canvas.drawCircle(
        badge,
        h * 0.5,
        Paint()..color = item.isTaken ? AppTheme.successColor : AppTheme.warningColor,
      );
      final p = Paint()
        ..color = Colors.white
        ..strokeWidth = h * 0.16
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (item.isTaken) {
        final path = Path()
          ..moveTo(badge.dx - h * 0.22, badge.dy)
          ..lineTo(badge.dx - h * 0.05, badge.dy + h * 0.18)
          ..lineTo(badge.dx + h * 0.25, badge.dy - h * 0.16);
        canvas.drawPath(path, p);
      } else {
        canvas.drawLine(badge + Offset(0, -h * 0.22), badge + Offset(0, h * 0.05), p);
        canvas.drawCircle(badge + Offset(0, h * 0.22), h * 0.04, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.items != items ||
      old.currentPeriod != currentPeriod ||
      old.selectedPeriod != selectedPeriod ||
      old.isDark != isDark;
}
