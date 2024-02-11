-- @description Select Note With MIDI Note Number 71
-- @author Ambrose Bonnaire-Sergeant
-- @version 1.0
-- @about
--    Select Note With MIDI Note Number 71

function Msg(param)
reaper.ShowConsoleMsg(tostring(param).."\n")
end


local r = reaper

local hwnd = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(hwnd)

local retval, notecnt, _, _ = r.MIDI_CountEvts(take)

  if notecnt == 0 then r.MB('No notes in the MIDI item.','ERROR',0) return end

  if notecnt > 0 then
  reaper.Undo_BeginBlock()
  local select_pitch = 71
  for i = 0, notecnt-1 do
    local retval, sel, _, startpos, endpos, _, pitch, _ = r.MIDI_GetNote(take, i)
      if pitch == select_pitch then r.MIDI_SetNote(take, i, true, muted, startpos, endpos, chan, pitch, vel,true) 
      else r.MIDI_SetNote(take, i, false, muted, startpos, endpos, chan, pitch, vel, true) 
      end
  end
  r.MIDI_Sort(take)
  r.MarkTrackItemsDirty(r.GetMediaItemTake_Track(take), r.GetMediaItemTake_Item(take))
  r.Undo_EndBlock(select(2,r.get_action_context()):match('([^\\/]+)%.%w+'),-1)
  end
