# AcademyPro Flutter Core & Static Analysis Report

**Date:** 2026-08-03  
**Target:** `academypro_app/lib/core/` and overall Flutter app structure (`academypro_app/lib/`)  
**Tool:** `flutter analyze` & manual static audit  

---

## 1. Executive Summary

A comprehensive static analysis and architecture audit was performed on the Flutter application (`academypro_app`).

- **Total Static Analysis Issues:** 182 issues (0 errors, 182 lints/warnings).
- **Core Package Audit:** `lib/core/` contains 11 files across 8 modules (`config`, `network`, `presentation`, `services`, `storage`, `theme`, `utils`, `widgets`).
- **Dead Code & Unreferenced Utilities:**
  - **`PermissionService` (`lib/core/services/permission_service.dart`)**: 100% dead code / unreferenced across the app.
  - **`LocalStorage` Offline Sync Queue (`lib/core/storage/local_storage.dart`)**: Methods `queueMatchStats()`, `getSyncQueue()`, `dequeueItem()`, and box `syncQueueBoxName` are never invoked.
  - **`AppConfig` Cutoff Constants (`lib/core/config/app_config.dart`)**: `academicHonorCutoff`, `ratingHighThreshold`, `ratingMidThreshold`, `ratingLowThreshold`, `sportIdentifier` are unreferenced outside `AppConfig`.
  - **`AppTheme` Static Color Constants (`lib/core/theme/app_theme.dart`)**: Color fields (`slate50`, `blue600`, etc.) are defined but bypass-bypassed by hardcoded hex `Color(0xFF...)` values in screens/widgets.
- **Root Entry Point (`lib/main.dart`)**: Correctly initializes Hive (`LocalStorage.init()`), sets system navigation bar styles (`SystemChrome.setSystemUIOverlayStyle`), handles offline state via `NetworkErrorScreen`, and manages role-based home screen routing.

---

## 2. Directory Structure of `lib/core/`

| Directory | File Path | Main Component / Class | Responsibility | Usage Status |
| :--- | :--- | :--- | :--- | :--- |
| `config/` | `core/config/app_config.dart` | `AppConfig` | Academic cutoffs, rating thresholds, defaults | Partial (3/8 constants used) |
| `network/` | `core/network/api_client.dart` | `ApiClient`, `apiClientProvider` | Dio client with JWT interceptor & timeout options | **Actively Used** (28 references) |
| `presentation/` | `core/presentation/network_error_screen.dart` | `NetworkErrorScreen` | Offline error UI with student QR pass display | **Actively Used** (`main.dart:83`) |
| `services/` | `core/services/network_service.dart` | `NetworkStatusNotifier`, `networkStatusProvider` | Riverpod network connectivity monitoring | **Actively Used** (`main.dart:76`) |
| `services/` | `core/services/notification_service.dart` | `NotificationService` | Local notifications plugin wrapper | **Actively Used** (`profile_tab_view.dart:52`) |
| `services/` | `core/services/permission_service.dart` | `PermissionService` | Lazy photo and camera permission requesters | **UNREFERENCED / DEAD CODE** |
| `storage/` | `core/storage/local_storage.dart` | `LocalStorage` | Hive storage (JWT token, user profile, JSON cache, sync queue) | **Partially Used** (Session & cache active; Sync queue unused) |
| `theme/` | `core/theme/app_theme.dart` | `AppTheme` | Material 3 light theme definition & color palette | **Actively Used** (`main.dart:71,82,117`) |
| `utils/` | `core/utils/app_toast.dart` | `AppToast` | Top safe-area floating toast banner (success, error, info) | **Actively Used** (Heavy usage across app) |
| `utils/` | `core/utils/phone_utils.dart` | `PhoneUtils` | RSA phone formatting (`+27 XX XXX XXXX`) and cleaning | **Actively Used** (`dashboard_screen.dart`, `profile_tab_view.dart`) |
| `widgets/` | `core/widgets/country_code_picker.dart` | `CountryCodePicker`, `CountryCode` | Modal bottom sheet country dial code picker | **Actively Used** (`coach_welcome_wizard_screen.dart`, `student_dashboard_screen.dart`) |

---

## 3. Detailed Audit of Dead Code & Unreferenced Utilities

### 3.1. Dead Service: `PermissionService`
- **File:** `lib/core/services/permission_service.dart`
- **Content:**
  - `requestPhotoPermissionOnDemand()`
  - `requestCameraPermissionOnDemand()`
- **Finding:** No file in `lib/` imports `permission_service.dart` or calls `PermissionService`. Camera and QR code permissions in `qr_scanner_modal.dart` and photo pickers manage permissions directly or rely on `image_picker` / `mobile_scanner` plugin defaults.
- **Recommendation:** Either integrate `PermissionService` into `qr_scanner_modal.dart` and photo update forms or remove the file.

### 3.2. Dead Storage Utilities: `LocalStorage` Offline Sync Queue
- **File:** `lib/core/storage/local_storage.dart`
- **Content:**
  - `static const String syncQueueBoxName = 'sync_queue_box';`
  - `queueMatchStats(Map<String, dynamic> payload)`
  - `getSyncQueue()`
  - `dequeueItem(dynamic key)`
- **Finding:** `sync_queue_box` is opened on app initialization (`await Hive.openBox(syncQueueBoxName);`), but no controller or service pushes or dequeues sync actions. Offline sync logic in controllers handles mutations in memory or fails fast.
- **Recommendation:** Implement offline queue processing in `dashboard_controller.dart` or clean up unused sync queue methods to reduce memory overhead from opening an empty Hive box.

### 3.3. Unreferenced Configuration Constants: `AppConfig`
- **File:** `lib/core/config/app_config.dart`
- **Unused Constants:**
  - `academicHonorCutoff = 65.0;`
  - `ratingHighThreshold = 4.0;`
  - `ratingMidThreshold = 3.0;`
  - `ratingLowThreshold = 2.0;`
  - `sportIdentifier = 'sports';`
- **Used Constants:**
  - `academicPassCutoff = 60.0;`
  - `academicWarningCutoff = 50.0;`
  - `gradeImprovementDefault = 0;`
- **Recommendation:** Remove unused static fields or apply them to athlete profile rating indicators.

### 3.4. Disconnected Theme Palette: `AppTheme`
- **File:** `lib/core/theme/app_theme.dart`
- **Finding:** `AppTheme` defines a full light mode color palette (`slate50`, `blue600`, `green600`, `red600`, etc.). However, individual presentation files (such as `student_dashboard_screen.dart`, `parent_dashboard_screen.dart`, `dashboard_screen.dart`) instantiate hardcoded hex `Color(0xFF...)` values directly instead of referencing `AppTheme.blue600` or `Theme.of(context).colorScheme.primary`.

---

## 4. `flutter analyze` Static Analysis Breakdown

Static analysis completed with **182 issues** (0 fatal compiler errors, 182 lints/warnings).

### Categorized Issue Counts

| Category / Lint Rule | Count | Primary Impact | Example Locations |
| :--- | :---: | :--- | :--- |
| `deprecated_member_use` (`withOpacity`) | ~105 | Flutter 3.27+ deprecation warning for `Color.withOpacity()` (use `.withValues()`) | `app_toast.dart:108`, `network_error_screen.dart:130`, `student_dashboard_screen.dart` |
| `deprecated_member_use` (`ColorScheme`) | 2 | `background` and `onBackground` deprecated in `ColorScheme.light` | `lib/core/theme/app_theme.dart:35,37` |
| `deprecated_member_use` (`FormField.value`) | 4 | `value` property deprecated in `FormField` (use `initialValue`) | `student_dashboard_screen.dart:2215`, `manage_metrics_modal.dart:192` |
| `deprecated_member_use` (`Switch.activeColor`) | 2 | `activeColor` deprecated on `Switch` (use `activeThumbColor`) | `create_event_modal.dart:1039`, `profile_tab_view.dart:1343` |
| `avoid_print` | ~30 | Direct `print()` statements in production code | `notification_service.dart:36,60,95,103`, `auth_state.dart:152`, `dashboard_controller.dart` |
| `use_super_parameters` | ~20 | Constructor `Key? key` not using `super.key` syntax | `network_error_screen.dart:9`, `login_screen.dart:13`, `create_squad_modal.dart:11` |
| `unnecessary_underscores` | ~12 | Parameter names with multiple underscores (`_, __`) | `country_code_picker.dart:90`, `login_screen.dart:167`, `events_tab_view.dart:689` |
| `use_build_context_synchronously` | ~8 | Using `BuildContext` across async gaps without `mounted` checks | `batch_test_logger_modal.dart:274`, `events_tab_view.dart:106`, `manage_metrics_modal.dart:85` |
| `unnecessary_import` | 1 | Unnecessary import of `package:flutter/services.dart` | `lib/features/dashboard/presentation/qr_scanner_modal.dart:3` |
| `unnecessary_to_list_in_spreads` | 2 | Redundant `.toList()` calls inside collection spreads | `add_player_modal.dart:249`, `roster_tab_view.dart:1004` |
| `prefer_final_fields` | 1 | Non-final private field `_selectedAgeGroup` | `lib/features/dashboard/presentation/roster_tab_view.dart:22` |
| `curly_braces_in_flow_control_structures` | 2 | Single-line if statements missing curly braces | `lib/features/parent/presentation/parent_dashboard_screen.dart:1018,1019` |
| `unnecessary_brace_in_string_interps` | 1 | Unnecessary braces in string interpolation | `lib/features/dashboard/presentation/batch_test_logger_modal.dart:680` |

---

## 5. Issues Identified in `lib/core/` Files

Below is the verbatim line-by-line list of all static analysis findings inside `lib/core/`:

1. **`lib/core/presentation/network_error_screen.dart`**
   - Line 9:9 - `use_super_parameters`: Parameter 'key' could be a super parameter (`super.key`).
   - Line 130:58 - `deprecated_member_use`: `withOpacity` is deprecated. Use `.withValues()`.
2. **`lib/core/services/notification_service.dart`**
   - Line 36:7 - `avoid_print`: Don't invoke 'print' in production code.
   - Line 60:7 - `avoid_print`: Don't invoke 'print' in production code.
   - Line 95:7 - `avoid_print`: Don't invoke 'print' in production code.
   - Line 103:7 - `avoid_print`: Don't invoke 'print' in production code.
3. **`lib/core/theme/app_theme.dart`**
   - Line 35:9 - `deprecated_member_use`: 'background' is deprecated. Use `surface`.
   - Line 37:9 - `deprecated_member_use`: 'onBackground' is deprecated. Use `onSurface`.
4. **`lib/core/utils/app_toast.dart`**
   - Line 108:46 - `deprecated_member_use`: `withOpacity` is deprecated. Use `.withValues()`.
   - Line 133:55 - `deprecated_member_use`: `withOpacity` is deprecated. Use `.withValues()`.
   - Line 143:61 - `deprecated_member_use`: `withOpacity` is deprecated. Use `.withValues()`.
5. **`lib/core/widgets/country_code_picker.dart`**
   - Line 90:45 - `unnecessary_underscores`: Unnecessary use of multiple underscores (`_, __`).

---

## 6. Recommendations for Implementer / Refactoring Phase

1. **Clean Up Dead Core Code:**
   - Remove or integrate `PermissionService` (`lib/core/services/permission_service.dart`).
   - Prune unreferenced offline sync queue methods in `LocalStorage` or wire up actual offline sync processing.
   - Clean up unused constants in `AppConfig`.
2. **Batch Fix Deprecations:**
   - Global replace for `.withOpacity(...)` to `.withValues(...)` across `lib/`.
   - Update `ColorScheme.light` properties in `AppTheme.dart` from `background`/`onBackground` to `surface`/`onSurface`.
3. **Replace `print()` with Debug Logger:**
   - Replace raw `print()` calls in services and controllers with `debugPrint()` or standard logging helper.
4. **Guard Async Context Usage:**
   - Add `if (!mounted) return;` or `if (context.mounted)` checks before using `BuildContext` after `await` calls in modals and tab views.
