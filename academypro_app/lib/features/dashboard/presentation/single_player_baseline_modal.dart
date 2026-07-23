import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_toast.dart';

class SinglePlayerBaselineModal extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;

  const SinglePlayerBaselineModal({
    Key? key,
    required this.playerId,
    required this.playerName,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String playerId,
    required String playerName,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SinglePlayerBaselineModal(
        playerId: playerId,
        playerName: playerName,
      ),
    );
  }

  @override
  ConsumerState<SinglePlayerBaselineModal> createState() => _SinglePlayerBaselineModalState();
}

class _SinglePlayerBaselineModalState extends ConsumerState<SinglePlayerBaselineModal> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _metrics = [];
  String? _selectedMetricId;
  
  final _scoreController = TextEditingController();
  final _sessionController = TextEditingController(text: 'Baseline Evaluation');
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getAndCache('/api/test-metrics');
      if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
        final list = res.data['data'] as List? ?? [];
        setState(() {
          _metrics = list;
          if (list.isNotEmpty) {
            _selectedMetricId = list.first['id'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (_selectedMetricId == null) {
      AppToast.showError(context, title: 'Missing Metric', message: 'Please select a test metric.');
      return;
    }

    final scoreText = _scoreController.text.trim();
    if (scoreText.isEmpty || double.tryParse(scoreText) == null) {
      AppToast.showError(context, title: 'Invalid Score', message: 'Please enter a valid numeric test score.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/api/player/evaluation-baseline',
        data: {
          'playerId': widget.playerId,
          'metricId': _selectedMetricId,
          'score': double.parse(scoreText),
          'testDate': _dateController.text.trim(),
          'sessionName': _sessionController.text.trim(),
        },
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (res.statusCode == 200 && res.data['success'] == true) {
          Navigator.pop(context, true);
          final selectedMetric = _metrics.firstWhere((m) => m['id'] == _selectedMetricId, orElse: () => null);
          final metricName = selectedMetric != null ? selectedMetric['name'] : 'Evaluation Metric';
          final unit = selectedMetric != null ? selectedMetric['unit'] : '';

          AppToast.showSuccess(
            context,
            title: 'Evaluation Baseline Saved',
            message: '$metricName set to $scoreText $unit for ${widget.playerName}.',
          );
        } else {
          AppToast.showError(context, title: 'Save Failed', message: res.data['message'] ?? 'Could not save baseline score.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.showError(context, title: 'Connection Error', message: 'Failed to record evaluation baseline score.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final selectedMetric = _metrics.firstWhere((m) => m['id'] == _selectedMetricId, orElse: () => null);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                    'Update Baseline Evaluation',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Recording test score for ${widget.playerName}',
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
          const Divider(height: 24.0),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Metric Dropdown
                    const Text(
                      'TEST METRIC EVALUATION',
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
                          value: _selectedMetricId,
                          borderRadius: BorderRadius.circular(16.0),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                          items: _metrics.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['id'],
                              child: Text(
                                '${m['name']} (${m['category']} • Unit: ${m['unit']})',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMetricId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Test Score Input
                    Text(
                      'RECORDED SCORE (${selectedMetric?['unit'] ?? ''})',
                      style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6.0),
                    TextField(
                      controller: _scoreController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'e.g. ${selectedMetric?['targetBenchmark'] ?? '5.2'}',
                        suffixText: selectedMetric?['unit'] ?? '',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Session Name
                    const Text(
                      'EVALUATION SESSION NAME',
                      style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6.0),
                    TextField(
                      controller: _sessionController,
                      style: const TextStyle(fontSize: 14.0),
                      decoration: InputDecoration(
                        hintText: 'e.g. Mid-Season Testing',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Test Date
                    const Text(
                      'TEST DATE (YYYY-MM-DD)',
                      style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6.0),
                    TextField(
                      controller: _dateController,
                      style: const TextStyle(fontSize: 14.0),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today, size: 18.0, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14.0), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(width: 18.0, height: 18.0, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                    : const Icon(Icons.check_circle_outline, size: 18.0),
                label: Text(_isSaving ? 'Saving Baseline...' : 'Save Evaluation Baseline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003EC7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
