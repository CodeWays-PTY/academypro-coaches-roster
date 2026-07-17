import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class RosterPlayer {
  final String id;
  final String firstName;
  final String lastName;
  final String ageGroup;
  final String position;
  final String team;
  final String status;
  final int ugroupsActive;

  RosterPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.ageGroup,
    required this.position,
    required this.team,
    required this.status,
    required this.ugroupsActive,
  });

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    return RosterPlayer(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      ageGroup: json['ageGroup'] ?? '',
      position: json['position'] ?? '',
      team: json['team'] ?? '',
      status: json['status'] ?? 'Active',
      ugroupsActive: json['ugroupsActive'] ?? 0,
    );
  }
}

class RosterState {
  final Map<String, List<RosterPlayer>> playersByAge;
  final bool loading;
  final String? error;

  RosterState({
    required this.playersByAge,
    required this.loading,
    this.error,
  });

  factory RosterState.initial() => RosterState(
        playersByAge: {},
        loading: false,
      );

  RosterState copyWith({
    Map<String, List<RosterPlayer>>? playersByAge,
    bool? loading,
    String? error,
  }) {
    return RosterState(
      playersByAge: playersByAge ?? this.playersByAge,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RosterNotifier extends StateNotifier<RosterState> {
  final ApiClient _apiClient;

  RosterNotifier(this._apiClient) : super(RosterState.initial());

  Future<void> fetchRoster(String ageGroup) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _apiClient.getAndCache('/api/rosters/$ageGroup');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data']['players'] ?? [];
        final players = list.map((x) => RosterPlayer.fromJson(x)).toList();
        
        final newMap = Map<String, List<RosterPlayer>>.from(state.playersByAge);
        newMap[ageGroup] = players;
        
        state = state.copyWith(
          playersByAge: newMap,
          loading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: response.data['message'] ?? 'Failed to fetch roster',
        );
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to connect to roster API',
      );
    }
  }
}

final rosterProvider = StateNotifierProvider<RosterNotifier, RState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RosterNotifier(apiClient);
});

typedef RState = RosterState;
