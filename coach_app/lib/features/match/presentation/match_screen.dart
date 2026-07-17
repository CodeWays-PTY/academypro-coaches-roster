import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/match_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String _activeFilter = 'All';
  int _secondsElapsed = 4452; // Starts at 74:12 for demo
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Load roster on startup
    Future.microtask(() {
      ref.read(matchProvider.notifier).loadMatchRoster('U15');
    });

    // Start timer increment
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleStatTap(String playerId, String stat, bool isIncrement) {
    // Premium haptic feedback clicks
    if (isIncrement) {
      HapticFeedback.mediumImpact();
      ref.read(matchProvider.notifier).incrementStat(playerId, stat);
    } else {
      HapticFeedback.lightImpact();
      ref.read(matchProvider.notifier).decrementStat(playerId, stat);
    }
  }

  void _showEndMatchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Match?'),
          content: const Text(
            'This will stop the game timer and submit all logged stats to the dashboard. Ensure all data is accurate before confirming.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                _performEndMatch();
              },
              child: const Text('Confirm End'),
            ),
          ],
        );
      },
    );
  }

  void _performEndMatch() async {
    // Show sync loading blocker
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.0),
                Text('Syncing Match Statistics...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    final allSynced = await ref.read(matchProvider.notifier).endMatchAndSync();
    
    if (mounted) {
      Navigator.of(context).pop(); // Dismiss loading card
      
      // Refresh Dashboard summary
      ref.read(dashboardSummaryProvider.notifier).fetchSummary();
      ref.read(dashboardFlagsProvider.notifier).fetchFlags();

      if (allSynced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match finished. Statistics synced successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD97706),
            content: Text('Offline: Match stats queued locally. Will sync when connection is restored.'),
          ),
        );
      }
      Navigator.of(context).pop(); // Return to Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFDC2626), size: 20),
            const SizedBox(width: 8.0),
            Text(
              _formatTimer(_secondsElapsed),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              onPressed: _showEndMatchDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), // Red
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              child: const Text('End Match', style: TextStyle(fontSize: 13.0)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bento global summary stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12.0,
              childAspectRatio: 1.6,
              children: [
                _buildBentoCount('TACKLES', '${matchState.totalTackles}', const Color(0xFF16A34A)),
                _buildBentoCount('CARRIES', '${matchState.totalCarries}', const Color(0xFF2563EB)),
                _buildBentoCount('TURNOVERS', '${matchState.totalErrors}', const Color(0xFFDC2626)),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: ['All', 'Forwards', 'Backs', 'Subs'].map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Player Counter Grid
          Expanded(
            child: matchState.loading
                ? const Center(child: CircularProgressIndicator())
                : _buildPlayerGrid(matchState.players),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCount(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerGrid(List<PlayerMatchStats> players) {
    // Apply filters
    final filtered = players.where((p) {
      if (_activeFilter == 'All') return true;
      return p.group == _activeFilter;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No active players match this group filter.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final player = filtered[index];
        return _buildPlayerCard(player);
      },
    );
  }

  Widget _buildPlayerCard(PlayerMatchStats player) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: Jersey & Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    player.jerseyNumber,
                    style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            Text(
              player.position,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.0, color: Color(0xFF64748B)),
            ),
            const Divider(height: 16.0, color: Color(0xFFE2E8F0)),
            
            // Counter row 1: Tackles
            _buildCounterRow(player.id, 'TKL', player.tacklesMade, const Color(0xFF16A34A)),
            const SizedBox(height: 6.0),
            // Counter row 2: Carries
            _buildCounterRow(player.id, 'OFF', player.carries, const Color(0xFF2563EB)),
            const SizedBox(height: 6.0),
            // Counter row 3: Turnovers
            _buildCounterRow(player.id, 'TO', player.errors, const Color(0xFFDC2626)),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String playerId, String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: color),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _handleStatTap(playerId, label, false),
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(Icons.remove, size: 14.0, color: Color(0xFF0F172A)),
              ),
            ),
            Container(
              width: 28.0,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
            GestureDetector(
              onTap: () => _handleStatTap(playerId, label, true),
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(Icons.add, size: 14.0, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
