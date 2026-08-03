# uSPORT Player Development Tracker — Hono API Specification

The uSPORT API is built using TypeScript on **Cloudflare Workers** with the **Hono** web framework, backed by **Cloudflare D1 Relational Database**, **Workers KV** caching, and **R2 Storage**.

---

## 1. Architecture, Authentication & Standards

### Authentication & Authorization
All protected API endpoints require a JWT Bearer token in the `Authorization` header:
```http
Authorization: Bearer <JWT_TOKEN>
```
Authentication is passwordless via email OTP (`/api/auth/send-otp`, `/api/auth/verify-otp`) or SMS OTP (`/api/sms/send-verification`, `/api/sms/verify-code`).

### Standard Response Envelope
All endpoints return standard JSON responses with HTTP status codes (`200 OK`, `201 Created`, `400 Bad Request`, `401 Unauthorized`, `404 Not Found`, `500 Internal Server Error`).

```json
{
  "success": true,
  "data": {},
  "message": "Optional descriptive status message"
}
```

### Performance & Edge Caching
Endpoints returning list datasets generate deterministic `ETag` headers (e.g. `W/"squads-10-1722690000"`) and inspect `If-None-Match`. When data is unchanged, the worker responds immediately with `HTTP 304 Not Modified` and zero database reads.

---

## 2. API Endpoint Directory Overview

| Module | Route | Method | Description |
| --- | --- | --- | --- |
| **Module 1** | `/api/auth/send-otp` | POST | Dispatches 6-digit email OTP code |
| | `/api/auth/verify-otp` | POST | Verifies OTP code & issues JWT bearer token |
| | `/api/auth/profile` | GET / POST | Retrieves or updates authenticated user profile |
| | `/api/auth/send-email-change-otp` | POST | Dispatches OTP code to new email address |
| | `/api/auth/verify-new-email` | POST | Verifies new email OTP & updates account email |
| **Module 2** | `/api/squads` | GET / POST | List coach squads or create a new squad |
| | `/api/rosters/:age_group` | GET | Fetch team roster (cached in Workers KV) |
| | `/api/players/:id/squads` | POST | Assign player to squad |
| | `/api/squads/:squadId/players/add` | POST | Add player assignment to squad |
| | `/api/squads/:squadId/players/remove` | POST | Remove player assignment from squad |
| | `/api/admin/all-players` | GET | Admin directory of all players across schools |
| | `/api/school/players` | GET | Filtered school player directory |
| | `/api/players` | POST | Register a new player profile |
| | `/api/players/:id/position` | POST | Update primary playing position for athlete |
| **Module 3** | `/api/dashboard/summary` | GET | Squad performance summary & baseline stats |
| | `/api/dashboard/flags` | GET | List flagged at-risk players |
| | `/api/dashboard/events` | GET / POST | List or create training & match events |
| | `/api/dashboard/events/:id` | POST | Update details for existing scheduled event |
| | `/api/dashboard/events/:id` | DELETE | Delete scheduled event |
| | `/api/dashboard/events/:id/delete` | POST | Delete scheduled event (POST endpoint) |
| | `/api/dashboard/actions` | GET / POST | List or create player action plan items |
| | `/api/dashboard/actions/:id/toggle` | POST | Toggle action plan completion state (24h purge) |
| | `/api/dashboard/actions/:id/delete` | POST | Delete action plan item |
| | `/api/dashboard/rising-stars` | GET | Retrieve top-performing rising star athletes |
| | `/api/dashboard/checkin` | POST | Log attendance check-in for practice/match |
| | `/api/dashboard/events/:id/attendance` | GET | Retrieve attendance record for an event |
| | `/api/match-stats` | POST | Log match stats & execute Auto-Score engine |
| **Module 4** | `/api/player/evaluation-baseline` | POST | Record physical testing evaluation baseline |
| | `/api/test-metrics` | GET / POST | List or create custom test metrics |
| | `/api/test-metrics/:id` | DELETE | Delete custom test metric |
| | `/api/test-logs` | POST | Log single athlete test score metric |
| | `/api/dashboard/test-logs` | POST | Log single athlete test score metric (alias) |
| | `/api/test-logs/batch` | POST | Batch log athlete test score metrics |
| | `/api/dashboard/test-logs/batch` | POST | Batch log athlete test score metrics (alias) |
| **Module 5** | `/api/student-portal` | GET | 360-degree athlete portal dataset |
| | `/api/student-portal/profile` | POST | Update student self-managed profile info |
| | `/api/parent/link-request` | POST | Initiate parent-child account link request |
| | `/api/player/link-requests` | GET | List pending parent link requests for athlete |
| | `/api/player/link-requests/:id/respond` | POST | Accept or decline parent link request |
| | `/api/parent/children` | GET | List linked child profiles for parent |
| **Module 6** | `/api/upload` | POST | Upload media / document asset to R2 storage |
| | `/api/admin/sports-config` | GET | Retrieve school sports configuration |
| | `/api/admin/bulk-upload` | POST | Ingest bulk stats/grades via CSV or JSON array |
| | `/api/sms/send-verification` | POST | Dispatch SMS OTP verification code |
| | `/api/coach/send-sms-otp` | POST | Dispatch SMS OTP verification code (alias) |
| | `/api/sms/verify-code` | POST | Verify SMS OTP code |
| | `/api/coach/verify-sms-otp` | POST | Verify SMS OTP code (alias) |
| **Module 7** | `/api/notifications` | GET | Retrieve user notification stream |
| | `/api/notifications/:id/read` | POST | Mark single notification as read |
| | `/api/notifications/read-all` | POST | Mark all notifications as read |
| | `/api/notifications/:id` | DELETE | Delete notification |
| | `/api/notifications/:id/delete` | POST | Delete notification (POST endpoint) |
| | `/api/notifications/send` | POST | Dispatch notification to target user or group |

---

## 3. Module Specifications

---

### Module 1: Authentication & OTP (`/api/auth/*`)

#### 1.1 Send Email OTP
* **Method:** `POST`
* **Route:** `/api/auth/send-otp`
* **Payload:**
```json
{
  "email": "coach.ross@overkruin.co.za"
}
```
* **Response (Success - 200):**
```json
{
  "success": true,
  "message": "OTP sent to coach.ross@overkruin.co.za"
}
```

#### 1.2 Verify Email OTP
* **Method:** `POST`
* **Route:** `/api/auth/verify-otp`
* **Payload:**
```json
{
  "email": "coach.ross@overkruin.co.za",
  "otp": "123456"
}
```
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": "USR-10928",
      "email": "coach.ross@overkruin.co.za",
      "role": "Coach",
      "schoolId": "OVK",
      "firstName": "Ross",
      "lastName": "Venter"
    }
  }
}
```

#### 1.3 Get Authenticated Profile
* **Method:** `GET`
* **Route:** `/api/auth/profile`
* **Headers:** `Authorization: Bearer <JWT>`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "id": "USR-10928",
    "email": "coach.ross@overkruin.co.za",
    "role": "Coach",
    "firstName": "Ross",
    "lastName": "Venter",
    "phone": "+27821234567",
    "avatar_url": "https://r2.cdn.com/avatars/ross.jpg"
  }
}
```

#### 1.4 Update Authenticated Profile
* **Method:** `POST`
* **Route:** `/api/auth/profile`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "firstName": "Ross",
  "lastName": "Venter",
  "phone": "+27821234567",
  "avatarUrl": "https://r2.cdn.com/avatars/ross-new.jpg"
}
```

#### 1.5 Send Email Change OTP
* **Method:** `POST`
* **Route:** `/api/auth/send-email-change-otp`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "newEmail": "new.ross@overkruin.co.za"
}
```

#### 1.6 Verify New Email OTP
* **Method:** `POST`
* **Route:** `/api/auth/verify-new-email`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "newEmail": "new.ross@overkruin.co.za",
  "otp": "654321"
}
```

---

### Module 2: Squad & Roster Management (`/api/squads/*`, `/api/school/*`, `/api/players/*`)

#### 2.1 Fetch Squads List
* **Method:** `GET`
* **Route:** `/api/squads`
* **Headers:** `Authorization: Bearer <JWT>`
* **Query Parameters:** `schoolId` (optional)
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "SQUAD-U15A",
      "name": "U15 Rugby A",
      "code": "U15A",
      "age_group": "U15",
      "sport": "Rugby",
      "player_count": 22
    }
  ]
}
```

#### 2.2 Create Squad
* **Method:** `POST`
* **Route:** `/api/squads`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "name": "U16 Rugby A",
  "code": "U16A",
  "ageGroup": "U16",
  "sport": "Rugby"
}
```

#### 2.3 Fetch Team Roster by Age Group
* **Method:** `GET`
* **Route:** `/api/rosters/:age_group`
* **Headers:** `Authorization: Bearer <JWT>`
* **Description:** Looks up roster cache in Workers KV. If cache miss, queries D1 database and updates KV cache before returning.
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "ageGroup": "U15",
    "players": [
      {
        "id": "OVK-U15-001",
        "firstName": "Liam",
        "lastName": "Venter",
        "position": "Flanker",
        "team": "A Team",
        "ugroupsActive": 1
      }
    ]
  }
}
```

#### 2.4 Assign Player to Squad
* **Method:** `POST`
* **Route:** `/api/players/:id/squads`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "squadId": "SQUAD-U15A"
}
```

#### 2.5 Add Player to Squad
* **Method:** `POST`
* **Route:** `/api/squads/:squadId/players/add`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "playerId": "OVK-U15-001"
}
```

#### 2.6 Remove Player from Squad
* **Method:** `POST`
* **Route:** `/api/squads/:squadId/players/remove`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "playerId": "OVK-U15-001"
}
```

#### 2.7 Admin Directory (All Players)
* **Method:** `GET`
* **Route:** `/api/admin/all-players`
* **Headers:** `Authorization: Bearer <JWT>`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "OVK-U15-001",
      "name": "Liam Venter",
      "firstName": "Liam",
      "lastName": "Venter",
      "ageGroup": "U15",
      "team": "A Team",
      "position": "Flanker",
      "schoolId": "OVK"
    }
  ]
}
```

#### 2.8 School Players Directory
* **Method:** `GET`
* **Route:** `/api/school/players`
* **Headers:** `Authorization: Bearer <JWT>`
* **Query Parameters:** `squadId`, `search`, `ageGroup`

#### 2.9 Register Player Profile
* **Method:** `POST`
* **Route:** `/api/players`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "firstName": "Liam",
  "lastName": "Venter",
  "ageGroup": "U15",
  "position": "Flanker",
  "team": "A Team",
  "schoolId": "OVK"
}
```

#### 2.10 Update Player Position
* **Method:** `POST`
* **Route:** `/api/players/:id/position`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "position": "Flyhalf"
}
```

---

### Module 3: Coach Dashboard, Events & Action Plans (`/api/dashboard/*`)

#### 3.1 Squad Summary Analytics
* **Method:** `GET`
* **Route:** `/api/dashboard/summary`
* **Headers:** `Authorization: Bearer <JWT>`
* **Query Parameters:** `ageGroup`, `squadId`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "totalPlayers": 24,
    "avgAutoScore": 3.8,
    "attendanceRate": 92.5,
    "academicAvg": 68.4,
    "flaggedCount": 2
  }
}
```

#### 3.2 Flagged At-Risk Players
* **Method:** `GET`
* **Route:** `/api/dashboard/flags`
* **Headers:** `Authorization: Bearer <JWT>`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "playerId": "OVK-U15-003",
      "name": "Johan Smith",
      "flagType": "Academic Drop",
      "reason": "Term 2 GPA dropped below 50%",
      "severity": "High"
    }
  ]
}
```

#### 3.3 Fetch Scheduled Events
* **Method:** `GET`
* **Route:** `/api/dashboard/events`
* **Headers:** `Authorization: Bearer <JWT>`
* **Query Parameters:** `squadId`, `month`, `year`

#### 3.4 Create Scheduled Event
* **Method:** `POST`
* **Route:** `/api/dashboard/events`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "title": "Match vs Menlopark",
  "eventType": "Match",
  "eventDate": "2026-08-15",
  "eventTime": "14:00",
  "location": "A Field",
  "squadId": "SQUAD-U15A"
}
```

#### 3.5 Update Event
* **Method:** `POST`
* **Route:** `/api/dashboard/events/:id`
* **Headers:** `Authorization: Bearer <JWT>`

#### 3.6 Delete Event (DELETE)
* **Method:** `DELETE`
* **Route:** `/api/dashboard/events/:id`
* **Headers:** `Authorization: Bearer <JWT>`

#### 3.6.1 Delete Event (POST Endpoint)
* **Method:** `POST`
* **Route:** `/api/dashboard/events/:id/delete`
* **Headers:** `Authorization: Bearer <JWT>`

#### 3.7 Fetch Action Plans
* **Method:** `GET`
* **Route:** `/api/dashboard/actions`
* **Headers:** `Authorization: Bearer <JWT>`
* **Query Parameters:** `playerId`, `status`

#### 3.8 Create Action Plan
* **Method:** `POST`
* **Route:** `/api/dashboard/actions`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "playerId": "OVK-U15-001",
  "title": "Increase High-Tackle Accuracy",
  "description": "Perform 20 extra tackle bag reps twice per week.",
  "targetDate": "2026-08-30"
}
```

#### 3.9 Toggle Action Plan Completion (24-Hour Purge Engine)
* **Method:** `POST`
* **Route:** `/api/dashboard/actions/:id/toggle`
* **Headers:** `Authorization: Bearer <JWT>`
* **Description:** Toggles `is_completed` state. When completed, sets `completed_at = CURRENT_TIMESTAMP`. Completed action plans older than 24 hours are automatically purged on query.

#### 3.10 Delete Action Plan
* **Method:** `POST`
* **Route:** `/api/dashboard/actions/:id/delete`
* **Headers:** `Authorization: Bearer <JWT>`

#### 3.11 Rising Stars Roster
* **Method:** `GET`
* **Route:** `/api/dashboard/rising-stars`
* **Headers:** `Authorization: Bearer <JWT>`

#### 3.12 Session Attendance Check-in
* **Method:** `POST`
* **Route:** `/api/dashboard/checkin`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "eventId": "EVT-1029",
  "attendees": [
    { "playerId": "OVK-U15-001", "status": "present" },
    { "playerId": "OVK-U15-002", "status": "absent" }
  ]
}
```

#### 3.13 Event Attendance Roster
* **Method:** `GET`
* **Route:** `/api/dashboard/events/:id/attendance`
* **Headers:** `Authorization: Bearer <JWT>`

#### 3.14 Log Match Statistics
* **Method:** `POST`
* **Route:** `/api/match-stats`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "playerId": "OVK-U15-001",
  "matchDate": "2026-07-17",
  "opponent": "Menlopark",
  "tacklesMade": 8,
  "tacklesMissed": 1,
  "carries": 5,
  "metresGained": 20.0,
  "errors": 1,
  "penalties": 0,
  "workRate": 4,
  "overallRating": 4
}
```
* **Response (Success - 201):**
```json
{
  "success": true,
  "data": {
    "id": 142,
    "playerId": "OVK-U15-001",
    "autoScore": 3.7,
    "autoScorePercent": 74.0,
    "tacklePercentage": 0.8889,
    "category": "🟡 On Track"
  }
}
```

---

### Module 4: Performance Testing & Metrics (`/api/test-metrics`, `/api/test-logs`)

#### 4.1 Log Evaluation Baseline
* **Method:** `POST`
* **Route:** `/api/player/evaluation-baseline`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "playerId": "OVK-U15-001",
  "speed40m": 5.70,
  "verticalJump": 2.58,
  "broadJump": 1.96,
  "pushUps": 25,
  "pullUps": 5
}
```

#### 4.2 List Custom Test Metrics
* **Method:** `GET`
* **Route:** `/api/test-metrics`
* **Headers:** `Authorization: Bearer <JWT>`

#### 4.3 Create or Update Test Metric
* **Method:** `POST`
* **Route:** `/api/test-metrics`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "key": "bronco_test",
  "label": "Bronco Shuttle Run (s)",
  "category": "Fitness",
  "unit": "seconds"
}
```

#### 4.4 Delete Custom Test Metric
* **Method:** `DELETE`
* **Route:** `/api/test-metrics/:id`
* **Headers:** `Authorization: Bearer <JWT>`

#### 4.5 Log Single Test Metric Score
* **Method:** `POST`
* **Route:** `/api/test-logs` (alias: `/api/dashboard/test-logs`)
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "playerId": "OVK-U15-001",
  "metricId": "bronco_test",
  "score": 285.5,
  "testDate": "2026-08-01"
}
```

#### 4.6 Batch Log Test Metric Scores
* **Method:** `POST`
* **Route:** `/api/test-logs/batch` (alias: `/api/dashboard/test-logs/batch`)
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "logs": [
    { "playerId": "OVK-U15-001", "metricId": "dash40yd", "score": 4.85 },
    { "playerId": "OVK-U15-002", "metricId": "dash40yd", "score": 5.12 }
  ]
}
```

---

### Module 5: Student Portal & Parent Access (`/api/student-portal/*`, `/api/parent/*`)

#### 5.1 Student 360 Overview
* **Method:** `GET`
* **Route:** `/api/student-portal`
* **Headers:** `Authorization: Bearer <JWT>`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "player": {
      "id": "OVK-U15-001",
      "name": "Liam Venter",
      "ageGroup": "U15",
      "position": "Flanker"
    },
    "academics": {
      "term1": 68.0,
      "term2": 64.0,
      "overallAvg": 66.0,
      "category": "🟢 University Ready"
    },
    "fitnessBaselines": {
      "speed40m": 5.70,
      "verticalJump": 2.58
    },
    "matchAverages": {
      "matchesLogged": 3,
      "avgScore": 3.7
    },
    "actionPlans": [],
    "parentLinkStatus": "Linked"
  }
}
```

#### 5.2 Update Student Profile
* **Method:** `POST`
* **Route:** `/api/student-portal/profile`
* **Headers:** `Authorization: Bearer <JWT>`

#### 5.3 Request Parent Link
* **Method:** `POST`
* **Route:** `/api/parent/link-request`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "parentEmail": "parent.venter@gmail.com",
  "playerId": "OVK-U15-001"
}
```

#### 5.4 Fetch Pending Link Requests
* **Method:** `GET`
* **Route:** `/api/player/link-requests`
* **Headers:** `Authorization: Bearer <JWT>`

#### 5.5 Respond to Parent Link Request
* **Method:** `POST`
* **Route:** `/api/player/link-requests/:id/respond`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "action": "accept"
}
```

#### 5.6 List Parent Linked Children
* **Method:** `GET`
* **Route:** `/api/parent/children`
* **Headers:** `Authorization: Bearer <JWT>`

---

### Module 6: System Admin, Storage & SMS Services (`/api/upload`, `/api/admin/*`, `/api/sms/*`)

#### 6.1 Upload Media Asset
* **Method:** `POST`
* **Route:** `/api/upload`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:** Multipart Form-Data with `file`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "url": "https://r2.cdn.com/uploads/2026/08/avatar_12903.jpg"
  }
}
```

#### 6.2 Fetch Sports Config
* **Method:** `GET`
* **Route:** `/api/admin/sports-config`
* **Headers:** `Authorization: Bearer <JWT>`
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "rugby",
      "name": "Rugby Union",
      "config": {
        "positions": ["Prop", "Hooker", "Lock", "Flanker", "Number 8", "Scrumhalf", "Flyhalf", "Center", "Wing", "Fullback"],
        "fields": [
          { "key": "tackles_made", "label": "Tackles Made", "type": "counter" },
          { "key": "carries", "label": "Carries", "type": "counter" }
        ]
      }
    }
  ]
}
```

#### 6.3 Admin Bulk Upload Ingestion
* **Method:** `POST`
* **Route:** `/api/admin/bulk-upload`
* **Headers:** `Authorization: Bearer <JWT>` (SchoolAdmin or SuperAdmin)
* **Payload:**
```json
{
  "records": [
    { "id": "OVK-U15-001", "vertical": 2.55, "dash40yd": 4.90, "gpa": 68.5 },
    { "id": "OVK-U15-002", "vertical": 2.40, "dash40yd": 5.15, "gpa": 72.0 }
  ]
}
```
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "inserted": 2,
    "updated": 0,
    "errors": []
  }
}
```

#### 6.4 Send SMS OTP Code
* **Method:** `POST`
* **Route:** `/api/sms/send-verification` (alias: `/api/coach/send-sms-otp`)
* **Payload:**
```json
{
  "phone": "+27821234567"
}
```

#### 6.5 Verify SMS OTP Code
* **Method:** `POST`
* **Route:** `/api/sms/verify-code` (alias: `/api/coach/verify-sms-otp`)
* **Payload:**
```json
{
  "phone": "+27821234567",
  "code": "482019"
}
```

---

### Module 7: Notification System (`/api/notifications/*`)

#### 7.1 Fetch User Notifications
* **Method:** `GET`
* **Route:** `/api/notifications`
* **Headers:** `Authorization: Bearer <JWT>`
* **Query Parameters:** `unreadOnly` (boolean)

#### 7.2 Mark Notification as Read
* **Method:** `POST`
* **Route:** `/api/notifications/:id/read`
* **Headers:** `Authorization: Bearer <JWT>`

#### 7.3 Mark All Notifications as Read
* **Method:** `POST`
* **Route:** `/api/notifications/read-all`
* **Headers:** `Authorization: Bearer <JWT>`

#### 7.4 Delete Notification (DELETE)
* **Method:** `DELETE`
* **Route:** `/api/notifications/:id`
* **Headers:** `Authorization: Bearer <JWT>`

#### 7.4.1 Delete Notification (POST Endpoint)
* **Method:** `POST`
* **Route:** `/api/notifications/:id/delete`
* **Headers:** `Authorization: Bearer <JWT>`

#### 7.5 Send Notification
* **Method:** `POST`
* **Route:** `/api/notifications/send`
* **Headers:** `Authorization: Bearer <JWT>`
* **Payload:**
```json
{
  "recipientId": "USR-10928",
  "title": "Match Schedule Update",
  "message": "The match against Menlopark has been moved to 15:00.",
  "type": "schedule_change"
}
```
