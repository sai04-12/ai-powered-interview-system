import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class CircularScoreGauge extends StatelessWidget {
  final double score; // 0 to 100
  final double size;
  final String? label;
  final Color? trackColor;
  final Color? progressColor;
  final double strokeWidth;

  const CircularScoreGauge({
    super.key,
    required this.score,
    this.size = 140,
    this.label,
    this.trackColor,
    this.progressColor,
    this.strokeWidth = 12,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveProgressColor = progressColor ??
        (score >= 80
            ? const Color(0xFF10B981)
            : score >= 60
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444));

    final effectiveTrackColor = trackColor ?? const Color(0xFFE2E8F0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              progress: (score / 100).clamp(0.0, 1.0),
              trackColor: effectiveTrackColor,
              progressColor: effectiveProgressColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}%',
                style: TextStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: size * 0.1,
                    fontWeight: FontWeight.w600,
                    color: effectiveProgressColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start at top (-pi/2)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

