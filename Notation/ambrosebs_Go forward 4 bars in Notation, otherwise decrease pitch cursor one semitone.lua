--[[
 * ReaScript Name: Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone (match file name without extension and author)
 * Description:
 * Instructions: Run
 * Screenshot URl:
 * Author:
 * Author URl:
 * Repository:
 * Repository URl:
 * File URl:
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URl:
 * REAPER: 5.0
 * Extensions:
--]]
 
--[[
 * Changelog:
 * v1.1 (2015-06-12)
   # Modification
   + Addition
   - Deletion
 * v1.0 (2015-02-27)
  + Initial Release
--]]

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
