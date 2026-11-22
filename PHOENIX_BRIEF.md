# PHOENIX ← 5 BRAINS: integration brief (for the Phoenix Claude Code session)

5 Brains is Jon's separate journalling and 5Brains check-in PWA. It already **reads** `accountability_day` and
**writes** `daily_weigh_ins`, so no Phoenix change is needed for those. Two small additions on the Phoenix side
complete the two-way link. Prerequisite: `five-brains/supabase/2026-11-22_five_brains.sql` must already be applied.

## 1. Water: shared table `daily_water`
`(user_id, date, water_ml, target_ml, source, updated_at)`, PK `(user_id, date)`, RLS owner-only.
`date` is the Brisbane local day.

- **On water change** (`ns.daily[date].water_ml` mutates), upsert:
  `{user_id, date, water_ml, target_ml, source:'phoenix', updated_at: now}` with `onConflict:'user_id,date'`.
- **On app open and on visibility change**, select today's row. If `updated_at` is newer than the local
  write and `source = 'five-brains'`, set `ns.daily[today].water_ml = water_ml`. Leave `water_log` alone, so undo
  only reverses Phoenix's own taps.
- The rule is last write wins, which is fine because only one person ever taps.

## 2. Weigh-ins written by 5 Brains
5 Brains upserts `daily_weigh_ins` with `{user_id, date, weight_kg, logged_at}`. It never touches `photo_url` or `notes`.
**Known gap:** the Phoenix macro engine reads `ns.daily[date].weight_kg` (via `nutRecordWeight`), not the cloud row.
On app open, if `daily_weigh_ins` has a row for today and local `ns.daily[today].weight_kg` is empty, call
`nutRecordWeight(row.weight_kg, today)` and set the morning-card done flag. Otherwise a weigh-in logged in 5 Brains
won't move the targets and Phoenix will prompt for it again.

## 3. Readiness: view `brains_wellbeing_day`
```js
const { data } = await sb.from('brains_wellbeing_day').select('*').eq('date', today).maybeSingle();
```
Columns: `sleep_hours, sleep_quality, energy_am, energy_pm, mood, stress, focus, perfect_day,
five_brains (jsonb {red,orange,yellow,blue,pink: 1-10}), water_ml, water_target_ml`.

Suggested uses:
- Show a readiness chip on Today. For example, if sleep is under 6 h or energy_am is 4 or less, say so before a Max Effort day.
- Pass these scores as context to the coach chat.

**Null means not checked in yet.** Never treat it as a low score.

The view contains no journal text or free-text fields, by construction. Don't query `brains_entry` from Phoenix.
