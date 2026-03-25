# Cron backup layout

There are **two different schedulers** represented in this backup:

## 1. OpenClaw Gateway cron
Stored in:
- `cron-jobs.json`

Currently present there:
- `daily-openclaw-maintenance`

## 2. Linux user crontab
Stored in:
- `system-crontab.txt`

Current installed entries:
- `0 4 * * * /home/phybyte-claw/.openclaw/workspace/.openclaw/scripts/daily-openclaw-maintenance.sh`
- `30 4 * * * /home/phybyte-claw/.openclaw/workspace/.openclaw/scripts/daily-openclaw-backup.sh`

## Related scripts
Located in:
- `../workspace/.openclaw/scripts/`

Relevant files:
- `daily-openclaw-maintenance.sh`
- `daily-openclaw-backup.sh`
