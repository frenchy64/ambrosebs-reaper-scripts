#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <absolute-path-to-liveness-file>"
  exit 1
fi

LIVENESS_FILE="$1"

TMPDIR="$(mktemp -d)"
SCRIPT_PATH="$TMPDIR/test_hello_world.lua"

# Write Hello World Lua script
cat > "$SCRIPT_PATH" << EOF
local liveness_path = [[${LIVENESS_FILE}]]
local resource_path = reaper.GetResourcePath()
reaper.ShowConsoleMsg("ResourcePath: " .. resource_path .. "\\n")
local file = io.open(liveness_path, "w")
if file then
  file:write("Hello World from GitHub Actions!\\n")
  file:close()
  reaper.ShowConsoleMsg("Successfully wrote file!\\n")
else
  reaper.ShowConsoleMsg("Failed to write file!\\n")
end
reaper.ShowConsoleMsg("Hello World from GitHub Actions!\\n")
EOF

echo "Running REAPER Hello World script at $SCRIPT_PATH ..."
reaper -nosplash -new -ignoreerrors -close:exit "$SCRIPT_PATH"
