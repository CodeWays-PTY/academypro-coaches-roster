import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/presentation/auth_state.dart';

class DashboardSummaryState {
  final int attendancePercent;
  final double teamPerformanceAvg;
  final int totalPlayers;
  final int uniReady;
  final int onTrack;
  final int atRisk;
  final int danger;
  final int flagged;
  final bool loading;
  final String? error;

  DashboardSummaryState({
    required this.attendancePercent,
    required this.teamPerformanceAvg,
    required this.totalPlayers,
    required this.uniReady,
    required this.onTrack,
    required this.atRisk,
    required this.danger,
    required this.flagged,
    required this.loading,
    this.error,
  });

  factory DashboardSummaryState.initial() => DashboardSummaryState(
        attendancePercent: 96,
        teamPerformanceAvg: 4.4,
        totalPlayers: 28,
        uniReady: 18,
        onTrack: 8,
        atRisk: 2,
        danger: 0,
        flagged: 2,
        loading: false,
      );

  DashboardSummaryState copyWith({
    int? attendancePercent,
    double? teamPerformanceAvg,
    int? totalPlayers,
    int? uniReady,
    int? onTrack,
    int? atRisk,
    int? danger,
    int? flagged,
    bool? loading,
    String? error,
  }) {
    return DashboardSummaryState(
      attendancePercent: attendancePercent ?? this.attendancePercent,
      teamPerformanceAvg: teamPerformanceAvg ?? this.teamPerformanceAvg,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      uniReady: uniReady ?? this.uniReady,
      onTrack: onTrack ?? this.onTrack,
      atRisk: atRisk ?? this.atRisk,
      danger: danger ?? this.danger,
      flagged: flagged ?? this.flagged,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

class DashboardSummaryNotifier extends StateNotifier<DashboardSummaryState> {
  final ApiClient _apiClient;

  DashboardSummaryNotifier(this._apiClient) : super(DashboardSummaryState.initial());

  Future<void> fetchSummary({String ageGroup = 'U15'}) async {
    state = state.copyWith(loading: true);
    try {
      final response = await _apiClient.getAndCache('/api/dashboard/summary?ageGroup=$ageGroup');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final kpis = data['kpis'];

        state = state.copyWith(
          attendancePercent: data['attendancePercent'] ?? 96,
          teamPerformanceAvg: (data['teamPerformanceAvg'] as num?)?.toDouble() ?? 4.4,
          totalPlayers: kpis['totalPlayers'] ?? 28,
          uniReady: kpis['uniReady'] ?? 18,
          onTrack: kpis['onTrack'] ?? 8,
          atRisk: kpis['atRisk'] ?? 2,
          danger: kpis['danger'] ?? 0,
          flagged: kpis['flagged'] ?? 2,
          loading: false,
          error: null,
        );
      } else {
        _applyAgeGroupFallback(ageGroup);
      }
    } catch (e) {
      _applyAgeGroupFallback(ageGroup);
    }
  }

  void _applyAgeGroupFallback(String ageGroup) {
    if (ageGroup == 'U16') {
      state = state.copyWith(
        attendancePercent: 94,
        teamPerformanceAvg: 4.2,
        totalPlayers: 24,
        uniReady: 15,
        onTrack: 6,
        atRisk: 3,
        danger: 0,
        flagged: 1,
        loading: false,
        error: null,
      );
    } else if (ageGroup == 'U18') {
      state = state.copyWith(
        attendancePercent: 98,
        teamPerformanceAvg: 4.6,
        totalPlayers: 30,
        uniReady: 22,
        onTrack: 6,
        atRisk: 1,
        danger: 1,
        flagged: 3,
        loading: false,
        error: null,
      );
    } else {
      state = DashboardSummaryState.initial();
    }
  }
}

class FlaggedPlayer {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String team;
  final String position;
  final String ageGroup;
  final String reason;
  final String flagReason;
  final String flagType;
  final String severity;

  FlaggedPlayer({
    required this.id,
    required this.name,
    String? firstName,
    String? lastName,
    required this.team,
    String? position,
    String? ageGroup,
    required this.reason,
    String? flagReason,
    required this.flagType,
    String? severity,
  })  : firstName = firstName ?? (name.contains(' ') ? name.split(' ').first : name),
        lastName = lastName ?? (name.contains(' ') ? name.split(' ').sublist(1).join(' ') : ''),
        position = position ?? 'Forward',
        ageGroup = ageGroup ?? 'U15',
        flagReason = flagReason ?? reason,
        severity = severity ?? flagType;

  factory FlaggedPlayer.fromJson(Map<String, dynamic> json) {
    final fullName = json['name'] ?? json['playerName'] ?? '';
    return FlaggedPlayer(
      id: json['id'] ?? '',
      name: fullName,
      firstName: json['firstName'],
      lastName: json['lastName'],
      team: json['team'] ?? '',
      position: json['position'] ?? 'Forward',
      ageGroup: json['ageGroup'] ?? 'U15',
      reason: json['reason'] ?? json['flagReason'] ?? '',
      flagReason: json['flagReason'] ?? json['reason'],
      flagType: json['flagType'] ?? 'atRisk',
      severity: json['severity'] ?? json['flagType'] ?? 'atRisk',
    );
  }
}

class DashboardFlagsNotifier extends StateNotifier<AsyncValue<List<FlaggedPlayer>>> {
  final ApiClient _apiClient;

  DashboardFlagsNotifier(this._apiClient)
      : super(AsyncValue.data(_defaultFlags));

  static final List<FlaggedPlayer> _defaultFlags = [
    FlaggedPlayer(
      id: 'OVK-U15-003',
      name: 'Ethan Botha',
      firstName: 'Ethan',
      lastName: 'Botha',
      team: 'U15 Academy Elite',
      position: 'Midfielder',
      ageGroup: 'U15',
      reason: '2 consecutive missed gym sessions',
      flagReason: '2 consecutive missed gym sessions',
      flagType: 'atRisk',
      severity: 'atRisk',
    ),
    FlaggedPlayer(
      id: 'OVK-U15-006',
      name: 'Ruben Van Zyl',
      firstName: 'Ruben',
      lastName: 'Van Zyl',
      team: 'U15 Academy Elite',
      position: 'Flanker',
      ageGroup: 'U15',
      reason: 'uGroup character reflection pending',
      flagReason: 'uGroup character reflection pending',
      flagType: 'attention',
      severity: 'attention',
    ),
  ];

  Future<void> fetchFlags({String? ageGroup}) async {
    try {
      final path = ageGroup != null ? '/api/dashboard/flags?ageGroup=$ageGroup' : '/api/dashboard/flags';
      final response = await _apiClient.getAndCache(path);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final flags = list.map((x) => FlaggedPlayer.fromJson(x)).toList();
        state = AsyncValue.data(flags);
      } else {
        state = AsyncValue.data(_defaultFlags);
      }
    } catch (e) {
      state = AsyncValue.data(_defaultFlags);
    }
  }
}

class RisingStarPlayer {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String team;
  final String position;
  final String ageGroup;
  final int streakWeeks;
  final int gymConsistencyWeeks;
  final int gradeImprovement;
  final int attendancePercent;
  final int gymProgressPercent;
  final String highlights;

  RisingStarPlayer({
    required this.id,
    required this.name,
    String? firstName,
    String? lastName,
    required this.team,
    String? position,
    String? ageGroup,
    required this.streakWeeks,
    int? gymConsistencyWeeks,
    int? gradeImprovement,
    int? attendancePercent,
    int? gymProgressPercent,
    required this.highlights,
  })  : firstName = firstName ?? (name.contains(' ') ? name.split(' ').first : name),
        lastName = lastName ?? (name.contains(' ') ? name.split(' ').sublist(1).join(' ') : ''),
        position = position ?? 'Forward',
        ageGroup = ageGroup ?? 'U15',
        gymConsistencyWeeks = gymConsistencyWeeks ?? streakWeeks,
        gradeImprovement = gradeImprovement ?? 12,
        attendancePercent = attendancePercent ?? 100,
        gymProgressPercent = gymProgressPercent ?? 15;

  bool get isQualifiedForRisingStar => streakWeeks >= 5 || gymConsistencyWeeks >= 5;

  factory RisingStarPlayer.fromJson(Map<String, dynamic> json) {
    final fullName = json['name'] ?? json['playerName'] ?? '';
    return RisingStarPlayer(
      id: json['id'] ?? '',
      name: fullName,
      firstName: json['firstName'],
      lastName: json['lastName'],
      team: json['team'] ?? '',
      position: json['position'] ?? 'Forward',
      ageGroup: json['ageGroup'] ?? 'U15',
      streakWeeks: json['streakWeeks'] ?? 5,
      gymConsistencyWeeks: json['gymConsistencyWeeks'] ?? json['streakWeeks'] ?? 5,
      gradeImprovement: json['gradeImprovement'] ?? 12,
      attendancePercent: json['attendancePercent'] ?? 100,
      gymProgressPercent: json['gymProgressPercent'] ?? 15,
      highlights: json['highlights'] ?? '',
    );
  }
}

class RisingStarsNotifier extends StateNotifier<AsyncValue<List<RisingStarPlayer>>> {
  final ApiClient _apiClient;

  RisingStarsNotifier(this._apiClient)
      : super(AsyncValue.data(_defaultStars));

  static final List<RisingStarPlayer> _defaultStars = [
    RisingStarPlayer(
      id: 'OVK-U15-001',
      name: 'Liam Venter',
      firstName: 'Liam',
      lastName: 'Venter',
      team: 'U15 Academy Elite',
      position: 'Forward',
      ageGroup: 'U15',
      streakWeeks: 5,
      gymConsistencyWeeks: 5,
      gradeImprovement: 15,
      attendancePercent: 100,
      gymProgressPercent: 18,
      highlights: '100% attendance & top 10m sprint time',
    ),
    RisingStarPlayer(
      id: 'OVK-U15-002',
      name: 'Marcus Reed',
      firstName: 'Marcus',
      lastName: 'Reed',
      team: 'U15 Academy Elite',
      position: 'Defender',
      ageGroup: 'U15',
      streakWeeks: 5,
      gymConsistencyWeeks: 5,
      gradeImprovement: 10,
      attendancePercent: 98,
      gymProgressPercent: 14,
      highlights: 'Perfect GPS workload & video analysis submission',
    ),
    RisingStarPlayer(
      id: 'OVK-U15-004',
      name: 'Leo Silva',
      firstName: 'Leo',
      lastName: 'Silva',
      team: 'U15 Academy Elite',
      position: 'Forward',
      ageGroup: 'U15',
      streakWeeks: 5,
      gymConsistencyWeeks: 5,
      gradeImprovement: 14,
      attendancePercent: 100,
      gymProgressPercent: 20,
      highlights: '+15kg squat PR & 5 consecutive uGroup meetings',
    ),
  ];

  Future<void> fetchStars({String? ageGroup}) async {
    try {
      final path = ageGroup != null ? '/api/dashboard/rising-stars?ageGroup=$ageGroup' : '/api/dashboard/rising-stars';
      final response = await _apiClient.getAndCache(path);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final stars = list.map((x) => RisingStarPlayer.fromJson(x)).toList();
        state = AsyncValue.data(stars);
      } else {
        state = AsyncValue.data(_defaultStars);
      }
    } catch (e) {
      state = AsyncValue.data(_defaultStars);
    }
  }

  Future<void> fetchRisingStars({String? ageGroup}) async {
    await fetchStars(ageGroup: ageGroup);
  }
}

class CoachActionItem {
  final String id;
  final String title;
  final String type;
  final String category;
  final String deadline;
  final String dateAdded;
  final bool isCompleted;
  final String? playerId;
  final String playerName;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final String playerPhone;
  final String notes;

  CoachActionItem({
    required this.id,
    required this.title,
    required this.type,
    String? category,
    required this.deadline,
    String? dateAdded,
    this.isCompleted = false,
    this.playerId,
    this.playerName = '',
    this.parentName = 'Parent Contact',
    this.parentPhone = '+27 82 555 0192',
    this.parentEmail = 'parent@academypro.co.za',
    this.playerPhone = '+27 71 444 8821',
    this.notes = 'Follow up required with coaching staff.',
  })  : category = category ?? type,
        dateAdded = dateAdded ?? 'Today';

  CoachActionItem copyWith({
    String? id,
    String? title,
    String? type,
    String? category,
    String? deadline,
    String? dateAdded,
    bool? isCompleted,
    String? playerId,
    String? playerName,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? playerPhone,
    String? notes,
  }) {
    return CoachActionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      deadline: deadline ?? this.deadline,
      dateAdded: dateAdded ?? this.dateAdded,
      isCompleted: isCompleted ?? this.isCompleted,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      playerPhone: playerPhone ?? this.playerPhone,
      notes: notes ?? this.notes,
    );
  }
}

class CoachActionNotifier extends StateNotifier<List<CoachActionItem>> {
  final ApiClient _apiClient;

  CoachActionNotifier(this._apiClient) : super(_defaultActions) {
    fetchActions();
  }

  static final List<CoachActionItem> _defaultActions = [
    CoachActionItem(
      id: '1',
      title: 'Review GPS workload for Liam Venter',
      type: 'GPS Analysis',
      category: 'GPS Analysis',
      deadline: 'Today, 17:00',
      playerId: 'OVK-U15-001',
      playerName: 'Liam Venter',
    ),
    CoachActionItem(
      id: '2',
      title: 'Follow up on Ethan Botha missed session',
      type: 'Attendance Alert',
      category: 'Attendance Alert',
      deadline: 'Tomorrow, 09:00',
      playerId: 'OVK-U15-003',
      playerName: 'Ethan Botha',
    ),
    CoachActionItem(
      id: '3',
      title: 'Confirm squad roster for Saturday Derby',
      type: 'Match Prep',
      category: 'Match Prep',
      deadline: 'Fri, 12:00',
    ),
  ];

  Future<void> fetchActions() async {
    try {
      final res = await _apiClient.getAndCache('/api/dashboard/actions');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        if (list.isNotEmpty) {
          final items = list.map((x) => CoachActionItem(
            id: x['id'].toString(),
            title: x['title'] ?? '',
            type: x['type'] ?? 'General',
            category: x['category'] ?? 'General',
            deadline: x['deadline'] ?? 'Today',
            dateAdded: x['dateAdded'] ?? 'Today',
            isCompleted: x['isCompleted'] == true,
            playerId: x['playerId'],
            playerName: x['playerName'] ?? '',
            parentName: x['parentName'] ?? 'Parent Contact',
            parentPhone: x['parentPhone'] ?? '+27 82 555 0192',
            parentEmail: x['parentEmail'] ?? 'parent@academypro.co.za',
            playerPhone: x['playerPhone'] ?? '+27 71 444 8821',
            notes: x['notes'] ?? 'Follow up required with coaching staff.',
          )).toList();
          state = items;
        }
      }
    } catch (_) {}
  }

  Future<void> addAction({
    String? playerId,
    String playerName = '',
    required String title,
    String category = 'General',
    String type = 'General',
    String deadline = 'Today, 17:00',
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newItem = CoachActionItem(
      id: newId,
      title: title,
      type: type,
      category: category,
      deadline: deadline,
      playerId: playerId,
      playerName: playerName,
      isCompleted: false,
    );
    state = [newItem, ...state];

    try {
      await _apiClient.post('/api/dashboard/actions', data: {
        'id': newId,
        'title': title,
        'type': type,
        'category': category,
        'deadline': deadline,
        'playerId': playerId,
        'playerName': playerName,
      });
      fetchActions();
    } catch (_) {}
  }

  Future<void> toggleAction(String actionId) async {
    state = state.map((item) {
      if (item.id == actionId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    try {
      await _apiClient.post('/api/dashboard/actions/$actionId/toggle');
    } catch (_) {}
  }
}

// Providers
final selectedAgeGroupProvider = StateProvider<String>((ref) {
  final cached = LocalStorage.getCachedData('selected_age_group');
  if (cached is String && cached.isNotEmpty) {
    return cached;
  }
  return 'U15';
});

final dashboardSummaryProvider = StateNotifierProvider<DashboardSummaryNotifier, DashboardSummaryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardSummaryNotifier(apiClient);
});

final dashboardFlagsProvider = StateNotifierProvider<DashboardFlagsNotifier, AsyncValue<List<FlaggedPlayer>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardFlagsNotifier(apiClient);
});

final risingStarsProvider = StateNotifierProvider<RisingStarsNotifier, AsyncValue<List<RisingStarPlayer>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RisingStarsNotifier(apiClient);
});

final coachActionProvider = StateNotifierProvider<CoachActionNotifier, List<CoachActionItem>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CoachActionNotifier(apiClient);
});

final playerActionTasksProvider = Provider.family<List<CoachActionItem>, String?>((ref, playerId) {
  final allActions = ref.watch(coachActionProvider);
  if (playerId == null || playerId.isEmpty) {
    return allActions;
  }
  return allActions.where((item) =>
      item.playerId == playerId ||
      item.playerName.toLowerCase().contains(playerId.toLowerCase())).toList();
});

class CoachEvent {
  final String id;
  final String schoolId;
  final String title;
  final String eventType;
  final String startTime;
  final String date;
  final int? durationMins;
  final String location;
  final bool isImportant;
  final int? completionCount;
  final String recurrenceRule;
  final String? workoutImagePath;
  final String team;
  final String ageGroup;

  CoachEvent({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.eventType,
    required this.startTime,
    required this.date,
    this.durationMins,
    required this.location,
    required this.isImportant,
    this.completionCount,
    this.recurrenceRule = 'Does Not Repeat',
    this.workoutImagePath,
    this.team = 'U15 Academy Elite',
    this.ageGroup = 'U15',
  });

  CoachEvent copyWith({
    String? id,
    String? schoolId,
    String? title,
    String? eventType,
    String? startTime,
    String? date,
    int? durationMins,
    String? location,
    bool? isImportant,
    int? completionCount,
    String? recurrenceRule,
    String? workoutImagePath,
    String? team,
    String? ageGroup,
  }) {
    return CoachEvent(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      startTime: startTime ?? this.startTime,
      date: date ?? this.date,
      durationMins: durationMins ?? this.durationMins,
      location: location ?? this.location,
      isImportant: isImportant ?? this.isImportant,
      completionCount: completionCount ?? this.completionCount,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      workoutImagePath: workoutImagePath ?? this.workoutImagePath,
      team: team ?? this.team,
      ageGroup: ageGroup ?? this.ageGroup,
    );
  }

  factory CoachEvent.fromJson(Map<String, dynamic> json) {
    return CoachEvent(
      id: json['id'] != null ? json['id'].toString() : 'EVT-${DateTime.now().millisecondsSinceEpoch}',
      schoolId: json['schoolId'] ?? '',
      title: json['title'] ?? '',
      eventType: json['eventType'] ?? 'Field',
      startTime: json['startTime'] ?? '',
      date: json['date'] ?? '',
      durationMins: json['durationMins'] != null ? (json['durationMins'] as num).toInt() : null,
      location: json['location'] ?? '',
      isImportant: json['isImportant'] == true,
      completionCount: json['completionCount'] != null ? (json['completionCount'] as num).toInt() : null,
      recurrenceRule: json['recurrenceRule'] ?? 'Does Not Repeat',
      workoutImagePath: json['workoutImagePath'] ?? json['workoutAttachmentName'],
      team: json['team'] ?? 'U15 Academy Elite',
      ageGroup: json['ageGroup'] ?? json['age_group'] ?? 'U15',
    );
  }
}

class DashboardEventsNotifier extends StateNotifier<AsyncValue<List<CoachEvent>>> {
  final ApiClient _apiClient;

  static final List<CoachEvent> _defaultEvents = [
    CoachEvent(
      id: '101',
      schoolId: 'sch1',
      title: 'Tactical & Offload Drills',
      eventType: 'Field',
      startTime: '16:30',
      date: '2026-07-22',
      durationMins: 90,
      location: 'Field A',
      isImportant: false,
      completionCount: 2,
      team: 'U15 Academy Elite',
      ageGroup: 'U15',
    ),
    CoachEvent(
      id: '102',
      schoolId: 'sch1',
      title: 'Power Hypertrophy & Core Conditioning',
      eventType: 'Gym',
      startTime: '07:00',
      date: '2026-07-22',
      durationMins: 60,
      location: 'Gym Facility',
      isImportant: false,
      completionCount: 3,
      team: 'U15 Academy Elite',
      ageGroup: 'U15',
    ),
    CoachEvent(
      id: '103',
      schoolId: 'sch1',
      title: 'Quarterly Fitness Testing Day',
      eventType: 'Test Day',
      startTime: '15:00',
      date: '2026-07-22',
      durationMins: 45,
      location: 'Krieket Field',
      isImportant: true,
      team: 'U16 Academy Elite',
      ageGroup: 'U16',
    ),
    CoachEvent(
      id: '104',
      schoolId: 'sch1',
      title: 'Premier Derby Match',
      eventType: 'Match',
      startTime: '14:00',
      date: '2026-07-22',
      durationMins: 120,
      location: 'Main Stadium',
      isImportant: true,
      team: 'U18 Premier Squad',
      ageGroup: 'U18',
    ),
  ];

  DashboardEventsNotifier(this._apiClient)
      : super(AsyncValue.data(_defaultEvents)) {
    fetchEvents();
  }

  Future<void> fetchEvents({String? ageGroup}) async {
    try {
      final query = ageGroup != null ? '?ageGroup=$ageGroup' : '';
      final response = await _apiClient.getAndCache('/api/dashboard/events$query');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final events = list.map((x) => CoachEvent.fromJson(x)).toList();
        state = AsyncValue.data(events);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e) {
      state = AsyncValue.data([]);
    }
  }

  Future<bool> createEvent({
    required String title,
    required String eventType,
    required String startTime,
    required String date,
    required String location,
    int? durationMins,
    bool isImportant = false,
    String recurrenceRule = 'Does Not Repeat',
    String? workoutImagePath,
    String? ageGroup,
    String? team,
  }) async {
    final eventId = 'EVT-${DateTime.now().millisecondsSinceEpoch}';
    final assignedTeam = team ?? 'U15 Academy Elite';
    final newEvent = CoachEvent(
      id: eventId,
      schoolId: 'sch1',
      title: title,
      eventType: eventType,
      startTime: startTime,
      date: date,
      durationMins: durationMins,
      location: location,
      isImportant: isImportant,
      recurrenceRule: recurrenceRule,
      workoutImagePath: workoutImagePath,
      team: assignedTeam,
      ageGroup: ageGroup ?? 'U15',
    );

    state.whenData((currentList) {
      state = AsyncValue.data([newEvent, ...currentList]);
    });

    try {
      await _apiClient.post('/api/dashboard/events', data: {
        'id': eventId,
        'title': title,
        'eventType': eventType,
        'startTime': startTime,
        'date': date,
        'location': location,
        'durationMins': durationMins,
        'isImportant': isImportant,
        'recurrenceRule': recurrenceRule,
        'workoutImagePath': workoutImagePath,
        'ageGroup': ageGroup ?? 'U15',
        'team': assignedTeam,
      });
    } catch (_) {}
    return true;
  }

  Future<bool> updateEvent(CoachEvent event) async {
    state.whenData((currentList) {
      final updated = currentList.map((e) => e.id.toString() == event.id.toString() ? event : e).toList();
      state = AsyncValue.data(updated);
    });

    try {
      await _apiClient.post('/api/dashboard/events/${event.id}', data: {
        'title': event.title,
        'eventType': event.eventType,
        'startTime': event.startTime,
        'date': event.date,
        'location': event.location,
        'durationMins': event.durationMins,
        'isImportant': event.isImportant,
        'recurrenceRule': event.recurrenceRule,
        'workoutImagePath': event.workoutImagePath,
        'ageGroup': event.ageGroup,
        'team': event.team,
      });
    } catch (_) {}
    return true;
  }

  Future<bool> deleteEvent(dynamic eventId) async {
    final targetIdStr = eventId.toString();
    state.whenData((currentList) {
      final updated = currentList.where((e) => e.id.toString() != targetIdStr).toList();
      state = AsyncValue.data(updated);
    });

    try {
      await _apiClient.post('/api/dashboard/events/$targetIdStr/delete');
    } catch (_) {}
    return true;
  }
}

final dashboardEventsProvider = StateNotifierProvider<DashboardEventsNotifier, AsyncValue<List<CoachEvent>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardEventsNotifier(apiClient);
});
