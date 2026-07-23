import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/roster_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'create_action_modal.dart';
import 'create_squad_modal.dart';
import 'add_player_modal.dart';

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
      final currentAge = ref.read(selectedAgeGroupProvider);
      ref.read(rosterProvider.notifier).fetchRoster(currentAge);
    });
  }

  void _onAgeGroupChanged(String? newAge) {
    if (newAge != null) {
      ref.read(selectedAgeGroupProvider.notifier).state = newAge;
      ref.read(rosterProvider.notifier).fetchRoster(newAge);
      ref.read(dashboardSummaryProvider.notifier).fetchSummary(ageGroup: newAge);
      ref.read(dashboardFlagsProvider.notifier).fetchFlags(ageGroup: newAge);
      ref.read(risingStarsProvider.notifier).fetchRisingStars(ageGroup: newAge);
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
    final selectedAgeGroup = ref.watch(selectedAgeGroupProvider);

    ref.listen<String>(selectedAgeGroupProvider, (previous, next) {
      if (previous != next) {
        ref.read(rosterProvider.notifier).fetchRoster(next);
      }
    });

    final rosterState = ref.watch(rosterProvider);
    final flagsState = ref.watch(dashboardFlagsProvider);

    final players = rosterState.playersByAge[selectedAgeGroup] ?? [];
    final filteredPlayers = players.where((p) {
      final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row 1: Title & Squad Dropdown Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Squad Roster',
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8.0),
              // Squad Dropdown selector
              Flexible(
                child: Consumer(
                  builder: (context, ref, child) {
                    final squads = ref.watch(squadsProvider);
                    final activeValue = squads.any((s) => s.ageGroup == selectedAgeGroup)
                        ? selectedAgeGroup
                        : (squads.isNotEmpty ? squads.first.ageGroup : 'U15');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
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
                          value: activeValue,
                          isDense: true,
                          isExpanded: false,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13.0),
                          items: [
                            ...squads.map((sq) => DropdownMenuItem(
                                  value: sq.ageGroup,
                                  child: Text(sq.name, overflow: TextOverflow.ellipsis),
                                )),
                            const DropdownMenuItem(
                              value: '__CREATE_NEW_SQUAD__',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 16.0),
                                  SizedBox(width: 6.0),
                                  Text('+ Create Squad', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (newAge) {
                            if (newAge == '__CREATE_NEW_SQUAD__') {
                              CreateSquadModal.show(context);
                            } else if (newAge != null) {
                              _onAgeGroupChanged(newAge);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Action Row 2: Search Field + Add Athlete Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search athlete by name...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
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
              ),
              const SizedBox(width: 8.0),
              // Add Athlete Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AddPlayerModal.show(context, initialAgeGroup: selectedAgeGroup);
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  height: 46.0,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1, size: 16.0, color: Color(0xFF2563EB)),
                      SizedBox(width: 4.0),
                      Text(
                        '+ Add Athlete',
                        style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildPositionRow(BuildContext context, WidgetRef ref, RosterPlayer player, [VoidCallback? onUpdated]) {
    return InkWell(
      onTap: () => _showEditPositionDialog(context, ref, player, onUpdated),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Position Allocation',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14.0),
            ),
            Row(
              children: [
                Text(
                  player.position.isNotEmpty ? player.position : 'Unassigned',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(width: 6.0),
                const Icon(
                  Icons.edit_outlined,
                  size: 16.0,
                  color: Color(0xFF2563EB),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPositionDialog(BuildContext context, WidgetRef ref, RosterPlayer player, [VoidCallback? onUpdated]) {
    final controller = TextEditingController(text: player.position);
    showDialog(
      context: context,
      builder: (context) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: const Text(
                'Edit Position',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specify the field position for ${player.firstName}:',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.0),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: controller,
                    enabled: !saving,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. Flanker / No. 8',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() {
                            saving = true;
                          });
                          final newPos = controller.text.trim();
                          final success = await ref
                              .read(rosterProvider.notifier)
                              .updatePlayerPosition(player, newPos);
                          if (success) {
                            player.position = newPos;
                            onUpdated?.call();
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: success ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                content: Row(
                                  children: [
                                    Icon(
                                      success ? Icons.check_circle_outline : Icons.error_outline,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      success
                                          ? 'Position updated successfully'
                                          : 'Failed to update position',
                                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
    final initials = '${player.firstName.isNotEmpty ? player.firstName[0] : ''}${player.lastName.isNotEmpty ? player.lastName[0] : ''}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFAF8FF),
      constraints: const BoxConstraints(maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 24.0 + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),

                  // Athlete Profile Header Section
                  Row(
                    children: [
                      Container(
                        width: 80.0,
                        height: 80.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0E1FB), // secondary-container / light blue
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFB7C8E1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials.isNotEmpty ? initials : 'P',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
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
                              '${player.firstName} ${player.lastName}',
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${player.position.isNotEmpty ? player.position : 'Unassigned'} • ${player.team.isNotEmpty ? player.team : player.ageGroup}',
                              style: const TextStyle(
                                fontSize: 13.0,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0052FF),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: const Text(
                                    'Active Squad',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDAE2FD),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Text(
                                    'ID: ${player.id}',
                                    style: const TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF434656),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Development Portals Bento Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Development Portals',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'METRICS OVERVIEW',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003EC7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Bento grid layout
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.15,
                    children: [
                      _buildBentoCard(
                        title: 'MIND\n(ACADEMIC)',
                        value: '$gpa%',
                        subtext: 'Term 1 Average',
                        icon: Icons.psychology,
                        color: const Color(0xFF003EC7),
                      ),
                      _buildBentoCard(
                        title: 'BODY\n(FITNESS)',
                        value: '$powerIndex',
                        subtext: 'Power Index',
                        icon: Icons.fitness_center,
                        color: const Color(0xFF16A34A),
                      ),
                      _buildBentoCard(
                        title: 'SPIRIT\n(UGROUP)',
                        value: uGroups,
                        subtext: 'Character Dev',
                        icon: Icons.diversity_3,
                        color: const Color(0xFF952200),
                        hasLeftBorder: true,
                      ),
                      _buildBentoCard(
                        title: 'GYM\nATTENDANCE',
                        value: '$gymAtt%',
                        subtext: 'Facility Attendance',
                        icon: Icons.open_in_full,
                        color: const Color(0xFF64748B),
                        valueColor: const Color(0xFF131B2E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Evaluation Baselines
                  const Text(
                    'Evaluation Baselines',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12.0),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _buildProfileRow('Vertical Jump Baseline', '$verticalJump metres'),
                        const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
                        _buildProfileRow('40m Dash Speed', '$speed40m seconds'),
                        const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
                        _buildPositionRow(context, ref, player, () => setSheetState(() {})),
                        const Divider(height: 1.0, color: Color(0xFFE2E8F0)),
                        _buildProfileRow('Athlete System ID', player.id),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          CreateActionModal.show(
                            context,
                            playerId: player.id,
                            playerName: '${player.firstName} ${player.lastName}',
                          );
                        },
                        icon: const Icon(Icons.add_task, size: 18.0),
                        label: const Text(
                          'Set Coach Action Plan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003EC7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child: const Text(
                          'Close Profile',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  },
);
}

  Widget _buildProfileRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14.0)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14.0)),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    Color? valueColor,
    bool hasLeftBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasLeftBorder)
            Container(
              width: 4.0,
              color: color,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Icon(icon, color: color, size: 18.0),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: valueColor ?? color,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.0,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
