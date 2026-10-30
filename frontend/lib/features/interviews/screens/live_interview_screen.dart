import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/ai_robot_avatar.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/audio_waveform.dart';

class LiveInterviewScreen extends StatefulWidget {
  const LiveInterviewScreen({super.key});

  @override
  State<LiveInterviewScreen> createState() => _LiveInterviewScreenState();
}

class _LiveInterviewScreenState extends State<LiveInterviewScreen> {
  int _secondsLeft = 1470; // 24:30
  Timer? _timer;
  final int _currentQuestionIndex = 3;
  final int _totalQuestions = 8;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  final bool _isListening = true;
  final TextEditingController _answerController = TextEditingController(
    text:
        'SQL databases are relational and structured with fixed schemas (ACID compliant), ideal for complex queries and transaction integrity like banking systems. NoSQL databases are non-relational, document or key-value stores with flexible schemas, built for horizontal scalability, high write throughput, and unstructured data.',
  );

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
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
    _answerController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _submitAnswer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer recorded! Analyzing facial gaze, response consistency, and semantic clarity...'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.go('/evaluation-report');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark studio mode for video stream
      body: Row(
        children: [
          // Sidebar
          const AppSidebar(
            currentRoute: '/live-interview',
            role: SidebarRole.candidate,
          ),

          // Main Live Stage
          Expanded(
            child: Column(
              children: [
                // Top Live Header Bar
                _buildLiveHeader(context),

                // Main Stage (Split: Candidate Camera on Left, AI Question Box on Right)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 950) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 6, child: _buildVideoViewport()),
                              const SizedBox(width: 20),
                              Expanded(flex: 5, child: _buildQuestionPanel()),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: 380, child: _buildVideoViewport()),
                                const SizedBox(height: 20),
                                _buildQuestionPanel(),
                              ],
                            ),
                          );
                        }
                      },
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

  Widget _buildLiveHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Session indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Live Session: Frontend & Python Developer',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              const Text(
                'AI Integrity Monitor Active',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Right: Timer & End Interview Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Time Left: ${_formatTime(_secondsLeft)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: () => context.go('/evaluation-report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.call_end, size: 16),
                label: const Text('End Interview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViewport() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      child: Stack(
        children: [
          // Simulated Webcam stream with candidate frame
          Center(
            child: _isCameraOff
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.videocam_off, size: 48, color: Colors.white38),
                      SizedBox(height: 8),
                      Text('Camera is turned off', style: TextStyle(color: Colors.white60)),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1E293B),
                          const Color(0xFF0F172A),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF38BDF8), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFFFED7AA),
                              child: Text(
                                'L',
                                style: TextStyle(
                                  color: Color(0xFF9A3412),
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Lasya (Candidate)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // REC Indicator (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right: Live Telemetry Integrity Indicators
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('OpenCV Integrity Check', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• Face: Detected ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                  Text('• Gaze: Focused ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                  Text('• Multiple Faces: None ✓', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                ],
              ),
            ),
          ),

          // Bottom Floating Media Controls Bar
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF475569)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 16),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMediaButton(
                      icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                      isActive: !_isMicMuted,
                      onTap: () => setState(() => _isMicMuted = !_isMicMuted),
                    ),
                    const SizedBox(width: 12),
                    _buildMediaButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      isActive: !_isCameraOff,
                      onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                    ),
                    const SizedBox(width: 12),
                    _buildMediaButton(
                      icon: Icons.subtitles_outlined,
                      isActive: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _buildMediaButton(
                      icon: Icons.settings_outlined,
                      isActive: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    // Red Hangup Button
                    InkWell(
                      onTap: () => context.go('/evaluation-report'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // AI Interviewer Avatar Floating Box (Bottom Left of Video)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1),
              ),
              child: Row(
                children: [
                  const AiRobotAvatar(size: 36),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'AI Interviewer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Asking role-specific adaptive questions',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF334155) : const Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildQuestionPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $_currentQuestionIndex of $_totalQuestions',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Technical Question',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Question Prompt exactly matching PDF
          const Text(
            'Explain the difference between SQL and NoSQL databases. When would you choose one over the other?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Sub-helper text
          const Text(
            'Take your time to think and answer clearly.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Audio Waveform Visualizer ("Listening...")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AudioWaveformVisualizer(
                  isListening: _isListening,
                  barColor: AppTheme.primary,
                  height: 32,
                ),
                const SizedBox(width: 14),
                const Text(
                  'Listening...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Response Text area
          const Text(
            'Candidate Answer Transcription:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: TextField(
              controller: _answerController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: 'Speak into your microphone or refine your answer here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Next / Submit Button
          ElevatedButton(
            onPressed: _submitAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Submit Answer & Next Question',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
