# Claude Code hand-off: deploy 5 Brains

Open Claude Code in `~/Desktop/five-brains-app` and paste this in.

---

You are deploying **5 Brains**, Jon's personal check-in and voice-journal PWA. Everything is already built and tested in this folder:
- `index.html` (single-file app)
- `sw.js`, `manifest.json`, `icons/`
- `supabase/2026-11-22_five_brains.sql`
- `SETUP.md` (read it first)
- `PHOENIX_BRIEF.md`

Do not rewrite the app. Deploy it, wire it up, and report back.

## Tasks, in order
1. **Supabase.** Apply `supabase/2026-11-22_five_brains.sql` to the Phoenix project (`mxtowhccuqarszcwpbkq`). It is idempotent.
   - Use the Supabase CLI if it's linked. Otherwise give Jon the exact steps for the SQL Editor and wait for him to confirm.
   - Then verify these exist with RLS on: `brains_day`, `brains_entry`, `daily_water` and the view `brains_wellbeing_day`.
2. **GitHub.** Create the repo `jontrick/five-brains` (public, or use `gh repo create` if the gh CLI is authed). Then, the same way as Phoenix (`~/Desktop/phoenix-sc/CLAUDE.md`):
   - `git init -b main`
   - add the remote
   - commit
   - `git push origin main`

   `reference/` is gitignored, so the sample report stays local. Verify the push with `git log origin/main --oneline -3`.
3. **Pages.** Enable GitHub Pages from `main` / root. Confirm `https://jontrick.github.io/five-brains/` loads and that `manifest.json` and `sw.js` return 200.
4. **Claude proxy CORS.** The app POSTs to `https://phoenix-coach.jon-d87.workers.dev`.
   - Check the worker's allowed origins.
   - If needed, add `https://jontrick.github.io` and redeploy, without changing anything else in the worker.
   - Verify with a test request using `Origin: https://jontrick.github.io`.
5. **Phoenix side.** This is a separate task in the `phoenix-sc` repo: implement `PHOENIX_BRIEF.md`.
   - Water sync via `daily_water`.
   - Pull weigh-ins from 5 Brains into `nutRecordWeight`.
   - Show a readiness chip from `brains_wellbeing_day`.
   - Follow Phoenix's usual version bump and deploy routine.
6. **Report back** with:
   - the live URL
   - SQL applied (yes/no)
   - worker CORS result
   - Phoenix version shipped
   - anything Jon must still do by hand

## House rules (same as Phoenix)
- No `alert()`, `confirm()` or `prompt()`: iOS PWAs suppress them. The app already uses an in-app `ask()` modal.
- Bump `APP_VERSION` in `index.html` and `VERSION` in `sw.js` on every push.
- Commit after every clean change.

## Do not
- Add an Anthropic API key to the client.
- Have Phoenix read `brains_entry`.
- Change the publishable Supabase key.
