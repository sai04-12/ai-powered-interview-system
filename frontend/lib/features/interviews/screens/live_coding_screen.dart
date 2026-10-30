import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';

class LiveCodingScreen extends StatefulWidget {
  const LiveCodingScreen({super.key});

  @override
  State<LiveCodingScreen> createState() => _LiveCodingScreenState();
}

class _LiveCodingScreenState extends State<LiveCodingScreen> {
  int _secondsLeft = 1125; // 18:45
  Timer? _timer;
  String _activeTab = 'Code Editor'; // 'Code Editor', 'Whiteboard', 'Text Response'
  String _selectedLanguage = 'Python';
  String _consoleOutput = 'Output: 120 (Execution: 0.04s - Tests Passed: 3/3 ✓)';
  bool _isRunning = false;

  final TextEditingController _codeController = TextEditingController(
    text: '''# Write a function to find the factorial of a number
def factorial(n):
    if n <= 0:
        return 1
    return n * factorial(n - 1)

# Test the function
print(factorial(5))''',
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _runCode() {
    setState(() => _isRunning = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _consoleOutput = 'Output: 120\nExecution Time: 0.038s\nStatus: All 3 Automated Unit Tests Passed ✓';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code compiled & executed successfully! Test cases passed.'),
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
            currentRoute: '/live-coding',
            role: SidebarRole.candidate,
          ),

          // Main Stage
          Expanded(
            child: Column(
              children: [
                // Top Coding Header Bar
                _buildHeader(context),

                // Editor Content Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Bar
                          _buildTabs(),

                          // Editor Window
                          Expanded(
                            child: _activeTab == 'Code Editor'
                                ? _buildCodeEditorWindow()
                                : _buildAlternativeView(),
                          ),

                          // Output Console Bar
                          _buildConsoleBar(),

                          // Bottom Controls (Run Code, Reset, Language)
                          _buildBottomControlBar(context),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Python Developer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Technical Assessment • Factorial Algorithm',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textDark),
                    const SizedBox(width: 6),
                    Text(
                      'Time Left: ${_formatTime(_secondsLeft)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.go('/evaluation-report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('End Session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildTabButton('Code Editor', Icons.code),
          const SizedBox(width: 12),
          _buildTabButton('Whiteboard', Icons.brush_outlined),
          const SizedBox(width: 12),
          _buildTabButton('Text Response', Icons.notes_outlined),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon) {
    final isActive = _activeTab == label;
    return InkWell(
      onTap: () => setState(() => _activeTab = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
          border: isActive ? Border.all(color: const Color(0xFFE2E8F0)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeEditorWindow() {
    return Container(
      color: const Color(0xFF0F172A), // Dark IDE Code Editor
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line Numbers
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(10, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          // Code Area
          Expanded(
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: Color(0xFFE2E8F0),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _activeTab == 'Whiteboard' ? Icons.brush : Icons.description,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            '$_activeTab Canvas Ready',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          const Icon(Icons.terminal, size: 16, color: Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _consoleOutput,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow, size: 18),
                label: const Text('Run Code', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _codeController.text = '''# Write a function to find the factorial of a number
def factorial(n):
    if n <= 0:
        return 1
    return n * factorial(n - 1)

# Test the function
print(factorial(5))''';
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Reset', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          // Language Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                items: ['Python', 'JavaScript', 'TypeScript', 'Java', 'C++']
                    .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLanguage = val ?? 'Python'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
