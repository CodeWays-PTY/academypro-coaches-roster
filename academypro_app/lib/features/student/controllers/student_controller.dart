import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class DynamicTestMetric {
  final String id;
  final String name;
  final String category;
  final String unit;
  final String goalDirection;
  final double targetBenchmark;
  final double initialBaseline;
  final double latestScore;
  final int targetPercent;
  final String trendText;
  final String latestTestDate;
  final String sessionName;

  DynamicTestMetric({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.goalDirection,
    required this.targetBenchmark,
    required this.initialBaseline,
    required this.latestScore,
    required this.targetPercent,
    required this.trendText,
    required this.latestTestDate,
    required this.sessionName,
  });

  factory DynamicTestMetric.fromJson(Map<String, dynamic> json) {
    return DynamicTestMetric(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Test Metric',
      category: json['category'] ?? 'General',
      unit: json['unit'] ?? '',
      goalDirection: json['goalDirection'] ?? 'HIGHER_IS_BETTER',
      targetBenchmark: (json['targetBenchmark'] as num?)?.toDouble() ?? 0.0,
      initialBaseline: (json['initialBaseline'] as num?)?.toDouble() ?? 0.0,
      latestScore: (json['latestScore'] as num?)?.toDouble() ?? 0.0,
      targetPercent: (json['targetPercent'] as num?)?.toInt() ?? 100,
      trendText: json['trendText'] ?? 'Initial',
      latestTestDate: json['latestTestDate'] ?? '',
      sessionName: json['sessionName'] ?? 'Evaluation',
    );
  }
}

class StudentEvent {
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
  final String ageGroup;
  final String team;
  final String? workoutImagePath;

  StudentEvent({
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
    required this.ageGroup,
    required this.team,
    this.workoutImagePath,
  });

  factory StudentEvent.fromJson(Map<String, dynamic> json) {
    return StudentEvent(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId'] ?? '',
      title: json['title'] ?? 'Training Session',
      eventType: json['eventType'] ?? 'Field Session',
      startTime: json['startTime'] ?? '00:00',
      date: json['date'] ?? '',
      durationMins: (json['durationMins'] as num?)?.toInt(),
      location: json['location'] ?? 'Grounds',
      isImportant: json['isImportant'] == true,
      completionCount: (json['completionCount'] as num?)?.toInt(),
      ageGroup: json['ageGroup'] ?? 'U15',
      team: json['team'] ?? '',
      workoutImagePath: json['workoutImagePath'],
    );
  }
}

class StudentSquad {
  final String id;
  final String name;
  final String code;

  StudentSquad({required this.id, required this.name, required this.code});

  factory StudentSquad.fromJson(Map<String, dynamic> json) {
    return StudentSquad(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

class StudentPortalData {
  final Map<String, dynamic> profile;
  final List<dynamic> academics;
  final Map<String, dynamic> fitness;
  final List<DynamicTestMetric> dynamicMetrics;
  final int readinessScore;
  final List<dynamic> matches;
  final List<dynamic> attendance;
  final List<StudentEvent> events;
  final List<StudentSquad> assignedSquads;

  StudentPortalData({
    required this.profile,
    required this.academics,
    required this.fitness,
    required this.dynamicMetrics,
    required this.readinessScore,
    required this.matches,
    required this.attendance,
    required this.events,
    required this.assignedSquads,
  });

  factory StudentPortalData.fromJson(Map<String, dynamic> json) {
    final profileObj = json['profile'] ?? {};
    final fitnessObj = json['fitness'] ?? {};
    final dynamicMetricsRaw = fitnessObj['dynamicMetrics'] as List<dynamic>? ?? [];
    final parsedMetrics = dynamicMetricsRaw
        .map((m) => DynamicTestMetric.fromJson(m as Map<String, dynamic>))
        .toList();

    final int parsedReadiness = (fitnessObj['readinessScore'] as num?)?.toInt() ?? 0;

    final eventsRaw = json['events'] as List<dynamic>? ?? [];
    final parsedEvents = eventsRaw
        .map((e) => StudentEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    final assignedSquadsRaw = profileObj['assignedSquads'] as List<dynamic>? ?? [];
    final parsedSquads = assignedSquadsRaw
        .map((s) => StudentSquad.fromJson(s as Map<String, dynamic>))
        .toList();

    return StudentPortalData(
      profile: profileObj,
      academics: json['academics'] ?? [],
      fitness: fitnessObj,
      dynamicMetrics: parsedMetrics,
      readinessScore: parsedReadiness,
      matches: json['matches'] ?? [],
      attendance: json['attendance'] ?? [],
      events: parsedEvents,
      assignedSquads: parsedSquads,
    );
  }
}

class StudentController extends StateNotifier<AsyncValue<StudentPortalData>> {
  final ApiClient _apiClient;
  Timer? _pollingTimer;
  String? _lastSquadId;

  StudentController(this._apiClient) : super(const AsyncValue.loading()) {
    // Live automatic sync: polls D1 every 8 seconds so new events appear live without pull-to-refresh
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      fetchStudentData(squadId: _lastSquadId, silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchStudentData({String? squadId, bool silent = false}) async {
    _lastSquadId = squadId;
    if (!silent && state.asData?.value == null) {
      state = const AsyncValue.loading();
    }
    try {
      final queryParam = (squadId != null && squadId.isNotEmpty) ? '?squad_id=$squadId' : '';
      final response = await _apiClient.getAndCache('/api/student-portal$queryParam');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = StudentPortalData.fromJson(response.data['data']);
        state = AsyncValue.data(data);
      } else if (!silent) {
        state = AsyncValue.error(response.data['message'] ?? 'Failed to load data', StackTrace.current);
      }
    } catch (err, stack) {
      if (silent) return; // Keep existing UI intact during silent background poll
      String cleanMessage = 'Failed to load dashboard. Please try again.';
      if (err is DioException) {
        if (err.response?.data != null && err.response?.data is Map && err.response?.data['message'] != null) {
          cleanMessage = err.response?.data['message'].toString() ?? cleanMessage;
        } else if (err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.connectionError) {
          cleanMessage = 'Network connection issue. Please check your internet connection.';
        }
      } else {
        cleanMessage = err.toString();
      }
      state = AsyncValue.error(cleanMessage, stack);
    }
  }
}

// Provider for Student Data
final studentControllerProvider = StateNotifierProvider<StudentController, AsyncValue<StudentPortalData>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StudentController(apiClient);
});

// Provider for Active Student Selected Squad ID
final selectedStudentSquadIdProvider = StateProvider<String?>((ref) => null);
