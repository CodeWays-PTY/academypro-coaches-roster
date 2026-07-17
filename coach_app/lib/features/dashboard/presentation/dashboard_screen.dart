import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../auth/presentation/login_screen.dart';
import '../../match/presentation/match_screen.dart'; // We will build the Match tracker next

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedAgeGroup = 'U15';

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
        title: const Text('uSPORT'),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        onPressed: () {
          // Go to Live Match Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MatchScreen()),
          );
        },
        child: const Icon(Icons.add_chart),
      ),
      bottomNavigationBar: _buildBottomNav(context, activeIndex: 0),
      body: RefreshIndicator(
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
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'U14', child: Text('U14 Academy Squad')),
                      DropdownMenuItem(value: 'U15', child: Text('U15 Academy Elite')),
                      DropdownMenuItem(value: 'U16', child: Text('U16 Academy Premier')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedAgeGroup = val;
                        });
                        // Roster fetch triggers would update based on this state
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Bento Summary Row
              summary.loading
                  ? const Center(child: LinearProgressIndicator())
                  : GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12.0,
                      children: [
                        _buildBentoKPI('ATTENDANCE', '${summary.attendancePercent}%', const Color(0xFF16A34A)),
                        _buildBentoKPI('PERFORMANCE', '${summary.teamPerformanceAvg}/5', const Color(0xFF2563EB)),
                        _buildBentoKPI('CRITICAL FLAGS', '${summary.flagged}', summary.flagged > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                      ],
                    ),
              const SizedBox(height: 32.0),

              // Requires Attention list
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
                    data: (flags) => Text(
                      '${flags.length} CRITICAL FLAGS',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              flagsState.when(
                data: (flags) {
                  if (flags.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 48.0, color: const Color(0xFF16A34A).withOpacity(0.5)),
                            const SizedBox(height: 12.0),
                            const Text(
                              'Squad clear of warnings!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4.0),
                            const Text(
                              'All student-athletes are tracking within green boundaries.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: flags.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                    itemBuilder: (context, index) => _buildFlaggedPlayerCard(flags[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load warnings list: $err',
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoKPI(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedPlayerCard(FlaggedPlayer player) {
    final leftBorderColor = player.severity == 'Critical' 
        ? const Color(0xFFDC2626) // Crimson Red
        : const Color(0xFFD97706); // Amber Gold

    final containerBg = player.severity == 'Critical'
        ? const Color(0xFFFEE2E2).withOpacity(0.2)
        : const Color(0xFFFEF3C7).withOpacity(0.2);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // circular avatar placeholder
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(
                        player.firstName.isNotEmpty ? player.firstName[0] : 'P',
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${player.firstName} ${player.lastName}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${player.position} • ${player.team}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      player.severity == 'Critical' ? Icons.error : Icons.warning,
                      color: leftBorderColor,
                    )
                  ],
                ),
                const SizedBox(height: 16.0),
                // Warning detail box
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: containerBg,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: leftBorderColor.withOpacity(0.15), width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.0,
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
