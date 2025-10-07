#!/usr/bin/env bash
set -e

SUMMARY_FILE="$HOME/.config/REAPER/test_midi_drum_trainer.log"
TEST_SCRIPT="$(pwd)/tests/test_midi_drum_trainer.lua"

echo "Running REAPER with test script $TEST_SCRIPT and summary file $SUMMARY_FILE ..."

export REAPER_MIDI_DRUM_TRAINER_SUMMARY_FILE="$SUMMARY_FILE"

# Remove old summary file
rm -f "$SUMMARY_FILE"

reaper -nosplash -new -ignoreerrors -close:exit "$TEST_SCRIPT" &
REAPER_PID=$!

# Stream summary file to stdout as it grows; kill REAPER when summary line appears
TIMEOUT=240
SECONDS_WAITED=0

#touch "$SUMMARY_FILE"
LAST_SIZE=0

while [ "$SECONDS_WAITED" -lt "$TIMEOUT" ]; do
  if [ -f "$SUMMARY_FILE" ]; then
    NEW_SIZE=$(stat --format="%s" "$SUMMARY_FILE")
    if [ "$NEW_SIZE" -gt "$LAST_SIZE" ]; then
      tail --bytes=+$((LAST_SIZE+1)) "$SUMMARY_FILE"
      LAST_SIZE="$NEW_SIZE"
    fi

    # Check for summary line
    if grep -q "^Summary:" "$SUMMARY_FILE"; then
      echo "Summary line detected, killing REAPER process $REAPER_PID."
      kill $REAPER_PID || true
      break
    fi
  fi
  sleep 2
  SECONDS_WAITED=$((SECONDS_WAITED + 2))
done

if [ "$SECONDS_WAITED" -ge "$TIMEOUT" ]; then
  echo "Timed out waiting for summary line. Killing REAPER process $REAPER_PID."
  kill $REAPER_PID || true
  exit 1
fi
