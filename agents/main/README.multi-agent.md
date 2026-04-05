# OpenClaw Multi-Agent Backup Layout

This repo is the safe, portable definition of the OpenClaw setup.

## Goal

Make it possible to rebuild the full agent setup on a new server without dragging along live secrets, sessions, or device auth state.

## Recommended structure

```text
agents/
  main/
  engineer/
  scout/
shared/
routing/
deploy/
```

## What belongs in git

Per agent:
- `AGENTS.md`
- `SOUL.md`
- `USER.md`
- `IDENTITY.md`
- `HEARTBEAT.md`
- `TOOLS.md`
- `MEMORY.md` if it contains only safe, intended-to-persist context
- small helper scripts
- safe documentation

Shared:
- routing docs
- deployment docs
- restore scripts
- public/redacted config snapshots

## What must stay out of git

- `credentials/`
- tokens / API keys / cookies
- `.openclaw/**` runtime state
- `sessions/`
- device pairing/auth state
- logs
- local virtualenvs
- anything in backups that contains live secrets

## Current local agent workspaces

- main: `/home/ubuntu/.openclaw/workspace`
- engineer: `/home/ubuntu/.openclaw/workspace-engineer`
- scout: `/home/ubuntu/.openclaw/workspace-scout`

## Restore model

1. Clone repo on new host
2. Recreate agent workspaces from `agents/*`
3. Re-add secrets locally (not from git)
4. Recreate routing/channel bindings
5. Restart OpenClaw gateway/agents

## Notes

This repo should be the reproducible skeleton, not a dump of the machine state.
