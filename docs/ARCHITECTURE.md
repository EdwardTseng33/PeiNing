# PeiNing — System Architecture

> The full system design for the PeiNing personal AI butler.
> Source of truth for the product/solution layer; deep media-infra detail lives alongside the voice engine.

---

## 1. Positioning

A personal AI butler **engine**, with PeiNing as its first "skin": a 30–35-year-old butler devoted to one elder.
Core audience = elders 60+ (served); buyer = adult children. The engine is reusable — future skins can serve other segments.

## 2. Three Brains + One Face

### 🧠 Reflex brain (hot path — must be fast)
- Real-time listen & speak; natural turn-taking.
- **Graceful interruption:** hear → decide whether to stop → may finish the half-sentence → resume with context, never a hard cut.
- Low latency is the lifeline (elders won't wait).
- Built on a real-time speech model (GPT-Realtime-2 integrated) + a "conversation rhythm" design layer.

### 🧠 Butler brain (background — deep, never blocks)
- **Perception:** each morning, prepares "today" — weather (→ health nudges), appointments / meds / important dates, curated local news, family updates shared by children.
- **Memory:** distills every interaction into a profile of the person — preferred topics, personality, family members & names, mood, body, daily rhythm, life stories, taboo topics, faith, chronic conditions.
- Runs in the background (morning, idle gaps, overnight). The conversation only *consumes* what's already prepared → **deep without being slow.**

### 🧠 Guardian brain (safety net — P0)
- Detects emotional / routine anomalies + crisis keywords → notifies family / refers to 1925 / 119.
- The AI is a **referrer**, not a therapist (regulatory line).

### 🙂 The Face (two tracks, self-hosted)
- 30–35-year-old butler. Elder picks one:
  - **Photorealistic** — 4 identities (2 male, 2 female), competitor-grade quality.
  - **2D character** — cute animal / cartoon.
- The 4 faces are **skins only** (look + voice). The butler brain behind them is **shared** — more faces ≠ more "knowing you" complexity.
- **Cost:** self-hosting cost scales with *concurrent streams*, not with *number of face options* → offering more faces is near-free at runtime (one-time creation only).
- **Voice out (her speaking) = yes.** **Camera in (real-time visual cognition of the elder) = not in v1** (cost + latency + privacy). Visual health sensing, if ever, = occasional background snapshots, not the live loop.

## 3. Two interaction layers (resolves the iOS proactive limit)

- **App closed → Push layer:** standard iOS push (always delivers; zero iOS-limit risk). Carries the butler's face, quick-action buttons (no app-open needed), critical alerts (can break silent mode), optional short voice clips. Daily greetings / meds / reminders / safety run here, 24/7.
- **App open → Conversation layer:** full real-time voice + talking face.
- This sidesteps "can the app speak proactively while closed" (iOS won't allow). The remaining risk is **behavioural** (will the elder tap the push and open the app) — a lower bar than cold-opening an app, and the first thing to validate.

## 4. Why "knows you" doesn't mean "slow"
Depth (perception + memory) is precomputed in the background butler brain; the live conversation only consumes prepared context. The only thing that would tax the hot path is real-time camera cognition → kept out of the live loop.

## 5. Self-hosting = the business model's root
- Whole pipeline self-hosted, zero per-minute third-party fees.
- Renting a conversational-avatar API ≈ US$0.05–0.20/min ≈ ~NT$900/user/month for the face alone → margin death.
- Self-hosted amortizes toward near-zero marginal cost → supports the ~65% gross margin in the financial model.
- The face renders only while the app is open (not 24/7) → cost down further.

## 6. Hybrid app shell (Capacitor)
- A real App Store app with native push, wrapping the reusable web core (~70% reuse from `castle-voice-engine`).
- One core → iOS first, Android later.
- Native layer provides: push notifications, notification actions, critical alerts, lock-screen presence, future health-data hooks.

## 7. Honest unknowns (validate, don't promise on paper)
- **Self-hosted real-time photorealistic on affordable hardware** is an unsolved frontier. Prior in-house attempts failed due to *method + hardware* (home-grown image-stitching, no proper GPU, not the competitor approach) — not a proof of impossibility. The PoC must use the proper generative method + proper hardware.
- Per the dead-ends rule: **no promise of "matches Tavus" without a PoC.**

---

*See `ROADMAP.md` for the build sequence. Product/market/finance research lives in the parent project folder.*
