#!/usr/bin/env bash
# Usage: cpu_ram.sh <pane_tty>
# Output: " CPU <sys>% | RAM <sys>% | <full cmdline> "
# CPU is measured using iostat/sar (like tmux-cpu plugin) with /proc/stat fallback.

get_cpu() {
  # iostat -c 1 2 takes two samples 1s apart; last line's final column is %idle.
  if command -v iostat >/dev/null 2>&1; then
    iostat -c 1 2 2>/dev/null | sed '/^\s*$/d' | tail -n 1 | \
      awk '{usage=100-$NF} END {printf "%.0f", usage}' | sed 's/,/./'
    return
  fi
  # sar -u 1 1: same idea, final column is %idle.
  if command -v sar >/dev/null 2>&1; then
    sar -u 1 1 2>/dev/null | sed '/^\s*$/d' | tail -n 1 | \
      awk '{usage=100-$NF} END {printf "%.0f", usage}' | sed 's/,/./'
    return
  fi
  # Fallback: /proc/stat delta over 1s.
  read s1 i1 < <(awk '/^cpu / { print $2+$3+$4+$5+$6+$7+$8+$9, $5+$6; exit }' /proc/stat)
  sleep 1
  read s2 i2 < <(awk '/^cpu / { print $2+$3+$4+$5+$6+$7+$8+$9, $5+$6; exit }' /proc/stat)
  awk -v s1="$s1" -v i1="$i1" -v s2="$s2" -v i2="$i2" \
    'BEGIN { dt=s2-s1; di=i2-i1; if (dt<=0) { print 0; exit }
             v=(1-di/dt)*100; if (v<0) v=0; if (v>100) v=100; printf "%.0f", v }'
}

cpu_sys=$(get_cpu)
ram_sys=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END { if (t>0) printf "%.0f", (1 - a/t) * 100; else print 0 }' /proc/meminfo)

# Foreground process on the pane tty — full command line.
tty=${1#/dev/}
full="-"
if [[ -n "$tty" ]]; then
  parsed=$(ps -t "$tty" -o stat=,args= 2>/dev/null | \
    awk '$1 ~ /\+/ && $2 != "ps" {
      args=""
      for (i=2; i<=NF; i++) args = args (i>2 ? " " : "") $i
      print args
      exit
    }')
  [[ -n "$parsed" ]] && full="$parsed"
fi

printf " CPU %s%% | RAM %s%% | %s " "$cpu_sys" "$ram_sys" "$full"
