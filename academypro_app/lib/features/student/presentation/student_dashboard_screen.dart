import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/student_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../auth/presentation/login_screen.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/presentation/notifications_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studentControllerProvider.notifier).fetchStudentData();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  void _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentDataState = ref.watch(studentControllerProvider);
    final userProfile = ref.watch(authProvider).userProfile;
    final notifState = ref.watch(notificationProvider);
    final studentName = userProfile != null
        ? '${userProfile['firstName']} ${userProfile['lastName']}'
        : 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF), // light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
        titleSpacing: 16.0,
        title: Row(
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Image.network(
                  'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=150',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0] : 'S',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            const Text(
              'AcademyPro',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF64748B)),
                onPressed: () {
                  NotificationsPanel.show(context);
                },
              ),
              if (notifState.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${notifState.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(studentControllerProvider.notifier).fetchStudentData();
        },
        child: studentDataState.when(
          data: (data) => _buildContent(data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48.0, color: Color(0xFFBA1A1A)),
                  const SizedBox(height: 12.0),
                  Text(
                    'Error loading dashboard: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => ref.read(studentControllerProvider.notifier).fetchStudentData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(StudentPortalData data) {
    if (_activeTab == 1) {
      return _buildFitnessTab(data);
    } else if (_activeTab == 2) {
      return _buildAcademicsTab(data);
    } else if (_activeTab == 3) {
      return _buildMatchesTab(data);
    }
    return _buildOverviewTab(data);
  }

  // ==========================================
  // TAB 1: OVERVIEW (Student Journey)
  // ==========================================
  Widget _buildOverviewTab(StudentPortalData data) {
    final profile = data.profile;
    final studentName = '${profile['firstName'] ?? 'Athlete'} ${profile['lastName'] ?? ''}'.trim();
    final team = profile['team'] ?? 'First Team';
    final ageGroup = profile['ageGroup'] ?? 'U15';
    final position = profile['position'] ?? 'Player';

    // Compute Power Index
    int powerIndex = 0;
    final baseline = data.fitness['baseline'];
    if (baseline != null) {
      final pushUps = baseline['pushUps'] as num? ?? 0;
      final squats = baseline['squats40kg'] as num? ?? 0;
      final pullUps = baseline['pullUps'] as num? ?? 0;
      powerIndex = (pushUps * 5 + squats * 10 + pullUps * 15).toInt();
    }

    // Compute Latest Grade
    final latestGrade = _getLatestGrade(data.academics);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Status Card
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFFC3C5D9).withOpacity(0.3), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF05B046).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: const Text(
                        'ZONE ACTIVE',
                        style: TextStyle(
                          color: Color(0xFF003A11),
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      '98TH PERCENTILE',
                      style: TextStyle(
                        color: Color(0xFF434656),
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Green Zone',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '$studentName is currently tracking at University Ready in the $ageGroup $team squad as a $position. Maintain this velocity to unlock Elite status.',
                  style: TextStyle(
                    fontSize: 15.0,
                    color: const Color(0xFF434656).withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT RANK',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF434656),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          latestGrade >= 65 ? 'A+' : (latestGrade >= 60 ? 'A' : 'B'),
                          style: const TextStyle(
                            fontSize: 36.0,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF05B046),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32.0),
                    Container(
                      width: 1.5,
                      height: 40.0,
                      color: const Color(0xFFC3C5D9).withOpacity(0.5),
                    ),
                    const SizedBox(width: 32.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECRUIT READINESS',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF434656),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          latestGrade >= 60 ? '94%' : '88%',
                          style: const TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 28.0),

          // Mind, Body, Spirit Portals Grid
          const Text(
            'Development Portals',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 16.0),
          _buildPortalCard(
            'Mind',
            'Academic performance and cognitive load metrics.',
            'GPA: $latestGrade%',
            Icons.psychology,
            const Color(0xFF003EC7),
            () => setState(() => _activeTab = 2), // Go to Academics Tab
          ),
          const SizedBox(height: 12.0),
          _buildPortalCard(
            'Body',
            'Athletic progression and performance index.',
            'Power Index: $powerIndex',
            Icons.sports_martial_arts,
            const Color(0xFF05B046),
            () => setState(() => _activeTab = 1), // Go to Fitness Tab
          ),
          const SizedBox(height: 12.0),
          _buildPortalCard(
            'Spirit',
            'Weekly uGroup attendance and character building.',
            profile['ugroupsActive'] == 1 ? 'Active' : 'Inactive',
            Icons.church_outlined,
            const Color(0xFF952200),
            () {},
          ),
          const SizedBox(height: 28.0),

          // Assigned Coach Action Plans / To-Do
          _buildCoachActionPlansForStudent(studentName),

          // Peace of Mind Coach Feed
          const Text(
            'Latest Feedback',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 12.0),
          _buildCoachFeedbackCard(data),
        ],
      ),
    );
  }

  Widget _buildCoachActionPlansForStudent(String studentName) {
    final actions = ref.watch(coachActionProvider);
    final studentFirstName = studentName.split(' ')[0].toLowerCase();
    final studentActions = actions.where((a) =>
        a.playerName.toLowerCase().contains(studentFirstName) ||
        (a.playerName.isNotEmpty && studentName.toLowerCase().contains(a.playerName.toLowerCase()))).toList();

    if (studentActions.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF2563EB), size: 22.0),
                SizedBox(width: 8.0),
                Text(
                  'My Action Plans (From Coach)',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131B2E),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '${studentActions.where((a) => !a.isCompleted).length} PENDING',
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        ...studentActions.map((item) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showActionItemDetailsModal(context, item);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: item.isCompleted
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: item.isCompleted ? Colors.white : null,
                borderRadius: BorderRadius.circular(18.0),
                border: item.isCompleted ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                boxShadow: [
                  BoxShadow(
                    color: item.isCompleted ? const Color(0x08000000) : const Color(0x202563EB),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      ref.read(coachActionProvider.notifier).toggleAction(item.id);
                    },
                    child: Icon(
                      item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: item.isCompleted ? const Color(0xFF10B981) : Colors.white,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: item.isCompleted ? const Color(0xFF64748B) : Colors.white,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Assigned to ${item.playerName} • ${item.category}',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFFBFDBFE),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20.0),
      ],
    );
  }

  void _showActionItemDetailsModal(BuildContext context, CoachActionItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: 24.0 + bottomPadding,
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
                    color: const Color(0xFFC3C5D9).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                item.title,
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Assigned Player: ${item.playerName} • Added ${item.dateAdded}',
                style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20.0),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16.0),

              // Parent & Guardian Contact Section
              const Text(
                'PARENT / GUARDIAN CONTACT',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
              ),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF2563EB), size: 18.0),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            item.parentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    InkWell(
                      onTap: () {
                        final cleanPhone = item.parentPhone.replaceAll(RegExp(r'[^\d+]'), '');
                        launchUrl(Uri.parse('tel:$cleanPhone'));
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.phone, color: Color(0xFF10B981), size: 18.0),
                          const SizedBox(width: 10.0),
                          Text(
                            item.parentPhone,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                              fontSize: 13.0,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    InkWell(
                      onTap: () {
                        launchUrl(Uri.parse('mailto:${item.parentEmail}'));
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.email, color: Color(0xFF6366F1), size: 18.0),
                          const SizedBox(width: 10.0),
                          Text(
                            item.parentEmail,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                              fontSize: 13.0,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Player Direct Contact
              const Text(
                'PLAYER DIRECT CONTACT',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
              ),
              const SizedBox(height: 10.0),
              InkWell(
                onTap: () {
                  final cleanPhone = item.playerPhone.replaceAll(RegExp(r'[^\d+]'), '');
                  launchUrl(Uri.parse('tel:$cleanPhone'));
                },
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smartphone, color: Color(0xFF003EC7), size: 18.0),
                      const SizedBox(width: 10.0),
                      Text(
                        '${item.playerName}: ${item.playerPhone}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                          fontSize: 13.0,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Plan Guidance & Notes
              const Text(
                'ACTION PLAN DETAILS & GUIDANCE',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
              ),
              const SizedBox(height: 8.0),
              Text(
                item.notes,
                style: const TextStyle(fontSize: 13.0, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 24.0),

              // Toggle Action Button
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(coachActionProvider.notifier).toggleAction(item.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(item.isCompleted ? Icons.undo : Icons.check_circle, size: 18.0),
                  label: Text(
                    item.isCompleted ? 'Mark as Pending' : 'Mark Task Completed',
                    style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.isCompleted ? const Color(0xFF64748B) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortalCard(
    String title,
    String desc,
    String value,
    IconData icon,
    Color themeColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFC3C5D9).withOpacity(0.4), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: themeColor, size: 28.0),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xFF434656),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 4.0),
                Icon(Icons.arrow_forward, color: themeColor, size: 16.0),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCoachFeedbackCard(StudentPortalData data) {
    final firstName = data.profile['firstName'] ?? data.profile['first_name'] ?? 'Athlete';
    String coachQuote = "$firstName is showing steady work ethic in drills. Focus on maintaining defensive shape during width plays.";
    if (data.matches.isNotEmpty) {
      final latest = data.matches.first;
      coachQuote = "$firstName played a great game vs. ${latest['opponent']}. Tackles and work rate were outstanding. Keep it up!";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFC3C5D9).withOpacity(0.4), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              image: DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBJgKVh9XL1zB21jv1RIcPjnknvLwARm0Ma5A7_4G6rjVJ79StPJ_drBmkrP97BFi4JpUB8rD1BiyGJdebPdjuns_A67hs0ePwARV3cxNAbXLrS9Y9eeWAcrSHhjEANCps2uAB2n4mt0Qm79A1XofJF8MN5cDunz65kMJf3eT9zTiZWscgJo1YMqHtwTuLtahit_YJvXWIIoHMQ3CLl4dzX5vod_utCoHuU8gik6cg0U4WGXb3ptBmNZQ'
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white.withOpacity(0.8)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF003EC7),
                      child: Icon(Icons.person, color: Colors.white, size: 16.0),
                    ),
                    SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach Ross Venter',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                        ),
                        Text(
                          'Head Technical Coach',
                          style: TextStyle(fontSize: 11.0, color: Color(0xFF434656)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '"$coachQuote"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF131B2E),
                      fontSize: 14.0,
                      height: 1.4,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: FITNESS PROGRESSION
  // ==========================================
  Widget _buildFitnessTab(StudentPortalData data) {
    final fitness = data.fitness;
    final baseline = fitness['baseline'];

    if (baseline == null) {
      return _buildEmptyState('No fitness baseline stats recorded.');
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        const Text(
          'Fitness Baselines & Tests',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Your June 2025 performance evaluation results.',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF434656)),
        ),
        const SizedBox(height: 16.0),

        // Speed Metrics
        _buildStatCard('Speed', [
          _buildStatRow('40m Sprint', '${baseline['speed40m'] ?? '-'} seconds'),
          _buildStatRow('60m Sprint', '${baseline['speed60m'] ?? '-'} seconds'),
          _buildStatRow('T-Test Agility', '${baseline['tTest'] ?? '-'} seconds'),
        ]),
        const SizedBox(height: 16.0),

        // Strength Metrics
        _buildStatCard('Strength & Power', [
          _buildStatRow('Push-Ups Reps', '${baseline['pushUps'] ?? '-'} reps'),
          _buildStatRow('Pull-Ups Reps', '${baseline['pullUps'] ?? '-'} reps'),
          _buildStatRow('Squats (40kg)', '${baseline['squats40kg'] ?? '-'} reps'),
          _buildStatRow('Broad Jump', '${baseline['broadJump'] ?? '-'} metres'),
          _buildStatRow('Vertical Jump', '${baseline['verticalJump'] ?? '-'} metres'),
        ]),
      ],
    );
  }

  // ==========================================
  // TAB 3: ACADEMICS
  // ==========================================
  Widget _buildAcademicsTab(StudentPortalData data) {
    if (data.academics.isEmpty) {
      return _buildEmptyState('No school academic grades recorded.');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: data.academics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final acad = data.academics[index];
        final term = acad['term'] ?? 1;
        final grade = (acad['gradePercentage'] as num?)?.toDouble() ?? 0.0;
        final discipline = acad['disciplineScore'] ?? 0;

        Color cardBorderColor = const Color(0xFF16A34A);
        Color textBadgeColor = const Color(0xFF166534);
        Color badgeBg = const Color(0xFFDCFCE7);
        String label = 'EXCELLENT';

        if (grade < 50) {
          cardBorderColor = const Color(0xFFDC2626);
          textBadgeColor = const Color(0xFF991B1B);
          badgeBg = const Color(0xFFFEE2E2);
          label = 'CRITICAL';
        } else if (grade < 60) {
          cardBorderColor = const Color(0xFFD97706);
          textBadgeColor = const Color(0xFF92400E);
          badgeBg = const Color(0xFFFEF3C7);
          label = 'WARNING';
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: cardBorderColor, width: 4.0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Term $term Report Card',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Discipline Score: $discipline Demerits',
                          style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$grade%',
                          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w900, color: cardBorderColor),
                        ),
                        const SizedBox(height: 4.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(color: textBadgeColor, fontSize: 9.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: MATCH LOGS
  // ==========================================
  Widget _buildMatchesTab(StudentPortalData data) {
    if (data.matches.isEmpty) {
      return _buildEmptyState('No matches played in database.');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: data.matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final match = data.matches[index];
        final opponent = match['opponent'] ?? 'Unknown Opponent';
        final date = match['matchDate'] ?? 'Unknown Date';
        final tackles = match['tacklesMade'] ?? 0;
        final carries = match['carries'] ?? 0;
        final autoScore = (match['autoScore'] as num?)?.toDouble() ?? 0.0;
        final category = match['category'] ?? '🟢 On Track';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs. $opponent',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        _buildMatchMetricChip('Tackles', '$tackles'),
                        const SizedBox(width: 8.0),
                        _buildMatchMetricChip('Carries', '$carries'),
                      ],
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$autoScore',
                      style: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      category,
                      style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchMetricChip(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        '$label: $val',
        style: const TextStyle(fontSize: 11.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
      ),
    );
  }

  // ==========================================
  // HELPERS & WIDGET UTILS
  // ==========================================

  Widget _buildStatCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Color(0xFF0F172A)),
            ),
            const Divider(height: 20.0, color: Color(0xFFE2E8F0)),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14.0, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 40.0, color: Color(0xFF64748B)),
            const SizedBox(height: 12.0),
            Text(
              msg,
              style: const TextStyle(fontSize: 14.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  double _getLatestGrade(List<dynamic> academics) {
    if (academics.isEmpty) return 78.0; // default seeded benchmark
    return (academics.last['gradePercentage'] as num?)?.toDouble() ?? 78.0;
  }



  Widget _buildBottomNav() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: bottomInset > 0 ? bottomInset : 12.0,
        top: 6.0,
      ),
      child: Container(
        height: 64.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BottomNavigationBar(
            currentIndex: _activeTab,
            onTap: (index) {
              setState(() {
                _activeTab = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF003EC7),
            unselectedItemColor: const Color(0xFF64748B),
            selectedLabelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 11.0),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
              BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Fitness'),
              BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'Academics'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_score_outlined), activeIcon: Icon(Icons.sports_score), label: 'Matches'),
            ],
          ),
        ),
      ),
    );
  }
}
