# Handoff Report — Explorer M2_1 (Flutter Features Audit)

## 1. Observation

### 1.1 Unreferenced / Dead Modal Files:
- **`academypro_app/lib/features/dashboard/presentation/add_player_modal.dart`**:
  - Contains class `AddPlayerModal` (lines 9–395).
  - Search command: `grep_search(Query: "add_player_modal.dart")` -> `0 results`.
  - Search command: `grep_search(Query: "AddPlayerModal")` -> Only matches lines within `add_player_modal.dart` itself.
- **`academypro_app/lib/features/dashboard/presentation/create_squad_modal.dart`**:
  - Contains class `CreateSquadModal` (lines 10–363).
  - Search command: `grep_search(Query: "create_squad_modal.dart")` -> `0 results`.
  - Search command: `grep_search(Query: "CreateSquadModal")` -> Only matches lines within `create_squad_modal.dart` itself.

### 1.2 Dead / Orphaned Controller Methods & Providers:
- **`CheckInNotifier.resetSession()`**:
  - File: `academypro_app/lib/features/dashboard/controllers/checkin_controller.dart:300`
  - Search command: `grep_search(Query: "resetSession")` -> Exactly 1 match (definition line 300).
- **`CheckInNotifier.changeSessionType(String)`**:
  - File: `academypro_app/lib/features/dashboard/controllers/checkin_controller.dart:138`
  - Search command: `grep_search(Query: "changeSessionType")` -> Exactly 1 match (definition line 138).
- **`RosterNotifier.addPlayer(...)`**:
  - File: `academypro_app/lib/features/dashboard/controllers/roster_controller.dart:247`
  - Search command: `grep_search(Query: "addPlayer(")` -> Exactly 2 matches: declaration on line 247 and call on line 75 of dead file `add_player_modal.dart`.
- **`NotificationNotifier.sendTestNotification(...)`**:
  - File: `academypro_app/lib/features/notifications/controllers/notification_controller.dart:139`
  - Search command: `grep_search(Query: "sendTestNotification")` -> Exactly 1 match (definition line 139).
- **`playerActionTasksProvider`**:
  - File: `academypro_app/lib/features/dashboard/controllers/dashboard_controller.dart:606`
  - Search command: `grep_search(Query: "playerActionTasksProvider")` -> Exactly 1 match (definition line 606).

### 1.3 Unused State Variables & Model Properties:
- **`AuthState.devOtp`**: File `features/auth/presentation/auth_state.dart:11`. Populated in `sendOtp` but never read in any UI screen.
- **`NotificationItem.actionRoute`**: File `features/notifications/models/notification_item.dart:10`. Parsed from JSON but never handled in notification onTap.
- **`CoachEvent.completionCount`**: File `features/dashboard/controllers/dashboard_controller.dart:626`. Parsed from JSON but never rendered.
- **`StudentEvent.completionCount`**: File `features/student/controllers/student_controller.dart:63`. Parsed from JSON but never rendered.

---

## 2. Logic Chain

1. **Step 1**: All 27 Dart files under `academypro_app/lib/features/` (`auth`, `dashboard`, `notifications`, `parent`, `student`) were listed and individually inspected using `view_file`.
2. **Step 2**: Every exported class, widget, modal, controller method, provider, state property, and helper was extracted.
3. **Step 3**: Using project-wide `grep_search` across `academypro_app/lib/`, each symbol was cross-referenced to verify if it is imported, instantiated, or invoked in any active widget or controller.
4. **Step 4**: `AddPlayerModal` and `CreateSquadModal` were confirmed to have zero imports/instantiations in any active feature or core file.
5. **Step 5**: Controller methods (`resetSession`, `changeSessionType`, `sendTestNotification`, `addPlayer`) and provider `playerActionTasksProvider` were confirmed to have zero callers/watchers outside declarations.
6. **Step 6**: Unused model properties (`devOtp`, `actionRoute`, `completionCount`) were confirmed to be write-only (set or parsed, but never read in UI).

---

## 3. Caveats

- **API Compatibility**: Model properties such as `completionCount`, `devOtp`, and `actionRoute` are parsed from remote JSON APIs. While they are dead on the Flutter client side, removing them from Dart models is safe, but server API response structure does not depend on their removal.
- **Read-Only Scope**: In compliance with Explorer role rules, no source code files in `academypro_app/lib/` were modified or deleted.

---

## 4. Conclusion

- **Unused Files to Remove**: 2 files (`features/dashboard/presentation/add_player_modal.dart`, `features/dashboard/presentation/create_squad_modal.dart`).
- **Dead Controller Code to Refactor/Clean**: 4 controller methods (`resetSession`, `changeSessionType`, `addPlayer`, `sendTestNotification`) and 1 provider (`playerActionTasksProvider`).
- **Clean Model Properties**: `AuthState.devOtp`, `NotificationItem.actionRoute`, `CoachEvent.completionCount`, `StudentEvent.completionCount`.
- Full findings documented in `c:\Development\academypro\.agents\explorer_m2_1\flutter_features_audit.md`.

---

## 5. Verification Method

1. Inspect `c:\Development\academypro\.agents\explorer_m2_1\flutter_features_audit.md`.
2. Re-run ripgrep searches across `academypro_app/lib`:
   - `grep_search(Query: "add_player_modal.dart", SearchPath: "c:\\Development\\academypro\\academypro_app\\lib")` -> 0 results
   - `grep_search(Query: "create_squad_modal.dart", SearchPath: "c:\\Development\\academypro\\academypro_app\\lib")` -> 0 results
   - `grep_search(Query: "resetSession", SearchPath: "c:\\Development\\academypro\\academypro_app\\lib")` -> 1 result
   - `grep_search(Query: "changeSessionType", SearchPath: "c:\\Development\\academypro\\academypro_app\\lib")` -> 1 result
   - `grep_search(Query: "playerActionTasksProvider", SearchPath: "c:\\Development\\academypro\\academypro_app\\lib")` -> 1 result
   - `grep_search(Query: "sendTestNotification", SearchPath: "c:\\Development\\academypro\\academypro_app\\lib")` -> 1 result
