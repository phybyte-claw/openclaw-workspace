# TOOLS.md - Claw's Setup Notes

## Infrastructure

- **LMStudio host:** `moonstation` (http://moonstation:1234/v1) — local model server on Philippe's homelab
- **Primary model:** `qwen/qwen3-coder-30b` — fallback: `openai-codex/gpt-5.4`
- **Tailscale domain:** `phyclaw.tail119a2.ts.net`
- **OpenClaw gateway:** localhost:18789 (systemd user service: `openclaw-gateway`)
- **OpenClaw state dir:** `/home/ubuntu/.openclaw/`
- **OpenClaw binary:** `/home/ubuntu/.nvm/versions/node/v24.14.1/bin/openclaw`

## Agents

- `main` ⚡ — default agent, this workspace (`~/.openclaw/workspace/`)
- `scout` 🛰️ — X/Twitter intelligence, workspace `~/.openclaw/workspace-scout/`
- `engineer` ⚙️ — SRE/infra ops, workspace `~/.openclaw/workspace-engineer/`

## Discord Channels

- `x-briefing` (ID: 1490441422330134681) → Scout agent
- `tech-ops` (ID: 1490441569528971467) → Engineer agent
- Discord listener: `/home/ubuntu/.openclaw/workspace/discord_listener.py`

## Telegram

- Philippe's Telegram user ID: `762062103`
- Bot: `@PhybyteBot`

## Key Services

- `openclaw-gateway` — systemd user service
- `discord_listener.py` — background process, log at `workspace/discord_listener.log`
- LMStudio — runs on `moonstation`, port 1234

## Model Notes

- **Gemma-4-26b:** Behaves as pure reasoning model — `content` is always empty, output only in `reasoning_content`. Do not use as primary for any agent.
- **Qwen3-coder-30b:** Reliable, ~45s cold-start after LMStudio idles it out.
- **Llama-3.3-70b:** OOM on moonstation (~61GB required, insufficient RAM).
- **Qwen3.5-9b:** Also a reasoning-only model on this setup — same issue as Gemma-4.

## Homelab Stack

- **Proxmox** — hypervisor
- **Ansible** — config management
- **Tailscale** — overlay network
- **n8n** — automation workflows
