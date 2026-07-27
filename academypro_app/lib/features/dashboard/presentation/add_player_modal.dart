import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_toast.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/roster_controller.dart';

class AddPlayerModal extends ConsumerStatefulWidget {
  final String? initialAgeGroup;

  const AddPlayerModal({Key? key, this.initialAgeGroup}) : super(key: key);

  static void show(BuildContext context, {String? initialAgeGroup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) => AddPlayerModal(initialAgeGroup: initialAgeGroup),
    );
  }

  @override
  ConsumerState<AddPlayerModal> createState() => _AddPlayerModalState();
}

class _AddPlayerModalState extends ConsumerState<AddPlayerModal> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController();
  
  late String _selectedAgeGroup;
  late String _selectedTeam;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final squads = ref.read(squadsProvider);
    final String activeAge = widget.initialAgeGroup ?? ref.read(selectedAgeGroupProvider) ?? 'GENERAL';
    
    _selectedAgeGroup = activeAge;
    
    final matchingSquad = squads.firstWhere(
      (sq) => sq.ageGroup == activeAge,
      orElse: () => squads.isNotEmpty ? squads.first : SquadItem(id: 'gen', name: 'General Roster', ageGroup: 'GENERAL'),
    );
    _selectedTeam = matchingSquad.name;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final position = _positionController.text.trim();

    await ref.read(rosterProvider.notifier).addPlayer(
      firstName: firstName,
      lastName: lastName,
      ageGroup: _selectedAgeGroup,
      position: position,
      team: _selectedTeam,
      email: email,
    );

    if (mounted) {
      Navigator.pop(context);
      AppToast.showSuccess(
        context,
        title: 'Athlete Added to Roster',
        message: '$firstName $lastName enrolled in $_selectedTeam${email.isNotEmpty ? " • Invite sent to $email" : ""}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final squads = ref.watch(squadsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0 + bottomSafeArea + bottomInset),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC3C5D9).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Icon(Icons.person_add_alt_1, color: Color(0xFF003EC7), size: 22.0),
                      ),
                      const SizedBox(width: 12.0),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Athlete / Player',
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Enroll athlete directly into a squad roster',
                            style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16.0),

                  // First Name & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FIRST NAME',
                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Marcus',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.5)),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LAST NAME',
                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 6.0),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Reed',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.5)),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Target Squad Selector
                  const Text(
                    'TARGET SQUAD',
                    style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        borderRadius: BorderRadius.circular(16.0),
                        value: squads.any((s) => s.ageGroup == _selectedAgeGroup)
                            ? _selectedAgeGroup
                            : (squads.isNotEmpty ? squads.first.ageGroup : 'GENERAL'),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF003EC7)),
                        items: [
                          if (squads.isEmpty)
                            const DropdownMenuItem(
                              value: 'GENERAL',
                              child: Text('General Roster (No Squad)', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            ),
                          ...squads.map((sq) {
                            return DropdownMenuItem(
                              value: sq.ageGroup,
                              child: Text(sq.name, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            final sq = squads.firstWhere((s) => s.ageGroup == val, orElse: () => SquadItem(id: 'gen', name: 'General Roster', ageGroup: 'GENERAL'));
                            setState(() {
                              _selectedAgeGroup = val;
                              _selectedTeam = sq.name;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Freetext Position Input
                  const Text(
                    'PRIMARY POSITION',
                    style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Prop, Fly-half, Center',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.5)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a primary position';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Mandatory Athlete Email
                  const Text(
                    'ATHLETE EMAIL (MANDATORY FOR ACCOUNT PROFILE)',
                    style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6.0),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'e.g. athlete@example.com',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF003EC7), width: 1.5)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Athlete email address is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Solid Action Buttons Row (Cancel & Submit)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50.0,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003EC7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                                  )
                                : const Text(
                                    'Add Athlete to Roster',
                                    style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
