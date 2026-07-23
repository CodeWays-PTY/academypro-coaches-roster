import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/storage/local_storage.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/roster_controller.dart';

class CreateSquadModal extends ConsumerStatefulWidget {
  const CreateSquadModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) => const CreateSquadModal(),
    );
  }

  @override
  ConsumerState<CreateSquadModal> createState() => _CreateSquadModalState();
}

class _CreateSquadModalState extends ConsumerState<CreateSquadModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final desc = _descController.text.trim();

    final newSquad = await ref.read(squadsProvider.notifier).createSquad(
      name: name,
      ageGroup: code,
      description: desc,
    );

    // Set new squad as active squad
    ref.read(selectedAgeGroupProvider.notifier).state = newSquad.ageGroup;
    LocalStorage.cacheData('selected_age_group', newSquad.ageGroup);

    // Refresh all dashboard metrics & roster for new squad
    ref.read(dashboardSummaryProvider.notifier).fetchSummary(ageGroup: newSquad.ageGroup);
    ref.read(dashboardFlagsProvider.notifier).fetchFlags(ageGroup: newSquad.ageGroup);
    ref.read(risingStarsProvider.notifier).fetchRisingStars(ageGroup: newSquad.ageGroup);
    ref.read(dashboardEventsProvider.notifier).fetchEvents(ageGroup: newSquad.ageGroup);
    ref.read(rosterProvider.notifier).fetchRoster(newSquad.ageGroup);

    if (mounted) {
      Navigator.pop(context);
      AppToast.showSuccess(
        context,
        title: 'Squad Created & Active',
        message: 'Squad "${newSquad.name}" (${newSquad.ageGroup}) is now set as your active roster.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.group_add, color: Color(0xFF2563EB), size: 22.0),
                ),
                const SizedBox(width: 12.0),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Squad',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Add a new team, division, or age group',
                      style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16.0),

            // Squad Name Input
            const Text(
              'SQUAD / TEAM NAME',
              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. U14 Academy Elite, First XV',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter squad name' : null,
            ),
            const SizedBox(height: 16.0),

            // Squad Code / Age Group Input
            const Text(
              'SQUAD CODE / AGE GROUP KEY',
              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'e.g. U14, DEV, 1stXV',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter squad code' : null,
            ),
            const SizedBox(height: 16.0),

            // Description Input
            const Text(
              'DESCRIPTION (OPTIONAL)',
              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 6.0),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: 'e.g. Junior Development Squad for 2026 Season',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
              ),
            ),
            const SizedBox(height: 24.0),

            // Create Button
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
                        'Create Squad & Activate',
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
