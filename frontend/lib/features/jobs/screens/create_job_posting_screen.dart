import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class CreateJobPostingScreen extends StatefulWidget {
  const CreateJobPostingScreen({super.key});

  @override
  State<CreateJobPostingScreen> createState() => _CreateJobPostingScreenState();
}

class _CreateJobPostingScreenState extends State<CreateJobPostingScreen> {
  final _titleController = TextEditingController(text: 'Frontend Developer');
  final _recruiterEmailController = TextEditingController(text: 'recruiter@company.com');
  final _descController = TextEditingController(
    text:
        'We are looking for a skilled Frontend Developer with experience in React.js, modern JavaScript and responsive design...',
  );
  String _department = 'Engineering';
  String _jobType = 'Full Time';
  String _experienceLevel = '3 - 5 Years';

  final List<String> _skills = ['React', 'JavaScript', 'HTML/CSS', 'Git'];

  @override
  void dispose() {
    _titleController.dispose();
    _recruiterEmailController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _publishJob() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job posting published! AI adaptive interview rubric configured.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        context.go('/recruiter/candidates');
      }
    });
  }

  void _addSkillDialog() {
    final skillCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Required Skill'),
        content: TextField(
          controller: skillCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Next.js, Redux, Docker'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (skillCtrl.text.trim().isNotEmpty) {
                setState(() => _skills.add(skillCtrl.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
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
          // Recruiter Sidebar
          const AppSidebar(
            currentRoute: '/jobs/create',
            role: SidebarRole.recruiter,
          ),

          // Main Screen
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: 'Job Posting Management',
                  subtitle: 'Create and configure role criteria for AI interview generation.',
                  showCandidateProfile: false,
                ),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create Job Posting',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Row 1: Job Title, Department, Job Type
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 700) {
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 5, child: _buildTextField('Job Title', _titleController)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 3,
                                        child: _buildDropdown(
                                          'Department',
                                          _department,
                                          ['Engineering', 'Design', 'Product', 'Data & AI'],
                                          (v) => setState(() => _department = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 3,
                                        child: _buildDropdown(
                                          'Job Type',
                                          _jobType,
                                          ['Full Time', 'Part Time', 'Contract', 'Internship'],
                                          (v) => setState(() => _jobType = v!),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildTextField('Job Title', _titleController),
                                      const SizedBox(height: 16),
                                      _buildDropdown(
                                        'Department',
                                        _department,
                                        ['Engineering', 'Design', 'Product', 'Data & AI'],
                                        (v) => setState(() => _department = v!),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDropdown(
                                        'Job Type',
                                        _jobType,
                                        ['Full Time', 'Part Time', 'Contract', 'Internship'],
                                        (v) => setState(() => _jobType = v!),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Row 2: Experience Level, Recruiter Email
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 700) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildDropdown(
                                          'Experience Level',
                                          _experienceLevel,
                                          ['0 - 1 Years', '1 - 3 Years', '3 - 5 Years', '5+ Years'],
                                          (v) => setState(() => _experienceLevel = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField('Recruiter Email', _recruiterEmailController),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    children: [
                                      _buildDropdown(
                                        'Experience Level',
                                        _experienceLevel,
                                        ['0 - 1 Years', '1 - 3 Years', '3 - 5 Years', '5+ Years'],
                                        (v) => setState(() => _experienceLevel = v!),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField('Recruiter Email', _recruiterEmailController),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Row 3: Job Description + Formatting Toolbar
                            const Text(
                              'Job Description',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 8),

                            // Mock Formatting Toolbar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE2E8F0)),
                                  left: BorderSide(color: Color(0xFFE2E8F0)),
                                  right: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildToolIcon(Icons.format_bold),
                                  _buildToolIcon(Icons.format_italic),
                                  _buildToolIcon(Icons.format_underlined),
                                  const SizedBox(width: 8),
                                  const VerticalDivider(width: 1, thickness: 1),
                                  const SizedBox(width: 8),
                                  _buildToolIcon(Icons.format_list_bulleted),
                                  _buildToolIcon(Icons.format_list_numbered),
                                  _buildToolIcon(Icons.link),
                                  _buildToolIcon(Icons.format_quote),
                                ],
                              ),
                            ),

                            // Description Input Area
                            TextField(
                              controller: _descController,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Row 4: Required Skills Chips
                            const Text(
                              'Required Skills',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ..._skills.map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          skill,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => setState(() => _skills.remove(skill)),
                                          child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                InkWell(
                                  onTap: _addSkillDialog,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.add, size: 14, color: Color(0xFF475569)),
                                        SizedBox(width: 4),
                                        Text('Add Skill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => context.go('/recruiter/dashboard'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textDark)),
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton(
                                  onPressed: _publishJob,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Publish Job', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 6),
        TextField(controller: controller),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
    );
  }
}
