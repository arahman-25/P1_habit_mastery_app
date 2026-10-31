# AI_FEATURE.md — "Garden Guide" Smart Helper Specification & Evaluation

> **Project**: Habit Mastery App (Topic: Habit Mastery League)  
> **Course**: CSC4360 Mobile Application Development · Georgia State University · Fall 2026  
> **Team**: Anti-Procrastinators (Jamal Lyons, Areeb Ur Rahman)  
> **Feature**: Smart Helper ("Garden Guide" Target Estimator)  
> **Implementation**: `habit_mastery_app/lib/services/garden_guide.dart`  
> **Verification Suite**: `habit_mastery_app/test/garden_guide_test.dart`  

---

## 1. Feature Overview & Design Philosophy

### The Problem
Traditional habit trackers rely on rigid streaks that punish users for normal life disruptions. A single missed day shames the user and resets counters to zero, leading to guilt, demotivation, and eventual app abandonment. Furthermore, users often set unrealistic targets (e.g., jumping immediately to 7 days per week), experience friction, and quit.

### Our Solution: The "Garden Guide"
The **Garden Guide** is an on-device smart helper designed around the core philosophy:
> *"Grow a routine. Not a guilt trip. Missed days are information, not failure."*

Instead of punitive streaks, Garden Guide observes the user's authentic practice routine over the **last three completed Monday–Sunday calendar weeks** and recommends a realistic, calibrated weekly target (between 1 and 7 days).

---

## 2. Honest Labeling & Method Justification

### Honest Labeling
In accordance with course academic integrity guidelines and software transparency standards, the **Garden Guide** is **honestly and explicitly labeled as a rule-based algorithm**, not a deep learning, neural network, or large language model.

### Why a Rule-Based Approach?
We intentionally selected a deterministic, rule-based approach rather than cloud AI/ML for four fundamental engineering and psychological reasons:

1. **100% Offline & Local (Zero Cloud Dependencies)**:
   - Cloud AI requires network round-trips, active internet connections, API keys, and external servers.
   - Habit tracking is deeply personal; our app keeps all habit and check-in records strictly on-device in SQLite. A rule-based helper executes in microseconds with zero network calls and zero cloud battery drain.
2. **Deterministic & Verifiable**:
   - Machine learning inference can produce unpredictable hallucinations, drift, or non-deterministic outputs.
   - For a student building self-efficacy, target suggestions must be mathematically reproducible, auditable, and consistent.
3. **Transparent Explainability**:
   - The user must always see the exact mathematical derivation of their suggestion (e.g., *"You practiced an average of 3.3 days over the last 3 full weeks"*). Black-box recommendations diminish user trust.
4. **User Agency & Non-Shaming**:
   - The helper suggests; the user decides. Recommendations are presented on a card with an explicit **"Apply Suggestion"** button. The app never silently modifies user targets. Missed days are treated as feedback to adjust expectations, never as moral failure.

---

## 3. Mathematical Formulation & Invariants

### 3.1 Input Data Invariants
1. **Whole, Completed Calendar Weeks Only**:
   - The algorithm evaluates distinct check-in counts from the **last 3 whole, completed Monday–Sunday local calendar weeks** occurring on or after the habit's `startedLocalDate`.
   - **Exclusion 1 (Current Week)**: The current, in-progress calendar week is strictly excluded because its count is incomplete.
   - **Exclusion 2 (Partial Start Weeks)**: Any partial week prior to the habit's first full Monday is excluded.
2. **Strict Daily Deduplication**:
   - Accidental duplicate taps on the same local calendar date are deduplicated via SQLite `UNIQUE(habitId, localDate)` and service-layer checks.
   - The maximum possible check-in count for any calendar week is strictly $7$.
3. **Valid Data Zero Handling**:
   - Weeks with 0 check-ins are valid historical data points and are **never skipped or discarded**. A user who practices 0 days in a completed week has that 0 factored into their 3-week average.

### 3.2 Target Calculation Formula
Given the three eligible completed week counts $(\text{Count}_1, \text{Count}_2, \text{Count}_3) \in [0, 7]^3$:

$$\text{Sum} = \sum_{i=1}^{3} \text{Count}_i$$

$$\text{Target} = \text{clamp}\left(\left\lfloor \frac{\text{Sum} + 1}{3} \right\rfloor, 1, 7\right)$$

#### Mathematical Rounding Behavior:
The term $\lfloor \frac{\text{Sum} + 1}{3} \rfloor$ performs fast, exact half-up integer rounding to the nearest whole integer:
- When $\text{Sum} \pmod 3 = 0$ (e.g., average $3.0$): $\lfloor \frac{3k + 1}{3} \rfloor = k$ (exact).
- When $\text{Sum} \pmod 3 = 1$ (e.g., average $3.33$): $\lfloor \frac{3k + 2}{3} \rfloor = k$ (rounds down to $k$, since $0.33 < 0.5$).
- When $\text{Sum} \pmod 3 = 2$ (e.g., average $3.67$): $\lfloor \frac{3k + 3}{3} \rfloor = k + 1$ (rounds up to $k+1$, since $0.67 \ge 0.5$).

#### Clamping Boundaries:
- Minimum target: **1 day per week** (ensures every active habit has a tangible goal; zero-practice weeks clamp to 1 to foster gentle re-entry).
- Maximum target: **7 days per week** (reflects maximum available days in a calendar week).

### 3.3 Insufficient History Fallback
- If the habit has existed for fewer than 3 completed calendar weeks, the function returns `null`.
- The UI displays: `"Not enough history. Practice for at least 3 full calendar weeks to receive smart target recommendations."`
- The user's existing target remains unchanged.

---

## 4. Baseline Comparisons

To demonstrate the efficacy of our rule-based Garden Guide, we compare it against standard alternative approaches:

| Dimension | Baseline A: Static / Fixed Targets | Baseline B: Streak Penalty Engine | Baseline C: Cloud ML / LLM Inference | Proposed: Rule-Based Garden Guide |
| :--- | :--- | :--- | :--- | :--- |
| **Adaptability** | None (user manually remembers to adjust) | None (binary pass/fail based on consecutive days) | High (adapts via generative prompts) | **High** (dynamically calibrated to recent 3-week reality) |
| **Psychological Impact** | Indifference / Demotivation when falling behind | High guilt; single missed day destroys streak | Variable; risk of patronizing or inappropriate advice | **Compassionate & Non-Shaming** ("Missed days are information") |
| **Privacy & Security** | Local | Local | Cloud leakage (transmits personal habit journals to 3rd party APIs) | **100% On-Device & Private** (Zero network calls) |
| **Latency & Battery** | Instant ($<1$ ms) | Instant ($<1$ ms) | Slow ($500-2500$ ms); drains mobile battery & data | **Instantaneous** ($<1$ ms pure Dart computation) |
| **Offline Reliability** | Works offline | Works offline | Fails completely when offline | **100% Offline Capable** (Airplane mode verified) |
| **Explainability** | N/A | Hard rules ("missed day = 0") | Black-box / Hallucination risk | **Transparent Math** (Shows 3-week average and exact formula) |
| **User Agency** | Manual only | Automated punishment | Unpredictable suggestions | **Opt-in Confirmation** ("Apply Suggestion" button) |

---

## 5. Verification: Five Mandatory Evaluation Test Fixtures

All five test fixtures are implemented and automated in `habit_mastery_app/test/garden_guide_test.dart`.

```text
habit_mastery_app/test/garden_guide_test.dart
  Garden Guide Pure Dart Algorithm — 5 Mandatory Evaluation Fixtures
    ✓ Fixture 1 (Normal Case): [2, 3, 4] yields average 3.0 and suggests target 3
    ✓ Fixture 1 Extension (Normal Rounding): half-up rounding checks
    ✓ Fixture 2 (No-Data Case): returns null and displays "Not enough history" when < 3 weeks
    ✓ Fixture 3 (Invalid Case): rejects invalid weekly counts when sanitize is false
    ✓ Fixture 3 Extension (Invalid Sanitization): clamps values into [0, 7] when sanitize is true
    ✓ Fixture 4 (Boundary Case): [0, 0, 0] clamped to min 1; [7, 7, 7] clamped to max 7
    ✓ Fixture 5 (Counterexample - Zero Weeks): treats 0-count weeks as valid data, not skipped
    ✓ Recommendation messaging reflects user agency and non-shaming philosophy
  GardenGuide & CheckInService SQLite Integration Tests
    ✓ Fixture 5 Integration: Duplicate check-in attempts on same day do not inflate week count and zero-count weeks count as valid data
    ✓ evaluateForHabit returns insufficient history when habit is too new
```

### Evaluation Matrix

| Fixture ID | Category | Test Input (`weeklyCounts`) | Expected Output | Formula Derivation | Pass Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Fixture 1** | **Normal Case** | `[2, 3, 4]` | `suggestedTarget = 3`<br>`average = 3.0` | $\text{Sum} = 9$<br>$\lfloor (9 + 1)/3 \rfloor = \lfloor 10/3 \rfloor = 3$<br>$\text{clamp}(3, 1, 7) = 3$ | **PASSED** |
| **Fixture 2** | **No-Data Case** | `null`<br>`[]`<br>`[4]` (1 week)<br>`[3, 5]` (2 weeks) | `suggestedTarget = null`<br>`hasEnoughHistory = false`<br>Message: *"Not enough history"* | Input length $< 3$ completed weeks.<br>Returns `null` fallback. | **PASSED** |
| **Fixture 3** | **Invalid Case** | Negative: `[-1, 3, 4]`<br>Value $>7$: `[8, 2, 3]` | `ArgumentError` (when `sanitize: false`)<br>Clamped to $[0, 7]$ (when `sanitize: true`) | Rejection prevents corrupt state.<br>Sanitization clamps $[-2, 3, 4] \to [0, 3, 4] \to \text{target } 2$. | **PASSED** |
| **Fixture 4** | **Boundary Case** | Zero: `[0, 0, 0]`<br>Near-zero: `[1, 0, 0]`<br>Max: `[7, 7, 7]`<br>Near-max: `[6, 7, 7]` | `[0, 0, 0] -> 1`<br>`[1, 0, 0] -> 1`<br>`[7, 7, 7] -> 7`<br>`[6, 7, 7] -> 7` | $\text{Sum} = 0 \to \lfloor 1/3 \rfloor = 0 \xrightarrow{\text{clamp}} 1$<br>$\text{Sum} = 1 \to \lfloor 2/3 \rfloor = 0 \xrightarrow{\text{clamp}} 1$<br>$\text{Sum} = 21 \to \lfloor 22/3 \rfloor = 7 \xrightarrow{\text{clamp}} 7$ | **PASSED** |
| **Fixture 5** | **Counterexample & Integrity** | Zero practice week: `[0, 3, 3]`<br>SQLite duplicate check-in taps | `suggestedTarget = 2`<br>`average = 2.0`<br>Single day duplicate taps blocked | `0` is valid data: $\text{Sum} = 6 \to \lfloor 7/3 \rfloor = 2$.<br>Duplicate dates do not inflate week count beyond distinct days. | **PASSED** |

---

## 6. Code Architecture & Component Reference

### 6.1 Pure Function: `suggestWeeklyTarget`
Located in `habit_mastery_app/lib/services/garden_guide.dart`:
```dart
int? suggestWeeklyTarget(
  List<int>? weeklyCounts, {
  bool sanitize = false,
}) {
  if (weeklyCounts == null || weeklyCounts.length < 3) {
    return null;
  }

  // Use the last 3 whole completed weeks
  final recentCounts = weeklyCounts.sublist(weeklyCounts.length - 3);

  final List<int> processedCounts;
  if (sanitize) {
    processedCounts = recentCounts.map((c) => c.clamp(0, 7)).toList();
  } else {
    for (final c in recentCounts) {
      if (c < 0 || c > 7) {
        throw ArgumentError.value(
          c,
          'weeklyCounts',
          'Weekly check-in count must be between 0 and 7 days (received $c).',
        );
      }
    }
    processedCounts = recentCounts;
  }

  final sum = processedCounts.fold<int>(0, (acc, val) => acc + val);
  final rawTarget = ((sum + 1) / 3).floor();
  return rawTarget.clamp(1, 7);
}
```

### 6.2 Data Transfer Object: `GardenGuideRecommendation`
Provides structured feedback for user-facing UI cards:
- `int? suggestedTarget`: The recommended weekly target.
- `int? currentTarget`: The user's active habit weekly target.
- `double? averageDaysPerWeek`: Exact arithmetic mean of completed practice.
- `List<int> completedWeekCounts`: The 3 week counts used.
- `bool hasEnoughHistory`: Flag indicating whether recommendation is available.
- `String headline`: Empathetic status summary (e.g. *"Ready to Bloom"*, *"Gentle Adjustment"*, *"Target Well-Calibrated"*).
- `String rationale`: Transparent mathematical breakdown ensuring complete explainability.
- `bool get shouldSuggestChange`: True when recommendation differs from active target.

### 6.3 Service Bridge: `GardenGuide.evaluateForHabit`
Connects `CheckInService` with SQLite to extract chronological completed week counts and evaluate the habit in a single call for UI screens.

---

## 7. Compliance Verification Checklist
- [x] **Zero Cloud Calls**: Verified with automated unit tests without network mocking.
- [x] **Pure Dart Core**: Calculation logic has zero Flutter UI or native platform dependencies.
- [x] **Honest Labeling**: Clearly documented as a deterministic rule-based estimator.
- [x] **Five Evaluation Fixtures**: All 5 test cases verified with green automated tests.
- [x] **User Agency**: Recommendations require explicit user opt-in ("Apply Suggestion").
- [x] **Non-Shaming**: Error and adjustment messages emphasize that *"Missed days are information, not failure."*
