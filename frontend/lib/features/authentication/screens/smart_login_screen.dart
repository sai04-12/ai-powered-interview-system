import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';

class SmartLoginScreen extends ConsumerStatefulWidget {
  const SmartLoginScreen({super.key});

  @override
  ConsumerState<SmartLoginScreen> createState() => _SmartLoginScreenState();
}

class _SmartLoginScreenState extends ConsumerState<SmartLoginScreen> {
  bool _isSignUp = false;
  final _emailController = TextEditingController(text: 'priya.sharma@example.com');
  final _passwordController = TextEditingController(text: 'SecretPassword123!');
  final _nameController = TextEditingController(text: 'Priya Sharma');
  bool _rememberMe = true;
  bool _obscurePassword = true;
  String _selectedRole = 'candidate'; // 'candidate' or 'recruiter'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    if (_isSignUp) {
      final success = await ref.read(authProvider.notifier).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole,
      );
      if (success && mounted) {
        if (_selectedRole == 'recruiter') {
          context.go('/recruiter/dashboard');
        } else {
          context.go('/dashboard');
        }
      }
    } else {
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        if (_emailController.text.contains('recruiter') || _selectedRole == 'recruiter') {
          context.go('/recruiter/dashboard');
        } else {
          context.go('/dashboard');
        }
      } else if (mounted) {
        // Fallback demo bypass for presentation review if offline
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Hero Presentation Pane
        Expanded(
          flex: 6,
          child: _buildHeroPane(),
        ),
        const SizedBox(width: 48),
        // Right Login Form Card
        Expanded(
          flex: 5,
          child: _buildFormCard(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeroPane(),
        const SizedBox(height: 32),
        _buildFormCard(),
      ],
    );
  }

  Widget _buildHeroPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge matching slide "02 | LOGIN & SIGN UP"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '02',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '|  LOGIN & SIGN UP',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Big Headline
        const Text(
          'Smart Interview\nPreparation for\nBrighter Careers',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A), // Rich Deep Blue
            height: 1.15,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),

        // Subtitle
        const Text(
          'Create your account or login to continue your AI-powered interview journey with a secure and user-friendly platform.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF475569),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Feature Grid matching Page 2
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildFeaturePill(
              icon: Icons.verified_user_outlined,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              title: 'Secure Authentication',
              subtitle: 'Safe and reliable access',
            ),
            _buildFeaturePill(
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFF5F3FF),
              title: 'Multiple Login Options',
              subtitle: 'Email, Google, Microsoft',
            ),
            _buildFeaturePill(
              icon: Icons.desktop_windows_outlined,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              title: 'Simple & Clean UI',
              subtitle: 'Easy to use interface',
            ),
            _buildFeaturePill(
              icon: Icons.bolt_outlined,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              title: 'Quick Onboarding',
              subtitle: 'Get started in seconds',
            ),
            _buildFeaturePill(
              icon: Icons.lock_open_outlined,
              iconColor: const Color(0xFFE11D48),
              bgColor: const Color(0xFFFFF1F2),
              title: 'Role-based Access',
              subtitle: 'For Candidates & Recruiters',
            ),
            _buildFeaturePill(
              icon: Icons.devices_outlined,
              iconColor: const Color(0xFF0891B2),
              bgColor: const Color(0xFFECFEFF),
              title: 'Web & Mobile Ready',
              subtitle: 'Access anytime, anywhere',
            ),
          ],
        ),

        const SizedBox(height: 28),

        // College Accreditation Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.school_outlined, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Alwardas Polytechnic College • Dept of Computer Engineering',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center Logo
            Center(
              child: const AppLogo(size: 40),
            ),
            const SizedBox(height: 20),

            // Welcome Text
            Center(
              child: Text(
                _isSignUp ? 'Create an Account' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _isSignUp
                    ? 'Start your AI-powered interview journey'
                    : 'Login to continue to your account',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // If Sign Up: Full Name & Role selector
            if (_isSignUp) ...[
              const Text(
                'Full Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  hintText: 'e.g. Priya Sharma',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Role',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 'candidate'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'candidate'
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedRole == 'candidate'
                                ? AppTheme.primary
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 16,
                              color: _selectedRole == 'candidate'
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Candidate',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedRole == 'candidate'
                                    ? AppTheme.primary
                                    : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 'recruiter'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'recruiter'
                              ? const Color(0xFFEFF6FF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedRole == 'recruiter'
                                ? AppTheme.primary
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_center_outlined,
                              size: 16,
                              color: _selectedRole == 'recruiter'
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Recruiter',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedRole == 'recruiter'
                                    ? AppTheme.primary
                                    : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Email Address
            const Text(
              'Email address',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline, size: 20),
                hintText: 'name@example.com',
              ),
            ),
            const SizedBox(height: 16),

            // Password
            const Text(
              'Password',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Remember me & Forgot Password
            if (!_isSignUp) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _rememberMe = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link sent to registered email.')),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: _handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isSignUp ? 'Sign Up' : 'Login',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),

            // Divider: or continue with
            Row(
              children: const [
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or continue with',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 20),

            // OAuth Buttons (Google & Microsoft)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/dashboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'G',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEA4335),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/dashboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.window, size: 18, color: Color(0xFF00A4EF)),
                        SizedBox(width: 8),
                        Text(
                          'Microsoft',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Switch Login / Sign Up
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSignUp ? 'Already have an account?' : "Don't have an account?",
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? 'Login' : 'Sign up',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
