(require-macros :fennel-test)

(local sut (require :midi-editor/notation))

(fn make-editor [R]
  {})

(fn make-R [R]
  {:MIDIEditor_GetActive (fn [] (assert nil ":MIDIEditor_GetActive"))
   :MIDIEditor_GetMode (fn [editor] (assert nil ":MIDIEditor_GetMode"))
   :ShowConsoleMsg (fn [...] (assert nil ":ShowConsoleMsg"))
   :MIDIEditor_OnCommand (fn [editor id] (assert nil ":MIDIEditor_OnCommand"))})

(fn stub [R]
  (local notation (require :midi-editor/notation))
  (notation.set-reaper! R)
  notation)

(deftest in-musical-notation?-test
  (each [mode expected (pairs {0 false 1 false 2 true -1 false})]
    (let [n (stub
              (doto (make-R)
                    (tset "MIDIEditor_GetMode" (fn [editor] mode))))]
      (assert-eq expected (n.in-musical-notation? (make-editor))
                 (.. mode " " (tostring expected))))))

(fn repeat [n v]
  (let [t []]
    (for [i 1 n]
      (table.insert t v))
    t))

(deftest repeat-test
  (assert-eq [1 1 1] (repeat 3 1)))

;; both inclusive
(fn range [from to]
  (let [t []]
    (for [i from to]
      (table.insert t i))
    t))

(deftest range-test
  (assert-eq [1 2 3] (range 1 3)))

;(deftest go-down+up-test
;  (each [bars (range 1 18)]
;    (each [method cases (pairs {"go-down" {0 [40050]
;                                           1 [40050]
;                                           2 (repeat bars 40682)
;                                           -1 [40050]}
;                                "go-up" {0 [40049]
;                                         1 [40049]
;                                         2 (repeat bars 40683)
;                                         -1 [40049]}})]
;      (each [mode expected (pairs cases)]
;        (let [commands []]
;          (var R nil)
;          (set R (doto (make-R)
;                       (tset "MIDIEditor_GetActive" (fn [] (make-editor R)))
;                       (tset "MIDIEditor_GetMode" (fn [editor] mode))
;                       (tset "MIDIEditor_OnCommand" (fn [editor command]
;                                                      (table.insert commands command)))))
;          (let [n (stub R)]
;            ((. n method) bars)
;            (assert-eq expected commands
;                       (.. "Method: " method ", " "Mode: " mode))))))))
