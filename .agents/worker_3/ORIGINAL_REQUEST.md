## 2026-07-28T15:50:36Z
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

You are Worker 3. Your working directory is `C:\Development\academypro\.agents\worker_3`.
Create your working directory and your `BRIEFING.md` first.

Read Explorer 3's report at `C:\Development\academypro\.agents\explorer_3\analysis.md` and `C:\Development\explorer_3\handoff.md`.

Your objective is to complete Milestone 3: Flutter Mobile App Remediation in `C:\Development\academypro\academypro_app\lib\`:
1. Replace default string fallbacks (`'OVK-STUDENT-JAN'`, `'Jan'`, `'Mentz'`) with clean empty states (`"--"`) in `student_dashboard_screen.dart`, `dashboard_screen.dart`, and `roster_controller.dart`.
2. Update Flutter controllers (`RosterController`, `DashboardController`, `NotificationController`) to remove silent `catch (_)` blocks, log errors, display error toasts via `AppToast.showError(...)`, and return `false` or rethrow on network exceptions instead of emitting fake `AsyncValue.data([])`.
3. Remove hardcoded dummy phone numbers (`+27 82 555 0192`, `+27 71 444 8821`) from `dashboard_controller.dart`.
4. Make rating thresholds (4.0, 3.0, 2.0) and academic cutoffs (65%, 60%, 50%) dynamic/configurable, and remove hardcoded grade improvement metric (`12%`) and hardcoded sport identifier (`'rugby'`).
5. Perform complete end-to-end removal of `parent_contact` and `email` fields from `PlayerModel`/`StudentModel`, forms, profile settings, and UI widgets in `academypro_app/lib/`.
6. Fix dev OTP key name handling in `auth_state.dart`.
7. Bind Parent Portal "Upcoming Match Ticket" and "Campus Checkout Status" UI cards in `parent_dashboard_screen.dart` to dynamic data models/endpoints instead of static mock strings.
8. Verify code quality using `flutter analyze` in `C:\Development\academypro\academypro_app`.
9. Document all changes in `C:\Development\academypro\.agents\worker_3\changes.md`.
10. Write `C:\Development\academypro\.agents\worker_3\handoff.md` and send a message back to the orchestrator upon completion.
