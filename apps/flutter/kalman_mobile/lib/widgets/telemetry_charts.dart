import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'parameter_cards.dart';

/// One plotted line series inside [MultiSeriesChartCard].
final class ChartTrace {
  const ChartTrace({
    required this.label,
    required this.values,
    required this.color,
    this.strokeWidth = 2.0,
    this.dashed = false,
  });

  final String label;
  final List<double?> values;
  final Color color;
  final double strokeWidth;
  final bool dashed;
}

/// Mobile-optimized oscilloscope card rendering multiple synchronized traces.
class MultiSeriesChartCard extends StatelessWidget {
  const MultiSeriesChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.traces,
    this.height = 175,
    this.symmetricZero = false,
  });

  final String title;
  final String subtitle;
  final List<ChartTrace> traces;
  final double height;
  final bool symmetricZero;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: kMuted, fontSize: 11.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final t in traces)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: t.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    t.label,
                    style: TextStyle(
                      color: t.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _MultiSeriesPainter(
              traces: traces,
              symmetricZero: symmetricZero,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _MultiSeriesPainter extends CustomPainter {
  const _MultiSeriesPainter({
    required this.traces,
    required this.symmetricZero,
  });

  final List<ChartTrace> traces;
  final bool symmetricZero;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = kBgInk;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = kLine.withValues(alpha: 0.65)
      ..strokeWidth = 1.0;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    var minV = double.infinity;
    var maxV = -double.infinity;
    var maxPoints = 0;
    for (final trace in traces) {
      maxPoints = math.max(maxPoints, trace.values.length);
      for (final v in trace.values) {
        if (v != null && v.isFinite) {
          minV = math.min(minV, v);
          maxV = math.max(maxV, v);
        }
      }
    }

    if (!minV.isFinite || !maxV.isFinite || maxPoints < 2) {
      return;
    }

    if (symmetricZero) {
      final bound = math.max(minV.abs(), maxV.abs());
      final pad = bound == 0 ? 1.0 : bound * 1.12;
      minV = -pad;
      maxV = pad;
    } else if ((maxV - minV).abs() < 1e-9) {
      minV -= 0.5;
      maxV += 0.5;
    } else {
      final pad = (maxV - minV) * 0.1;
      minV -= pad;
      maxV += pad;
    }

    final span = maxV - minV;
    double mapY(double v) =>
        size.height - ((v - minV) / span).clamp(0.0, 1.0) * size.height;

    if (minV < 0 && maxV > 0) {
      final zeroY = mapY(0);
      final zeroPaint = Paint()
        ..color = kMuted.withValues(alpha: 0.35)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);
    }

    for (final trace in traces) {
      final len = trace.values.length;
      if (len < 2) continue;
      final paint = Paint()
        ..color = trace.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = trace.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      var started = false;
      for (var i = 0; i < len; i++) {
        final v = trace.values[i];
        if (v == null || !v.isFinite) {
          started = false;
          continue;
        }
        final x = size.width * i / (len - 1);
        final y = mapY(v);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          if (trace.dashed && i.isOdd) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiSeriesPainter oldDelegate) => true;
}
