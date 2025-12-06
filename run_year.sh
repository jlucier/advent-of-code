#!/usr/bin/env bash
set -euo pipefail

if ! command -v hyperfine >/dev/null 2>&1; then
    echo "Error: hyperfine is not installed. Please install it first."
    exit 1
fi

zig build --release=fast

# ---- CONFIG ----
YEAR="$1"

# -------------------------------
# Human-friendly time formatter
# Input: seconds in float
format_time_smart() {
    local s="$1"
    awk -v s="$s" '
        BEGIN {
            if (s < 0.001)       printf "%.3f us", s * 1e6;
            else if (s < 1.0)    printf "%.3f ms", s * 1e3;
            else                 printf "%.3f s",  s;
        }
    '
}


total_mean_sec=0

echo "Running benchmarks with hyperfine..."
echo

printf "%-12s │ %-12s │ %-12s │ %-12s │ %-12s │ %-5s\n" \
  "Executable" "Mean" "Stddev" "Min" "Max" "Runs"
printf "%s\n" "─────────────┼──────────────┼──────────────┼──────────────┼──────────────┼───────"

for file in ./zig-out/bin/${YEAR}*; do
    exe=$(basename $file)

    [ ! -f "$file" ] && { echo "Missing executable: $file"; continue; }

    tmp_json=$(mktemp)

    # Run hyperfine silently, dumping JSON
    hyperfine \
        --warmup 1 \
        --max-runs 50 \
        --export-json "$tmp_json" \
        --shell=none \
        "$file >/dev/null 2>&1" \
        > /dev/null 2>&1

    # Extract values using jq
    mean=$(jq -r '.results[0].mean | if .==null then 0 else . end' "$tmp_json")
    min=$(jq -r '.results[0].min  | if .==null then 0 else . end' "$tmp_json")
    max=$(jq -r '.results[0].max  | if .==null then 0 else . end' "$tmp_json")
    stddev=$(jq -r '.results[0].stddev | if .==null then 0 else . end' "$tmp_json")
    mem=$(jq -r '.results[0].memory_usage | if .==null then 0 else . end' "$tmp_json")
    run_count=$(jq '.results[0].times | length' "$tmp_json")

    rm "$tmp_json"

    total_mean_sec=$(awk -v a="$total_mean_sec" -v m="$mean" 'BEGIN { printf "%.10f", a+m }')

    printf "%12s │ %12s │ %12s │ %12s │ %12s │ %5d\n" \
      "$exe" \
      "$(format_time_smart "$mean")" \
      "$(format_time_smart "$stddev")" \
      "$(format_time_smart "$min")" \
      "$(format_time_smart "$max")" \
      "$run_count"

done

printf "%s\n" "─────────────────────────────────────────────────────────────────────────────────"
printf "Total (mean): %s\n" "$(format_time_smart "$total_mean_sec")"

