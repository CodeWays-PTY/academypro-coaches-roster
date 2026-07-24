import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
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
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
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
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB), size: 26.0),
            tooltip: 'My Digital Pass',
            onPressed: () {
              if (studentDataState.value != null) {
                _showQRCodeModal(context, studentDataState.value!);
              }
            },
          ),
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
      return _buildEventsTab(data);
    } else if (_activeTab == 2) {
      return _buildStatsTab(data);
    } else if (_activeTab == 3) {
      return _buildFeedbackTab(data);
    } else if (_activeTab == 4) {
      return _buildProfileTab(data);
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

    // Athlete Readiness Score
    final readinessScore = data.readinessScore;

    // Compute Latest Grade
    final latestGrade = _getLatestGrade(data.academics);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 140.0),
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
          const SizedBox(height: 24.0),

          // Next Event Countdown Hero Card
          _buildNextEventHeroWidget(data),
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
            latestGrade > 0 ? 'Term Avg: ${latestGrade.toStringAsFixed(1)}%' : 'No grades recorded',
            Icons.psychology,
            const Color(0xFF003EC7),
            () => setState(() => _activeTab = 3), // Go to Academics Tab (Index 3)
          ),
          const SizedBox(height: 12.0),
          _buildPortalCard(
            'Body',
            'Athletic progression and dynamic test metrics.',
            readinessScore > 0 ? 'Readiness: $readinessScore%' : 'No tests logged',
            Icons.sports_martial_arts,
            const Color(0xFF05B046),
            () => setState(() => _activeTab = 2), // Go to Fitness Tab (Index 2)
          ),
          const SizedBox(height: 12.0),
          _buildPortalCard(
            'Spirit',
            'Weekly uGroup attendance and character building.',
            profile['ugroupsActive'] == 1 ? 'Active' : 'Inactive',
            Icons.church_outlined,
            const Color(0xFF952200),
            () => _showSpiritDetailModal(context, data), // Opens Spirit Portal Modal
          ),
          const SizedBox(height: 28.0),

          // Assigned Coach Action Plans / To-Do
          _buildCoachActionPlansForStudent(studentName),

          // Peace of Mind Coach Feed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Feedback',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF131B2E),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _activeTab = 3),
                icon: const Icon(Icons.arrow_forward, size: 14.0, color: Color(0xFF2563EB)),
                label: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          InkWell(
            onTap: () => setState(() => _activeTab = 3),
            borderRadius: BorderRadius.circular(20.0),
            child: _buildCoachFeedbackCard(data),
          ),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildNextEventHeroWidget(StudentPortalData data) {
    if (data.events.isEmpty) return const SizedBox();

    final now = DateTime.now();
    StudentEvent? nextEvent;

    for (final event in data.events) {
      try {
        final parts = event.startTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dateParts = event.date.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final eventTime = DateTime(year, month, day, hour, minute);

        if (eventTime.isAfter(now) || eventTime.add(Duration(minutes: event.durationMins ?? 90)).isAfter(now)) {
          nextEvent = event;
          break;
        }
      } catch (_) {}
    }

    nextEvent ??= data.events.first;

    final countdownText = _formatCountdown(nextEvent.date, nextEvent.startTime);
    final hasImage = nextEvent.workoutImagePath != null && nextEvent.workoutImagePath!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEventDetailsModal(context, nextEvent!),
        borderRadius: BorderRadius.circular(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF003EC7).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer, color: Color(0xFF60A5FA), size: 18.0),
                      SizedBox(width: 6.0),
                      Text(
                        'NEXT TEAM EVENT',
                        style: TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      countdownText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              Text(
                nextEvent.title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF94A3B8), size: 14.0),
                  const SizedBox(width: 6.0),
                  Text(
                    '${nextEvent.date} at ${nextEvent.startTime}',
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.0, fontWeight: FontWeight.w600),
                  ),
                  if (nextEvent.durationMins != null) ...[
                    const SizedBox(width: 12.0),
                    const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8), size: 14.0),
                    const SizedBox(width: 4.0),
                    Text(
                      '${nextEvent.durationMins}m',
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13.0),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 14.0),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      nextEvent.location,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.0),
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4.0),
                      Icon(Icons.chevron_right, color: Color(0xFF60A5FA), size: 16.0),
                    ],
                  )
                ],
              ),
              if (hasImage) ...[
                const SizedBox(height: 16.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.network(
                        nextEvent.workoutImagePath!,
                        width: double.infinity,
                        height: 280.0,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        color: const Color(0xFF003EC7).withOpacity(0.9),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 18.0),
                            SizedBox(width: 6.0),
                            Text(
                              'View Coach Workout Plan',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown(String dateStr, String startTimeStr) {
    try {
      final now = DateTime.now();
      final parts = startTimeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dateParts = dateStr.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final eventTime = DateTime(year, month, day, hour, minute);
      final diff = eventTime.difference(now);

      if (diff.isNegative) {
        if (diff.inHours.abs() < 2) {
          return 'IN PROGRESS NOW';
        }
        return 'Completed';
      }

      if (diff.inMinutes < 60) {
        return 'Starting in ${diff.inMinutes} mins';
      } else if (diff.inHours < 24) {
        final hrs = diff.inHours;
        final mins = diff.inMinutes % 60;
        if (mins == 0) {
          return 'Starting in ${hrs}h';
        }
        return 'Starting in ${hrs}h ${mins}m';
      } else if (diff.inDays == 1) {
        return 'Starts tomorrow at $startTimeStr';
      } else {
        return 'Starting in ${diff.inDays} days';
      }
    } catch (_) {
      return '$dateStr at $startTimeStr';
    }
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
  // TAB 2: COMBINED STATS & PERFORMANCE HUB
  // ==========================================
  int _selectedStatsFilter = 0; // 0: All, 1: Fitness & Tests, 2: Academics, 3: Match Logs

  Widget _buildStatsTab(StudentPortalData data) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 140.0),
      children: [
        const Text(
          'Stats & Performance Hub',
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Unified athletic evaluation, academic scores, and match statistics.',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF434656)),
        ),
        const SizedBox(height: 16.0),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatsPill('All Stats', 0),
              const SizedBox(width: 8.0),
              _buildStatsPill('Fitness & Tests', 1),
              const SizedBox(width: 8.0),
              _buildStatsPill('Academics', 2),
              const SizedBox(width: 8.0),
              _buildStatsPill('Match Logs', 3),
            ],
          ),
        ),
        const SizedBox(height: 20.0),

        // Fitness Section
        if (_selectedStatsFilter == 0 || _selectedStatsFilter == 1) ...[
          const Row(
            children: [
              Icon(Icons.fitness_center, color: Color(0xFF05B046), size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Fitness & Athletic Benchmarks',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildFitnessSectionContent(data),
          const SizedBox(height: 28.0),
        ],

        // Academics Section
        if (_selectedStatsFilter == 0 || _selectedStatsFilter == 2) ...[
          const Row(
            children: [
              Icon(Icons.school, color: Color(0xFF003EC7), size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Academic Performance',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildAcademicsSectionContent(data),
          const SizedBox(height: 28.0),
        ],

        // Match Logs Section
        if (_selectedStatsFilter == 0 || _selectedStatsFilter == 3) ...[
          const Row(
            children: [
              Icon(Icons.sports_score, color: Color(0xFFD97706), size: 20.0),
              SizedBox(width: 8.0),
              Text(
                'Match Logs & Auto-Scores',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildMatchesSectionContent(data),
        ],
      ],
    );
  }

  Widget _buildStatsPill(String label, int index) {
    final isSelected = _selectedStatsFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatsFilter = index);
      },
      selectedColor: const Color(0xFF003EC7),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        fontSize: 12.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: isSelected ? const Color(0xFF003EC7) : const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildFitnessSectionContent(StudentPortalData data) {
    if (data.dynamicMetrics.isEmpty) {
      return _buildEmptyState('No dynamic athletic test benchmarks recorded.');
    }

    return Column(
      children: data.dynamicMetrics.map((metric) {
        final baseline = metric.initialBaseline;
        final latest = metric.latestScore;
        final unit = metric.unit;
        final isLowerBetter = metric.goalDirection == 'LOWER_IS_BETTER';

        double percentChange = 0.0;
        if (baseline > 0) {
          if (isLowerBetter) {
            percentChange = ((baseline - latest) / baseline) * 100;
          } else {
            percentChange = ((latest - baseline) / baseline) * 100;
          }
        }

        final isImproved = percentChange >= 0;
        final changeString = isImproved
            ? '+${percentChange.toStringAsFixed(1)}% from last measured'
            : '${percentChange.toStringAsFixed(1)}% from last measured';

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      metric.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: isImproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isImproved ? Icons.trending_up : Icons.trending_down,
                            size: 14.0,
                            color: isImproved ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            changeString,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: isImproved ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BASELINE', style: TextStyle(fontSize: 10.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2.0),
                        Text('$baseline $unit', style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TARGET', style: TextStyle(fontSize: 10.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2.0),
                        Text('${metric.targetBenchmark} $unit', style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF003EC7))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('LATEST SCORE', style: TextStyle(fontSize: 10.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2.0),
                        Text('$latest $unit', style: const TextStyle(fontSize: 17.0, fontWeight: FontWeight.w900, color: Color(0xFF05B046))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: LinearProgressIndicator(
                    value: (metric.targetPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF05B046),
                    minHeight: 6.0,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcademicsSectionContent(StudentPortalData data) {
    if (data.academics.isEmpty) {
      return _buildEmptyState('No academic report cards recorded.');
    }

    return Column(
      children: data.academics.map((acad) {
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
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10.0,
                offset: Offset(0, 3),
              ),
            ],
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Color(0xFF0F172A)),
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
                          '${grade.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w900, color: cardBorderColor),
                        ),
                        const SizedBox(height: 2.0),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchesSectionContent(StudentPortalData data) {
    if (data.matches.isEmpty) {
      return _buildEmptyState('No match logs recorded.');
    }

    return Column(
      children: data.matches.map((match) {
        final opponent = match['opponent'] ?? 'Unknown Opponent';
        final date = match['matchDate'] ?? 'Unknown Date';
        final tackles = match['tacklesMade'] ?? 0;
        final carries = match['carries'] ?? 0;
        final autoScore = (match['autoScore'] as num?)?.toDouble() ?? 0.0;
        final category = match['category'] ?? '🟢 On Track';

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      date,
                      style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        _buildMatchMetricChip('Tackles', '$tackles'),
                        const SizedBox(width: 8.0),
                        _buildMatchMetricChip('Carries', '$carries'),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$autoScore',
                      style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      category,
                      style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // TAB 3: COACH FEEDBACK HISTORY
  // ==========================================
  Widget _buildFeedbackTab(StudentPortalData data) {
    final List<Map<String, String>> feedbackList = [
      {
        'coach': 'Coach Ross Venter',
        'role': 'Head Performance Coach',
        'date': 'Yesterday at 15:30',
        'category': 'Athletic Speed & Agility',
        'notes': 'Jan showed tremendous explosive acceleration during 40m sprint evaluations today. Maintain focus on hip extension for maximum top-speed retention.',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      },
      {
        'coach': 'Coach Mark de Klerk',
        'role': 'Tactical & Kicking Coach',
        'date': '2026-07-21 at 10:15',
        'category': 'Match Strategy & Tactical Kicking',
        'notes': 'High-ball catching technique improved significantly under pressure. Recommended continuing 20 extra spiralled box-kicks post session.',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      },
      {
        'coach': 'Dr. Hannes Visser',
        'role': 'Academic Advisor',
        'date': '2026-07-18 at 09:00',
        'category': 'Academic Progress',
        'notes': 'Term 2 academic average maintained above 68.0%. Good balance between training load and exam preparation.',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      },
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 140.0),
      itemCount: feedbackList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coach Feedback History',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
              ),
              SizedBox(height: 4.0),
              Text(
                'All evaluation notes, performance guidance, and tactical advice from your coaches.',
                style: TextStyle(fontSize: 13.0, color: Color(0xFF434656)),
              ),
              SizedBox(height: 16.0),
            ],
          );
        }

        final fb = feedbackList[index - 1];

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20.0,
                      backgroundImage: NetworkImage(fb['avatar']!),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fb['coach']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            fb['role']!,
                            style: const TextStyle(fontSize: 11.0, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        fb['category']!,
                        style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  fb['notes']!,
                  style: const TextStyle(fontSize: 14.0, color: Color(0xFF334155), height: 1.4),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.access_time, size: 12.0, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4.0),
                    Text(
                      fb['date']!,
                      style: const TextStyle(fontSize: 11.0, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: EDIT ATHLETE PROFILE & DIGITAL PASS
  // ==========================================
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _ageGroupController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _teamController = TextEditingController();
  bool _isSavingProfile = false;

  Widget _buildProfileTab(StudentPortalData data) {
    final profile = data.profile;
    if (_firstNameController.text.isEmpty && profile['firstName'] != null) {
      _firstNameController.text = profile['firstName'] ?? '';
      _lastNameController.text = profile['lastName'] ?? '';
      _positionController.text = profile['position'] ?? '';
      _ageGroupController.text = profile['ageGroup'] ?? '';
      _parentContactController.text = profile['parentContact'] ?? '';
      _teamController.text = profile['team'] ?? '';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 140.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Athlete Profile',
                  style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Manage personal details and access digital QR pass.',
                  style: TextStyle(fontSize: 13.0, color: Color(0xFF434656)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded, size: 32.0, color: Color(0xFF2563EB)),
              onPressed: () => _showQRCodeModal(context, data),
            ),
          ],
        ),
        const SizedBox(height: 20.0),

        // Digital Pass Banner
        GestureDetector(
          onTap: () => _showQRCodeModal(context, data),
          child: Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003EC7), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003EC7).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 36.0),
                ),
                const SizedBox(width: 14.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digital Athlete ID & QR Pass',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Tap to present scannable pass for gym & event check-ins.',
                        style: TextStyle(fontSize: 12.0, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 24.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24.0),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Personal Information',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14.0),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14.0),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Playing Position',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_rugby_outlined),
                  ),
                ),
                const SizedBox(height: 14.0),
                TextFormField(
                  controller: _ageGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Age Group (e.g. U15, U16)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                ),
                const SizedBox(height: 14.0),
                TextFormField(
                  controller: _teamController,
                  decoration: const InputDecoration(
                    labelText: 'Team Assignment (e.g. U15 A Team)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                ),
                const SizedBox(height: 14.0),
                TextFormField(
                  controller: _parentContactController,
                  decoration: const InputDecoration(
                    labelText: 'Guardian / Parent Contact Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton.icon(
                  onPressed: _isSavingProfile
                      ? null
                      : () async {
                          setState(() => _isSavingProfile = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);
                            final res = await apiClient.dio.post('/api/student-portal/profile', data: {
                              'firstName': _firstNameController.text.trim(),
                              'lastName': _lastNameController.text.trim(),
                              'position': _positionController.text.trim(),
                              'ageGroup': _ageGroupController.text.trim(),
                              'team': _teamController.text.trim(),
                              'parentContact': _parentContactController.text.trim(),
                            });
                            if (res.data['success'] == true) {
                              await ref.read(studentControllerProvider.notifier).fetchStudentData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profile details updated successfully!')),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update profile: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSavingProfile = false);
                          }
                        },
                  icon: _isSavingProfile
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSavingProfile ? 'Saving Changes...' : 'Save Profile Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003EC7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20.0),

        OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_outlined, color: Color(0xFFDC2626)),
          label: const Text('Sign Out of Account', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          ),
        ),
      ],
    );
  }

  void _showQRCodeModal(BuildContext context, StudentPortalData data) {
    final profile = data.profile;
    final studentName = '${profile['firstName'] ?? 'Jan'} ${profile['lastName'] ?? 'Mentz'}'.trim();
    final studentId = profile['id'] ?? 'OVK-STUDENT-JAN';
    final ageGroup = profile['ageGroup'] ?? 'U15';
    final position = profile['position'] ?? 'Flyhalf';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Digital Athlete Pass',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=$studentId',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 200,
                        height: 200,
                        color: const Color(0xFFF1F5F9),
                        alignment: Alignment.center,
                        child: const Icon(Icons.qr_code_2, size: 120, color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      studentId,
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF003EC7), letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                studentName,
                style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Hoërskool Overkruin • $position ($ageGroup)',
                style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003EC7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('Close QR Pass', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
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
    if (academics.isEmpty) return 0.0;
    return (academics.last['gradePercentage'] as num?)?.toDouble() ?? 0.0;
  }



  // ==========================================
  // TAB 5: TEAM EVENTS & SCHEDULE
  // ==========================================
  Widget _buildEventsTab(StudentPortalData data) {
    final events = data.events;
    if (events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 140.0),
        children: [
          _buildEmptyState('No upcoming team sessions or events scheduled.'),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 140.0),
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Events & Schedule',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF131B2E)),
              ),
              SizedBox(height: 4.0),
              Text(
                'Upcoming training sessions, match days, and coach workout plans.',
                style: TextStyle(fontSize: 13.0, color: Color(0xFF434656)),
              ),
              SizedBox(height: 16.0),
            ],
          );
        }

        final event = events[index - 1];
        final hasImage = event.workoutImagePath != null && event.workoutImagePath!.trim().isNotEmpty;
        final countdown = _formatCountdown(event.date, event.startTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showEventDetailsModal(context, event),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: event.eventType == 'Match Day'
                              ? const Color(0xFFFEE2E2)
                              : event.eventType == 'Gym Session'
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          event.eventType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: event.eventType == 'Match Day'
                                ? const Color(0xFF991B1B)
                                : event.eventType == 'Gym Session'
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF166534),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          countdown,
                          style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14.0, color: Color(0xFF64748B)),
                      const SizedBox(width: 6.0),
                      Text(
                        '${event.date} at ${event.startTime}',
                        style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                      if (event.durationMins != null) ...[
                        const SizedBox(width: 12.0),
                        const Icon(Icons.timer_outlined, size: 14.0, color: Color(0xFF64748B)),
                        const SizedBox(width: 4.0),
                        Text(
                          '${event.durationMins} mins',
                          style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14.0, color: Color(0xFF64748B)),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569)),
                        ),
                      ),
                      const Row(
                        children: [
                          Text('Details', style: TextStyle(fontSize: 12.0, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          SizedBox(width: 2.0),
                          Icon(Icons.chevron_right, size: 16.0, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ],
                  ),
                  if (hasImage) ...[
                    const SizedBox(height: 16.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Image.network(
                            event.workoutImagePath!,
                            width: double.infinity,
                            height: 300.0,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100.0,
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: const Text('Workout image preview unavailable', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            color: const Color(0xFF003EC7).withOpacity(0.9),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 18.0),
                                SizedBox(width: 6.0),
                                Text(
                                  'View Coach Workout Plan',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEventDetailsModal(BuildContext context, StudentEvent event) {
    final hasImage = event.workoutImagePath != null && event.workoutImagePath!.trim().isNotEmpty;
    final countdown = _formatCountdown(event.date, event.startTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12.0),
              Container(
                width: 44.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                            decoration: BoxDecoration(
                              color: event.eventType == 'Match Day'
                                  ? const Color(0xFFFEE2E2)
                                  : event.eventType == 'Gym Session'
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              event.eventType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: event.eventType == 'Match Day'
                                    ? const Color(0xFF991B1B)
                                    : event.eventType == 'Gym Session'
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF166534),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Text(
                              countdown,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _buildEventDetailRow(Icons.calendar_month, 'Date & Time', '${event.date} at ${event.startTime}'),
                            const Divider(height: 20.0, color: Color(0xFFE2E8F0)),
                            _buildEventDetailRow(Icons.location_on_outlined, 'Location', event.location),
                            if (event.durationMins != null) ...[
                              const Divider(height: 20.0, color: Color(0xFFE2E8F0)),
                              _buildEventDetailRow(Icons.timer_outlined, 'Duration', '${event.durationMins} minutes'),
                            ],
                            const Divider(height: 20.0, color: Color(0xFFE2E8F0)),
                            _buildEventDetailRow(Icons.groups_outlined, 'Team Assignment', '${event.ageGroup} ${event.team}'),
                          ],
                        ),
                      ),
                      if (hasImage) ...[
                        const SizedBox(height: 20.0),
                        const Text(
                          'Coach Workout Plan',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10.0),
                        GestureDetector(
                          onTap: () => _showFullImageModal(context, event.workoutImagePath!, event.title),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Image.network(
                                  event.workoutImagePath!,
                                  width: double.infinity,
                                  height: 320.0,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  color: const Color(0xFF003EC7).withOpacity(0.9),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 20.0),
                                      SizedBox(width: 8.0),
                                      Text(
                                        'Tap to Expand Full Resolution Plan',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (hasImage) {
                            _showFullImageModal(context, event.workoutImagePath!, event.title);
                          }
                        },
                        icon: Icon(hasImage ? Icons.zoom_in : Icons.check_circle_outline, size: 20.0),
                        label: Text(hasImage ? 'Open Full Resolution Workout Plan' : 'Close Event Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003EC7),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20.0),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.0, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            const SizedBox(height: 2.0),
            Text(value, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ],
    );
  }

  void _showFullImageModal(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28.0),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20.0),
                  minScale: 1.0,
                  maxScale: 6.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Failed to load workout plan image.', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24.0,
                left: 20.0,
                right: 20.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.zoom_in, color: Color(0xFF60A5FA), size: 18.0),
                      SizedBox(width: 8.0),
                      Text(
                        'Pinch to Zoom & Pan Workout Details',
                        style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpiritDetailModal(BuildContext context, StudentPortalData data) {
    final profile = data.profile;
    final uGroupsActive = profile['ugroupsActive'] == 1 || profile['ugroupsActive'] == true;
    final attendanceLogs = data.attendance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12.0),
              Container(
                width: 44.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: const Icon(Icons.church_outlined, color: Color(0xFF952200), size: 28.0),
                          ),
                          const SizedBox(width: 14.0),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spirit & Character',
                                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'Weekly uGroups & Leadership Mentorship',
                                style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF952200), Color(0xFFC2410C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'uGROUPS MEMBERSHIP',
                                  style: TextStyle(color: Color(0xFFFFEDD5), fontSize: 11.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    uGroupsActive ? 'ACTIVE' : 'STANDBY',
                                    style: const TextStyle(color: Color(0xFF952200), fontSize: 10.0, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            const Text(
                              'Overkruin Student Leadership Cell',
                              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6.0),
                            const Text(
                              'Weekly character building, peer support, and spiritual growth sessions.',
                              style: TextStyle(fontSize: 13.0, color: Color(0xFFFFEDD5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      const Text(
                        'Character & Leadership Pillars',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12.0),
                      _buildPillarTile(Icons.verified_user_outlined, 'Integrity & Honor', 'Demonstrating honesty and accountability in sports & academics.'),
                      _buildPillarTile(Icons.psychology_outlined, 'Resilience & Grit', 'Overcoming setbacks and maintaining focus under pressure.'),
                      _buildPillarTile(Icons.groups_outlined, 'Servant Leadership', 'Supporting teammates and serving the school community.'),
                      const SizedBox(height: 24.0),
                      const Text(
                        'Recent Attendance Logs',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12.0),
                      if (attendanceLogs.isEmpty)
                        _buildEmptyState('No attendance logs recorded yet.')
                      else
                        ...attendanceLogs.map((item) {
                          final sessionName = item['sessionName'] ?? item['title'] ?? 'uGroup Session';
                          final date = item['date'] ?? item['sessionDate'] ?? 'Recent';
                          final status = item['status'] ?? 'PRESENT';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF05B046), size: 20.0),
                                    const SizedBox(width: 10.0),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sessionName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: Color(0xFF0F172A))),
                                        const SizedBox(height: 2.0),
                                        Text(date, style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF952200),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        ),
                        child: const Text('Close Spirit Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillarTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: const Color(0xFF952200), size: 20.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2.0),
                Text(desc, style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0, top: 4.0),
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
                selectedLabelStyle: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 10.0),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Events'),
                  BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Stats'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Feedback'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      );
    }
}
