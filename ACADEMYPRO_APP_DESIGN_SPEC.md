# uSPORT Player Development Tracker — Coach App Design Specification

This specification maps the HTML layouts provided in the design brief (the "Live Match Tracker" and "Coach Command Center") into native **Flutter (Dart)** widgets. It maintains the exact spatial structure, Bento-grid layouts, and tactile interactions, while aligning with the light, sun-optimized color palette.

---

## 1. Design Translation: Color Palette & Theme Mode

To satisfy both the premium look of the design brief and the outdoor readability requirement:
*   **Dual-Theme Architecture:** The app will support both **Light Mode** (default for outdoor field usage under bright sunlight) and **Dark Mode** (for indoor office and review environments).
*   **Color Mapping Table:**

| Style Token | Brief Dark-Mode Hex | uSPORT Light-Mode Hex (Outdoor) | Flutter Color Value |
| :--- | :--- | :--- | :--- |
| **Canvas Background** | `#0D1322` (Deep Navy) | `#F8FAFC` (Slate 50) | `Colors.slate[50]` / `Color(0xFFF8FAFC)` |
| **Surface Container** | `#191F2F` (Dark Grey-Blue) | `#FFFFFF` (White) | `Colors.white` / `Color(0xFFFFFFFF)` |
| **Surface Low** | `#151B2B` | `#F1F5F9` (Slate 100) | `Colors.slate[100]` / `Color(0xFFF1F5F9)` |
| **Primary Accent** | `#B7C4FF` (Periwinkle) | `#2563EB` (Electric Blue) | `Colors.blue[600]` / `Color(0xFF2563EB)` |
| **Secondary Accent** | `#53E16F` (Neon Green) | `#16A34A` (Forest Green) | `Colors.green[600]` / `Color(0xFF16A34A)` |
| **Error / Alert** | `#FFB4AB` (Soft Red) | `#DC2626` (Crimson Red) | `Colors.red[600]` / `Color(0xFFDC2626)` |
| **Warning / Alert** | `#F1C100` (Yellow) | `#D97706` (Amber Orange) | `Colors.amber[600]` / `Color(0xFFD97706)` |

---

## 2. Screen 1: Coach Command Center (Dashboard)

This screen serves as the main hub when a coach opens the app.

```
+-------------------------------------------------------------+
|  uSPORT (Profile)                                       [x] |  <- Header
+-------------------------------------------------------------+
|  ACTIVE COMMAND                                             |
|  [Shield] U16 Academy Elite (v)                             |  <- Team Dropdown Selector
+-------------------------------------------------------------+
|  [ Attendance ]   [ Performance ]   [ Squad Health ]        |
|  [    94%     ]   [   7.2 / 10  ]   [   Optimum    ]        |  <- Bento KPI Cards
+-------------------------------------------------------------+
|  REQUIRES ATTENTION                                         |
|  +-------------------------------------------------------+  |
|  | [!] Leo Silva (Forward #10)                           |  |
|  | Academic Drop: GPA below 60%. Tutoring needed.        |  |  <- Alert Card
|  +-------------------------------------------------------+  |
|  +-------------------------------------------------------+  |
|  | [!] Marcus Reed (Defender #4)                         |  |
|  | Injury Risk: Fatigue spike (1.8x load). Capped mins.  |  |  <- Alert Card
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
|  DAILY UNIT SUMMARY                                         |
|  [ Bar Chart - Load ]     [ Readiness progress bars ]       |  <- Analytics Row
+-------------------------------------------------------------+
|                                                      [FAB]  |  <- Quick Action FAB
+-------------------------------------------------------------+
|  [Dash]      [Roster]      [Match]      [Inbox]      [More] |  <- Bottom Navigation
+-------------------------------------------------------------+
```

### Flutter Widget Tree Blueprint (Command Center)

```dart
class CoachDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: _buildBottomNav(context, activeIndex: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamSelector(context),
            SizedBox(height: 24.0),
            _buildKPIGrid(context),
            SizedBox(height: 24.0),
            _buildFlagsSection(context),
            SizedBox(height: 24.0),
            _buildUnitSummarySection(context),
          ],
        ),
      ),
    );
  }
}
```

*   **Team Dropdown Selector (`_buildTeamSelector`):**
    *   Uses a `MaterialButton` with a custom `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))`.
    *   Displays a custom popup dropdown using `PopupMenuButton` styling to avoid standard system spinners.
*   **Bento KPI Cards (`_buildKPIGrid`):**
    *   Constructed as a `GridView.count` with `crossAxisCount: 3`, `shrinkWrap: true`, and `physics: NeverScrollableScrollPhysics()`.
    *   Tiles use a custom `Card` container (elevation: 0, solid slate/white fill, light outline border).
*   **Alert Cards (`_buildFlagsSection`):**
    *   Horizontal list or static stack of custom `Container` widgets.
    *   Uses a left-hand decorative border decoration:
        ```dart
        border: Border(left: BorderSide(color: Color(0xFFDC2626), width: 4.0))
        ```
    *   Includes action buttons like `RESOLVE ACTION` inside the card itself.

---

## 3. Screen 2: Live Match Tracker

Designed specifically for rapid logging during matches on the sideline.

```
+-------------------------------------------------------------+
| [Rugby] Live Match                       (Timer) 74:12  [X] |  <- Header (w/ End Button)
+-------------------------------------------------------------+
|   [ Tackles: 42 ]      [ Carries: 108 ]     [ Errors: 12 ]  |  <- Bento Stat Summary
+-------------------------------------------------------------+
|  [ All ]    [ Forwards ]    [ Backs ]    [ Subs ]           |  <- Filter Pills
+-------------------------------------------------------------+
|  +---------------------------+ +--------------------------+  |
|  | (Avatar) M. Rashford #10   | | (Avatar) S. Kerr #20    |  |  <- Player Grid
|  |                           | |                          |  |     (2 Columns)
|  | TKL [-]  12  [+] (Blue)   | | TKL [-]  05  [+] (Blue)  |  |
|  | OFF [-]  24  [+] (Green)  | | OFF [-]  31  [+] (Green) |  |  <- Custom Tap Counters
|  | TO  [-]  02  [+] (Red)    | | TO  [-]  04  [+] (Red)   |  |
|  +---------------------------+ +--------------------------+  |
+-------------------------------------------------------------+
|  [Dash]      [Roster]      [Match]      [Inbox]      [More] |  <- Bottom Navigation
+-------------------------------------------------------------+
```

### Flutter Widget Tree Blueprint (Match Tracker)

```dart
class LiveMatchTrackerScreen extends StatefulWidget {
  @override
  _LiveMatchTrackerScreenState createState() => _LiveMatchTrackerScreenState();
}

class _LiveMatchTrackerScreenState extends State<LiveMatchTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildMatchAppBar(context),
      bottomNavigationBar: _buildBottomNav(context, activeIndex: 2),
      body: Column(
        children: [
          _buildBentoStatSummary(context),
          _buildFilterPills(context),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.78, // Adjusts size to fit photo and 3 stat counters
              ),
              itemCount: activePlayers.length,
              itemBuilder: (context, index) => _buildPlayerCard(context, activePlayers[index]),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Counter Clicker Design & Haptic Triggers
To reproduce the instant-feedback feel of the prototype, the increment/decrement buttons are built using specialized tactile controls:

```dart
Widget _buildStatRow({
  required String label,
  required int value,
  required Color activeColor,
  required VoidCallback onIncrement,
  required VoidCallback onDecrement,
}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
    decoration: BoxDecoration(
      color: Colors.slate[100], // Light gray background pill
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.between,
      children: [
        Text(label, style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold)),
        Row(
          children: [
            // Decrement Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDecrement();
              },
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(Icons.remove, size: 14.0),
              ),
            ),
            SizedBox(width: 8.0),
            Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0)),
            SizedBox(width: 8.0),
            // Increment Button
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onIncrement();
              },
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(Icons.add, size: 14.0, color: activeColor),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

---

## 4. Key Performance Optimizations (Sideline-Proof)

1.  **State Management (Riverpod):** The statistics are held in a global `StateNotifier` which optimizes rebuilding only the specific Player Grid tile updating, rather than refreshing the entire grid. This avoids lag on older mobile devices.
2.  **Haptic Triggers:** Tap events bind directly to `HapticFeedback.lightImpact()` (for decrements) and `HapticFeedback.mediumImpact()` (for increments) so coaches don't have to look at the screen to confirm a button was pressed.
3.  **Local Persistence (Hive):** Every tap is immediately written to an offline-first Hive queue. If the phone battery dies or the app crashes, the match progress is preserved up to the last second.
4.  **Auto-Score Async Processing:** The mobile app does not process calculations. It posts the raw counter numbers to the API Worker which returns the calculated Auto-Score asynchronously.
