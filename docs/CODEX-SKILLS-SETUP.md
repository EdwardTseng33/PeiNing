# Codex Skills Setup

Munea keeps Codex operating skills in this repository so another computer can continue the same development posture.

These files do not change Claude's runtime behavior. They are Codex-local skills stored in the repo for sync. Claude can read them as reference material, but Claude will not automatically load them unless its own environment is configured to do so.

## Source Of Truth

```text
codex-skills/
  cto-context-architect/
    SKILL.md
  munea-cto/
    SKILL.md
```

## What They Do

- `cto-context-architect`: global CTO / architecture / production-readiness operating mode.
- `munea-cto`: Munea-specific overlay for product direction, backend/API, Supabase, App Store, subscription, voice/avatar, admin, analytics, and data safety work.

## Install On Another Windows Computer

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-codex-skills.ps1
```

Then restart Codex so it reloads available skills.

## Manual Install

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills" | Out-Null
Copy-Item -Recurse -Force .\codex-skills\cto-context-architect "$env:USERPROFILE\.codex\skills\"
Copy-Item -Recurse -Force .\codex-skills\munea-cto "$env:USERPROFILE\.codex\skills\"
```

## Optional Validation

If the Codex system validator exists on the machine:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\cto-context-architect"
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\munea-cto"
```

The repo smoke test also checks that the repo-backed skill files have the expected frontmatter:

```powershell
npm run smoke:no-api
```

## Collaboration Boundary

- Codex skills are stored here to make Codex behavior portable.
- Claude collaboration is unaffected unless Claude explicitly reads or imports these files.
- Do not store secrets, API keys, Supabase credentials, Apple keys, or private user data in skills.
- If the product direction changes, update both the product docs and the relevant skill text in the same pull/commit.
