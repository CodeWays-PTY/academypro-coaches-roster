import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_state.dart';
import '../../../core/storage/local_storage.dart';

class ProfileTabView extends ConsumerStatefulWidget {
  const ProfileTabView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends ConsumerState<ProfileTabView> {
  bool _pushNotifications = true;
  bool _emailAlerts = true;
  bool _biometricAuth = false;
  bool _offlineDataMode = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userProfile = authState.userProfile ?? LocalStorage.getUserProfile();

    final firstName = userProfile?['first_name'] ?? 'Jan-Albert';
    final lastName = userProfile?['last_name'] ?? 'Mentz';
    final email = userProfile?['email'] ?? authState.email ?? 'janmen777@gmail.com';
    final role = (userProfile?['role'] ?? 'Head Coach').toString().toUpperCase();
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 16.0,
          bottom: 32.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title
            const Text(
              'Coach Profile',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF131B2E),
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Manage your credentials, preferences, and account security.',
              style: TextStyle(
                fontSize: 14.0,
                color: Color(0xFF434656),
              ),
            ),
            const SizedBox(height: 20.0),

            // Profile Header Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Avatar Circle with Initials
                  Container(
                    width: 68.0,
                    height: 68.0,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003EC7), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF003EC7).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : 'AP',
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Color(0xFF505F76),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDE1FF),
                                borderRadius: BorderRadius.circular(999.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user_outlined, size: 12.0, color: Color(0xFF0038B6)),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    role,
                                    style: const TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0038B6),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Quick Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatTile(
                    label: 'ACADEMY TENANT',
                    value: 'Overkruin',
                    icon: Icons.account_balance,
                    iconColor: const Color(0xFF003EC7),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _buildQuickStatTile(
                    label: 'SECURITY STATUS',
                    value: 'Verified',
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28.0),

            // Section 1: Account Settings
            _buildSectionTitle('ACCOUNT & SECURITY'),
            const SizedBox(height: 10.0),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Personal Info',
                subtitle: 'Update name, contact & display options',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showInfoDialog(context, 'Personal Info', 'Your account profile is managed via uSPORT Master Roster.');
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Password & One-Time Codes',
                subtitle: 'Manage OTP login preferences',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showInfoDialog(context, 'Security', 'Passwordless OTP verification is active on $email.');
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildSwitchTile(
                icon: Icons.fingerprint,
                title: 'Biometric Unlock',
                subtitle: 'Require Fingerprint / Face ID to open app',
                value: _biometricAuth,
                onChanged: (val) {
                  setState(() => _biometricAuth = val);
                },
              ),
            ]),
            const SizedBox(height: 24.0),

            // Section 2: Notifications & Sync
            _buildSectionTitle('PREFERENCES & OFFLINE DATA'),
            const SizedBox(height: 10.0),
            _buildCardGroup([
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive match alerts and attendance nudges',
                value: _pushNotifications,
                onChanged: (val) {
                  setState(() => _pushNotifications = val);
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildSwitchTile(
                icon: Icons.mail_outline,
                title: 'Email Digest Reports',
                subtitle: 'Weekly summary of player evaluations',
                value: _emailAlerts,
                onChanged: (val) {
                  setState(() => _emailAlerts = val);
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildSwitchTile(
                icon: Icons.wifi_off_outlined,
                title: 'Offline Sync Mode',
                subtitle: 'Cache roster stats for field use without internet',
                value: _offlineDataMode,
                onChanged: (val) {
                  setState(() => _offlineDataMode = val);
                },
              ),
            ]),
            const SizedBox(height: 24.0),

            // Section 3: App Info & Help
            _buildSectionTitle('SYSTEM & SUPPORT'),
            const SizedBox(height: 10.0),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Knowledge Base',
                subtitle: 'User manuals, scoring guides & video tutorials',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showInfoDialog(context, 'Support', 'Contact CodeWays support at support@codeways.co.za');
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About AcademyPro',
                subtitle: 'Version 1.0.0+3 (Build 3) • Cloudflare D1',
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF737688),
                  ),
                ),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 32.0),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52.0,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, size: 20.0),
                label: const Text(
                  'Sign Out of AcademyPro',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA1A1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Center(
              child: Text(
                '© 2026 CodeWays PTY Ltd. All rights reserved.',
                style: TextStyle(
                  fontSize: 11.0,
                  color: Color(0xFF737688),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, size: 18.0, color: iconColor),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF737688),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFF737688),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Icon(icon, size: 20.0, color: const Color(0xFF505F76)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF131B2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12.0,
          color: Color(0xFF737688),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Icon(icon, size: 20.0, color: const Color(0xFF505F76)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF131B2E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12.0,
          color: Color(0xFF737688),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: const Color(0xFF003EC7),
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003EC7))),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your AcademyPro coach account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF737688))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
