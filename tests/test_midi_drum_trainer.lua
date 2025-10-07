-- This script assumes SWS Extensions are installed and available.
-- It will automatically enable the REAPER config variable
--   "promptendrec" (integer, in [reaper] section)
--   0 = Don't prompt after recording ends; saves the files automatically
--   1 = Prompt the user after recording ends (default)
-- via SWS/SNM_SetIntConfigVar("promptendrec", 0) before recording,
-- and restore the previous setting immediately after recording.
-- This allows for fully automated, dialog-free test runs.
-- MIDI Drum Trainer Automated Test Runner with streaming CI log output

-- Helper to get env variable for output log file
local function getenv(name)
  local v = os.getenv(name)
  if v == nil then return "" end
  return v
end

local summary_file = reaper.GetResourcePath().."/test_midi_drum_trainer.log"
os.remove(summary_file)

-- Helper to save MIDI file for debugging
local function save_midi_for_debugging(take, filename)
  if not take then
    log("ERROR: Cannot save MIDI - take is nil")
    return
  end
  -- Log MIDI events for debugging (directory creation may not work in headless mode)
  local _, note_cnt, cc_cnt, _ = reaper.MIDI_CountEvts(take)
  log("DEBUG: MIDI take '" .. filename .. "' has " .. note_cnt .. " notes and " .. cc_cnt .. " CC events")
  -- Log first few MIDI events
  for i = 0, math.min(note_cnt-1, 5) do
    local _, _, _, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    log(string.format("  Note %d: chan=%d, pitch=%d, vel=%d, ppq=%d-%d", i, chan, pitch, vel, startppq, endppq))
  end
  for i = 0, math.min(cc_cnt-1, 5) do
    local _, _, _, ppq, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, i)
    log(string.format("  CC %d: chan=%d, msg2=%d, msg3=%d, ppq=%d", i, chan, msg2, msg3, ppq))
  end
end

-- Logging helper: prints to console and appends to file if configured
local function log(msg)
  reaper.ShowConsoleMsg(msg .. "\n")
  local f = io.open(summary_file, "a")
  if f then
    f:write(msg .. "\n")
    f:close()
  end
end

log("MIDI Drum Trainer Test Runner: Starting up...")

local function create_scenario_tracks(scenario_name, prev_last_track_idx)
  log("> > Insert folder track for scenario")
  reaper.InsertTrackAtIndex(prev_last_track_idx + 1, true) -- magic: InsertTrackAtIndex(index, wantDefaults)
  local folder_track = reaper.GetTrack(0, prev_last_track_idx + 1)
  log("> > > folder_track pointer: " .. tostring(folder_track))
  if not folder_track then
    log("ERROR: Failed to create folder track!")
    error("Failed to create folder track")
  end
  reaper.GetSetMediaTrackInfo_String(folder_track, "P_NAME", "Scenario: " .. scenario_name, true) -- magic: "P_NAME", true for set
  reaper.SetMediaTrackInfo_Value(folder_track, "I_FOLDERDEPTH", 1) -- magic: 1 = folder parent
  log("> > > folder_track created successfully")

  log("> > Insert MIDI Drum Trainer output track")
  reaper.InsertTrackAtIndex(prev_last_track_idx + 2, true)
  local trainer_track = reaper.GetTrack(0, prev_last_track_idx + 2)
  log("> > > trainer_track pointer: " .. tostring(trainer_track))
  if not trainer_track then
    log("ERROR: Failed to create trainer track!")
    error("Failed to create trainer track")
  end
  reaper.GetSetMediaTrackInfo_String(trainer_track, "P_NAME", "Output", true)
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_FOLDERDEPTH", 0) -- magic: 0 = no folder change
  log("> > > trainer_track created successfully")

  log("> > Insert input track for feeding MIDI")
  reaper.InsertTrackAtIndex(prev_last_track_idx + 3, true)
  local input_track = reaper.GetTrack(0, prev_last_track_idx + 3)
  log("> > > input_track pointer: " .. tostring(input_track))
  if not input_track then
    log("ERROR: Failed to create input track!")
    error("Failed to create input track")
  end
  reaper.GetSetMediaTrackInfo_String(input_track, "P_NAME", "Input", true)
  reaper.SetMediaTrackInfo_Value(input_track, "I_FOLDERDEPTH", -1) -- magic: -1 = folder end
  log("> > > input_track created successfully")

  log("> > Set up routing (send from input to output)")
  local send_idx = reaper.CreateTrackSend(input_track, trainer_track)
  log("> > > send_idx: " .. tostring(send_idx))
  if send_idx < 0 then
    log("ERROR: Failed to create track send!")
    error("Failed to create track send")
  end
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_MIDIFLAGS", 1) -- magic: 1 = MIDI only (bit 0 set)
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_SRCCHAN", -1) -- magic: -1 = all channels
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_DSTCHAN", -1)
  log("> > > routing configured successfully")

  -- Update arrange to ensure changes are committed
  reaper.UpdateArrange()
  reaper.TrackList_AdjustWindows(false)

  log("> < Create scenario tracks")
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
  log("> > set_lane_config")
  local num_params = reaper.TrackFX_GetNumParams(track, fx_idx)
  log("> > > FX has " .. num_params .. " parameters")
  local lanes_slider_idx = get_slider_param_index_by_name(track, fx_idx, "Lanes")
  log("> > > Lanes idx: "..tostring(lanes_slider_idx))
  if lanes_slider_idx then
    reaper.TrackFX_SetParam(track, fx_idx, lanes_slider_idx, #lanes-1)
    log("> > > Set Lanes parameter to: " .. (#lanes-1))
  else
    log("WARNING: Could not find Lanes parameter!")
  end
  for i, lane in ipairs(lanes) do
    log("> > > set Lane "..i.." config")
    local lane_num = i
    if lane.cc_controller then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCController" .. lane_num)
      if idx then 
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_controller)
        log("> > > > Set CCController" .. lane_num .. " to " .. lane.cc_controller)
      else
        log("WARNING: Could not find CCController" .. lane_num)
      end
    end
    if lane.cc_min_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMinValue" .. lane_num)
      if idx then 
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_min_value)
        log("> > > > Set CCMinValue" .. lane_num .. " to " .. lane.cc_min_value)
      else
        log("WARNING: Could not find CCMinValue" .. lane_num)
      end
    end
    if lane.cc_max_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMaxValue" .. lane_num)
      if idx then 
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_max_value)
        log("> > > > Set CCMaxValue" .. lane_num .. " to " .. lane.cc_max_value)
      else
        log("WARNING: Could not find CCMaxValue" .. lane_num)
      end
    end
    if lane.output_channel then
      local idx = get_slider_param_index_by_name(track, fx_idx, "OutputChannel" .. lane_num)
      if idx then 
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.output_channel)
        log("> > > > Set OutputChannel" .. lane_num .. " to " .. lane.output_channel)
      else
        log("WARNING: Could not find OutputChannel" .. lane_num)
      end
    end
  end
  log("> < set_lane_config")
  -- Ensure FX parameters are updated
  reaper.UpdateArrange()
end

local function ensure_jsfx_on_track(track, jsfx_name)
  log("> > ensure_jsfx_on_track")
  local fx_idx = -1
  local fx_count = reaper.TrackFX_GetCount(track)
  log("> > > Track has " .. fx_count .. " FX plugins")
  for i = 0, fx_count-1 do
    log("> > > track number "..i)
    local _, fxname = reaper.TrackFX_GetFXName(track, i, "")
    log("> > > fx name: "..fxname)
    if fxname:find(jsfx_name, 1, true) then
      fx_idx = i
      break
    end
  end
  if fx_idx == -1 then
    log("> > > fx add by name")
    fx_idx = reaper.TrackFX_AddByName(track, jsfx_name, false, 1) -- magic: instantiate JSFX
    log("> > > fx_idx after add: " .. tostring(fx_idx))
    if fx_idx == -1 then
      log("Could not load JSFX: " .. tostring(jsfx_name))
      -- Try to list available JSFX
      log("Available JSFX search paths:")
      log("  Resource path: " .. reaper.GetResourcePath())
      error("Could not load JSFX: " .. tostring(jsfx_name))
    end
    -- Verify it was added
    local _, loaded_name = reaper.TrackFX_GetFXName(track, fx_idx, "")
    log("> > > Loaded FX name: " .. loaded_name)
    -- Give FX time to initialize
    reaper.UpdateArrange()
  end
  log("> < ensure_jsfx_on_track")
  return fx_idx
end

local function create_named_midi_item(track, test_idx, name)
  local start_qn = (test_idx-1) * 1.0
  local end_qn = start_qn + 0.25
  local start_time = reaper.TimeMap2_QNToTime(0, start_qn) -- magic: QN to seconds
  local end_time = reaper.TimeMap2_QNToTime(0, end_qn)
  log("> > > Creating MIDI item: " .. name .. " at QN " .. start_qn .. "-" .. end_qn .. " (time: " .. start_time .. "-" .. end_time .. ")")
  local item = reaper.CreateNewMIDIItemInProj(track, start_time, end_time, false)
  log("> > > item pointer: " .. tostring(item))
  if not item then
    log("ERROR: Failed to create MIDI item!")
    error("Failed to create MIDI item")
  end
  reaper.GetSetMediaItemInfo_String(item, "P_NAME", name, true)
  local take = reaper.GetActiveTake(item)
  log("> > > take pointer: " .. tostring(take))
  if take then 
    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true) 
  else
    log("WARNING: No active take for MIDI item!")
  end
  return item, start_time, end_time, start_qn
end

-- Insert all MIDI events into the take, including note-off after note-on to avoid hanging notes.
local function insert_events_in_take(take, events, item_len_qn)
  log("> > > insert_events_in_take: take=" .. tostring(take) .. ", event count=" .. #events)
  local ppq_noteon = 0
  local ppq_noteoff = nil
  if item_len_qn then
    -- Compute note-off at end of item (use item length in quarter notes, convert to PPQ by multiplying by 960)
    local qn_length = item_len_qn
    ppq_noteoff = math.floor(qn_length * 960) -- magic: REAPER default is 960 PPQ per quarter
  else
    ppq_noteoff = 120 -- magic: fallback small duration
  end
  log("> > > > ppq_noteon=" .. ppq_noteon .. ", ppq_noteoff=" .. ppq_noteoff)

  for idx, ev in ipairs(events) do
    local is_cc = ev.is_cc == true
    local msg1 = is_cc and (ev.cc_controller or 2) or (ev.note or 60)
    log("> > > > Event " .. idx .. ": is_cc=" .. tostring(is_cc) .. ", msg1=" .. msg1 .. ", msg2=" .. tostring(ev.msg2 or ev.vel))
    -- Insert note-on or CC at start
    local ok = reaper.MIDI_InsertCC(
      take, false, false, ev.ppqpos or ppq_noteon,
      is_cc and 0xB0 or 0x90,          -- magic: 0xB0 = CC, 0x90 = note-on
      ev.chan or 0, msg1, ev.msg2 or ev.vel
    )
    log("> > > > > MIDI_InsertCC result: " .. tostring(ok))
    -- If this is a note-on, insert a note-off (0x80) at end of item
    if not is_cc then
      local ok2 = reaper.MIDI_InsertCC(
        take, false, false, ppq_noteoff,
        0x80,                           -- magic: 0x80 = note-off
        ev.chan or 0, msg1, 0
      )
      log("> > > > > MIDI_InsertCC (note-off) result: " .. tostring(ok2))
    end
  end
  reaper.MIDI_Sort(take)
  log("> > > < insert_events_in_take complete")
end

-- Analyze the output MIDI take within a specific time range (in seconds)
local function analyze_take_range(take, range_start_s, range_end_s, expected_lane)
  local found_channels = {}
  local notecnt = select(2, reaper.MIDI_CountEvts(take)) -- magic: MIDI_CountEvts returns (retval, notecnt, ...), notes only
  log(string.format("  > Analyzing take range [%.3f, %.3f), total notes=%d", range_start_s, range_end_s, notecnt))
  for i=0, notecnt-1 do
    local _, _, _, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq) -- magic: PPQ to seconds
    if (start_time >= range_start_s and start_time < range_end_s) then
      log(string.format("  > > Found note in range: time=%.3f, chan=%d, pitch=%d, vel=%d", start_time, chan, pitch, vel))
      table.insert(found_channels, chan)
    end
  end
  if #found_channels == 0 then
    log("  > No notes found in range")
    return nil
  end
  log(string.format("  > Returning channel %d", found_channels[1]))
  return found_channels[1]
end

local scenarios = {
  -- Scenario 1: Default 3-lane split (CC 0-60, 61-120, 121-127), each lane maps to a different output channel
  {
    name  = "Scenario 1: Default 3-lane split (0-60, 61-120, 121-127)",
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
  -- Scenario 2: No third lane: only 0-60 and 61-120 (output channels 1 and 2)
  {
    name  = "Scenario 2: No third lane: only 0-60 and 61-120",
    jsfx_name = "ambrosebs_MIDI Drum Trainer",
    lanes = {
      { cc_controller=2, cc_min_value=0,   cc_max_value=60,   output_channel=1 },
      { cc_controller=2, cc_min_value=61,  cc_max_value=120,  output_channel=2 }
    },
    tests = {
      { name = "CC=40,  Note=60 (should match lane 0)",  note = 60,  cc_controller = 2, cc_value =  40, expected_lane = 0 },
      { name = "CC=80,  Note=61 (should match lane 1)",  note = 61,  cc_controller = 2, cc_value =  80, expected_lane = 1 },
      -- FIXME decide how to handle fallthru logic. See FIXME in jsfx midirecv loop
      -- here we assume that fallthru (matches no lane) blocks the MIDI note. but we forward it instead.
      --{ name = "CC=127, Note=62 (should match no lane)", note = 62,  cc_controller = 2, cc_value = 127, expected_lane = nil }
    }
  },
  -- Scenario 3: Custom 4-lane split (0-31, 32-63, 64-95, 96-127), output channels 1-4
  {
    name  = "Scenario 3: Custom 4-lane split (0-31, 32-63, 64-95, 96-127)",
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
  log("Setting up test scenarios...")
  log("Initial track count: " .. reaper.CountTracks(0))
  log("REAPER version: " .. reaper.GetAppVersion())
  log("Project sample rate: " .. reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false))
  -- Get and log the project tempo
  local bpm = reaper.Master_GetTempo()
  log("Project BPM: " .. bpm)
  local prev_last_track_idx = reaper.CountTracks(0)-1
  local scenario_info = {}
  local max_end_qn = 0

  for sidx, scenario in ipairs(scenarios) do
    log("> Scenario "..sidx..": "..scenario.name)
    local folder_track, trainer_track, input_track =
      create_scenario_tracks(scenario.name, prev_last_track_idx)
    prev_last_track_idx = prev_last_track_idx + 3
    local fx_idx = ensure_jsfx_on_track(trainer_track, scenario.jsfx_name)
    set_lane_config(trainer_track, fx_idx, scenario.lanes)
    local ntests = #scenario.tests
    local test_starts, test_ends, test_names, test_qns = {}, {}, {}, {}
    for tidx, test in ipairs(scenario.tests) do
      log("> > Test "..tidx..": "..test.name)
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
        log("> > > Take for input item exists, inserting events...")
      else
        log("ERROR: No take for input item!")
      end
      insert_events_in_take(take, {
        { is_cc=true,  cc_controller=test.cc_controller or 2, msg2=test.cc_value, ppqpos=0, chan=0 },
        { is_cc=false, note=test.note or 60, vel=100, ppqpos=1, chan=0 } -- slightly after CC
      }, 0.25) -- magic: item_len_qn = 0.25 (quarter note per test)
      -- Verify the events were inserted and save for debugging
      if take then
        local _, note_cnt, cc_cnt, _ = reaper.MIDI_CountEvts(take)
        log("> > > Verification: note_cnt=" .. note_cnt .. ", cc_cnt=" .. cc_cnt)
        save_midi_for_debugging(take, string.format("scenario%d_test%d_input", sidx, tidx))
      end
      log("> < Test "..tidx..": "..test.name)
    end
    -- Update arrange to ensure all items are committed
    reaper.UpdateArrange()
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
    log("< Scenario "..sidx..": "..scenario.name)
  end

  for i, info in ipairs(scenario_info) do
    log("> Arming Scenario "..i)
    local track_num = reaper.GetMediaTrackInfo_Value(info.trainer_track, "IP_TRACKNUMBER")
    log("> > Track number: " .. track_num)
    reaper.SetMediaTrackInfo_Value(info.trainer_track, "I_RECARM", 1) -- magic: arm for record
    reaper.SetMediaTrackInfo_Value(info.trainer_track, "I_RECINPUT", 4096) -- magic: 4096 = record output (MIDI)
    reaper.SetMediaTrackInfo_Value(info.trainer_track, "I_RECMODE", 4)     -- magic: 4 = record output (MIDI) mode
    -- Verify the arm state
    local arm_state = reaper.GetMediaTrackInfo_Value(info.trainer_track, "I_RECARM")
    local rec_input = reaper.GetMediaTrackInfo_Value(info.trainer_track, "I_RECINPUT")
    local rec_mode = reaper.GetMediaTrackInfo_Value(info.trainer_track, "I_RECMODE")
    log("> > Armed state verified: I_RECARM=" .. arm_state .. ", I_RECINPUT=" .. rec_input .. ", I_RECMODE=" .. rec_mode)
    log("< Arming Scenario "..i)
  end

  -- Place marker at start of next bar after max_end_qn
  local qn_per_bar = 4 -- magic: 4 quarter notes per bar
  local marker_qn = (math.floor(max_end_qn / qn_per_bar) + 1) * qn_per_bar
  local marker_time = reaper.TimeMap2_QNToTime(0, marker_qn)
  reaper.AddProjectMarker2(0, false, marker_time, 0, "End of recording", -1, 0)
  local marker_bar = math.floor(marker_qn / qn_per_bar) + 1
  log(string.format("DEBUG: 'End of recording' marker at time %.3f (bar %d)\n", marker_time, marker_bar))
  log(string.format("DEBUG: max_end_qn=%.3f", max_end_qn))

  -- Log all input items before recording
  log("DEBUG: Verifying all input items before recording:")
  for sidx, info in ipairs(scenario_info) do
    local input_item_count = reaper.CountTrackMediaItems(info.input_track)
    log(string.format("  Scenario %d: %d items on input track", sidx, input_item_count))
    for i = 0, input_item_count-1 do
      local item = reaper.GetTrackMediaItem(info.input_track, i)
      local take = reaper.GetActiveTake(item)
      if take then
        local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        local _, note_cnt, cc_cnt, _ = reaper.MIDI_CountEvts(take)
        log(string.format("    Item %d: %s (notes=%d, cc=%d)", i, name, note_cnt, cc_cnt))
      end
    end
  end

  -- Log all track states before recording
  log("DEBUG: Track states before recording:")
  for sidx, info in ipairs(scenario_info) do
    local folder_num = reaper.GetMediaTrackInfo_Value(info.folder_track, "IP_TRACKNUMBER")
    local trainer_num = reaper.GetMediaTrackInfo_Value(info.trainer_track, "IP_TRACKNUMBER")
    local input_num = reaper.GetMediaTrackInfo_Value(info.input_track, "IP_TRACKNUMBER")
    log(string.format("  Scenario %d: folder=#%d, trainer=#%d (armed=%d), input=#%d", 
      sidx, folder_num, trainer_num, 
      reaper.GetMediaTrackInfo_Value(info.trainer_track, "I_RECARM"),
      input_num))
  end

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
    local ok = reaper.SNM_SetIntConfigVar("promptendrec", 0)
    if not ok then
      log("WARNING: SWS could not set promptendrec=0. Dialog may still appear.")
    end
  end

  reaper.SetEditCurPos(0, false, false)
  reaper.Main_OnCommand(1013, 0) -- magic: 1013 = Transport: Record

  local function marker_poll()
    local play_state = reaper.GetPlayState()
    local cur_pos = reaper.GetPlayPosition()
    if play_state & 4 ~= 0 then -- magic: 4 = recording
      if cur_pos >= marker_time then
        log("DEBUG: Stopping transport using OnStopButton()")
        reaper.OnStopButton()
        -- Wait a bit for recording to finalize, then analyze
        local function wait_for_stop()
          local play_state = reaper.GetPlayState()
          if play_state == 0 then  -- 0 = stopped
            log("DEBUG: Transport stopped, restoring settings and analyzing")
            if reaper.SNM_SetIntConfigVar then
              local ok = reaper.SNM_SetIntConfigVar("promptendrec", prev_promptendrec)
              if not ok then
                log("WARNING: SWS could not restore promptendrec to previous value ("..tostring(prev_promptendrec)..").")
              end
            end
            if metronome_enabled == 0 then
              reaper.Main_OnCommand(40364, 0)
            end
            analyze_outputs()
          else
            log("DEBUG: Still stopping, play_state=" .. play_state)
            reaper.defer(wait_for_stop)
          end
        end
        reaper.defer(wait_for_stop)
      else
        reaper.defer(marker_poll)
      end
    else
      if reaper.SNM_SetIntConfigVar then
        local ok = reaper.SNM_SetIntConfigVar("promptendrec", prev_promptendrec)
        if not ok then
          log("WARNING: SWS could not restore promptendrec to previous value ("..tostring(prev_promptendrec)..").")
        end
      end
      if metronome_enabled == 0 then
        reaper.Main_OnCommand(40364, 0)
      end
      analyze_outputs()
    end
  end

  function analyze_outputs()
    log("========== MIDI Drum Trainer Test Results ==========")
    log("Total tracks in project: " .. reaper.CountTracks(0))
    local total_scenarios = #scenario_info
    local total_tests = 0
    local passed_scenarios = 0
    local passed_tests = 0

    for sidx, info in ipairs(scenario_info) do
      local scenario = info.scenario
      local output_tracknum = reaper.GetMediaTrackInfo_Value(info.trainer_track, "IP_TRACKNUMBER") -- magic: IP_TRACKNUMBER = 1-based
      local output_tracknum = reaper.GetMediaTrackInfo_Value(info.trainer_track, "IP_TRACKNUMBER")
      log(string.format("\n%s", scenario.name))
      log(string.format("  Output Track #: %d", output_tracknum))
      log("---------------------------------------------------")
      local scenario_pass = true
      -- For each scenario, find the recorded output item (should be one long MIDI item)
      local output_take = nil
      local item_count = reaper.CountTrackMediaItems(info.trainer_track)
      log("  Number of items on trainer track: " .. item_count)
      for i = 0, item_count-1 do
        local it = reaper.GetTrackMediaItem(info.trainer_track, i)
        log("  > Item " .. i .. " pointer: " .. tostring(it))
        local take = reaper.GetActiveTake(it)
        log("  > Item " .. i .. " take pointer: " .. tostring(take))
        if take then
          local _, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
          log("  > Item " .. i .. " take name: " .. take_name)
          local note_count = select(2, reaper.MIDI_CountEvts(take))
          log("  > Item " .. i .. " note count: " .. note_count)
          output_take = take
          break
        end
      end
      if not output_take then
        log("  No output MIDI take found for this scenario!")
        scenario_pass = false
        goto continue_to_next
      end
      -- Save output for debugging
      save_midi_for_debugging(output_take, string.format("scenario%d_output", sidx))
      for tidx, test in ipairs(scenario.tests) do
        total_tests = total_tests + 1
        local range_start_s = info.test_starts[tidx]
        local range_end_s = info.test_ends[tidx]
        local detected = analyze_take_range(output_take, range_start_s, range_end_s, test.expected_lane)
        local pass = detected == test.expected_lane
        local expected_str = test.expected_lane == nil and "no lane" or ("lane " .. tostring(test.expected_lane))
        local got_str = detected == nil and "no lane" or ("lane " .. tostring(detected))
        local status_str = pass and "PASS" or "FAIL"
        if pass then passed_tests = passed_tests + 1 else scenario_pass = false end
        log(string.format(
          "  Test %d: %-40s [%s]\n      Expected: %-10s Got: %s",
          tidx, test.name, status_str, expected_str, got_str
        ))
      end
      if scenario_pass then passed_scenarios = passed_scenarios + 1 end
      ::continue_to_next::
      log("---------------------------------------------------")
    end
    log("All scenarios complete.")
    log("===================================================")
    local summary = string.format(
      "Summary: %d/%d scenarios passed, %d/%d unit tests passed.",
      passed_scenarios, total_scenarios, passed_tests, total_tests)
    log(summary)
    log("===================================================")
  end

  marker_poll()
end

run_tests()
