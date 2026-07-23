import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/checkin_controller.dart';
import 'create_event_modal.dart';

class EventsTabView extends ConsumerStatefulWidget {
  const EventsTabView({Key? key}) : super(key: key);

  @override
  ConsumerState<EventsTabView> createState() => _EventsTabViewState();
}

class _EventsTabViewState extends ConsumerState<EventsTabView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final selectedAge = ref.read(selectedAgeGroupProvider);
      ref.read(dashboardEventsProvider.notifier).fetchEvents(ageGroup: selectedAge);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedAge = ref.watch(selectedAgeGroupProvider);

    ref.listen<String>(selectedAgeGroupProvider, (previous, next) {
      if (previous != next) {
        ref.read(dashboardEventsProvider.notifier).fetchEvents(ageGroup: next);
      }
    });

    final eventsState = ref.watch(dashboardEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardEventsProvider.notifier).fetchEvents(ageGroup: selectedAge);
        },
        child: eventsState.when(
          data: (events) {
            final now = DateTime.now();
            final todayStr = DateFormat('yyyy-MM-dd').format(now);

            // Filter today's events vs upcoming events dynamically
            final todayEvents = events.where((e) => e.date == todayStr).toList();
            final upcomingEvents = events.where((e) => e.date != todayStr).toList();

            todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
            upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===================================================================
                  // 1. CLEAN HEADER (Fixed layout, no text collision)
                  // ===================================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Events & Schedule',
                              style: TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              'Manage training sessions, gym tests & matches',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          CreateEventModal.show(context);
                        },
                        icon: const Icon(Icons.add, size: 18.0),
                        label: const Text('Add Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003EC7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  // ===================================================================
                  // 2. TODAY'S EVENTS SECTION
                  // ===================================================================
                  const Text(
                    "TODAY'S SCHEDULE",
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  if (todayEvents.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_busy, color: Color(0xFF94A3B8), size: 36.0),
                          SizedBox(height: 8.0),
                          Text(
                            'No sessions scheduled for today',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayEvents.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        return _buildEventCard(context, todayEvents[index]);
                      },
                    ),

                  const SizedBox(height: 24.0),

                  // ===================================================================
                  // 3. UPCOMING EVENTS SECTION
                  // ===================================================================
                  const Text(
                    'UPCOMING SESSIONS',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  if (upcomingEvents.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No upcoming events scheduled',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingEvents.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12.0),
                      itemBuilder: (context, index) {
                        return _buildEventCard(context, upcomingEvents[index]);
                      },
                    ),

                  const SizedBox(height: 32.0),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load events: $err',
              style: const TextStyle(color: Color(0xFFBA1A1A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CoachEvent event) {
    Color leftBorderColor = const Color(0xFF003EC7);
    Color badgeBgColor = const Color(0xFFDBEAFE);
    Color badgeTextColor = const Color(0xFF1D4ED8);
    IconData iconData = Icons.sports_soccer;
    String badgeText = event.eventType;

    switch (event.eventType) {
      case 'Field':
      case 'Field Session':
        leftBorderColor = const Color(0xFF003EC7);
        badgeBgColor = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF1D4ED8);
        iconData = Icons.sports_soccer;
        badgeText = 'Field';
        break;
      case 'Gym':
      case 'Gym Session':
        leftBorderColor = const Color(0xFF7C3AED);
        badgeBgColor = const Color(0xFFF3E8FF);
        badgeTextColor = const Color(0xFF6B21A8);
        iconData = Icons.fitness_center;
        badgeText = 'Gym';
        break;
      case 'Test Day':
        leftBorderColor = const Color(0xFFD97706);
        badgeBgColor = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFF92400E);
        iconData = Icons.timer_outlined;
        badgeText = 'Test Day';
        break;
      case 'Match':
      case 'Match Day':
        leftBorderColor = const Color(0xFF166534);
        badgeBgColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF15803D);
        iconData = Icons.sports_score;
        badgeText = 'Match';
        break;
      default:
        leftBorderColor = const Color(0xFF003EC7);
        badgeBgColor = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF1D4ED8);
        iconData = Icons.sports_soccer;
        break;
    }

    return InkWell(
      onTap: () => _showEventDetailsBottomSheet(context, event),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Category Indicator Accent Bar
              Container(
                width: 6.0,
                decoration: BoxDecoration(
                  color: leftBorderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    bottomLeft: Radius.circular(16.0),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Category Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    Icon(iconData, size: 13.0, color: badgeTextColor),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      badgeText.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.bold,
                                        color: badgeTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              // Team Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield_outlined, size: 12.0, color: Color(0xFF003EC7)),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      event.team,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (event.isImportant)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  margin: const EdgeInsets.only(right: 6.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.star, color: Color(0xFFD97706), size: 12.0),
                                      SizedBox(width: 4.0),
                                      Text(
                                        'IMPORTANT',
                                        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                      ),
                                    ],
                                  ),
                                ),
                              const Icon(Icons.arrow_forward_ios, size: 14.0, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14.0, color: Color(0xFF64748B)),
                          const SizedBox(width: 6.0),
                          Text(
                            '${event.startTime} • ${event.date} (${event.durationMins ?? 60}m)',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12.0),
                          const Icon(Icons.location_on_outlined, size: 14.0, color: Color(0xFF64748B)),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(fontSize: 12.0, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (event.workoutImagePath != null && event.eventType != 'Match') ...[
                        const SizedBox(height: 10.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo, color: Color(0xFF166534), size: 13.0),
                              SizedBox(width: 6.0),
                              Text(
                                'Workout Photo Attached',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetailsBottomSheet(BuildContext context, CoachEvent event) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, MediaQuery.of(context).padding.bottom + 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                '${event.eventType} • ${event.startTime} • ${event.location}',
                style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20.0),

              // View Workout Photo Button (Only when photo exists and NOT on Match Days)
              if (event.workoutImagePath != null && event.eventType != 'Match') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showWorkoutImageDialog(context, event.workoutImagePath!);
                    },
                    icon: const Icon(Icons.photo, size: 18.0),
                    label: const Text('View Workout Routine Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
              ],

              // Start Practice Check-In CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(checkInProvider.notifier).selectEvent(event);
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 18.0),
                  label: const Text('Start Practice Check-In For This Event', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003EC7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        CreateEventModal.show(context, eventToEdit: event);
                      },
                      icon: const Icon(Icons.edit, size: 16.0),
                      label: const Text('Edit Event'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(dashboardEventsProvider.notifier).deleteEvent(event.id);
                      },
                      icon: const Icon(Icons.delete, size: 16.0, color: Color(0xFFEF4444)),
                      label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 8.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Workout Routine Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: imagePath.startsWith('assets/')
                    ? Image.asset(imagePath, fit: BoxFit.contain)
                    : Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
