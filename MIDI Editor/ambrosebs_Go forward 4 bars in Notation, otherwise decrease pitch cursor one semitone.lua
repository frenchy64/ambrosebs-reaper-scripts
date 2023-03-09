-- @description Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone
-- @author frenchy64
-- @version 1.4
-- @about
--    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
--    in musical notation software such as Dorico by guessing how many bars the music
--    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
--    which goes "down" in that view.
-- compiled from 'MIDI Editor/ambrosebs_Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone.fnl'
local function in_musical_notation_3f(editor)
  return (2 == reaper.MIDIEditor_GetMode(editor))
end
if __fnl_global__debug_2dmode then
  reaper.ShowConsoleMsg("Running\n")
else
end
local function go_down()
  local editor = reaper.MIDIEditor_GetActive()
  if in_musical_notation_3f(editor) then
    for i = 1, 4 do
      reaper.MIDIEditor_OnCommand(editor, 40682)
    end
    return nil
  else
    return reaper.MIDIEditor_OnCommand(editor, 40050)
  end
end
local function go_up()
  local editor = reaper.MIDIEditor_GetActive()
  if in_musical_notation_3f(editor) then
    for i = 1, 4 do
      reaper.MIDIEditor_OnCommand(editor, 40683)
    end
    return nil
  else
    return reaper.MIDIEditor_OnCommand(editor, 40049)
  end
end
return go_down()
