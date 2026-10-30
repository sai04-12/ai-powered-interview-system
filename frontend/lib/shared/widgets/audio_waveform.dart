import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isListening;
  final Color? barColor;
  final double height;

  const AudioWaveformVisualizer({
    super.key,
    this.isListening = true,
    this.barColor,
    this.height = 36,
  });

  @override
  State<AudioWaveformVisualizer> createState() => _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.barColor ?? AppTheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(14, (index) {
            // Compute dynamic height based on sine wave with offset
            final phase = (index / 14) * 2 * math.pi;
            final progress = _controller.value * 2 * math.pi;
            final scale = widget.isListening
                ? 0.3 + 0.7 * (0.5 + 0.5 * math.sin(progress + phase))
                : 0.2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3.5,
              height: widget.height * scale,
              decoration: BoxDecoration(
                color: color.withValues(alpha: widget.isListening ? 0.9 : 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

