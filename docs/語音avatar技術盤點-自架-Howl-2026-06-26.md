# 陪寧 PeiNing · 會說話的臉 — 自架技術 + 開源地景盤點（第一階段）

> **編製：** 霍爾（CPO · 移動城堡）
> **委託：** Edward Tseng
> **日期：** 2026-06-26
> **任務定位：** 兩階段研究的**第一階段（技術 + 開源地景）**。第二階段卡西法接著做「自架架構設計」，本檔是給他的彈藥。
> **方法：** WebFetch 實查 4 個參考服務官網 + WebSearch 補技術細節 + 盤點城堡已有開源資產（Duix-Avatar / SoulX-FlashHead）+ 對照《Voice Path 死路備忘錄》8 條撞牆教訓。
> **caveat：** 全文標【實查】=本輪 WebFetch/WebSearch 第一手讀到 ／【推斷】=我據技術常識與已知數據外推、未逐一驗證。

---

## ⚠️ 先講最重要的一句（給 Edward）

Edward 這輪的拍板，剛好繞過我們最痛的死路、又踩中一個新的硬骨頭，我必須誠實說清楚：

- **好消息**：2026 六月的開源地景，**「會說話的臉」這層技術上幾乎全部開源了**——擬真、卡通、即時、串流都有 Apache/MIT 授權的選項。Edward 說的「TTS 不是重點、focus 在臉」方向完全正確，臉這層的開源成熟度比一年前跳了一大級。
- **硬骨頭（沒變）**：我們死路 A（MuseTalk 即時 lipsync 撞 A100/H100 之牆）的**根本病因，在「擬真 + 即時 + 自架」這個鐵三角上依然存在**。最頂的擬真即時開源方案（阿里 LiveAvatar 14B）要 **5 張 H800** 才能 45 FPS——這跟我們一年前撞的牆是同一道牆，只是換了型號。
- **這次的差異**（為什麼這輪不是重蹈死路 A）：① 出現了**端側 / 單卡可跑的即時路線**（Duix-Mobile < 120ms、Ditto 單卡串流）——不再只有「A100 神經渲染」一條路；② **2D 卡通軌**在硬體需求上比擬真軌低一個量級，是真正穩的保底。

**一句話總判斷**：擬真軌「自架打到 Tavus/Anam 水準」=**做得到、但要嘛端側降規格、要嘛吞一張 48-80GB 的卡**，不是免費午餐；**2D 可愛動物軌才是這次商業模式撐得起的主力保底**。詳見 §五。

---

## 一、4 個參考服務逐一拆解【實查】

> Edward 要求「這次重構必須真的達到這 4 家的效果水準」。先把標竿釘死：它們各自做到什麼、怎麼做到、有沒有開源可自架版本。

### 標竿總表（4 家硬數據）

| 服務 | 核心引擎 | 延遲（speech→video）| 畫質 | 部署 | 開源/自架 | 價格 |
|---|---|---|---|---|---|---|
| **Tavus CVI** | Phoenix-4（render）+ Raven-1（感知）+ Sparrow-1（turn-taking）| **~600ms（均 sub-500ms）** | **1080p / 40+ FPS** | 雲端 only | ❌ 零開源 | $59→$397→Enterprise /月 |
| **Anam.ai** | CARA-3 單一即時模型 | **180ms 均回應**（自稱比次佳快 33%）| 未揭露 fps/解析度 | 雲端 API only | ❌ | 未公開（導頁）|
| **LiveAvatar（=HeyGen）** | WebRTC 串流即時 avatar | 自稱市場最快之一 | 未揭露 | 雲端 only | ❌ | **$0.10-0.20/分鐘**（credit 制）|
| **DUIX（硅基智能）** | 即時雙向（雲端版）/ 端側 SDK | 雲端 **200ms TTFB** / 端側 **<120ms** | 1:1 likeness、未揭露 fps | 雲端 + **端側 SDK** | ⚠️ **部分開源**（見下）| 雲端未公開、端側 SDK 開源但 1000 MAU 天花板 |

---

### 1.1 Tavus CVI —— 擬真即時的天花板【實查】

**技術路線**：三模型分工（這是業界最清楚的「會說話的臉」拆解範本）
- **Phoenix-4**（渲染）：即時臉部行為引擎、全臉動畫 + 微表情 + 情緒驅動、**1080p studio-quality lip-sync、身份一致性保持**、支援 10+ 種情緒顯式控制。官網**未明說**底層是 Gaussian splatting / diffusion / NeRF 哪一種【實查未揭露】——我**推斷**是某種即時 neural rendering（從「40+ FPS + 1080p + 即時情緒」這組合反推、純 diffusion 跑不到 40fps，較可能是 GAN-based 或蒸餾後的輕量 diffusion / splatting 混合）【推斷】。
- **Raven-1**（感知）：多模態、即時讀臉部表情 + 語氣 + 視線 + 情緒 + 環境。
- **Sparrow-1**（對話）：transformer turn-taking、處理停頓/打斷/節奏、可調耐心與可打斷度。

**即時性怎麼做到**：~600ms speech-to-video、均 sub-500ms。規模上自稱 20 億次互動、retention 比純語音 agent 高 15×。

**畫質標竿**：1080p / 40+ FPS / 微表情 + 情緒 = 目前擬真即時 talking-head 的**最高公開標竿**。

**開源/自架**：**完全沒有**。雲端 only（Vercel/AWS 相容）、零開源元件。這正是我們死路 C（把 Tavus 當 end-to-end 撞牆）的教訓來源——Tavus 是黑箱、自架這條路它一點都不給。

---

### 1.2 Anam.ai —— 延遲王、但最神秘【實查】

**技術路線**：CARA-3「industry-leading real-time avatar model」、自然動作 + 微表情。**底層渲染技術官網完全不揭露**【實查未揭露】、fps/解析度/GPU 全部不公開。

**即時性**：**180ms 均回應、自稱比次佳競品快 33%**——這是 4 家裡延遲數字最漂亮的。

**畫質標竿**：自稱在 Avatar Benchmark 2025「Naturalness / Responsiveness / Interruptibility」全項第一、對標 Tavus/HeyGen/D-ID。但**無任何客觀規格佐證**【實查】。

**開源/自架**：**完全沒有**。純雲端 API。

**霍爾解讀**：Anam 把「延遲 + 自然度 + 可打斷」當差異化主打、技術完全藏起來。它的 180ms 是**整條對話 pipeline**（含 LLM + TTS）的回應、不是單純 render 延遲——拿來跟我們自架的 render 延遲直接比不公平。**對標它要對標的是「整體對話即時感」、不是單一技術指標**。

---

### 1.3 LiveAvatar —— 其實是 HeyGen 的即時產品（重要釐清！）【實查】

**⚠️ 關鍵釐清（Edward 必看，避免混淆）**：
- **liveavatar.com** = **HeyGen 公司**推出的即時 avatar 串流產品（WebRTC、credit 制、$0.10-0.20/分鐘）。完全雲端、零開源。
- **`github.com/Alibaba-Quark/LiveAvatar`** = **阿里巴巴 Quark** 團隊的**同名但完全不同主體**的開源論文實作（ECCV 2026）。**這個才是可自架的**。
- **兩者同名、不同公司、不要搞混。** 一個是要付錢的雲端服務（HeyGen）、一個是可自架的開源模型（阿里）。

**HeyGen LiveAvatar 技術路線**：WebRTC 即時串流音視訊、自稱市場最快之一。畫質/fps/解析度未揭露【實查】。

**價格**：credit 制（1 credit = 10 美分 = Full 模式 30 秒 / Lite 模式 1 分鐘）→ 約 **$0.10/分鐘（Lite）到 $0.20/分鐘（Full）**。Starter $19/150 credits、Essential $100/1000 credits。

**開源/自架**：HeyGen 版**沒有**。但它的開源同名兄弟（阿里 LiveAvatar）是這份報告的核心發現，詳見 §二。

---

### 1.4 DUIX（硅基智能）—— 我們已有開源版，但要看清「開源了什麼」【實查 · 城堡資產】

這是 4 家裡唯一我們**手上已有開源版**的（`E:\Claude\castle-voice-engine\external\Duix-Avatar\`）。但我必須把「開源了什麼、沒開源什麼」說到骨頭裡——這正是我們撞牆的真相：

**DUIX 雲端版（duix.com 官網）**：200ms TTFB、1:1 likeness、即時雙向、含視覺感知（臉/手勢/情緒/環境）。**這個沒開源。**

**DUIX 開源版有兩條線、能力完全不同：**

| 開源 repo | 能力 | 硬體 | 授權 | 即時? |
|---|---|---|---|---|
| **`duixcom/Duix-Avatar`**（我們已有）| **離線預錄影片合成 + 數字人克隆**（含 ASR=fun-asr、TTS=fish-speech、video synth）| RTX 4070 / 32GB RAM / 100GB 碟 | 全球免費商用（**10萬用戶 or 年營收 1000萬美元才需簽約**）| ❌ **明確非即時** |
| **`duixcom/Duix-Mobile`**（新發現）| **端側即時互動 avatar SDK**、支援打斷/barge-in、串流語音 | 端側（Snapdragon 8 Gen 2 實測 <120ms）、跨 iOS/Android/平板/車載/VR/IoT/大螢幕 | ⚠️ **custom license、1000 MAU 天花板**（超過要回求 duix.com 授權）| ✅ **即時 <120ms** |

**🔴 致命細節 1（撞牆真相）**：我們手上的 `Duix-Avatar` 開源版 README 第 367 行白紙黑字——
> "Duix.Avatar's digital human realizes digital human cloning and **non-real-time video synthesis**. If you want a digital human to support **interaction**, you can visit duix.com"

**= 我們之前撞牆的根因**：手上的開源 Duix = 預錄合成（RTX 4070 可跑），**即時對話那層它沒給你、要回連雲端**。死路備忘錄裡 Edward 自己 catch 的「Duix 不可能用 A100/H100 服務每個用戶」現在有答案了：**Duix 的即時不靠 A100 神經渲染、而是靠 `Duix-Mobile` 這條「端側輕量」路線**——這就是業界輕量路線的真身。

**🔴 致命細節 2（授權地雷）**：`Duix-Mobile` 的 license **不是 Apache**、是 custom license、**1000 MAU 就觸天花板**。這比 `Duix-Avatar` 的「10萬用戶」嚴格 100 倍。陪寧若用 Duix-Mobile 當即時引擎、**過 1000 個長輩用戶就要回求授權**——商業模式上是隱藏地雷，卡西法做架構時要把這條當紅線標出來。

**霍爾判斷**：Duix 開源資產的真實價值 = **`Duix-Avatar` 拿來做「預錄招呼/固定話術」的高品質離線合成**（這條我們已驗證、RTX 4070 可跑、授權寬鬆）；`Duix-Mobile` **只能當「端側即時」的技術參考、不能當商業主力**（1000 MAU 天花板）。

---

## 二、擬真軌 · 2026 六月最新可自架 SOTA【實查】

> 目標：**即時（live 對話、非預錄）**的 photorealistic talking-head、開源 + 商用授權友善 + 可自架。

### 擬真即時自架候選總表

| 方案 | 出處 | 授權 | 即時? | GPU 需求 | 延遲 | 畫質 vs 4 家 | 商用 |
|---|---|---|---|---|---|---|---|
| **阿里 LiveAvatar 14B** ⭐ | Alibaba-Quark · ECCV 2026 | **Apache 2.0** | ✅ 45 FPS 串流 | **5× H800**（即時）/ 單卡 80GB（離線）/ FP8 48GB | 串流即時 | **最接近 Tavus**（14B diffusion、無限長度）| ✅ |
| **Ditto** ⭐ | ant-research | 開源（待確認細則）| ✅ streaming + low first-frame | **單卡可跑**【實查 streaming/realtime、卡型推斷消費級可】| 低首幀延遲 | 中高（motion-space diffusion）| ⚠️ 待查 |
| **Duix-Mobile** | 硅基智能 | custom（1000 MAU 上限）| ✅ <120ms | **端側**（手機 SoC）| <120ms | 中（端側 photorealistic）| ⚠️ 受限 |
| **MuseTalk（+ 2026 改版）** | 騰訊音樂 TMElyralab | **MIT** | ⚠️ 自稱即時、我們實測 A10G RTF 3.2 過 | 宣稱即時需強卡 | —— | 中（latent inpainting）| ✅ |
| **LatentSync 1.6** | ByteDance | **Apache 2.0** | ❌ 非即時（video2video）| RTX 4090 25fps（離線）| —— | 高（霍爾 5/23 首選）| ✅（國籍走 sulima Tier B）|
| **Hallo 2** | 復旦 | MIT-like | ❌ 非即時（4K/1hr 長片）| 高 VRAM | —— | 高 | ✅ |

### 2.1 阿里 LiveAvatar 14B —— 擬真即時自架的天花板，但帳單嚇人【實查】

**這是 2026 六月「可自架的擬真即時」最頂選項。** 直接對標 Tavus。

- **架構**：14B diffusion、base 是 **WanS2V-14B** + LoRA adapter + **distribution-matching distillation 蒸到 4 步推理**。
- **授權**：**Apache 2.0**（含 base Wan 模型）= 完全商用友善。✅
- **即時性**：**45 FPS 串流**（Timestep-forcing pipeline parallelism）、**支援 10,000+ 秒無限長度串流**（block-wise autoregressive）。
- **輸入**：音訊 + 參考圖 + 選配文字 prompt（**單張照片即可、不必影片**——這比 LatentSync 的 video2video 友善）。
- **🔴 GPU 真相（硬骨頭所在）**：
  - 即時 45 FPS = **5 張 H800**（這就是我們死路 A 的牆、換了型號而已）
  - 單卡離線 = **80GB VRAM**（A100 80G / H100）
  - FP8 量化 = **48GB GPU**（仍超過 RTX 4090 的 24GB）
  - **我們的 RTX 4090（24GB）跑不動即時、連 FP8 單卡都差一截**【實查】
- **意外彈藥**：官網明說「strong generalization across **cartoon characters**, singing, diverse scenarios」——**這個 14B 模型同時能做卡通**！對 Edward 的 2D 軌是加分（同一引擎兩軌通吃、若硬體扛得住）。
- **安裝**：Python 3.10 / PyTorch 2.8 / CUDA 12.4 / Flash Attention / FFmpeg。

**霍爾判斷**：技術上這就是「自架打到 Tavus」的答案、授權也完美。**但它的即時門檻（5×H800 或單卡 48-80GB）= 跟我們撞過的 MuseTalk A100 牆是同一種病**。要嘛租雲端 GPU（又回到月費問題、違反 Edward「不串第三方付費」精神的變體——雖然是租算力不是串服務，卡西法要算清楚 GPU 租賃月帳）、要嘛買一張 48GB+ 的卡（一次性硬體投資）。**這條路要 Edward 拍板「願意吞 GPU 成本」才走得通。**

### 2.2 Ditto —— 我最看好的「單卡即時擬真」黑馬【實查】

- **出處**：ant-research、《Ditto: Motion-Space Diffusion for Controllable Realtime Talking Head Synthesis》。
- **關鍵**：論文明確主打「**streaming processing, realtime inference, low first-frame delay**——這些是 AI 助理這種互動應用的關鍵功能」。**這是少數把「即時 + 低首幀延遲」當設計目標、而非事後優化的開源方案。**
- **GPU**：streaming/realtime【實查】、**單卡可跑**【推斷消費級可、需卡西法 PoC 實測 RTX 4090 真實 fps】。
- **授權**：source code 開源、**商用細則待確認**【實查未明】——卡西法接手第一件事查 LICENSE。
- **國籍**：ant-research（螞蟻）= 中國國籍、踩 ADR-020 邊界、需 sulima Tier B/C audit。

**霍爾判斷**：**如果 Edward 不想吞 LiveAvatar 的 GPU 帳單、Ditto 是擬真軌「單卡可跑」的最務實突破口**。它跟死路 A（MuseTalk）的差異是：MuseTalk 即時是「事後硬擠」（我們實測 A10G RTF 3.2 過不了）、Ditto 是「為即時而設計」（motion-space + 蒸餾 + 串流原生）。**但必須 PoC 實測 RTX 4090 的真實 fps + 確認商用授權**——不 PoC 就當它行 = 違反死路備忘錄鐵律。

### 2.3 為什麼 LatentSync / Hallo 2 這次降級為配角【實查 + 對照舊研究】

我 5/23 的舊研究首選 LatentSync 1.6、但**那是為「預錄」場景選的**。這次 Edward 要的是**即時 live 對話**——
- **LatentSync 1.6**：非即時（video2video、RTX 4090 離線 25fps）、且要源影片當底。✅ 適合「預錄話術池」、❌ 不適合即時對話。
- **Hallo 2**：非即時（為 4K/1hr 長片設計）、VRAM 高。✅ 適合「高品質預錄」、❌ 不適合即時。

**結論**：這兩個降為「**預錄招呼/固定話術的高畫質後援**」、不是即時主力。即時主力是 LiveAvatar（吞 GPU）或 Ditto（單卡）。

---

## 三、2D 軌 · 可愛動物/卡通即時嘴型【實查】

> 目標：風格化 2D 角色即時說話 + 嘴型同步。**這軌是 Edward 這次新增的方向、也是我判斷的商業保底。**

### 2D 即時嘴型自架候選總表

| 方案 | 路線 | 授權 | GPU/延遲 | 適配陪寧 |
|---|---|---|---|---|
| **Live2D Cubism + viseme 驅動** ⭐ | 2D rigging + 音訊→嘴形參數 | Cubism SDK（**營收門檻內免費**）| **極低、CPU/瀏覽器可跑、120-185ms** | ⭐⭐⭐ 最穩保底 |
| **NVIDIA Audio2Face（已開源）** ⭐ | 音訊→blendshapes、可驅動 2D/3D rig | **開源**（2025 NVIDIA 開源）| RTX 3070+ 即可即時 | ⭐⭐ 嘴形引擎 |
| **Azure Speech SDK viseme 事件** | TTS 同步吐 22 個 viseme ID + 時間戳 | 商用 API（但只取 viseme metadata、非串服務核心）| 極低 | ⭐ viseme 來源 |
| **阿里 LiveAvatar 14B（卡通模式）** | 同 §2.1、明說支援 cartoon | Apache 2.0 | 5×H800 / 48-80GB | ⚠️ 畫質頂但硬體貴 |
| **met4citizen/TalkingHead** | 瀏覽器 JS、3D avatar 即時 lipsync | 開源 | 瀏覽器、極輕 | ⭐ web 原型快 |
| **PIRenderer / MakeItTalk** | 風格化臉動畫 | 開源 | 輕量、消費級 | VTuber 風 |

### 3.1 主推路線：Live2D Cubism + viseme 即時驅動 ⭐【實查】

**這是 2D 可愛動物軌最成熟、最便宜、最穩的路。**

- **怎麼運作**：美術畫一隻可愛動物（貓/狗/兔）→ Live2D Cubism 做 2D rigging（拆分嘴/眼/頭部部件）→ 音訊即時抽 viseme（嘴形）→ 驅動嘴部參數。底層臉一直自然動（呼吸/眨眼/擺頭）、上層只換嘴形。
- **🟢 這正好繞過我們死路 E（viseme 整圖切換撞牆）**：死路 E 我們錯在「切整張臉的定格」、Live2D 是「只動嘴部件、底層 rig 連續動」——**架構上根本不同，正是 Duix 兩層架構的 2D 正版實現**。
- **延遲**：120-185ms（LSTM/Transformer 抽音訊特徵）、**CPU/瀏覽器就能跑、不必 GPU**。
- **授權**：Live2D Cubism SDK 在**營收門檻內免費**（小團隊/早期完全 OK、規模大才需商業授權、門檻比 Duix-Mobile 寬）。
- **嘴形來源**：可用 NVIDIA Audio2Face（開源）或 Azure viseme 事件（只取 metadata）。

**霍爾判斷**：**這軌技術風險最低、硬體成本趨近於零、且天然避開我們踩過的 viseme 整圖切換牆。** 對陪寧的長輩場景——可愛動物比「擬真人臉」更沒有恐怖谷風險、長輩接受度可能更高（參考日本介護 PARO 海豹機器人邏輯）。

### 3.2 NVIDIA Audio2Face 已開源 = 2D/3D 嘴形引擎的免費心臟【實查】

- 2025 NVIDIA **開源** Audio2Face：音訊→臉部 blendshapes、即時。
- **RTX 3070+ 即可即時**（我們的 RTX 4090 綽綽有餘）。
- 可驅動 Live2D / Unity / Unreal rig。
- **價值**：這是「音訊→嘴形」這顆心臟的免費開源版、配 Live2D 美術皮 = 完整 2D 即時說話鏈、全自架、零授權費。

---

## 四、授權盤點（商用 / 自架紅線）【實查】

> 卡西法做架構選型時的紅線清單。

### 🟢 完全商用友善（可放心自架）

| 方案 | 授權 | 軌 |
|---|---|---|
| 阿里 LiveAvatar 14B（含 Wan base）| Apache 2.0 | 擬真 + 卡通 |
| NVIDIA Audio2Face | 開源（2025 釋出）| 2D/3D 嘴形引擎 |
| MuseTalk | MIT | 擬真 |
| LatentSync 1.6 | Apache 2.0 | 預錄後援 |
| Hallo 2 | MIT-like | 預錄後援 |
| met4citizen/TalkingHead | 開源 | 2D web |

### 🟡 有條件 / 要小心（卡西法做架構前必查 LICENSE）

| 方案 | 紅線 |
|---|---|
| **Duix-Mobile** | 🔴 custom license、**1000 MAU 天花板**、超過要回求授權 + 須標「Powered by Duix.com」+ 模型名要加「duix.com」。**陪寧過 1000 長輩就觸雷。** |
| **Duix-Avatar**（我們已有）| 較寬：10萬用戶 / 年營收 1000萬美元才需簽約。離線合成可用。 |
| **Ditto** | 商用細則【實查未明】、ant-research 中國國籍踩 ADR-020、需 sulima audit。 |
| **Live2D Cubism** | 營收門檻內免費、規模大需商業授權（門檻寬）。 |

### 🟡 國籍合規（ADR-020 / sulima audit 觸發）

阿里 LiveAvatar、Ditto（ant）、Duix（硅基）、MuseTalk（騰訊）、LatentSync（ByteDance）**全是中國國籍**。
- **個人自用 + 本機 inference + 不送 cloud** = 大概率 sulima Tier B GO（同 LatentSync 前例）。
- **對外服務長輩用戶** = 必重跑 sulima Tier C audit。
- 卡西法做架構時、選任一中國國籍模型 = 派工 sulima Tier B/C 先審 weights 來源 + 推理是否本機落地。

---

## 五、誠實總判斷：自架能不能打到 Tavus/Anam 水準？【霍爾 verdict】

> Edward 要的就是這個誠實答案。我考慮我們撞過 5 次牆的歷史、不灌水。

### 擬真軌 · 能達標嗎？

**答案：技術上能、但有代價、且有一塊還沒解的硬骨頭。**

| 維度 | 自架真相 |
|---|---|
| **技術可得性** | 🟢 達標。阿里 LiveAvatar 14B（Apache 2.0）= 14B diffusion、45fps 串流、單照片驅動、畫質最接近 Tavus。技術完全開源、授權完美。 |
| **即時 GPU 帳單** | 🔴 **這是硬骨頭、跟死路 A 同病**。即時 45fps = 5×H800；單卡即時要 48-80GB。**我們的 RTX 4090（24GB）跑不動即時擬真。** 要嘛租雲端 GPU（月帳要算）、要嘛買 48GB+ 卡。 |
| **單卡突破口** | 🟡 Ditto（為即時設計、單卡可跑）是務實出路、但**商用授權 + RTX 4090 真實 fps 都要 PoC 驗證**、不能當它行。 |
| **延遲對標** | 🟡 Tavus 600ms / Anam 180ms 是整條 pipeline。自架 render 延遲可拼、但要配上我們既有的 GPT realtime（死路 C 教訓：別把 avatar 當 end-to-end、它只負責「臉」、語音/對話用既有架構）。 |

**擬真軌一句話**：**「自架打到 Tavus 畫質」做得到（LiveAvatar 14B），但「在便宜硬體上即時」還沒解**——這正是死路 A 的牆、2026 六月仍在。突破口是 Ditto（待 PoC）或吞 GPU 成本。**不 PoC 就承諾達標 = 違反死路備忘錄鐵律。**

### 2D 軌 · 是不是更穩的保底？

**答案：是。我強烈建議 2D 卡通軌當商業主力保底。**

- 🟢 **硬體成本趨近零**：Live2D + Audio2Face、CPU/瀏覽器 or RTX 3070 即可即時。沒有擬真軌的 GPU 帳單問題。
- 🟢 **天然避開兩道死路**：避開死路 A（即時 GPU 牆）+ 死路 E（viseme 整圖切換牆、Live2D 是兩層架構正版）。
- 🟢 **商業模式撐得起**：硬體便宜 = BOM 可控 = 符合 Edward「每分鐘服務費不能太貴」的鐵律。
- 🟢 **長輩接受度**：可愛動物無恐怖谷風險、可能比擬真人臉更討長輩喜歡（PARO 邏輯）。
- 🟡 **唯一 trade-off**：情感衝擊不如「真人臉」、但對「陪伴長輩」場景，可愛 > 擬真未必輸。

### 給 Edward 的拍板選項（霍爾建議）

我給三條路、附我的推薦——這是策略選擇、不是技術細節：

**選項 A · 2D 卡通保底先行（霍爾推薦當第一步）**
- 先做 Live2D 可愛動物軌：硬體零成本、避開所有撞過的牆、最快能讓長輩看到一張會說話的臉。
- 風險最低、商業模式最穩、最快驗證「長輩到底要不要這張臉」。

**選項 B · 擬真軌走 Ditto 單卡 PoC（並行探路）**
- 卡西法 PoC：Ditto 在 RTX 4090 的真實即時 fps + 商用授權確認。
- 通了 = 擬真軌不必吞 H800 帳單；不通 = 老實回報、不硬推。

**選項 C · 擬真軌吞 GPU 成本走 LiveAvatar 14B（要 Edward 拍板花錢）**
- 畫質直接對標 Tavus、但要租雲端 GPU 或買 48GB+ 卡。
- **需 Edward 明確拍板「願意為擬真畫質吞 GPU 成本」才走**——這違反「便宜自架」的精神、不是預設。

**霍爾的策略主張**：**A 先做（保底 + 最快驗證需求）、B 並行探路（擬真的便宜出路）、C 暫緩（等 A/B 結果 + Edward 願不願花 GPU 錢再說）。** 別一上來就撲擬真即時——那是我們撞過 5 次的牆、這次先用 2D 站穩、再用 Ditto 試探便宜擬真。

---

## 六、給卡西法的交接（第二階段 · 自架架構設計彈藥）

卡西法接手「自架架構設計」時，這份的可用彈藥：

1. **標竿釘死**：Tavus 600ms/1080p/40fps、Anam 180ms、Duix 200ms — 自架要對標的數字。
2. **擬真即時主選**：阿里 LiveAvatar 14B（Apache 2.0、5×H800 即時 / 48-80GB 單卡）。
3. **擬真單卡突破口**：Ditto（為即時設計、單卡）— **第一件事 PoC 實測 RTX 4090 fps + 查 LICENSE 商用**。
4. **2D 主推**：Live2D Cubism + NVIDIA Audio2Face（開源、RTX 3070+ 即時、避開死路 E）。
5. **已有資產用法**：`Duix-Avatar`（離線預錄話術、RTX 4070、授權寬）✅；`Duix-Mobile`（端側即時參考、**1000 MAU 天花板紅線**）⚠️；`SoulX-FlashHead`（有 streaming 版本、死路 B 撞過 deploy fail、接前必讀 README + tested versions）。
6. **死路紅線**（架構設計時必避）：
   - 別把 avatar 當 end-to-end（死路 C）— 語音/對話用既有 GPT realtime、avatar 只管「臉」。
   - 別承諾「便宜硬體即時擬真」沒 PoC（死路 A）。
   - 別用整圖切換做 2D（死路 E）— Live2D 兩層架構。
   - 接任何模型先讀 README + tested versions（死路 B）。
7. **合規**：所有候選模型中國國籍、選定後派 sulima Tier B（自用）/ Tier C（對外）audit。

---

## 七、引用來源【實查 · 2026-06-26 第一手】

- [Tavus CVI 官網](https://www.tavus.io/cvi)
- [Anam.ai 官網](https://anam.ai/)
- [LiveAvatar（HeyGen）官網](https://www.liveavatar.com/)
- [DUIX 官網](https://www.duix.com/)
- [Alibaba-Quark/LiveAvatar 開源（ECCV 2026）](https://github.com/Alibaba-Quark/LiveAvatar)
- [duixcom/Duix-Avatar（我們已有）](https://github.com/duixcom/Duix-Avatar)
- [duixcom/Duix-Mobile（端側即時 SDK）](https://github.com/duixcom/Duix-Mobile)
- [Ditto: Motion-Space Diffusion 論文](https://arxiv.org/html/2411.19509v3)
- [Ditto 專案頁](https://digital-avatar.github.io/ai/Ditto/)
- [NVIDIA 開源 Audio2Face](https://developer.nvidia.com/blog/nvidia-open-sources-audio2face-animation-model/)
- [8 Best Open Source Lip-Sync Models 2026](https://www.pixazo.ai/blog/best-open-source-lip-sync-models)
- [met4citizen/TalkingHead](https://github.com/met4citizen/talkinghead)
- [Real-Time Lip Sync for Live2D（EmergentMind）](https://www.emergentmind.com/topics/real-time-lip-sync-for-live-2d-animation)
- [MuseTalk arxiv](https://arxiv.org/html/2410.10122v2)
- [The Live Avatar Landscape: 10 providers 評測](https://medium.com/@ggarciabernardo/the-live-avatar-landscape-apis-transport-and-subjective-evaluation-of-10-leading-providers-5b5b6e8a54dc)

---

*霍爾 ship · 2026-06-26 · 第一階段（技術 + 開源地景）· 對照死路備忘錄 8 條撞牆教訓 · 給卡西法第二階段架構設計彈藥*
*下一步：卡西法接手「自架架構設計」、第一件事 Ditto RTX 4090 PoC + LICENSE 查核。*
