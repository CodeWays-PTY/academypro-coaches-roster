# uSPORT Player Development Tracker — Auto-Score Algorithm Specification

To standardise match metrics, the Excel tracker uses an automated match evaluation score. This document outlines the exact weights, formulas, and implementation rules to translate the Excel formulas into the Hono backend API.

---

## 1. The Core Formulas (From Excel)

In the spreadsheet, the `Auto Score` (Column 13, cell `M4`) uses this formula:
```excel
=IFERROR(ROUND(((E4/(E4+IF(F4=0,0.01,F4)))*2+(G4/10)+(H4/50)+MAX(0,(1-(I4+J4)/5))+(K4/5)*2.5+(L4/5)*2.5)/10*5,1),"")
```

The matching `Category` (Column 15, cell `O4`) uses this:
```excel
=IF(M4="","",IF(M4>=4,"🟢 Excelling",IF(M4>=3,"🟡 On Track",IF(M4>=2,"🟠 At Risk","🔴 Developing"))))
```

And `Tackle %` (Column 14, cell `N4`) uses this:
```excel
=IFERROR(E4/(E4+F4),"")
```

---

## 2. Breaking Down the Weights & Logic

The algorithm evaluates match play out of a standard **10-point baseline** (which is then scaled down to a 0–5 point rating). 

The 10 points are distributed as follows:

| Metric | Excel Cell | Weight / Max Points | Contribution % | Formula Logic |
| :--- | :--- | :--- | :--- | :--- |
| **Tackle Accuracy** | `E4` (Made) / `F4` (Missed) | **2.0 Points** | **20%** | Scales from 0 to 2 based on tackles made vs. missed. Avoids division-by-zero errors by using `0.01` if missed is zero. |
| **Carries Volume** | `G4` | **Uncapped** (~1.0 standard) | **10%** | Adds `0.1` points per carry. (10 carries = 1.0 point). |
| **Metres Gained** | `H4` | **Uncapped** (~1.0 standard) | **10%** | Adds `0.02` points per metre. (50m = 1.0 point). |
| **Discipline & Errors** | `I4` (Errors) / `J4` (Penalties) | **1.0 Point** (Max) | **10%** | Starts at 1.0 point. Deducts `0.2` points for every error or penalty conceded. Floors at `0.0`. |
| **Work Rate** | `K4` (Rating 1-5) | **2.5 Points** | **25%** | Scaled linearly: `(WorkRate / 5) * 2.5` |
| **Overall Rating** | `L4` (Rating 1-5) | **2.5 Points** | **25%** | Scaled linearly: `(OverallRating / 5) * 2.5` |

---

## 3. Mathematical Execution Code (TypeScript)

When the coach enters stats on their mobile app and clicks **Save**, the raw data is sent to the Cloudflare Worker. The Hono API calculates the metrics using this TypeScript function before writing to D1:

```typescript
interface MatchStatsInput {
  tacklesMade: number;
  tacklesMissed: number;
  carries: number;
  metresGained: number;
  errors: number;
  penalties: number;
  workRate: number;     // 1 to 5
  overallRating: number;  // 1 to 5
}

interface CalculatedMatchStats {
  autoScore: number;       // 0.0 to 5.0
  autoScorePercent: number; // 0% to 100%
  tacklePercentage: number | null; // 0 to 1
  category: string;        // Emojis + text
}

export function calculateMatchStats(input: MatchStatsInput): CalculatedMatchStats {
  const {
    tacklesMade,
    tacklesMissed,
    carries,
    metresGained,
    errors,
    penalties,
    workRate,
    overallRating,
  } = input;

  // 1. Tackle Accuracy (Max 2.0)
  const missedAdjustment = tacklesMissed === 0 ? 0.01 : tacklesMissed;
  const tackleAccuracyTerm = (tacklesMade / (tacklesMade + missedAdjustment)) * 2;

  // 2. Carries (10 carries = 1.0 pt)
  const carriesTerm = carries / 10;

  // 3. Metres Gained (50m = 1.0 pt)
  const metresTerm = metresGained / 50;

  // 4. Discipline (Max 1.0, deductions of 0.2 per error/penalty)
  const errorsAndPenalties = errors + penalties;
  const disciplineTerm = Math.max(0, 1 - (errorsAndPenalties / 5));

  // 5. Work Rate (Max 2.5)
  const workRateTerm = (workRate / 5) * 2.5;

  // 6. Overall Rating (Max 2.5)
  const overallRatingTerm = (overallRating / 5) * 2.5;

  // Calculate Raw Sum
  const totalPoints = 
    tackleAccuracyTerm + 
    carriesTerm + 
    metresTerm + 
    disciplineTerm + 
    workRateTerm + 
    overallRatingTerm;

  // Scale from 10 points to 5 points, round to 1 decimal place
  let autoScore = (totalPoints / 10) * 5;
  autoScore = Math.round(autoScore * 10) / 10;

  // Cap/Floor safety boundaries
  autoScore = Math.max(0, Math.min(5, autoScore));

  // Scale to 0-100% representation
  const autoScorePercent = autoScore * 20;

  // Calculate tackle percentage for database (nullable if no tackles attempted)
  const totalTackles = tacklesMade + tacklesMissed;
  const tacklePercentage = totalTackles > 0 ? (tacklesMade / totalTackles) : null;

  // Determine Category based on 5-point scale thresholds
  let category = "🔴 Developing";
  if (autoScore >= 4.0) {
    category = "🟢 Excelling";
  } else if (autoScore >= 3.0) {
    category = "🟡 On Track";
  } else if (autoScore >= 2.0) {
    category = "🟠 At Risk";
  }

  return {
    autoScore,
    autoScorePercent,
    tacklePercentage,
    category
  };
}
```

---

## 4. Scale Harmonisation (Excel vs. App Dashboard)

To present a unified RAG indicator across the ecosystem, the app harmonises academic percentages and sporting auto-scores:

| Pillar | 🟢 Green (Excellent) | 🟡 Amber (On Track) | 🟠 Orange (At Risk) | 🔴 Red (Danger) |
| :--- | :--- | :--- | :--- | :--- |
| **Mind (Academics)** | **65%+** (Uni Ready) | **60% - 64%** | **50% - 59%** | **<50%** |
| **Body (Sport Score %)** | **80%+** (Auto Score >= 4.0) | **60% - 79%** (Auto Score >= 3.0) | **40% - 59%** (Auto Score >= 2.0) | **<40%** (Auto Score < 2.0) |
| **Spirit (uGroups)** | Active (1) | Active (1) | Inactive (0) | Inactive (0) + Flagged |
