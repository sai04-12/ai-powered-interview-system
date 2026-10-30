import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';
import '../../../shared/widgets/circular_score_gauge.dart';

class ResumeUploadAnalysisScreen extends StatefulWidget {
  const ResumeUploadAnalysisScreen({super.key});

  @override
  State<ResumeUploadAnalysisScreen> createState() => _ResumeUploadAnalysisScreenState();
}

class _ResumeUploadAnalysisScreenState extends State<ResumeUploadAnalysisScreen> {
  bool _isAnalyzing = false;
  final String _fileName = 'resume_lasya.pdf';

  void _runAnalysis() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NLP Skill extraction and semantic matching complete! Match: 92%'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(
            currentRoute: '/resume-analysis',
            role: SidebarRole.candidate,
          ),

          // Main Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: 'Resume Upload & Analysis',
                  subtitle: 'Extract skills, experience, and verify profile credentials with NLP.',
                  showCandidateProfile: true,
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: _buildUploadCard()),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 6, child: _buildAnalysisResultCard(context)),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildUploadCard(),
                                    const SizedBox(height: 24),
                                    _buildAnalysisResultCard(context),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Your Resume',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Our AI will analyze your resume and match it with job requirements',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // Drag and Drop Container
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected new file: resume_lasya.pdf (2.4 MB)')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined, size: 36, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Drag & drop your resume here\nor click to browse',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Supports: PDF, DOC, DOCX (Max 5MB)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Uploaded File Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PDF',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 2),
                      const Text('2.4 MB', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Row(
                  children: const [
                    Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Uploaded',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _runAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Analyze Resume', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resume Analysis Result',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 20),

          // Center Circular Score Gauge
          Center(
            child: const CircularScoreGauge(
              score: 92,
              size: 130,
              label: 'Match Score',
              progressColor: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),

          // Extracted Information Header
          const Text(
            'Extracted Information',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),

          _buildInfoRow(Icons.business_center_outlined, '5+ Years Experience'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.code, '12 Technical Skills'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.school_outlined, 'B.Tech Computer Science'),
          const SizedBox(height: 20),

          // Extracted Skill Tags matching Screen 6
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SkillChip('Python'),
              _SkillChip('React'),
              _SkillChip('FastAPI'),
              _SkillChip('SQL'),
              _SkillChip('Machine Learning'),
            ],
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/live-interview'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue to Interview Session →', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
          ),
        ],
      ),
    );
  }
}
