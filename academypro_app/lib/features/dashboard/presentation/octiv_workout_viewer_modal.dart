import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/dashboard_controller.dart';

class OctivWorkoutViewerModal extends StatelessWidget {
  final CoachEvent event;

  const OctivWorkoutViewerModal({Key? key, required this.event}) : super(key: key);

  static Future<void> show(BuildContext context, CoachEvent event) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => OctivWorkoutViewerModal(event: event),
    );
  }

  List<Widget> _buildFormattedWorkoutLines(String rawText) {
    final lines = rawText.split('\n');
    final List<Widget> widgets = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10.0));
        continue;
      }

      // Check Octiv-style headers (e.g. Part A:, EFFORT, Into, Measure:)
      if (trimmed.startsWith('Part ') || trimmed.endsWith(':')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
            child: Text(
              trimmed,
              style: const TextStyle(
                color: Color(0xFF10B981), // Octiv Neon Green Accent
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else if (trimmed.toUpperCase() == trimmed && trimmed.length > 2 && !trimmed.contains('|')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: Text(
              trimmed,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              trimmed,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      } else if (trimmed.toLowerCase() == 'into') {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Into',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Text(
              trimmed,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final workoutContent = event.workoutText ??
        '''Part A:
EFFORT
Measure: Time (Speed)
IN PAIRS:

200/150 | 250/200 | 300/250 Calorie Machine

Into

10 Rounds | You Go I Go (5 each)
3-5 Devils Press
6-10 Box Step or Jump Overs

Into

8 Rounds | You Go, I Go (4 each)
8-12 Dumbbell Push Press
6-12 Shuttle Runs (7.5m)

(Cap: 40 Minutes)

*single or dual dumbbell Devils Press & Push Press''';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF111827), // Octiv Dark Mode Surface
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Top Drag Handle & Location Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 16.0, 8.0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF9CA3AF), size: 18.0),
                          const SizedBox(width: 6.0),
                          Text(
                            event.location,
                            style: const TextStyle(
                              color: Color(0xFFF9FAFB),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1F2937)),

            // Octiv Navigation Header Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Workout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          event.eventType.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Programmes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            height: 3.0,
                            width: 90.0,
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24.0),
                      const Text(
                        'My Workouts',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFF1F2937)),

            // Main Formatted Octiv Workout Routine Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${event.date} • ${event.startTime} (${event.durationMins ?? 60} Mins)',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildFormattedWorkoutLines(workoutContent),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar (Copy Routine to Clipboard)
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: workoutContent));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF065F46),
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18.0),
                            SizedBox(width: 8.0),
                            Text('Workout routine copied to clipboard!'),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18.0),
                  label: const Text(
                    'Copy Workout Routine',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
