# 5 Brains — setup (about 15 minutes)

A single-file PWA. It lives in its **own GitHub repo** and gets its own home-screen icon. It shares
the Phoenix Supabase project and your Phoenix login.

## 1. Supabase (one time)
Go to Supabase → SQL Editor, then paste and run **`supabase/2026-11-22_five_brains.sql`**. It creates:

| table / view | what it holds | who reads it |
|---|---|---|
| `brains_day` | daily check-ins, 5Brains scores, ticks | 5 Brains |
| `brains_entry` | journal transcripts and reflections (**private**) | 5 Brains only |
| `daily_water` | water total per day | **both apps** |
| `brains_wellbeing_day` (view) | sleep, energy, mood, stress, 5Brains scores and water. No journal text. | Phoenix |

RLS is on for every table, and each policy lets you see only your own rows. To revoke Phoenix's read access, run `drop view brains_wellbeing_day;`.

## 2. Deploy
1. Create a repo called `jontrick/five-brains`. Public is fine because no secrets are in the code; the Supabase key is the same publishable key Phoenix already ships.
2. Push `index.html`, `manifest.json`, `sw.js` and `icons/`, using the same Terminal/Claude Code flow you use for Phoenix.
3. In the repo, go to Settings → Pages and deploy from `main` / root. The app will be at `https://jontrick.github.io/five-brains/`.
4. Open that link in **Safari** on your iPhone, then tap Share → **Add to Home Screen**.

Optional: point a subdomain such as `brains.projectphoenix-app.com` at it with a `CNAME` file.

## 3. Reflection engine (Claude)
The app sends requests to your existing proxy, `https://phoenix-coach.jon-d87.workers.dev`, with model `claude-sonnet-4-5`.
That way, no API key sits on the phone.

In the app, go to **Settings → Reflection engine → Test connection**. If it fails with a CORS error, the worker
only allows `projectphoenix-app.com`. Add `https://jontrick.github.io` (or your subdomain) to its
`Access-Control-Allow-Origin` list and redeploy the worker.

Paste the key points of your EPP / 5Brains assessment into **Settings → About me**. Every reflection then uses them as context.

## 4. Voice
- **Mic button**: live transcription (en-AU) where iOS allows it. Apple has been patchy about allowing speech
  recognition inside home-screen apps. If it's blocked, the app tells you so.
- **Always works**: tap the text box and use the 🎤 on the iOS keyboard. Apple's dictation is on-device and accurate.

## 5. How the Phoenix link works

| direction | what | how |
|---|---|---|
| Phoenix → 5 Brains | session done, sets, weigh-in, kcal and protein vs target | reads `accountability_day` (live today) |
| 5 Brains → Phoenix | weigh-ins | upserts `daily_weigh_ins`, the same row Phoenix's morning check-in writes |
| 5 Brains → Phoenix | water | writes `daily_water`. **Phoenix needs a small change to read it (see PHOENIX_BRIEF.md)** |
| 5 Brains → Phoenix | sleep, energy, mood, stress, 5Brains scores | `brains_wellbeing_day` view. **Phoenix change needed (see PHOENIX_BRIEF.md)** |

The app applies the rules from Phoenix's own integration brief:
- Today's "not trained" counts as *not yet*, not a miss.
- Null kcal displays as **no data**, never as 0.
- Days follow Brisbane time.

## 6. Report for Dave (Dec 16)
Open it from Journal → **Report for Dave** (or Settings → Report).
- It covers Day 1 up to the session date set in Settings (default 16 Dec 2026).
- **✨ Write AI summary** drafts the summary, an assessment of each focus point, a draft optimal day, patterns, themes and questions for Dave.
  Journal entries are summarised as themes only. No raw transcripts go into the report.
- You can tap any drafted text to edit it before exporting.
- **Save as PDF** opens the print sheet. On iPhone, pinch out on the preview, then Share → Save to Files.
  If printing doesn't open from the home-screen app, tap **Download**, open the file in Safari, then Share → Print.

## 7. Daily flow
- **Morning**: sleep, energy, target for the day, 5Brains check, weigh-in.
- **Through the day**: log an **energy pulse** at highs, lows and after big meetings (energy, revs underneath, what you were doing, what came before it). Tap walk, snack or breathing after heavy blocks, add water, and record voice notes under Feelings or Ideas.
- **Evening**: energy, mood, stress, focus, whether the goalposts moved, whether you hit the original target, win, gratitude, and a review of tomorrow's diary.
- **Sunday**: Journal → Run weekly review.

Ticks marked **Req** decide whether a day counts as perfect. You can edit the list in Settings. Turn on strict mode for 75 Hard rules,
where a missed day offers a reset to Day 1.
