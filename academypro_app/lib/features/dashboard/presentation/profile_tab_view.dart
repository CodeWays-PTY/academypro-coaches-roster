import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/presentation/auth_state.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/services/notification_service.dart';

class ProfileTabView extends ConsumerStatefulWidget {
  const ProfileTabView({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends ConsumerState<ProfileTabView> {
  late bool _pushNotifications;
  bool _emailAlerts = true;
  bool _offlineDataMode = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load push notification setting from local storage
    final savedPush = LocalStorage.getCachedData('push_notifications_enabled');
    _pushNotifications = savedPush is bool ? savedPush : true;
  }

  Future<void> _handlePushToggle(bool enabled) async {
    setState(() => _pushNotifications = enabled);
    await LocalStorage.cacheData('push_notifications_enabled', enabled);

    final notifService = NotificationService();
    if (enabled) {
      final granted = await notifService.requestPermissions();
      if (granted) {
        final authState = ref.read(authProvider);
        final profile = authState.userProfile ?? LocalStorage.getUserProfile() ?? {};
        final tenant = profile['schoolName'] ?? profile['school_name'] ?? profile['tenant'] ?? 'Hoërskool Overkruin';
        
        // Trigger live push notification to prove it works
        await notifService.showNotification(
          id: 1001,
          title: 'Push Notifications Active',
          body: 'You will now receive live match day alerts and attendance nudges for $tenant.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20.0),
                  SizedBox(width: 10.0),
                  Text('Push notifications enabled & active'),
                ],
              ),
            ),
          );
        }
      }
    } else {
      await notifService.cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            content: const Row(
              children: [
                Icon(Icons.notifications_off_outlined, color: Color(0xFF94A3B8), size: 20.0),
                SizedBox(width: 10.0),
                Text('Push notifications disabled'),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        final imagePath = pickedFile.path;
        await ref.read(authProvider.notifier).updateUserProfile({
          'avatarUrl': imagePath,
          'profile_pic': imagePath,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              content: const Row(
                children: [
                  Icon(Icons.camera_alt_outlined, color: Color(0xFF10B981), size: 20.0),
                  SizedBox(width: 10.0),
                  Text('Profile picture updated successfully'),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 20.0,
            bottom: 24.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF131B2E),
                ),
              ),
              const SizedBox(height: 4.0),
              const Text(
                'Choose an option to update your display image',
                style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20.0),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select photo from local device gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text('Take a New Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Use camera to capture profile picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditPersonalInfoSheet(BuildContext context, Map<String, dynamic> currentProfile) {
    HapticFeedback.lightImpact();

    final firstNameController = TextEditingController(
      text: currentProfile['first_name'] ?? currentProfile['firstName'] ?? 'Jan-Albert',
    );
    final lastNameController = TextEditingController(
      text: currentProfile['last_name'] ?? currentProfile['lastName'] ?? 'Mentz',
    );
    final emailController = TextEditingController(
      text: currentProfile['email'] ?? 'janmen777@gmail.com',
    );
    final phoneController = TextEditingController(
      text: currentProfile['phone'] ?? '+27 82 123 4567',
    );
    final tenantController = TextEditingController(
      text: currentProfile['schoolName'] ?? currentProfile['school_name'] ?? currentProfile['tenant'] ?? 'Hoërskool Overkruin',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Personal Info',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Update your profile details across AcademyPro & uSPORT network',
                  style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24.0),

                // First Name Input
                _buildInputField(
                  controller: firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16.0),

                // Last Name Input
                _buildInputField(
                  controller: lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16.0),

                // Email Input
                _buildInputField(
                  controller: emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),

                // Phone Input
                _buildInputField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16.0),

                // School Tenant Input (Dynamic School)
                _buildInputField(
                  controller: tenantController,
                  label: 'Academy Tenant / School',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 28.0),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52.0,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final updated = {
                        'first_name': firstNameController.text.trim(),
                        'firstName': firstNameController.text.trim(),
                        'last_name': lastNameController.text.trim(),
                        'lastName': lastNameController.text.trim(),
                        'email': emailController.text.trim().toLowerCase(),
                        'phone': phoneController.text.trim(),
                        'schoolName': tenantController.text.trim(),
                        'school_name': tenantController.text.trim(),
                        'tenant': tenantController.text.trim(),
                      };

                      await ref.read(authProvider.notifier).updateUserProfile(updated);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20.0),
                                SizedBox(width: 10.0),
                                Text('Personal info updated successfully'),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003EC7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6.0),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15.0),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20.0),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userProfile = authState.userProfile ?? LocalStorage.getUserProfile() ?? {};

    final firstName = userProfile['first_name'] ?? userProfile['firstName'] ?? 'Jan-Albert';
    final lastName = userProfile['last_name'] ?? userProfile['lastName'] ?? 'Mentz';
    final email = userProfile['email'] ?? authState.email ?? 'janmen777@gmail.com';
    final role = (userProfile['role'] ?? 'Head Coach').toString().toUpperCase();
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

    // Dynamic School / Tenant Name
    final rawSchool = userProfile['schoolName'] ?? userProfile['school_name'] ?? userProfile['tenant'] ?? 'Hoërskool Overkruin';
    final dynamicTenant = rawSchool.toString().replaceAll('Hoërskool ', '');

    // Avatar image check
    final avatarPath = userProfile['avatarUrl'] ?? userProfile['profile_pic'];

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
              'Manage your credentials, preferences, and account info.',
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
                  // Avatar Circle with Camera Upload Hook
                  GestureDetector(
                    onTap: () => _showImagePickerOptions(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 72.0,
                          height: 72.0,
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
                          child: avatarPath != null && avatarPath.toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(36.0),
                                  child: avatarPath.toString().startsWith('http')
                                      ? Image.network(
                                          avatarPath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              initials.isNotEmpty ? initials : 'AP',
                                              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        )
                                      : Image.file(
                                          File(avatarPath),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              initials.isNotEmpty ? initials : 'AP',
                                              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                )
                              : Center(
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
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

            // Dynamic Quick Info Grid
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatTile(
                    label: 'ACADEMY TENANT',
                    value: dynamicTenant,
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

            // Section 1: Account Settings (Personal Info opens tab/sheet)
            _buildSectionTitle('ACCOUNT & SECURITY'),
            const SizedBox(height: 10.0),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Personal Info',
                subtitle: 'Edit name, contact details & academy tenant',
                onTap: () => _openEditPersonalInfoSheet(context, userProfile),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildSettingTile(
                icon: Icons.camera_alt_outlined,
                title: 'Profile Picture',
                subtitle: 'Upload or update your avatar photo',
                onTap: () => _showImagePickerOptions(context),
              ),
            ]),
            const SizedBox(height: 24.0),

            // Section 2: Real Push Notifications & Sync
            _buildSectionTitle('PREFERENCES & NOTIFICATIONS'),
            const SizedBox(height: 10.0),
            _buildCardGroup([
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive match alerts and attendance nudges',
                value: _pushNotifications,
                onChanged: (val) => _handlePushToggle(val),
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
                subtitle: 'Version 1.0.0+4 (Build 4) • Cloudflare D1',
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
                  overflow: TextOverflow.ellipsis,
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
