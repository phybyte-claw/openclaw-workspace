#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENCLAW_HOME="${OPENCLAW_HOME:-/home/ubuntu/.openclaw}"

restore_agent() {
  local name="$1"
  local src="$ROOT_DIR/agents/$name"
  local dst

  case "$name" in
    main) dst="$OPENCLAW_HOME/workspace" ;;
    *) dst="$OPENCLAW_HOME/workspace-$name" ;;
  esac

  mkdir -p "$dst"
  rsync -a --delete \
    --exclude '.git' \
    --exclude '.openclaw' \
    "$src/" "$dst/"

  echo "restored $name -> $dst"
}

for agent in "$ROOT_DIR"/agents/*; do
  [ -d "$agent" ] || continue
  restore_agent "$(basename "$agent")"
done

echo "Done. Secrets and runtime state still need to be restored manually."
