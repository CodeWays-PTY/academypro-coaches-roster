import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../controllers/dashboard_controller.dart';

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
            final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

            // Filter today's events: matches todayStr or matches '2026-07-20' (the seeded date)
            final todayEvents = events.where((e) => e.date == todayStr || e.date == '2026-07-20').toList();
            final upcomingEvents = events.where((e) => e.date != todayStr && e.date != '2026-07-20').toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline Section
                  const Text(
                    'Command Events',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF131B2E),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Schedule and periodization training calendar.',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Color(0xFF434656),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Today's Agenda
                  _buildSectionHeader("TODAY'S AGENDA"),
                  const SizedBox(height: 12.0),
                  if (todayEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No sessions scheduled for today.',
                        style: TextStyle(color: Color(0xFF737688), fontSize: 13.0),
                      ),
                    )
                  else
                    ...todayEvents.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildEventCard(context, event),
                        )),

                  const SizedBox(height: 24.0),

                  // Upcoming Events
                  _buildSectionHeader("UPCOMING EVENTS"),
                  const SizedBox(height: 12.0),
                  if (upcomingEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No upcoming events scheduled.',
                        style: TextStyle(color: Color(0xFF737688), fontSize: 13.0),
                      ),
                    )
                  else
                    ...upcomingEvents.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildEventCard(context, event),
                        )),
                  const SizedBox(height: 24.0),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 48.0),
                  const SizedBox(height: 12.0),
                  Text(
                    'Failed to load calendar events.\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFBA1A1A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF737688),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8.0),
        const Expanded(
          child: Divider(color: Color(0xFFC3C5D9), thickness: 0.8),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, CoachEvent event) {
    Color leftBorderColor;
    Color badgeBgColor;
    Color badgeTextColor;
    IconData iconData;
    String badgeText = event.eventType;

    switch (event.eventType) {
      case 'Field Session':
        leftBorderColor = const Color(0xFF003EC7);
        badgeBgColor = const Color(0xFFDDE1FF);
        badgeTextColor = const Color(0xFF0038B6);
        iconData = Icons.sports_soccer;
        break;
      case 'Match Day':
        leftBorderColor = const Color(0xFF22C55E);
        badgeBgColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF166534);
        iconData = Icons.sports_score_outlined;
        break;
      case 'Development':
        leftBorderColor = const Color(0xFF952200);
        badgeBgColor = const Color(0xFFFFDBD2);
        badgeTextColor = const Color(0xFF891E00);
        iconData = Icons.meeting_room;
        break;
      case 'Gym Session':
      default:
        leftBorderColor = const Color(0xFF505F76);
        badgeBgColor = const Color(0xFFD3E4FE);
        badgeTextColor = const Color(0xFF38485D);
        iconData = Icons.fitness_center;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Details for "${event.title}" session'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFC3C5D9).withOpacity(0.3),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: leftBorderColor, width: 4.0),
              ),
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
                      child: Text(
                        badgeText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (event.isImportant)
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20.0)
                    else if (event.eventType != 'Field Session')
                      Text(
                        event.startTime,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: leftBorderColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 10.0),
                if (event.eventType == 'Field Session') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF505F76), size: 16.0),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                '${event.location}  •  ${event.startTime}',
                                style: const TextStyle(fontSize: 12.0, color: Color(0xFF505F76)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        width: 60.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3C5D9).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: 0.75,
                          child: Container(
                            decoration: BoxDecoration(
                              color: leftBorderColor,
                              borderRadius: BorderRadius.circular(999.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: Color(0xFF003EC7), size: 16.0),
                          const SizedBox(width: 2.0),
                          Text(
                            event.intensity ?? 'High',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003EC7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else if (event.eventType == 'Gym Session') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(iconData, color: const Color(0xFF505F76), size: 16.0),
                          const SizedBox(width: 6.0),
                          Text(
                            event.location,
                            style: const TextStyle(fontSize: 12.0, color: Color(0xFF505F76)),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(3, (index) {
                          final count = event.completionCount ?? 0;
                          final isFilled = index < count;
                          return Padding(
                            padding: const EdgeInsets.only(left: 3.0),
                            child: Icon(
                              Icons.circle,
                              size: 14.0,
                              color: isFilled ? const Color(0xFF505F76) : const Color(0xFFC3C5D9),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            event.eventType == 'Development' ? Icons.meeting_room : Icons.location_on,
                            color: const Color(0xFF505F76),
                            size: 16.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            event.location,
                            style: const TextStyle(fontSize: 12.0, color: Color(0xFF505F76)),
                          ),
                        ],
                      ),
                      Text(
                        event.startTime,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: leftBorderColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
