import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class SystemWorkflowScreen extends StatelessWidget {
  const SystemWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(
            currentRoute: '/workflow',
            role: SidebarRole.candidate,
          ),

          // Main Workflow Content
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: '11. System Workflow & Architecture',
                  subtitle: 'End-to-end process from candidate registration to final recruiter shortlisting.',
                  showCandidateProfile: true,
                ),

                // Top Quote Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  color: const Color(0xFFEFF6FF),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '"Innovative Technology for a Smarter Future"',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'Alwardas Polytechnic College • Dept of Computer Engineering (2025 - 2026)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),

                // Scrollable Workflow Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 10-step visual pipeline cards
                          _buildWorkflowStepsGrid(context),
                          const SizedBox(height: 32),

                          // Tech Stack & Presentation Team Credit Banner (Pages 6 & 7)
                          _buildProjectCreditsCard(context),
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

  Widget _buildWorkflowStepsGrid(BuildContext context) {
    final steps = [
      _WorkflowStepData(
        number: '01',
        title: 'Registration & Profile Creation',
        desc: 'Candidate registers and creates an encrypted profile with role-based access.',
        icon: Icons.person_add_alt_1_outlined,
        color: const Color(0xFF2563EB),
        route: '/login',
        tech: 'FastAPI + Argon2id JWT',
      ),
      _WorkflowStepData(
        number: '02',
        title: 'Identity Verification',
        desc: 'Face recognition, ID verification, and real-time liveness check.',
        icon: Icons.face_retouching_natural,
        color: const Color(0xFF7C3AED),
        route: '/profile-matching',
        tech: 'OpenCV + DeepFace',
      ),
      _WorkflowStepData(
        number: '03',
        title: 'Resume Upload & Analysis',
        desc: 'Extract candidate skills, experience, and education from PDF/DOCX.',
        icon: Icons.upload_file_outlined,
        color: const Color(0xFF0284C7),
        route: '/profile-matching',
        tech: 'NLP + spaCy + S3 Storage',
      ),
      _WorkflowStepData(
        number: '04',
        title: 'Job Role Matching',
        desc: 'Compare candidate skills with job requirements using semantic analysis.',
        icon: Icons.sync_alt,
        color: const Color(0xFF0D9488),
        route: '/profile-matching',
        tech: 'Semantic Vector Match (92%)',
      ),
      _WorkflowStepData(
        number: '05',
        title: 'AI Question Generation',
        desc: 'Generates role-specific adaptive questions (Technical, Behavioral, HR).',
        icon: Icons.psychology_outlined,
        color: const Color(0xFF2563EB),
        route: '/live-interview',
        tech: 'LLM (OpenAI / Gemini)',
      ),
      _WorkflowStepData(
        number: '06',
        title: 'Interview Session (Video + Chat)',
        desc: 'Conduct interview with real-time video, speech detection, and adaptive Q&A.',
        icon: Icons.videocam_outlined,
        color: const Color(0xFFE11D48),
        route: '/live-interview',
        tech: 'Flutter Web/Mobile + WebRTC',
      ),
      _WorkflowStepData(
        number: '07',
        title: 'Response Analysis & Integrity Check',
        desc: 'Analyze responses, facial expressions, eye gaze, and session integrity.',
        icon: Icons.visibility_outlined,
        color: const Color(0xFF059669),
        route: '/live-interview',
        tech: 'OpenCV Gaze + Speech NLP',
      ),
      _WorkflowStepData(
        number: '08',
        title: 'Evaluation & Scoring',
        desc: 'Multi-parameter scoring: Technical, Communication, Problem Solving, Integrity.',
        icon: Icons.fact_check_outlined,
        color: const Color(0xFF7C3AED),
        route: '/evaluation-report',
        tech: 'Rubric Engine + LLM Evaluation',
      ),
      _WorkflowStepData(
        number: '09',
        title: 'Report Generation',
        desc: 'Generate comprehensive PDF report with scores, feedback, and recommendation.',
        icon: Icons.picture_as_pdf_outlined,
        color: const Color(0xFFD97706),
        route: '/evaluation-report',
        tech: 'ReportLab PDF Generator',
      ),
      _WorkflowStepData(
        number: '10',
        title: 'Recruiter Review & Shortlisting',
        desc: 'Recruiters review candidate performance analytics and make hiring decisions.',
        icon: Icons.how_to_reg_outlined,
        color: const Color(0xFF2563EB),
        route: '/recruiter/candidates',
        tech: 'Recruiter Dashboard & Analytics',
      ),
    ];

    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: steps.map((step) => _buildStepCard(context, step)).toList(),
    );
  }

  Widget _buildStepCard(BuildContext context, _WorkflowStepData step) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Number & Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: step.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step.number,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: step.color,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: step.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon, size: 20, color: step.color),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                step.desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Tech Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  step.tech,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Test Step Button
              InkWell(
                onTap: () => context.go(step.route),
                child: Row(
                  children: [
                    Text(
                      'Open Screen',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: step.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 12, color: step.color),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectCreditsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.school, color: AppTheme.primary, size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-POWERED Intelligent Interview System',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    'Department of Computer Engineering • Alwardas Polytechnic College, Visakhapatnam',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Team Member Details from Page 7
          const Text(
            'Designed & Developed By Team Members:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: const [
              _StudentBadge(name: 'L. LASYA', rollNo: '24634-CM-055'),
              _StudentBadge(name: 'G. GAYATRI', rollNo: '24634-CM-022'),
              _StudentBadge(name: 'D. CHARISHMA', rollNo: '24634-CM-014'),
              _StudentBadge(name: 'CH. MOHITHA SRI', rollNo: '24634-CM-013'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepData {
  final String number;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final String route;
  final String tech;

  _WorkflowStepData({
    required this.number,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.route,
    required this.tech,
  });
}

class _StudentBadge extends StatelessWidget {
  final String name;
  final String rollNo;

  const _StudentBadge({required this.name, required this.rollNo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 2),
          Text(rollNo, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

