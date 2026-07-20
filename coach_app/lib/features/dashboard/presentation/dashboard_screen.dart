import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../auth/presentation/login_screen.dart';
import '../../match/presentation/match_screen.dart';
import 'roster_tab_view.dart';
import 'events_tab_view.dart';

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
    // Fetch metrics summary and flags on init
    Future.microtask(() {
      ref.read(dashboardSummaryProvider.notifier).fetchSummary();
      ref.read(dashboardFlagsProvider.notifier).fetchFlags();
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
    final userProfile = ref.watch(authProvider).userProfile;

    final coachName = userProfile != null 
        ? '${userProfile['firstName']} ${userProfile['lastName']}'
        : 'Coach';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      appBar: AppBar(
        title: const Text('AcademyPro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                coachName.isNotEmpty ? coachName[0] : 'C',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: _activeTab == 2
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create event session scheduler initiated')),
                );
              },
              child: const Icon(Icons.add_task, size: 28.0),
            )
          : FloatingActionButton(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MatchScreen()),
                );
              },
              child: const Icon(Icons.add_chart),
            ),
      bottomNavigationBar: _buildBottomNav(context, activeIndex: _activeTab),
      body: _buildBody(summary, flagsState),
    );
  }

  Widget _buildBody(DashboardSummaryState summary, AsyncValue<List<FlaggedPlayer>> flagsState) {
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
        return const Center(
          child: Text(
            'App Configuration & Profile Settings',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
        );
      case 0:
      default:
        return _buildDashboardOverview(summary, flagsState);
    }
  }

  Widget _buildDashboardOverview(DashboardSummaryState summary, AsyncValue<List<FlaggedPlayer>> flagsState) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardSummaryProvider.notifier).fetchSummary();
        await ref.read(dashboardFlagsProvider.notifier).fetchFlags();
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
                      // If we are filtering, update data
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

            // Requires Attention title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Requires Attention',
                  style: TextStyle(
                    fontSize: 20.0,
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
            const SizedBox(height: 16.0),

            // RAG Flags List
            flagsState.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No critical demerits or warning flags detected today.',
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
          ],
        ),
      ),
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
                ElevatedButton(
                  onPressed: () {
                    // Action resolve hooks
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Intervention check-in initiated for ${player.firstName}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                    ),
                  ),
                  child: const Text('RESOLVE ACTION', style: TextStyle(fontSize: 13.0)),
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
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
