# Comprehensive Audit Report: `academypro_app/lib/features/`

**Audit Target**: `academypro_app/lib/features/` (`auth`, `dashboard`, `notifications`, `parent`, `student`)  
**Auditor**: Explorer M2_1 (`teamwork_preview_explorer`)  
**Date**: 2026-08-03  

---

## 1. Executive Summary

A comprehensive audit was performed across all 27 files in `academypro_app/lib/features/` and cross-referenced against the entire Flutter application codebase (`academypro_app/lib/`).

### Summary of Findings:
- **Unused/Unreferenced Screen & Modal Files**: **2 Files**
  1. `features/dashboard/presentation/add_player_modal.dart` (`AddPlayerModal`)
  2. `features/dashboard/presentation/create_squad_modal.dart` (`CreateSquadModal`)
- **Dead/Orphaned Controller Methods**: **4 Methods**
  1. `CheckInNotifier.resetSession()` in `features/dashboard/controllers/checkin_controller.dart` (line 300)
  2. `CheckInNotifier.changeSessionType(String)` in `features/dashboard/controllers/checkin_controller.dart` (line 138)
  3. `RosterNotifier.addPlayer(...)` in `features/dashboard/controllers/roster_controller.dart` (line 247)
  4. `NotificationNotifier.sendTestNotification(...)` in `features/notifications/controllers/notification_controller.dart` (line 139)
- **Unused Riverpod Providers**: **1 Provider**
  1. `playerActionTasksProvider` in `features/dashboard/controllers/dashboard_controller.dart` (line 606)
- **Unused State Variables & Data Model Properties**: **4 Properties**
  1. `AuthState.devOtp` in `features/auth/presentation/auth_state.dart` (line 11)
  2. `NotificationItem.actionRoute` in `features/notifications/models/notification_item.dart` (line 10)
  3. `CoachEvent.completionCount` in `features/dashboard/controllers/dashboard_controller.dart` (line 626)
  4. `StudentEvent.completionCount` in `features/student/controllers/student_controller.dart` (line 63)

---

## 2. Detailed Findings with Proof of Non-Usage

### 2.1 Unreferenced / Dead Modal Widget Files

#### 1. `features/dashboard/presentation/add_player_modal.dart`
- **Class**: `AddPlayerModal` (lines 9–395)
- **Observation**: File exists in filesystem at `c:\Development\academypro\academypro_app\lib\features\dashboard\presentation\add_player_modal.dart`.
- **Proof of Non-Usage**: 
  - Cross-reference search for `add_player_modal.dart` across all files in `academypro_app/lib/` returned **0 import statements**.
  - `AddPlayerModal` is only referenced within `add_player_modal.dart` itself.
  - The app uses `AddExistingPlayerModal` (`add_existing_player_modal.dart`) in `roster_tab_view.dart:238` instead.
- **Recommendation**: Safe to delete `add_player_modal.dart`.

#### 2. `features/dashboard/presentation/create_squad_modal.dart`
- **Class**: `CreateSquadModal` (lines 10–363)
- **Observation**: File exists in filesystem at `c:\Development\academypro\academypro_app\lib\features\dashboard\presentation\create_squad_modal.dart`.
- **Proof of Non-Usage**: 
  - Cross-reference search for `create_squad_modal.dart` across `academypro_app/lib/` returned **0 import statements**.
  - `CreateSquadModal` is only referenced within `create_squad_modal.dart` itself.
  - Squad creation is handled directly in `roster_tab_view.dart` inline bottom sheets or admin flows.
- **Recommendation**: Safe to delete `create_squad_modal.dart`.

---

### 2.2 Dead / Orphaned Controller Methods & Riverpod Providers

#### 1. `CheckInNotifier.resetSession()`
- **File & Location**: `features/dashboard/controllers/checkin_controller.dart`, lines 300–306
- **Code**:
  ```dart
  void resetSession() {
    final updatedMap = <String, CheckInPlayerRecord>{};
    state.playerRecords.forEach((id, record) {
      updatedMap[id] = record.copyWith(isCheckedIn: false, checkInTime: null);
    });
    state = state.copyWith(playerRecords: updatedMap);
  }
  ```
- **Proof of Non-Usage**: `resetSession` is defined on line 300 of `checkin_controller.dart`, but is never invoked anywhere across `academypro_app/lib/`.

#### 2. `CheckInNotifier.changeSessionType(String)`
- **File & Location**: `features/dashboard/controllers/checkin_controller.dart`, lines 138–140
- **Code**:
  ```dart
  void changeSessionType(String sessionType) {
    state = state.copyWith(sessionType: sessionType);
  }
  ```
- **Proof of Non-Usage**: `changeSessionType` is defined on line 138 of `checkin_controller.dart`, but is never called by `checkin_tab_view.dart` or any other UI component.

#### 3. `RosterNotifier.addPlayer(...)`
- **File & Location**: `features/dashboard/controllers/roster_controller.dart`, lines 247–290
- **Code**:
  ```dart
  Future<bool> addPlayer({
    required String firstName,
    required String lastName,
    required String ageGroup,
    required String position,
    required String team,
  }) async { ... }
  ```
- **Proof of Non-Usage**: The only invocation of `addPlayer` is on line 75 of `add_player_modal.dart`, which is itself an unreferenced dead file (see Section 2.1). `addPlayer` is not used anywhere else in the app.

#### 4. `NotificationNotifier.sendTestNotification(...)`
- **File & Location**: `features/notifications/controllers/notification_controller.dart`, lines 139–155
- **Code**:
  ```dart
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'system',
  }) async { ... }
  ```
- **Proof of Non-Usage**: Defined on line 139 of `notification_controller.dart`, but never called anywhere in the UI or app controllers.

#### 5. `playerActionTasksProvider`
- **File & Location**: `features/dashboard/controllers/dashboard_controller.dart`, lines 606–614
- **Code**:
  ```dart
  final playerActionTasksProvider = Provider.family<List<CoachActionItem>, String?>((ref, playerId) {
    final allActions = ref.watch(coachActionProvider);
    if (playerId == null || playerId.isEmpty) {
      return allActions;
    }
    return allActions.where((item) =>
        item.playerId == playerId ||
        item.playerName.toLowerCase().contains(playerId.toLowerCase())).toList();
  });
  ```
- **Proof of Non-Usage**: Defined on line 606 of `dashboard_controller.dart`, but never watched or read in any presentation widget or screen.

---

### 2.3 Obsolete / Unused Data Model Properties & State Variables

#### 1. `AuthState.devOtp`
- **File & Location**: `features/auth/presentation/auth_state.dart`, lines 11, 18, 38, 45, 73
- **Proof of Non-Usage**: `devOtp` is populated inside `sendOtp()` (`auth_state.dart:73`), but no screen (including `login_screen.dart`) reads `authState.devOtp`.

#### 2. `NotificationItem.actionRoute`
- **File & Location**: `features/notifications/models/notification_item.dart`, lines 10, 20, 32, 44, 54
- **Proof of Non-Usage**: Parsed in `fromJson` (`notification_item.dart:32`), but `NotificationsPanel` (`notifications_panel.dart`) never checks or triggers `actionRoute` upon tapping a notification.

#### 3. `CoachEvent.completionCount`
- **File & Location**: `features/dashboard/controllers/dashboard_controller.dart`, lines 626, 642, 659, 675, 694
- **Proof of Non-Usage**: Parsed from API response, but never rendered in `events_tab_view.dart` or any dashboard view.

#### 4. `StudentEvent.completionCount`
- **File & Location**: `features/student/controllers/student_controller.dart`, lines 63, 78, 95
- **Proof of Non-Usage**: Parsed from API JSON, but never rendered in `student_dashboard_screen.dart`.

---

## 3. Inventory of Active Feature Files Verified

All remaining 25 files in `features/` were verified as actively used and correctly wired up:

| Subfolder | File Path | Status | Verification Reference |
|---|---|---|---|
| `auth/presentation` | `auth_state.dart` | Active | Used in `login_screen.dart`, `coach_welcome_wizard_screen.dart`, `dashboard_screen.dart` |
| `auth/presentation` | `coach_welcome_wizard_screen.dart` | Active | Used in `login_screen.dart:99`, `main.dart:102` |
| `auth/presentation` | `login_screen.dart` | Active | Main login entry point used in `main.dart:93`, `profile_tab_view.dart`, `parent_dashboard_screen.dart`, `student_dashboard_screen.dart` |
| `dashboard/controllers` | `checkin_controller.dart` | Active | Used in `checkin_tab_view.dart`, `qr_scanner_modal.dart` |
| `dashboard/controllers` | `dashboard_controller.dart` | Active | Used in `dashboard_screen.dart`, `events_tab_view.dart`, `roster_tab_view.dart`, `student_dashboard_screen.dart` |
| `dashboard/controllers` | `roster_controller.dart` | Active | Used in `roster_tab_view.dart`, `manage_player_squads_modal.dart`, `add_existing_player_modal.dart` |
| `dashboard/presentation` | `add_existing_player_modal.dart` | Active | Used in `roster_tab_view.dart:238` |
| `dashboard/presentation` | `batch_test_logger_modal.dart` | Active | Used in `dashboard_screen.dart:251`, `events_tab_view.dart:570` |
| `dashboard/presentation` | `checkin_tab_view.dart` | Active | Used in `dashboard_screen.dart:159` |
| `dashboard/presentation` | `create_action_modal.dart` | Active | Used in `dashboard_screen.dart:1098`, `roster_tab_view.dart:1021` |
| `dashboard/presentation` | `create_event_modal.dart` | Active | Used in `events_tab_view.dart:121, 646` |
| `dashboard/presentation` | `dashboard_screen.dart` | Active | Main Coach Dashboard screen |
| `dashboard/presentation` | `events_tab_view.dart` | Active | Used in `dashboard_screen.dart:161` |
| `dashboard/presentation` | `manage_metrics_modal.dart` | Active | Used in `dashboard_screen.dart:267` |
| `dashboard/presentation` | `manage_player_squads_modal.dart` | Active | Used in `roster_tab_view.dart:848` |
| `dashboard/presentation` | `profile_tab_view.dart` | Active | Used in `dashboard_screen.dart:163` |
| `dashboard/presentation` | `qr_scanner_modal.dart` | Active | Used in `checkin_tab_view.dart:357` |
| `dashboard/presentation` | `roster_tab_view.dart` | Active | Used in `dashboard_screen.dart:157` |
| `dashboard/presentation` | `single_player_baseline_modal.dart` | Active | Used in `roster_tab_view.dart:958` |
| `notifications/controllers` | `notification_controller.dart` | Active | Used in `notifications_panel.dart`, `parent_dashboard_screen.dart`, `student_dashboard_screen.dart` |
| `notifications/models` | `notification_item.dart` | Active | Used in `notification_controller.dart`, `notifications_panel.dart` |
| `notifications/presentation` | `notifications_panel.dart` | Active | Used in `dashboard_screen.dart`, `student_dashboard_screen.dart`, `parent_dashboard_screen.dart` |
| `parent/presentation` | `parent_dashboard_screen.dart` | Active | Main Parent Dashboard screen |
| `student/controllers` | `student_controller.dart` | Active | Used in `student_dashboard_screen.dart`, `parent_dashboard_screen.dart` |
| `student/presentation` | `student_dashboard_screen.dart` | Active | Main Student Dashboard screen |

---

## 4. Verification Method

To independently verify these findings:

1. **Unused File Verification**:
   ```powershell
   # Run ripgrep on file imports/references
   rg "add_player_modal" c:\Development\academypro\academypro_app\lib
   rg "create_squad_modal" c:\Development\academypro\academypro_app\lib
   ```
   Both commands return 0 results outside their own file declarations.

2. **Dead Controller Method Verification**:
   ```powershell
   rg "resetSession" c:\Development\academypro\academypro_app\lib
   rg "changeSessionType" c:\Development\academypro\academypro_app\lib
   rg "sendTestNotification" c:\Development\academypro\academypro_app\lib
   rg "playerActionTasksProvider" c:\Development\academypro\academypro_app\lib
   ```
   Each query returns exactly 1 result (its definition line in the controller).

3. **Compilation Check**:
   Run `flutter analyze` or `flutter check` from `academypro_app/`.
