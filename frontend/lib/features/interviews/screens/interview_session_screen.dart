import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/providers/interview_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class InterviewSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const InterviewSessionScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<InterviewSessionScreen> createState() => _InterviewSessionScreenState();
}

class _InterviewSessionScreenState extends ConsumerState<InterviewSessionScreen> {
  final TextEditingController _answerController = TextEditingController();
  int _charCount = 0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _answerController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interviewNotifierProvider.notifier).loadSession(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _answerController.removeListener(_onTextChanged);
    _answerController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _answerController.text;
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    setState(() {
      _charCount = text.length;
      _wordCount = words;
    });
    ref.read(interviewNotifierProvider.notifier).updateAnswerText(text);
  }

  Future<void> _showAbandonDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Interview Session?'),
        content: const Text(
          'Are you sure you want to abandon this interview session? '
          'Your progress will be closed and cannot be resumed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Interview'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abandon Session'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(interviewNotifierProvider.notifier)
          .abandonSession(widget.sessionId);
      if (success && mounted) {
        context.go('/interviews');
      }
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'hard':
        return const Color(0xFFA855F7);
      default:
        return AppTheme.primaryLight;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technical':
        return AppTheme.accent;
      case 'problem_solving':
        return AppTheme.accentTeal;
      case 'project_experience':
        return AppTheme.primaryLight;
      case 'behavioral':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(interviewNotifierProvider);
    final notifier = ref.read(interviewNotifierProvider.notifier);

    // If session is completed, redirect to completion screen
    if (sessionState.isCompleted && sessionState.session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/interviews/${widget.sessionId}/completed');
        }
      });
    }

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: AppHeader(),
      ),
      body: sessionState.errorMessage != null && sessionState.session == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to Load Session',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sessionState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => notifier.loadSession(widget.sessionId),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : sessionState.isLoading || sessionState.session == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading interview session...', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : _buildSessionBody(context, sessionState, notifier),

    );
  }

  Widget _buildSessionBody(
    BuildContext context,
    InterviewActiveState state,
    InterviewNotifier notifier,
  ) {
    final session = state.session!;
    final question = state.currentQuestion;
    final total = session.totalQuestionCount;
    final currentIdx = session.currentQuestionIndex;
    final progress = total > 0 ? (currentIdx / total).clamp(0.0, 1.0) : 0.0;
    final isLastQuestion = currentIdx >= total - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Session Status & Abandon Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                session.jobTitle ?? 'Job Interview',
                                style: const TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (session.company != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                session.company!,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Question ${currentIdx + 1} of $total',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    onPressed: state.isSubmitting || state.isAdvancing ? null : _showAbandonDialog,
                    icon: const Icon(Icons.exit_to_app, size: 16),
                    label: const Text('Abandon'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              const SizedBox(height: 20),

              // Adaptive feedback banner if present
              if (state.lastAdaptationNote != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, color: AppTheme.accentTeal, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.lastAdaptationNote!,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Error banner if any
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(fontSize: 13, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Question Card
              if (question != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata Tags
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(question.category).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getCategoryColor(question.category).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _formatCategory(question.category),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getCategoryColor(question.category),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 13,
                                    color: _getDifficultyColor(question.difficulty),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    question.difficulty.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getDifficultyColor(question.difficulty),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                question.skill,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                              backgroundColor: AppTheme.surfaceElevated,
                              side: const BorderSide(color: Color(0xFF475569)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Question Prompt
                        Text(
                          question.questionText,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.45,
                          ),
                        ),

                        if (question.selectionReason != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  question.selectionReason!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Answer Input Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Response',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '$_wordCount words | $_charCount characters',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _answerController,
                          maxLines: 8,
                          minLines: 5,
                          enabled: !state.isSubmitting && !state.isAdvancing,
                          decoration: InputDecoration(
                            hintText: 'Type your detailed answer here. Focus on clear reasoning, technical depth, and specific experiences...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF475569)),
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceElevated,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submission / Progression Controls
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // Submission Status Tag
                            if (state.hasSubmittedCurrentAnswer)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Answer Recorded',
                                    style: TextStyle(
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'Answer not yet submitted',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),

                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                // Submit Answer Button
                                ElevatedButton.icon(
                                  onPressed: state.isSubmitting || state.isAdvancing || _charCount == 0
                                      ? null
                                      : () async {
                                          await notifier.submitAnswer(widget.sessionId);
                                        },
                                  icon: state.isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.save_outlined, size: 18),
                                  label: Text(
                                    state.hasSubmittedCurrentAnswer ? 'Update Answer' : 'Submit Answer',
                                  ),
                                ),

                                // Next / Complete Button
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLastQuestion ? AppTheme.success : AppTheme.accent,
                                  ),
                                  onPressed: !state.hasSubmittedCurrentAnswer || state.isAdvancing
                                      ? null
                                      : () async {
                                          final ok = await notifier.advanceNext(widget.sessionId);
                                          if (ok) {
                                            _answerController.clear();
                                          }
                                        },
                                  icon: state.isAdvancing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Icon(
                                          isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward,
                                          size: 18,
                                        ),
                                  label: Text(isLastQuestion ? 'Complete Session' : 'Next Question'),
                                ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No questions available for this session.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
