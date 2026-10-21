import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/providers/interview_provider.dart';
import 'package:frontend/providers/job_provider.dart';
import 'package:frontend/providers/resume_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class InterviewSetupScreen extends ConsumerStatefulWidget {
  final String? initialJobId;
  final String? initialResumeId;

  const InterviewSetupScreen({
    super.key,
    this.initialJobId,
    this.initialResumeId,
  });

  @override
  ConsumerState<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends ConsumerState<InterviewSetupScreen> {
  String? _selectedJobId;
  String? _selectedResumeId;
  int _questionCount = 5;
  String _mode = 'mixed';
  bool _consentGiven = true;
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedJobId = widget.initialJobId;
    _selectedResumeId = widget.initialResumeId;
  }

  Future<void> _startSession() async {
    if (_selectedJobId == null) {
      setState(() => _errorMessage = 'Please select a target job position.');
      return;
    }
    if (!_consentGiven) {
      setState(() => _errorMessage = 'Please review and accept the interview terms.');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(interviewServiceProvider);
      final session = await service.createSession(
        jobId: _selectedJobId!,
        resumeId: _selectedResumeId,
        totalQuestions: _questionCount,
        mode: _mode,
      );

      // Start the draft session automatically to enter in_progress state
      await service.startSession(session.id);

      if (mounted) {
        context.go('/interviews/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsListProvider);
    final resumesAsync = ref.watch(resumesListProvider);

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: AppHeader(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/jobs'),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Interview Setup & Guidelines',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure your adaptive interview session, select target competencies, and review instructions.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
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
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Configuration Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Position',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        jobsAsync.when(
                          data: (jobs) {
                            if (jobs.isEmpty) {
                              return const Text('No jobs available.', style: TextStyle(color: AppTheme.textSecondary));
                            }
                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: jobs.any((j) => j.id == _selectedJobId) ? _selectedJobId : null,
                              decoration: const InputDecoration(
                                labelText: 'Select Job Position',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                              items: jobs.map((j) {
                                return DropdownMenuItem(
                                  value: j.id,
                                  child: Text(
                                    '${j.title} ${j.company != null ? "(${j.company})" : ""}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedJobId = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading jobs: $e', style: const TextStyle(color: AppTheme.error)),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Candidate Resume (Optional Context)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Authorizes tailoring interview questions to align with your documented skills.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        resumesAsync.when(
                          data: (resumes) {
                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: resumes.any((r) => r.id == _selectedResumeId) ? _selectedResumeId : null,
                              decoration: const InputDecoration(
                                labelText: 'Attach Resume (Optional)',
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No Resume (Standard Question Bank)', overflow: TextOverflow.ellipsis),
                                ),
                                ...resumes.map((r) {
                                  return DropdownMenuItem(
                                    value: r.id,
                                    child: Text('${r.filename} (${r.extractionStatus.toUpperCase()})', overflow: TextOverflow.ellipsis),
                                  );
                                }),
                              ],
                              onChanged: (val) => setState(() => _selectedResumeId = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => const SizedBox(),
                        ),
                        const SizedBox(height: 20),

                        // Question Count & Mode
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 500;
                            final children = [
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Question Count', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      initialValue: _questionCount,
                                      decoration: const InputDecoration(prefixIcon: Icon(Icons.format_list_numbered)),
                                      items: const [
                                        DropdownMenuItem(value: 3, child: Text('3 Questions (Quick)', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 5, child: Text('5 Questions (Standard)', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 7, child: Text('7 Questions (In-Depth)', overflow: TextOverflow.ellipsis)),
                                      ],
                                      onChanged: (val) => setState(() => _questionCount = val ?? 5),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isWide) const SizedBox(height: 16),
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Interview Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _mode,
                                      decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
                                      items: const [
                                        DropdownMenuItem(value: 'mixed', child: Text('Mixed (Tech + Behavioral)', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 'technical', child: Text('Technical & Problem Solving', overflow: TextOverflow.ellipsis)),
                                        DropdownMenuItem(value: 'behavioral', child: Text('Behavioral & Collaboration', overflow: TextOverflow.ellipsis)),
                                      ],
                                      onChanged: (val) => setState(() => _mode = val ?? 'mixed'),
                                    ),
                                  ],
                                ),
                              ),
                            ];

                            return isWide
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: children,
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: children,
                                  );
                          },
                        ),

                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Guidelines & Consent Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Candidate Guidelines & Integrity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Questions adapt deterministically to test your technical competencies.\n'
                          '• Each question requires an answer submission before advancing to the subsequent question.\n'
                          '• Once an interview session is submitted or abandoned, it cannot be restarted.\n'
                          '• Automated evaluation and scoring will be generated during Phase 7.',
                          style: TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'I understand the interview format and agree to submit authentic, typed responses.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          value: _consentGiven,
                          onChanged: (val) => setState(() => _consentGiven = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Start Button
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _startSession,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(_isCreating ? 'Preparing Session...' : 'Begin Interview Session'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
