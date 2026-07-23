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

class StudentPortalData {
  final Map<String, dynamic> profile;
  final List<dynamic> academics;
  final Map<String, dynamic> fitness;
  final List<DynamicTestMetric> dynamicMetrics;
  final int readinessScore;
  final List<dynamic> matches;
  final List<dynamic> attendance;

  StudentPortalData({
    required this.profile,
    required this.academics,
    required this.fitness,
    required this.dynamicMetrics,
    required this.readinessScore,
    required this.matches,
    required this.attendance,
  });

  factory StudentPortalData.fromJson(Map<String, dynamic> json) {
    final fitnessObj = json['fitness'] ?? {};
    final dynamicMetricsRaw = fitnessObj['dynamicMetrics'] as List<dynamic>? ?? [];
    final parsedMetrics = dynamicMetricsRaw
        .map((m) => DynamicTestMetric.fromJson(m as Map<String, dynamic>))
        .toList();

    final int parsedReadiness = (fitnessObj['readinessScore'] as num?)?.toInt() ?? 88;

    return StudentPortalData(
      profile: json['profile'] ?? {},
      academics: json['academics'] ?? [],
      fitness: fitnessObj,
      dynamicMetrics: parsedMetrics,
      readinessScore: parsedReadiness,
      matches: json['matches'] ?? [],
      attendance: json['attendance'] ?? [],
    );
  }
}

class StudentController extends StateNotifier<AsyncValue<StudentPortalData>> {
  final ApiClient _apiClient;

  StudentController(this._apiClient) : super(const AsyncValue.loading());

  Future<void> fetchStudentData() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.getAndCache('/api/student-portal');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = StudentPortalData.fromJson(response.data['data']);
        state = AsyncValue.data(data);
      } else {
        state = AsyncValue.error(response.data['message'] ?? 'Failed to load data', StackTrace.current);
      }
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

// Provider for Student Data
final studentControllerProvider = StateNotifierProvider<StudentController, AsyncValue<StudentPortalData>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StudentController(apiClient);
});
