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
  int _selectedTabIndex = 0; // 0 = Search Existing, 1 = Register New Player
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _registerFormKey = GlobalKey<FormState>();

  List<RosterPlayer> _allSchoolPlayers = [];
  List<RosterPlayer> _filteredPlayers = [];
  bool _isLoading = true;
  bool _isRegistering = false;
  final Set<String> _addingPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _loadSchoolPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
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

  Future<void> _handleRegisterNewPlayer(String targetSquadId) async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isRegistering = true);
    HapticFeedback.lightImpact();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    final success = await ref.read(rosterProvider.notifier).registerAndAddPlayer(
          firstName: firstName,
          lastName: lastName,
          email: email,
          ageGroup: widget.activeAgeGroup,
          squadId: targetSquadId,
        );

    if (mounted) {
      setState(() => _isRegistering = false);

      if (success) {
        AppToast.showSuccess(
          context,
          title: '$firstName $lastName registered & added to squad',
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = 0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.0),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Search Existing',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: _selectedTabIndex == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTabIndex = 1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9.0),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        size: 16.0,
                        color: _selectedTabIndex == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Register New',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(String squadId, String squadName) {
    return SingleChildScrollView(
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Registering player to school system & assigning to $squadName (${widget.activeAgeGroup}).',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // First Name Field
            const Text(
              'First Name',
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter first name';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'e.g. John',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 20.0),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
            const SizedBox(height: 14.0),

            // Last Name Field
            const Text(
              'Surname / Last Name',
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter surname';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'e.g. Smith',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 20.0),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
            const SizedBox(height: 14.0),

            // Email Field
            const Text(
              'Email Address',
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email address';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'e.g. john.smith@school.co.za',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2563EB), size: 20.0),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
            const SizedBox(height: 24.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton.icon(
                onPressed: _isRegistering ? null : () => _handleRegisterNewPlayer(squadId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 0,
                ),
                icon: _isRegistering
                    ? const SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded, size: 20.0),
                label: Text(
                  _isRegistering ? 'Registering Player...' : 'Register & Add to Squad',
                  style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squads = ref.watch(squadsProvider);
    final activeSquad = squads.firstWhere(
      (s) => s.ageGroup == widget.activeAgeGroup,
      orElse: () => squads.isNotEmpty ? squads.first : SquadItem(id: 'default', name: 'Active Squad', ageGroup: widget.activeAgeGroup, description: ''),
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
                child: Icon(
                  _selectedTabIndex == 0 ? Icons.person_search_rounded : Icons.person_add_rounded,
                  color: const Color(0xFF2563EB),
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedTabIndex == 0 ? 'Add School Player to Squad' : 'Register New Player',
                      style: const TextStyle(
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
          const SizedBox(height: 14.0),

          // Tab Bar Switcher
          _buildTabBar(),
          const SizedBox(height: 16.0),

          // Content Area (Search Existing vs Register New)
          Expanded(
            child: _selectedTabIndex == 1
                ? _buildRegisterTab(activeSquad.id, activeSquad.name)
                : Column(
                    children: [
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
                                      children: [
                                        const Icon(Icons.search_off_rounded, size: 48.0, color: Color(0xFFCBD5E1)),
                                        const SizedBox(height: 12.0),
                                        const Text(
                                          'No registered school players found',
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        const Text(
                                          'Check spelling or register a new player',
                                          style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                        ),
                                        const SizedBox(height: 14.0),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            setState(() => _selectedTabIndex = 1);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF2563EB),
                                            side: const BorderSide(color: Color(0xFF2563EB)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                          ),
                                          icon: const Icon(Icons.person_add_rounded, size: 18.0),
                                          label: const Text('Register New Player', style: TextStyle(fontWeight: FontWeight.bold)),
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
          ),
        ],
      ),
    );
  }
}
