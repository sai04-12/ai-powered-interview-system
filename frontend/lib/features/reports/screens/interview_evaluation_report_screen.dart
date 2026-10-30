import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';
import '../../../shared/widgets/circular_score_gauge.dart';

class InterviewEvaluationReportScreen extends StatelessWidget {
  const InterviewEvaluationReportScreen({super.key});

  void _downloadReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Download PDF Report'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Report file: Priya_Sharma_Interview_Evaluation_Report.pdf'),
            SizedBox(height: 8),
            Text(
              'Includes candidate score (82%), AI integrity breakdown, answer transcriptions, and rubric assessment.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading: Priya_Sharma_Interview_Evaluation_Report.pdf'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Confirm Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(
            currentRoute: '/evaluation-report',
            role: SidebarRole.candidate,
          ),

          // Main Report Content
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: 'Interview Evaluation Report',
                  subtitle: 'Actionable performance assessment and AI integrity analysis.',
                  showCandidateProfile: true,
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Interview Summary Card & Overall Score Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 7, child: _buildInterviewSummaryCard()),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 5, child: _buildOverallScoreCard()),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildInterviewSummaryCard(),
                                    const SizedBox(height: 20),
                                    _buildOverallScoreCard(),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // 2. Detailed Assessment Progress Bars
                          _buildDetailedAssessmentCard(),
                          const SizedBox(height: 24),

                          // 3. AI Feedback Card & Download PDF
                          _buildFeedbackAndActionCard(context),
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

  Widget _buildInterviewSummaryCard() {
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
            'Interview Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 18),

          _buildSummaryRow(
            icon: Icons.person_outline,
            label: 'Candidate',
            value: 'Priya Sharma',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20),

          _buildSummaryRow(
            icon: Icons.work_outline,
            label: 'Position',
            value: 'Frontend Developer',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20),

          _buildSummaryRow(
            icon: Icons.calendar_today_outlined,
            label: 'Interview Date',
            value: '18 Mar 2025, 10:00 AM',
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 20),

          _buildSummaryRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: '32 minutes',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Overall Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),

          const CircularScoreGauge(
            score: 82,
            size: 135,
            label: 'Good',
            progressColor: Color(0xFF10B981),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Text(
                  'Recommended for Next Round',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAssessmentCard() {
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
            'Detailed Assessment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),

          _buildProgressBar('Technical Knowledge', 0.85, '85%'),
          const SizedBox(height: 14),
          _buildProgressBar('Problem Solving', 0.78, '78%'),
          const SizedBox(height: 14),
          _buildProgressBar('Communication', 0.80, '80%'),
          const SizedBox(height: 14),
          _buildProgressBar('Behavioral Response', 0.76, '76%'),
          const SizedBox(height: 14),
          _buildProgressBar('Integrity Score', 0.88, '88%'),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String title, double value, String percentageText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              percentageText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackAndActionCard(BuildContext context) {
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
          // AI Feedback Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Feedback paragraph matching PDF
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'The candidate demonstrates strong technical knowledge and good communication skills. '
              'Responses were consistent and confident. Recommended for next round.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Download Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _downloadReport(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text(
                  'Download PDF Report',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
