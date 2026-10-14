import 'package:flutter/material.dart';

class TrendChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const TrendChartWidget({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              values: values,
              lineColor: const Color(0xFF0D5C3A),
              fillColor: const Color(0xFF0D5C3A).withOpacity(0.12),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((l) => Text(
            l,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final double minVal = values.reduce((a, b) => a < b ? a : b) - 2;
    final double maxVal = values.reduce((a, b) => a > b ? a : b) + 2;
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    final double stepX = size.width / (values.length - 1);

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      final double normalized = (values[i] - minVal) / range;
      final double y = size.height - (normalized * (size.height - 12)) - 6;
      points.add(Offset(x, y));
    }

    // Draw Fill Path
    final Path fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      fillPath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw Stroke Path
    final Path strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      strokePath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    final Paint strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(strokePath, strokePaint);

    // Draw points
    final Paint pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final Paint pointInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, pointPaint);
      canvas.drawCircle(pt, 2.0, pointInner);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
