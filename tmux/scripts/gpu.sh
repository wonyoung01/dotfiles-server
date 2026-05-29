#!/usr/bin/env bash

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "NoGPU"
  exit 0
fi

nvidia-smi --query-gpu=index,utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits |
  awk -F',' '
{
  gsub(/ /, "", $1)
  gsub(/ /, "", $2)
  gsub(/ /, "", $3)
  gsub(/ /, "", $4)

  vram_pct = ($3 / $4) * 100

  printf " GPU%s: %s%%/%.1f%% |", $1, $2, vram_pct
}'
