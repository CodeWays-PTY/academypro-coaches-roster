import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../student/controllers/student_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../auth/presentation/login_screen.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studentControllerProvider.notifier).fetchStudentData();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      appBar: AppBar(
        title: const Text('uSPORT Parent Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
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
                  const Icon(Icons.error_outline, size: 48.0, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12.0),
                  Text(
                    'Error loading dashboard: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
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
  // TAB 1: OVERVIEW & PARENT HEADERS
  // ==========================================
  Widget _buildOverviewTab(StudentPortalData data) {
    final profile = data.profile;
    final studentName = '${profile['firstName'] ?? 'Student'} ${profile['lastName'] ?? ''}'.trim();
    final parentName = ref.watch(authProvider).userProfile?['firstName'] ?? 'Parent';
    final team = profile['team'] ?? 'Unassigned Team';
    final ageGroup = profile['ageGroup'] ?? 'U/N';
    final position = profile['position'] ?? 'Player';

    // Compute average attendance
    double totalAtt = 0;
    double presentAtt = 0;
    for (var att in data.attendance) {
      totalAtt += (att['total'] as num).toDouble();
      presentAtt += (att['present'] as num).toDouble();
    }
    final attendancePct = totalAtt > 0 ? (presentAtt / totalAtt * 100).round() : 100;

    // Compute average match score
    double totalScores = 0;
    int scoreCount = 0;
    for (var m in data.matches) {
      if (m['autoScore'] != null) {
        totalScores += (m['autoScore'] as num).toDouble();
        scoreCount++;
      }
    }
    final avgScore = scoreCount > 0 ? (totalScores / scoreCount) : 0.0;
    final roundedAvg = (avgScore * 10).round() / 10;

    // Check for flags / alerts to display to Parent
    final latestGrade = _getLatestGrade(data.academics);
    final hasAcademicWarning = latestGrade > 0 && latestGrade < 60;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Welcoming Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $parentName',
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Viewing progress for your child: $studentName',
                    style: const TextStyle(fontSize: 14.0, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          '$position • $team ($ageGroup)',
                          style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Flag / Intervention warning for parents
          if (hasAcademicWarning) ...[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Amber Light
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFD97706).withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Color(0xFFD97706), size: 20.0),
                      SizedBox(width: 8.0),
                      Text(
                        'INTERVENTION SUGGESTED',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${studentName}\'s academic average has dropped to $latestGrade%. We recommend coordinating a check-in or request tutoring.',
                    style: const TextStyle(fontSize: 13.0, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 12.0),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tutoring assistance request submitted to school coordinator.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    ),
                    child: const Text('Request Tutoring Support', style: TextStyle(fontSize: 12.0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
          ],

          // Grid Stats Bento
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.3,
            children: [
              _buildBentoCard('ATTENDANCE', '$attendancePct%', const Color(0xFF16A34A), Icons.check_circle_outline),
              _buildBentoCard('PERFORMANCE avg', scoreCount > 0 ? '$roundedAvg/5' : 'N/A', const Color(0xFF2563EB), Icons.sports_score_outlined),
              _buildBentoCard('uGROUPS attend', profile['ugroupsActive'] == 1 ? 'ACTIVE' : 'INACTIVE', profile['ugroupsActive'] == 1 ? const Color(0xFF16A34A) : const Color(0xFF64748B), Icons.church_outlined),
              _buildBentoCard('ACADEMIC avg', data.academics.isNotEmpty ? '$latestGrade%' : 'N/A', _getGradeColor(data.academics), Icons.school_outlined),
            ],
          ),
          const SizedBox(height: 24.0),

          // Parent Support Box
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support Contacts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Color(0xFF0F172A)),
                  ),
                  const Divider(height: 16.0),
                  _buildContactRow('Head Coach Venter', 'coach.ross@overkruin.co.za'),
                  const SizedBox(height: 8.0),
                  _buildContactRow('Tutoring Coordinator', 'tutoring@overkruin.co.za'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactRow(String roleName, String email) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(roleName, style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B))),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening mail client to: $email')),
            );
          },
          child: Text(email, style: const TextStyle(fontSize: 13.0, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildBentoCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              Icon(icon, color: const Color(0xFF64748B), size: 16.0),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB REUSES FOR FITNESS, ACADEMICS, MATCHES
  // ==========================================
  Widget _buildFitnessTab(StudentPortalData data) {
    final baseline = data.fitness['baseline'];
    if (baseline == null) return _buildEmptyState('No fitness stats recorded.');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text('Fitness Baselines', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16.0),
        _buildStatCard('Speed', [
          _buildStatRow('40m Sprint', '${baseline['speed40m'] ?? '-'}s'),
          _buildStatRow('60m Sprint', '${baseline['speed60m'] ?? '-'}s'),
          _buildStatRow('T-Test Agility', '${baseline['tTest'] ?? '-'}s'),
        ]),
        const SizedBox(height: 16.0),
        _buildStatCard('Strength', [
          _buildStatRow('Push-Ups', '${baseline['pushUps'] ?? '-'} reps'),
          _buildStatRow('Pull-Ups', '${baseline['pullUps'] ?? '-'} reps'),
          _buildStatRow('Squats (40kg)', '${baseline['squats40kg'] ?? '-'} reps'),
        ]),
      ],
    );
  }

  Widget _buildAcademicsTab(StudentPortalData data) {
    if (data.academics.isEmpty) return _buildEmptyState('No academics recorded.');
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: data.academics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final acad = data.academics[index];
        final grade = (acad['gradePercentage'] as num?)?.toDouble() ?? 0.0;
        final term = acad['term'] ?? 1;
        final discipline = acad['disciplineScore'] ?? 0;

        Color border = const Color(0xFF16A34A);
        if (grade < 50) border = const Color(0xFFDC2626);
        else if (grade < 60) border = const Color(0xFFD97706);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: border, width: 4.0))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Term $term Report Card', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                        Text('Discipline Demerits: $discipline', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.0)),
                      ],
                    ),
                    Text('$grade%', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w900, color: border)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab(StudentPortalData data) {
    if (data.matches.isEmpty) return _buildEmptyState('No matches played.');
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      itemCount: data.matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final match = data.matches[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('vs. ${match['opponent']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                    Text('${match['matchDate']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.0)),
                  ],
                ),
                Text('${match['autoScore']}', style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
            const Divider(height: 20.0),
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
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 36.0, color: Color(0xFF64748B)),
            const SizedBox(height: 8.0),
            Text(msg, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  double _getLatestGrade(List<dynamic> academics) {
    if (academics.isEmpty) return 0;
    return (academics.last['gradePercentage'] as num?)?.toDouble() ?? 0.0;
  }

  Color _getGradeColor(List<dynamic> academics) {
    final grade = _getLatestGrade(academics);
    if (grade == 0) return const Color(0xFF64748B);
    if (grade < 50) return const Color(0xFFDC2626);
    if (grade < 60) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
      ),
      child: BottomNavigationBar(
        currentIndex: _activeTab,
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: 'Fitness'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Academics'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_score_outlined), label: 'Matches'),
        ],
      ),
    );
  }
}
