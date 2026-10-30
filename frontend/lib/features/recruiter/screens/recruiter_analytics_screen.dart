import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class RecruiterAnalyticsScreen extends StatefulWidget {
  const RecruiterAnalyticsScreen({super.key});

  @override
  State<RecruiterAnalyticsScreen> createState() => _RecruiterAnalyticsScreenState();
}

class _RecruiterAnalyticsScreenState extends State<RecruiterAnalyticsScreen> {
  final String _dateRange = 'Mar 01, 2025 - Mar 31, 2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(
            currentRoute: '/recruiter/dashboard',
            role: SidebarRole.recruiter,
          ),

          // Main Analytics Screen
          Expanded(
            child: Column(
              children: [
                // Top Header
                AppTopbar(
                  title: 'Recruiter Dashboard',
                  subtitle: 'Track interviews, analyze candidate performance, and make better hiring decisions.',
                  showCandidateProfile: false,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          _dateRange,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. KPI Metric Cards Row
                          _buildKpiMetricsRow(),
                          const SizedBox(height: 24),

                          // 2. Charts Row (Interviews Overview & Position-wise Performance)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 950) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 6, child: _buildInterviewsOverviewChart()),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 5, child: _buildPositionWisePerformanceChart()),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildInterviewsOverviewChart(),
                                    const SizedBox(height: 20),
                                    _buildPositionWisePerformanceChart(),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // 3. Recent Interviews Table (Screen 4)
                          _buildRecentInterviewsTable(context),
                          const SizedBox(height: 24),

                          // 4. Quick Action Banner to Candidates List
                          _buildRecruiterActionBanner(context),
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

  Widget _buildKpiMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Total Candidates',
              value: '124',
              growthText: '+ 12%',
              icon: Icons.people_outline,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            ),
            _buildMetricCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Interviews Conducted',
              value: '48',
              growthText: '+ 18%',
              icon: Icons.assignment_turned_in_outlined,
              iconColor: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFF5F3FF),
            ),
            _buildMetricCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Shortlisted',
              value: '12',
              growthText: '+ 20%',
              icon: Icons.star_border_outlined,
              iconColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
            ),
            _buildMetricCard(
              width: constraints.maxWidth > 800 ? cardWidth : (constraints.maxWidth - 16) / 2,
              title: 'Hire Rate',
              value: '25%',
              growthText: '+ 5%',
              icon: Icons.trending_up,
              iconColor: const Color(0xFF0284C7),
              bgColor: const Color(0xFFE0F2FE),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String growthText,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 12, color: Color(0xFF10B981)),
                  Text(
                    growthText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewsOverviewChart() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Interviews Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot(const Color(0xFF2563EB), 'Completed'),
                  const SizedBox(width: 14),
                  _buildLegendDot(const Color(0xFF14B8A6), 'Shortlisted'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Bar Chart representation for 4 Weeks
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBarGroup('Week 1', 20, 8),
                _buildBarGroup('Week 2', 28, 12),
                _buildBarGroup('Week 3', 35, 15),
                _buildBarGroup('Week 4', 48, 22),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0)),
        ],
      ),
    );
  }

  Widget _buildBarGroup(String label, double completedHeight, double shortlistedHeight) {
    const maxHeight = 160.0;
    const maxVal = 50.0;

    final cHeight = (completedHeight / maxVal) * maxHeight;
    final sHeight = (shortlistedHeight / maxVal) * maxHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Completed Bar
            Container(
              width: 18,
              height: cHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(width: 4),
            // Shortlisted Bar
            Container(
              width: 18,
              height: sHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPositionWisePerformanceChart() {
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
            'Position-wise Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),

          _buildPositionBar('Frontend Developer', 0.85, '85%', const Color(0xFF2563EB)),
          const SizedBox(height: 14),
          _buildPositionBar('Python Developer', 0.72, '72%', const Color(0xFFE11D48)),
          const SizedBox(height: 14),
          _buildPositionBar('Data Analyst', 0.68, '68%', const Color(0xFFD97706)),
          const SizedBox(height: 14),
          _buildPositionBar('UI/UX Designer', 0.88, '88%', const Color(0xFF10B981)),
          const SizedBox(height: 14),
          _buildPositionBar('DevOps Engineer', 0.75, '75%', const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _buildPositionBar(String title, double value, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            Text(
              percentage,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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

  Widget _buildRecruiterActionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.people_alt_outlined, color: AppTheme.primary, size: 24),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to review candidate submissions?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '5 new candidates have completed AI adaptive interviews and are awaiting shortlisting.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => context.go('/recruiter/candidates'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Manage Candidates →'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInterviewsTable(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Interviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              TextButton(
                onPressed: () => context.go('/recruiter/candidates'),
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(2),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  children: [
                    Padding(padding: EdgeInsets.all(10), child: Text('Candidate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                _buildTableRow(context, 'Rahul Mehta', 'Frontend Developer', 'Today', '85%', 'Shortlisted', const Color(0xFF10B981)),
                _buildTableRow(context, 'Sneha Patel', 'Python Developer', 'Today', '72%', 'Completed', const Color(0xFF2563EB)),
                _buildTableRow(context, 'Arjun Kumar', 'Data Analyst', 'Yesterday', '68%', 'Completed', const Color(0xFF2563EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(BuildContext context, String name, String pos, String date, String score, String status, Color statusColor) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: InkWell(
            onTap: () => context.go('/evaluation-report'),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(name[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
                const SizedBox(width: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(pos, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(score, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ),
      ],
    );
  }
}
