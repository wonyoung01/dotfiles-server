#!/usr/bin/env bash
# Usage: cpu_ram.sh <pane_tty>
# Output: " CPU <sys>% | RAM <sys>% | <full cmdline> "
# Linux: CPU via iostat/sar (like tmux-cpu plugin) with /proc/stat fallback,
#        RAM from /proc/meminfo.
# macOS: CPU via `top` (two 1s samples), RAM from vm_stat (active + wired +
#        compressed over hw.memsize). macOS iostat has different flags and its
#        last column is a load average, and there is no /proc.

if [[ "$(uname)" == "Darwin" ]]; then

get_cpu() {
  # First sample is since-boot; the second (1s later) is current.
  # Line: "CPU usage: 6.25% user, 12.5% sys, 81.25% idle"
  top -l 2 -n 0 -s 1 2>/dev/null | awk '/^CPU usage/ { u=$3; s=$5 }
    END { gsub(/%/, "", u); gsub(/%/, "", s); printf "%.0f", u + s }'
}

get_ram() {
  vm_stat 2>/dev/null | awk -v total="$(sysctl -n hw.memsize 2>/dev/null)" '
    /page size of/                  { ps = $8 + 0 }
    /^Pages active/                 { a  = $NF + 0 }
    /^Pages wired down/             { w  = $NF + 0 }
    /^Pages occupied by compressor/ { c  = $NF + 0 }
    END { if (total > 0 && ps > 0) printf "%.0f", (a + w + c) * ps / total * 100; else print 0 }'
}

else

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

get_ram() {
  awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END { if (t>0) printf "%.0f", (1 - a/t) * 100; else print 0 }' /proc/meminfo
}

fi

cpu_sys=$(get_cpu)
ram_sys=$(get_ram)

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
