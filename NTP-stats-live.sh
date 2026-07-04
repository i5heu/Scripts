#!/usr/bin/env bash

# Which field to track
FIELD="NTP packets received"

# Extract the counter value robustly
get_counter() {
  chronyc serverstats 2>/dev/null \
    | awk -F: '/^'"$FIELD"'/ {
        # $2 is " 13232062", so trim whitespace
        val = $2
        gsub(/^[ \t]+|[ \t]+$/, "", val)
        print val
      }'
}

# Seed the previous values
prev_count=$(get_counter)
prev_time=$(date +%s)

if [[ -z $prev_count ]]; then
  echo "⚠️  Could not read '$FIELD' from chronyc—check permissions or path."
  exit 1
fi

echo "Requests/sec (Press Ctrl+C to stop) 🚀"

while true; do
  sleep 1

  curr_count=$(get_counter)
  curr_time=$(date +%s)

  # Only proceed if we got a number
  if [[ $curr_count =~ ^[0-9]+$ ]]; then
    delta_count=$(( curr_count - prev_count ))
    delta_time=$(( curr_time - prev_time ))

    if (( delta_time > 0 )); then
      # Calculate and print with two decimals
      rps=$(awk "BEGIN { printf \"%.2f\", $delta_count / $delta_time }")
      printf "\r⏱  %6s NTP req/s" "$rps"
    fi

    prev_count=$curr_count
    prev_time=$curr_time
  else
    echo -e "\n⚠️  Unexpected counter value: '$curr_count'"
    exit 1
  fi
done
