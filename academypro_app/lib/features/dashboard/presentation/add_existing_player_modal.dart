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
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty) {
      AppToast.showError(context, title: 'Missing First Name', message: 'Please enter a first name');
      return;
    }
    if (lastName.isEmpty) {
      AppToast.showError(context, title: 'Missing Surname', message: 'Please enter a surname / last name');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      AppToast.showError(context, title: 'Invalid Email', message: 'Please enter a valid email address');
      return;
    }

    setState(() => _isRegistering = true);
    HapticFeedback.lightImpact();

    try {
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
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        AppToast.showError(
          context,
          title: 'Registration Error',
          message: e.toString(),
        );
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
      physics: const BouncingScrollPhysics(),
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
          TextField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
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
          TextField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
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
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
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
    );
  }

}
