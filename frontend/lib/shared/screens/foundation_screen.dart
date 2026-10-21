import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/status_card.dart';

class FoundationScreen extends ConsumerWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthCheckProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Banner
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1B4B), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3730A3), width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'AI-Powered Intelligent Interview System',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Phase 4 Authentication & RBAC enabled. Secure Argon2id password hashing, JWT token rotation, and role-based workflows initialized.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => ref.invalidate(healthCheckProvider),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Check Health'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Authentication & Session Status Section
                      const Text(
                        'Authentication & Role Session',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (authState.isAuthenticated)
                        StatusCard(
                          title: 'Active Session: ${authState.user?.fullName ?? authState.user?.email}',
                          subtitle:
                              'Email: ${authState.user?.email} | Role: ${authState.user?.role.toUpperCase()} | Account Status: Active',
                          icon: authState.user?.role == 'recruiter'
                              ? Icons.business_center
                              : Icons.person,
                          iconColor: authState.user?.role == 'recruiter'
                              ? AppTheme.accentTeal
                              : AppTheme.primaryLight,
                          trailing: OutlinedButton(
                            onPressed: () => ref.read(authProvider.notifier).logout(),
                            child: const Text('Sign Out'),
                          ),
                        )
                      else
                        StatusCard(
                          title: 'No Active Session (Unauthenticated)',
                          subtitle:
                              'Sign in to access candidate interviews or recruiter management tools.',
                          icon: Icons.lock_outline,
                          iconColor: AppTheme.textSecondary,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Sign In'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => context.go('/register'),
                                child: const Text('Register'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Health Status Section
                      const Text(
                        'Backend Health & Communication',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      healthAsync.when(
                        data: (health) => StatusCard(
                          title: 'FastAPI Backend Operational',
                          subtitle:
                              'Environment: ${health.environment} | API Version: ${health.version} | Timestamp: ${health.timestamp}',
                          icon: Icons.check_circle_outline,
                          iconColor: AppTheme.success,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'CONNECTED',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        loading: () => StatusCard(
                          title: 'Connecting to Backend...',
                          subtitle: 'Pinging ${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}',
                          icon: Icons.hourglass_top,
                          iconColor: AppTheme.warning,
                          trailing: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (err, stack) => StatusCard(
                          title: 'Backend Offline / Unreachable',
                          subtitle:
                              'Target: ${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}\n$err',
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppTheme.error,
                          onTap: () => ref.invalidate(healthCheckProvider),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.error),
                            tooltip: 'Retry Connection',
                            onPressed: () => ref.invalidate(healthCheckProvider),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Architecture & Modules Grid
                      const Text(
                        'System Architecture & Core Subsystems',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                child: const StatusCard(
                                  title: 'Authentication & Security',
                                  subtitle:
                                      'Argon2id password hashing, JWT tokens with refresh cycle, RBAC for Candidate, Recruiter, and Admin.',
                                  icon: Icons.security,
                                  iconColor: AppTheme.accent,
                                ),
                              ),
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                child: StatusCard(
                                  title: 'Resume & Job Matching',
                                  subtitle:
                                      'PDF/DOCX text parsing, transparent skill overlap, and semantic matching without data fabrication.',
                                  icon: Icons.document_scanner_outlined,
                                  iconColor: AppTheme.accentTeal,
                                  onTap: () => context.go('/resumes'),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                child: StatusCard(
                                  title: 'Adaptive AI Engine',
                                  subtitle:
                                      'Stateful interview sessions, job-relevant dynamic questions, follow-ups, and validated rubric scoring.',
                                  icon: Icons.psychology,
                                  iconColor: AppTheme.primaryLight,
                                  onTap: () => context.go('/interviews'),
                                ),
                              ),
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                child: const StatusCard(
                                  title: 'Session & Identity Integrity',
                                  subtitle:
                                      'Consent-driven camera check, connection and pause telemetry distinct from job competence scoring.',
                                  icon: Icons.videocam_outlined,
                                  iconColor: AppTheme.warning,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
