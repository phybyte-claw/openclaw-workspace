#!/bin/bash
# system-metrics.sh — called by Engineer agent to report system health

echo "=== SYSTEM METRICS: $(hostname) ==="
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Uptime:    $(uptime -p)  |  load: $(uptime | awk -F'load average:' '{print $2}' | xargs)  |  CPUs: $(nproc)"
echo ""

# --- CPU 24h stats from sar ---
echo "--- CPU (24h via sar) ---"
CPU_DATA=$(
    for f in $(ls /var/log/sysstat/sa[0-9][0-9] 2>/dev/null | sort | tail -2); do
        sar -u -f "$f" 2>/dev/null | grep -v "^$\|Linux\|CPU\|Average"
    done | awk '{print 100-$NF}'
)
if [ -n "$CPU_DATA" ]; then
    CPU_MAX=$(echo "$CPU_DATA" | sort -n | tail -1)
    COUNT=$(echo "$CPU_DATA" | wc -l)
    MID=$(( (COUNT + 1) / 2 ))
    CPU_MEDIAN=$(echo "$CPU_DATA" | sort -n | sed -n "${MID}p")
    echo "  median=${CPU_MEDIAN}%  max=${CPU_MAX}%  (${COUNT} samples)"
else
    echo "  no sar data available"
fi
echo ""

# --- Memory ---
echo "--- Memory (24h via sar) ---"
MEM_DATA=$(
    for f in $(ls /var/log/sysstat/sa[0-9][0-9] 2>/dev/null | sort | tail -2); do
        sar -r -f "$f" 2>/dev/null | grep -v "^$\|Linux\|kbmemfree\|Average"
    done | awk '{print $5}'
)
if [ -n "$MEM_DATA" ]; then
    MEM_MAX=$(echo "$MEM_DATA" | sort -n | tail -1)
    COUNT=$(echo "$MEM_DATA" | wc -l)
    MID=$(( (COUNT + 1) / 2 ))
    MEM_MEDIAN=$(echo "$MEM_DATA" | sort -n | sed -n "${MID}p")
    echo "  usage: median=${MEM_MEDIAN}%  max=${MEM_MAX}%  (${COUNT} samples)"
fi
free -h | awk '
    /Mem:/  { printf "  RAM:  total=%-6s  used=%-6s  free=%-6s  avail=%s\n", $2, $3, $4, $7 }
    /Swap:/ { if ($2 != "0B") printf "  Swap: total=%-6s  used=%-6s  free=%s\n", $2, $3, $4 }
'
echo ""

# --- Disk (real mounts only) ---
echo "--- Disk ---"
df -h --output=target,size,used,avail,pcent | \
    grep -v "^tmpfs\|^udev\|^Filesystem\|^/run/credentials\|^/dev/shm\|^/run/lock\|^/run " | \
    awk 'NR>1 {
        gsub(/%/,"",$5)
        flag = ($5+0 >= 80) ? " ⚠️ HIGH" : ""
        printf "  %-12s  size=%-6s  used=%-6s  avail=%-6s  use=%s%%%s\n", $1, $2, $3, $4, $5, flag
    }'
echo ""

# --- Top processes by CPU ---
echo "--- Top 5 Processes (CPU) ---"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6 | \
    awk 'NR==1 { printf "  %-7s %-22s %5s  %5s\n", "PID", "COMMAND", "%CPU", "%MEM" }
         NR>1  { printf "  %-7s %-22s %4s%%  %4s%%\n", $1, $2, $3, $4 }'
echo ""

# --- Key Services ---
echo "--- Services ---"
for svc in openclaw-gateway; do
    STATUS=$(systemctl --user is-active "$svc" 2>/dev/null || echo "unknown")
    ICON=$([ "$STATUS" = "active" ] && echo "✅" || echo "❌")
    echo "  $ICON $svc: $STATUS"
done

DISC_PID=$(pgrep -f discord_listener.py 2>/dev/null | tr '\n' ' ' | xargs)
if [ -n "$DISC_PID" ]; then
    echo "  ✅ discord_listener: running (pid $DISC_PID)"
else
    echo "  ❌ discord_listener: not running"
fi

LMSTUDIO_MODELS=$(curl -s --max-time 3 http://moonstation:1234/v1/models 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); [print('  ✅ LMStudio: '+str(len(d['data']))+' models — '+', '.join(m['id'].split('/')[-1] for m in d['data'][:4])+'...' if len(d['data'])>4 else '  ✅ LMStudio: '+str(len(d['data']))+' models — '+', '.join(m['id'].split('/')[-1] for m in d['data']))]" 2>/dev/null)
if [ -n "$LMSTUDIO_MODELS" ]; then
    echo "$LMSTUDIO_MODELS"
else
    echo "  ❌ LMStudio (moonstation): unreachable"
fi
