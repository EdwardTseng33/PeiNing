#!/usr/bin/env python3
"""
沐寧 Munea · 角色引擎 — 讀 characters.json，可當任何角色講話。
真人（寧寧/阿宏/小昀/阿原）會帶「記憶」（user_profile.json）；動物（咪咪/旺財）用各自演技聲音。
用法：GEMINI_API_KEY="..." py chat_engine.py [角色名 角色名 ...]
"""
import os, sys, json, time, wave
from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    sys.exit("需要 GEMINI_API_KEY")
HERE = os.path.dirname(os.path.abspath(__file__))
client = genai.Client(api_key=API_KEY)

CHARS = json.load(open(os.path.join(HERE, "characters.json"), encoding="utf-8"))
RED = "（界線：只陪伴／生活提醒／情緒支持，不診斷不治療、絕不說不用看醫生；嚴重不適或想不開→不裝醫生，溫柔轉介家人／1925／119。）"

def _profile_ctx():
    pf = os.path.join(HERE, "user_profile.json")
    if not os.path.exists(pf):
        return ""
    p = json.load(open(pf, encoding="utf-8"))
    return (f"\n（你正陪伴的人：你都叫她「{p.get('稱呼','')}」、{p.get('年紀','')}歲、住{p.get('住在','')}；"
            f"喜歡{'、'.join(p.get('喜好', []))}；你記得她說過：{'；'.join(p.get('回憶', []))}。自然帶入、別像念資料。）")

def reply(char, user):
    c = CHARS[char]
    sys_i = c["persona"] + RED + (_profile_ctx() if c["type"] == "human" else "")
    last = ""
    for attempt in range(4):
        for m in ("gemini-2.5-flash", "gemini-flash-latest", "gemini-2.0-flash"):
            try:
                r = client.models.generate_content(
                    model=m, contents=user,
                    config=types.GenerateContentConfig(system_instruction=sys_i, temperature=0.9))
                return r.text.strip()
            except Exception as e:
                last = str(e)[:50]
        time.sleep(2 * (attempt + 1))
    return f"(連不上腦 — {last})"

def speak(char, text, fn):
    c = CHARS[char]
    content = (c["style"] or "") + text
    for m in ("gemini-3.1-flash-tts-preview", "gemini-2.5-flash-preview-tts"):
        try:
            r = client.models.generate_content(
                model=m, contents=content,
                config=types.GenerateContentConfig(response_modalities=["AUDIO"],
                    speech_config=types.SpeechConfig(voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(voice_name=c["voice"])))))
            pcm = r.candidates[0].content.parts[0].inline_data.data
            with wave.open(fn, "wb") as w:
                w.setnchannels(1); w.setsampwidth(2); w.setframerate(24000); w.writeframes(pcm)
            return True
        except Exception:
            pass
    return False

if __name__ == "__main__":
    USER = "欸我跟你說，我最近想開始學畫畫，但又怕自己太老沒天份。"
    who = sys.argv[1:] or ["小昀", "阿宏", "阿原"]
    print(f"【用戶】{USER}\n")
    for name in who:
        print(f"── {name}（聲音 {CHARS[name]['voice']}）──")
        print(reply(name, USER))
        print()
    print("DONE — 角色引擎讀設定檔、可當任何角色講話。")
