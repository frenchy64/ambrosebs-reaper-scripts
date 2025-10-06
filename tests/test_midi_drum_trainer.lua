-- Data-driven JSFX Drum Trainer test script for REAPER.
-- Each scenario gets its own track group (folder track), with dedicated input/output tracks.
-- Each test is run on its own bar (half-bar duration), and all input/output MIDI items are named for inspection.
-- All tracks and items are left for post-run inspection, with no cleanup.

-- Helper: Create a scenario folder with child output/input tracks, and route input to output
local function create_scenario_tracks(scenario_name, prev_last_track_idx)
  -- Insert folder track for scenario group
  reaper.InsertTrackAtIndex(prev_last_track_idx + 1, true)
  local folder_track = reaper.GetTrack(0, prev_last_track_idx + 1)
  reaper.GetSetMediaTrackInfo_String(folder_track, "P_NAME", "Scenario: " .. scenario_name, true)
  reaper.SetMediaTrackInfo_Value(folder_track, "I_FOLDERDEPTH", 1) -- 1 = start folder

  -- Insert output (Drum Trainer) track
  reaper.InsertTrackAtIndex(prev_last_track_idx + 2, true)
  local trainer_track = reaper.GetTrack(0, prev_last_track_idx + 2)
  reaper.GetSetMediaTrackInfo_String(trainer_track, "P_NAME", "Drum Trainer: " .. scenario_name, true)
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_FOLDERDEPTH", 0) -- 0 = normal child

  -- Insert input track
  reaper.InsertTrackAtIndex(prev_last_track_idx + 3, true)
  local input_track = reaper.GetTrack(0, prev_last_track_idx + 3)
  reaper.GetSetMediaTrackInfo_String(input_track, "P_NAME", "Input: " .. scenario_name, true)
  reaper.SetMediaTrackInfo_Value(input_track, "I_FOLDERDEPTH", -1) -- -1 = last child in folder

  -- Route input to output (MIDI only)
  local send_idx = reaper.CreateTrackSend(input_track, trainer_track)
  -- I_MIDIFLAGS = 0: send all MIDI, no audio
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_MIDIFLAGS", 0)
  -- I_SRCCHAN = -1: all source MIDI channels
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_SRCCHAN", -1)
  -- I_DSTCHAN = -1: retain original MIDI channel (no remap)
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_DSTCHAN", -1)

  return folder_track, trainer_track, input_track
end

-- Helper: Looks up the internal parameter index for a JSFX slider by its name, for a given track and fx index.
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
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_controller)
      end
    end
    if lane.cc_min_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMinValue" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_min_value)
      end
    end
    if lane.cc_max_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMaxValue" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_max_value)
      end
    end
    if lane.output_channel then
      local idx = get_slider_param_index_by_name(track, fx_idx, "OutputChannel" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.output_channel)
      end
    end
  end
end

-- Helper: Insert Drum Trainer JSFX if not already present, return fx index
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

-- Helper: Create a named MIDI item at a given bar (half-bar duration)
local function create_named_midi_item(track, bar_idx, name)
  local start_qn = (bar_idx-1) * 1.0 -- start of bar N
  local end_qn = start_qn + 0.5      -- half-bar later
  local start_time = reaper.TimeMap2_QNToTime(0, start_qn)
  local end_time = reaper.TimeMap2_QNToTime(0, end_qn)
  local item = reaper.CreateNewMIDIItemInProj(track, start_time, end_time, false)
  reaper.GetSetMediaItemInfo_String(item, "P_NAME", name, true)
  return item, start_time, end_time
end

-- Helper: Insert MIDI events into a take at start (all at first tick for simplicity)
local function insert_events_in_take(take, events)
  for _, ev in ipairs(events) do
    local is_cc = ev.is_cc == true
    local msg1
    if is_cc then
      msg1 = ev.cc_controller or 2
    else
      msg1 = ev.note or 60
    end
    reaper.MIDI_InsertCC(
      take, false, false, ev.ppqpos or 0,
      is_cc and 0xB0 or 0x90, -- 0xB0 = CC, 0x90 = Note On
      ev.chan or 0, msg1, ev.msg2 or ev.vel
    )
  end
  reaper.MIDI_Sort(take)
end

-- Wait until play position reaches (or exceeds) the given time, then stop the transport and call the callback
function record_until(target_time, after_stop_callback)
  local function poll()
    local play_state = reaper.GetPlayState()
    local cur_pos = reaper.GetPlayPosition()
    if play_state & 4 ~= 0 then -- still recording
      if cur_pos >= target_time then
        -- 1017 = Transport: Stop (save all recorded media)
        reaper.Main_OnCommand(1017, 0)
        -- Wait a bit before continuing (e.g., 0.3 seconds)
        local wait_frames = 18 -- ~0.3 sec at 60fps
        local function wait()
          if wait_frames > 0 then
            wait_frames = wait_frames - 1
            reaper.defer(wait)
          else
            after_stop_callback()
          end
        end
        wait()
      else
        reaper.defer(poll)
      end
    else
      after_stop_callback()
    end
  end
  poll()
end

-- Arm, record, and get resulting output MIDI item; callback gets output item
function render_and_get_output_item_async(trainer_track, start_time, end_time, cb)
  -- Arm track for recording
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECARM", 1)
  -- I_RECINPUT=4096: record output (MIDI)
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECINPUT", 4096)
  -- I_RECMODE=4: record output (MIDI) mode
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECMODE", 4)
  -- Set time selection to match test
  reaper.GetSet_LoopTimeRange(true, false, start_time, end_time, false)
  -- Move to start of item
  reaper.SetEditCurPos(start_time, false, false)
  -- Start recording
  reaper.Main_OnCommand(1013, 0)
  record_until(end_time, function()
    -- Find the new recorded MIDI item on output track in the bar's time range
    local out_item = nil
    for i = 0, reaper.CountTrackMediaItems(trainer_track)-1 do
      local item = reaper.GetTrackMediaItem(trainer_track, i)
      local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if math.abs(pos - start_time) < 0.01 and math.abs(len - (end_time-start_time)) < 0.01 then
        out_item = item
        break
      end
    end
    cb(out_item)
  end)
end

-- Detect lane from note events
local function detect_lane_zero_based(item)
  local take = reaper.GetActiveTake(item)
  if not take then return nil end
  local notecnt = select(2, reaper.MIDI_CountEvts(take))
  for i=0, notecnt-1 do
    local _, _, _, startppq, _, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if vel > 0 then return chan end
  end
  return nil
end

local scenarios = {
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
  --[[
  {
    name  = "No third lane: only 0-60 and 61-120",
    jsfx_name = "ambrosebs_MIDI Drum Trainer",
    lanes = {
      { cc_min_value=0,  cc_max_value=60   },
      { cc_min_value=61, cc_max_value=120  }
    },
    tests = {
      { name = "CC=40,  Note=60 (should match lane 0)",  note = 60,  cc_controller = 2, cc_value =  40, expected_lane = 0 },
      { name = "CC=80,  Note=61 (should match lane 1)",  note = 61,  cc_controller = 2, cc_value =  80, expected_lane = 1 },
      { name = "CC=127, Note=62 (should match no lane)", note = 62,  cc_controller = 2, cc_value = 127, expected_lane = nil }
    }
  },
  {
    name  = "Custom 4-lane split (0-31, 32-63, 64-95, 96-127)",
    jsfx_name = "ambrosebs_MIDI Drum Trainer",
    lanes = {
      { cc_min_value=0,   cc_max_value=31   },
      { cc_min_value=32,  cc_max_value=63   },
      { cc_min_value=64,  cc_max_value=95   },
      { cc_min_value=96,  cc_max_value=127  }
    },
    tests = {
      { name = "CC=20,  Note=36",  note = 36,  cc_controller = 2, cc_value =  20, expected_lane = 0 },
      { name = "CC=40,  Note=37",  note = 37,  cc_controller = 2, cc_value =  40, expected_lane = 1 },
      { name = "CC=70,  Note=38",  note = 38,  cc_controller = 2, cc_value =  70, expected_lane = 2 },
      { name = "CC=120, Note=39",  note = 39,  cc_controller = 2, cc_value = 120, expected_lane = 3 }
    }
  }
  ]]
}

-- Async test runner, preserving all tracks and items for inspection
local function run_tests()
  local scenario_idx = 1
  local bar_offset = 1 -- each scenario starts at bar 1
  local prev_last_track_idx = reaper.CountTracks(0)-1
  local run_scenario, run_test

  run_scenario = function()
    local scenario = scenarios[scenario_idx]
    if not scenario then
      reaper.ShowConsoleMsg("All scenarios complete.\n")
      return
    end
    -- Create new track group for scenario
    local folder_track, trainer_track, input_track =
      create_scenario_tracks(scenario.name, prev_last_track_idx)
    prev_last_track_idx = prev_last_track_idx + 3 -- update for next scenario
    -- Insert Drum Trainer JSFX and configure
    local fx_idx = ensure_jsfx_on_track(trainer_track, scenario.jsfx_name)
    set_lane_config(trainer_track, fx_idx, scenario.lanes)
    -- Start with bar 1 for first test in this scenario
    local test_idx = 1
    local num_tests = #scenario.tests

    run_test = function()
      if test_idx > num_tests then
        -- After all tests, disarm & mute scenario tracks
        reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECARM", 0)
        reaper.SetMediaTrackInfo_Value(input_track,   "I_RECARM", 0)
        reaper.SetMediaTrackInfo_Value(trainer_track, "B_MUTE", 1)
        reaper.SetMediaTrackInfo_Value(input_track,   "B_MUTE", 1)
        reaper.SetEditCurPos(0, false, false) -- reset play cursor for next scenario
        scenario_idx = scenario_idx + 1
        bar_offset = 1
        reaper.defer(run_scenario)
        return
      end
      local test = scenario.tests[test_idx]
      local bar = bar_offset + test_idx - 1
      -- Create input MIDI item for this test
      local item_name = string.format("Test %d Input: %s", test_idx, test.name)
      local input_item, start_time, end_time = create_named_midi_item(input_track, bar, item_name)
      local take = reaper.GetActiveTake(input_item)
      -- Insert test events (at PPQ 0 or as needed)
      insert_events_in_take(take, {
        { is_cc=true,  cc_controller=test.cc_controller or 2, msg2=test.cc_value, ppqpos=0, chan=0 },
        { is_cc=false, note=test.note or 60, vel=100, ppqpos=0, chan=0 }
      })
      -- Move play cursor to start of test
      reaper.SetEditCurPos(start_time, false, false)

      -- Record and analyze output
      render_and_get_output_item_async(trainer_track, start_time, end_time, function(output_item)
        -- Name output MIDI item for this test
        if output_item then
          reaper.GetSetMediaItemInfo_String(output_item, "P_NAME",
            string.format("Test %d Output: %s", test_idx, test.name), true)
        end
        -- Analyze
        local detected = output_item and detect_lane_zero_based(output_item)
        local pass = detected == test.expected_lane
        local expected_str = test.expected_lane == nil and "no lane" or ("lane " .. tostring(test.expected_lane))
        local got_str = detected == nil and "no lane" or ("lane " .. tostring(detected))
        reaper.ShowConsoleMsg(test.name .. ": " .. (pass and "PASS" or "FAIL") ..
          " (Expected " .. expected_str .. ", got " .. got_str .. ")\n")
        test_idx = test_idx + 1
        reaper.defer(run_test)
      end)
    end

    run_test()
  end

  run_scenario()
end

run_tests()
