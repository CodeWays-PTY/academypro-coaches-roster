import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/student_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../auth/presentation/login_screen.dart';

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
        title: const Text('uSPORT Student'),
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
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(StudentPortalData data) {
    final profile = data.profile;
    final name = '${profile['firstName'] ?? 'Athlete'} ${profile['lastName'] ?? ''}'.trim();
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

    // Compute overall match score average
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Athlete Profile Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      name.isNotEmpty ? name[0] : 'A',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '$position • $team ($ageGroup)',
                          style: const TextStyle(fontSize: 14.0, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Overview Bento Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.3,
            children: [
              _buildBentoCard('ATTENDANCE', '$attendancePct%', const Color(0xFF16A34A), Icons.check_circle_outline),
              _buildBentoCard('PERFORMANCE', scoreCount > 0 ? '$roundedAvg/5' : 'N/A', const Color(0xFF2563EB), Icons.sports_score_outlined),
              _buildBentoCard('uGROUPS SPIRITUAL', profile['ugroupsActive'] == 1 ? 'ACTIVE' : 'INACTIVE', profile['ugroupsActive'] == 1 ? const Color(0xFF16A34A) : const Color(0xFF64748B), Icons.church_outlined),
              _buildBentoCard('ACADEMIC STATUS', data.academics.isNotEmpty ? '${_getLatestGrade(data.academics)}%' : 'N/A', _getGradeColor(data.academics), Icons.school_outlined),
            ],
          ),
          const SizedBox(height: 28.0),

          // Recent Match Card Quick-Peek
          const Text(
            'Recent Match Performance',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12.0),
          data.matches.isEmpty
              ? _buildEmptyState('No matches played yet.')
              : _buildRecentMatchCard(data.matches.first),
        ],
      ),
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
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Your June 2025 performance evaluation results.',
          style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
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

  Widget _buildRecentMatchCard(dynamic match) {
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0, color: Color(0xFF0F172A)),
                ),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8.0),
                Text('Tackles: $tackles • Carries: $carries', style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B))),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$autoScore',
                  style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
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
