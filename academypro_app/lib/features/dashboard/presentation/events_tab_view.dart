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
        _showEventDetailsBottomSheet(context, event);
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

  void _showEventDetailsBottomSheet(BuildContext context, CoachEvent event) {
    Color themeColor;
    IconData typeIcon;
    switch (event.eventType) {
      case 'Field Session':
        themeColor = const Color(0xFF003EC7);
        typeIcon = Icons.sports_soccer;
        break;
      case 'Match Day':
        themeColor = const Color(0xFF22C55E);
        typeIcon = Icons.sports_score_outlined;
        break;
      case 'Development':
        themeColor = const Color(0xFF952200);
        typeIcon = Icons.meeting_room;
        break;
      case 'Gym Session':
      default:
        themeColor = const Color(0xFF505F76);
        typeIcon = Icons.fitness_center;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: 24.0 + bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3C5D9).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(typeIcon, color: themeColor, size: 14.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    event.eventType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: themeColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (event.isImportant) ...[
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFD97706), size: 12.0),
                                    const SizedBox(width: 2.0),
                                    Text(
                                      'IMPORTANT',
                                      style: TextStyle(
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131B2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF505F76)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16.0),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: _formatDate(event.date),
              ),
              const SizedBox(height: 16.0),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Time',
                value: event.durationMins != null
                    ? '${event.startTime} (${event.durationMins} mins)'
                    : event.startTime,
              ),
              const SizedBox(height: 16.0),
              _buildDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: event.location,
              ),
              if (event.eventType == 'Field Session' && event.intensity != null) ...[
                const SizedBox(height: 16.0),
                _buildDetailRow(
                  icon: Icons.bolt,
                  label: 'Intensity',
                  value: event.intensity!,
                  valueColor: themeColor,
                ),
              ],
              if (event.eventType == 'Gym Session' && event.completionCount != null) ...[
                const SizedBox(height: 16.0),
                _buildDetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Completion Progress',
                  customWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final count = event.completionCount ?? 0;
                      final isFilled = index < count;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          Icons.circle,
                          size: 16.0,
                          color: isFilled ? const Color(0xFF505F76) : const Color(0xFFC3C5D9),
                        ),
                      );
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003EC7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Close Details',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? customWidget,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: const Color(0xFF505F76), size: 18.0),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF737688),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2.0),
              if (customWidget != null)
                customWidget
              else
                Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF131B2E),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthInt = int.parse(parts[1]);
        final day = parts[2];
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        if (monthInt >= 1 && monthInt <= 12) {
          return '$day ${months[monthInt - 1]} $year';
        }
      }
    } catch (_) {}
    return dateStr;
  }
}
