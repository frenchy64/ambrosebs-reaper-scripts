-- @description Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone
-- @author Ambrose Bonnaire-Sergeant
-- @version 1.6
-- @about
--    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
--    in musical notation software such as Dorico by guessing how many bars the music
--    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
--    which goes "down" in that view.
-- compiled from https://github.com/frenchy64/ambrosebs-reaper-scripts/blob/a3f863d/fnl/midi-editor/notation.fnl
local R = _G.reaper
local function set_reaper_21(r)
  R = r
  return r
end
local function in_musical_notation_3f(editor)
  return (2 == R.MIDIEditor_GetMode(editor))
end
local function go_dir(notation, other, bars)
  local editor = R.MIDIEditor_GetActive()
  if in_musical_notation_3f(editor) then
    for i = 1, bars do
      R.MIDIEditor_OnCommand(editor, notation)
    end
    return nil
  else
    return R.MIDIEditor_OnCommand(editor, other)
  end
end
local function go_down(bars)
  return go_dir(40682, 40050, bars)
end
local function go_up(bars)
  return go_dir(40683, 40049, bars)
end
return {["set-reaper!"] = set_reaper_21, ["go-up"] = go_up, ["go-down"] = go_down, ["in-musical-notation?"] = in_musical_notation_3f}
