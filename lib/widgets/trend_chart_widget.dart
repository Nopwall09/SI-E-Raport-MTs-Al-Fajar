import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Grafik tren sederhana untuk memantau perkembangan nilai anak secara berkala.
class TrendChartWidget extends StatelessWidget {
  const TrendChartWidget({
    super.key,
    required this.values,
    required this.labels,
    this.height = 90,
  });

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values,
              lineColor: kBrand,
              fillColor: kBrand.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < labels.length; i++)
              Column(
                children: [
                  if (i < values.length)
                    Text(
                      values[i] % 1 == 0
                          ? values[i].toInt().toString()
                          : values[i].toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kBrand,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      fontSize: 11,
                      color: kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minVal = values.reduce((a, b) => a < b ? a : b) - 3;
    final maxVal = values.reduce((a, b) => a > b ? a : b) + 3;
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = size.width / (values.length - 1);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 18)) - 8;
      points.add(Offset(x, y));
    }

    // Area pengisian bawah kurva
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      fillPath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Garis kurva utama
    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      strokePath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(strokePath, strokePaint);

    // Titik data (bullet points)
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final pointInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, pointPaint);
      canvas.drawCircle(pt, 2.2, pointInner);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

