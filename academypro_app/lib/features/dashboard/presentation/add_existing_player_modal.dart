import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/roster_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../../../core/utils/app_toast.dart';

class AddExistingPlayerModal extends ConsumerStatefulWidget {
  final String activeAgeGroup;

  const AddExistingPlayerModal({
    Key? key,
    required this.activeAgeGroup,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required String activeAgeGroup}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExistingPlayerModal(activeAgeGroup: activeAgeGroup),
    );
  }

  @override
  ConsumerState<AddExistingPlayerModal> createState() => _AddExistingPlayerModalState();
}

class _AddExistingPlayerModalState extends ConsumerState<AddExistingPlayerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<RosterPlayer> _allSchoolPlayers = [];
  List<RosterPlayer> _filteredPlayers = [];
  bool _isLoading = true;
  final Set<String> _addingPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _loadSchoolPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchoolPlayers([String query = '']) async {
    setState(() {
      _isLoading = true;
    });

    final players = await ref.read(rosterProvider.notifier).fetchSchoolPlayers(query);

    if (mounted) {
      setState(() {
        _allSchoolPlayers = players;
        _filteredPlayers = players;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredPlayers = _allSchoolPlayers;
      } else {
        _filteredPlayers = _allSchoolPlayers.where((p) {
          final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
          return fullName.contains(clean) || p.ageGroup.toLowerCase().contains(clean);
        }).toList();
      }
    });
  }

  Future<void> _handleAddPlayer(RosterPlayer player, String targetSquadId) async {
    setState(() {
      _addingPlayerIds.add(player.id);
    });

    HapticFeedback.lightImpact();

    final success = await ref.read(rosterProvider.notifier).addPlayerToSquad(
          player.id,
          targetSquadId,
          widget.activeAgeGroup,
        );

    if (mounted) {
      setState(() {
        _addingPlayerIds.remove(player.id);
      });

      if (success) {
        AppToast.showSuccess(
          context,
          title: '${player.firstName} ${player.lastName} added to squad',
        );
        // Refresh local search list
        _loadSchoolPlayers(_searchController.text);
      } else {
        AppToast.showError(
          context,
          title: 'Failed to add ${player.firstName} to squad',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final squads = ref.watch(squadsProvider);
    final activeSquad = squads.firstWhere(
      (s) => s.ageGroup == widget.activeAgeGroup,
      orElse: () => squads.isNotEmpty ? squads.first : Squad(id: 'default', schoolId: 'OVK', coachId: '', name: 'Active Squad', ageGroup: widget.activeAgeGroup, code: widget.activeAgeGroup),
    );

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        top: 16.0,
        left: 20.0,
        right: 20.0,
        bottom: bottomInset + paddingBottom + 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Header Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Color(0xFF2563EB),
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add School Player to Squad',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Target: ${activeSquad.name}',
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search player by first name, last name or grade...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20.0),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18.0, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
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
          const SizedBox(height: 16.0),

          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search_off_rounded, size: 48.0, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12.0),
                            Text(
                              'No registered school players found',
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'Check spelling or ask admin to register student',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredPlayers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                        itemBuilder: (context, index) {
                          final player = _filteredPlayers[index];
                          final initials = '${player.firstName.isNotEmpty ? player.firstName[0] : ''}${player.lastName.isNotEmpty ? player.lastName[0] : ''}';
                          final isAlreadyInSquad = player.assignedSquads.any((s) => s.id == activeSquad.id);
                          final isAdding = _addingPlayerIds.contains(player.id);

                          return Container(
                            padding: const EdgeInsets.all(14.0),
                            decoration: BoxDecoration(
                              color: isAlreadyInSquad ? const Color(0xFFF8FAFC) : Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: isAlreadyInSquad ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 22.0,
                                  backgroundColor: isAlreadyInSquad ? const Color(0xFFE2E8F0) : const Color(0xFFEFF6FF),
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: isAlreadyInSquad ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12.0),

                                // Player Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${player.firstName} ${player.lastName}',
                                        style: const TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Wrap(
                                        spacing: 6.0,
                                        runSpacing: 4.0,
                                        children: [
                                          Text(
                                            '${player.position} • ${player.ageGroup}',
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (isAlreadyInSquad)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6.0),
                                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                              ),
                                              child: const Text(
                                                'In Active Squad',
                                                style: TextStyle(
                                                  fontSize: 10.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            )
                                          else if (player.assignedSquads.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(6.0),
                                              ),
                                              child: Text(
                                                player.assignedSquads.map((s) => s.name).join(', '),
                                                style: const TextStyle(
                                                  fontSize: 10.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8.0),

                                // One-Tap Add Button
                                ElevatedButton.icon(
                                  onPressed: isAdding
                                      ? null
                                      : () => _handleAddPlayer(player, activeSquad.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAlreadyInSquad ? const Color(0xFF475569) : const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                    elevation: 0,
                                  ),
                                  icon: isAdding
                                      ? const SizedBox(
                                          width: 14.0,
                                          height: 14.0,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                                        )
                                      : const Icon(Icons.add, size: 16.0),
                                  label: Text(
                                    isAlreadyInSquad ? 'Re-Add' : '+ Add',
                                    style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
