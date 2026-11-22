# Work data → 5 Brains (planned, not built yet)

Jon's choices (23 Nov 2026): **Google Workspace** (VisionMade), pull **meetings**, **Drive docs/reports activity**
and **VMC git work volume/type**; Jon is the Workspace admin. To be done together, step by step.

## What gets stored (times, counts and categories only)
| Source | Stored | Never stored |
|---|---|---|
| Google Calendar | start/end, attendee count, 1-on-1 vs group, back-to-back flag, gap before/after | titles, descriptions, attendee names/emails |
| Google Drive (Drive Activity API) | edit timestamps per hour, file type (doc/sheet/slide) | file names, content |
| VMC git (repo ??? — vmc-app-2 / vmc-central-hub, Jon to confirm) | commits per hour, type bucket (build/fix/docs/test) | commit messages, code |

## Shape
- Supabase table `work_events (user_id, date, kind, start_at, end_at, attendees, meta jsonb)` + view
  `work_day` (meeting minutes, meeting count, max back-to-back run, deep-work minutes, commits). RLS owner-only.
- Supabase Edge Function `work-sync`, run hourly by `pg_cron`. Secrets: Google OAuth client id/secret +
  refresh token (read-only scopes `calendar.readonly`, `drive.activity.readonly`), GitHub fine-grained token
  (read-only Contents/Metadata on the chosen repo).
- 5 Brains reads `work_day` / `work_events`: Today meeting strip, pulses auto-tagged with the meeting just
  finished, "Your day by the clock" gets meetings + deep work, Dave report gets meeting load vs energy.

## Steps for Jon (later, one at a time)
1. Google Cloud console → OAuth client (Web) + consent screen (Internal) → one sign-in to mint the refresh token.
2. GitHub → fine-grained token, read-only, the chosen VMC repo.
3. Laptop Claude Code session: deploy `work-sync`, set secrets, schedule cron, apply SQL.
