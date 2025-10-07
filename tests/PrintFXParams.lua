--[[
Monitors all parameters (sliders) for the first FX on the first track.
Prints out which slider changed and stops execution on first change.
]]

local track = reaper.GetTrack(0, 0) -- first track
local fx_idx = 0 -- first FX on track

if not track then
  reaper.ShowConsoleMsg("No track found.\n")
  return
end

local num_params = reaper.TrackFX_GetNumParams(track, fx_idx)
local prev_vals = {}

-- Initialize with current values
for i = 0, num_params-1 do
  local val = reaper.TrackFX_GetParam(track, fx_idx, i)
  prev_vals[i] = val
end

function check_for_changes()
  for i = 0, num_params-1 do
    local _, val = reaper.TrackFX_GetParam(track, fx_idx, i)
    if val ~= prev_vals[i] then
      reaper.ShowConsoleMsg(
        string.format("Slider %d changed: %.6f -> %.6f\n", i, prev_vals[i], val)
      )
      return -- stop on first change
    end
  end
  reaper.defer(check_for_changes)
end

reaper.ShowConsoleMsg("Monitoring sliders for changes. Move a slider in the FX UI or set via script...\n")
check_for_changes()
