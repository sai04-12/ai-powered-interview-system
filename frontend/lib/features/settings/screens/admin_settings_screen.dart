import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/app_topbar.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  String _selectedSection = 'Account';
  final _companyController = TextEditingController(text: 'Your Company');
  final _emailController = TextEditingController(text: 'recruiter@company.com');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _websiteController = TextEditingController(text: 'https://company.com');

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account profile settings saved successfully!'),
        backgroundColor: Color(0xFF10B981),
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
            currentRoute: '/settings',
            role: SidebarRole.recruiter,
          ),

          // Main Screen
          Expanded(
            child: Column(
              children: [
                // Top Header
                const AppTopbar(
                  title: 'Settings & Administration',
                  subtitle: 'Configure company profile, AI parameters, and interview evaluation rubrics.',
                  showCandidateProfile: false,
                ),

                // Settings Body (Left Submenu + Right Form Card)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 850) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Submenu
                                  SizedBox(
                                    width: 220,
                                    child: _buildSubmenu(),
                                  ),
                                  const SizedBox(width: 32),
                                  // Right Form Area
                                  Expanded(
                                    child: _buildSettingsContent(),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildSubmenu(),
                                  const SizedBox(height: 24),
                                  _buildSettingsContent(),
                                ],
                              );
                            }
                          },
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

  Widget _buildSubmenu() {
    final items = [
      {'title': 'Account', 'icon': Icons.person_outline},
      {'title': 'Company', 'icon': Icons.business_outlined},
      {'title': 'Team', 'icon': Icons.group_outlined},
      {'title': 'Interview Settings', 'icon': Icons.tune_outlined},
      {'title': 'AI Parameters', 'icon': Icons.psychology_outlined},
      {'title': 'Integrations', 'icon': Icons.extension_outlined},
      {'title': 'Security', 'icon': Icons.security_outlined},
      {'title': 'Billing', 'icon': Icons.credit_card_outlined},
    ];

    return Column(
      children: items.map((item) {
        final title = item['title'] as String;
        final icon = item['icon'] as IconData;
        final isSelected = _selectedSection == title;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            onTap: () => setState(() => _selectedSection = title),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
        const SizedBox(height: 20),

        const Text(
          'Profile Information',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
        const SizedBox(height: 16),

        // Avatar + Upload Logo Row
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFEFF6FF),
              child: const Text(
                'U',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 18),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select image dialog opened.')),
                );
              },
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Upload Logo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Company Name
        _buildInputField('Company Name', _companyController),
        const SizedBox(height: 16),

        // Email
        _buildInputField('Email', _emailController),
        const SizedBox(height: 16),

        // Contact Number
        _buildInputField('Contact Number', _phoneController),
        const SizedBox(height: 16),

        // Website
        _buildInputField('Website', _websiteController),
        const SizedBox(height: 28),

        // Save Changes Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 6),
        TextField(controller: controller),
      ],
    );
  }
}
