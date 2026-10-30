import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_logo.dart';

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildNavbar(context),

            // Hero Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  children: [
                    _buildHeroContent(context),
                    const SizedBox(height: 60),
                    // Bottom 4 Feature Cards Bar
                    _buildFeatureBar(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          InkWell(
            onTap: () => context.go('/dashboard'),
            child: const AppLogo(size: 36),
          ),

          // Nav Links
          Row(
            children: [
              _buildNavLink(context, 'Features', '/workflow'),
              const SizedBox(width: 24),
              _buildNavLink(context, 'For Recruiters', '/recruiter/dashboard'),
              const SizedBox(width: 24),
              _buildNavLink(context, 'How It Works', '/workflow'),
              const SizedBox(width: 24),
              _buildNavLink(context, 'Pricing', '/settings'),
            ],
          ),

          // Action Buttons
          Row(
            children: [
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String text, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 6, child: _buildHeroLeft(context)),
              const SizedBox(width: 40),
              Expanded(flex: 5, child: _buildHeroRight(context)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildHeroLeft(context),
              const SizedBox(height: 40),
              _buildHeroRight(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildHeroLeft(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
              SizedBox(width: 6),
              Text(
                'AI-POWERED RECRUITMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Headline
        const Text(
          'Smarter Interviews\nfor a Brighter Future',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.15,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 18),

        // Subtitle
        const Text(
          'AI-powered interview platform with profile verification, resume analysis, adaptive questioning and detailed integrity assessment.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/live-interview'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_circle_outline, size: 20, color: AppTheme.textDark),
              label: const Text(
                'Watch Demo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroRight(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background Gradient Blob
          Container(
            width: 320,
            height: 340,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
          ),

          // Central Profile Visual
          Container(
            width: 280,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    color: const Color(0xFFEFF6FF),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Color(0xFFFED7AA),
                          child: Text(
                            'L',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Lasya',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          'Candidate • Python & Frontend',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Right Floating Badge: "Resume Analysis 92% Match"
          Positioned(
            top: -15,
            right: -25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.description, size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text(
                    'Resume Analysis\n92% Match',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF065F46),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Left Floating Card: "AI Interview"
          Positioned(
            bottom: -20,
            left: -35,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'AI Interview',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  _HeroCheckItem('Profile Verified'),
                  _HeroCheckItem('Adaptive Questions'),
                  _HeroCheckItem('Integrity Analysis'),
                  _HeroCheckItem('Detailed Report'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureItem(Icons.verified_user_outlined, 'Identity Verification', 'Secure & Reliable', const Color(0xFF2563EB)),
                    _buildFeatureDivider(),
                    _buildFeatureItem(Icons.psychology_outlined, 'AI Questioning', 'Role-specific', const Color(0xFF7C3AED)),
                    _buildFeatureDivider(),
                    _buildFeatureItem(Icons.insights_outlined, 'Real-time Analysis', 'Behavior & Responses', const Color(0xFF059669)),
                    _buildFeatureDivider(),
                    _buildFeatureItem(Icons.assessment_outlined, 'Detailed Reports', 'Actionable Insights', const Color(0xFFD97706)),
                  ],
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildFeatureItem(Icons.verified_user_outlined, 'Identity Verification', 'Secure & Reliable', const Color(0xFF2563EB)),
                    _buildFeatureItem(Icons.psychology_outlined, 'AI Questioning', 'Role-specific', const Color(0xFF7C3AED)),
                    _buildFeatureItem(Icons.insights_outlined, 'Real-time Analysis', 'Behavior & Responses', const Color(0xFF059669)),
                    _buildFeatureItem(Icons.assessment_outlined, 'Detailed Reports', 'Actionable Insights', const Color(0xFFD97706)),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureDivider() {
    return Container(
      height: 32,
      width: 1,
      color: const Color(0xFFCBD5E1),
    );
  }
}

class _HeroCheckItem extends StatelessWidget {
  final String text;
  const _HeroCheckItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
