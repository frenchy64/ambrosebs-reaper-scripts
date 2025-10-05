#!/bin/bash
# Example script to run the posture MIDI filter

cd "$(dirname "$0")"

echo "Building the posture MIDI filter..."
lein uberjar

if [ $? -eq 0 ]; then
  echo "Build successful! Running application..."
  echo "Press Ctrl+C to stop."
  echo ""
  java -jar target/uberjar/posture-midi-filter-0.1.0-SNAPSHOT-standalone.jar
else
  echo "Build failed!"
  exit 1
fi
