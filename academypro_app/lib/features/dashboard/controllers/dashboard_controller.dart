import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
        totalPlayers: 26,
        uniReady: 16,
        onTrack: 7,
        atRisk: 3,
        danger: 0,
        flagged: 1,
        loading: false,
      );
    } else if (ageGroup == 'U18') {
      state = state.copyWith(
        attendancePercent: 98,
        teamPerformanceAvg: 4.7,
        totalPlayers: 30,
        uniReady: 22,
        onTrack: 6,
        atRisk: 2,
        danger: 0,
        flagged: 1,
        loading: false,
      );
    } else {
      state = state.copyWith(
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
    }
  }
}

// Flags Controller representing Flagged Players
class FlaggedPlayer {
  final String id;
  final String firstName;
  final String lastName;
  final String ageGroup;
  final String position;
  final String team;
  final String flagReason;
  final String severity;
  final double avgGrade;
  final double? latestScore;

  FlaggedPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.ageGroup,
    required this.position,
    required this.team,
    required this.flagReason,
    required this.severity,
    required this.avgGrade,
    this.latestScore,
  });

  factory FlaggedPlayer.fromJson(Map<String, dynamic> json) {
    return FlaggedPlayer(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      ageGroup: json['ageGroup'] ?? '',
      position: json['position'] ?? '',
      team: json['team'] ?? '',
      flagReason: json['flagReason'] ?? '',
      severity: json['severity'] ?? '',
      avgGrade: (json['avgGrade'] as num?)?.toDouble() ?? 0.0,
      latestScore: (json['latestScore'] as num?)?.toDouble(),
    );
  }
}

class DashboardFlagsNotifier extends StateNotifier<AsyncValue<List<FlaggedPlayer>>> {
  final ApiClient _apiClient;

  DashboardFlagsNotifier(this._apiClient)
      : super(AsyncValue.data(_defaultFlags));

  static final List<FlaggedPlayer> _defaultFlags = [
    FlaggedPlayer(
      id: 'p3',
      firstName: 'Imaneul',
      lastName: 'Venter',
      ageGroup: 'U15',
      position: 'Lock',
      team: 'U15 Academy Elite',
      flagReason: 'Declining academic grades (-10%) & missed rehabilitative gym sessions',
      severity: 'Warning',
      avgGrade: 58.0,
      latestScore: 3.2,
    ),
    FlaggedPlayer(
      id: 'p5',
      firstName: 'Kalimamba',
      lastName: 'Zulu',
      ageGroup: 'U15',
      position: 'Prop',
      team: 'U15 Academy Elite',
      flagReason: 'Disciplinary suspension, attendance drop (-18%) & academic alert',
      severity: 'Critical',
      avgGrade: 52.0,
      latestScore: 2.8,
    ),
    FlaggedPlayer(
      id: 'p6',
      firstName: 'Devon',
      lastName: 'Smith',
      ageGroup: 'U16',
      position: 'Center',
      team: 'U16 Academy Elite',
      flagReason: 'Academic alert in Physical Science (-12%) & missed conditioning',
      severity: 'Warning',
      avgGrade: 61.0,
      latestScore: 3.4,
    ),
    FlaggedPlayer(
      id: 'p7',
      firstName: 'Marcus',
      lastName: 'van Zyl',
      ageGroup: 'U18',
      position: 'Scrum-half',
      team: 'U18 Premier Squad',
      flagReason: 'Knee rehab assignment check & tactical playbook review overdue',
      severity: 'Critical',
      avgGrade: 64.0,
      latestScore: 3.6,
    ),
  ];

  Future<void> fetchFlags({String? ageGroup}) async {
    try {
      final endpoint = ageGroup != null ? '/api/dashboard/flags?ageGroup=$ageGroup' : '/api/dashboard/flags';
      final response = await _apiClient.getAndCache(endpoint);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'];
        final flags = list.map((x) => FlaggedPlayer.fromJson(x)).toList();
        state = AsyncValue.data(flags);
      }
    } catch (err) {
      // Retain current data on fallback
    }
  }
}

/// Rising Star Player Model with strict 5-week consistency gatekeeper rule
class RisingStarPlayer {
  final String id;
  final String firstName;
  final String lastName;
  final String ageGroup;
  final String position;
  final String team;
  final double gradeAverage;
  final double gradeImprovement; // e.g. +5.5%
  final double attendancePercent;
  final double attendanceImprovement; // e.g. +3.0%
  final int gymConsistencyWeeks; // Must be >= 5
  final double gymProgressPercent; // e.g. +12.0%
  final bool isGradesUp;
  final bool isAttendanceUp;
  final bool isGymConsistent;

  RisingStarPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.ageGroup,
    required this.position,
    required this.team,
    required this.gradeAverage,
    required this.gradeImprovement,
    required this.attendancePercent,
    required this.attendanceImprovement,
    required this.gymConsistencyWeeks,
    required this.gymProgressPercent,
    required this.isGradesUp,
    required this.isAttendanceUp,
    required this.isGymConsistent,
  });

  /// STRICT QUALIFICATION GATEKEEPER:
  /// ONLY qualified if Grades ARE UP, Attendance IS UP, and Gym improvement is consistent for AT LEAST 5 WEEKS!
  bool get isQualifiedForRisingStar =>
      isGradesUp && isAttendanceUp && isGymConsistent && gymConsistencyWeeks >= 5;

  factory RisingStarPlayer.fromJson(Map<String, dynamic> json) {
    return RisingStarPlayer(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      ageGroup: json['ageGroup'] ?? '',
      position: json['position'] ?? '',
      team: json['team'] ?? '',
      gradeAverage: (json['gradeAverage'] as num?)?.toDouble() ?? 0.0,
      gradeImprovement: (json['gradeImprovement'] as num?)?.toDouble() ?? 0.0,
      attendancePercent: (json['attendancePercent'] as num?)?.toDouble() ?? 0.0,
      attendanceImprovement: (json['attendanceImprovement'] as num?)?.toDouble() ?? 0.0,
      gymConsistencyWeeks: json['gymConsistencyWeeks'] is int
          ? json['gymConsistencyWeeks']
          : int.tryParse(json['gymConsistencyWeeks']?.toString() ?? '0') ?? 0,
      gymProgressPercent: (json['gymProgressPercent'] as num?)?.toDouble() ?? 0.0,
      isGradesUp: json['isGradesUp'] == true,
      isAttendanceUp: json['isAttendanceUp'] == true,
      isGymConsistent: json['isGymConsistent'] == true,
    );
  }
}

class RisingStarsNotifier extends StateNotifier<AsyncValue<List<RisingStarPlayer>>> {
  final ApiClient _apiClient;

  RisingStarsNotifier(this._apiClient)
      : super(AsyncValue.data(_defaultStars));

  static final List<RisingStarPlayer> _defaultStars = [
    RisingStarPlayer(
      id: 'p1',
      firstName: 'Alex',
      lastName: 'Henderson',
      ageGroup: 'U15',
      position: 'Flanker',
      team: 'U15 Academy Elite',
      gradeAverage: 88.0,
      gradeImprovement: 6.5,
      attendancePercent: 98.0,
      attendanceImprovement: 4.0,
      gymConsistencyWeeks: 5,
      gymProgressPercent: 14.0,
      isGradesUp: true,
      isAttendanceUp: true,
      isGymConsistent: true,
    ),
    RisingStarPlayer(
      id: 'p2',
      firstName: 'Bibi',
      lastName: 'Achuma',
      ageGroup: 'U15',
      position: 'Fly-half',
      team: 'U15 Academy Elite',
      gradeAverage: 92.5,
      gradeImprovement: 4.0,
      attendancePercent: 99.0,
      attendanceImprovement: 3.5,
      gymConsistencyWeeks: 6,
      gymProgressPercent: 12.5,
      isGradesUp: true,
      isAttendanceUp: true,
      isGymConsistent: true,
    ),
    RisingStarPlayer(
      id: 'p8',
      firstName: 'Liam',
      lastName: 'Naidoo',
      ageGroup: 'U16',
      position: 'Fly-half',
      team: 'U16 Academy Elite',
      gradeAverage: 89.0,
      gradeImprovement: 5.0,
      attendancePercent: 97.0,
      attendanceImprovement: 3.0,
      gymConsistencyWeeks: 6,
      gymProgressPercent: 15.0,
      isGradesUp: true,
      isAttendanceUp: true,
      isGymConsistent: true,
    ),
    RisingStarPlayer(
      id: 'p9',
      firstName: 'Francois',
      lastName: 'du Plessis',
      ageGroup: 'U18',
      position: 'Lock',
      team: 'U18 Premier Squad',
      gradeAverage: 94.0,
      gradeImprovement: 7.0,
      attendancePercent: 100.0,
      attendanceImprovement: 5.0,
      gymConsistencyWeeks: 7,
      gymProgressPercent: 18.0,
      isGradesUp: true,
      isAttendanceUp: true,
      isGymConsistent: true,
    ),
  ];

  Future<void> fetchRisingStars({String? ageGroup}) async {
    try {
      final endpoint = ageGroup != null ? '/api/dashboard/rising-stars?ageGroup=$ageGroup' : '/api/dashboard/rising-stars';
      final response = await _apiClient.getAndCache(endpoint);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'];
        final players = list.map((x) => RisingStarPlayer.fromJson(x)).toList();
        state = AsyncValue.data(players);
      }
    } catch (err) {
      // Retain fallback list
    }
  }
}

/// Coach Custom Action Item Model (Defined BY THE COACH)
class CoachActionItem {
  final String id;
  final String playerId;
  final String playerName;
  final String title;
  final String category;
  final String dateAdded;
  final bool isCompleted;

  CoachActionItem({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.title,
    required this.category,
    required this.dateAdded,
    this.isCompleted = false,
  });

  CoachActionItem copyWith({
    String? id,
    String? playerId,
    String? playerName,
    String? title,
    String? category,
    String? dateAdded,
    bool? isCompleted,
  }) {
    return CoachActionItem(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      title: title ?? this.title,
      category: category ?? this.category,
      dateAdded: dateAdded ?? this.dateAdded,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class CoachActionNotifier extends StateNotifier<List<CoachActionItem>> {
  CoachActionNotifier()
      : super([
          CoachActionItem(
            id: 'act1',
            playerId: 'p3',
            playerName: 'Imaneul Venter',
            title: 'Arrange 1-on-1 Science Tutor & Rehab Progress Review',
            category: 'School & Rehab',
            dateAdded: '2026-07-18',
            isCompleted: false,
          ),
          CoachActionItem(
            id: 'act2',
            playerId: 'p5',
            playerName: 'Kalimamba Zulu',
            title: 'Parent Conference & Study Hall Attendance Check',
            category: 'Parent Consultation',
            dateAdded: '2026-07-20',
            isCompleted: false,
          ),
        ]);

  void addAction({
    required String playerId,
    required String playerName,
    required String title,
    required String category,
  }) {
    final newItem = CoachActionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerId: playerId,
      playerName: playerName,
      title: title,
      category: category,
      dateAdded: DateTime.now().toString().split(' ')[0],
      isCompleted: false,
    );
    state = [newItem, ...state];
  }

  void toggleAction(String actionId) {
    state = state.map((item) {
      if (item.id == actionId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();
  }
}

// Providers
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
  return CoachActionNotifier();
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
  final int id;
  final String schoolId;
  final String title;
  final String eventType;
  final String startTime;
  final String date;
  final int? durationMins;
  final String location;
  final String? intensity;
  final bool isImportant;
  final int? completionCount;
  final String recurrenceRule;

  CoachEvent({
    required this.id,
    required this.schoolId,
    required this.title,
    required this.eventType,
    required this.startTime,
    required this.date,
    this.durationMins,
    required this.location,
    this.intensity,
    required this.isImportant,
    this.completionCount,
    this.recurrenceRule = 'Does Not Repeat',
  });

  CoachEvent copyWith({
    int? id,
    String? schoolId,
    String? title,
    String? eventType,
    String? startTime,
    String? date,
    int? durationMins,
    String? location,
    String? intensity,
    bool? isImportant,
    int? completionCount,
    String? recurrenceRule,
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
      intensity: intensity ?? this.intensity,
      isImportant: isImportant ?? this.isImportant,
      completionCount: completionCount ?? this.completionCount,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }

  factory CoachEvent.fromJson(Map<String, dynamic> json) {
    return CoachEvent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      schoolId: json['schoolId'] ?? '',
      title: json['title'] ?? '',
      eventType: json['eventType'] ?? '',
      startTime: json['startTime'] ?? '',
      date: json['date'] ?? '',
      durationMins: json['durationMins'] != null ? (json['durationMins'] as num).toInt() : null,
      location: json['location'] ?? '',
      intensity: json['intensity'],
      isImportant: json['isImportant'] == true,
      completionCount: json['completionCount'] != null ? (json['completionCount'] as num).toInt() : null,
      recurrenceRule: json['recurrenceRule'] ?? 'Does Not Repeat',
    );
  }
}

class DashboardEventsNotifier extends StateNotifier<AsyncValue<List<CoachEvent>>> {
  final ApiClient _apiClient;

  DashboardEventsNotifier(this._apiClient)
      : super(AsyncValue.data(_defaultEvents));

  static final List<CoachEvent> _defaultEvents = [
    CoachEvent(
      id: 101,
      schoolId: 'sch1',
      title: 'High-Intensity Contact & Offload Drills',
      eventType: 'Field Session',
      startTime: '16:30',
      date: '2026-07-21',
      durationMins: 90,
      location: 'Primary Oval Field 1',
      intensity: 'High',
      isImportant: false,
      completionCount: 2,
    ),
    CoachEvent(
      id: 102,
      schoolId: 'sch1',
      title: 'Power Hypertrophy & Core Conditioning',
      eventType: 'Gym Session',
      startTime: '07:00',
      date: '2026-07-21',
      durationMins: 60,
      location: 'High Performance Center',
      intensity: 'Medium',
      isImportant: false,
      completionCount: 3,
    ),
    CoachEvent(
      id: 103,
      schoolId: 'sch1',
      title: 'Tactical Playbook Video Session & Analysis',
      eventType: 'Development',
      startTime: '15:00',
      date: '2026-07-24',
      durationMins: 45,
      location: 'Seminar Room 1',
      intensity: 'Low',
      isImportant: false,
    ),
    CoachEvent(
      id: 104,
      schoolId: 'sch1',
      title: 'Premier Derby Match vs Grey College',
      eventType: 'Match Day',
      startTime: '14:00',
      date: '2026-07-27',
      durationMins: 120,
      location: 'Main Stadium Pitch',
      intensity: 'High',
      isImportant: true,
    ),
    CoachEvent(
      id: 105,
      schoolId: 'sch1',
      title: 'Active Hydrotherapy & Lower Body Rehab',
      eventType: 'Development',
      startTime: '09:30',
      date: '2026-07-30',
      durationMins: 60,
      location: 'Pool & Hydro Facility',
      intensity: 'Low',
      isImportant: false,
    ),
  ];

  Future<void> fetchEvents() async {
    try {
      final response = await _apiClient.getAndCache('/api/dashboard/events');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final events = list.map((x) => CoachEvent.fromJson(x)).toList();
        state = AsyncValue.data(events);
      }
    } catch (err) {
      // Retain cached default events state
    }
  }

  Future<bool> createEvent({
    required String title,
    required String eventType,
    required String startTime,
    required String date,
    required String location,
    int? durationMins,
    String? intensity,
    bool isImportant = false,
    String recurrenceRule = 'Does Not Repeat',
    List<int>? repeatDaysOfWeek,
  }) async {
    final currentEvents = state.value ?? _defaultEvents;
    final int baseId = DateTime.now().millisecondsSinceEpoch % 100000;
    final List<CoachEvent> newEvents = [];

    // Parse base date
    DateTime baseDate = DateTime.tryParse(date) ?? DateTime.now();

    if (recurrenceRule != 'Does Not Repeat' && repeatDaysOfWeek != null && repeatDaysOfWeek.isNotEmpty) {
      // Generate events for selected days of week over 4 weeks
      int addedCount = 0;
      for (int dayOffset = 0; dayOffset < 28; dayOffset++) {
        final DateTime targetDate = baseDate.add(Duration(days: dayOffset));
        if (repeatDaysOfWeek.contains(targetDate.weekday)) {
          final String instanceDateStr =
              "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
          newEvents.add(CoachEvent(
            id: baseId + addedCount,
            schoolId: 'sch1',
            title: title,
            eventType: eventType,
            startTime: startTime,
            date: instanceDateStr,
            location: location,
            durationMins: durationMins,
            intensity: intensity,
            isImportant: isImportant,
            recurrenceRule: recurrenceRule,
          ));
          addedCount++;
        }
      }
    } else {
      int count = 1;
      int intervalDays = 0;
      if (recurrenceRule == 'Every Day') {
        count = 7;
        intervalDays = 1;
      } else if (recurrenceRule == 'Every Week') {
        count = 4;
        intervalDays = 7;
      } else if (recurrenceRule == 'Every 2 Weeks') {
        count = 4;
        intervalDays = 14;
      } else if (recurrenceRule == 'Every Month') {
        count = 3;
        intervalDays = 30;
      }

      for (int i = 0; i < count; i++) {
        final DateTime instanceDate = baseDate.add(Duration(days: i * intervalDays));
        final String instanceDateStr =
            "${instanceDate.year}-${instanceDate.month.toString().padLeft(2, '0')}-${instanceDate.day.toString().padLeft(2, '0')}";

        newEvents.add(CoachEvent(
          id: baseId + i,
          schoolId: 'sch1',
          title: title,
          eventType: eventType,
          startTime: startTime,
          date: instanceDateStr,
          location: location,
          durationMins: durationMins,
          intensity: intensity,
          isImportant: isImportant,
          recurrenceRule: recurrenceRule,
        ));
      }
    }

    state = AsyncValue.data([...newEvents, ...currentEvents]);

    try {
      await _apiClient.post('/api/dashboard/events', data: {
        'title': title,
        'eventType': eventType,
        'startTime': startTime,
        'date': date,
        'location': location,
        'durationMins': durationMins,
        'intensity': intensity,
        'isImportant': isImportant,
        'recurrenceRule': recurrenceRule,
      });
    } catch (_) {}

    return true;
  }

  Future<bool> updateEvent(CoachEvent updatedEvent) async {
    final currentEvents = state.value ?? _defaultEvents;
    final updatedList = currentEvents.map((e) => e.id == updatedEvent.id ? updatedEvent : e).toList();
    state = AsyncValue.data(updatedList);

    try {
      await _apiClient.post('/api/dashboard/events/update', data: {
        'id': updatedEvent.id,
        'title': updatedEvent.title,
        'eventType': updatedEvent.eventType,
        'startTime': updatedEvent.startTime,
        'date': updatedEvent.date,
        'location': updatedEvent.location,
        'durationMins': updatedEvent.durationMins,
        'intensity': updatedEvent.intensity,
        'isImportant': updatedEvent.isImportant,
        'recurrenceRule': updatedEvent.recurrenceRule,
      });
    } catch (_) {}

    return true;
  }

  Future<bool> deleteEvent(int eventId) async {
    final currentEvents = state.value ?? _defaultEvents;
    final updatedList = currentEvents.where((e) => e.id != eventId).toList();
    state = AsyncValue.data(updatedList);

    try {
      await _apiClient.post('/api/dashboard/events/delete', data: {'id': eventId});
    } catch (_) {}

    return true;
  }
}

final dashboardEventsProvider = StateNotifierProvider<DashboardEventsNotifier, AsyncValue<List<CoachEvent>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardEventsNotifier(apiClient);
});
