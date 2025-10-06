-- This script assumes SWS Extensions are installed and available.
-- It will automatically enable the REAPER config variable
--   "promptendrec" (integer, in [reaper] section)
--   0 = Don't prompt after recording ends; saves the files automatically
--   1 = Prompt the user after recording ends (default)
-- via SWS/SNM_SetIntConfigVar("promptendrec", 0) before recording,
-- and restore the previous setting immediately after recording.
-- This allows for fully automated, dialog-free test runs.
-- When constructing a GitHub Action workflow for this script,
-- ensure SWS Extensions are installed and available.

local function create_scenario_tracks(scenario_name, prev_last_track_idx)
  -- Insert folder track for scenario
  reaper.InsertTrackAtIndex(prev_last_track_idx + 1, true)
  local folder_track = reaper.GetTrack(0, prev_last_track_idx + 1)
  reaper.GetSetMediaTrackInfo_String(folder_track, "P_NAME", "Scenario: " .. scenario_name, true)
  reaper.SetMediaTrackInfo_Value(folder_track, "I_FOLDERDEPTH", 1)
  -- Insert MIDI Drum Trainer output track
  reaper.InsertTrackAtIndex(prev_last_track_idx + 2, true)
  local trainer_track = reaper.GetTrack(0, prev_last_track_idx + 2)
  reaper.GetSetMediaTrackInfo_String(trainer_track, "P_NAME", "Output", true)
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_FOLDERDEPTH", 0)
  -- Insert input track for feeding MIDI
  reaper.InsertTrackAtIndex(prev_last_track_idx + 3, true)
  local input_track = reaper.GetTrack(0, prev_last_track_idx + 3)
  reaper.GetSetMediaTrackInfo_String(input_track, "P_NAME", "Input", true)
  reaper.SetMediaTrackInfo_Value(input_track, "I_FOLDERDEPTH", -1)
  -- Set up routing (send from input to output)
  local send_idx = reaper.CreateTrackSend(input_track, trainer_track)
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_MIDIFLAGS", 0) -- MIDI only, no audio
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_SRCCHAN", -1) -- All channels
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_DSTCHAN", -1)
  return folder_track, trainer_track, input_track
end

function get_slider_param_index_by_name(track, fx_idx, slider_name)
  local num_params = reaper.TrackFX_GetNumParams(track, fx_idx)
  for i = 0, num_params - 1 do
    local _, name = reaper.TrackFX_GetParamName(track, fx_idx, i, "")
    if name:gsub("%s+", "") == slider_name:gsub("%s+", "") then
      return i
    end
  end
  return nil
end

local function set_lane_config(track, fx_idx, lanes)
  local lanes_slider_idx = get_slider_param_index_by_name(track, fx_idx, "Lanes")
  if lanes_slider_idx then
    reaper.TrackFX_SetParam(track, fx_idx, lanes_slider_idx, #lanes-1)
  end
  for i, lane in ipairs(lanes) do
    local lane_num = i
    if lane.cc_controller then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCController" .. lane_num)
      if idx then reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_controller) end
    end
    if lane.cc_min_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMinValue" .. lane_num)
      if idx then reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_min_value) end
    end
    if lane.cc_max_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMaxValue" .. lane_num)
      if idx then reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_max_value) end
    end
    if lane.output_channel then
      local idx = get_slider_param_index_by_name(track, fx_idx, "OutputChannel" .. lane_num)
      if idx then reaper.TrackFX_SetParam(track, fx_idx, idx, lane.output_channel) end
    end
  end
end

local function ensure_jsfx_on_track(track, jsfx_name)
  local fx_idx = -1
  for i = 0, reaper.TrackFX_GetCount(track)-1 do
    local _, fxname = reaper.TrackFX_GetFXName(track, i, "")
    if fxname:find(jsfx_name, 1, true) then
      fx_idx = i
      break
    end
  end
  if fx_idx == -1 then
    fx_idx = reaper.TrackFX_AddByName(track, jsfx_name, false, 1)
    if fx_idx == -1 then error("Could not load JSFX: " .. tostring(jsfx_name)) end
  end
  return fx_idx
end

local function create_named_midi_item(track, test_idx, name)
  local start_qn = (test_idx-1) * 1.0
  local end_qn = start_qn + 0.25
  local start_time = reaper.TimeMap2_QNToTime(0, start_qn)
  local end_time = reaper.TimeMap2_QNToTime(0, end_qn)
  local item = reaper.CreateNewMIDIItemInProj(track, start_time, end_time, false)
  reaper.GetSetMediaItemInfo_String(item, "P_NAME", name, true)
  local take = reaper.GetActiveTake(item)
  if take then reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true) end
  return item, start_time, end_time, start_qn
end

-- Insert all MIDI events into the take, including note-off after note-on to avoid hanging notes.
local function insert_events_in_take(take, events, item_len_qn)
  local ppq_noteon = 0
  local ppq_noteoff = nil
  if item_len_qn then
    -- Compute note-off at end of item (use item length in quarter notes, convert to PPQ by multiplying by 960)
    local qn_length = item_len_qn
    ppq_noteoff = math.floor(qn_length * 960) -- default PPQ for REAPER is 960 per quarter
  else
    ppq_noteoff = 120 -- fallback: small duration
  end

  for _, ev in ipairs(events) do
    local is_cc = ev.is_cc == true
    local msg1 = is_cc and (ev.cc_controller or 2) or (ev.note or 60)
    -- Insert note-on or CC at start
    reaper.MIDI_InsertCC(
      take, false, false, ev.ppqpos or ppq_noteon,
      is_cc and 0xB0 or 0x90,
      ev.chan or 0, msg1, ev.msg2 or ev.vel
    )
    -- If this is a note-on, insert a note-off at the end of the item
    if not is_cc then
      -- Insert note-off (0x80) at end of item, same channel and note
      reaper.MIDI_InsertCC(
        take, false, false, ppq_noteoff,
        0x80,
        ev.chan or 0, msg1, 0
      )
    end
  end
  reaper.MIDI_Sort(take)
end

-- Analyze the output MIDI take within a specific time range (in seconds)
local function analyze_take_range(take, range_start_s, range_end_s, expected_lane)
  -- Find all note-ons in the range and their channels
  local found_channels = {}
  local got_note = false
  local notecnt = select(2, reaper.MIDI_CountEvts(take))
  for i=0, notecnt-1 do
    local _, _, _, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
    local end_time = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)
    -- Only consider note-ons that start within the range
    if (start_time >= range_start_s and start_time < range_end_s) then
      table.insert(found_channels, chan)
      got_note = true
    end
  end
  if #found_channels == 0 then
    return nil
  end
  -- For this test setup, we expect only one channel per interval
  return found_channels[1]
end

local scenarios = {
  -- Default 3-lane split (CC 0-60, 61-120, 121-127), each lane maps to a different output channel
  {
    name  = "Default 3-lane split (0-60, 61-120, 121-127)",
    jsfx_name = "ambrosebs_MIDI Drum Trainer",
    lanes = {
      { cc_controller=2, cc_min_value=0,   cc_max_value=60,   output_channel=1 },
      { cc_controller=2, cc_min_value=61,  cc_max_value=120,  output_channel=2 },
      { cc_controller=2, cc_min_value=121, cc_max_value=127,  output_channel=3 }
    },
    tests = {
      { name = "CC=40,  Note=60",  note = 60,  cc_controller = 2, cc_value =  40, expected_lane = 0 },
      { name = "CC=80,  Note=61",  note = 61,  cc_controller = 2, cc_value =  80, expected_lane = 1 },
      { name = "CC=127, Note=62",  note = 62,  cc_controller = 2, cc_value = 127, expected_lane = 2 }
    }
  },
  -- No third lane: only 0-60 and 61-120 (output channels 1 and 2)
  {
    name  = "No third lane: only 0-60 and 61-120",
    jsfx_name = "ambrosebs_MIDI Drum Trainer",
    lanes = {
      { cc_controller=2, cc_min_value=0,   cc_max_value=60,   output_channel=1 },
      { cc_controller=2, cc_min_value=61,  cc_max_value=120,  output_channel=2 }
    },
    tests = {
      { name = "CC=40,  Note=60 (should match lane 0)",  note = 60,  cc_controller = 2, cc_value =  40, expected_lane = 0 },
      { name = "CC=80,  Note=61 (should match lane 1)",  note = 61,  cc_controller = 2, cc_value =  80, expected_lane = 1 },
      { name = "CC=127, Note=62 (should match no lane)", note = 62,  cc_controller = 2, cc_value = 127, expected_lane = nil }
    }
  },
  -- Custom 4-lane split (0-31, 32-63, 64-95, 96-127), output channels 1-4
  {
    name  = "Custom 4-lane split (0-31, 32-63, 64-95, 96-127)",
    jsfx_name = "ambrosebs_MIDI Drum Trainer",
    lanes = {
      { cc_controller=2, cc_min_value=0,   cc_max_value=31,   output_channel=1 },
      { cc_controller=2, cc_min_value=32,  cc_max_value=63,   output_channel=2 },
      { cc_controller=2, cc_min_value=64,  cc_max_value=95,   output_channel=3 },
      { cc_controller=2, cc_min_value=96,  cc_max_value=127,  output_channel=4 }
    },
    tests = {
      { name = "CC=20,  Note=36",  note = 36,  cc_controller = 2, cc_value =  20, expected_lane = 0 },
      { name = "CC=40,  Note=37",  note = 37,  cc_controller = 2, cc_value =  40, expected_lane = 1 },
      { name = "CC=70,  Note=38",  note = 38,  cc_controller = 2, cc_value =  70, expected_lane = 2 },
      { name = "CC=120, Note=39",  note = 39,  cc_controller = 2, cc_value = 120, expected_lane = 3 }
    }
  }
}

local function run_tests()
  local prev_last_track_idx = reaper.CountTracks(0)-1
  local scenario_info = {}
  local max_end_qn = 0

  for sidx, scenario in ipairs(scenarios) do
    local folder_track, trainer_track, input_track =
      create_scenario_tracks(scenario.name, prev_last_track_idx)
    prev_last_track_idx = prev_last_track_idx + 3
    local fx_idx = ensure_jsfx_on_track(trainer_track, scenario.jsfx_name)
    set_lane_config(trainer_track, fx_idx, scenario.lanes)
    local ntests = #scenario.tests
    local test_starts, test_ends, test_names, test_qns = {}, {}, {}, {}
    for tidx, test in ipairs(scenario.tests) do
      local beat = tidx
      local item_name = string.format("Test %d Input: %s", tidx, test.name)
      local input_item, start_time, end_time, start_qn = create_named_midi_item(input_track, beat, item_name)
      test_starts[tidx] = start_time
      test_ends[tidx] = end_time
      test_names[tidx] = string.format("Test %d Output: %s", tidx, test.name)
      test_qns[tidx] = (beat-1) * 1.0 + 0.25
      if test_qns[tidx] > max_end_qn then max_end_qn = test_qns[tidx] end
      local take = reaper.GetActiveTake(input_item)
      if take then
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", item_name, true)
      end
      -- Insert note-on and note-off events to ensure no hanging notes when splitting
      insert_events_in_take(take, {
        { is_cc=true,  cc_controller=test.cc_controller or 2, msg2=test.cc_value, ppqpos=0, chan=0 },
        { is_cc=false, note=test.note or 60, vel=100, ppqpos=0, chan=0 }
      }, 0.25) -- item_len_qn = 0.25
    end
    scenario_info[#scenario_info+1] = {
      scenario = scenario,
      folder_track = folder_track,
      trainer_track = trainer_track,
      input_track = input_track,
      test_starts = test_starts,
      test_ends = test_ends,
      test_names = test_names,
      test_qns = test_qns,
    }
  end

  for _, info in ipairs(scenario_info) do
    reaper.SetMediaTrackInfo_Value(info.trainer_track, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(info.trainer_track, "I_RECINPUT", 4096) -- 4096 = record output (MIDI)
    reaper.SetMediaTrackInfo_Value(info.trainer_track, "I_RECMODE", 4)     -- 4 = record output (MIDI) mode
  end

  -- Place marker at start of next bar after max_end_qn
  local qn_per_bar = 4
  local marker_qn = (math.floor(max_end_qn / qn_per_bar) + 1) * qn_per_bar
  local marker_time = reaper.TimeMap2_QNToTime(0, marker_qn)
  reaper.AddProjectMarker2(0, false, marker_time, 0, "End of recording", -1, 0)
  local marker_bar = math.floor(marker_qn / qn_per_bar) + 1
  reaper.ShowConsoleMsg(string.format("DEBUG: 'End of recording' marker at time %.3f (bar %d)\n", marker_time, marker_bar))

  -- Enable metronome if not already enabled (40364 = Options: Metronome enabled)
  local metronome_enabled = reaper.GetToggleCommandState(40364)
  if metronome_enabled == 0 then
    reaper.Main_OnCommand(40364, 0)
  end

  -- Use SWS to set "promptendrec" so no dialog appears after recording stops.
  -- promptendrec: 0 = Don't prompt after recording ends (auto-save), 1 = Prompt (default)
  local prev_promptendrec = 1
  if reaper.SNM_GetIntConfigVar then
    prev_promptendrec = reaper.SNM_GetIntConfigVar("promptendrec", 1)
  end
  if reaper.SNM_SetIntConfigVar then
    local ok = reaper.SNM_SetIntConfigVar("promptendrec", 0) -- 0 = Don't prompt after recording ends
    if not ok then
      reaper.ShowConsoleMsg("WARNING: SWS could not set promptendrec=0. Dialog may still appear.\n")
    end
  end

  reaper.SetEditCurPos(0, false, false)
  reaper.Main_OnCommand(1013, 0) -- 1013 = Transport: Record

  local function marker_poll()
    local play_state = reaper.GetPlayState()
    local cur_pos = reaper.GetPlayPosition()
    if play_state & 4 ~= 0 then -- still recording
      if cur_pos >= marker_time then
        reaper.ShowConsoleMsg("DEBUG: Stopping transport using OnStopButton()\n")
        reaper.OnStopButton() -- Simulate pressing Stop on the transport (should auto-save, no dialog with promptendrec=0)
        -- Restore promptendrec as soon as possible
        local function restore_pref_and_analyze()
          if reaper.SNM_SetIntConfigVar then
            local ok = reaper.SNM_SetIntConfigVar("promptendrec", prev_promptendrec)
            if not ok then
              reaper.ShowConsoleMsg("WARNING: SWS could not restore promptendrec to previous value ("..tostring(prev_promptendrec)..").\n")
            end
          end
          if metronome_enabled == 0 then
            reaper.Main_OnCommand(40364, 0) -- 40364 = Options: Metronome enabled (turn off if originally off)
          end
          reaper.defer(analyze_outputs)
        end
        reaper.defer(restore_pref_and_analyze)
      else
        reaper.defer(marker_poll)
      end
    else
      if reaper.SNM_SetIntConfigVar then
        local ok = reaper.SNM_SetIntConfigVar("promptendrec", prev_promptendrec)
        if not ok then
          reaper.ShowConsoleMsg("WARNING: SWS could not restore promptendrec to previous value ("..tostring(prev_promptendrec)..").\n")
        end
      end
      if metronome_enabled == 0 then
        reaper.Main_OnCommand(40364, 0)
      end
      analyze_outputs()
    end
  end

  function analyze_outputs()
    for _, info in ipairs(scenario_info) do
      -- For each scenario, find the recorded output item (should be one long MIDI item)
      local output_take = nil
      for i = 0, reaper.CountTrackMediaItems(info.trainer_track)-1 do
        local it = reaper.GetTrackMediaItem(info.trainer_track, i)
        local take = reaper.GetActiveTake(it)
        if take then
          output_take = take
          break
        end
      end
      if not output_take then
        reaper.ShowConsoleMsg("No output MIDI take found for scenario: " .. info.scenario.name .. "\n")
        goto continue_to_next
      end
      -- For each test, analyze the logical interval
      for tidx, test in ipairs(info.scenario.tests) do
        local range_start_s = info.test_starts[tidx]
        local range_end_s = info.test_ends[tidx]
        local detected = analyze_take_range(output_take, range_start_s, range_end_s, test.expected_lane)
        local pass = detected == test.expected_lane
        local expected_str = test.expected_lane == nil and "no lane" or ("lane " .. tostring(test.expected_lane))
        local got_str = detected == nil and "no lane" or ("lane " .. tostring(detected))
        reaper.ShowConsoleMsg(test.name .. ": " .. (pass and "PASS" or "FAIL") ..
          " (Expected " .. expected_str .. ", got " .. got_str .. ")\n")
      end
      ::continue_to_next::
    end
    reaper.ShowConsoleMsg("All scenarios complete.\n")
  end

  marker_poll()
end

run_tests()
