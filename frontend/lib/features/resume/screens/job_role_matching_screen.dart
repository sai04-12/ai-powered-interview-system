import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';
import '../../../shared/widgets/circular_score_gauge.dart';

class JobRoleMatchingScreen extends StatefulWidget {
  const JobRoleMatchingScreen({super.key});

  @override
  State<JobRoleMatchingScreen> createState() => _JobRoleMatchingScreenState();
}

class _JobRoleMatchingScreenState extends State<JobRoleMatchingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(
            currentRoute: '/profile-matching',
            role: SidebarRole.candidate,
          ),

          // Main Screen
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: 'Job Role Matching & Verification',
                  subtitle: 'Semantic comparison between candidate profile and target job description.',
                  showCandidateProfile: true,
                ),

                // Stepper Header
                _buildStepperHeader(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Two comparison cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildCandidateProfileCard()),
                                    const SizedBox(width: 20),
                                    Expanded(child: _buildJobDescriptionCard()),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildCandidateProfileCard(),
                                    const SizedBox(height: 20),
                                    _buildJobDescriptionCard(),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Skill Match Analysis Section
                          _buildSkillMatchAnalysisSection(context),
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

  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          _buildStepItem(stepNumber: 1, label: 'Profile Verification', isDone: true),
          _buildStepDivider(isDone: true),
          _buildStepItem(stepNumber: 2, label: 'Resume Analysis', isDone: true),
          _buildStepDivider(isDone: true),
          _buildStepItem(stepNumber: 3, label: 'Job Role Matching', isActive: true),
          _buildStepDivider(isDone: false),
          _buildStepItem(stepNumber: 4, label: 'Interview Setup', isPending: true),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String label,
    bool isDone = false,
    bool isActive = false,
    bool isPending = false,
  }) {
    Color circleColor;
    Widget child;

    if (isDone) {
      circleColor = const Color(0xFF10B981); // Emerald
      child = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = AppTheme.primary;
      child = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    } else {
      circleColor = const Color(0xFFE2E8F0);
      child = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: child,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? AppTheme.primary
                : (isDone ? AppTheme.textDark : AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isDone}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        height: 2,
        color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCandidateProfileCard() {
    final skills = ['Python', 'FastAPI', 'PostgreSQL', 'REST APIs', 'SQL', 'Machine Learning'];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Candidate Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Extracted from resume and verified details',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing verified resume: Lasya_Resume.pdf')),
                  );
                },
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('View Resume', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Candidate Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEFF6FF),
                child: const Text(
                  'L',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lasya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.business_center_outlined, size: 14, color: AppTheme.textMuted),
                      SizedBox(width: 4),
                      Text('2.5 Years Experience', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      SizedBox(width: 12),
                      Icon(Icons.school_outlined, size: 14, color: AppTheme.textMuted),
                      SizedBox(width: 4),
                      Text('B.Tech Computer Science', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Extracted Skills Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Extracted Skills',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit skills dialog opened.')),
                  );
                },
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) {
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
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Required skills and qualifications for the selected role',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing job description: Junior Python Developer')),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('View Details', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Role Title & Tags
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business_center, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Junior Python Developer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTag('0 - 3 Years', Icons.schedule),
                        _buildTag('Full Time', Icons.access_time),
                        _buildTag('Engineering', Icons.location_on_outlined),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key Requirements
          const Text(
            'Key Requirements',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),

          _buildRequirementBullet('Strong knowledge of Python programming'),
          _buildRequirementBullet('Experience with FastAPI or Django'),
          _buildRequirementBullet('Understanding of REST APIs and web development'),
          _buildRequirementBullet('Database knowledge (PostgreSQL / MySQL)'),
          _buildRequirementBullet('Good problem solving and communication skills'),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildRequirementBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillMatchAnalysisSection(BuildContext context) {
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
          // Section Title & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Skill Match Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Comparison of candidate skills with job requirements',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              // Legend
              Row(
                children: [
                  _buildLegendDot(const Color(0xFF10B981), 'Matched'),
                  const SizedBox(width: 14),
                  _buildLegendDot(const Color(0xFFF59E0B), 'Partial Match'),
                  const SizedBox(width: 14),
                  _buildLegendDot(const Color(0xFFEF4444), 'Missing'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Columns + Score Gauge Box
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 950;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skills match columns
                  Expanded(
                    flex: isWide ? 7 : 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Matched Skills (5)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Matched Skills (5)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSkillBadge('Python', Icons.check_circle, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                              _buildSkillBadge('FastAPI', Icons.check_circle, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                              _buildSkillBadge('PostgreSQL', Icons.check_circle, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                              _buildSkillBadge('REST APIs', Icons.check_circle, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                              _buildSkillBadge('SQL', Icons.check_circle, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Partial Match (1)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Partial Match (1)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSkillBadge(
                                'Machine Learning',
                                Icons.warning_amber_rounded,
                                const Color(0xFFF59E0B),
                                const Color(0xFFFFFBEB),
                                note: 'Basic knowledge, can be improved',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Missing Skills (2)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Missing Skills (2)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSkillBadge(
                                'Django',
                                Icons.remove_circle_outline,
                                const Color(0xFFEF4444),
                                const Color(0xFFFEF2F2),
                                note: 'Not found in resume',
                              ),
                              _buildSkillBadge(
                                'Docker',
                                Icons.remove_circle_outline,
                                const Color(0xFFEF4444),
                                const Color(0xFFFEF2F2),
                                note: 'Not found in resume',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right Box: Overall Match Score
                  Expanded(
                    flex: isWide ? 4 : 5,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Overall Match Score',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Based on semantic analysis using NLP & LLM',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),

                          // Gauge Meter 92%
                          const CircularScoreGauge(
                            score: 92,
                            size: 130,
                            label: 'Match Score',
                            progressColor: Color(0xFF10B981),
                          ),
                          const SizedBox(height: 16),

                          // Strong Role Alignment Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.emoji_events_outlined, color: Color(0xFF059669), size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Strong role alignment!\nCandidate\'s profile matches well with the job requirements.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF065F46),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Primary Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/live-interview'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Continue to Interview Setup',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSkillBadge(String name, IconData icon, Color color, Color bg, {String? note}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                note,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

