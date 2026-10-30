import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import 'app_logo.dart';

enum SidebarRole { candidate, recruiter }

class AppSidebar extends StatelessWidget {
  final String currentRoute;
  final SidebarRole role;
  final Function(SidebarRole)? onRoleChanged;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.role = SidebarRole.candidate,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          right: BorderSide(color: AppTheme.cardBorderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: InkWell(
              onTap: () => context.go('/dashboard'),
              borderRadius: BorderRadius.circular(8),
              child: const AppLogo(size: 34),
            ),
          ),

          // Role Switcher Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (onRoleChanged != null) {
                          onRoleChanged!(SidebarRole.candidate);
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: role == SidebarRole.candidate
                              ? AppTheme.surfaceLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: role == SidebarRole.candidate
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Candidate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: role == SidebarRole.candidate
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: role == SidebarRole.candidate
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (onRoleChanged != null) {
                          onRoleChanged!(SidebarRole.recruiter);
                        } else {
                          context.go('/recruiter/dashboard');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: role == SidebarRole.recruiter
                              ? AppTheme.surfaceLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: role == SidebarRole.recruiter
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Recruiter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: role == SidebarRole.recruiter
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: role == SidebarRole.recruiter
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: role == SidebarRole.candidate
                  ? _buildCandidateMenu(context)
                  : _buildRecruiterMenu(context),
            ),
          ),

          // Workflow & Presentation Highlights
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_tree_outlined,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'System Workflow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '11-Step AI Pipeline & College Project Architecture',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => context.go('/workflow'),
                      child: const Text(
                        'View 11-Step Flow',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer info matching College Slide
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.cardBorderLight, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Alwardas Polytechnic College',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Dept. of Computer Engineering',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCandidateMenu(BuildContext context) {
    return [
      _buildNavItem(
        context,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
      ),
      _buildNavItem(
        context,
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'My Interviews',
        route: '/interviews',
      ),
      _buildNavItem(
        context,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        route: '/profile-matching',
      ),
      _buildNavItem(
        context,
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Resume',
        route: '/resumes',
      ),
      _buildNavItem(
        context,
        icon: Icons.card_membership_outlined,
        activeIcon: Icons.card_membership,
        label: 'Certificates',
        route: '/evaluation-report',
      ),
      _buildNavItem(
        context,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings',
        route: '/settings',
      ),
    ];
  }

  List<Widget> _buildRecruiterMenu(BuildContext context) {
    return [
      _buildNavItem(
        context,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Dashboard',
        route: '/recruiter/dashboard',
      ),
      _buildNavItem(
        context,
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Candidates',
        route: '/recruiter/candidates',
      ),
      _buildNavItem(
        context,
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        label: 'Job Postings',
        route: '/jobs',
      ),
      _buildNavItem(
        context,
        icon: Icons.video_call_outlined,
        activeIcon: Icons.video_call,
        label: 'Interviews',
        route: '/interviews',
      ),
      _buildNavItem(
        context,
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: 'Reports',
        route: '/evaluation-report',
      ),
      _buildNavItem(
        context,
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Settings',
        route: '/settings',
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route ||
        (route != '/dashboard' &&
            route != '/recruiter/dashboard' &&
            currentRoute.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppTheme.primary : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

