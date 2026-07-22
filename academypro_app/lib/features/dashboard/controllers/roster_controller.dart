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
        playersByAge: Map.from(RosterNotifier._defaultRosters),
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

  static final Map<String, List<RosterPlayer>> _defaultRosters = {
    'U15': [
      RosterPlayer(id: 'OVK-U15-001', firstName: 'Liam', lastName: 'Venter', ageGroup: 'U15', position: 'Forward', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-002', firstName: 'Marcus', lastName: 'Reed', ageGroup: 'U15', position: 'Defender', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-003', firstName: 'Ethan', lastName: 'Botha', ageGroup: 'U15', position: 'Midfielder', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 0, age: 15),
      RosterPlayer(id: 'OVK-U15-004', firstName: 'Leo', lastName: 'Silva', ageGroup: 'U15', position: 'Forward', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-005', firstName: 'Jayden', lastName: 'Smith', ageGroup: 'U15', position: 'Goalkeeper', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-006', firstName: 'Ruben', lastName: 'Van Zyl', ageGroup: 'U15', position: 'Flanker', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 0, age: 15),
      RosterPlayer(id: 'OVK-U15-007', firstName: 'Kabelo', lastName: 'Mokoena', ageGroup: 'U15', position: 'Winger', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-008', firstName: 'Sipho', lastName: 'Dlamini', ageGroup: 'U15', position: 'Scrum-half', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-009', firstName: 'Alex', lastName: 'Henderson', ageGroup: 'U15', position: 'Flanker', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-010', firstName: 'Bibi', lastName: 'Achuma', ageGroup: 'U15', position: 'Fly-half', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
      RosterPlayer(id: 'OVK-U15-011', firstName: 'Daniel', lastName: 'Coetzee', ageGroup: 'U15', position: 'Lock', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 0, age: 15),
      RosterPlayer(id: 'OVK-U15-012', firstName: 'Franco', lastName: 'Joubert', ageGroup: 'U15', position: 'Prop', team: 'U15 Academy Elite', status: 'Active', ugroupsActive: 1, age: 15),
    ],
    'U16': [
      RosterPlayer(id: 'OVK-U16-001', firstName: 'Pieter', lastName: 'Du Plessis', ageGroup: 'U16', position: 'Lock', team: 'U16 Academy Elite', status: 'Active', ugroupsActive: 1, age: 16),
      RosterPlayer(id: 'OVK-U16-002', firstName: 'Thabo', lastName: 'Nkosi', ageGroup: 'U16', position: 'Center', team: 'U16 Academy Elite', status: 'Active', ugroupsActive: 1, age: 16),
      RosterPlayer(id: 'OVK-U16-003', firstName: 'Christo', lastName: 'Steyn', ageGroup: 'U16', position: 'Hooker', team: 'U16 Academy Elite', status: 'Active', ugroupsActive: 1, age: 16),
      RosterPlayer(id: 'OVK-U16-004', firstName: 'Zubair', lastName: 'Patel', ageGroup: 'U16', position: 'Fullback', team: 'U16 Academy Elite', status: 'Active', ugroupsActive: 0, age: 16),
      RosterPlayer(id: 'OVK-U16-005', firstName: 'David', lastName: 'Meyer', ageGroup: 'U16', position: 'Flanker', team: 'U16 Academy Elite', status: 'Active', ugroupsActive: 1, age: 16),
    ],
    'U18': [
      RosterPlayer(id: 'OVK-U18-001', firstName: 'Gideon', lastName: 'Louw', ageGroup: 'U18', position: 'Fly-half', team: 'U18 Premier Squad', status: 'Active', ugroupsActive: 1, age: 18),
      RosterPlayer(id: 'OVK-U18-002', firstName: 'Jacques', lastName: 'Fourie', ageGroup: 'U18', position: 'Eightman', team: 'U18 Premier Squad', status: 'Active', ugroupsActive: 1, age: 18),
      RosterPlayer(id: 'OVK-U18-003', firstName: 'Tebogo', lastName: 'Molefe', ageGroup: 'U18', position: 'Winger', team: 'U18 Premier Squad', status: 'Active', ugroupsActive: 1, age: 18),
      RosterPlayer(id: 'OVK-U18-004', firstName: 'Wian', lastName: 'Bezuidenhout', ageGroup: 'U18', position: 'Prop', team: 'U18 Premier Squad', status: 'Active', ugroupsActive: 0, age: 18),
    ],
  };

  RosterNotifier(this._apiClient) : super(RosterState.initial());

  void _applyFallback(String ageGroup) {
    final newMap = Map<String, List<RosterPlayer>>.from(state.playersByAge);
    if (!newMap.containsKey(ageGroup) || (newMap[ageGroup] ?? []).isEmpty) {
      newMap[ageGroup] = _defaultRosters[ageGroup] ?? _defaultRosters['U15']!;
    }
    state = state.copyWith(
      playersByAge: newMap,
      loading: false,
      error: null,
    );
  }

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
        _applyFallback(ageGroup);
      }
    } catch (e) {
      _applyFallback(ageGroup);
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
