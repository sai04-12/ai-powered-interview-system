import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/evaluation_model.dart';
import 'package:frontend/providers/evaluation_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class InterviewEvaluationScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const InterviewEvaluationScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<InterviewEvaluationScreen> createState() => _InterviewEvaluationScreenState();
}

class _InterviewEvaluationScreenState extends ConsumerState<InterviewEvaluationScreen> {
  bool _isEvaluating = false;
  String? _actionError;

  Future<void> _triggerEvaluation({bool force = false}) async {
    setState(() {
      _isEvaluating = true;
      _actionError = null;
    });

    try {
      await ref.read(sessionEvaluationNotifierProvider.notifier).evaluateSession(
            widget.sessionId,
            forceReevaluate: force,
          );
      ref.invalidate(sessionEvaluationReportProvider(widget.sessionId));
    } catch (e) {
      setState(() {
        _actionError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEvaluating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(sessionEvaluationReportProvider(widget.sessionId));

    return Scaffold(
      appBar: const AppHeader(),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading structured AI evaluation report...'),
              ],
            ),
          ),
          error: (err, _) => Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 3,
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to Load Evaluation Report',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(sessionEvaluationReportProvider(widget.sessionId)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Loading'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/interviews'),
                        child: const Text('Back to Interviews'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          data: (report) => _buildReportView(context, report),
        ),
      ),
    );
  }

  Widget _buildReportView(BuildContext context, SessionEvaluationReportModel report) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 16,
        vertical: 24,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Navigation and Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/interviews'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Interviews'),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (report.evaluatedQuestions < report.answeredQuestions || report.averageOverallScore == null)
                        ElevatedButton.icon(
                          onPressed: _isEvaluating ? null : () => _triggerEvaluation(force: false),
                          icon: _isEvaluating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.assessment),
                          label: const Text('Evaluate Session Answers'),
                        ),
                      OutlinedButton.icon(
                        onPressed: _isEvaluating ? null : () => _triggerEvaluation(force: true),
                        icon: const Icon(Icons.replay),
                        label: const Text('Re-evaluate'),
                      ),
                    ],
                  ),
                ],
              ),
              if (_actionError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _actionError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Title and Metadata Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.jobTitle ?? 'Interview Session Evaluation',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (report.company != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    report.company!,
                                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _buildStatusPill(report.status),
                        ],
                      ),
                      const Divider(height: 32),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _buildMetadataItem('Session ID', report.sessionId.substring(0, 8)),
                          _buildMetadataItem('Evaluated', '${report.evaluatedQuestions} / ${report.totalQuestions} Questions'),
                          _buildMetadataItem('Evaluator Engine', report.evaluatorType.toUpperCase()),
                          if (report.completedAt != null)
                            _buildMetadataItem('Completed At', report.completedAt!.toLocal().toString().split('.')[0]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Overall Score Overview Banner
              _buildOverallScoreSection(context, report),
              const SizedBox(height: 24),

              // Mandatory AI Evaluation Limitations Disclaimer
              _buildDisclaimerCard(context, report.evaluationLimitations),
              const SizedBox(height: 24),

              // Strengths & Improvement Areas
              if (report.aggregatedStrengths.isNotEmpty || report.aggregatedImprovements.isNotEmpty) ...[
                _buildStrengthsAndImprovements(context, report),
                const SizedBox(height: 24),
              ],

              // Question-by-Question Rubric Breakdowns
              Text(
                'Per-Question Rubric Breakdowns',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...report.questionEvaluations.map((q) => _buildQuestionEvaluationCard(context, q)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade700;
    if (status == 'completed') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (status == 'requires_review') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
    } else if (status == 'failed') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildOverallScoreSection(BuildContext context, SessionEvaluationReportModel report) {
    final hasScore = report.averageOverallScore != null;
    final score = report.averageOverallScore ?? 0.0;
    Color scoreColor = Colors.grey;

    if (hasScore) {
      if (score >= 80) {
        scoreColor = Colors.green.shade600;
      } else if (score >= 60) {
        scoreColor = Colors.blue.shade600;
      } else if (score >= 40) {
        scoreColor = Colors.orange.shade600;
      } else {
        scoreColor = Colors.red.shade600;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withValues(alpha: 0.1),
                border: Border.all(color: scoreColor, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                report.formattedOverallScore,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Rubric Proficiency Score',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rubric Average: ${report.formattedRubricScore}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasScore
                        ? 'Weighted across all applicable rubric dimensions (technical knowledge, relevance, problem solving, and practical application).'
                        : 'Evaluation in progress or flagged for review. Submit answers to calculate proficiency scores.',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context, String disclaimer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel, color: Colors.amber.shade800, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transparent Scoring & Evaluation Limitations Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  disclaimer,
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsAndImprovements(BuildContext context, SessionEvaluationReportModel report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final strengthsWidget = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text('Demonstrated Strengths', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: 24),
                ...report.aggregatedStrengths.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Expanded(child: Text(s, style: const TextStyle(fontSize: 13, height: 1.4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final improvementsWidget = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text('Growth Opportunities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: 24),
                ...report.aggregatedImprovements.map(
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Expanded(child: Text(i, style: const TextStyle(fontSize: 13, height: 1.4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              strengthsWidget,
              const SizedBox(height: 16),
              improvementsWidget,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: strengthsWidget),
              const SizedBox(width: 16),
              Expanded(child: improvementsWidget),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuestionEvaluationCard(BuildContext context, SessionQuestionEvaluationModel item) {
    final eval = item.evaluation;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${item.questionOrder + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 10),
                Chip(
                  label: Text(item.category.replaceAll('_', ' ').toUpperCase()),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(item.skill),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (eval != null) _buildStatusPill(eval.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.questionText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            if (eval == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('No evaluation generated for this question yet.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else ...[
              if (eval.feedbackSummary != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  child: Text(
                    eval.feedbackSummary!,
                    style: TextStyle(fontSize: 13, color: Colors.indigo.shade900),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Criteria Breakdown
              const Text(
                'Rubric Dimensions & Answer Evidence:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...eval.criteriaScores.map((c) => _buildCriterionRow(context, c)),

              // Evidence Excerpts
              if (eval.evidenceExcerpts.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Evidence Excerpts from Candidate Response:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                ...eval.evidenceExcerpts.map(
                  (excerpt) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border(left: BorderSide(color: Colors.blue.shade400, width: 4)),
                    ),
                    child: Text(
                      '“$excerpt”',
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCriterionRow(BuildContext context, CriterionScoreModel c) {
    Color scoreColor = Colors.red;
    if (c.score == 4) {
      scoreColor = Colors.green;
    } else if (c.score == 3) {
      scoreColor = Colors.blue;
    } else if (c.score == 2) {
      scoreColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                c.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    '${c.score} / ${c.maxScore}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${(c.normalizedWeight * 100).toStringAsFixed(0)}% weight)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.maxScore > 0 ? c.score / c.maxScore : 0.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.explanation,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
