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
        attendancePercent: 100,
        teamPerformanceAvg: 0.0,
        totalPlayers: 0,
        uniReady: 0,
        onTrack: 0,
        atRisk: 0,
        danger: 0,
        flagged: 0,
        loading: true,
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

  Future<void> fetchSummary() async {
    state = state.copyWith(loading: true);
    try {
      final response = await _apiClient.getAndCache('/api/dashboard/summary');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final kpis = data['kpis'];

        state = state.copyWith(
          attendancePercent: data['attendancePercent'] ?? 100,
          teamPerformanceAvg: (data['teamPerformanceAvg'] as num?)?.toDouble() ?? 0.0,
          totalPlayers: kpis['totalPlayers'] ?? 0,
          uniReady: kpis['uniReady'] ?? 0,
          onTrack: kpis['onTrack'] ?? 0,
          atRisk: kpis['atRisk'] ?? 0,
          danger: kpis['danger'] ?? 0,
          flagged: kpis['flagged'] ?? 0,
          loading: false,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to fetch metrics summary',
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

  DashboardFlagsNotifier(this._apiClient) : super(const AsyncValue.loading());

  Future<void> fetchFlags() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getAndCache('/api/dashboard/flags');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'];
        final flags = list.map((x) => FlaggedPlayer.fromJson(x)).toList();
        state = AsyncValue.data(flags);
      }
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
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
  });

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
    );
  }
}

class DashboardEventsNotifier extends StateNotifier<AsyncValue<List<CoachEvent>>> {
  final ApiClient _apiClient;

  DashboardEventsNotifier(this._apiClient) : super(const AsyncValue.loading());

  Future<void> fetchEvents() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getAndCache('/api/dashboard/events');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final events = list.map((x) => CoachEvent.fromJson(x)).toList();
        state = AsyncValue.data(events);
      } else {
        state = AsyncValue.error(response.data['message'] ?? 'Failed to fetch events', StackTrace.current);
      }
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final dashboardEventsProvider = StateNotifierProvider<DashboardEventsNotifier, AsyncValue<List<CoachEvent>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardEventsNotifier(apiClient);
});
