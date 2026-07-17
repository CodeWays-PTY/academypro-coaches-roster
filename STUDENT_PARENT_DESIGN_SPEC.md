# uSPORT Player Development Tracker — Student & Parent Portal Design Specification

This specification translates the HTML blueprints provided in the design brief (the "Student Journey Dashboard" and "Parent Overview") into native **Flutter (Dart)** widgets. It establishes structural patterns, layout containers, and metrics visualizers, aligning them with the unified uSPORT dual-theme design system.

---

## 1. Screen 1: Student Journey Dashboard

Designed as a personal development summary for student-athletes.

```
+-------------------------------------------------------------+
|  uSPORT (Profile)                                       [!] |  <- Top App Bar w/ Notification
+-------------------------------------------------------------+
|  +-------------------------------------------------------+  |
|  | ZONE ACTIVE                        98TH PERCENTILE    |  |
|  | Green Zone                                            |  |  <- Hero Performance Card
|  | You're currently tracking at University Ready.       |  |
|  |                                                       |  |
|  | CURRENT RANK: A+    |   RECRUIT READINESS: 94%        |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
|  PORTALS                                                    |
|  [ Mind - GPA 3.9 ]  [ Body - VO2 54 ]  [ Spirit - Lvl 12 ] |  <- Mind/Body/Spirit Cards
+-------------------------------------------------------------+
|  [Star] SMALL WINS                                          |
|  +---------------------------+ +--------------------------+  |
|  | PHYSICAL MILESTONE        | | ACADEMIC GAIN            |  |
|  | New PB in Squats          | | Calculus Quiz            |  |  <- Small Wins Bento Items
|  | +5kg this week     [Icon] | | +4% improvement   [Icon] |  |
|  +---------------------------+ +--------------------------+  |
+-------------------------------------------------------------+
|  WEEKLY VOLUME                                42.5 HRS TOTAL|
|  Training vs Academics balance                              |  <- Weekly Progress Chart
|  [Mon] [Tue] [Wed] [Thu] [Fri] [Sat] [Sun] (Bar Chart)      |
+-------------------------------------------------------------+
|  [Dash]      [Roster]      [Match]      [Inbox]      [More] |  <- Bottom Navigation
+-------------------------------------------------------------+
```

### Flutter Widget Tree Blueprint (Student Dashboard)

```dart
class StudentDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNav(context, activeIndex: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroStatusCard(context),
            SizedBox(height: 24.0),
            _buildPortalCardsGrid(context),
            SizedBox(height: 24.0),
            _buildSmallWinsSection(context),
            SizedBox(height: 24.0),
            _buildWeeklyVolumeChart(context),
          ],
        ),
      ),
    );
  }
}
```

*   **Weekly Volume Chart (`_buildWeeklyVolumeChart`):**
    *   Utilizes the `fl_chart` package (`BarChart`) to build custom vertical bars.
    *   Individual bar items use `BarChartGroupData` with dynamic heights and custom hover interactions (`BarChartRodData` with specific rounded corners and active color changes).
*   **Small Wins Bento Cards:**
    *   Constructed using a `Row` container containing two equal-width `Expanded` cards.
    *   Cards use `BoxDecoration` with a thick left-hand border indicator to visually separate categories (Body is Green, Mind is Blue, Spirit is Gold).
        ```dart
        border: Border(left: BorderSide(color: Color(0xFF16A34A), width: 4.0))
        ```

---

## 2. Screen 2: Parent Portal Overview

Designed to give parents quick updates, upcoming schedule tickets, and "peace of mind" telemetry.

```
+-------------------------------------------------------------+
|  uSPORT (Profile Avatar)                                [!] |  <- Top App Bar
+-------------------------------------------------------------+
|  +-------------------------------------------------------+  |
|  | -- LEO'S PERFORMANCE HUB                              |  |
|  | On Track [Verified]                                   |  |  <- Parent Hero status
|  | Leo is meeting U15 Elite Development benchmarks.      |  |
|  | SQUAD RANK: #4/24   |   CONSISTENCY: 94%              |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
|  +----------------------------+  DEVELOPMENT METRICS        |
|  | TICKET: Sat, 10:00 AM      |  +-----------------------+  |  <- Match Ticket on Left
|  | West Field Complex         |  | Academics             |  |  <- Development Progress
|  | Court 4 - Home Jersey      |  | GPA 3.8 Stable [==== ]|  |     bars on Right
|  | [ ADD TO CALENDAR ]        |  +-----------------------+  |
|  +----------------------------+                             |
+-------------------------------------------------------------+
|  PEACE OF MIND                                              |
|  +-------------------------------------------------------+  |
|  | IMAGE: Coach & Player High-Five                       |  |  <- Premium Coach Report Card
|  | Sarah (Head Coach): "Leo showed leadership today..."  |  |
|  +-------------------------------------------------------+  |
|  +-------------------------------------------------------+  |
|  | Facility Checkout                                     |  |  <- Real-Time Security Logs
|  | Checkout facility 4:15 PM  |  Status: Safe            |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
|                                                   [FAB-CALL]|  <- Floating Help/Contact Button
+-------------------------------------------------------------+
|  [Overview]  [Roster]      [Match]      [Inbox]      [More] |  <- Bottom Navigation
+-------------------------------------------------------------+
```

### Flutter Widget Tree Blueprint (Parent Portal)

```dart
class ParentOverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildParentAppBar(context),
      floatingActionButton: _buildContactSupportFAB(context),
      bottomNavigationBar: _buildBottomNav(context, activeIndex: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildParentHeroStatus(context),
            SizedBox(height: 24.0),
            // Flex row layout (Ticket on Left, Development bars on Right on Tablet/Desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildMatchTicket(context)),
                      SizedBox(width: 16.0),
                      Expanded(flex: 7, child: _buildDevelopmentMetrics(context)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildMatchTicket(context),
                      SizedBox(height: 20.0),
                      _buildDevelopmentMetrics(context),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 24.0),
            _buildPeaceOfMindSection(context),
          ],
        ),
      ),
    );
  }
}
```

### Custom Match Ticket Widget (`_buildMatchTicket`)

Constructed in Flutter to match the custom curved border ticket visual:
*   Uses a `ClipPath` with a custom `Path` shape clipper that punches semi-circular holes in the left and right borders:

```dart
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 8.0; // Hole size
    final cutoutY = size.height - 76.0; // Position of the ticket cut

    path.lineTo(0.0, cutoutY - radius);
    path.arcToPoint(
      Offset(0.0, cutoutY + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, cutoutY + radius);
    path.arcToPoint(
      Offset(size.width, cutoutY - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
```

### Multi-Segment Progress Indicator (`_buildDevelopmentMetrics`)

Builds the horizontal segmented score bars:
*   The segmented indicators are drawn using `Row` containing several `Expanded` block boxes.
*   Active segments use the category accent color (`Colors.green`), while inactive ones use the base background color (`Colors.slate[200]`).

```dart
Widget _buildSegmentedProgress({required int activeSegments, required Color activeColor}) {
  return Row(
    children: List.generate(5, (index) {
      final isActive = index < activeSegments;
      return Expanded(
        child: Container(
          height: 6.0,
          margin: EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: isActive ? activeColor : activeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      );
    }),
  );
}
```

---

## 3. Real-Time Security Feeds & Telemetry

The "Peace of Mind" feed connects directly to D1 table logs.
*   **Checkout Alerts:** Uses a simple card containing checkout details, timestamp (e.g., `4:15 PM`), status icon, and safe/active flags.
*   **Coach Report Cards:** Features a rounded image container stacked under text blocks, rendering coach feedback. Images are cached locally using the `cached_network_image` package to save mobile bandwidth.
