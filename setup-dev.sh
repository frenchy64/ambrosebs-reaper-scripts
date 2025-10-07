#!/usr/bin/env bash

set -e

if [ ! -d "$HOME/.config/REAPER/Effects" ]; then
  echo "Could not find REAPER config directory"
  exit 1
fi

MIDI_LINK="$HOME/.config/REAPER/Effects/ambrosebs MIDI"
TESTS_LINK="$HOME/.config/REAPER/Scripts/ambrosebs Tests"

if [ ! -f "$MIDI_LINK" ]; then
  ln -s "$(pwd)/MIDI" "$MIDI_LINK"
fi
if [ ! -f "$TESTS_LINK" ]; then
  ln -s "$(pwd)/tests" "$TESTS_LINK"
fi
