# Good Morning: Wake-Up Protocol

Research basis and default routine spec. Written 2026-11-14 for the app architecture session. It covers what the evidence supports, the exact default sequence, short and long variants, and the parameters users can adjust.

**One-paragraph summary.** No single intervention reliably removes sleep inertia in the first few minutes. The evidence base is small (many studies have n = 6–30). What the evidence does support well is narrower: grogginess is worst in the first ~15–30 min, snoozing and returning to bed prolong the drowsy period, and getting upright and moving raises *subjective* alertness. So the protocol focuses on **getting the person out of bed and keeping them out** until inertia has mostly passed. It does not promise instant sharpness. Verification matters more than the exact exercise: the user's real problem is going back to bed, and the strongest lever the app has is a **no-return guard** for roughly 20 minutes after the routine.

Confidence ratings used below:
- **High:** consistent across multiple studies or reviews.
- **Moderate:** at least one controlled study plus plausible mechanism, or consistent but mostly subjective outcomes.
- **Low:** single tiny study, indirect evidence, or mechanism only.
- **Popular / unsupported:** widely repeated claim without direct evidence.

---

## 1. Evidence summary per intervention

### 1.1 Sleep inertia itself (what we are fighting)
- **Finding:** Sleep inertia is impaired alertness and performance right after waking. It is worst in the first ~15–30 min, usually mostly gone within 30–60 min, and in some measures can persist longer. It is worse after sleep loss, when waking from deep (slow-wave) sleep, and when waking at an adverse circadian time (early for an evening type). The ~30 min figure is the common reference used in aviation fatigue rules.
- **Implication for the app:** The danger window is the first ~20–30 min. Any routine that ends at minute 3 and then lets the user lie down again leaves the main window unprotected.
- **Confidence:** High for the shape (worst early, decaying over tens of minutes). Moderate for exact durations, which vary a lot by study and measure.
- Sources: [Hilditch & McHill 2019, *Sleep inertia: current insights*](https://www.dovepress.com/sleep-inertia-current-insights-peer-reviewed-fulltext-article-NSS) · [EASA systematic review on sleep inertia duration and countermeasures](https://www.easa.europa.eu/en/downloads/139387/en) · [Korean population survey, mean self-reported grogginess ≈16 min, longer with anxiety and short sleep (2026)](https://www.neurologylive.com/view/korean-survey-analysis-shows-morning-sleep-inertia-associated-sleep-patterns-anxiety)

### 1.2 Reactive countermeasures overall
- **Finding:** A systematic review of countermeasures used *after* waking found no convincing evidence base for any single reactive countermeasure. Caffeine is the best candidate, though it works best when taken before sleep. Light, temperature, and sound show promise, mostly on subjective alertness.
- **Implication:** Combine several cheap, low-risk interventions and verify behavior. Do not market any single step as "the cure".
- **Confidence:** High that evidence is thin.
- Sources: [Hilditch, Dorrian & Banks 2016, *Time to wake up: reactive countermeasures to sleep inertia*, Industrial Health](https://www.jstage.jst.go.jp/article/indhealth/54/6/54_2015-0236/_article/-char/ja) · [Hilditch & McHill 2019](https://www.dovepress.com/sleep-inertia-current-insights-peer-reviewed-fulltext-article-NSS)

### 1.3 Physical activity right after waking
- **Direct test:** Kovac et al. 2021 woke 15 people from a 2 h nap. They did a **30 s high-intensity cycle sprint**, a 30 s low-intensity cycle, or nothing. Results:
  - Subjective sleepiness was lowest after high intensity, then low intensity, then rest.
  - The cortisol awakening response was largest after high intensity.
  - **Cognitive performance did not differ** between conditions.
  - The authors warn that people may *feel* more alert without performing better.
- **Supporting evidence:** Brief bouts of activity (stair climbing for a few minutes, short jogging) reliably raise self-reported energy and vigor. In one study of short sleepers, brief stair walking raised vigor more than a low dose of caffeine.
- **Why it still matters here:** The user's problem is falling back asleep, not test scores. Feeling less sleepy, being upright, and having a raised heart rate all work directly against returning to bed. Movement is also the step the camera can verify best.
- **Dose:** No dose-response data exist for waking. The only direct test used 30 s, and that produced a subjective effect. The default here uses about 45–60 s of vigorous calisthenics, preceded by a warm-up.
- **Choice of exercise:**
  - **Jumping jacks:** about 6–8 METs ("vigorous calisthenics" in the Compendium of Physical Activities), so they reach vigorous intensity within seconds. Whole-body, large arm movements make them easy to count with body-pose detection, and they need no equipment.
  - Downsides: high impact, noisy for neighbors below, and less suitable for people with joint problems, pregnancy, or pelvic-floor issues.
  - **Squats:** lower impact, quiet, also countable by pose (hip/knee angle), but slower to raise heart rate.
  - **Marching or high knees:** a good warm-up and low-impact substitute.
  - **Stretching:** low arousal, so not suitable as the main step. It is used as a 2-minute standing cool-down after the main exercise (see 1.15).
  - **Brisk walking:** verifiable by step count, and a natural fit for "leave the bedroom".
- **Confidence:**
  - Moderate that brief vigorous movement increases subjective alertness and lowers sleepiness.
  - Low that it improves objective cognition.
  - Low for any specific rep count. The numbers below are design choices, not findings.
- Sources: [Kovac et al. 2021, *The impact of a short burst of exercise on sleep inertia*](https://pubmed.ncbi.nlm.nih.gov/34606883/) · [Kovac et al. 2020 review, *Exercising caution upon waking*](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7155753/) · [Stenling et al. 2019, brief stair climbing and feelings of energy](https://frontiersin.org/article/10.3389/fpsyg.2019.02300/full) · [Randolph 2016, stair walking vs caffeine in short sleepers (thesis)](https://openscholar.uga.edu/record/14760/files/randolph_derek_d_201608_ms.pdf) · [MET values for jumping jacks / calisthenics (Compendium-based)](https://www.wikipedia.org/wiki/Metabolic_equivalent)

### 1.4 Safety: standing up and exercising seconds after waking
- **Initial orthostatic hypotension:** a blood-pressure drop within ~15 s of standing.
  - Light-headedness on standing is reported by almost all healthy young adults at some point, and about 20% of young people report it frequently.
  - In young people blood pressure usually recovers within ~20 s.
  - In adults 65 and over, prevalence is ~29% when measured continuously, and it is linked to falls.
  - Standing up straight from lying, then immediately jumping, is the riskiest combination.
- **Mitigation built into the protocol:** sit on the edge of the bed for ≥10 s, then stand. Walk for ≥20 s (that covers the ~15–20 s blood-pressure dip) before any jumping. Use a warm-up march.
- **Cardiovascular:** acute heart attacks and sudden cardiac death peak in the morning hours after waking. Sympathetic surge, raised blood pressure, and platelet activity are the likely causes, and exertion is a known trigger. A meta-analysis attributes ~1 in 11 heart attacks to the morning excess.
  - For a healthy young user, risk from 45 s of jumping jacks is very low.
  - The app still needs a health-screen opt-out, a low-impact mode, and a "stop / I feel dizzy" button that never counts as failure without a fallback.
- **Confidence:** High that brief dizziness on standing is common and transient. High that a morning cardiac peak exists. The safety margins (10 s sit, 20 s walk) are conservative design choices based on the ~15–20 s recovery time.
- Sources: [Initial orthostatic hypotension in teenagers and young adults (van Wijnen et al. 2016)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5104795/) · [Prevalence of initial orthostatic hypotension in older adults, meta-analysis](https://pmc.ncbi.nlm.nih.gov/articles/PMC8437071) · [Diagnostic timing review (recovery within ~20 s in young adults)](https://pmc.ncbi.nlm.nih.gov/articles/PMC7803043/table/tbl2) · [Circadian variation of ischemic cardiac events](https://pubmed.ncbi.nlm.nih.gov/7692150/) · [Cardiovascular triggers review (Tofler & Muller)](https://pubmed.ncbi.nlm.nih.gov/20890064/)

### 1.5 Light exposure
- **Directly on sleep inertia:**
  - **After waking from deep sleep at night:** blue-enriched light (as little as ~200 lux at the eye) for up to an hour improved subjective alertness and mood and reduced attention lapses versus dim red light.
  - **After a normal night's sleep in the morning:** light had little or no effect on sleep inertia. Gradual dawn simulation *before* the wake time (rising to ~250–300 lux over 30 min) helped subjective alertness more than switching on light at wake-up.
  - **After a nap:** 2000 lux for just 1 min gave a subjective boost comparable to caffeine, but no performance benefit.
- **Circadian effect (well supported, slower):** morning light shifts the body clock earlier, which makes future mornings easier, especially for late chronotypes.
  - Indoor light is typically ~100–300 lux. Outdoor daylight is ~1,000–100,000 lux (thousands even when overcast).
  - A week of natural light shifted melatonin timing earlier.
  - Clinical light boxes use 10,000 lux for 30 min. An expert consensus recommends ≥250 melanopic EDI during the day.
  - The popular "5 minutes of sunlight resets your clock" claim has no established threshold behind it.
- **Implication:**
  - Immediately: turn on room lights or open curtains (cheap, maybe helpful subjectively, and it keeps the room "awake").
  - Within the first hour: go outside or sit by a bright window for a meaningful dose. This is a full-variant step and a long-term benefit.
  - The phone can trigger a dawn simulation only with smart bulbs (HomeKit). Treat that as optional.
- **Confidence:**
  - Low–Moderate for light as an acute inertia countermeasure after normal morning waking.
  - High for morning outdoor light shifting the circadian clock earlier.
  - Moderate for pre-wake dawn simulation on subjective alertness.
- Sources: [Hilditch et al., morning sleep inertia and white light (PLoS ONE 2013)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3832615/) · [Gabel et al. 2013, dawn simulation vs blue light](https://orbi.uliege.be/bitstream/2268/171514/1/Gabel_CI_2013.pdf) · [Blue-enriched light after slow-wave-sleep awakening (2022)](https://pmc.ncbi.nlm.nih.gov/articles/PMC9787581) · [NASA-funded light and sleep inertia study](https://ntrs.nasa.gov/citations/20220012907) · [Hayashi, Masuda & Hori 2003 (caffeine, bright light, face washing after a nap)](https://pubmed.ncbi.nlm.nih.gov/14652086/) · [Wright et al. 2013, natural light camping study](https://www.Gwern.net/doc/melatonin/2013-wright.pdf) · [Discussion of outdoor vs indoor lux and the "5 minute" claim](https://scienceblog.com/t-morning-sunlight-body-clock-five-minute-rule-window-glass/)

### 1.6 Cold water on the face / cold shower
- **Finding:**
  - In the only controlled study found, washing the face after a 20 min nap produced a **mild and transient** drop in subjective sleepiness right afterwards and no lasting performance benefit (n = 10).
  - Cold-hand-immersion and extremity-cooling ideas exist, but direct published results are scarce.
  - No controlled study was found showing that a cold shower reduces sleep inertia.
- **Implication:** A cold face splash is cheap and gets the user to the bathroom, which is out of the bedroom. Use it as a *location* step and a brief jolt, not as a core intervention. Cold showers are an optional user preference only.
- **Confidence:** Low (face splash: small transient subjective effect). Popular / unsupported for a cold shower as an inertia cure.
- Sources: [Hayashi, Masuda & Hori 2003](https://pubmed.ncbi.nlm.nih.gov/14652086/) · [Hilditch et al. 2016 review](https://www.jstage.jst.go.jp/article/indhealth/54/6/54_2015-0236/_article/-char/ja)

### 1.7 Hydration
- **Finding:**
  - Losing ~1.5–2% of body mass to dehydration increases fatigue and lowers alertness and mood. It also slightly impairs vigilance and attention.
  - No study tested a glass of water *on waking* as a sleep-inertia countermeasure.
  - Overnight fluid loss is usually well under 1–2% of body mass, so for most people the effect is modest.
- **Implication:** Drinking 250–500 ml is harmless, cheap, and builds a habit, and it requires walking to a water source (out of the bedroom). Low priority, and only in the default and full variants.
- **Confidence:** Moderate that dehydration of ≥1.5–2% hurts alertness. Low that morning water measurably reduces sleep inertia.
- Sources: [Ganio et al. 2011, mild dehydration impairs cognition and mood in men](https://pubmed.ncbi.nlm.nih.gov/21736786/) · [Cognitive performance and dehydration review (2012)](https://pubmed.ncbi.nlm.nih.gov/22855911/)

### 1.8 Caffeine timing
- **Finding:**
  - Caffeine is the best-supported pharmacological countermeasure.
  - Swallowed caffeine takes time to absorb, so caffeine taken *after* waking does little for the first ~15–20 min.
  - Caffeine gum (200 mg) improved response speed at ~12–18 min after waking in one study.
  - The strongest effect comes from caffeine taken *before* the sleep period, as in the "caffeine nap" (200 mg before a nap). That suits naps, not overnight sleep.
- **"Wait 90 minutes after waking before coffee":** no trial supports it. A 2024 review found no evidence for the rule, and sleep researchers describe the timing as personal preference. Classified as **popular / unsupported**.
- **Implication:** The app should not delay or forbid coffee. Optionally, it can remind the user to have caffeine early if they use it, while advising against caffeine within ~8 h of bedtime (standard sleep hygiene). Not a verified step.
- **Confidence:** Moderate–High for caffeine as an alertness aid (with a ~15–30 min onset). Low for caffeine taken after waking having any effect in the first 15 min. Popular / unsupported for the 90-minute delay.
- Sources: [Hilditch et al. 2016 review](https://www.jstage.jst.go.jp/article/indhealth/54/6/54_2015-0236/_article/-char/ja) · [Caffeine and sleep inertia, oral bioavailability note (2021)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8492773) · [Caffeine-nap pilot, n = 6 (2020)](https://pubmed.ncbi.nlm.nih.gov/32819191/) · [Univ. of Arizona on the 90-minute coffee rule](https://psychiatry.arizona.edu/node/1960) · [Sleepopolis summary of the delayed-caffeine controversy](https://sleepopolis.com/news/controversy-over-wait-to-caffeinate-rule/)

### 1.9 Alarm sound (melodic vs harsh)
- **Finding:**
  - Survey: alarm sounds rated as **melodic** were associated with less self-reported sleep inertia (n = 50).
  - Small at-home study: a melodic alarm reduced attention lapses and false starts on a vigilance test compared with a harsh "beep" control, with no difference in raw reaction time (two groups of 10).
  - Harsh alarms are commonly assumed to "wake you harder", but they show no inertia advantage.
- **Implication:** Default to a melodic tone or a user-chosen song, with a volume ramp (low to full over ~30 s). Fall back to a loud tone if no dismissal happens after ~60 s (reliability matters more than gentleness).
- **Confidence:** Low–Moderate.
- Sources: [McFarlane, Garcia et al. 2020, PLOS ONE](https://econpapers.repec.org/RePEc:plo:pone00:0215788) · [McFarlane et al. 2020, Clocks & Sleep (PVT study)](https://doaj.org/article/5bd1b3953110438192b402e3c512b68f) · [RMIT summary](https://rmit.edu.au/news/all-news/2021/apr/snooze-blues)

### 1.10 Snoozing
- **Finding (mixed):**
  - Ogawa et al. 2022: a snooze alarm prolonged the drowsy period after waking. The authors attribute this to repeated forced awakenings (lab n = 10).
  - Sundelin et al. 2023: in habitual snoozers, 30 min of snoozing improved or did not affect cognition right after waking. Effects were gone by ~40 min, it cost ~6 min of sleep, and there was no effect on mood or sleepiness (lab n = 31).
  - Snoozing is very common: 69% of ~1,700 people snooze at least sometimes, and more often among evening types and short sleepers.
- **Implication:**
  - Snoozing is not clearly harmful for everyone, but it is *the* behavior that defeats this user.
  - The default is **no snooze**. Optionally, the user can enable a single pre-planned "wake window": a gentle pre-alarm X minutes before the real alarm. That gets the Sundelin pattern without open-ended snoozing.
  - The real alarm always requires the routine to dismiss.
- **Confidence:** Low–Moderate either way. The "snoozing is terrible" claim is overstated in popular media.
- Sources: [Ogawa et al. 2022, J Physiol Anthropol](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9804954/) · [Sundelin, Landry & Axelsson 2023, *Is snoozing losing?*, J Sleep Res](https://newsroom.wiley.com/press-releases/press-release-details/2023/Is-it-ok-to-press-the-snooze-button/default.aspx) · [Snoozing survey of 450 participants (2022)](https://pmc.ncbi.nlm.nih.gov/articles/PMC9548674)

### 1.11 Leaving the bedroom / not returning to bed
- **Finding:**
  - No controlled trial was found that tests "leave the bedroom" against sleep inertia.
  - Stimulus-control logic from insomnia therapy (the bed is for sleep, so get up rather than lie awake) is well established *for insomnia*, but not tested for morning relapse.
  - Practical reasoning is strong: sleep inertia makes the immediate desire to sleep high for ~15–30 min, and lying down in a dark, warm bed recreates sleep conditions. Physical distance plus an ongoing obligation (the guard window) removes that opportunity.
- **Implication:** The prop-up spot for the camera exercise should be **outside the bedroom, or at least across the room**. The app keeps watching for ~20 min afterwards.
- **Confidence:** Low (direct evidence). High as behavioral design logic.
- Sources: [Hilditch & McHill 2019](https://www.dovepress.com/sleep-inertia-current-insights-peer-reviewed-fulltext-article-NSS) · [Practical sleep-inertia countermeasures in emergency workers, NSS 2022](https://www.dovepress.com/i-want-to-be-safe-and-not-still-half-asleep-exploring-practical-counte-peer-reviewed-fulltext-article-NSS)

### 1.12 Cognitive tasks (math-problem alarms and similar)
- **Finding:**
  - No study was found showing that solving puzzles to dismiss an alarm reduces sleep inertia or prevents going back to sleep.
  - Sleep inertia specifically impairs complex cognition, so a hard puzzle mostly measures grogginess. It can also be done lying in bed, which defeats the purpose.
  - A short reaction-time test (PVT-style) is the standard *measure* of sleep inertia. It is useful as a readout and score, not as an intervention.
- **Implication:** No puzzle gate. Optionally, run a 30 s reaction-time check at the end as a measurement, used to tune the routine over time.
- **Confidence:** Popular / unsupported as an intervention. High that reaction-time tests are a valid measure.
- Sources: [Hilditch & McHill 2019](https://www.dovepress.com/sleep-inertia-current-insights-peer-reviewed-fulltext-article-NSS) · [McFarlane et al. 2020 (PVT used as the sleep-inertia measure)](https://doaj.org/article/5bd1b3953110438192b402e3c512b68f)

### 1.13 What actually drives better mornings over time
- **Finding:** In 833 people tracked for 2 weeks, morning alertness was predicted by:
  - sleeping longer and later than usual the night before,
  - physical activity the *previous day*,
  - a carbohydrate-rich breakfast with a low blood-glucose response.
  
  A high-sugar breakfast was the worst. This was an observational study, partly funded by Zoe Ltd.
- **Implication:** The routine cannot replace enough sleep. The app should surface sleep duration (from HealthKit) and suggest an earlier bedtime when the routine keeps failing.
- **Confidence:** Moderate (large but observational).
- Sources: [Vallat et al. 2022, Nature Communications (Berkeley summary)](https://news.berkeley.edu/2022/11/29/scientists-discover-secret-to-waking-up-alert-and-refreshed/)

### 1.14 What makes people go back to bed, and countermeasures
| Driver | Evidence | Countermeasure in this protocol |
|---|---|---|
| Strong sleep pressure during the inertia window (first 15–30 min) | High | 20 min no-return guard; routine front-loads standing and moving |
| Easy alarm dismissal or snooze from bed | Moderate (snooze prolongs drowsiness in one study; very common) | Dismissal needs physical steps away from bed; no default snooze |
| Dark room, warm bed, lying posture | Mechanism / Moderate | Lights-on step; routine done standing, away from bed |
| Short or irregular sleep, waking from deep sleep | High | Sleep-duration feedback; optional pre-alarm window |
| Evening chronotype (waking early on body clock) | Moderate–High | Morning light step in full variant; bedtime nudges |
| Anxiety, low mood | Moderate (survey) | Out of scope; do not shame failures |

### 1.15 Morning stretching
- **No direct evidence on waking up:** no study was found that tests which stretches reduce sleep inertia or help people stay out of bed.
  - The closest evidence is a workplace trial (134 office workers): 10 min of daily stretching for three months lowered exhaustion and raised vitality. It was a long-term program, not one session after waking.
  - So the specific stretches below are design choices, not tested findings.
- **Moving stretches are more activating than still holds:**
  - Static stretching tends to lower heart rate slightly (meta-analysis).
  - Dynamic stretching shifted autonomic markers toward a more activated (sympathetic) state, in small studies.
  - So the set starts and stays partly dynamic, and keeps holds short (15 s).
- **Avoid forward bending in the first hour:**
  - Lumbar discs take on fluid overnight and are measurably taller in the morning.
  - In a randomized trial (85 people with chronic low back pain), avoiding early-morning forward bending significantly reduced pain, pain days, and medication use. The control group improved too once it was given the same instruction.
  - So there are no toe touches, forward folds, or rounded-back hamstring stretches.
- **Hold length:** 15–30 s per hold is the commonly cited guideline (attributed to ACSM; I couldn't access the original). The routine uses 15 s to fit 2 minutes, and 30 s in the full variant.
- **Also excluded:**
  - Fast neck circles (neck strain, dizziness).
  - Head-below-heart poses such as downward dog (dizziness when coming back up).
  - Bouncing (ballistic) stretches.
  - Deep backbends.
  - Floor stretches (lying down recreates sleep posture).
- **Implication:** Use a 2-minute standing set after the jumping jacks, while the camera is still propped up and the body is warm. Each stretch is chosen so front-camera pose detection can verify it.
- **Confidence:** Low for any wake-up benefit. Moderate for avoiding early-morning forward bending (one RCT plus disc physiology). Moderate for dynamic stretching being more activating than static.
- Sources: [Snook et al. 1998, *Spine*, control of early-morning lumbar flexion](https://pubmed.ncbi.nlm.nih.gov/9854759/) · [MRI study of diurnal disc volume change](https://pubmed.ncbi.nlm.nih.gov/19937492/) · [Adams et al. 1990, diurnal changes in spinal mechanics](https://boneandjoint.org.uk/Article/10.1302/0301-620X.72B2.2138156) · [Dynamic vs static stretching and autonomic markers](https://jssm.org/jssm-20-690.xml-Fulltext) · [Static stretching and heart rate meta-analysis](https://pmc.ncbi.nlm.nih.gov/articles/PMC8488840) · [Workplace stretching trial (news report)](https://runnersworldonline.com.au/workplace-stretching-eases-anxiety/) · [Hold-duration guidance summary](https://www.bustle.com/wellness/how-long-should-you-hold-stretch)

---

## 2. Recommended default sequence (~6 min active + 20 min guard)

Design principles behind the order:
1. Upright before vertical, walk before jump (orthostatic safety).
2. Leave the bed early, because the bed is the threat.
3. Light on before the camera step, which also helps pose detection.
4. Highest-arousal step in the middle, once safe.
5. Stretch after the main exercise, while warm and still on camera.
6. Then keep the person busy and away from the bed through the inertia window.

Each step has a timeout. On timeout the alarm sound resumes (louder) and the step restarts. Nothing dismisses the alarm except finishing step 7.

| # | Step | Exact amount | Why here | Verification (phone / Watch) |
|---|---|---|---|---|
| 0 | **Alarm** | Melodic tone or user song, volume ramp 30 s from 30% to 100%. If not acknowledged by 60 s, switch to loud fallback tone. Watch: haptic taps every 2 s. **No snooze.** | Melodic sound is linked to less inertia; ramp avoids startle; fallback guarantees waking. | Acknowledgement only moves to step 1; it does not stop the routine. Watch tap or phone button. |
| 1 | **Sit up, feet on floor** | Hold seated **10 s** (countdown). Timeout to complete: 60 s after acknowledgement. | Lets blood pressure adapt before standing (initial orthostatic hypotension peaks within ~15 s of standing). | Phone in hand: device pitch goes from flat to ≥45° held steady for 10 s (Core Motion attitude). Watch: wrist motion plus no "lying" pattern. Weak check; accept on the timer. |
| 2 | **Stand and walk to the prop-up spot** (outside the bedroom, or the far side of the room) | ≥ **20 steps**, within **45 s** (user-set step goal 10–60). | Gets the user out of bed early. Walking ≥20 s covers the transient BP dip before any jumping. | Phone pedometer (CMPedometer) step delta ≥ goal; Watch step count as a backup. Optional location anchor: scan the QR or NFC sticker placed at the spot (Vision barcode or Core NFC). This is the strongest check that the user left the bed. |
| 3 | **Lights on / curtains open** | Room brightness above threshold within **30 s**. | Keeps the environment awake and may help subjective alertness. Also needed for reliable pose detection. | Front-camera brightness estimate: derive scene luminance from the camera's auto-exposure values (ISO × exposure duration) or average frame luma, and require at least the "lit indoor room" level (calibrate against "lamp on" on day 1). iOS gives apps no direct lux reading from the ambient light sensor. |
| 4 | **Warm-up march** (phone propped, front camera) | **20 s** marching in place with knees lifted (≈ 16–24 knee lifts). | Raises heart rate gradually before vigorous movement; also checks the camera framing. | Body-pose detection (Vision human body pose): count alternating knee-above-hip-line events; require ≥ 12 in 20 s, with full body in frame. |
| 5 | **Jumping jacks** | **40 reps** (~40–50 s). Low-impact substitute: **20 squats**. | Main arousal step. Vigorous intensity (~6–8 METs) is reached within seconds; a 30 s vigorous bout lowered sleepiness in the only direct study. | Pose: count one rep per full cycle of wrists above head + ankles apart, then arms down + feet together. Squats: hip dropping to ≤ knee height plus knee angle ≤ ~110°, then back to standing. Watch (if running a workout session): heart rate rising ≥ **+25 bpm above resting** or ≥ **55% of age-predicted maximum** (208 − 0.7 × age). Heart rate is supporting evidence, never the only gate. |
| 6 | **Standing stretches** (phone still propped) | **2:00** of stretching, six stretches (see 2.1), ~2:15 with changeovers. | Cool-down after the jumping jacks, while muscles are warm. Still on camera, so each stretch can be verified. Standing only, so there is no return to a lying posture. | Pose per stretch (see 2.1). A hold counts only while the pose is held; the timer pauses when the pose is lost. |
| 7 | **Bathroom: cold water on face** | **3 splashes / ~15 s**. Timeout 2 min. | Small, transient alerting effect. Its main job is moving the person further from the bed. **The alarm stops when this step is verified.** | Scan the QR or NFC anchor sticker at the sink (Vision barcode or Core NFC). Otherwise self-report button plus ≥ 8 more steps (pedometer). |
| 8 | **Drink water** | **300 ml** (glass or bottle). Self-paced, no timeout. | Cheap, harmless habit; corrects any overnight fluid deficit; keeps the user standing in kitchen or bathroom. | Self-report tap. Optional: scan a QR sticker on the bottle or glass shelf. Low verification value by design. |
| 9 | **No-return guard** | **20 min** after step 7 (user range 10–45). | Covers the period of strongest sleep inertia, when relapse happens. | **Phone:** if the device sits flat and motionless for ≥ **3 min** and no steps occur, prompt; if the prompt is not answered in 60 s, sound the alarm again. **Watch:** if heart rate drops toward the sleeping baseline (≤ resting + 5 bpm) plus no wrist motion for ≥ 3 min, haptic prompt, then re-alarm. Steps ≥ **150** during the window count as a pass. |
| 10 | **Reaction-time check (optional, default on)** | **30 s**, ~10 taps on random-interval cues, at the end of the guard window. | Measures residual inertia (it is not a treatment). Logs whether the routine helps over time. | The app measures reaction times directly; lapses = responses > 500 ms. |

**Default active time:** about 6 min for steps 0–8, plus the passive guard.

| Step | Typical time |
|---|---|
| Alarm until acknowledged | ~30 s |
| Sit | 10 s |
| Walk to prop spot | ~30 s (max 45 s) |
| Lights on | ~10 s |
| Body-in-frame check | ~10 s |
| March | 20 s |
| 40 jumping jacks | ~45 s |
| Stretches | ~2:15 |
| Walk to sink + face splash | ~45 s |
| Water | ~30 s |
| **Total** | **≈ 6 min** |

Notes for implementation:
- The camera steps (4–6) need a "body in frame" pre-check of ≤10 s. If the body is not detected for 30 s, fall back to the Watch-motion count or offer squats.
- Count reps only while a person is detected. Pause the count, rather than reset it, when tracking is lost for less than 3 s.
- **Stop button** (always visible during steps 4–6): "I feel dizzy / unwell". It switches to the seated alternative: sit **60 s**, then **2 min walking** (≥ 150 steps) as a substitute. It must never be a free dismissal; it swaps the exercise rather than skipping the routine.

### 2.1 Stretch set detail (step 6)
Standing only. One stretch flows into the next, with a ~3 s on-screen preview of the next pose between them. Show a short demo animation for each stretch.

| # | Stretch | Time | Why in this position | Front-camera pose check (Vision body pose) |
|---|---|---|---|---|
| 6a | **Arm circles**, forward then backward | 15 s (~8 each way) | Moving start that keeps the activation from the jumping jacks; warms the shoulders. | Each wrist traces a loop around its shoulder: wrist passes above the shoulder and below the hip line alternately; ≥ 6 loops. |
| 6b | **Overhead reach on tiptoes** (fingers interlaced or palms together) | 15 s | Lengthens the whole body upward; this mild backward extension of the spine is safe for morning discs. | Both wrists above the top of the head, shoulders–hips–ankles roughly vertical (within ~10°). |
| 6c | **Standing side bend**, left then right, top arm overhead | 15 s each = 30 s | Side of the trunk, stiff after lying in one position; a sideways bend avoids forward bending. | Line from mid-hip to neck tilted ≥ 15° from vertical, with the top-side wrist above the head; the left side is checked first, then the right. |
| 6d | **"Cactus arms" chest opener**: upper arms out at shoulder height, elbows bent 90°, squeeze shoulder blades together | 15 s | Opens the chest and front of the shoulders after a curled sleeping position. | Both elbows within ~15° of shoulder height, both wrists above their elbows, forearms roughly vertical. |
| 6e | **Slow trunk twists**, hips facing forward, arms bent at chest height | 15 s (~6 per side) | Gentle spinal rotation, done moving rather than held; adds a little activation before the balance stretch. | Apparent shoulder width (left–right shoulder distance) narrows alternately while hip width stays steady; ≥ 4 alternations. |
| 6f | **Standing quad stretch**, left then right; free hand on a wall or chair allowed | 15 s each = 30 s | Front of thigh and hip flexor. Placed last because it needs balance, which is best once the user is warm and alert. | One ankle raised to ≥ knee height of the standing leg (heel toward the buttock), standing knee straight; left first, then right. |

Total: 120 s of stretching (~2:15 with changeovers).

Not used, by design: toe touches or forward folds, rounded-back hamstring stretches, neck circles, downward dog or other head-down poses, bouncing stretches, deep backbends, floor stretches.

---

## 3. Variants

### 3.1 Minimum variant (~2 min)
For rushed mornings or travel. It keeps the parts that matter most against relapse: leave the bed, move hard, lights, guard.

| # | Step | Amount | Verification |
|---|---|---|---|
| 0 | Alarm (melodic, ramp, no snooze) | 30 s ramp; fallback at 60 s | Acknowledge |
| 1 | Sit, feet on floor | **10 s** | Device tilt / timer |
| 2 | Walk to prop spot | **≥ 15 steps** within 30 s | Pedometer (+ QR/NFC anchor if set) |
| 3 | Lights on | Within **15 s** | Camera exposure brightness |
| 4 | March in place | **10 s** | Pose: ≥ 6 knee lifts |
| 5 | Jumping jacks | **30 reps** (or 15 squats) | Pose rep count; Watch heart-rate rise |
| 6 | No-return guard | **15 min** | Phone stillness / Watch heart rate + motion, as above |

About 1.5–2 min active. The alarm stops after step 5. No stretches in this variant, to keep it short.

### 3.2 Full variant (~13 min active)
For days with time to spare, or after repeated relapses.

| # | Step | Amount | Verification |
|---|---|---|---|
| 0 | Optional **dawn pre-light** (HomeKit smart bulb) | Ramp to max over **30 min** before alarm | HomeKit scene state |
| 1 | Alarm | As default | Acknowledge |
| 2 | Sit | **15 s** | Tilt / timer |
| 3 | Walk to prop spot outside bedroom | **≥ 30 steps** | Pedometer + QR/NFC anchor (required) |
| 4 | Lights on | Within 30 s | Camera brightness |
| 5 | March in place | **30 s** | Pose knee lifts ≥ 20 |
| 6 | Jumping jacks, set 1 | **40 reps** | Pose + heart rate |
| 7 | Rest standing | **20 s** | Pose: standing, in frame |
| 8 | Squats | **20 reps** | Pose (hip/knee angles) |
| 9 | Jumping jacks, set 2 (or high knees 30 s) | **30 reps** | Pose + heart rate ≥ 60% of max or +30 bpm |
| 10 | **Standing stretches**: the same six as 2.1 with **30 s holds** (arm circles and trunk twists 30 s each) | **~3.5 min** | Pose per stretch, as 2.1 |
| 11 | Face splash at sink | ~15 s (alarm stops here) | QR/NFC anchor at sink |
| 12 | Water | **500 ml** | Self-report / QR |
| 13 | **Daylight**: outdoors, balcony, or at a bright window | **5 min** (user 2–15) | Rear or front camera brightness well above indoor levels (outdoor exposure values are typically 10–100× indoor), or Watch "time in daylight" (watchOS ambient-light sensing, readable in HealthKit as time in daylight on Apple Watch SE 2nd gen / Series 6+; data may arrive late, so use it as a bonus, not a gate) |
| 14 | Reaction-time check | **30 s** | App-measured |
| 15 | No-return guard | **30 min** from step 11 | As default |

About 13 min active, including walking time between locations (about 10 min without the stretches).

---

## 4. User-adjustable parameters and safe ranges

| Parameter | Default | Safe range | Notes |
|---|---|---|---|
| Alarm sound | Melodic built-in | Any melodic tone or user song; harsh tone allowed | Fallback loud tone at 60 s always on (can raise to 120 s) |
| Volume ramp | 30 s | 0–60 s | Longer than 60 s risks not waking |
| Snooze | Off | Off, or **one** pre-alarm 10–30 min before the real alarm | The real alarm never snoozes; pre-alarm is a gentle sound or Watch haptic only |
| Seated pause | 10 s | **10–60 s** (never below 10) | Raise for users who get dizzy |
| Steps to prop spot | 20 | 10–60 | Anchor location (QR/NFC) strongly recommended |
| Warm-up march | 20 s | **15–60 s** (never below 15 when followed by jumps) | |
| Main exercise | Jumping jacks | Jumping jacks / squats / high knees / march only | Low-impact mode replaces jumps with squats; march only for injury, pregnancy, or medical advice |
| Jumping jack reps | 40 | 20–100 | Above 100 adds little alertness and raises injury risk on a cold body |
| Squat reps | 20 | 10–40 | |
| Stretch set | On (default and full variants) | On / off | Off in the minimum variant |
| Stretch hold time | 15 s | 10–30 s per stretch / side | 30 s in the full variant; whole set scales from ~1:30 to ~3:30 |
| Quad stretch | On | On / off | Off for users with balance problems; replace with a second overhead reach |
| Heart-rate check | Off unless Watch present | +15 to +40 bpm over resting, or 50–70% of age-predicted max | Never a hard gate; warn above 85% of max |
| Lights-on threshold | Calibrated "lamp on" | Calibrated per room | Recalibrate if the user changes room |
| Face splash step | On | On / off | |
| Water | 300 ml | 0–750 ml | Off for users on fluid restriction |
| Daylight (full variant) | 5 min | 2–15 min | |
| No-return guard | 20 min | **10–45 min** | Below 10 min leaves the worst inertia window unguarded |
| Guard stillness trigger | 3 min | 2–10 min | |
| Re-alarm after unanswered guard prompt | 60 s | 30–120 s | |
| Reaction-time check | On | On / off | |
| Variant | Default | Minimum / Default / Full | Suggest Full automatically after 2 relapses in 7 days |

**Safety requirements that are not user-adjustable:**
- First-run health screen: heart condition, uncontrolled blood pressure, pregnancy, recent injury or surgery, fainting history, age 65+. Any "yes" sets low-impact mode and suggests checking with a doctor.
- The "I feel dizzy / unwell" button is always present during exercise steps. It switches to the seated + walking alternative and never marks the user as failed.
- Never require jumping within 20 s of standing up.
- A reminder about a clear, non-slippery floor area of about 2 × 2 m on setup.

---

## 5. Evidence quality at a glance

| Intervention | Rating | In protocol as |
|---|---|---|
| Sleep inertia is worst in the first 15–30 min | High | Guard window length |
| Snooze / return to bed prolongs drowsiness | Low–Moderate (mixed) | No default snooze; guard |
| Brief vigorous exercise lowers subjective sleepiness | Moderate | Core step |
| Exercise improves objective cognition on waking | Low (null in the one direct study) | Not claimed |
| Melodic alarm reduces inertia | Low–Moderate | Default sound |
| Light at wake-up after a normal night | Low–Moderate | Lights-on step |
| Morning outdoor light shifts the circadian clock earlier | High | Full-variant daylight step |
| Dawn simulation before waking | Moderate | Optional (HomeKit) |
| Cold face splash | Low (small, transient) | Location step |
| Cold shower cures inertia | Popular / unsupported | Not included |
| Water on waking | Low (for inertia) | Habit step |
| Caffeine as an alertness aid | Moderate–High (slow onset when swallowed) | Not gated; no delay |
| Wait 90 min before coffee | Popular / unsupported | Not used |
| Puzzle alarms prevent going back to sleep | Popular / unsupported | Not used; reaction test as a measure only |
| Stretching helps you wake up | Low (no direct study) | 2-min standing cool-down |
| Avoid forward bending in the first hour after rising | Moderate (one RCT + disc physiology) | No forward folds in the stretch set |
| Dynamic stretching is more activating than static | Low–Moderate (small studies) | Set mixes moving stretches and 15 s holds |
| Enough sleep the night before | Moderate–High | Feedback / bedtime nudges |
| Brief orthostatic dizziness on standing is common | High | Sit 10 s, walk before jumping |
