import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class AiRobotAvatar extends StatelessWidget {
  final double size;
  final bool isAnimated;

  const AiRobotAvatar({
    super.key,
    this.size = 64,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.75,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(size * 0.2),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Left Glowing Eye
              Container(
                width: size * 0.18,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(size * 0.08),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF38BDF8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Right Glowing Eye
              Container(
                width: size * 0.18,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(size * 0.08),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF38BDF8),
                      blurRadius: 6,
                      spreadRadius: 1,
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
}

