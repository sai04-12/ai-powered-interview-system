import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/models/resume_model.dart';
import 'package:frontend/providers/resume_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class ResumeListScreen extends ConsumerWidget {
  const ResumeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumesAsync = ref.watch(resumesListProvider);

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
                // Header and Upload Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'My Resumes & Documents',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Manage your uploaded resumes, extracted skill profiles, and job matches.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/resumes/upload'),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Upload Resume'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Resumes List State
                Expanded(
                  child: resumesAsync.when(
                    data: (resumes) {
                      if (resumes.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return ListView.separated(
                        itemCount: resumes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final resume = resumes[index];
                          return _buildResumeCard(context, ref, resume);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load resumes: $err',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(resumesListProvider),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_outlined, size: 48, color: AppTheme.primaryLight),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Resumes Uploaded Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your first PDF or Word resume to unlock automatic skill extraction and job matching.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/resumes/upload'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Upload Resume Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeCard(BuildContext context, WidgetRef ref, ResumeModel resume) {
    final skills = resume.skills;
    final exp = resume.totalExperienceYears;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryLight, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resume.filename,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${(resume.fileSize / 1024).toStringAsFixed(1)} KB | Uploaded: ${resume.createdAt?.toLocal().toString().split('.')[0] ?? 'Recently'}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (resume.isCompleted ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resume.extractionStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: resume.isCompleted ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                  tooltip: 'Delete Resume',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Resume?'),
                        content: Text('Are you sure you want to delete "${resume.filename}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(resumeUploadProvider.notifier).deleteResume(resume.id);
                    }
                  },
                ),
              ],
            ),
            if (exp != null || skills.isNotEmpty) ...[
              const Divider(height: 24),
              if (exp != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Documented Experience: $exp years',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              if (skills.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.take(8).map((skill) {
                    return Chip(
                      label: Text(skill, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.surfaceElevated,
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFF475569)),
                    );
                  }).toList(),
                ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: resume.isCompleted
                    ? () => context.go('/match?resumeId=${resume.id}')
                    : null,
                icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                label: const Text('Match Against Job Openings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
