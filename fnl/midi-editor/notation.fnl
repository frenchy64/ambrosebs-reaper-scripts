(var R {})

(fn in-musical-notation? [editor]
  (= 2 (R.MIDIEditor_GetMode editor)))

(when _G.debug-mode (R.ShowConsoleMsg "Running test\n"))

(fn go-down []
  (let [editor (R.MIDIEditor_GetActive)]
    (if (in-musical-notation? editor)
      (for [i 1 4] (R.MIDIEditor_OnCommand editor 40682))
      (R.MIDIEditor_OnCommand editor 40050))))

(fn go-up []
  (let [editor (R.MIDIEditor_GetActive)]
    (if (in-musical-notation? editor)
      (for [i 1 4] (R.MIDIEditor_OnCommand editor 40683))
      (R.MIDIEditor_OnCommand editor 40049))))

(fn init []
  (set R {})
  (go-down))
