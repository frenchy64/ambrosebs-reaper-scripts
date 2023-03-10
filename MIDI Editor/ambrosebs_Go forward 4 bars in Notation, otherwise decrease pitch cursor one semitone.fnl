;; @description Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone
;; @author Ambrose Bonnaire-Sergeant
;; @version 1.6
;; @about
;;    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
;;    in musical notation software such as Dorico by guessing how many bars the music
;;    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
;;    which goes "down" in that view.

(global R {})

(fn in-musical-notation? [editor]
  (= 2 (R.MIDIEditor_GetMode editor)))

(when _G.debug-mode (R.ShowConsoleMsg "Running test\n"))

(fn go-down []
  (let [editor (R.MIDIEditor_GetActive)]
    (if (in-musical-notation? editor)
      (for [i 1 4] (R.MIDIEditor_OnCommand editor 40682))
      (R.MIDIEditor_OnCommand editor 40050))))

(fn go-up [reaper]
  (let [editor (reaper.MIDIEditor_GetActive)]
    (if (in-musical-notation? editor)
      (for [i 1 4] (reaper.MIDIEditor_OnCommand editor 40683))
      (reaper.MIDIEditor_OnCommand editor 40049))))

(fn init []
  (set reaper reaper)
  (go-down))
