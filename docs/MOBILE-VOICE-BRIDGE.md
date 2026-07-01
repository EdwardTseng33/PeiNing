# Munea Mobile Voice Bridge

> Updated: 2026-07-02
> Scope: first microphone bridge for the iOS-first app path.

## Current Decision

Munea keeps `聊聊` as the core interaction surface.

Voice priority:

1. Taiwan Mandarin.
2. English.
3. Taiwanese Hokkien remains research only.

The app should not depend only on browser speech recognition, because iOS / WKWebView support can be inconsistent. The current bridge therefore supports two layers:

1. Browser speech recognition when available.
2. MediaRecorder microphone capture fallback when speech recognition is unavailable.

## Current Implementation

- Frontend: `web/src/app.js`
  - `chatMic` still starts speech recognition first when supported.
  - If speech recognition is unavailable, the same button records microphone audio.
  - First tap starts recording.
  - Second tap stops recording.
  - Recorded audio is converted to a data URL and posted to `/voice-note`.

- Backend: `engine/server.py`
  - `POST /voice-note`
  - Accepts `{ audio, mime, durationMs, char }`.
  - Decodes base64 payload and returns byte count.
  - This is a bridge validation endpoint, not final speech understanding.

- Test: `scripts/smoke.ps1`
  - Full smoke test now posts a tiny base64 payload to `/voice-note`.
  - This confirms that the audio payload route is wired.

## What This Proves

- The app has a fallback path for devices without speech recognition.
- The frontend can package microphone audio for backend processing.
- The backend can receive and decode audio payloads.
- Future Gemini Live / STT work has a defined insertion point.

## What This Does Not Prove Yet

- Real iPhone microphone permission behavior.
- WKWebView MediaRecorder compatibility on the target iOS version.
- Audio format quality for Gemini Live or speech-to-text.
- End-to-end real-time interruption and turn-taking.

## Next Device Test

On macOS with Xcode, use the full handoff checklist in `docs/TESTFLIGHT-MAC-HANDOFF-2026-07-02.md`.

Minimum path:

1. Run `npm install`.
2. Run `npm run cap:add:ios`.
3. Add iOS microphone usage text in `ios/App/App/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Munea needs microphone access so you can talk with your AI health companion.</string>
```

4. Run the app on a real iPhone.
5. Open `聊聊`.
6. Tap the mic button once to start recording, then again to stop.
7. Confirm the caption changes to indicate the voice note was received.
8. Run backend smoke test from the development machine:

```powershell
npm run smoke
```

Report the Mac result back with Xcode version, iPhone model / iOS version, microphone prompt result, recording result, playback result, and any signing error text.

## Next Engineering Step

Replace `/voice-note` placeholder behavior with one of these:

1. Gemini Live real-time voice loop.
2. STT first, then existing `/chat`, then TTS.
3. Native audio capture plugin if WKWebView capture is unstable.

Do not connect real-time avatar until the voice loop is stable.
