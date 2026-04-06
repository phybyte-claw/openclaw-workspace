# MEMORY.md

## Philippe

- Philippe prefers concise, technical responses for work, and a more relaxed tone in casual conversation.
- When reasonable, default toward taking action instead of asking for permission.
- Philippe is an SRE at a space company working with infrastructure, automation, and distributed systems.
- He runs a homelab with Proxmox, Ansible, Tailscale, and n8n.
- He is building a public brand called Phybyte around space infrastructure and AI automation, with a YouTube channel and presence on X and LinkedIn.
- Telegram user ID: `762062103`

## Workspace / OpenClaw

- This workspace already had a git history before the latest bootstrap; earlier work included OpenClaw maintenance automation and backup snapshots.
- The workspace contains a redacted public config snapshot at `config/openclaw.public.json` for safe configuration review.
- OpenClaw binary: `/home/ubuntu/.nvm/versions/node/v24.14.1/bin/openclaw` (not in PATH by default).

## Agents

- Three agents configured: `main` ⚡ (default), `scout` 🛰️ (x-briefing Discord channel), `engineer` ⚙️ (tech-ops Discord channel).
- All agents use `qwen/qwen3-coder-30b` as primary model with `openai-codex/gpt-5.4` as fallback.
- Discord routing handled by `discord_listener.py` in this workspace.

## Model Notes (Critical)

- **Gemma-4-26b:** Pure reasoning model on this LMStudio setup — output goes to `reasoning_content` only, `content` is always empty. OpenClaw gateway fails to parse it. Do not use as primary.
- **Qwen3.5-9b:** Same reasoning-only issue as Gemma-4.
- **Llama-3.3-70b:** OOM on moonstation (~61GB required).
- **Qwen3-coder-30b:** Works correctly. ~45s cold-start after LMStudio idles.

## Claw

- Name: Claw
- Nature: calm, competent machine familiar
- Vibe: low-drama, dryly funny, sharp when needed
- Emoji: ⚡
