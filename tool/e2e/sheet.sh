#!/bin/bash
# Contact sheet: tool/e2e/sheet.sh out.png in1.png in2.png ... (side by side, 360px wide each)
out="$1"; shift
args=(); filt=""; i=0
for f in "$@"; do args+=(-i "$f"); filt+="[$i:v]scale=360:-2[v$i];"; i=$((i+1)); done
ins=""; for ((j=0;j<i;j++)); do ins+="[v$j]"; done
if [ "$i" -eq 1 ]; then filt+="${ins}copy[o]"; else filt+="${ins}hstack=inputs=$i[o]"; fi
ffmpeg -loglevel error -y "${args[@]}" -filter_complex "$filt" -map "[o]" "$out"
