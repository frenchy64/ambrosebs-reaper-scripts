#!/usr/bin/env bash
set -e

LOG_FILE="/tmp/reaper_recording_test.log"
TEST_SCRIPT="/tmp/test_recording.lua"

# Create minimal test script
cat > "$TEST_SCRIPT" << 'EOF'
local log_file = "/tmp/reaper_recording_test.log"

local function log(msg)
  reaper.ShowConsoleMsg(msg .. "\n")
  local f = io.open(log_file, "a")
  if f then
    f:write(msg .. "\n")
    f:close()
  end
end

log("=== REAPER Recording Test ===")
log("REAPER version: " .. reaper.GetAppVersion())

-- Create and arm a track
reaper.InsertTrackAtIndex(0, true)
local track = reaper.GetTrack(0, 0)
reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 4096)
log("Track created and armed")

-- Attempt to start recording
log("Attempting to start recording with Main_OnCommand(1013)...")
reaper.Main_OnCommand(1013, 0)

local attempts = 0
local max_attempts = 50

local function check_recording()
  attempts = attempts + 1
  local play_state = reaper.GetPlayState()
  local is_recording = (play_state & 4) ~= 0
  
  if attempts <= 5 or attempts % 10 == 0 then
    log(string.format("Attempt %d: play_state=%d, recording=%s", 
      attempts, play_state, is_recording and "YES" or "NO"))
  end
  
  if is_recording then
    log("SUCCESS: Recording started after " .. attempts .. " attempts")
    reaper.OnStopButton()
    log("Summary: RECORDING_WORKS")
  elseif attempts < max_attempts then
    reaper.defer(check_recording)
  else
    log("FAILED: Recording never started after " .. max_attempts .. " attempts")
    log("Summary: RECORDING_FAILED")
  end
end

reaper.defer(check_recording)
EOF

echo "Running REAPER recording test..."
rm -f "$LOG_FILE"

# Check if reaper is available
if ! command -v reaper &> /dev/null; then
  echo "ERROR: 'reaper' command not found in PATH"
  echo "Please ensure REAPER is installed and available in PATH"
  exit 1
fi

# Run REAPER with a timeout
timeout 10 reaper -nosplash -new -ignoreerrors "$TEST_SCRIPT" 2>&1 || true

# Give it a moment to finish writing
sleep 1

# Display results
echo ""
echo "==================== Test Results ===================="
if [ -f "$LOG_FILE" ]; then
  cat "$LOG_FILE"
  echo ""
  echo "======================================================"
  
  if grep -q "Summary: RECORDING_WORKS" "$LOG_FILE"; then
    echo "✓ Test PASSED: Recording works in headless mode"
    exit 0
  elif grep -q "Summary: RECORDING_FAILED" "$LOG_FILE"; then
    echo "✗ Test FAILED: Recording does not work in headless mode"
    exit 1
  else
    echo "✗ Test INCOMPLETE: No conclusive result"
    exit 1
  fi
else
  echo "✗ Test ERROR: Log file not created"
  exit 1
fi
