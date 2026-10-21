import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import '../../providers/auth_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: AppTheme.primaryLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'AI Interviewer Platform',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Intelligent Recruitment & Evaluation Engine',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Phase 5 Navigation Links
          if (authState.isAuthenticated) ...[
            TextButton.icon(
              onPressed: () => context.go('/resumes'),
              icon: const Icon(Icons.description_outlined, size: 16),
              label: const Text('Resumes'),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => context.go('/jobs'),
              icon: const Icon(Icons.work_outline, size: 16),
              label: const Text('Jobs'),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => context.go('/match'),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Match'),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => context.go('/interviews'),
              icon: const Icon(Icons.record_voice_over_outlined, size: 16),
              label: const Text('Interviews'),
            ),
            const SizedBox(width: 12),
          ],

          // Auth State Actions
          if (authState.isAuthenticated) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (authState.user?.role == 'recruiter'
                        ? AppTheme.accentTeal
                        : AppTheme.primaryLight)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (authState.user?.role == 'recruiter'
                          ? AppTheme.accentTeal
                          : AppTheme.primaryLight)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    authState.user?.role == 'recruiter'
                        ? Icons.business_center
                        : Icons.person,
                    size: 14,
                    color: authState.user?.role == 'recruiter'
                        ? AppTheme.accentTeal
                        : AppTheme.primaryLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    authState.user?.fullName ?? authState.user?.email ?? 'User',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: authState.user?.role == 'recruiter'
                          ? AppTheme.accentTeal
                          : AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${authState.user?.role.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Sign In'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => context.go('/register'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Register'),
            ),
          ],
        ],
      ),
    );
  }
}
