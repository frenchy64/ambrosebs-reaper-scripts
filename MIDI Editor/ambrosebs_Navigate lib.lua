-- @noindex
-- @author Ambrose Bonnaire-Sergeant
-- @version 1.0
-- @about
--    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
--    in musical notation software such as Dorico by guessing how many bars the music
--    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
--    which goes "down" in that view.

function InMusicalNotation(editor)
  return 2 == reaper.MIDIEditor_GetMode(editor)
end

if debug_mode then
  reaper.ShowConsoleMsg("Running\n")
end

function GoDir(notation, other)
  editor = reaper.MIDIEditor_GetActive()
  if InMusicalNotation(editor) then
    for i = 1,4,1 do
      reaper.MIDIEditor_OnCommand(editor, notation)
    end
  else
    reaper.MIDIEditor_OnCommand(editor, other)
  end
end

function GoDown()
  GoDir(40682 -- Navigate: Move edit cursor right one measure
      , 40050 -- Edit: Decrease pitch cursor one semitone
      )
end

function GoUp()
  GoDir(40683 -- Navigate: Move edit cursor left one measure
      , 40049 -- Edit: Increase pitch cursor one semitone
      )
end
