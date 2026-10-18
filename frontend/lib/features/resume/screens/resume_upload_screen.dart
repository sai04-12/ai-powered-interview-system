import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_theme.dart';
import 'package:frontend/models/resume_model.dart';
import 'package:frontend/providers/resume_provider.dart';
import 'package:frontend/shared/widgets/app_header.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  String? _selectedFileName;
  List<int>? _selectedFileBytes;
  int? _selectedFileSize;
  String? _localValidationError;

  Future<void> _pickFile() async {
    setState(() {
      _localValidationError = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final size = bytes.length;
        final name = file.name;

        if (bytes.isEmpty) {
          setState(() {
            _localValidationError = 'Selected file is empty.';
          });
          return;
        }

        // 10 MB limit check
        if (size > 10 * 1024 * 1024) {
          setState(() {
            _localValidationError = 'File size exceeds maximum limit of 10 MB.';
          });
          return;
        }

        setState(() {
          _selectedFileName = name;
          _selectedFileBytes = bytes;
          _selectedFileSize = size;
        });
      }
    } catch (e) {
      setState(() {
        _localValidationError = 'Error selecting file: ${e.toString()}';
      });
    }
  }

  Future<void> _submitUpload() async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      setState(() {
        _localValidationError = 'Please select a PDF or DOCX resume to upload.';
      });
      return;
    }

    final notifier = ref.read(resumeUploadProvider.notifier);
    final resume = await notifier.upload(
      bytes: _selectedFileBytes!,
      filename: _selectedFileName!,
    );

    if (resume != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume uploaded and processed successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(resumeUploadProvider);
    final uploadedResume = uploadState.uploadedResume;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Navigation Breadcrumb / Back
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/resumes'),
                      tooltip: 'Back to Resumes',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Upload Candidate Resume',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload your PDF or DOCX resume for automated text parsing, technical skills extraction, and job matching.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Error Banners
                if (_localValidationError != null || uploadState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _localValidationError ?? uploadState.errorMessage ?? '',
                            style: const TextStyle(color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Upload Card / Dropzone
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            size: 48,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFileName ?? 'Select PDF or Word Document',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedFileSize != null
                              ? '${(_selectedFileSize! / (1024 * 1024)).toStringAsFixed(2)} MB'
                              : 'Supports PDF & DOCX up to 10 MB',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 24),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: uploadState.isUploading ? null : _pickFile,
                              icon: const Icon(Icons.file_open_outlined, size: 18),
                              label: Text(_selectedFileName == null ? 'Browse File' : 'Change File'),
                            ),
                            ElevatedButton.icon(
                              onPressed: uploadState.isUploading || _selectedFileBytes == null
                                  ? null
                                  : _submitUpload,
                              icon: uploadState.isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined, size: 18),
                              label: Text(uploadState.isUploading ? 'Extracting Text...' : 'Upload & Parse Resume'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upload Results Card if completed
                if (uploadedResume != null) ...[
                  _buildResultsCard(uploadedResume),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/resumes'),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('View All Resumes & Match with Jobs'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ResumeModel resume) {
    final skills = resume.skills;
    final exp = resume.totalExperienceYears;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resume.isCompleted ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  color: resume.isCompleted ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 10),
                Text(
                  resume.isCompleted ? 'Extraction Completed' : 'Extraction Notice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
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
              ],
            ),
            const Divider(height: 24),
            Text(
              'Document: ${resume.filename} (${(resume.fileSize / 1024).toStringAsFixed(1)} KB)',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (exp != null) ...[
              const SizedBox(height: 8),
              Text(
                'Identified Experience Duration: $exp years',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Identified Technical Skills:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  return Chip(
                    label: Text(skill, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppTheme.surfaceElevated,
                    side: const BorderSide(color: Color(0xFF475569)),
                  );
                }).toList(),
              )
            else
              const Text(
                'No standard skills recognized in document text.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
