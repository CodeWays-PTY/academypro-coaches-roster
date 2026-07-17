import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/auth_state.dart';

class PlayerMatchStats {
  final String id;
  final String name;
  final String jerseyNumber;
  final String position;
  final String group; // 'Forwards' | 'Backs' | 'Subs'
  int tacklesMade;
  int tacklesMissed;
  int carries;
  int errors;
  int penalties;

  PlayerMatchStats({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.position,
    required this.group,
    this.tacklesMade = 0,
    this.tacklesMissed = 0,
    this.carries = 0,
    this.errors = 0,
    this.penalties = 0,
  });

  double get tacklePercentage {
    final total = tacklesMade + tacklesMissed;
    return total > 0 ? tacklesMade / total : 1.0;
  }

  Map<String, dynamic> toJson() => {
        'playerId': id,
        'tacklesMade': tacklesMade,
        'tacklesMissed': tacklesMissed,
        'carries': carries,
        'errors': errors,
        'penalties': penalties,
      };
}

class MatchState {
  final List<PlayerMatchStats> players;
  final bool loading;
  final bool syncing;
  final String? error;

  MatchState({
    required this.players,
    required this.loading,
    required this.syncing,
    this.error,
  });

  factory MatchState.initial() => MatchState(players: [], loading: true, syncing: false);

  MatchState copyWith({
    List<PlayerMatchStats>? players,
    bool? loading,
    bool? syncing,
    String? error,
  }) {
    return MatchState(
      players: players ?? this.players,
      loading: loading ?? this.loading,
      syncing: syncing ?? this.syncing,
      error: error ?? this.error,
    );
  }

  // Global counts for Bento metrics
  int get totalTackles => players.fold(0, (sum, p) => sum + p.tacklesMade);
  int get totalCarries => players.fold(0, (sum, p) => sum + p.carries);
  int get totalErrors => players.fold(0, (sum, p) => sum + p.errors);
}

class MatchNotifier extends StateNotifier<MatchState> {
  final ApiClient _apiClient;

  MatchNotifier(this._apiClient) : super(MatchState.initial());

  Future<void> loadMatchRoster(String ageGroup) async {
    state = state.copyWith(loading: true);
    try {
      // Load roster from API (falls back to local cache if offline)
      final response = await _apiClient.getAndCache('/api/rosters/$ageGroup');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List playersList = response.data['data']['players'];
        
        final matchPlayers = playersList.map((p) {
          // Assign forwards/backs/subs group based on position
          final pos = (p['position'] as String? ?? '').toLowerCase();
          String group = 'Backs';
          if (pos.contains('prop') || pos.contains('hooker') || pos.contains('lock') || 
              pos.contains('flanker') || pos.contains('number 8') || pos.contains('eight') || pos.contains('sub')) {
            group = pos.contains('sub') ? 'Subs' : 'Forwards';
          }

          // Compute mock jersey number based on player id index
          final idNum = RegExp(r'\d+$').stringMatch(p['id']) ?? '1';
          
          return PlayerMatchStats(
            id: p['id'],
            name: '${p['firstName']} ${p['lastName']}',
            jerseyNumber: '#$idNum',
            position: p['position'] ?? 'Player',
            group: group,
          );
        }).toList();

        state = state.copyWith(players: matchPlayers, loading: false, error: null);
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Failed to load roster: $e');
    }
  }

  void incrementStat(String playerId, String stat) {
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.id == playerId) {
          final updated = PlayerMatchStats(
            id: p.id,
            name: p.name,
            jerseyNumber: p.jerseyNumber,
            position: p.position,
            group: p.group,
            tacklesMade: p.tacklesMade,
            tacklesMissed: p.tacklesMissed,
            carries: p.carries,
            errors: p.errors,
            penalties: p.penalties,
          );
          if (stat == 'TKL') updated.tacklesMade++;
          if (stat == 'OFF') updated.carries++;
          if (stat == 'TO') updated.errors++;
          return updated;
        }
        return p;
      }).toList(),
    );
  }

  void decrementStat(String playerId, String stat) {
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.id == playerId) {
          final updated = PlayerMatchStats(
            id: p.id,
            name: p.name,
            jerseyNumber: p.jerseyNumber,
            position: p.position,
            group: p.group,
            tacklesMade: p.tacklesMade,
            tacklesMissed: p.tacklesMissed,
            carries: p.carries,
            errors: p.errors,
            penalties: p.penalties,
          );
          if (stat == 'TKL' && updated.tacklesMade > 0) updated.tacklesMade--;
          if (stat == 'OFF' && updated.carries > 0) updated.carries--;
          if (stat == 'TO' && updated.errors > 0) updated.errors--;
          return updated;
        }
        return p;
      }).toList(),
    );
  }

  Future<bool> endMatchAndSync() async {
    state = state.copyWith(syncing: true);
    
    bool allSynced = true;
    final matchDate = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

    for (final player in state.players) {
      // Skip players with no match activity
      if (player.tacklesMade == 0 && player.carries == 0 && player.errors == 0) continue;

      final payload = {
        'playerId': player.id,
        'matchDate': matchDate,
        'opponent': 'Menlopark',
        'tacklesMade': player.tacklesMade,
        'tacklesMissed': player.tacklesMissed,
        'carries': player.carries,
        'metresGained': player.carries * 4.0, // Mock metres based on carries
        'errors': player.errors,
        'penalties': player.penalties,
        'workRate': 4,
        'overallRating': 4,
      };

      try {
        // Send request to API
        await _apiClient.dio.post('/api/match-stats', data: payload);
      } on DioException {
        // If offline, queue the payload locally in Hive
        await LocalStorage.queueMatchStats(payload);
        allSynced = false;
      }
    }

    state = state.copyWith(syncing: false);
    return allSynced;
  }
}

// Providers
final matchProvider = StateNotifierProvider<MatchNotifier, MatchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchNotifier(apiClient);
});
