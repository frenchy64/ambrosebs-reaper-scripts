-- @description Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone (match file name without extension and author)
-- @author frenchy64
-- @version 1.0
-- @about
--    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
--    in musical notation software such as Dorico by guessing how many bars the music
--    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
--    which goes "down" in that view.

function InMusicalNotation(editor)
  return 2 == reaper.MIDIEditor_GetMode(editor)
end

debug_mode = true
if debug_mode then
  reaper.ShowConsoleMsg("Running\n")
end

function GoDown()
  editor = reaper.MIDIEditor_GetActive()
  if InMusicalNotation(editor) then
    -- Navigate: Move edit cursor right one measure
    for i = 1,4,1 do
      reaper.MIDIEditor_OnCommand(editor, 40682)
    end
  else
    -- Edit: Decrease pitch cursor one semitone
    reaper.MIDIEditor_OnCommand(editor, 40050)
  end
end

GoDown()
