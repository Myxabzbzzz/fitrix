# SDD ledger — plan: docs/superpowers/plans/2026-10-25-cycling-skiing.md
Spec: docs/superpowers/specs/2026-10-25-cycling-skiing-design.md (owner «начинай»; Claude's calls marked)
Implementers sonnet; reviews opus.
## Pre-flight scan
| Pair / task | Produces vs consumes | Finding |
|---|---|---|
| T1↔T9 | backend field names avgSpeedKmh/maxSpeedKmh/elevationGainM/indoor/avgPowerW/ski{} | consistent |
| T2↔T3 | RunDetails.ski uses SkiDay from T3 but T2 comes first | CONFLICT → Ruling P1 |
| T3 | simplifyRoute must expose kept indices (T3 extends it, in run_track.dart owned by T2) | sequential, ok |
| T2↔T4 | ActivityProfile/profileFor, RunTrack(profile:) | consistent |
| T4↔T5 | events DistanceReached/SkiDescentDone consumed by voice | consistent |
| T4↔T6 | RunSession.kind, RunDetails extras | consistent |
| T6↔T7/T8 | live/summary routes reused | consistent |
| T7 | indoor ride RunDetails(indoor:true) needs kind ride, meters optional | RunDetails.meters non-null today → Ruling P2 |
Ruling P1: T2 adds RunDetails.ski as a raw `Map<String,Object?>? skiJson` passthrough? No — T2 leaves `ski` out; T3 adds `SkiDay? ski` to RunDetails together with SkiDay (T3 owns that field). — keeps tasks independent — cost: none.
Ruling P2: indoor ride stores meters = (km × 1000) or 0 with `indoor: true`; UI shows "—" when indoor and km not given (meters 0 + indoor means unknown). — avoids changing a non-null field used by running — cost: a 0 that means unknown only when indoor.
Task 1: dispatched (sonnet), BASE f8fc994
Task 1: implemented 60c3783 (backend 115; no RED step); review dispatched
Task 1: review (opus) → Approved. Minor (deferred): duplicated speed fragment / avgPowerW branches in describe; indoor false not pinned; no RED run recorded.
Task 1: complete (commits f8fc994..60c3783, review clean)
Task 2: dispatched (sonnet), BASE 60c3783
Task 2: implemented c817cc1 (1292 tests; live clock may step back ≤10 s after a long stop); review dispatched
Task 2: review (opus) → Needs fixes: 1 Important (auto-stop live clock not monotonic — steps back after stops ≥10 s, during slow sparse fixes, and on pause).
Ruling R1: grace version — non-moving gaps count min(gap, 10 s) (Garmin-like auto-pause grace); live tail and banked gap use the same function → monotonic, smooth. Spec "stops < 10 s don't stop the clock" still holds; a long stop adds 10 s. Test "30 s stop" expectation updated accordingly; add monotonicity tests. — cost: ~10 s per long stop counted as moving.
Ruling R2: include in this round (user-facing): maxSpeed rejects a single spike (median of fix-to-fix speeds over the ≥3 s window, or equivalent) with a tight test; partial ride split label = its real distance (not the next 5-km label) + fix the doc comment; maxRunSpeed kept only as runProfile's source or removed.
Task 2: minor (deferred): first fix ≥10 s after start/resume loses that time; elevation computed twice for gain/loss
Fix round 1 sent (FIX_BASE c817cc1).
Task 2: fix round 1/5 (4 addressed, 0 open; commits c817cc1..b5d223c) — 1295 tests
Task 2: minor (deferred): maxSpeed O(n·w) sort per fix; sub-2-segment sprints discounted (by design)
Task 2: complete (commits 60c3783..b5d223c, review clean)
Task 3: dispatched (sonnet), BASE b5d223c
Task 3: implemented 412920c (1307 tests); review dispatched
Task 3: review (opus, with probes) → Needs fixes: 1 Critical (fixed 8 m trim band → lifts lost after ordinary queues with correlated noise; descents swallow idle time), Important: descent needs only ≥30 m drop (phantom descents while standing in queues), tests use uncorrelated noise, descent avgSpeed includes stops.
Ruling S1 (supersedes plan thresholds where they conflict): (a) trim legs by last crossing at the start / first crossing at the end of the hysteresis band; (b) stationary stretches (ground speed < 0.5 m/s for > 2 min) split legs and become "other"; (c) descent also needs ≥ 100 m ground distance at moving ground speed ≥ 1.5 m/s; (d) lift: climb ≥ 0.3 m/s (slow fixed-grip chairs) and ground speed ≤ 12 m/s (trams); (e) descent avgSpeed = distance / moving time (fix-to-fix ≥ 1 m/s), duration = trimmed leg; (f) tests with random-walk correlated altitude noise (~±4–9 m), 10–20 min queues, lift base 10–14 m above run end, 5–10 min mid-run stop, 40 min hut stop, 35 m drift during lunch. Spec "Claude's calls" updated to match. — real-world robustness for the anti-goals — cost: thresholds may need tuning after a real ski day.
Ruling S2 (parked, tell owner): riding a gondola/lift DOWN and a ≥35 m mid-station dip can still count as a descent — needs real data; documented as a known limitation.
Task 3: minor (deferred): ski_math↔run_track import cycle; wall-clock perf assertion under -j 4
Fix round 1 sent (FIX_BASE 412920c).
Task 3: fix round 1/5 (a,c,d,e,f addressed; (b) open — interior stops inside a descent not split → ~1 h descents; commits 412920c..2dd4d96)
Ruling S3: follow the spec — split a descent at interior stationary stretches (≥ 2 min); each part keeps descent status only if it still meets the descent criteria, otherwise "other"; merge short (≤ 30 s) holes in stationary detection so jitter/shuffling queues stay one stop; fix the misleading comment; tests assert hut/lunch are "other" and each descent's duration is close to its moving time. Also fix robustMaxSpeed overstatement under white position jitter (16.8 vs 10 m/s at 2 m jitter): estimate from displacement over ≥ 3 s windows with spike rejection; tests with 2–3 m jitter within ~10 %.
Fix round 2 sent.
Task 3: fix round 2/5 (S3.1 addressed, S3.3 addressed but new Important: no spike rejection at range/segment starts; S3.2 queue tests single-seed; commits 2dd4d96..9037e95). Fix round 3 sent: centred median block + edge tests + multi-seed queue tests + doc comment.
Task 3: fix round 3/5 (2 addressed, 0 open; commits 9037e95..756a491) — 1323 tests
Task 3: complete (commits b5d223c..756a491, review clean; known limitation S2 parked)
Task 4: dispatched (sonnet), BASE 756a491
Task 4: implemented 6c755b5 (1334 tests); concerns: ski 2 m distanceFilter vs stationary detection, 1.5 MB prefs JSON per 30 s on long ski days; review dispatched
Task 4: review (opus, real-recorder probes) → Needs fixes: I1 ski segmentation fed kept fixes → stops are gaps, stationary rule never fires (stalled lift counted as ski time/load; hut stop not split); I2 Health ski distance includes lifts; I3 crash-recovery writes 1–3 MB JSON to prefs every 30 s and restore is quadratic on the UI isolate.
Ruling K1: make ski_math stationary detection gap-aware (a step with dt ≥ 15 s and speed < 0.5 m/s counts as still for its span; gaps are stop boundaries); recorder-level tests (jittery 10-min hut stop splits; 4-min chairlift stall stays one lift, liftTime excludes nothing extra) through the real recorder.
Ruling K2: for ski, RunDetails.meters = descent-only distance (SkiDay.skiMeters) — spec 13 "ski distance (descents only)"; Health and Felix read it.
Ruling K3: in-progress persistence for all kinds: small header in prefs + append-only fix log file in the app support directory (path_provider), flushing only new fixes every 10–30 s, tolerant of a truncated last line, deleted on end; one-time migration from the legacy prefs payload; restore builds the track in one pass (no quadratic copies). Running behaviour unchanged (tests green).
Fix round 1 sent (FIX_BASE 6c755b5).
Task 4: fix round 1/5 (K1, K2, K3, minors addressed; new Important: 30 s–2 min breather mid-descent splits live SkiDescentDone; minors: unguarded file reset in start, truncate-before-write in restore rewrite, fix file not deleted on sign-out/account switch; commits 6c755b5..fb95508)
Ruling K4: fix in round 2 — descent "done" when followed by kept movement after 30 s, or when no kept fix follows only after the 2-min stop threshold; guard reset() like _persist; restore rewrite = temp file + rename (or truncate after last newline) and a failed rewrite keeps the session; AppSession signOut/clearLocalData (or recorder on generation change) deletes the fix file; flush unflushed fixes on dispose.
Fix round 2 sent.
Task 4: fix round 2/5 (5 addressed, 0 open; commits fb95508..a32d94e) — 1354 tests
Task 4: minor (deferred): fix file deleted lazily (when main shell builds after sign-out, not at sign-out); _flushed advanced after a swallowed rewrite failure can glue one fix to a cut-off line; constructor deletes file on unparsable header
Task 4: complete (commits 756a491..a32d94e, review clean)
Task 5: dispatched (sonnet), BASE a32d94e
Task 5: implemented a98e533 (1370 tests; no RED; kind read from session, last kind kept for finish); review dispatched
Task 5: review (opus) → Needs fixes: 1 Critical (restored ride/ski saved without resuming → RunFinished resolves to _lastKind=run → run-worded finish spoken under run's voice setting). ⚠️ gear on Cycling/Skiing → Tasks 7/8 (carried).
Ruling V1: carry kind on every RunEvent that lacks a fixed kind (RunStarted/Paused/Resumed/Finished) emitted from the session; drop _lastKind; test session cleared before RunFinished with ride voice off/run on → silent; on→off toggle test; fold in wording: uz "{index}-tushish", spoken "kilometr soatiga" instead of "km/soat"; es "velocidad máxima", ride start wording; ru «Заезд» instead of «Поездка».
Task 5: minor (deferred): queued phrases still play after voice off; ru bare "м" TTS expansion; fire-and-forget prefs save; no RED.
Fix round 1 sent (FIX_BASE a98e533).
Task 5: fix round 1/5 (2 addressed, 0 open; commits a98e533..a296387) — 1372 tests
Task 5: complete (commits a32d94e..a296387, review clean)
Task 6: dispatched (sonnet), BASE a296387
Task 6: implemented 512c3fd (1384 tests; fixed Save dropping kind/ski via RunDetails.withRpe); review dispatched
Task 6: review (opus) → Approved. ⚠️ indoor log note → T7 (Ruling: T7 adds optional `note` to RunDetails, JSON 'note', ≤500 chars, shown on the summary).
Task 6: minor (deferred; #2 likely must-fix at final): two segmentation passes per scan; live "time on slopes" can step back when a lift is recognised late; ski distance fallback to whole-track meters; highlight test checks property only; currentSpeed shows "--" right after a stop; small inefficiencies; indoor-with-distance not at SE×1.3, live ski paused not at SE×1.3; extra live-screen gear (harmless)
Task 6: complete (commits a296387..512c3fd, review clean)
Task 7: dispatched (sonnet), BASE 512c3fd
Task 7: implemented 165961b (1399 tests); review dispatched
Task 7: review (opus) → Approved. ⚠️ Outdoor plan-done relies on recorder finish keeping templateId (T4 tests cover it — confirmed).
Ruling C1: carry into T8 — make run_dialogs (askUnfinishedRun / confirmDiscardRun) kind-aware wording (run/ride/ski) since rides and ski days now reach them; localized power unit "W"/"Вт"; ru «В помещении (запись)».
Task 7: minor (deferred): 'Indoor ride' fallback name English; template id literals repeated; import order; doc line >80; test name overclaims indoor; no Football→Cycling pill test; Outdoor test doesn't assert plan done
Task 7: complete (commits 512c3fd..165961b, review clean)
Task 8: dispatched (sonnet), BASE 165961b
Task 8: implemented 9b1c3b2..2993dc9 (1414 tests; C1 wording everywhere); review dispatched
Task 8: review (opus) → Needs fixes: I1 duplicated start logic (ski/cycling/_beginRun ×3) blocks one-place fixes; I2 planned-start "marks done" test doesn't finish/assert. Also remaining run wording A–C (location-off snacks, finish failed, not found) — in C1 scope.
Ruling K8: extract shared startFreeActivity(context, ref, kind) + _beginRun with nullable template; kind-aware location-off / finish-failed / not-found strings; es ski launch body masculine; plan-done tests finish through the recorder; rename misleading test.
Fix round 1 sent (FIX_BASE 2993dc9).
Task 8: fix round 1/5 (4 addressed, 0 open; commits 2993dc9..13f76bc) — 1414 tests
Task 8: minor (deferred): _Figure / history provider duplicated between cycling and skiing; redundant select in bar; no SE check for bar title/ride labels; Winter sports tile without image
Task 8: complete (commits 165961b..13f76bc, review clean)
Task 9: dispatched (sonnet), BASE 13f76bc
Task 9: implemented 585f593 (1419 tests, backend 115); review dispatched
Task 9: review (opus) → Needs fixes: 1 Important (Health-imported cycling/winterSports get running pace via _importDistanceJson). Fix round 1 sent incl. empty ski day omits ski block, field-level >300 guard, ski kind without ski block test.
Task 9: fix round 1/5 (4 addressed, 0 open; commits 585f593..f478825) — 1421 tests
Task 9: complete (commits 13f76bc..f478825, review clean)
Final review: dispatched (opus), range f8fc994..f478825
Final review (opus, real-recorder probes) → With fixes: I1 live "time on slopes" saw-tooths on every lift (up to 53 s back); I2 queues/huts/lunch count as slope time and load (spec goal 14 as written); I3 any restore failure deletes the whole fix file. Minors triaged: 'Indoor ride' English fallback (must), partial split label rounds past distance, GPS weak while standing on ski, ski bar/resume km incl. lifts, Info.plist text "runs".
Ruling F1: live slope time monotonic — bank the scan value at scan time, then add elapsed only while not on a lift; never decreases.
Ruling F2 (Claude's own spec call, told to owner): ski duration/load/"time on slopes" = day − lifts − manual pauses − stationary stretches > 2 min (queues, huts, lunch). Spec goal 14 updated. Cost if wrong: walking in boots isn't counted.
Ruling F3: delete the fix file only when there is no header at all; on a parse/restore failure rename the file aside (…fixes.broken) and keep it.
Ruling F4: localize the indoor-ride fallback name; last partial split label never past the distance covered; ski GPS "weak" not shown while standing after a good fix; ski bar/resume prompt show descent km (or no km) consistent with summary; Info.plist location text mentions runs, rides and ski days. BIKING stays (stationary type unsupported on Android).
Final fix wave: dispatched (sonnet), FIX_BASE f478825
Final fix wave: re-review → F1–F4 ADDRESSED (probes: 0 clock step-backs; kill/restore ok). Residual minors: ride summary partial split shows label "5","5"/"0" (my F4 ruling changed the label without updating the display — visible on Муха's first ride); stale .broken when header exists but file missing; es "Salida en interior".
Ruling F5: complete F4 in the same wave — ride summary shows a partial split as formatKm(meters) like runs do; delete an older .broken when setting aside a header with no file; es «Ciclismo en interior».
Final fix wave F5: re-review ADDRESSED (8ee48ea..276c65e). Controller verified at HEAD: analyze clean, flutter test 1442 passed (5 skipped), backend 115/115.
Final review: complete (f8fc994..276c65e). Parked for owner/device: battery over a 5–8 h ski day; thresholds on real resort data (S2); Android untested.
