# Munea — Build Roadmap

> Build sequence: validate the killers first, then build on the engine, then grow.

## Step 0 — Validate the two make-or-break unknowns (cheapest first, biggest certainty)
1. **Push → open behaviour:** will an elder tap a push notification and open the app? (Push delivery itself is a solved iOS standard; what's unproven is the behaviour.) Test with a simple prototype.
2. **Self-hosted photorealistic feasibility:** can a single-GPU, real-time generative avatar (e.g. Ditto) hit acceptable fps / latency / quality? Done the *proper* way (competitor-grade method + real hardware), not the old in-house image-stitching. License check included. **Spend gated on explicit go-ahead.**

## Step 1 — Minimum running version, on the existing engine (~70% reuse)
- Reflex brain (natural speech) + **2D face** (self-hostable now) + basic butler brain (memory + morning context) + medication reminders + family dashboard + child-led onboarding.
- Ship to a real device; nail voice latency.

## Step 2 — Deepen the butler + bring on the photorealistic face (if Step 0 PoC passes)
- Full perception + memory layers (more sources, long-term store).
- Photorealistic faces (4: 2M / 2F) wired in (self-host spec set by PoC results).
- Guardian / safety net completed.

## Step 3 — Pre-launch
- Regulatory-safe copy (alarm ≠ pharmacist; companion ≠ counseling/therapy; crisis = referral).
- Apple review, trademark registration, trial-conversion flow.

---

## Layer-by-layer self-host status (2026-06)

| Layer | Self-host? | Note |
|---|---|---|
| 📲 Push (reach elder when app closed) | ✅ yes | iOS standard |
| 👂 Listen (Taiwanese STT) | ✅ yes | open source; already have it |
| 🧠 Think (brain) | ✅ yes | open models self-hostable; heaviest reasoning can use cheap cloud, cost-controlled |
| 🗣️ Speak (TTS) | ✅ yes | mature open-source TTS |
| 🙂 Face — 2D (animal / cartoon) | ✅ yes, now | cheap; near-zero hardware cost |
| 🙂 Face — photorealistic (4) | 🟡 yes, but PoC first | quality achievable; affordable real-time is the frontier to test |

**Bottom line:** the whole chain is self-hostable — 5 of 6 layers confirmed now; only affordable real-time photorealistic faces need one proper PoC.
