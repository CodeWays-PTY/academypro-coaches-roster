# Changes Log — Worker 3 (Milestone 3: Flutter Mobile App Remediation)

## Summary of Changes

### 1. Centralized Dynamic Configuration (`lib/core/config/app_config.dart`)
- **New File**: Created `AppConfig` class providing configurable variables:
  - `academicHonorCutoff`: `65.0`
  - `academicPassCutoff`: `60.0`
  - `academicWarningCutoff`: `50.0`
  - `ratingHighThreshold`: `4.0`
  - `ratingMidThreshold`: `3.0`
  - `ratingLowThreshold`: `2.0`
  - `gradeImprovementDefault`: `0`
  - `sportIdentifier`: `'sports'`

### 2. Global Toast & Context Handling (`lib/core/utils/app_toast.dart` & `lib/main.dart`)
- Added `static final GlobalKey<NavigatorState> navigatorKey` to `AppToast`.
- Configured `MaterialApp(navigatorKey: AppToast.navigatorKey)` in `lib/main.dart`.
- Updated `AppToast.showError`, `showSuccess`, and `showInfo` to accept `BuildContext? context`, falling back to `navigatorKey.currentContext` when `context` is `null`.

### 3. Clean Empty States for Fallbacks (Task 1)
- `lib/features/student/presentation/student_dashboard_screen.dart`: Replaced `'Jan'`, `'Mentz'`, `'OVK-STUDENT-JAN'`, and `'OVK-ATHLETE'` default fallbacks with clean empty states `"--"`.
- `lib/features/dashboard/presentation/dashboard_screen.dart`: Replaced `'Jan-Albert'` and `'Mentz'` fallbacks with clean empty states `"--"`.
- `lib/features/dashboard/controllers/roster_controller.dart`: Replaced `'OVK-'` fallback ID generation with clean ID format `'$ageGroup-${DateTime.now().millisecondsSinceEpoch}'`.

### 4. Controller Remediation & Failure Toasting (Task 2)
- `lib/features/dashboard/controllers/roster_controller.dart`:
  - Removed silent `catch (_)` swallowing in `updatePlayerSquads`, `fetchSchoolPlayers`, `addPlayerToSquad`, `removePlayerFromSquad`, `updatePlayerPosition`, and `addPlayer`.
  - Added error logging with `print(...)` and error notification via `AppToast.showError(...)`.
  - Updated `addPlayer` to return `false` on network exception rather than returning hardcoded `true`.
- `lib/features/dashboard/controllers/dashboard_controller.dart`:
  - Removed silent `catch (_)` swallowing in `fetchSummary`, `fetchActions`, `addAction`, `toggleAction`, `fetchSquads`, and `createSquad`.
  - Added error logging and `AppToast.showError(...)` alerts.
- `lib/features/notifications/controllers/notification_controller.dart`:
  - Removed silent `catch (_)` swallowing in `fetchNotifications`, `markAsRead`, `markAllAsRead`, `deleteNotification`, and `sendTestNotification`.
  - Fixed `fetchNotifications` to preserve existing state and set `error` message instead of replacing notification state with `[]`.

### 5. Removed Hardcoded Dummy Phone Numbers (Task 3)
- `lib/features/dashboard/controllers/dashboard_controller.dart`:
  - Removed hardcoded dummy phone numbers `'+27 82 555 0192'` and `'+27 71 444 8821'` from `CoachActionItem` default parameters and fallback JSON deserializers.

### 6. Dynamic Thresholds, Cutoffs & Icons (Task 4)
- `lib/features/parent/presentation/parent_dashboard_screen.dart`: Updated academic cutoffs to reference `AppConfig.academicPassCutoff` and `AppConfig.academicWarningCutoff`.
- `lib/features/student/presentation/student_dashboard_screen.dart`: Updated grade Honor/Pass/Warning cutoffs to reference `AppConfig`.
- `lib/features/dashboard/controllers/dashboard_controller.dart`: Replaced `gradeImprovement = gradeImprovement ?? 12` with `AppConfig.gradeImprovementDefault`.
- Replaced hardcoded `Icons.sports_rugby` and `Icons.sports_rugby_outlined` with dynamic `Icons.sports` and `Icons.sports_outlined` in `login_screen.dart`, `notification_item.dart`, and `student_dashboard_screen.dart`.

### 7. End-to-End Removal of `parent_contact` and `email` (Task 5)
- `lib/features/dashboard/controllers/roster_controller.dart`: Removed `email` from `RosterPlayer` model and `addPlayer` parameter/payload. Removed `json['parentContact']` fallback check.
- `lib/features/dashboard/presentation/add_player_modal.dart`: Removed `_emailController` and mandatory email input field.
- `lib/features/student/presentation/student_dashboard_screen.dart`: Removed `_emailController`, account email display input, and `item.parentEmail` UI links.
- `lib/features/dashboard/presentation/dashboard_screen.dart`: Removed `parentEmail` copy action and text display.

### 8. Dev OTP Key Handling Fix (Task 6)
- `lib/features/auth/presentation/auth_state.dart`: Updated `otpCode` parsing to check both `response.data['devOtp']` and `response.data['otp']`.

### 9. Dynamic Parent Portal Header Cards (Task 7)
- `lib/features/parent/presentation/parent_dashboard_screen.dart`:
  - Bound "Upcoming Match Ticket" card to dynamic `StudentPortalData.matches` data (`matchDate`, `venue`, `courtInfo`, `matchStatus`).
  - Bound "Campus Checkout Status" card to dynamic `StudentPortalData.attendance` and `profile` checkout data (`checkoutTime`, `checkoutStatus`, `checkoutDesc`).
