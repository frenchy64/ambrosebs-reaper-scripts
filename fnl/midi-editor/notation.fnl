;; @description Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone
;; @author Ambrose Bonnaire-Sergeant
;; @version 1.6
;; @about
;;    Intended to be assigned to the Down arrow in the MIDI Editor, this action simulates pressing Down
;;    in musical notation software such as Dorico by guessing how many bars the music
;;    is zoomed by. If in a different MIDI editor mode, decreases the pitch cursor,
;;    which goes "down" in that view.

(var R _G.reaper)

;(when _G.debug-mode (R.ShowConsoleMsg "Running test\n"))

(fn set-reaper! [r]
  (set R r)
  r)

(fn in-musical-notation? [editor]
  (= 2 (R.MIDIEditor_GetMode editor)))

(fn go-dir [notation other]
  (let [editor (R.MIDIEditor_GetActive)]
    (if (in-musical-notation? editor)
      (for [i 1 4] (R.MIDIEditor_OnCommand editor notation))
      (R.MIDIEditor_OnCommand editor other))))

(fn go-down []
  (go-dir 40682 40050))

(fn go-up []
  (go-dir 40683 40049))

; (local n (require "midi-editor/notation"))
{: set-reaper!
 : go-up
 : go-down
 : in-musical-notation?}
