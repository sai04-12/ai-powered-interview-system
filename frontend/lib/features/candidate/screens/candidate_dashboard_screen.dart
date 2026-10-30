import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class CandidateDashboardScreen extends StatelessWidget {
  const CandidateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Left Sidebar
          const AppSidebar(
            currentRoute: '/dashboard',
            role: SidebarRole.candidate,
          ),

          // Main Screen Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                const AppTopbar(
                  title: 'Good Morning, Lasya 👋',
                  subtitle: 'Ready for your next opportunity?',
                  showCandidateProfile: true,
                ),

                // Sub-header Banner Quote
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.format_quote, size: 16, color: AppTheme.primary),
                          SizedBox(width: 6),
                          Text(
                            '"Practice Smarter. Perform Brighter."',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'AI Assessment Engine Ready',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Upcoming Interview Banner Card
                          _buildUpcomingInterviewCard(context),
                          const SizedBox(height: 24),

                          // 2. 4 Stat Cards Row
                          _buildStatsRow(context),
                          const SizedBox(height: 28),

                          // 3. Recent Activity Section
                          _buildRecentActivitySection(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingInterviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Upcoming Interview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Frontend Developer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
                    SizedBox(width: 6),
                    Text(
                      'Today, 10:00 AM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () => context.go('/live-interview'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.play_arrow, size: 18, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Join Interview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Profile Verified',
              value: 'Verified',
              icon: Icons.verified_outlined,
              iconColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
              onTap: () => context.go('/verification'),
            ),
            _buildStatCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Resume Analyzed',
              value: '92% Match',
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              onTap: () => context.go('/resume-analysis'),
            ),
            _buildStatCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Completed Interviews',
              value: '3',
              icon: Icons.video_camera_front_outlined,
              iconColor: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
              onTap: () => context.go('/interviews'),
            ),
            _buildStatCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Average Score',
              value: '78%',
              icon: Icons.star_outline,
              iconColor: const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              onTap: () => context.go('/evaluation-report'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/interviews'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Activity 1: Resume analyzed
          _buildActivityItem(
            context: context,
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            title: 'Resume analyzed',
            timestamp: '2 days ago',
            badgeText: 'Completed',
            badgeColor: const Color(0xFF10B981),
            badgeBgColor: const Color(0xFFECFDF5),
            onTap: () => context.go('/resume-analysis'),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24),

          // Activity 2: Interview completed
          _buildActivityItem(
            context: context,
            icon: Icons.video_camera_front_outlined,
            iconColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
            title: 'Interview completed',
            subtitle: 'Frontend Developer',
            timestamp: 'Frontend Developer',
            badgeText: 'Score: 82%',
            badgeColor: const Color(0xFF2563EB),
            badgeBgColor: const Color(0xFFEFF6FF),
            onTap: () => context.go('/evaluation-report'),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 24),

          // Activity 3: Profile verification
          _buildActivityItem(
            context: context,
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            title: 'Profile verification',
            timestamp: '1 week ago',
            badgeText: 'Verified',
            badgeColor: const Color(0xFF10B981),
            badgeBgColor: const Color(0xFFECFDF5),
            onTap: () => context.go('/verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    String? subtitle,
    required String timestamp,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

