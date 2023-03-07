-- @author frenchy64
-- @version 1.0
-- @about
--    Ensure every note in a MIDI item shares the same accidentals (inherited from the first 
--    instance of that note).

function inherit()
  local midi_editor = reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake(midi_editor)

  reaper.MIDIEditor_OnCommand(midi_editor, 40214) -- unselect all
  
  if not take then
    return
  end

  local ok, midi = reaper.MIDI_GetAllEvts(take, "")
  if not ok then
    reaper.MB("Could not load the MIDI string.", "ERROR", 0)
    return
  end

  -- TODO find the accidental of the first instance of each note, and then set
  -- the next instances of to the same accidental.
  local notes_by_pitch={}
  local ticks, prevPos, pos, savePos = 0, 1, 1, 1
  note_to_accidental = {}
  count = 0
  while pos < #midi do
    offset, flags, msg, pos = string.unpack("i4Bs4", midi, pos)
    ticks = ticks + offset
    local match = true
    for _, word in ipairs(tWords) do
      if not msg:match(word) then
        match = false break
      end
    end
    count = count + 1
    -- TODO copy https://github.com/ReaTeam/ReaScripts/blob/df9ff97d370a509bd4ef37a08634c69576fcc0b0/MIDI%20Editor/kl_Preset%20velocity.lua#L39
    local chan, pitch = msg:match("NOTE (%d+) (%d+) ")
    if chan and pitch then
      chan  = (tonumber(chan)//1)%16
      pitch = (tonumber(pitch)//1)%256
      local idx = (ticks<<12) | (pitch<<4) | chan
      local group = tNotation[idx] or {}
      tNotation[idx] = group
      group[#group+1] = {
        msg = msg,
        idx = count
      }
      table.insert(tableEvents, string.pack("i4Bs4", offset, flags, ms))  
    end
  end

  -- iterate over each group
  for _,pitches in values(notes_by_pitch) do
    local first_pitch = pitches[1].idx
    local first_msg = pitches[1].msg
  end
end

