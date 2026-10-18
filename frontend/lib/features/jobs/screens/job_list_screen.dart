import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/models/job_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/job_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class JobListScreen extends ConsumerWidget {
  const JobListScreen({super.key});

  void _showCreateJobDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final reqSkillsCtrl = TextEditingController();
    final prefSkillsCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final eduCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post New Job Opening'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Job Title *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(labelText: 'Company / Organization'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Job Description *'),
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().length < 10 ? 'Description must be at least 10 chars' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reqSkillsCtrl,
                    decoration: const InputDecoration(labelText: 'Required Skills (comma-separated) *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'At least one required skill needed' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: prefSkillsCtrl,
                    decoration: const InputDecoration(labelText: 'Preferred Skills (comma-separated)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: expCtrl,
                    decoration: const InputDecoration(labelText: 'Minimum Experience (years)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: eduCtrl,
                    decoration: const InputDecoration(labelText: 'Education Requirements'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reqSkills = reqSkillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final prefSkills = prefSkillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final minExp = int.tryParse(expCtrl.text.trim());

                final notifier = ref.read(jobActionProvider.notifier);
                final job = await notifier.createJob(
                  title: titleCtrl.text.trim(),
                  company: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  requiredSkills: reqSkills,
                  preferredSkills: prefSkills,
                  minExperienceYears: minExp,
                  educationRequirements: eduCtrl.text.trim().isEmpty ? null : eduCtrl.text.trim(),
                );

                if (job != null && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Job posted successfully!'), backgroundColor: AppTheme.success),
                  );
                }
              }
            },
            child: const Text('Post Job'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsListProvider);
    final authState = ref.watch(authProvider);
    final isRecruiterOrAdmin = authState.user?.isRecruiter == true || authState.user?.isAdmin == true;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: AppHeader(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Job Openings & Positions',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Explore available job postings and match your skills against job requirements.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isRecruiterOrAdmin)
                      ElevatedButton.icon(
                        onPressed: () => _showCreateJobDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Post New Job'),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                Expanded(
                  child: jobsAsync.when(
                    data: (jobs) {
                      if (jobs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline, size: 48, color: AppTheme.textSecondary),
                              const SizedBox(height: 16),
                              const Text('No Job Postings Available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Check back soon for new opportunities.', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: jobs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final job = jobs[index];
                          return _buildJobCard(context, ref, job);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text('Failed to load jobs: $err', style: const TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(jobsListProvider),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, WidgetRef ref, JobModel job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22.0),
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
                        job.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      if (job.company != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          job.company!,
                          style: const TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                if (job.minExperienceYears != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: Text(
                      '${job.minExperienceYears}+ Yrs Exp',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Required Skills:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.requiredSkills.map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/match?jobId=${job.id}'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Match My Resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
