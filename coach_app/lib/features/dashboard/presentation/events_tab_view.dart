import 'package:flutter/material.dart';

class EventsTabView extends StatelessWidget {
  const EventsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Command Events',
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Schedule and periodization training calendar.',
            style: TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24.0),

          // Timeline View
          _buildSectionHeader('TODAY\'S AGENDA'),
          const SizedBox(height: 12.0),
          _buildEventCard(
            'Tactical Periodization',
            '16:30 • Pitch 4 • 90 min',
            'Tactical movement drills & defensive block setups.',
            'FIELD SESSION',
            const Color(0xFF2563EB),
            Icons.sports_soccer,
          ),
          const SizedBox(height: 24.0),

          _buildSectionHeader('UPCOMING EVENTS'),
          const SizedBox(height: 12.0),
          _buildEventCard(
            'League Match: vs. Pretoria Boys High',
            'Sat, 10:00 AM • West Field Complex',
            'Jersey: Home Blue. Arrival: 09:00 AM.',
            'MATCH DAY',
            const Color(0xFF05B046),
            Icons.sports_score_outlined,
            isImportant: true,
          ),
          const SizedBox(height: 12.0),
          _buildEventCard(
            'Spiritual Character Dev (uGroup)',
            'Wed, 18:00 PM • Youth Hall',
            'Group discussion on leadership and integrity.',
            'uGROUPS DEV',
            const Color(0xFF952200),
            Icons.church_outlined,
          ),
          const SizedBox(height: 12.0),
          _buildEventCard(
            'Gym Strength Baselines Check',
            'Mon, 06:00 AM • High Performance Gym',
            'Squats & Pull-Ups PBs check-ins.',
            'GYM SESSION',
            const Color(0xFF64748B),
            Icons.fitness_center_outlined,
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8.0),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _buildEventCard(
    String title,
    String timeLoc,
    String desc,
    String badgeText,
    Color themeColor,
    IconData icon, {
    bool isImportant = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isImportant ? themeColor.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: isImportant ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: themeColor, width: 4.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isImportant)
                      const Icon(Icons.star, color: Color(0xFFD97706), size: 18.0),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Icon(Icons.access_time_filled, color: const Color(0xFF64748B), size: 14.0),
                    const SizedBox(width: 6.0),
                    Text(
                      timeLoc,
                      style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13.0, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
