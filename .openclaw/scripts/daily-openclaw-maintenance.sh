#!/usr/bin/env bash
set -u

PATH="$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
TZ="Europe/Berlin"
export TZ

OPENCLAW_CMD=(node "$HOME/.npm-global/lib/node_modules/openclaw/openclaw.mjs")
CHANNEL_TARGET="channel:1486064862160486563"
CHANNEL_KIND="discord"
NOW="$(date '+%Y-%m-%d %H:%M:%S %Z')"
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || hostname || echo unknown-host)"
WORKDIR="$HOME/.openclaw/workspace"
TMPDIR_BASE="${TMPDIR:-/tmp}"
RUN_DIR="$(mktemp -d "$TMPDIR_BASE/openclaw-maintenance.XXXXXX")"
BEFORE_FILE="$RUN_DIR/update-status-before.txt"
AFTER_FILE="$RUN_DIR/update-status-after.txt"
UPDATE_LOG="$RUN_DIR/update.log"
RESTART_LOG="$RUN_DIR/restart.log"
STATUS_LOG="$RUN_DIR/status.log"
RESULT_SUMMARY="$RUN_DIR/report.txt"
OPENCLAW_VERSION_BEFORE="unknown"
OPENCLAW_VERSION_AFTER="unknown"
UPDATE_EXIT=0
RESTART_EXIT=0
STATUS_EXIT=0
FAIL_STEP=""
CLEANUP_NEEDED=1

cleanup() {
  if [[ "$CLEANUP_NEEDED" == "1" && -d "$RUN_DIR" ]]; then
    rm -rf "$RUN_DIR"
  fi
}
trap cleanup EXIT

run_capture() {
  local log_file="$1"
  shift
  set +e
  "$@" >"$log_file" 2>&1
  local rc=$?
  set -e
  return "$rc"
}

extract_version() {
  local file="$1"
  awk '/npm latest/ {print $NF; found=1} END {if (!found) exit 1}' "$file" 2>/dev/null || true
}

suggest_fix() {
  local step="$1"
  case "$step" in
    update)
      cat <<'EOF'
Suggested fixes:
- Run `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs update status` to verify the active install source/channel.
- Run `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs update --yes --no-restart` manually to inspect the full error output.
- If it timed out, rerun during a quieter window and inspect network/package-manager latency.
- If the update says the working tree is dirty, clean or stash local changes first.
- If package install/build failed, inspect the update log and rerun `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs doctor`.
EOF
      ;;
    restart)
      cat <<'EOF'
Suggested fixes:
- Run `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs gateway status` to inspect the service state.
- Run `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs gateway restart` manually and then `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs status --deep`.
- If systemd reports failures, inspect the user service logs for `openclaw-gateway.service`.
EOF
      ;;
    status)
      cat <<'EOF'
Suggested fixes:
- Run `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs update status` manually to verify the install state.
- Run `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs status --deep` to confirm the gateway and channels are healthy.
EOF
      ;;
    *)
      cat <<'EOF'
Suggested fixes:
- Review the logs captured for this run and retry manually.
- Confirm the OpenClaw gateway is reachable with `node ~/.npm-global/lib/node_modules/openclaw/openclaw.mjs status --deep`.
EOF
      ;;
  esac
}

trim_file() {
  local file="$1"
  local max_lines="${2:-40}"
  if [[ -f "$file" ]]; then
    tail -n "$max_lines" "$file"
  else
    echo "(no log captured)"
  fi
}

set -e

run_capture "$BEFORE_FILE" "${OPENCLAW_CMD[@]}" update status || true
if [[ -s "$BEFORE_FILE" ]]; then
  OPENCLAW_VERSION_BEFORE="$(extract_version "$BEFORE_FILE")"
  [[ -n "$OPENCLAW_VERSION_BEFORE" ]] || OPENCLAW_VERSION_BEFORE="unknown"
fi

if ! run_capture "$UPDATE_LOG" timeout 1800 "${OPENCLAW_CMD[@]}" update --yes --no-restart; then
  UPDATE_EXIT=$?
  FAIL_STEP="update"
fi

if [[ -z "$FAIL_STEP" ]]; then
  if ! run_capture "$RESTART_LOG" "${OPENCLAW_CMD[@]}" gateway restart; then
    RESTART_EXIT=$?
    FAIL_STEP="restart"
  fi
fi

if ! run_capture "$AFTER_FILE" "${OPENCLAW_CMD[@]}" update status; then
  STATUS_EXIT=$?
  [[ -z "$FAIL_STEP" ]] && FAIL_STEP="status"
fi

if [[ -s "$AFTER_FILE" ]]; then
  OPENCLAW_VERSION_AFTER="$(extract_version "$AFTER_FILE")"
  [[ -n "$OPENCLAW_VERSION_AFTER" ]] || OPENCLAW_VERSION_AFTER="unknown"
fi

{
  echo "OpenClaw daily maintenance report"
  echo "Time: $NOW"
  echo "Host: $HOSTNAME_SHORT"
  echo ""
  if [[ -z "$FAIL_STEP" ]]; then
    echo "Status: SUCCESS"
    echo ""
    echo "Summary:"
    if [[ "$OPENCLAW_VERSION_BEFORE" != "$OPENCLAW_VERSION_AFTER" && "$OPENCLAW_VERSION_AFTER" != "unknown" ]]; then
      echo "- OpenClaw version changed: $OPENCLAW_VERSION_BEFORE -> $OPENCLAW_VERSION_AFTER"
    else
      echo "- OpenClaw version unchanged: $OPENCLAW_VERSION_AFTER"
    fi
    echo "- Update command completed successfully"
    echo "- Gateway restart completed successfully"
    echo ""
    echo "Update output (tail):"
    trim_file "$UPDATE_LOG" 30
    echo ""
    echo "Current version status:"
    cat "$AFTER_FILE"
  else
    echo "Status: FAILURE"
    echo ""
    echo "Failure point: $FAIL_STEP"
    case "$FAIL_STEP" in
      update)
        if [[ "${UPDATE_EXIT:-0}" == "124" ]]; then
          echo "- openclaw update --yes --no-restart timed out after 1800 seconds"
        else
          echo "- openclaw update --yes --no-restart failed with exit code ${UPDATE_EXIT:-unknown}"
        fi
        ;;
      restart)
        echo "- update completed, but openclaw gateway restart failed with exit code ${RESTART_EXIT:-unknown}"
        ;;
      status)
        echo "- update/restart may have completed, but openclaw update status failed with exit code ${STATUS_EXIT:-unknown}"
        ;;
    esac
    echo ""
    suggest_fix "$FAIL_STEP"
    echo ""
    echo "Relevant logs:"
    if [[ -f "$UPDATE_LOG" ]]; then
      echo "- Update log (tail):"
      trim_file "$UPDATE_LOG" 40
      echo ""
    fi
    if [[ -f "$RESTART_LOG" ]]; then
      echo "- Restart log (tail):"
      trim_file "$RESTART_LOG" 40
      echo ""
    fi
    if [[ -f "$AFTER_FILE" ]]; then
      echo "- Post-run update status:"
      cat "$AFTER_FILE"
    fi
  fi
} > "$RESULT_SUMMARY"

"${OPENCLAW_CMD[@]}" message send --channel "$CHANNEL_KIND" --target "$CHANNEL_TARGET" --message "$(cat "$RESULT_SUMMARY")"
