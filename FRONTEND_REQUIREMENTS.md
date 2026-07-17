# uSPORT Player Development Tracker — Frontend & UX Requirements

This document specifies the UX guidelines, design tokens, and layout guidelines for both the **Alpine.js/Tailwind Web Portal** and the **Flutter Mobile Application**.

For detailed Flutter code-level component blueprints mapped directly from the HTML prototypes:
*   Coach Portal (Live Match Tracker & Command Center): See **[COACH_APP_DESIGN_SPEC.md](file:///C:/development/usport-player-tracker/COACH_APP_DESIGN_SPEC.md)**.
*   Student & Parent Portals (Journey Dashboard & Performance Overview): See **[STUDENT_PARENT_DESIGN_SPEC.md](file:///C:/development/usport-player-tracker/STUDENT_PARENT_DESIGN_SPEC.md)**.

---

## 1. Design Tokens & Sunlight-Optimised Colors

Because coaches use this system outdoors in direct sunlight, the UI uses a strictly **Light Mode** layout to prevent glare.

| Token | Class / Value | Purpose |
| :--- | :--- | :--- |
| **Canvas Background** | `bg-slate-50` / `#F8FAFC` | Main app background |
| **Surface Card** | `bg-white` / `#FFFFFF` | Panels, lists, forms |
| **Primary Text** | `text-slate-900` / `#0F172A` | High contrast body text |
| **Secondary Text** | `text-slate-500` / `#64748B` | Labels, details, descriptions |
| **Primary Accent** | `bg-blue-600` / `#2563EB` | Active buttons, primary focus |
| **Primary Hover** | `bg-blue-700` / `#1D4ED8` | Hover/active states |
| **Dividers** | `border-slate-100` / `#F1F5F9` | Section separating lines |

### RAG Indicator Styling
Soft, high-readability colors are paired with bold text to draw immediate attention without visually cluttering the screen:

*   🟢 **Green (65%+ Academics / 80%+ Sport):** `bg-green-100 text-green-800` (University Ready / Excelling)
*   🟡 **Amber (60%-64% Academics / 60%-79% Sport):** `bg-yellow-100 text-yellow-800` (On Track / Solid)
*   🟠 **Orange (50%-59% Academics / 40%-59% Sport):** `bg-orange-100 text-orange-800` (At Risk / Coach Action Required)
*   🔴 **Red (<50% Academics / <40% Sport):** `bg-red-100 text-red-800` (Danger / Intervention Required)

---

## 2. Web Portal UX Rules (HTML5 + Alpine.js + Tailwind)

### A. Core Layout & Navigation
*   **Sticky Header:** The header navigation panel must be fixed to the top (`sticky top-0 z-50`).
*   **Content Boundary:** The dashboard container holds a max-width of `1200px` (`max-w-7xl mx-auto px-4`).
*   **Custom Scrollbar:** Standardise thin scrollbars across all browsers:
    ```css
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: #f8fafc; }
    ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 3px; }
    ```

### B. Custom Form Inputs
To maintain a premium, cohesive SaaS feel, browser-native UI styles are completely overridden:
*   **Checkboxes & Radio Buttons:** Styled with custom borders and Tailwind accent colors (`accent-blue-600 focus:ring-blue-500`).
*   **Select Dropdowns:** Custom Alpine.js components render dropdowns (no native `<select>` tags).
*   **Text Inputs:** Clean borders, solid active shadows, and a clickable **`X`** icon to clear input values.
*   **No Alerts:** Use custom Alpine.js toasts/modals instead of native browser `alert()` or `confirm()` popups.

### C. Alpine.js Loading Protocol
All Alpine scripts must load in a specific, non-blocking order to prevent race conditions:
```html
<head>
  <!-- 1. Define Initialization Logic -->
  <script>
    document.addEventListener('alpine:init', () => {
      Alpine.data('dashboardStore', () => ({
        activeTab: 'roster',
        loading: false,
        init() {
          // Initialize states
        }
      }));
    });
  </script>
  <!-- 2. Load Alpine Plugins (with defer) -->
  <script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.14.0/dist/cdn.min.js"></script>
  <!-- 3. Load Core Library (with defer) -->
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.14.0/dist/cdn.min.js"></script>
</head>
```

---

## 3. Coach Mobile App UX Rules (Flutter)

### A. Navigation & Mobile Drawer
*   **Right-Side Drawer:** The main navigation panel slides in from the right.
    *   **Dimensions:** Occupies exactly **80%** of the screen width.
    *   **Overlay Backdrop:** The remaining **20%** screen visibility is covered with a dark backdrop-blur overlay (`backdrop-filter blur-sm`).
    *   **Content:** Contains navigation routes with icons at the top, and school helpdesk/support contacts fixed to the bottom.

### B. The "Tap & Go" Match Stats Panel
Coaches log metrics on the sideline without using mobile keyboards:
*   **Action Counter Card:** A scrollable list of players. Next to each name, large `+` and `-` button blocks surround the statistic value.
*   **Tactile Targets:** Tap buttons are at least `48x48 dp` to ensure reliable registration when running down the field.
*   **Vibrations:** Incorporate subtle haptic feedback triggers on each increment/decrement event.

```
+---------------------------------------------------+
| [Flanker] Liam Venter                             |
|                                                   |
| Tackles:   [ - ]   08   [ + ]   (Tackle %: 88%)   |
| Carries:   [ - ]   05   [ + ]                     |
| Errors:    [ - ]   01   [ + ]   [Save Stats]      |
+---------------------------------------------------+
```

### C. "Smart-Default" Attendance
*   **List Default:** Session attendance sheets default all listed team athletes to **Present**.
*   **Interaction:** The coach scrolls the list and simply taps/swipes left on the few absent/excused athletes.
*   **Result:** Submits in a single click, taking under 10 seconds.

---

## 4. Student Portal UX Rules (Flutter Charts)

*   **Radar Chart Dashboard:** An interactive radar chart showing balanced progress between Mind (Overall Academic %), Body (Match Day Averages), Spirit (uGroups Attendance), and Fitness baselines.
*   **PB Progression Line Graph:** Tracks weight training progression (Squat counts) and speed improvements (40m times) over Week 0, 8, and 16 milestones.
*   **Theme Integration:** The Flutter charts must use the same Electric Blue (`#2563EB`) primary colors, with grey grid lines and RAG markers.
