#!/bin/bash
# Tiles frames of a video: tool/e2e/frames.sh in.mov out.png <start_s> <dur_s> <fps> [cols]
# Also: tool/e2e/frames.sh in.mov --gaps   prints frame times and gaps > 50 ms
# while frames flow (the simulator only records changed frames).
in="$1"; out="$2"
if [ "$out" = "--gaps" ]; then
  ffprobe -v error -select_streams v:0 -show_entries frame=pts_time -of csv=p=0 "$in" |
    awk -F, 'NR>1{d=$1-p; if (d>0.05 && d<0.6) printf "%.3f gap %.0f ms\n", p, d*1000} {p=$1}'
  exit 0
fi
ss="$3"; dur="$4"; fps="$5"; cols="${6:-6}"
n=$(python3 -c "import math;print(math.ceil($dur*$fps))")
rows=$(( (n + cols - 1) / cols ))
ffmpeg -loglevel error -y -ss "$ss" -t "$dur" -i "$in" \
  -vf "fps=$fps,scale=220:-2,tile=${cols}x${rows}:padding=4:color=white" \
  -frames:v 1 "$out"
