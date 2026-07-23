import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class BatchTestLoggerModal extends ConsumerStatefulWidget {
  final String ageGroup;

  const BatchTestLoggerModal({Key? key, required this.ageGroup}) : super(key: key);

  static void show(BuildContext context, {String ageGroup = 'U15'}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BatchTestLoggerModal(ageGroup: ageGroup),
    );
  }

  @override
  ConsumerState<BatchTestLoggerModal> createState() => _BatchTestLoggerModalState();
}

class _BatchTestLoggerModalState extends ConsumerState<BatchTestLoggerModal> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _testMetrics = [];
  List<dynamic> _players = [];
  
  String? _selectedMetricId;
  final _sessionController = TextEditingController(text: 'Testing Evaluation');
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);

  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _dateController.dispose();
    for (var c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      final metricsRes = await apiClient.getAndCache('/api/test-metrics');
      final rosterRes = await apiClient.getAndCache('/api/rosters/${widget.ageGroup}');

      if (metricsRes.statusCode == 200 && metricsRes.data['success'] == true) {
        _testMetrics = metricsRes.data['data'] ?? [];
        if (_testMetrics.isNotEmpty) {
          _selectedMetricId = _testMetrics.first['id'];
        }
      }

      if (rosterRes.statusCode == 200 && rosterRes.data['success'] == true) {
        _players = rosterRes.data['data']['players'] ?? [];
        for (var p in _players) {
          _scoreControllers[p['id']] = TextEditingController();
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitBatchLogs() async {
    if (_selectedMetricId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a test metric'), backgroundColor: Colors.orange),
      );
      return;
    }

    final List<Map<String, dynamic>> logs = [];
    _scoreControllers.forEach((playerId, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val != null) {
          logs.add({
            'playerId': playerId,
            'score': val,
          });
        }
      }
    });

    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one player test score.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/api/test-logs/batch', data: {
        'metricId': _selectedMetricId,
        'testDate': _dateController.text.trim(),
        'sessionName': _sessionController.text.trim(),
        'logs': logs,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged ${logs.length} test scores successfully!'), backgroundColor: const Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Failed to log scores'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting batch scores: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final selectedMetric = _testMetrics.firstWhere((m) => m['id'] == _selectedMetricId, orElse: () => null);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
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
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Squad Test Session',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Squad ${widget.ageGroup} testing grid entry',
                    style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20.0),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_testMetrics.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No test metrics configured yet. Please configure team metrics first.', textAlign: TextAlign.center),
              ),
            )
          else ...[
            // Select Test & Date Header Controls
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMetricId,
                    borderRadius: BorderRadius.circular(16.0),
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Select Test Metric',
                      prefixIcon: const Icon(Icons.speed, size: 18.0, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                    ),
                    items: _testMetrics.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['id'],
                        child: Text('${m['name']} (${m['unit']})', style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMetricId = val),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _sessionController,
              decoration: InputDecoration(
                labelText: 'Evaluation Session Name (e.g. June Baselines, Pre-Season)',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
            ),
            const SizedBox(height: 16.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ENTER ATHLETE SCORES (${_players.length} PLAYERS)',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                ),
                if (selectedMetric != null)
                  Text(
                    'Unit: ${selectedMetric['unit']}',
                    style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Player List Grid
            Expanded(
              child: ListView.separated(
                itemCount: _players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final player = _players[index];
                  final playerId = player['id'];
                  final controller = _scoreControllers[playerId];

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16.0,
                          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                          child: Text(
                            player['firstName'] != null && player['firstName'].toString().isNotEmpty ? player['firstName'][0] : 'P',
                            style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12.0),
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
                              Text(
                                '${player['position'] ?? 'Player'} • ${player['team'] ?? 'Squad'}',
                                style: const TextStyle(fontSize: 11.0, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100.0,
                          child: TextFormField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: selectedMetric != null ? 'Score' : '-',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitBatchLogs,
                icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline, size: 18.0),
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
