import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/phone_utils.dart';

class SquadInfo {
  final String id;
  final String name;
  final String code;

  SquadInfo({required this.id, required this.name, required this.code});

  factory SquadInfo.fromJson(Map<String, dynamic> json) {
    return SquadInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class RosterPlayer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String ageGroup;
  String position;
  final String team;
  final String status;
  final int ugroupsActive;
  final int? age;
  final String parentPhone;
  final List<SquadInfo> assignedSquads;

  RosterPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email = '',
    required this.ageGroup,
    required this.position,
    required this.team,
    required this.status,
    required this.ugroupsActive,
    this.age,
    String? parentPhone,
    List<SquadInfo>? assignedSquads,
  })  : parentPhone = (parentPhone != null && parentPhone.trim().isNotEmpty) ? PhoneUtils.formatRSAPhone(parentPhone) : '',
        assignedSquads = assignedSquads ?? [];

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    final rawPhone = json['parentPhone'] ?? json['parentContact'];
    final rawSquads = json['assignedSquads'] as List<dynamic>? ?? [];
    return RosterPlayer(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      ageGroup: json['ageGroup'] ?? '',
      position: json['position'] ?? '',
      team: json['team'] ?? '',
      status: json['status'] ?? 'Active',
      ugroupsActive: json['ugroupsActive'] ?? 0,
      age: json['age'] is int ? json['age'] : (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
      parentPhone: (rawPhone != null && rawPhone.toString().trim().isNotEmpty) ? PhoneUtils.formatRSAPhone(rawPhone.toString()) : '',
      assignedSquads: rawSquads.map((s) => SquadInfo.fromJson(s as Map<String, dynamic>)).toList(),
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

  Future<bool> updatePlayerSquads(String playerId, String ageGroup, List<String> squadIds) async {
    try {
      final response = await _apiClient.post(
        '/api/players/$playerId/squads',
        data: {'squadIds': squadIds},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRoster(ageGroup);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<RosterPlayer>> fetchSchoolPlayers([String query = '']) async {
    try {
      final qParam = query.trim().isNotEmpty ? '?q=${Uri.encodeComponent(query.trim())}' : '';
      final response = await _apiClient.getAndCache('/api/school/players$qParam');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        return list.map((x) => RosterPlayer.fromJson(x)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addPlayerToSquad(String playerId, String squadId, String currentAgeGroup) async {
    try {
      final response = await _apiClient.post(
        '/api/squads/$squadId/players/add',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRoster(currentAgeGroup);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removePlayerFromSquad(String playerId, String squadId, String currentAgeGroup) async {
    try {
      final response = await _apiClient.post(
        '/api/squads/$squadId/players/remove',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRoster(currentAgeGroup);
        return true;
      }
    } catch (_) {}
    return false;
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
          assignedSquads: p.assignedSquads,
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

  Future<bool> addPlayer({
    required String firstName,
    required String lastName,
    required String ageGroup,
    required String position,
    required String team,
    String? email,
    String? parentPhone,
  }) async {
    final newId = 'OVK-$ageGroup-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newPlayer = RosterPlayer(
      id: newId,
      firstName: firstName,
      lastName: lastName,
      ageGroup: ageGroup,
      position: position,
      team: team,
      status: 'Active',
      ugroupsActive: 1,
      parentPhone: parentPhone,
    );

    final newMap = Map<String, List<RosterPlayer>>.from(state.playersByAge);
    final currentList = newMap[ageGroup] ?? [];
    newMap[ageGroup] = [newPlayer, ...currentList];

    state = state.copyWith(playersByAge: newMap);

    try {
      await _apiClient.post('/api/players', data: {
        'id': newId,
        'firstName': firstName,
        'lastName': lastName,
        'ageGroup': ageGroup,
        'position': position,
        'team': team,
        'email': email,
        'parentPhone': parentPhone,
      });
    } catch (_) {}

    return true;
  }
}

final rosterProvider = StateNotifierProvider<RosterNotifier, RState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RosterNotifier(apiClient);
});

typedef RState = RosterState;
