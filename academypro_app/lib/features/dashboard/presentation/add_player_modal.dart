import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _phoneController = TextEditingController();
  
  String _selectedPosition = 'Forward';
  late String _selectedAgeGroup;
  late String _selectedTeam;
  bool _isSubmitting = false;

  final List<String> _positions = [
    'Forward',
    'Back',
    'Midfielder',
    'Defender',
    'Goalkeeper',
    'Lock',
    'Prop',
    'Flanker',
    'Fly-half',
    'Scrum-half',
    'Winger',
    'Center',
    'Fullback',
  ];

  @override
  void initState() {
    super.initState();
    final squads = ref.read(squadsProvider);
    final String activeAge = widget.initialAgeGroup ?? ref.read(selectedAgeGroupProvider) ?? 'U15';
    
    _selectedAgeGroup = activeAge;
    
    final matchingSquad = squads.firstWhere(
      (sq) => sq.ageGroup == activeAge,
      orElse: () => squads.isNotEmpty ? squads.first : SquadItem(id: '1', name: 'U15 Squad', ageGroup: 'U15'),
    );
    _selectedTeam = matchingSquad.name;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    await ref.read(rosterProvider.notifier).addPlayer(
      firstName: firstName,
      lastName: lastName,
      ageGroup: _selectedAgeGroup,
      position: _selectedPosition,
      team: _selectedTeam,
      parentPhone: phone.isNotEmpty ? phone : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          content: Text('$firstName $lastName added to $_selectedTeam!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final squads = ref.watch(squadsProvider);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: 24.0 + bottomPadding,
      ),
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
                  child: const Icon(Icons.person_add_alt_1, color: Color(0xFF2563EB), size: 22.0),
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
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
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
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Target Squad Dropdown
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
                  value: squads.any((s) => s.ageGroup == _selectedAgeGroup) ? _selectedAgeGroup : (squads.isNotEmpty ? squads.first.ageGroup : 'U15'),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                  items: squads.map((sq) {
                    return DropdownMenuItem(
                      value: sq.ageGroup,
                      child: Text(sq.name, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final sq = squads.firstWhere((s) => s.ageGroup == val);
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

            // Position Dropdown
            const Text(
              'POSITION',
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
                  value: _selectedPosition,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                  items: _positions.map((pos) {
                    return DropdownMenuItem(
                      value: pos,
                      child: Text(pos, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPosition = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Parent Contact Phone (Optional)
            const Text(
              'PARENT CONTACT PHONE (OPTIONAL)',
              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g. +27 82 123 4567',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              ),
            ),
            const SizedBox(height: 24.0),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
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
                        style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
