-- Data-driven JSFX Drum Trainer test script for REAPER, async CPS conversion.

-- Helper: Insert and configure JSFX, returning track and fx index
local function setup_jsfx_on_new_track(jsfx_name)
  reaper.Main_OnCommand(40001, 0)
  local track = reaper.GetTrack(0, reaper.CountTracks(0)-1)
  local fx_idx = reaper.TrackFX_AddByName(track, jsfx_name, false, 1)
  if fx_idx == -1 then error("Could not load JSFX: " .. tostring(jsfx_name)) end
  return track, fx_idx
end

-- Looks up the internal parameter index for a JSFX slider by its name, for a given track and fx index.
-- Returns the parameter index (0-based) if found, or nil otherwise.
function get_slider_param_index_by_name(track, fx_idx, slider_name)
  local num_params = reaper.TrackFX_GetNumParams(track, fx_idx)
  for i = 0, num_params - 1 do
    local _, name = reaper.TrackFX_GetParamName(track, fx_idx, i, "")
    -- Remove whitespace for robust matching
    if name:gsub("%s+", "") == slider_name:gsub("%s+", "") then
      return i
    end
  end
  return nil
end

local function set_lane_config(track, fx_idx, lanes)
  -- update number of lanes slider
  local lanes_slider_idx = get_slider_param_index_by_name(track, fx_idx, "Lanes")
  if lanes_slider_idx then
    reaper.TrackFX_SetParam(track, fx_idx, lanes_slider_idx, #lanes-1)
  else
    reaper.ShowConsoleMsg("WARNING: Could not find 'Lanes' slider in JSFX.\n")
  end

  for i, lane in ipairs(lanes) do
    local lane_num = i
    -- Set CC Controller
    if lane.cc_controller then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCController" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_controller)
      end
    end
    -- Set CC Min Value
    if lane.cc_min_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMinValue" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_min_value)
      end
    end
    -- Set CC Max Value
    if lane.cc_max_value then
      local idx = get_slider_param_index_by_name(track, fx_idx, "CCMaxValue" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.cc_max_value)
      end
    end
    -- Set Output Channel (already handled in your script, but kept here for completeness)
    if lane.output_channel then
      local idx = get_slider_param_index_by_name(track, fx_idx, "OutputChannel" .. lane_num)
      if idx then
        reaper.TrackFX_SetParam(track, fx_idx, idx, lane.output_channel)
      end
    end
  end
end

-- Helper: Create a new track for input and route its MIDI to the trainer track
local function setup_input_routing(trainer_track)
  reaper.Main_OnCommand(40001, 0) -- Insert new track
  local input_track = reaper.GetTrack(0, reaper.CountTracks(0)-1)
  -- Route all MIDI from input_track to trainer_track
  local send_idx = reaper.CreateTrackSend(input_track, trainer_track)
  -- Set send to MIDI only (disable audio)
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_MIDIFLAGS", 0)
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_SRCCHAN", -1) -- All MIDI
  reaper.SetTrackSendInfo_Value(input_track, 0, send_idx, "I_DSTCHAN", -1) -- All MIDI
  return input_track
end

-- Helper: Create test MIDI take with specified events on a given track
local function create_test_take_on_track(track, events)
  local item = reaper.CreateNewMIDIItemInProj(track, 0, 2.0, false)
  local take = reaper.GetActiveTake(item)
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
      is_cc and 0xB0 or 0x90,
      ev.chan or 0, msg1, ev.msg2 or ev.vel
    )
  end
  reaper.MIDI_Sort(take)
  return item, take
end

-- Wait until play position reaches (or exceeds) the given time, then stop the transport and call the callback
function record_until(target_time, after_stop_callback)
  local function poll()
    local play_state = reaper.GetPlayState()
    local cur_pos = reaper.GetPlayPosition()
    if play_state & 4 ~= 0 then -- still recording
      if cur_pos >= target_time then
        -- Use action 1017: Transport: Stop (save all recorded media)
        reaper.Main_OnCommand(1017, 0)
        -- Wait a bit before continuing (e.g., 0.3 seconds)
        local wait_frames = 18 -- ~0.3 seconds at 60fps
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
      -- Not recording, just call callback right away
      after_stop_callback()
    end
  end
  poll()
end

-- Render Drum Trainer output to new MIDI item and get resulting NOTE events (Note On/Off only), async CPS
function render_and_get_output_note_events_async(trainer_track, record_time, cb)
  -- Arm the track for recording
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECARM", 1)
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECINPUT", 4096)
  reaper.SetMediaTrackInfo_Value(trainer_track, "I_RECMODE", 4)
  reaper.Main_OnCommand(1013, 0) -- Start recording
  record_until(record_time, function()
    -- Get the most recent recorded item (output from FX chain)
    local item = reaper.GetTrackMediaItem(trainer_track, reaper.CountTrackMediaItems(trainer_track)-1)
    local take = item and reaper.GetActiveTake(item)
    local events = {}
    if take then
      local notecnt = select(2, reaper.MIDI_CountEvts(take))
      for i=0, notecnt-1 do
        local _, _, _, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        table.insert(events, {
          type = "note_on",
          ppqpos = startppq,
          chanmsg = 0x90,
          chan = chan,
          msg1 = pitch,
          msg2 = vel,
        })
      end
    end
    cb(events)
  end)
end

local function cleanup()
  reaper.Main_OnCommand(40005, 0)
end

local function detect_lane_zero_based(events, scenario)
  local lane_detect = scenario.lane_detect or function(events)
    for _, ev in ipairs(events) do
      if (ev.chanmsg & 0xF0) == 0x90 and ev.msg2 > 0 then
        return ev.chan
      end
    end
    return nil
  end
  return lane_detect(events)
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

-- Async test runner CPS style
local total_scenarios = #scenarios
local scenarios_passed = 0
local scenarios_failed = 0
local total_tests = 0
local tests_passed = 0
local tests_failed = 0

local function run_test_scenarios(scenarios, scenario_idx, test_idx)
  scenario_idx = scenario_idx or 1
  test_idx = test_idx or 1
  if scenario_idx > #scenarios then
    -- All done!
    reaper.ShowConsoleMsg(
      string.format(
        "Test results: %d/%d scenarios passed, %d/%d tests passed.\n",
        scenarios_passed, total_scenarios, tests_passed, total_tests
      )
    )
    return
  end
  local scenario = scenarios[scenario_idx]
  if test_idx == 1 then
    reaper.ShowConsoleMsg("==== Running Scenario: " .. scenario.name .. " ====\n")
  end
  local test = scenario.tests[test_idx]
  if not test then
    -- Finished this scenario, go to next
    if scenario.all_pass then scenarios_passed = scenarios_passed + 1 else scenarios_failed = scenarios_failed + 1 end
    reaper.ShowConsoleMsg("==== End Scenario: " .. scenario.name .. " ====\n\n")
    run_test_scenarios(scenarios, scenario_idx + 1, 1)
    return
  end

  cleanup()
  -- 1. Setup Drum Trainer track with JSFX
  local trainer_track, fx_idx = setup_jsfx_on_new_track(scenario.jsfx_name or "ambrosebs_MIDI Drum Trainer")
  set_lane_config(trainer_track, fx_idx, scenario.lanes)

  -- 2. Setup input track and routing
  local input_track = setup_input_routing(trainer_track)

  -- 3. Insert test MIDI item on input track
  -- Insert MIDI on the grid: for 8 divisions, each division is 1/8 of 2.0 (since MIDI item is 2.0 quarter notes long)
  local divisions = 8
  local grid_len = 2.0 / divisions
  local grid_ppq = 480 -- default REAPER PPQ per quarter note
  local cc_ppqpos = 0
  local note_ppqpos = 1 * grid_ppq * grid_len -- second division (can adjust as needed)
  local events = {
    { is_cc=true,  cc_controller=test.cc_controller or 2, msg2=test.cc_value, ppqpos=cc_ppqpos, chan=0 },
    { is_cc=false, note=test.note or 60, vel=100, ppqpos=note_ppqpos, chan=0 }
  }
  local item, take = create_test_take_on_track(input_track, events)

  -- 4. Arm trainer track, record, and wait until end of input item (2.0 quarter notes)
  local record_time = 2.1 -- slightly after end of MIDI item to ensure capture

  render_and_get_output_note_events_async(trainer_track, record_time, function(output_events)
    -- Move play cursor to start of item for completeness
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    reaper.SetEditCurPos(pos, false, false)

    -- Print all NOTE events for debugging
    for i, ev in ipairs(output_events) do
      reaper.ShowConsoleMsg(string.format(
        "EVENT %d: chanmsg=0x%X chan=%d msg1=%d msg2=%d\n",
        i, ev.chanmsg, ev.chan, ev.msg1, ev.msg2))
    end

    local expected_lane = test.expected_lane
    local detected = detect_lane_zero_based(output_events, scenario)
    local pass = detected == expected_lane
    scenario.all_pass = (scenario.all_pass == nil) and pass or (scenario.all_pass and pass)
    if pass then
      tests_passed = tests_passed + 1
    else
      tests_failed = tests_failed + 1
    end
    total_tests = total_tests + 1
    local expected_str = expected_lane == nil and "no lane" or ("lane " .. tostring(expected_lane))
    local got_str = detected == nil and "no lane" or ("lane " .. tostring(detected))
    reaper.ShowConsoleMsg(test.name .. ": " .. (pass and "PASS" or "FAIL") ..
      " (Expected " .. expected_str .. ", got " .. got_str .. ")\n")

    -- Next test (CPS)
    run_test_scenarios(scenarios, scenario_idx, test_idx + 1)
  end)
end

-- Start async scenario runner
run_test_scenarios(scenarios)
