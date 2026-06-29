# Munea RunPod Avatar PoC Schedule

> Updated: 2026-06-29
> RunPod console: https://console.runpod.io/pods
> Purpose: operational checklist for Ditto retest and first LiveAvatar benchmark.

## Current Context

- Ditto has already been tested on RunPod with an RTX 4090 path.
- The previous Ditto result proved that a single consumer GPU path is plausible, but the remaining question is online / streaming fps.
- LiveAvatar has not yet been scheduled.
- LiveAvatar should not start with a 5x H800 production-style burn. First benchmark the cheaper single H100/H200 FP8 path if available.

Important boundary:

This document records the intended RunPod workflow. It does not assume Codex can see the authenticated RunPod console contents.

## PoC Priority

| Priority | PoC | Goal | RunPod Target | Decision |
|---:|---|---|---|---|
| 1 | Ditto online retest | Confirm standard real-time avatar feasibility | RTX 4090 / 24GB | Can Ditto become the standard talking-head engine? |
| 2 | LiveAvatar first benchmark | Confirm high-end engine physics and cold start | H100/H200 80GB+ single card first | Is LiveAvatar worth further investment? |
| 3 | 2D viseme mobile check | Confirm first TestFlight fallback | iPhone / WKWebView, no RunPod | Can TestFlight ship with low-cost live presence? |

## Ditto Retest

Source guide:

- `docs/Ditto-優化重測指南-2026-06-27.md`

What to answer:

1. Can optimized Ditto reach product-usable online fps?
2. Does mouth sync remain acceptable after lowering resolution and steps?
3. Is RTX 4090 enough, or does the next GPU tier matter?

Run sequence:

1. Open the previous RunPod pod if it still exists.
2. Reinstall volatile packages:

```bash
pip install tensorrt==8.6.1 --extra-index-url https://pypi.nvidia.com
pip install cuda-python==12.1.0
```

3. Confirm checkpoint files still exist:

```bash
ls -lh /workspace/ditto-talkinghead/checkpoints/
```

4. Run the optimized offline test:

```bash
python inference.py --help 2>&1 | head -60
grep -rn "max_size" inference.py core/ scripts/ 2>/dev/null | head
grep -rn "sampling_timesteps" inference.py core/ scripts/ 2>/dev/null | head
```

5. Run with target values:

- `max_size`: 1280
- `sampling_timesteps`: 25

6. Run the online config:

```bash
find /workspace -iname "v0.4_hubert_cfg_trt_online.pkl" 2>/dev/null
```

Measurement form:

```text
Ditto RunPod Pod:
GPU:
Template:
Offline baseline:
Offline optimized 1280/25:
Online optimized 1280/25:
First frame latency:
Mouth close sounds:
Sync:
Face artifacts:
Output mp4 path:
Verdict:
```

Decision:

- `>=25 online it/s` and mouth quality OK: proceed toward Ditto engine integration.
- `18-24 online it/s`: keep Ditto as conditional, test a stronger GPU tier before rejection.
- `<18 online it/s`: do not bet v1 on real-time Ditto; keep 2D viseme fallback and evaluate hybrid / pre-generated video.

## LiveAvatar First Benchmark

Source guide:

- `docs/LiveAvatar-PoC重跑指南-2026-06-27.md`
- `docs/avatar-顯卡經濟學與LiveAvatar評估-2026-06-27.md`

What to answer:

1. Can a single 80GB+ Hopper-class card run LiveAvatar in FP8 mode?
2. What fps does it actually reach?
3. Is cold start closer to 10-20 seconds or 60-90 seconds?
4. Is the output clearly better than Ditto enough to justify the cost?

Recommended first RunPod target:

- GPU: H100 80GB or H200 141GB.
- Template: CUDA 12.8 / PyTorch 2.8 if available.
- Disk: at least 120GB.

Do not start with:

- RTX 4090, because it cannot realistically hold the 14B path for LiveAvatar.
- 5x H800, unless the single-card benchmark shows a reason to spend.

Run sequence:

```bash
cd /workspace
git clone https://github.com/Alibaba-Quark/LiveAvatar && cd LiveAvatar
apt-get update && apt-get install -y ffmpeg git-lfs
git lfs install
pip install torch==2.8.0 torchvision==0.23.0 --index-url https://download.pytorch.org/whl/cu128
pip install flash_attn_3 --find-links https://windreamer.github.io/flash-attention3-wheels/cu128_torch280 --extra-index-url https://download.pytorch.org/whl/cu128
pip install -r requirements.txt
pip install "huggingface_hub[cli]"
huggingface-cli download Wan-AI/Wan2.2-S2V-14B --local-dir ./ckpt/Wan2.2-S2V-14B
huggingface-cli download Quark-Vision/Live-Avatar --local-dir ./ckpt/LiveAvatar
export ENABLE_COMPILE=false
export ENABLE_FP8=true
bash infinite_inference_single_gpu.sh
```

Second run:

```bash
export ENABLE_COMPILE=true
export ENABLE_FP8=true
time bash infinite_inference_single_gpu.sh
```

Measurement form:

```text
LiveAvatar RunPod Pod:
GPU:
Template:
Disk:
FP8 enabled:
Compile enabled:
First run fps:
Compiled run fps:
Cold start full load:
First visible frame:
GPU utilization:
VRAM usage:
Output path:
Quality vs Ditto:
Verdict:
```

Decision:

- `40-45 fps`, cold start can be hidden, quality clearly better: consider high-end engine integration behind `liveavatar` mode.
- `25-35 fps`, good quality: LiveAvatar remains premium / limited / possibly pre-generated or high-tier only.
- `<25 fps`, cold start too long, or quality not clearly better: do not invest in real-time LiveAvatar for v1.

## Current App Integration Point

The app now has `window.MuneaAvatarRuntime`.

Modes:

- `static-css`
- `2d-viseme`
- `ditto`
- `liveavatar`

RunPod outputs should feed future engine adapters behind this runtime. Do not wire Ditto or LiveAvatar directly into `聊聊` without going through the runtime contract.

## Next Scheduling Notes

- Ditto retest is the cheaper and more immediately useful RunPod task.
- LiveAvatar first benchmark is useful for strategic clarity, but it is not required for the first TestFlight if 2D viseme is acceptable.
- Stop pods immediately after each run and record output paths before shutdown.
