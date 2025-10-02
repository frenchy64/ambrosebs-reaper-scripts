#!/usr/bin/env bash

set -e

if [ ! -d "$HOME/.config/REAPER/Effects" ]; then
  echo "Could not find REAPER config directory"
  exit 1
fi

if [ ! -f "$HOME/.config/REAPER/Effects/ambrosebs MIDI" ]; then
  ln -s "$(pwd)/MIDI" "$HOME/.config/REAPER/Effects/ambrosebs MIDI"
fi
