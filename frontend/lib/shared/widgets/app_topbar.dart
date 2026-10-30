import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';

class AppTopbar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showCandidateProfile;

  const AppTopbar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showCandidateProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Greeting & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Custom trailing widgets if any
          ?trailing,

          const SizedBox(width: 16),

          // Quick Screen Switcher Menu for Evaluator/Demo
          PopupMenuButton<String>(
            tooltip: 'PDF Screen Showcase Jump',
            onSelected: (route) => context.go(route),
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  '12 PDF SCREENS SHOWCASE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: '/landing',
                child: Text('1. Landing Page'),
              ),
              const PopupMenuItem(
                value: '/login',
                child: Text('2. Login / Sign Up'),
              ),
              const PopupMenuItem(
                value: '/dashboard',
                child: Text('3. Candidate Dashboard'),
              ),
              const PopupMenuItem(
                value: '/recruiter/dashboard',
                child: Text('4. Recruiter Dashboard'),
              ),
              const PopupMenuItem(
                value: '/verification',
                child: Text('5. Profile Verification'),
              ),
              const PopupMenuItem(
                value: '/resume-analysis',
                child: Text('6. Resume Upload & Analysis'),
              ),
              const PopupMenuItem(
                value: '/live-interview',
                child: Text('7. Interview Session (Video + Qs)'),
              ),
              const PopupMenuItem(
                value: '/live-coding',
                child: Text('8. Live Coding / Response Input'),
              ),
              const PopupMenuItem(
                value: '/evaluation-report',
                child: Text('9. Interview Result / Report'),
              ),
              const PopupMenuItem(
                value: '/recruiter/candidates',
                child: Text('10. Candidates List (Recruiter)'),
              ),
              const PopupMenuItem(
                value: '/jobs/create',
                child: Text('11. Job Posting Management'),
              ),
              const PopupMenuItem(
                value: '/settings',
                child: Text('12. Settings / Admin'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: '/workflow',
                child: Text('⚡ System Workflow (11 Steps)'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.slideshow, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'PDF Screens',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primary),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications: Live interview scheduled for today at 10:00 AM.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: AppTheme.textDark,
                  size: 22,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // User Profile Avatar
          InkWell(
            onTap: () => context.go('/dashboard'),
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFFFED7AA),
                      alignment: Alignment.center,
                      child: Text(
                        showCandidateProfile ? 'L' : 'RV',
                        style: const TextStyle(
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showCandidateProfile ? 'Lasya' : 'Rohit Verma',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      showCandidateProfile ? 'Candidate' : 'Recruiter',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
