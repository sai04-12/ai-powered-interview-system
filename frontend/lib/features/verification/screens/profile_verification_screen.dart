import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class ProfileVerificationScreen extends StatefulWidget {
  const ProfileVerificationScreen({super.key});

  @override
  State<ProfileVerificationScreen> createState() => _ProfileVerificationScreenState();
}

class _ProfileVerificationScreenState extends State<ProfileVerificationScreen> {
  bool _idUploaded = true;
  String _uploadedFileName = 'Government_ID_Lasya.pdf';
  bool _isVerifyingFace = false;
  bool _faceVerified = true;

  void _triggerFaceVerification() {
    setState(() => _isVerifyingFace = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isVerifyingFace = false;
          _faceVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity & Facial Liveness Verified Successfully via OpenCV!'),
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
            currentRoute: '/verification',
            role: SidebarRole.candidate,
          ),

          // Main Verification Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: 'Identity Verification',
                  subtitle: 'Upload a government ID and complete biometric face verification.',
                  showCandidateProfile: true,
                ),

                // Stepper Header
                _buildStepper(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identity Verification',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Upload a government ID and complete face verification',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 24),

                          // 2 Cards: Upload ID Document (Left) & Face Verification (Right)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 900) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildIdUploadCard()),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildFaceVerificationCard()),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildIdUploadCard(),
                                    const SizedBox(height: 24),
                                    _buildFaceVerificationCard(),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Next Step Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => context.go('/resume-analysis'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                ),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Proceed to Resume Analysis'),
                              ),
                            ],
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

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildStepItem(1, 'Personal Details', isDone: true),
          _buildStepDivider(true),
          _buildStepItem(2, 'Identity Verification', isActive: true),
          _buildStepDivider(false),
          _buildStepItem(3, 'Face Verification', isPending: true),
          _buildStepDivider(false),
          _buildStepItem(4, 'Complete', isPending: true),
        ],
      ),
    );
  }

  Widget _buildStepItem(int num, String label, {bool isDone = false, bool isActive = false, bool isPending = false}) {
    Color bg = isDone
        ? const Color(0xFF10B981)
        : (isActive ? AppTheme.primary : const Color(0xFFE2E8F0));
    Widget icon = isDone
        ? const Icon(Icons.check, size: 13, color: Colors.white)
        : Text(
            '$num',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: icon,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primary : (isDone ? AppTheme.textDark : AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isDone) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 2,
        color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildIdUploadCard() {
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
            'Upload ID Document',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),

          // Drag & Drop Box
          InkWell(
            onTap: () {
              setState(() {
                _idUploaded = true;
                _uploadedFileName = 'Government_ID_Lasya.pdf';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID Document attached: Government_ID_Lasya.pdf')),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF93C5FD), style: BorderStyle.solid, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Drag & drop your file here\nor click to browse',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Supports: PDF, JPG, PNG (Max 5MB)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_idUploaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _uploadedFileName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                    ),
                  ),
                  const Text(
                    'Uploaded (2.1 MB)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaceVerificationCard() {
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
            'Face Verification',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),

          // Face Viewport with OpenCV Green Detection Box
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Candidate visual avatar
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFFED7AA),
                  child: const Text(
                    'L',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF9A3412)),
                  ),
                ),

                // Green Bounding Box Overlay matching slide 5 screen
                Container(
                  width: 140,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Face 98%',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isVerifyingFace)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Start Verification Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _triggerFaceVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _faceVerified ? 'Re-Verify Biometrics' : 'Start Verification',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
