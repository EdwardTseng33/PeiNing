# Munea (沐寧)

> A personal AI butler that lives in your phone — speaks Taiwanese, remembers you, and reaches out before you have to ask.

**Munea (沐寧)** is a personal AI butler app for elders (60+), bought by their adult children. It is presented as a warm, capable **30–35-year-old butler** — deliberately *not* an "elderly app" — and is built to feel like a real person to talk to: it listens and speaks naturally, perceives the day, remembers the person deeply, and quietly watches over their safety.

- **Core audience:** elders 60+ (the "master" being served)
- **Buyer:** their adult children (the user ≠ the payer)
- **Platform:** iOS first (App Store), Android later
- **Smart-health product line** — the pure-app rebirth of the Careon companion concept.

---

## What makes it different

- **Taiwanese (台語) first** — the moat. Listen *and* speak, self-hosted, zero license fee. Competitors are English/Korean only.
- **Proactive by design** — reaches out via **push** when the app is closed; full **voice conversation** when opened.
- **Deeply personal** — remembers your topics, personality, family, mood, health, and life stories.
- **Safety net built-in (P0)** — detects distress / anomalies → notifies family, refers to 1925 / 119. The AI is a *referrer*, never a therapist.
- **Self-hosted** — the whole media stack runs on our own infrastructure (no per-minute third-party fees). This is what makes the business model viable.

---

## Architecture at a glance — Three Brains + One Face

| Layer | Role | When it runs |
|---|---|---|
| 🧠 **Reflex brain** | The live conversation — natural turn-taking, graceful interruption | Hot path (must be fast) |
| 🧠 **Butler brain** | Perception (daily context) + deep memory of the person | Background (no lag) |
| 🧠 **Guardian brain** | Safety net — anomaly & crisis detection → family / hotline | Background |
| 🙂 **The Face** | Talking avatar — choice of photorealistic (4: 2M / 2F) or 2D character | Only while app is open |

> **Key principle:** everything that makes the butler *know you* runs in the background brain, so depth never slows the conversation.

### Two interaction layers
- **App closed → Push layer:** standard iOS push (always delivers). Warm message, the butler's face, quick-action buttons (e.g. "taken" / "snooze"), critical alerts for safety.
- **App open → Conversation layer:** real-time voice + talking face + natural chat (where all the "feels human" work lives).

---

## Tech approach

- **Hybrid native app via Capacitor** — a *real* App Store app with native push, wrapping a reusable web core (~70% reused from our voice engine). One core → iOS first, Android later.
- **Self-hosted media pipeline** — STT (Taiwanese) → brain → TTS → avatar render, all on our own infrastructure.
- **Voice engine foundation:** `castle-voice-engine` (real-time voice, talking face, memory continuity, GPT-Realtime-2 integrated).

---

## Repo structure

```
peining/
├── README.md            # this file
├── docs/
│   ├── ARCHITECTURE.md  # the full system design
│   └── ROADMAP.md       # build plan: validate → MVP → scale
├── src/                 # web core (app UI + engine integration) — set up on macOS
└── ios/  android/       # native shells (Capacitor) — added on macOS
```

---

## Status

**Pre-build.** Architecture & positioning locked (2026-06). Next: validate the two make-or-break unknowns —
1. **Behaviour:** will elders tap a push and open the app?
2. **Feasibility:** can we self-host photorealistic faces in real time on affordable hardware? (PoC, done the *right* way this time.)

— then build the MVP on the existing voice engine.

## Development

iOS build, Apple Developer account, and native packaging are done on **macOS** (Xcode + Capacitor). The web core and docs are cross-platform.
