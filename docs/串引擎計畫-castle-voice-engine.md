# 串真引擎計畫：把 castle-voice-engine 接進沐寧 App（v2 · 已讀引擎、落實）

> 把原型從「會點的外殼」變成「真的會聽會說會記得」。對應原型程式裡的 `[ENGINE]` 接點。
> v2 · 2026-06-27 蘇菲 · **已實際讀過 `E:\Claude\castle-voice-engine` 的 STATUS / PRODUCT-PASSPORT / 實際路由**，把 v1「API 待讀」補成具體。

---

## 0. 先講最重要的一個發現（誠實校正 v1）

引擎 `castle-voice-engine` 的對外名 = **BeyondVoice**，本質是 **Edward 個人專屬的「語音版蘇菲」**（單人自用、跑在 Modal 雲端、現場 live），**不是一個商業產品**。

→ 對沐寧的意義（**這點以前沒講清楚、現在校正**）：
- **架構與大量功能可以借**（語音管線、雲端部署法、感知/記憶那一整套 API 真的已經做好了）。
- **但沐寧是「賣給很多長輩」的商業產品（多人）**，引擎是「Edward 一個人用」（單人）。所以沐寧要**自己一套部署**、不是直接共用 Edward 的個人引擎。
- **臉（avatar）尤其不能照抄**：引擎內那幾個臉的方案（SoulX-FlashHead / Duix / MuseTalk）被引擎自己標成「個人自用可、對外商業 NO-GO」或「死路」。**沐寧的臉走我們今晚 PoC 過的 Ditto（Apache-2.0、可商用）**——這是兩條不同的路。

---

## 1. 引擎實際長怎樣（讀完程式庫的事實）

- **部署**：Modal 雲端 + FastAPI，現場 live：`https://edwardt0303--castle-voice-engine-fastapi-app.modal.run/`。scale-to-zero（沒人用就睡、省錢）。
- **語音主路**：gpt-realtime-2（即時語音、Phase 1 已 ship、live）。
- **臉的探索**：breeze_poc 內有 MuseTalk（死路）/ SoulX-FlashHead（個人自用）等 PoC；**沐寧不走這條，走 Ditto**。
- **台語**：`breeze_poc/app_breeze.py` = Breeze（台語）PoC 已存在 → 沐寧台語層有現成起點。
- ⛔ **動臉的技術前必讀**：`castle-voice-engine/docs/voice-path-deadends-memo.md`（8 條已撞死路，憲法級）。

## 2. 引擎「真的已經有」的 API（按沐寧三顆腦分）

> 以下都是程式庫裡**真實存在的路由**（讀 code 確認）。確切的傳入/傳出格式，接的時候逐支再讀一次。

**🧠 反射腦（即時對話）**
- 即時語音（gpt-realtime-2，WebSocket，就是那個 live demo）
- `POST /brain/ask_claude` — 深想（Claude）

**🧠 管家腦 · 感知（清晨備今天）— ⭐ 大半已做好**
- `POST /brain/morning_brief`（清晨總整理）· `POST /brain/get_weather` · `POST /brain/get_time_context` · `POST /brain/news_brief`
- `POST /perception/update` · `POST /brain/get_perception`（感知狀態存取）

**🧠 管家腦 · 記憶（深度認識這個人）— ⭐ 大半已做好**
- `POST /memory/shared/set` · `GET /memory/shared/get/{key}` · `GET /memory/shared/list`（共用記憶存取）
- `POST /brain/save_interest`（記喜好）
- `POST /brain/start_interview` · `/brain/log_interview_insight` · `/brain/end_interview`（**深度訪談 = 慢慢認識這個人、挖生命故事**，正好對應沐寧北極星「記得這個人」）
- `POST /brain/get_contact_history` · `/brain/save_contact_meeting`（關係/互動記憶）

**🤝 派工 / 工具**：`GET /dispatch/tools` · `POST /dispatch`
**📷 鏡頭多模態（Phase 3）**：`/camera/*` `/vision/*` — **沐寧 v1 不做攝影機對內**（北極星 §5）→ 這組先略過。

## 3. 沐寧要做的三件分類（借 / 加 / 不照抄）

**✅ 借（直接對應、省最多）**
- 雲端部署法（Modal FastAPI + scale-to-zero）
- 即時語音（gpt-realtime-2 整合）= 反射腦
- 感知整套（morning_brief / weather / perception）= 管家腦感知層
- 記憶整套（memory/shared + interview + interest）= 管家腦記憶層
- 認得本人（引擎用 SpeechBrain 認 Edward → 沐寧認長輩）、隱私遮罩（spaCy）

**➕ 加（引擎沒有、沐寧的命脈）**
- **台語 ASR + TTS**（引擎是華語/英語蘇菲；台語是沐寧護城河 → 接 Breeze Taigi，起點在 breeze_poc）
- **多人**（一個引擎服務很多長輩，各自記憶分開 → 記憶要按「哪位長輩」分艙，引擎現在是單人共用）
- **iOS 推播**（App 沒開時找長輩 = 命脈 → Capacitor 原生層）
- **守護腦**（危機 → 通知家人 / 1925 / 119）
- **Ditto 臉服務化**（雲端 GPU 常駐 Ditto、App 呼叫 → 今晚 PoC 過、待 TRT 即時）

**🚫 不照抄**
- 引擎的臉（SoulX/Duix/MuseTalk）= Track-A/死路 → 沐寧用 Ditto
- 單人共用記憶 → 沐寧要多人分艙

## 4. 接線順序（先接最有感的命脈）
1. **聊聊的真語音**（反射腦 gpt-realtime-2）= 第一個「真的會聽會說」——產品靈魂，先接。台語層同步接 Breeze。
2. **記憶**（記得上次）= 黏著關鍵 → 接 `/memory/shared` + interview，加「按長輩分艙」。
3. **感知**（清晨備今天）→ 接 `/brain/morning_brief` 那組，首頁問候帶出來（非寫死）。
4. **2D 會動的臉** →（Ditto 擬真臉 PoC/TRT 過後再上）。
5. **守護腦** + **推播層**（原生）。

## 5. 待 Edward / Mac 拍板（接之前要定）
1. **沐寧自己一套 Modal 部署 vs 共用引擎** → 建議**自己一套**（商業多人 ≠ 個人單人；也避免動到 Edward 自用引擎）。
2. **台語即時延遲**：反射腦要快 = 命脈，Breeze 接上後實測。
3. **引擎那套腦的 license**：gpt-realtime-2 走 OpenAI API（用量計費）；沐寧商業上線前要過一次 license/成本帳（這跟「全自架不付每分鐘費」的初衷要對齊）。

---

## 6. ✅ 語音腦路線評估結論（2026-06-27 · 三角度收斂 · **Edward 已拍板**）

**🎯 Edward 6/27 拍板語言分階段：v1 只做台灣中文（華語）、先克服華語；英語+台語往後期。** → v1 語音腦＝**gpt-realtime-2 單腦（台灣中文 S2S）**，乾淨、proven、最低風險。**台語那條「自拼 pipeline」的兩顆腦架構＝整個延後到台語期（v2 護城河加深）**，卡西法的台語 pipeline 深評同步延後、不卡 v1。

**v1 走 A（OpenAI gpt-realtime-2、台灣中文）、自架(B)當半年後備胎、混合(C)是路線圖不是 v1。**

| 角度（誰的本份）| 結論 |
|---|---|
| 🔧 技術（CTO 卡西法）| 自架語音腦**現在是死路**：① 台語從沒實測過、自架國語 TTS 已撞 83% CER ② 即時 <250ms 只有一體式即時模型做得到、cascade 自架累加到秒級 + cold start 9.6s ③ 自架要自扛半夜維運（掛了長輩沒人陪）。A 是唯一現在達得到北極星的路。|
| 💰 成本（CFO 蘇菲）| 三年內規模 OpenAI 比自架省；自架要 ~幾百人同時在線才損益平衡、沐寧到不了。成本被「90/10 比例＋快取命中率」綁架（兩個假設要先驗）。財務模型有 STT+TTS 重複計費要修。|
| 🔒 合規（Trust 沙利曼）| 長輩語音=敏感個資、走 OpenAI=送美國 → 必確認 zero-retention/DPA；B2B2C 資安稽核會問。此條若卡，反推提早自架。|

**🎯 三方共同盲點（最該先補）**：**台語從頭到尾沒被真正實測**（自架沒測、連 gpt-realtime 也只有國語 log）→ **v1 上線前必用 gpt-realtime-2 實測一輪台語對話**，台語是生死關、不能用「多語很強」假設帶過。

**待補的一塊外部掃描**（決定半年備胎走不走通）：2026 年「台語專用開源 ASR/TTS/即時語音模型」現況——授權友善、能本機跑、延遲品質達陪伴門檻的有沒有。

**前置驗證（與開發並行、不卡上線）**：① 90/10 真實佔比小樣本實測（成本單點故障）② OpenAI zero-retention/DPA 確認 ③ gpt-realtime 台語實測。

---
*串引擎計畫 v2 · 2026-06-27 · 蘇菲 · 已讀引擎程式庫落實 · 取代 v1「API 待讀」。動臉技術前必讀引擎 deadends-memo。*
