-- Data-driven JSFX Drum Trainer test script for REAPER

-- Helper: Insert and configure JSFX
local function setup_jsfx_on_new_track(jsfx_name)
  reaper.Main_OnCommand(40001, 0)
  local track = reaper.GetTrack(0, reaper.CountTracks(0)-1)
  local fx_idx = reaper.TrackFX_AddByName(track, jsfx_name, false, 1)
  if fx_idx == -1 then error("Could not load JSFX: " .. tostring(jsfx_name)) end
  return track, fx_idx
end

-- Helper: Create test MIDI take with specified events
local function create_test_take(events)
  local track = reaper.GetTrack(0, reaper.CountTracks(0)-1)
  local item = reaper.CreateNewMIDIItemInProj(track, 0, 2.0, false)
  local take = reaper.GetActiveTake(item)
  for _, ev in ipairs(events) do
    local is_cc = ev.is_cc == true
    local msg1
    if is_cc then
      msg1 = ev.cc_controller or 2 -- default controller 2 for CC
    else
      msg1 = ev.note or 60  -- default note 60 for Note On
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

-- Helper: Render JSFX output to new MIDI item and get resulting events
local function render_and_get_output_events(track)
  reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
  reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 4096)
  reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", 2)
  reaper.Main_OnCommand(1013, 0)
  reaper.Sleep(500)
  reaper.Main_OnCommand(1016, 0)
  local item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
  local take = reaper.GetActiveTake(item)
  local events = {}
  local _, cnt = reaper.MIDI_CountEvts(take)
  for i=0, cnt-1 do
    local _, _, _, ppqpos, chanmsg, chan, msg1, msg2 = reaper.MIDI_GetCC(take, i)
    table.insert(events, {ppqpos=ppqpos, chanmsg=chanmsg, chan=chan, msg1=msg1, msg2=msg2})
  end
  return events
end

local function cleanup()
  reaper.Main_OnCommand(40005, 0)
end

local function get_expected_lane_zero_based(cc_value, lanes)
  for i, lane in ipairs(lanes) do
    if cc_value >= lane.cc_min_value and cc_value <= lane.cc_max_value then
      return i - 1
    end
  end
  return nil
end

local function detect_lane_zero_based(events, scenario)
  local lane_detect = scenario.lane_detect or function(events)
    for _, ev in ipairs(events) do
      if ev.chanmsg == 0x90 and ev.msg2 > 0 then
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
      { cc_min_value=0,   cc_max_value=60   },
      { cc_min_value=61,  cc_max_value=120  },
      { cc_min_value=121, cc_max_value=127  }
    },
    tests = {
      { name = "CC=40,  Note=60",  note = 60,  cc_controller = 2, cc_value =  40, expected_lane = 0 },
      { name = "CC=80,  Note=61",  note = 61,  cc_controller = 2, cc_value =  80, expected_lane = 1 },
      { name = "CC=127, Note=62",  note = 62,  cc_controller = 2, cc_value = 127, expected_lane = 2 }
    }
  },
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
}

for _, scenario in ipairs(scenarios) do
  reaper.ShowConsoleMsg("==== Running Scenario: " .. scenario.name .. " ====\n")
  for _, test in ipairs(scenario.tests) do
    cleanup()
    local track, _ = setup_jsfx_on_new_track(scenario.jsfx_name or "ambrosebs_MIDI Drum Trainer")
    local events = {
      { is_cc=true,  cc_controller=test.cc_controller or 2, msg2=test.cc_value, ppqpos=0, chan=0 },
      { is_cc=false, note=test.note or 60, vel=100, ppqpos=240, chan=0 }
    }
    create_test_take(events)
    local output_events = render_and_get_output_events(track)
    local expected_lane = test.expected_lane
    if expected_lane == nil then
      expected_lane = get_expected_lane_zero_based(test.cc_value, scenario.lanes)
    end
    local detected = detect_lane_zero_based(output_events, scenario)
    local pass = detected == expected_lane
    local expected_str = expected_lane == nil and "no lane" or ("lane " .. tostring(expected_lane))
    local got_str = detected == nil and "no lane" or ("lane " .. tostring(detected))
    reaper.ShowConsoleMsg(test.name .. ": " .. (pass and "PASS" or "FAIL") ..
      " (Expected " .. expected_str .. ", got " .. got_str .. ")\n")
  end
  reaper.ShowConsoleMsg("==== End Scenario: " .. scenario.name .. " ====\n\n")
end

reaper.ShowConsoleMsg("All scenarios and tabular tests complete.\n")
