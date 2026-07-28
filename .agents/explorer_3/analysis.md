# AcademyPro Flutter Mobile App Exploration Analysis

## Overview
This document contains the complete, read-only exploration results of the Flutter Mobile App codebase located at `C:\Development\academypro\academypro_app\lib\`.

---

## Findings Summary

### 1. Default String Fallbacks (`'OVK-STUDENT-JAN'`, hardcoded user/school strings)
* **File:** `lib/features/student/presentation/student_dashboard_screen.dart`
  * **Line 2511-2512**:
    ```dart
    final studentName = '${profile['firstName'] ?? 'Jan'} ${profile['lastName'] ?? 'Mentz'}'.trim();
    final studentId = profile['id'] ?? 'OVK-STUDENT-JAN';
    ```
  * **Line 1911**:
    ```dart
    'Athlete Profile   ${profile['id'] ?? 'OVK-ATHLETE'}',
    ```
  * **Line 295-298**:
    ```dart
    final studentName = '${profile['firstName'] ?? 'Athlete'} ${profile['lastName'] ?? ''}'.trim();
    final team = profile['team'] ?? 'First Team';
    final ageGroup = profile['ageGroup'] ?? 'U15';
    final position = profile['position'] ?? 'Player';
    ```
* **File:** `lib/features/dashboard/presentation/dashboard_screen.dart`
  * **Line 53-54**:
    ```dart
    final firstName = userProfile['first_name'] ?? userProfile['firstName'] ?? 'Jan-Albert';
    final lastName = userProfile['last_name'] ?? userProfile['lastName'] ?? 'Mentz';
    ```
* **File:** `lib/features/dashboard/controllers/roster_controller.dart`
  * **Line 237**:
    ```dart
    final newId = 'OVK-$ageGroup-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    ```

---

### 2. Silent `catch (_)` Blocks & Exception Swallowing in Controllers
* **File:** `lib/features/dashboard/controllers/roster_controller.dart`
  * **Lines 143, 155, 169, 183, 267**:
    ```dart
    // Lines 133-144: updatePlayerSquads
    try {
      final response = await _apiClient.post(...);
      if (response.statusCode == 200 || response.statusCode == 201) { ... return true; }
    } catch (_) {}
    return false;

    // Lines 147-157: fetchSchoolPlayers
    try { ... } catch (_) {}
    return [];

    // Lines 159-170: addPlayerToSquad
    try { ... } catch (_) {}
    return false;

    // Lines 173-184: removePlayerFromSquad
    try { ... } catch (_) {}
    return false;

    // Lines 256-267: createPlayer
    try { await _apiClient.post('/api/players', ...); } catch (_) {}
    return true; // Returns true regardless of network failure!
    ```
* **File:** `lib/features/dashboard/controllers/dashboard_controller.dart`
  * **Lines 97-99**: `fetchSummary()` swallows error and resets loading state without `AppToast.showError` or error state set.
  * **Lines 364, 399, 412, 479, 516**: Silent `catch (_) {}` swallowing failures on fetching actions, adding actions, toggling actions, adding squads, and editing squads.
* **File:** `lib/features/notifications/controllers/notification_controller.dart`
  * **Lines 76-78**:
    ```dart
    } catch (e) {
      state = state.copyWith(notifications: [], unreadCount: 0, loading: false);
    }
    ```
    Replaces notification state with empty array `[]` on error!
  * **Lines 98-100, 109-111, 121-125, 140-142**: Silent `catch (_)` handling markAsRead, markAllAsRead, deleteNotification, sendTestNotification without alerting user or showing `AppToast.showError`.

---

### 3. Hardcoded Dummy Phone Numbers
* **File:** `lib/features/dashboard/controllers/dashboard_controller.dart`
  * **Line 292, 294**:
    ```dart
    this.parentPhone = '+27 82 555 0192',
    this.playerPhone = '+27 71 444 8821',
    ```
  * **Line 357, 359**:
    ```dart
    parentPhone: x['parentPhone'] ?? '+27 82 555 0192',
    playerPhone: x['playerPhone'] ?? '+27 71 444 8821',
    ```

---

### 4. Thresholds, Academic Cutoffs, and Hardcoded Sport Identifiers
* **Academic Cutoffs (60%, 50%):**
  * **File:** `lib/features/parent/presentation/parent_dashboard_screen.dart`
    * **Line 673**:
      ```dart
      latestGrade >= 60 ? 'On Track' : (latestGrade > 0 ? 'Needs Attention' : 'Pending'),
      ```
    * **Lines 999-1001**:
      ```dart
      Color border = const Color(0xFF16A34A);
      if (grade < 50) border = const Color(0xFFDC2626);
      else if (grade < 60) border = const Color(0xFFD97706);
      ```
  * **File:** `lib/features/student/presentation/student_dashboard_screen.dart`
    * **Lines 400**:
      ```dart
      (latestGrade >= 85 ? 'A+' : (latestGrade >= 75 ? 'A' : (latestGrade >= 65 ? 'B+' : (latestGrade >= 55 ? 'B' : (latestGrade >= 45 ? 'C' : 'D')))))
      ```
    * **Lines 1533-1543**:
      ```dart
      if (grade < 50) {
        label = 'CRITICAL';
      } else if (grade < 60) {
        label = 'WARNING';
      }
      ```
* **Sport Identifiers / Icons (`rugby`):**
  * **File:** `lib/features/auth/presentation/login_screen.dart` Line 160: `Icons.sports_rugby`
  * **File:** `lib/features/notifications/models/notification_item.dart` Line 64: `Icons.sports_rugby_outlined`
  * **File:** `lib/features/student/presentation/student_dashboard_screen.dart` Line 2142, Line 2903: `Icons.sports_rugby`
* **Grade Improvement Metric / Rating Thresholds:**
  * No explicit `"12%"` hardcoded text found in dart codebase; rating calculations use `(latestGrade / 20).clamp(1, 5).toInt()` in `parent_dashboard_screen.dart` (Line 677).

---

### 5. Occurrences of `parent_contact` and `email`
* **`parent_contact`**:
  * Found as fallbacks in `lib/features/dashboard/controllers/dashboard_controller.dart` Line 356 (`parentName: x['parentName'] ?? 'Parent Contact'`).
  * In `lib/features/dashboard/presentation/dashboard_screen.dart` Line 815 (`'Parent contact email ...'`).
* **`email`**:
  * Extensively used across models, controllers, and UI widgets:
    * `lib/features/auth/presentation/auth_state.dart` (sendOtp, verifyOtp)
    * `lib/features/dashboard/presentation/profile_tab_view.dart` (email change verification modals, `/api/auth/send-email-change-otp`, `/api/auth/verify-new-email`)
    * `lib/features/parent/presentation/parent_dashboard_screen.dart` (`/api/parent/link-request` sending `childEmail`)
    * `lib/features/student/presentation/student_dashboard_screen.dart` (`accountEmail`, profile form sync with account email).

---

### 6. Dev OTP Key Mismatch in `auth_state.dart`
* **File:** `lib/features/auth/presentation/auth_state.dart`
  * **Line 65**:
    ```dart
    final otpCode = response.data['otp']?.toString();
    ```
  * Note: The Cloudflare Worker / backend sends `devOtp` or `otp` in response payload. In `auth_state.dart`, line 65 queries `response.data['otp']`. If the API response returns `devOtp` (e.g. `{"success": true, "devOtp": "123456"}`), `otpCode` resolves to `null`.

---

### 7. Parent Portal UI Cards Binding Analysis
* **File:** `lib/features/parent/presentation/parent_dashboard_screen.dart`
  * **"Upcoming Match Ticket" Card (`_buildHeaderCard` / Lines 502-616)**:
    * **STATIC BINDING**. Date ("Sat, 10:00 AM"), Venue ("West Field Complex"), and Court ("Court 4 • Home Jersey") are hardcoded static strings inside the widget tree and are NOT bound to `StudentPortalData.matches` or any D1 API endpoint.
  * **"Campus Checkout Status" Card (`_buildCampusCheckoutCard` / Lines 904-958)**:
    * **STATIC BINDING**. Time ("4:15 PM") and Status ("STATUS: SAFE", "checked out of training facility") are hardcoded static strings inside the widget tree (only `studentName` is interpolated into the string) and are NOT bound to real checkin/checkout API data.
