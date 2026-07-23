import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/phone_utils.dart';

class RosterPlayer {
  final String id;
  final String firstName;
  final String lastName;
  final String ageGroup;
  String position;
  final String team;
  final String status;
  final int ugroupsActive;
  final int? age;
  final String parentPhone;

  RosterPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.ageGroup,
    required this.position,
    required this.team,
    required this.status,
    required this.ugroupsActive,
    this.age,
    String? parentPhone,
  }) : parentPhone = PhoneUtils.formatRSAPhone(parentPhone ?? '+27 82 123 4567');

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    return RosterPlayer(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      ageGroup: json['ageGroup'] ?? '',
      position: json['position'] ?? '',
      team: json['team'] ?? '',
      status: json['status'] ?? 'Active',
      ugroupsActive: json['ugroupsActive'] ?? 0,
      age: json['age'] is int ? json['age'] : (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
      parentPhone: PhoneUtils.formatRSAPhone(json['parentPhone'] ?? json['parentContact'] ?? '+27 82 123 4567'),
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
        loading: true,
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
        final newMap = Map<String, List<RosterPlayer>>.from(state.playersByAge);
        newMap[ageGroup] = newMap[ageGroup] ?? [];
        state = state.copyWith(playersByAge: newMap, loading: false);
      }
    } catch (e) {
      final newMap = Map<String, List<RosterPlayer>>.from(state.playersByAge);
      newMap[ageGroup] = newMap[ageGroup] ?? [];
      state = state.copyWith(playersByAge: newMap, loading: false);
    }
  }

  Future<bool> updatePlayerPosition(RosterPlayer player, String newPosition) async {
    final cleanPosition = newPosition.trim();
    if (cleanPosition.isEmpty) return false;

    // Mutate state immediately for instant UI update
    final newMap = Map<String, List<RosterPlayer>>.from(state.playersByAge);
    final playersList = newMap[player.ageGroup] ?? [];
    
    final updatedList = playersList.map((p) {
      if (p.id == player.id) {
        return RosterPlayer(
          id: p.id,
          firstName: p.firstName,
          lastName: p.lastName,
          ageGroup: p.ageGroup,
          position: cleanPosition,
          team: p.team,
          status: p.status,
          ugroupsActive: p.ugroupsActive,
          age: p.age,
        );
      }
      return p;
    }).toList();

    newMap[player.ageGroup] = updatedList;
    state = state.copyWith(playersByAge: newMap);

    try {
      final response = await _apiClient.post(
        '/api/players/${player.id}/position',
        data: {'position': cleanPosition},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Local state already updated
      return true;
    }
  }
}

final rosterProvider = StateNotifierProvider<RosterNotifier, RState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RosterNotifier(apiClient);
});

typedef RState = RosterState;
