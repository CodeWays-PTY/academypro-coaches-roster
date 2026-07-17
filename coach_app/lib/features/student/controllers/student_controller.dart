import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_state.dart';

class StudentPortalData {
  final Map<String, dynamic> profile;
  final List<dynamic> academics;
  final Map<String, dynamic> fitness;
  final List<dynamic> matches;
  final List<dynamic> attendance;

  StudentPortalData({
    required this.profile,
    required this.academics,
    required this.fitness,
    required this.matches,
    required this.attendance,
  });

  factory StudentPortalData.fromJson(Map<String, dynamic> json) {
    return StudentPortalData(
      profile: json['profile'] ?? {},
      academics: json['academics'] ?? [],
      fitness: json['fitness'] ?? {},
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
