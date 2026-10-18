import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/models/match_model.dart';
import 'package:frontend/providers/job_provider.dart';
import 'package:frontend/providers/match_provider.dart';
import 'package:frontend/providers/resume_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class ResumeMatchScreen extends ConsumerStatefulWidget {
  final String? initialResumeId;
  final String? initialJobId;

  const ResumeMatchScreen({
    super.key,
    this.initialResumeId,
    this.initialJobId,
  });

  @override
  ConsumerState<ResumeMatchScreen> createState() => _ResumeMatchScreenState();
}

class _ResumeMatchScreenState extends ConsumerState<ResumeMatchScreen> {
  String? _selectedResumeId;
  String? _selectedJobId;

  @override
  void initState() {
    super.initState();
    _selectedResumeId = widget.initialResumeId;
    _selectedJobId = widget.initialJobId;
  }

  Future<void> _runEvaluation() async {
    if (_selectedResumeId == null || _selectedJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a resume and a target job to evaluate.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    await ref.read(matchProvider.notifier).evaluateMatch(
          resumeId: _selectedResumeId!,
          jobId: _selectedJobId!,
        );
  }

  Color _getScoreColor(double score) {
    if (score >= 75.0) return AppTheme.success;
    if (score >= 50.0) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final resumesAsync = ref.watch(resumesListProvider);
    final jobsAsync = ref.watch(jobsListProvider);
    final matchState = ref.watch(matchProvider);

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: AppHeader(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/resumes'),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Intelligent Job Matching',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Evaluate candidate resumes against job opening requirements using transparent skill gap analysis.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Resume & Target Job Opening',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        // Resume Dropdown
                        resumesAsync.when(
                          data: (resumes) {
                            final completedResumes = resumes.where((r) => r.isCompleted).toList();
                            if (completedResumes.isEmpty) {
                              return OutlinedButton.icon(
                                onPressed: () => context.go('/resumes/upload'),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('No parsed resumes found — Upload a Resume First'),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              initialValue: completedResumes.any((r) => r.id == _selectedResumeId) ? _selectedResumeId : null,
                              decoration: const InputDecoration(
                                labelText: 'Candidate Resume',
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                              items: completedResumes.map((r) {
                                return DropdownMenuItem(
                                  value: r.id,
                                  child: Text('${r.filename} (${r.skills.length} skills)'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedResumeId = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading resumes: $e', style: const TextStyle(color: AppTheme.error)),
                        ),
                        const SizedBox(height: 16),

                        // Job Dropdown
                        jobsAsync.when(
                          data: (jobs) {
                            if (jobs.isEmpty) {
                              return const Text('No jobs available yet.', style: TextStyle(color: AppTheme.textSecondary));
                            }
                            return DropdownButtonFormField<String>(
                              initialValue: jobs.any((j) => j.id == _selectedJobId) ? _selectedJobId : null,
                              decoration: const InputDecoration(
                                labelText: 'Target Job Position',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                              items: jobs.map((j) {
                                return DropdownMenuItem(
                                  value: j.id,
                                  child: Text('${j.title} ${j.company != null ? "(${j.company})" : ""}'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedJobId = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading jobs: $e', style: const TextStyle(color: AppTheme.error)),
                        ),
                        const SizedBox(height: 20),

                        // Evaluate Button
                        ElevatedButton.icon(
                          onPressed: matchState.isLoading ? null : _runEvaluation,
                          icon: matchState.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome_rounded),
                          label: Text(matchState.isLoading ? 'Calculating Match Score...' : 'Run Match Analysis'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message Banner
                if (matchState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            matchState.errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Evaluation Results Dashboard
                if (matchState.matchResult != null)
                  _buildMatchResults(matchState.matchResult!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchResults(MatchModel match) {
    final overallColor = _getScoreColor(match.overallScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Header
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: overallColor, width: 4),
                    color: overallColor.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      '${match.overallScore.round()}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: overallColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.jobTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Evaluation completed on ${match.createdAt?.toLocal().toString().split('.')[0] ?? 'Recently'}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Component Breakdown Progress Bars
            const Text(
              'Score Component Breakdown',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildScoreBar('Technical Skills Match', match.skillScore),
            const SizedBox(height: 10),
            _buildScoreBar('Experience Duration Match', match.experienceScore),
            if (match.educationScore != null) ...[
              const SizedBox(height: 10),
              _buildScoreBar('Education Criteria Match', match.educationScore!),
            ],
            const Divider(height: 32),

            // Matched Skills
            const Text(
              'Matched Skills with Evidence:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            if (match.matchedSkills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.matchedSkills.map((m) {
                  return Chip(
                    avatar: const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                    label: Text('${m.skill} ${m.isRequired ? "(Required)" : "(Preferred)"}', style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.success.withValues(alpha: 0.12),
                    side: BorderSide(color: AppTheme.success.withValues(alpha: 0.3)),
                  );
                }).toList(),
              )
            else
              const Text('No direct skill matches identified in resume text.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),

            // Missing Required Skills
            if (match.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Missing or Unverified Required Skills:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.warning),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.missingSkills.map((s) {
                  return Chip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warning),
                    label: Text(s, style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
                    backgroundColor: AppTheme.warning.withValues(alpha: 0.12),
                    side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.3)),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 32),

            // Explanation & Methodology
            const Text(
              'Detailed Evaluation Explanation',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                match.explanation,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Limitations Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3730A3)),
              ),
              child: Text(
                match.limitations,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, double score) {
    final color = _getScoreColor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            Text('${score.round()}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
