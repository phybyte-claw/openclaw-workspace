#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRONTAB_FILE="$SCRIPT_DIR/system-crontab.txt"

if [[ ! -f "$CRONTAB_FILE" ]]; then
  echo "Missing crontab snapshot: $CRONTAB_FILE" >&2
  exit 1
fi

crontab "$CRONTAB_FILE"
echo "Installed crontab from $CRONTAB_FILE"
