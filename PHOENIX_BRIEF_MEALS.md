# PHOENIX → 5 BRAINS: meal tick timestamps (brief for the Phoenix Claude Code session)

Jon ticks his meals ("feeds") in Phoenix. 5 Brains needs **the time of each tick**, so it can ask him where he ate and line meals up against his energy readings. At the moment Phoenix only syncs daily totals (`nutrition_daily`), and feed ticks stay on the device.

**Prerequisite:** apply `five-brains/supabase/2026-11-23_feed_events.sql`. It creates the shared table `feed_events`, keyed on `(user_id, date, feed_id)`, with owner-only RLS.

## Change (Phoenix side only)
1. **On every eaten toggle**, upsert one row with `onConflict:'user_id,date,feed_id'`:
   - Where: v2 is `nut2SetFeed(date, id, {eaten})`, plus the `data-n2-eat` / Today-tile handlers that call it. If v1 `ns.daily[dk].eaten[slot]` is still live, cover that too.
   - Row:
     ```js
     { user_id, date, feed_id: fd.id, name: fd.name, planned_time: fd.time,
       eaten: true|false,
       eaten_at: eaten ? new Date().toISOString() : null,   // the real tick moment
       kcal, protein_g,      // this feed's eaten totals, null if unknown (never 0 for unknown)
       source: 'phoenix', updated_at: now }
     ```
   - **Never send `location` or `note`.** 5 Brains owns those, and a PostgREST upsert only overwrites the columns it is sent.
   - Re-ticking a feed that is already eaten must not move `eaten_at`. Only a false → true change stamps the time.
2. **Cloud writes never swallow errors** (house rule 8). Use `_phxRecordWriteError` as usual.
3. Do not block the tick UI on the network. Fire and forget, with the usual retry.
4. Follow the usual gates: runtime check, harness, `APP_VERSION` bump, push.

## What 5 Brains already does (live in v1.6.0)
- It reads today's `feed_events`. Each ticked feed shows its tick time and asks "where were you?" with chips such as Home, Office, Car and Café/out.
- It writes only `location` and `note`.
- Manual meal logging stays available as a fallback.
