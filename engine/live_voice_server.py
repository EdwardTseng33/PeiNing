"""沐寧 · 即時語音橋接（stage 1）

瀏覽器 ⇄ 這個橋 ⇄ Gemini Live。讓長輩「開口就即時跟寧寧講電話」。
- 獨立的 async WebSocket 伺服器（:8201），不動 engine/server.py（那是 Codex 的地盤）。
- 把寧寧的人格＋非醫療界線＋長輩記憶（重用 chat_engine）當成 Live 的 system instruction，
  所以即時語音的寧寧也有個性、也記得使用者。

跑法：GEMINI_API_KEY=... python engine/live_voice_server.py
訊息協定（瀏覽器→橋）：
  - binary：麥克風 PCM16 @16kHz（即時串流）
  - {"type":"text","text":"..."}：純文字（測試/打字備援）
  - {"type":"audio_end"}：這段說完了
訊息協定（橋→瀏覽器）：
  - binary：寧寧的語音 PCM16 @24kHz
  - {"type":"caption","who":"nening|user","text":"..."}
  - {"type":"interrupted"} / {"type":"turn_complete"}
"""

import os
import sys
import json
import asyncio

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import chat_engine as eng
from google import genai
from google.genai import types
import websockets

MODEL = "gemini-3.1-flash-live-preview"
KEY = os.environ.get("GEMINI_API_KEY")
if not KEY:
    sys.exit("需要 GEMINI_API_KEY")

client = genai.Client(api_key=KEY)


def system_instruction(char="寧寧"):
    c = eng.CHARS.get(char) or eng.CHARS["寧寧"]
    base = c.get("persona", "")
    base += eng.RED
    if c.get("type") == "human":
        base += eng._profile_ctx()
    base += "（現在是即時語音通話，像講電話。講話要口語、簡短、溫暖，一次一兩句就好，別長篇大論。）"
    return base


def live_config(char="寧寧"):
    return types.LiveConnectConfig(
        response_modalities=["AUDIO"],
        system_instruction=system_instruction(char),
    )


async def handle(ws):
    char = "寧寧"
    try:
        async with client.aio.live.connect(model=MODEL, config=live_config(char)) as session:
            async def from_browser():
                async for message in ws:
                    if isinstance(message, (bytes, bytearray)):
                        await session.send_realtime_input(
                            audio=types.Blob(data=bytes(message), mime_type="audio/pcm;rate=16000")
                        )
                    else:
                        try:
                            obj = json.loads(message)
                        except Exception:
                            continue
                        t = obj.get("type")
                        if t == "text" and obj.get("text"):
                            await session.send_client_content(
                                turns=types.Content(role="user", parts=[types.Part(text=obj["text"])]),
                                turn_complete=True,
                            )
                        elif t == "audio_end":
                            await session.send_realtime_input(audio_stream_end=True)

            async def from_live():
                async for msg in session.receive():
                    data = getattr(msg, "data", None)
                    if data:
                        await ws.send(data)
                    sc = getattr(msg, "server_content", None)
                    if sc:
                        ot = getattr(sc, "output_transcription", None)
                        if ot and getattr(ot, "text", None):
                            await ws.send(json.dumps({"type": "caption", "who": "nening", "text": ot.text}))
                        it = getattr(sc, "input_transcription", None)
                        if it and getattr(it, "text", None):
                            await ws.send(json.dumps({"type": "caption", "who": "user", "text": it.text}))
                        if getattr(sc, "interrupted", False):
                            await ws.send(json.dumps({"type": "interrupted"}))
                        if getattr(sc, "turn_complete", False):
                            await ws.send(json.dumps({"type": "turn_complete"}))

            await asyncio.gather(from_browser(), from_live())
    except websockets.ConnectionClosed:
        pass


async def main():
    async with websockets.serve(handle, "127.0.0.1", 8201, max_size=None):
        print("即時語音橋接已啟動：ws://127.0.0.1:8201（模型 " + MODEL + "）")
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
