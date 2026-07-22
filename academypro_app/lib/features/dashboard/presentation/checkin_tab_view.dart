import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/checkin_controller.dart';
import '../controllers/roster_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'qr_scanner_modal.dart';

class CheckInTabView extends ConsumerStatefulWidget {
  const CheckInTabView({Key? key}) : super(key: key);

  @override
  ConsumerState<CheckInTabView> createState() => _CheckInTabViewState();
}

class _CheckInTabViewState extends ConsumerState<CheckInTabView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final selectedAge = ref.read(selectedAgeGroupProvider);
      ref.read(rosterProvider.notifier).fetchRoster(selectedAge);
      _syncRosterToCheckIn(selectedAge);
    });
  }

  void _syncRosterToCheckIn(String ageGroup) {
    final rosterState = ref.read(rosterProvider);
    final players = rosterState.playersByAge[ageGroup] ?? [];
    ref.read(checkInProvider.notifier).initRoster(ageGroup, players);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAgeGroup = ref.watch(selectedAgeGroupProvider);
    final rosterState = ref.watch(rosterProvider);
    final checkInState = ref.watch(checkInProvider);

    // Sync roster data whenever roster updates for current age group
    ref.listen<RosterState>(rosterProvider, (previous, next) {
      final players = next.playersByAge[selectedAgeGroup] ?? [];
      if (players.isNotEmpty && checkInState.totalCount == 0) {
        ref.read(checkInProvider.notifier).initRoster(selectedAgeGroup, players);
      }
    });

    final recordsList = checkInState.playerRecords.values.toList();
    final filteredRecords = recordsList.where((r) {
      final fullName = '${r.player.firstName} ${r.player.lastName}'.toLowerCase();
      final pos = r.player.position.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return fullName.contains(q) || pos.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(rosterProvider.notifier).fetchRoster(selectedAgeGroup);
          final players = ref.read(rosterProvider).playersByAge[selectedAgeGroup] ?? [];
          ref.read(checkInProvider.notifier).initRoster(selectedAgeGroup, players);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Practice Check-In',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Mark attendance by name or scan QR badges',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  // Age Group Dropdown Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedAgeGroup,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14.0),
                        items: const [
                          DropdownMenuItem(value: 'U15', child: Text('U15')),
                          DropdownMenuItem(value: 'U16', child: Text('U16')),
                          DropdownMenuItem(value: 'U18', child: Text('U18')),
                        ],
                        onChanged: (newAge) {
                          if (newAge != null) {
                            ref.read(selectedAgeGroupProvider.notifier).state = newAge;
                            ref.read(rosterProvider.notifier).fetchRoster(newAge);
                            final players = ref.read(rosterProvider).playersByAge[newAge] ?? [];
                            ref.read(checkInProvider.notifier).changeAgeGroup(newAge, players);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // CONTINUOUS QR SCANNER ACTION CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003EC7), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003EC7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32.0),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Continuous QR Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.0),
                          Text(
                            'Keep camera open to scan athlete badges back-to-back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        QrScannerModal.show(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF003EC7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      ),
                      child: const Text(
                        'Open Scanner',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // ATTENDANCE PROGRESS STATS CARD
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: checkInState.checkedInCount > 0
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'CHECKED IN: ${checkInState.checkedInCount} / ${checkInState.totalCount} ATHLETES',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(checkInState.progressPercentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003EC7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Linear Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999.0),
                      child: LinearProgressIndicator(
                        value: checkInState.progressPercentage,
                        minHeight: 8.0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          checkInState.checkedInCount == checkInState.totalCount && checkInState.totalCount > 0
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF003EC7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Session Type Tabs Selector
                    Row(
                      children: ['Field Practice', 'Gym Session', 'uGroup Session'].map((st) {
                        final isSel = checkInState.sessionType == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(st),
                            selected: isSel,
                            selectedColor: const Color(0xFFDBEAFE),
                            backgroundColor: const Color(0xFFF8FAFC),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 11.5,
                            ),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                            ),
                            onSelected: (_) {
                              ref.read(checkInProvider.notifier).changeSessionType(st);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // SEARCH INPUT BAR WITH 'X' CLEAR BUTTON
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search player by name or position...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14.0),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
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
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.0),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              // ROSTER LIST (MANUAL CHECK-IN BY NAME)
              if (filteredRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32.0),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(Icons.person_search_outlined, color: Color(0xFF94A3B8), size: 48.0),
                      SizedBox(height: 12.0),
                      Text(
                        'No roster players match search filter',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14.0, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredRecords.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10.0),
                  itemBuilder: (context, index) {
                    final item = filteredRecords[index];
                    final player = item.player;
                    final isCheckedIn = item.isCheckedIn;
                    final timeStr = item.checkInTime != null ? DateFormat('hh:mm a').format(item.checkInTime!) : '';

                    return InkWell(
                      onTap: () {
                        ref.read(checkInProvider.notifier).toggleCheckIn(player.id);
                      },
                      borderRadius: BorderRadius.circular(16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: isCheckedIn ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isCheckedIn ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                            width: isCheckedIn ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Status Checkbox Indicator Button
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: BoxDecoration(
                                color: isCheckedIn ? const Color(0xFF22C55E) : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCheckedIn ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isCheckedIn ? Icons.check : Icons.radio_button_unchecked,
                                color: isCheckedIn ? Colors.white : const Color(0xFF94A3B8),
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: 14.0),

                            // Athlete Name & Position
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${player.firstName} ${player.lastName}',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: isCheckedIn ? const Color(0xFF14532D) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    '${player.position.toUpperCase()} • ${player.team.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isCheckedIn ? const Color(0xFF166534) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Check-in Badge/Status
                            if (isCheckedIn)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(999.0),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Color(0xFF15803D), size: 12.0),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(999.0),
                                ),
                                child: const Text(
                                  'Unchecked',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24.0),

              // SUBMIT PRACTICE ATTENDANCE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: checkInState.loading
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          final success = await ref.read(checkInProvider.notifier).submitAttendance();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20.0),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: Text(
                                        'Practice attendance saved! (${checkInState.checkedInCount} Present)',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.cloud_upload_outlined, size: 20.0),
                  label: checkInState.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                        )
                      : Text(
                          'Confirm & Save Practice Attendance (${checkInState.checkedInCount}/${checkInState.totalCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003EC7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                  ),
                ),
              ),

              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
