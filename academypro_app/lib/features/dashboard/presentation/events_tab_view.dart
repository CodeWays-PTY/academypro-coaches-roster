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
      ref.read(dashboardEventsProvider.notifier).fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(dashboardEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardEventsProvider.notifier).fetchEvents();
        },
        child: eventsState.when(
          data: (events) {
            final now = DateTime.now();
            final todayStr = DateFormat('yyyy-MM-dd').format(now);

            // Filter today's events: matches todayStr or matches '2026-07-22'
            final todayEvents = events.where((e) => e.date == todayStr || e.date == '2026-07-22').toList();
            final upcomingEvents = events.where((e) => e.date != todayStr && e.date != '2026-07-22').toList();

            todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
            upcomingEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Command Events',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF131B2E),
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'Schedule and periodization training calendar.',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Color(0xFF434656),
                              ),
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
                        label: const Text('Add Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003EC7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24.0),

                  // Today's Events Section
                  const Text(
                    "TODAY'S SCHEDULED EVENTS",
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12.0),

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
                          Icon(Icons.event_available, color: Color(0xFF64748B), size: 36.0),
                          SizedBox(height: 8.0),
                          Text(
                            'No scheduled events for today',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14.0, fontWeight: FontWeight.w500),
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
                      itemBuilder: (ctx, i) => _buildEventCard(context, todayEvents[i]),
                    ),

                  const SizedBox(height: 28.0),

                  // Upcoming Events Section
                  if (upcomingEvents.isNotEmpty) ...[
                    const Text(
                      'UPCOMING EVENTS',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcomingEvents.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12.0),
                      itemBuilder: (ctx, i) => _buildEventCard(context, upcomingEvents[i]),
                    ),
                  ],

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: leftBorderColor, width: 5.0)),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconData, color: badgeTextColor, size: 13.0),
                          const SizedBox(width: 4.0),
                          Text(
                            badgeText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              color: badgeTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: leftBorderColor, size: 14.0),
                        const SizedBox(width: 4.0),
                        Text(
                          '${event.startTime} (${event.durationMins ?? 90}m)',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: leftBorderColor,
                          ),
                        ),
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
                    const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 14.0),
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
                if (event.workoutAttachmentName != null) ...[
                  const SizedBox(height: 10.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attachment, color: Color(0xFF2563EB), size: 13.0),
                        const SizedBox(width: 6.0),
                        Text(
                          event.workoutAttachmentName!,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetailsBottomSheet(BuildContext context, CoachEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              '${event.eventType} • ${event.startTime} • ${event.location}',
              style: const TextStyle(fontSize: 13.0, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20.0),

            // Start Practice Check-In CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(checkInProvider.notifier).selectEvent(event);
                },
                icon: const Icon(Icons.qr_code_scanner, size: 18.0),
                label: const Text('Start Practice Check-In For This Event'),
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
    );
  }
}
