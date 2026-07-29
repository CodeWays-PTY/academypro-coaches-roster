import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_toast.dart';
import '../controllers/dashboard_controller.dart';

class BatchTestLoggerModal extends ConsumerStatefulWidget {
  final String ageGroup;
  final CoachEvent? initialEvent;

  const BatchTestLoggerModal({
    Key? key,
    required this.ageGroup,
    this.initialEvent,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    String ageGroup = 'U15',
    CoachEvent? initialEvent,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BatchTestLoggerModal(
        ageGroup: ageGroup,
        initialEvent: initialEvent,
      ),
    );
  }

  @override
  ConsumerState<BatchTestLoggerModal> createState() => _BatchTestLoggerModalState();
}

class _BatchTestLoggerModalState extends ConsumerState<BatchTestLoggerModal> {
  bool _isLoading = true;
  bool _isSaving = false;

  late String _selectedAgeGroup;
  String? _selectedEventId;
  String? _selectedMetricId;

  List<CoachEvent> _testEvents = [];
  List<dynamic> _testMetrics = [];
  List<dynamic> _players = [];

  final _sessionController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);

  // Nested controllers map: [metricId][playerId] -> TextEditingController
  final Map<String, Map<String, TextEditingController>> _scoreControllers = {};

  // Baselines reference map: [playerId][metricId] -> String (e.g. "5.42" or null)
  final Map<String, Map<String, String>> _playerBaselines = {};

  @override
  void initState() {
    super.initState();
    _selectedAgeGroup = widget.ageGroup;
    if (widget.initialEvent != null) {
      _selectedEventId = widget.initialEvent!.id;
      if (widget.initialEvent!.team.isNotEmpty) {
        _selectedAgeGroup = widget.initialEvent!.team;
      } else if (widget.initialEvent!.ageGroup.isNotEmpty) {
        _selectedAgeGroup = widget.initialEvent!.ageGroup;
      }
      _sessionController.text = widget.initialEvent!.title;
      _dateController.text = widget.initialEvent!.date;
    } else {
      _sessionController.text = 'Fitness Testing Session';
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _dateController.dispose();
    _disposeScoreControllers();
    super.dispose();
  }

  void _disposeScoreControllers() {
    for (var metricMap in _scoreControllers.values) {
      for (var controller in metricMap.values) {
        controller.dispose();
      }
    }
    _scoreControllers.clear();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Fetch Events & filter strictly for 'Test Day' (fitness test) events, sorted by date DESC (most recent first)
      final eventsRes = await apiClient.getAndCache('/api/events');
      if (eventsRes.statusCode == 200 && eventsRes.data['success'] == true) {
        final rawEvents = (eventsRes.data['data'] as List? ?? []).map((json) {
          return CoachEvent(
            id: json['id'] ?? '',
            schoolId: json['school_id'] ?? json['schoolId'] ?? 'OVK',
            title: json['title'] ?? 'Event',
            eventType: json['event_type'] ?? json['eventType'] ?? 'General',
            startTime: json['start_time'] ?? json['startTime'] ?? '09:00',
            date: json['date'] ?? '',
            durationMins: json['duration_mins'] ?? json['durationMins'],
            location: json['location'] ?? 'Field',
            isImportant: (json['is_important'] == 1 || json['isImportant'] == true),
            completionCount: json['completion_count'] ?? json['completionCount'],
            recurrenceRule: json['recurrence_rule'] ?? json['recurrenceRule'] ?? 'Does Not Repeat',
            workoutImagePath: json['workout_image_path'] ?? json['workoutImagePath'],
            team: json['team'] ?? json['age_group'] ?? json['ageGroup'] ?? '',
            ageGroup: json['age_group'] ?? json['ageGroup'] ?? 'U15',
          );
        }).toList();

        // Filter strictly to Test Day category
        _testEvents = rawEvents.where((e) {
          final type = e.eventType.toLowerCase().trim();
          return type == 'test day' || type == 'fitness test' || type == 'test';
        }).toList();

        // Sort by date DESC (most recent date first)
        _testEvents.sort((a, b) {
          final dateCmp = b.date.compareTo(a.date);
          if (dateCmp != 0) return dateCmp;
          return b.startTime.compareTo(a.startTime);
        });

        // Set selected event ID if not already selected or if invalid
        if (_selectedEventId == null || !_testEvents.any((e) => e.id == _selectedEventId)) {
          if (_testEvents.isNotEmpty) {
            _selectedEventId = _testEvents.first.id;
            _sessionController.text = _testEvents.first.title;
            _dateController.text = _testEvents.first.date;
          }
        }
      }

      // 2. Fetch Test Metric Definitions
      final metricsRes = await apiClient.getAndCache('/api/test-metrics');
      if (metricsRes.statusCode == 200 && metricsRes.data['success'] == true) {
        _testMetrics = metricsRes.data['data'] ?? [];
        if (_testMetrics.isNotEmpty && _selectedMetricId == null) {
          _selectedMetricId = _testMetrics.first['id'];
        }
      }

      // 3. Fetch Squad Roster Players & Baseline References
      final rosterRes = await apiClient.getAndCache('/api/rosters/$_selectedAgeGroup');
      if (rosterRes.statusCode == 200 && rosterRes.data['success'] == true) {
        _players = rosterRes.data['data']['players'] ?? [];

        // Build controllers map and extract baselines reference
        _disposeScoreControllers();
        _playerBaselines.clear();

        for (var m in _testMetrics) {
          final metricId = m['id'];
          _scoreControllers[metricId] = {};

          for (var p in _players) {
            final playerId = p['id'];
            // Inputs start empty by default as requested
            _scoreControllers[metricId]![playerId] = TextEditingController();

            // Extract previous baseline if present in player data
            if (!_playerBaselines.containsKey(playerId)) {
              _playerBaselines[playerId] = {};
            }

            // Extract baseline from player baselines array/object if available
            String? prevVal;
            final baselines = p['fitnessBaselines'] ?? p['testLogs'] ?? p['baselines'];
            if (baselines is List) {
              final match = baselines.firstWhere(
                (b) => b['metric_id'] == metricId || b['metricId'] == metricId || b['metricName'] == m['name'],
                orElse: () => null,
              );
              if (match != null && match['score'] != null) {
                prevVal = match['score'].toString();
              }
            } else if (baselines is Map && baselines[metricId] != null) {
              prevVal = baselines[metricId].toString();
            }

            _playerBaselines[playerId]![metricId] = prevVal ?? '--';
          }
        }
      }
    } catch (e) {
      print('Error loading batch logger data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSquadChanged(String? newSquad) {
    if (newSquad == null || newSquad == _selectedAgeGroup) return;
    setState(() {
      _selectedAgeGroup = newSquad;
      _selectedEventId = null;
    });
    _loadInitialData();
  }

  void _onEventSelected(String? eventId) {
    if (eventId == null) return;
    final evt = _testEvents.firstWhere((e) => e.id == eventId, orElse: () => _testEvents.first);
    setState(() {
      _selectedEventId = evt.id;
      _sessionController.text = evt.title;
      _dateController.text = evt.date;
    });
  }

  Future<void> _submitBatchLogs() async {
    if (_selectedMetricId == null) {
      AppToast.showError(context, title: 'Missing Metric', message: 'Please select a test metric.');
      return;
    }

    final List<Map<String, dynamic>> logs = [];

    // Gather entries across all metrics where input is not empty
    _scoreControllers.forEach((metricId, playerMap) {
      playerMap.forEach((playerId, controller) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          final val = double.tryParse(text);
          if (val != null) {
            logs.add({
              'playerId': playerId,
              'metricId': metricId,
              'score': val,
            });
          }
        }
      });
    });

    if (logs.isEmpty) {
      AppToast.showError(context, title: 'No Scores Entered', message: 'Please enter at least one athlete test score before saving.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/api/test-logs/batch', data: {
        'eventId': _selectedEventId,
        'metricId': _selectedMetricId,
        'testDate': _dateController.text.trim(),
        'sessionName': _sessionController.text.trim(),
        'logs': logs,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        Navigator.pop(context);
        AppToast.showSuccess(
          context,
          title: 'Scores Recorded',
          message: 'Successfully logged ${logs.length} metric score(s)!',
        );
      } else {
        AppToast.showError(
          context,
          title: 'Submission Failed',
          message: response.data['message'] ?? 'Failed to log test scores.',
        );
      }
    } catch (e) {
      AppToast.showError(context, title: 'Network Error', message: 'Error submitting test scores: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final squads = ref.watch(squadsProvider);
    final activeSquads = squads.isNotEmpty ? squads.map((s) => s.ageGroup).toSet().toList() : ['U14', 'U15', 'U16', 'U17', 'U18', 'First XV'];
    if (!activeSquads.contains(_selectedAgeGroup)) {
      activeSquads.insert(0, _selectedAgeGroup);
    }

    final selectedMetric = _testMetrics.firstWhere(
      (m) => m['id'] == _selectedMetricId,
      orElse: () => null,
    );

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 16.0,
        bottom: 20.0 + bottomInset + safeBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Modal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture Squad Test Metrics',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    'Select a team & Test Day event to enter metrics',
                    style: TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 18.0),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // 1. SELECT TEAM SQUAD & TEST DAY EVENT (Recent date first)
            Row(
              children: [
                // Squad Selector
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAgeGroup,
                    isDense: true,
                    borderRadius: BorderRadius.circular(14.0),
                    decoration: InputDecoration(
                      labelText: 'Select Squad',
                      prefixIcon: const Icon(Icons.shield_outlined, size: 18.0, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                    ),
                    items: activeSquads.map((sq) {
                      return DropdownMenuItem<String>(
                        value: sq,
                        child: Text(sq, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: _onSquadChanged,
                  ),
                ),
                const SizedBox(width: 8.0),

                // Event Selector (Strictly Test Day Events, Recent First)
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: (_testEvents.any((e) => e.id == _selectedEventId)) ? _selectedEventId : null,
                    isDense: true,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14.0),
                    decoration: InputDecoration(
                      labelText: 'Fitness Test Event',
                      prefixIcon: const Icon(Icons.event_available, size: 18.0, color: Color(0xFFD97706)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                    ),
                    hint: const Text('Select Test Event', style: TextStyle(fontSize: 12.0)),
                    items: _testEvents.isEmpty
                        ? [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No Test Day events found', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
                            )
                          ]
                        : _testEvents.map((evt) {
                            return DropdownMenuItem<String>(
                              value: evt.id,
                              child: Text(
                                '${evt.title} (${evt.date})',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                    onChanged: _onEventSelected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // 2. MULTI-METRIC TABS (Horizontal Chips)
            if (_testMetrics.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _testMetrics.map((m) {
                    final isSelected = m['id'] == _selectedMetricId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.bolt : Icons.tune,
                              size: 14.0,
                              color: isSelected ? Colors.white : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 5.0),
                            Text(
                              '${m['name']} (${m['unit']})',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedMetricId = m['id']);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12.0),
            ],

            // Active Metric & Athlete Count Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ATHLETE SCORES (${_players.length} ATHLETES)',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                ),
                if (selectedMetric != null)
                  Text(
                    'Active Metric: ${selectedMetric['name']} (${selectedMetric['unit']})',
                    style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
              ],
            ),
            const SizedBox(height: 8.0),

            // 3. ATHLETE LIST (Empty inputs by default + Previous baseline reference underneath)
            Expanded(
              child: _players.isEmpty
                  ? const Center(
                      child: Text(
                        'No athletes found in this squad.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13.0),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                      itemBuilder: (context, index) {
                        final player = _players[index];
                        final playerId = player['id'];
                        final metricId = _selectedMetricId ?? '';
                        final controller = _scoreControllers[metricId]?[playerId];

                        final prevBaseline = _playerBaselines[playerId]?[metricId] ?? '--';
                        final unit = selectedMetric != null ? selectedMetric['unit'] : '';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 17.0,
                                backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                                child: Text(
                                  player['firstName'] != null && player['firstName'].toString().isNotEmpty
                                      ? player['firstName'][0]
                                      : 'P',
                                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13.0),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${player['firstName']} ${player['lastName']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      '${player['position'] ?? 'Athlete'} • ${_selectedAgeGroup}',
                                      style: const TextStyle(fontSize: 11.0, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 110.0,
                                    child: TextFormField(
                                      controller: controller,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      decoration: InputDecoration(
                                        hintText: 'Enter Score',
                                        hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                        fillColor: Colors.white,
                                        filled: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  // Baseline reference underneath as requested
                                  Text(
                                    'Prev: ${prevBaseline != '--' ? '$prevBaseline $unit' : '--'}',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12.0),

            // 4. SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitBatchLogs,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 18.0),
                label: const Text('Save Batch Test Scores', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
