import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.textColor,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Ai',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.52,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Text(
            'AI Interview',
            style: TextStyle(
              fontSize: size * 0.54,
              fontWeight: FontWeight.w800,
              color: textColor ?? AppTheme.textDark,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ],
    );
  }
}

