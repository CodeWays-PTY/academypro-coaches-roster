# Handoff Report — Explorer 3

## 1. Observation
- Direct examination of `C:\Development\academypro\academypro_app\lib\` files:
  - Default Fallbacks: Found `'OVK-STUDENT-JAN'`, `'Jan'`, `'Mentz'` fallbacks in `student_dashboard_screen.dart:2511-2512` and `dashboard_screen.dart:53-54`. Found `'OVK-$ageGroup...'` ID generator in `roster_controller.dart:237`.
  - Silent `catch (_)` blocks: Identified silent catches in `roster_controller.dart` (Lines 143, 155, 169, 183, 267), `dashboard_controller.dart` (Lines 364, 399, 412, 479, 516), and `notification_controller.dart` (Lines 76-78 emitting `AsyncValue.data([])`/`state.copyWith(notifications: [])`, Lines 98, 109, 121, 140 handling API updates silently without toasts).
  - Hardcoded phone numbers: `dashboard_controller.dart:292, 294, 357, 359` contain hardcoded `+27 82 555 0192` and `+27 71 444 8821`.
  - Cutoffs & Sports: Found grade cutoffs (<50 critical red, <60 warning orange) in `parent_dashboard_screen.dart:999-1001` and `student_dashboard_screen.dart:1533-1543`. Identified `Icons.sports_rugby` hardcoded in `login_screen.dart`, `notification_item.dart`, and `student_dashboard_screen.dart`.
  - `parent_contact` & `email`: Traced usages across auth, profile tab, parent dashboard, and student profile settings.
  - Dev OTP Key Mismatch: `auth_state.dart:65` looks for `response.data['otp']`.
  - Parent Portal Cards: Confirmed "Upcoming Match Ticket" (lines 502-616) and "Campus Checkout Status" (lines 904-958) in `parent_dashboard_screen.dart` use hardcoded static strings instead of D1 API bindings.

## 2. Logic Chain
1. Searching exact query strings mapped directly to file locations and line numbers in the Dart codebase.
2. Checking exception handlers confirmed that network failures fail silently without presenting `AppToast.showError` to users, and in `notification_controller.dart` network errors cause the app to swallow errors and set notifications to empty list `[]`.
3. Inspection of `parent_dashboard_screen.dart` showed that header cards for "Upcoming Match Ticket" and "Campus Checkout Status" render static constants ("Sat, 10:00 AM", "4:15 PM") rather than parsing dynamic model objects.

## 3. Caveats
- No caveats. Investigation was complete and read-only across all 35 Dart files in `lib/`.

## 4. Conclusion
The Flutter codebase contains multiple hardcoded fallbacks (`OVK-STUDENT-JAN`, `Jan-Albert`, `Mentz`), dummy phone numbers (`+27 82 555 0192`), swallowed network exceptions in core controllers (`RosterController`, `DashboardController`, `NotificationController`), a potential key name mismatch for dev OTPs (`otp` vs backend payload), and static UI card bindings in the Parent Portal.

## 5. Verification Method
- Code inspection of files in `lib/`:
  - `lib/features/student/presentation/student_dashboard_screen.dart`
  - `lib/features/parent/presentation/parent_dashboard_screen.dart`
  - `lib/features/dashboard/controllers/roster_controller.dart`
  - `lib/features/dashboard/controllers/dashboard_controller.dart`
  - `lib/features/notifications/controllers/notification_controller.dart`
  - `lib/features/auth/presentation/auth_state.dart`
- Full analysis report written to `C:\Development\academypro\.agents\explorer_3\analysis.md`.
