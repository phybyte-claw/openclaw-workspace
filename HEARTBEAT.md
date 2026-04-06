# HEARTBEAT.md

## Active Checks

Run these periodically (2-3x/day). Skip late night (23:00-08:00 Berlin time) unless urgent.

### 1. OpenClaw Health
- `openclaw health` — check gateway, Telegram, agents
- Verify `discord_listener.py` is still running (`ps aux | grep discord_listener`)
- Check cron job last run status (`openclaw cron list`)

### 2. LMStudio Model Status
- Ping `http://moonstation:1234/v1/models` — confirm qwen3-coder-30b is loaded
- If no response or model missing, note it for Philippe

### 3. System Health (quick)
- Disk usage on root (`df -h /`)
- Load average (`uptime`)
- Alert Philippe if disk > 80% or load is sustained high

## Delivery

Report to Philippe via Telegram (ID: 762062103) only if something needs attention.
If everything is healthy, reply HEARTBEAT_OK — no message needed.
