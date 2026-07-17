# uSPORT Player Development Tracker — Hono API Specification

The API is built using TypeScript on **Cloudflare Workers** with the **Hono** web framework, interacting with **D1 SQL Database** and **Workers KV** for caching.

---

## 1. Authentication & Security Headers

All requests to protected endpoints must include a Bearer Token in the authorization header:
```http
Authorization: Bearer <JWT_TOKEN>
```

### CORS & Response Helpers
Every API response returns standard CORS headers and structured JSON.
```json
{
  "success": true,
  "data": {},
  "message": "Optional message details"
}
```

---

## 2. API Endpoint Directory

```
POST /api/auth/login                  --> User login (all roles)
GET  /api/rosters/:age_group          --> Fetch team roster (cached in KV)
POST /api/match-stats                 --> Log match performance (runs Auto-Score)
POST /api/attendance                  --> Smart-default session attendance
POST /api/admin/bulk-upload           --> School Admin Excel/CSV grade uploads
GET  /api/players/:id/dashboard       --> Retrieve player 360 overview
GET  /api/players/flagged             --> Fetch flagged players roster
```

---

## 3. Detailed Payload & Schema Models

### A. Authentication Login
* **Method:** `POST`
* **Route:** `/api/auth/login`
* **Payload:**
```json
{
  "email": "coach.ross@overkruin.co.za",
  "password": "securepassword123"
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

---

### B. Fetch Team Roster
* **Method:** `GET`
* **Route:** `/api/rosters/:age_group`
* **Headers:** `Authorization: Bearer <JWT>`
* **Description:** Looks up roster cache in Workers KV. If empty, queries D1 database and populates KV before responding.
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

---

### C. Log Match Performance
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
* **Description:** The worker runs the Auto-Score algorithm in real time, logs the raw data and calculations to the D1 `match_stats` table, and returns the computed score and RAG category.
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

### D. Bulk Grade CSV Ingestion
* **Method:** `POST`
* **Route:** `/api/admin/bulk-upload`
* **Headers:** `Authorization: Bearer <JWT>` (Must hold role `SchoolAdmin` or `SuperAdmin`)
* **Payload (Multipart Form-Data):**
  - `file`: CSV / Excel spreadsheet containing columns: `Player ID`, `Term 1 %`, `Term 2 %`, `Term 3 %`, `Term 4 %`, `T1 Discipline`, `T2 Discipline`, `T3 Discipline`.
* **Description:** Worker stream-reads the file from the request body, processes rows asynchronously using SQLite prepared statements, handles errors, and updates database records inside a SQL transaction.
* **Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "rowsProcessed": 53,
    "inserted": 53,
    "updated": 0,
    "errors": []
  }
}
```

---

### E. Individual Player Dashboard Data
* **Method:** `GET`
* **Route:** `/api/players/:id/dashboard`
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
      "team": "A Team"
    },
    "academics": {
      "term1": 68.0,
      "term2": 64.0,
      "term3": null,
      "term4": null,
      "overallAvg": 66.0,
      "category": "🟢 University Ready",
      "trend": "Down",
      "flag": false
    },
    "fitnessBaselines": {
      "speed40m": 5.70,
      "speed60m": 8.37,
      "broadJump": 1.96,
      "pushUps": 25,
      "pullUps": 5,
      "squats40kg": 29,
      "verticalJump": 2.58,
      "tTest": 10.66
    },
    "matchAverages": {
      "matchesLogged": 3,
      "avgTackles": 8.2,
      "tacklePercentage": 0.85,
      "avgCarries": 5.4,
      "avgMetres": 22.1,
      "avgWorkRate": 4.1,
      "avgRating": 4.0,
      "avgScore": 3.6,
      "bestScore": 4.2
    }
  }
}
```
