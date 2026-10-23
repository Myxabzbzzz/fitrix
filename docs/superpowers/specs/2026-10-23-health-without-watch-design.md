# Wave 2D+: Health that is useful without a watch — Design

Date: 2026-10-23. Owner: Муха. Status: the four items approved by Муха in chat («давай все четыре»); numbers and placement are Claude's calls, stated to Муха.

## Why

Муха connected Apple Health on his iPhone (no watch). The connection works (steps read for 31 days; today 14,146), but his Health holds only steps, and steps are shown in two small places and affect nothing — so it looks like Health gives nothing. Most users at first will be in the same place (phone only). FITRIX workouts are written to Health only after a workout is recorded (none yet) — that part works as designed.

## Goals

1. **Steps feed nutrition.** When Health is connected and today's steps are known, the daily calorie target adds `stepsKcal = round(clamp(steps − 5000, 0, ∞) × 0.04 × weightKg / 70)`, capped at 800 kcal. Carbs take the extra kcal (protein and fat stay per-kg). The nutrition screen shows a line «+N kcal for steps today (S steps)». The target rises during the day as steps grow. No steps / not connected → today's behaviour unchanged. Felix nutrition context gets the same targets (already flows from the targets).
2. **Steps always visible.** Home shows a compact steps tile (today's steps, 7-day average) whenever connected and today's steps are known — independent of the Today card / plan. The existing steps line inside the Today card is removed (no duplicate). Progress gets a "Steps" weekly bar chart (last 7 days from the daily cache, with average), shown only when connected and at least one day has steps.
3. **"From Apple Health" summary on the Connected apps screen.** Under the connected Health tile: for the last 7 days — days with steps, nights with sleep, days with resting HR, days with HRV, weigh-ins imported, workouts imported, workouts saved to Health. Zero counts are shown as zero (they are facts about the last 7 days, not today's values) with a one-line hint when everything except steps is zero: «No watch data yet — a watch (Apple Watch, Garmin, WHOOP, Mi Band) adds sleep, heart rate and workouts.» (Android variant without Apple Watch.)
4. **iPhone "in bed" sleep as a fallback.** If the night window has no asleep segments but has in-bed segments (iPhone Sleep schedule writes "In Bed"), last night's sleep = merged in-bed time, marked as in-bed. Check-in pre-fill label: «in bed, from {source}». Readiness, recovery and Felix use it like any sleep value. Awake segments never count.

## Non-goals

- Steps in readiness or training load.
- Walking/steps as workouts.
- Changing the Health permission set (steps, sleep already requested).

## Anti-goals

- A zero shown as "today's" value when a type is unknown (goal 3 counts are 7-day counts, labelled as such).
- Calorie target jumping by the steps bonus when Health is disconnected or steps unknown.
- In-bed time used when real sleep exists.

## Constraints

- Same as wave 2D (`docs/superpowers/plans/2026-10-23-health.md` Global Constraints): HealthSource boundary + fakes, l10n en/ru/uz/es (no plural-dependent wording), SE 375×667 ×1.3 no overflow, tests green, no cloud actions.
- The written-workouts ledger (`health_written_v1`) and imports store already exist; weigh-ins imported need a record — builder's call (e.g. remember imported weigh-in day keys in prefs).
