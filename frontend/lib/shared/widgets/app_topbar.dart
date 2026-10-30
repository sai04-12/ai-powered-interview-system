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
                  'PDF SCREENS SHOWCASE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: '/login',
                child: Text('Page 2: Login & Sign Up'),
              ),
              const PopupMenuItem(
                value: '/dashboard',
                child: Text('Page 2: Candidate Dashboard'),
              ),
              const PopupMenuItem(
                value: '/profile-matching',
                child: Text('Page 3: Job Role Matching (Semantic)'),
              ),
              const PopupMenuItem(
                value: '/live-interview',
                child: Text('Page 4: Live AI Interview (Video + Chat)'),
              ),
              const PopupMenuItem(
                value: '/evaluation-report',
                child: Text('Page 4: Interview Evaluation Report'),
              ),
              const PopupMenuItem(
                value: '/recruiter/candidates',
                child: Text('Page 4: Recruiter Candidates List'),
              ),
              const PopupMenuItem(
                value: '/recruiter/dashboard',
                child: Text('Page 4: Recruiter Analytics Dashboard'),
              ),
              const PopupMenuItem(
                value: '/workflow',
                child: Text('Page 5: 11-Step System Workflow'),
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
                        showCandidateProfile ? 'PS' : 'RV',
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
                      showCandidateProfile ? 'Priya Sharma' : 'Rohit Verma',
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
