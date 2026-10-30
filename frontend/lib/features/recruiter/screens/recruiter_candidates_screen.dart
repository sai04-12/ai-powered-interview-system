import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class CandidateItem {
  final String name;
  final String position;
  final int score;
  final String status;
  final String interviewDate;
  bool isSelected;

  CandidateItem({
    required this.name,
    required this.position,
    required this.score,
    required this.status,
    required this.interviewDate,
    this.isSelected = false,
  });
}

class RecruiterCandidatesScreen extends StatefulWidget {
  const RecruiterCandidatesScreen({super.key});

  @override
  State<RecruiterCandidatesScreen> createState() => _RecruiterCandidatesScreenState();
}

class _RecruiterCandidatesScreenState extends State<RecruiterCandidatesScreen> {
  String _searchQuery = '';
  String _selectedPosition = 'All Positions';
  String _selectedStatus = 'All Status';
  int _currentPage = 1;

  final List<CandidateItem> _candidates = [
    CandidateItem(
      name: 'Rahul Mehta',
      position: 'Frontend Developer',
      score: 85,
      status: 'Shortlisted',
      interviewDate: '18 Mar 2025',
    ),
    CandidateItem(
      name: 'Sneha Patel',
      position: 'Python Developer',
      score: 72,
      status: 'Completed',
      interviewDate: '16 Mar 2025',
    ),
    CandidateItem(
      name: 'Arjun Kumar',
      position: 'Data Analyst',
      score: 68,
      status: 'Completed',
      interviewDate: '15 Mar 2025',
    ),
    CandidateItem(
      name: 'Neha Singh',
      position: 'UI/UX Designer',
      score: 88,
      status: 'Shortlisted',
      interviewDate: '14 Mar 2025',
    ),
    CandidateItem(
      name: 'Vikram Joshi',
      position: 'DevOps Engineer',
      score: 75,
      status: 'Completed',
      interviewDate: '12 Mar 2025',
    ),
  ];

  void _showAddCandidateDialog() {
    final nameCtrl = TextEditingController();
    final posCtrl = TextEditingController(text: 'Frontend Developer');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Candidate for AI Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Candidate Full Name', hintText: 'e.g. Priya Sharma'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: posCtrl,
              decoration: const InputDecoration(labelText: 'Target Position', hintText: 'e.g. Python Developer'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _candidates.insert(
                    0,
                    CandidateItem(
                      name: nameCtrl.text.trim(),
                      position: posCtrl.text.trim(),
                      score: 82,
                      status: 'Shortlisted',
                      interviewDate: 'Today, 10:00 AM',
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Candidate ${nameCtrl.text} added & scheduled for interview.')),
                );
              }
            },
            child: const Text('Add Candidate'),
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
            currentRoute: '/recruiter/candidates',
            role: SidebarRole.recruiter,
          ),

          // Main Candidates List View
          Expanded(
            child: Column(
              children: [
                // Top Header
                AppTopbar(
                  title: 'Candidates',
                  subtitle: 'Manage and track all candidates for your job postings.',
                  showCandidateProfile: false,
                  trailing: ElevatedButton.icon(
                    onPressed: _showAddCandidateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Add Candidate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),

                // Table Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Search and Filter Bar
                            _buildFilterBar(),
                            const SizedBox(height: 20),

                            // Data Table
                            _buildDataTable(context),
                            const SizedBox(height: 20),

                            // Pagination Row
                            _buildPaginationRow(),
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

  Widget _buildFilterBar() {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 4,
          child: SizedBox(
            height: 42,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search candidates...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Filter button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 16),
          label: const Text('Filter', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 12),

        // Positions Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPosition,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
              items: ['All Positions', 'Frontend Developer', 'Python Developer', 'Data Analyst', 'UI/UX Designer']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedPosition = val ?? 'All Positions'),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Status Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
              items: ['All Status', 'Shortlisted', 'Completed', 'In Review']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val ?? 'All Status'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final filtered = _candidates.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery) ||
          c.position.toLowerCase().contains(_searchQuery);
      final matchesPosition = _selectedPosition == 'All Positions' || c.position == _selectedPosition;
      final matchesStatus = _selectedStatus == 'All Status' || c.status == _selectedStatus;
      return matchesSearch && matchesPosition && matchesStatus;
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(48), // Checkbox
          1: FlexColumnWidth(3),   // Name
          2: FlexColumnWidth(2.5), // Position
          3: FlexColumnWidth(1.5), // Score
          4: FlexColumnWidth(2),   // Status
          5: FlexColumnWidth(2),   // Interview Date
          6: FixedColumnWidth(60), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header Row
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            children: [
              _buildHeaderCell(''),
              _buildHeaderCell('Name'),
              _buildHeaderCell('Position'),
              _buildHeaderCell('Score'),
              _buildHeaderCell('Status'),
              _buildHeaderCell('Interview Date'),
              _buildHeaderCell('Actions'),
            ],
          ),

          // Candidate Rows
          ...filtered.map((candidate) {
            return TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              children: [
                TableCell(
                  child: Checkbox(
                    value: candidate.isSelected,
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => candidate.isSelected = val ?? false),
                  ),
                ),
                TableCell(
                  child: InkWell(
                    onTap: () => context.go('/evaluation-report'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              candidate.name.substring(0, 1),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            candidate.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Text(
                    candidate.position,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ),
                TableCell(
                  child: Text(
                    '${candidate.score}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: candidate.score >= 80
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                TableCell(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: candidate.status == 'Shortlisted'
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        candidate.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: candidate.status == 'Shortlisted'
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Text(
                    candidate.interviewDate,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
                TableCell(
                  child: IconButton(
                    icon: const Icon(Icons.more_horiz, size: 18, color: AppTheme.textMuted),
                    onPressed: () => context.go('/evaluation-report'),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildPaginationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Showing 1 to 5 of 25 candidates',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        Row(
          children: [
            _buildPageButton('1', isActive: _currentPage == 1, onTap: () => setState(() => _currentPage = 1)),
            _buildPageButton('2', isActive: _currentPage == 2, onTap: () => setState(() => _currentPage = 2)),
            _buildPageButton('3', isActive: _currentPage == 3, onTap: () => setState(() => _currentPage = 3)),
            _buildPageButton('4', isActive: _currentPage == 4, onTap: () => setState(() => _currentPage = 4)),
            _buildPageButton('5', isActive: _currentPage == 5, onTap: () => setState(() => _currentPage = 5)),
            _buildPageButton('>', isActive: false, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildPageButton(String text, {required bool isActive, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isActive ? AppTheme.primary : const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

