#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <output-summary-path>"
  exit 1
fi

SUMMARY_FILE="$1"
TEST_SCRIPT="test/test_midi_drum_trainer.lua"

echo "Running REAPER with test script $TEST_SCRIPT and summary file $SUMMARY_FILE ..."

export REAPER_MIDI_DRUM_TRAINER_SUMMARY_FILE="$SUMMARY_FILE"

reaper -nosplash -new -ignoreerrors -close:exit "$TEST_SCRIPT" &
REAPER_PID=$!

TIMEOUT=120
SECONDS_WAITED=0
while [ ! -f "$SUMMARY_FILE" ]; do
  sleep 2
  SECONDS_WAITED=$((SECONDS_WAITED + 2))
  if [ "$SECONDS_WAITED" -ge "$TIMEOUT" ]; then
    echo "Timed out waiting for summary file. Killing REAPER process $REAPER_PID."
    kill $REAPER_PID || true
    exit 1
  fi
done

echo "Summary file detected. Killing REAPER process $REAPER_PID."
kill $REAPER_PID || true
