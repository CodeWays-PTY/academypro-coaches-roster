import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../auth/presentation/login_screen.dart';
import 'roster_tab_view.dart';
import 'events_tab_view.dart';
import 'profile_tab_view.dart';
import 'create_event_modal.dart';
import 'create_action_modal.dart';

import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/presentation/notifications_panel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedAgeGroup = 'U15';
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardSummaryProvider.notifier).fetchSummary();
      ref.read(dashboardFlagsProvider.notifier).fetchFlags();
      ref.read(risingStarsProvider.notifier).fetchRisingStars();
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
    final summary = ref.watch(dashboardSummaryProvider);
    final flagsState = ref.watch(dashboardFlagsProvider);
    final starsState = ref.watch(risingStarsProvider);
    final coachActions = ref.watch(coachActionProvider);
    final userProfile = ref.watch(authProvider).userProfile ?? LocalStorage.getUserProfile() ?? {};
    final notifState = ref.watch(notificationProvider);

    final firstName = userProfile['first_name'] ?? userProfile['firstName'] ?? 'Jan-Albert';
    final lastName = userProfile['last_name'] ?? userProfile['lastName'] ?? 'Mentz';
    final avatarPath = userProfile['avatarUrl'] ?? userProfile['profile_pic'];
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56.0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _activeTab = 4;
              });
            },
            child: CircleAvatar(
              backgroundColor: const Color(0xFF003EC7),
              child: avatarPath != null && avatarPath.toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: avatarPath.toString().startsWith('http')
                          ? Image.network(avatarPath.toString(), fit: BoxFit.cover, width: 40, height: 40)
                          : Image.file(File(avatarPath.toString()), fit: BoxFit.cover, width: 40, height: 40),
                    )
                  : Text(
                      initials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AcademyPro',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003EC7),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF434656)),
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
          const SizedBox(width: 8.0),
        ],
      ),
      floatingActionButton: _activeTab == 2
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF003EC7),
              foregroundColor: Colors.white,
              onPressed: () {
                HapticFeedback.mediumImpact();
                CreateEventModal.show(context);
              },
              icon: const Icon(Icons.add, size: 22.0),
              label: const Text(
                'Create Event',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(context, activeIndex: _activeTab),
      body: _buildBody(summary, flagsState, starsState, coachActions),
    );
  }

  Widget _buildBody(
    DashboardSummaryState summary,
    AsyncValue<List<FlaggedPlayer>> flagsState,
    AsyncValue<List<RisingStarPlayer>> starsState,
    List<CoachActionItem> coachActions,
  ) {
    switch (_activeTab) {
      case 1:
        return const RosterTabView();
      case 2:
        return const EventsTabView();
      case 3:
        return const Center(
          child: Text(
            'Messages & Inbox coming soon',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
        );
      case 4:
        return const ProfileTabView();
      case 0:
      default:
        return _buildDashboardOverview(summary, flagsState, starsState, coachActions);
    }
  }

  Widget _buildDashboardOverview(
    DashboardSummaryState summary,
    AsyncValue<List<FlaggedPlayer>> flagsState,
    AsyncValue<List<RisingStarPlayer>> starsState,
    List<CoachActionItem> coachActions,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardSummaryProvider.notifier).fetchSummary();
        await ref.read(dashboardFlagsProvider.notifier).fetchFlags();
        await ref.read(risingStarsProvider.notifier).fetchRisingStars();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Team Selector dropdown
            const Text(
              'CURRENT COMMAND',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAgeGroup,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15.0),
                  items: const [
                    DropdownMenuItem(value: 'U15', child: Text('U15 Academy Elite')),
                    DropdownMenuItem(value: 'U16', child: Text('U16 Academy Elite')),
                    DropdownMenuItem(value: 'U18', child: Text('U18 Premier Squad')),
                  ],
                  onChanged: (newAge) {
                    if (newAge != null) {
                      setState(() {
                        _selectedAgeGroup = newAge;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Squad KPIs Overview Row
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'ATTENDANCE',
                    '${summary.attendancePercent}%',
                    Icons.trending_up,
                    summary.loading,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _buildKpiCard(
                    'PERFORMANCE avg',
                    '${summary.teamPerformanceAvg}/5',
                    Icons.sports_score,
                    summary.loading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    'SQUAD HEALTH',
                    'Optimum',
                    Icons.favorite_outline,
                    summary.loading,
                    subtitle: '${summary.uniReady + summary.onTrack} of ${summary.totalPlayers} fit units',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28.0),

            // ===================================================================
            // SECTION 1: RISING STARS (5-WEEK CONSISTENCY CLUB)
            // Strict Qualification Rule: ONLY displayed if Grades UP + Attendance UP + 5-Wk Gym Consistency
            // ===================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Color(0xFF10B981), size: 22.0),
                    SizedBox(width: 8.0),
                    Text(
                      'Rising Stars (5-Wk Consistency)',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: const Text(
                    '5 WKS CONSISTENT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Only displayed when grades are up, attendance is up, and gym progress is consistent for 5+ weeks.',
              style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14.0),

            starsState.when(
              data: (players) {
                // APPLY STRICT QUALIFICATION FILTER HERE
                final qualifiedStars = players.where((p) => p.isQualifiedForRisingStar).toList();

                if (qualifiedStars.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.military_tech_outlined, color: Color(0xFF94A3B8), size: 36.0),
                        SizedBox(height: 8.0),
                        Text(
                          'No Athletes Currently Qualify for Rising Stars',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 14.0),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          'Athletes require 5 consecutive weeks of simultaneous improvement across Grades, Attendance, and Gym performance.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 195.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: qualifiedStars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14.0),
                    itemBuilder: (context, index) {
                      return _buildRisingStarCard(context, qualifiedStars[index]);
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 28.0),

            // ===================================================================
            // SECTION 2: REQUIRES ATTENTION (FLAGS & AT-RISK ATHLETES)
            // ===================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Requires Attention',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                flagsState.when(
                  data: (list) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      '${list.length} FLAGS',
                      style: const TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            flagsState.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No critical warning flags detected today.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    return _buildFlagItem(context, list[index]);
                  },
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )),
              error: (err, _) => Center(child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading warnings: $err', style: const TextStyle(color: Color(0xFFDC2626))),
              )),
            ),

            const SizedBox(height: 28.0),

            // ===================================================================
            // SECTION 3: COACH CUSTOM ACTION TASKS BOARD
            // ===================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.task_alt, color: Color(0xFF2563EB), size: 22.0),
                    SizedBox(width: 8.0),
                    Text(
                      'Coach Action Tasks',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${coachActions.where((a) => !a.isCompleted).length} Open',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            if (coachActions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No open action tasks. Use "Set Action Plan" on any player to define custom tasks.',
                    style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: coachActions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final item = coachActions[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(coachActionProvider.notifier).toggleAction(item.id);
                          },
                          child: Icon(
                            item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: item.isCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            size: 22.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: item.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '${item.playerName} • Added ${item.dateAdded}',
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
                            item.category,
                            style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRisingStarCard(BuildContext context, RisingStarPlayer player) {
    return Container(
      width: 260.0,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2010B981),
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(
                      player.firstName.isNotEmpty ? player.firstName[0] : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${player.firstName} ${player.lastName}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14.0),
                      ),
                      Text(
                        '${player.position} • ${player.ageGroup}',
                        style: const TextStyle(fontSize: 11.0, color: Color(0xFFA7F3D0)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Color(0xFFFBBF24), size: 16.0),
                    SizedBox(width: 4.0),
                    Text(
                      'STREAK',
                      style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
                Text(
                  '${player.gymConsistencyWeeks} WKS CONSISTENT',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStarMetricPill('GRADES', '+${player.gradeImprovement}%', Icons.school),
              _buildStarMetricPill('ATTEND', '${player.attendancePercent}%', Icons.event_available),
              _buildStarMetricPill('GYM', '+${player.gymProgressPercent}%', Icons.fitness_center),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarMetricPill(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFA7F3D0), size: 14.0),
        const SizedBox(height: 2.0),
        Text(
          val,
          style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: Color(0xFFA7F3D0), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, bool loading, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              Icon(icon, color: const Color(0xFF64748B), size: 16.0),
            ],
          ),
          const SizedBox(height: 12.0),
          if (loading)
            const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2.0))
          else
            Text(
              value,
              style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4.0),
            Text(subtitle, style: const TextStyle(fontSize: 11.0, color: Color(0xFF64748B))),
          ]
        ],
      ),
    );
  }

  Widget _buildFlagItem(BuildContext context, FlaggedPlayer player) {
    Color leftBorderColor = const Color(0xFFDC2626);
    Color cardBgColor = const Color(0xFFFEF2F2);

    if (player.severity == 'Warning') {
      leftBorderColor = const Color(0xFFD97706);
      cardBgColor = const Color(0xFFFFFBEB);
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
            border: Border(left: BorderSide(color: leftBorderColor, width: 4.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(
                        player.firstName.isNotEmpty ? player.firstName[0] : 'P',
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${player.firstName} ${player.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${player.position} • Squad: ${player.team} (${player.ageGroup})',
                            style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.error_outline, color: leftBorderColor, size: 20.0),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          color: leftBorderColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        player.flagReason,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // Open Custom Coach Action modal
                      CreateActionModal.show(
                        context,
                        playerId: player.id,
                        playerName: '${player.firstName} ${player.lastName}',
                      );
                    },
                    icon: const Icon(Icons.assignment_add, size: 16.0),
                    label: const Text(
                      'Set Action Plan',
                      style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, {required int activeIndex}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: BottomNavigationBar(
          currentIndex: activeIndex,
          onTap: (index) {
            setState(() {
              _activeTab = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11.0),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Roster'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_score_outlined), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
