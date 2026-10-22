import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/providers/interview_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class InterviewCompletionScreen extends ConsumerWidget {
  final String sessionId;

  const InterviewCompletionScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(interviewNotifierProvider);
    final session = sessionState.session;

    if (session == null || session.id != sessionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(interviewNotifierProvider.notifier).loadSession(sessionId);
      });
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: AppHeader(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Completion Icon & Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: AppTheme.success,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Interview Session Completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      session?.jobTitle != null
                          ? 'Responses recorded for ${session!.jobTitle}'
                          : 'Your answers have been recorded successfully.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Session Summary Box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Status',
                            'COMPLETED',
                            valueColor: AppTheme.success,
                            isBold: true,
                          ),
                          const Divider(height: 18, color: Color(0xFF334155)),
                          _buildSummaryRow(
                            'Questions Answered',
                            '${session?.totalQuestionCount ?? 5} of ${session?.totalQuestionCount ?? 5}',
                          ),
                          if (session?.startedAt != null) ...[
                            const Divider(height: 18, color: Color(0xFF334155)),
                            _buildSummaryRow(
                              'Started At',
                              session!.startedAt!.toLocal().toString().split('.').first,
                            ),
                          ],
                          if (session?.completedAt != null) ...[
                            const Divider(height: 18, color: Color(0xFF334155)),
                            _buildSummaryRow(
                              'Completed At',
                              session!.completedAt!.toLocal().toString().split('.').first,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // AI Evaluation Access Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.assessment, color: AppTheme.primaryLight, size: 22),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI Answer Evaluation & Transparent Scoring is available. View objective rubric assessments, criterion scores, and growth suggestions.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/interviews/$sessionId/evaluation'),
                              icon: const Icon(Icons.analytics_outlined, size: 18),
                              label: const Text('View AI Evaluation Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/interviews'),
                            icon: const Icon(Icons.list_alt, size: 18),
                            label: const Text('My Interviews'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/jobs'),
                            icon: const Icon(Icons.work_outline, size: 18),
                            label: const Text('Explore Jobs'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
