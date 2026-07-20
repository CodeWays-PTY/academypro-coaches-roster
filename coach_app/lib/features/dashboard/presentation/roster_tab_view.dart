import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/roster_controller.dart';
import '../controllers/dashboard_controller.dart';

class RosterTabView extends ConsumerStatefulWidget {
  const RosterTabView({Key? key}) : super(key: key);

  @override
  ConsumerState<RosterTabView> createState() => _RosterTabViewState();
}

class _RosterTabViewState extends ConsumerState<RosterTabView> {
  String _selectedAgeGroup = 'U15';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rosterProvider.notifier).fetchRoster(_selectedAgeGroup);
    });
  }

  void _onAgeGroupChanged(String? newAge) {
    if (newAge != null) {
      setState(() {
        _selectedAgeGroup = newAge;
      });
      ref.read(rosterProvider.notifier).fetchRoster(newAge);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSubtitle(RosterPlayer player) {
    final parts = <String>[];
    if (player.position.isNotEmpty) {
      parts.add(player.position.toUpperCase());
    }
    if (player.team.isNotEmpty) {
      parts.add(player.team.toUpperCase());
    }
    
    if (parts.isEmpty) {
      return Text(
        'UNASSIGNED • ${player.ageGroup}',
        style: const TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8), // slate-400
          letterSpacing: 0.5,
        ),
      );
    }
    
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6.0,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          Text(
            parts[i],
            style: const TextStyle(
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB), // azure-600
              letterSpacing: 0.8,
            ),
          ),
          if (i < parts.length - 1)
            const Text(
              '/',
              style: TextStyle(
                fontSize: 11.0,
                color: Color(0xFFCBD5E1), // slate-300
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterState = ref.watch(rosterProvider);
    final flagsState = ref.watch(dashboardFlagsProvider);

    final players = rosterState.playersByAge[_selectedAgeGroup] ?? [];
    final filteredPlayers = players.where((p) {
      final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Squad Roster',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              // Age Dropdown selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAgeGroup,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13.0),
                    items: const [
                      DropdownMenuItem(value: 'U15', child: Text('U15 Academy Elite')),
                      DropdownMenuItem(value: 'U16', child: Text('U16 Academy Elite')),
                      DropdownMenuItem(value: 'U18', child: Text('U18 Premier Squad')),
                    ],
                    onChanged: _onAgeGroupChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search athlete by name...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.0),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20.0),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18.0, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Loader or Error states
          if (rosterState.loading && players.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (rosterState.error != null && players.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 40.0, color: Color(0xFF64748B)),
                    const SizedBox(height: 8.0),
                    Text(rosterState.error!, style: const TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: () => ref.read(rosterProvider.notifier).fetchRoster(_selectedAgeGroup),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredPlayers.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No athletes match your query.', style: TextStyle(color: Color(0xFF64748B))),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: filteredPlayers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (context, index) {
                  final player = filteredPlayers[index];
                  final initials = '${player.firstName.isNotEmpty ? player.firstName[0] : ''}${player.lastName.isNotEmpty ? player.lastName[0] : ''}';
                  
                  // Check if player has flags
                  final isFlagged = flagsState.maybeWhen(
                    data: (flags) => flags.any((f) => f.id == player.id),
                    orElse: () => false,
                  );

                  return GestureDetector(
                    onTap: () => _showPlayerProfileSheet(context, player, isFlagged),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isFlagged 
                              ? const Color(0xFFFCA5A5) // red-300
                              : const Color(0xFFE2E8F0), // slate-200
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 56.0,
                            height: 56.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFlagged 
                                  ? const Color(0xFFFEE2E2) 
                                  : const Color(0xFFEFF6FF), // azure-50
                              border: Border.all(
                                color: isFlagged 
                                    ? const Color(0xFFFCA5A5) 
                                    : const Color(0xFFDBEAFE), // azure-100
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                initials.isNotEmpty ? initials : 'P',
                                style: TextStyle(
                                  color: isFlagged 
                                      ? const Color(0xFFDC2626) 
                                      : const Color(0xFF2563EB), // azure-600
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          
                          // Middle Text Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${player.firstName} ${player.lastName}'.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (player.age != null && player.age! > 0) ...[
                                      const SizedBox(width: 8.0),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9), // slate-100
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        child: Text(
                                          'Age ${player.age}',
                                          style: const TextStyle(
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569), // slate-600
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                _buildSubtitle(player),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          
                          // Trailing elements (Warning icon if flagged, and Chevron Right)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFlagged) ...[
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20.0),
                                const SizedBox(width: 8.0),
                              ],
                              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 22.0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showPlayerProfileSheet(BuildContext context, RosterPlayer player, bool isFlagged) {
    // Generate seeded random values for player baselines and grades
    final randSeed = player.id.hashCode;
    final r = Random(randSeed);

    final gpa = isFlagged 
        ? (50.0 + r.nextDouble() * 9.0).toStringAsFixed(1)
        : (72.0 + r.nextDouble() * 25.0).toStringAsFixed(1);
    
    final verticalJump = (0.45 + r.nextDouble() * 0.35).toStringAsFixed(2);
    final speed40m = (4.70 + r.nextDouble() * 0.90).toStringAsFixed(2);
    final powerIndex = (520 + r.nextInt(280));
    final gymAtt = 90 + r.nextInt(10);
    final uGroups = player.ugroupsActive == 1 ? 'ACTIVE (98% attend)' : 'INACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Athlete Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                        child: Icon(Icons.person, color: const Color(0xFF2563EB), size: 32.0),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${player.firstName} ${player.lastName}',
                              style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '${player.position} • Squad: ${player.team} (${player.ageGroup})',
                              style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isFlagged ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          isFlagged ? 'ATTENTION REQUIRED' : 'ON TRACK',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: isFlagged ? const Color(0xFF991B1B) : const Color(0xFF166534),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Development Metrics Bento grid
                  const Text('Development Portals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                  const SizedBox(height: 12.0),

                  // Grid stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.25,
                    children: [
                      _buildMetricBox('MIND (Academic)', '$gpa%', 'Term 1 Average', Icons.psychology, const Color(0xFF2563EB)),
                      _buildMetricBox('BODY (Fitness)', '$powerIndex', 'Power Index', Icons.sports_martial_arts, const Color(0xFF16A34A)),
                      _buildMetricBox('SPIRIT (uGroup)', uGroups, 'Character Dev', Icons.church_outlined, const Color(0xFF952200)),
                      _buildMetricBox('GYM ATTENDANCE', '$gymAtt%', 'Facility Attendance', Icons.fitness_center_outlined, const Color(0xFF64748B)),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Baselines Info
                  const Text('Evaluation Baselines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                  const Divider(height: 20.0),
                  _buildProfileRow('Vertical Jump Baseline', '$verticalJump metres'),
                  _buildProfileRow('40m Dash Speed', '$speed40m seconds'),
                  _buildProfileRow('Position Allocation', player.position),
                  _buildProfileRow('Athlete System ID', player.id),
                  const SizedBox(height: 24.0),

                  // Intervention Resolve Button
                  if (isFlagged) ...[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Intervention check-in card sent to ${player.firstName}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        minimumSize: const Size(double.infinity, 48.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      child: const Text('Initiate Resolve Contact', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 12.0),
                  ],

                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: const Text('Close Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, String sub, IconData icon, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(12.0),
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
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              Icon(icon, color: themeColor, size: 16.0),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: themeColor),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 10.0, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
