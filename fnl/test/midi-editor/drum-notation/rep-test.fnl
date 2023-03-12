(require-macros :fennel-test)
(local clj (require :cljlib))
(import-macros cljm :cljlib)
(local sut (require :midi-editor/drum-notation/rep))
(local gp8 (require :midi-editor/drum-notation/guitar-pro8))
;(ns reascript-test.drum-notation.rep-test
;  (:require [clojure.test :refer [deftest is testing]]
;            [clojure.data :as data]
;            [clojure.string :as str]
;            [reascript-test.drum-notation.guitar-pro8 :as gp8]
;            [reascript-test.drum-notation.rep :as sut]))

(deftest midi-coord-str-test
  (assert-eq "C-1" (sut.midi-coord-str (sut.->midi-coord "C" -1)))
  (assert-eq "C0" (sut.midi-coord-str (sut.->midi-coord "C" 0)))
  (assert-eq "G9" (sut.midi-coord-str (sut.->midi-coord "G" 9))))

(deftest midi-number->coord-test
  (assert-eq "C-1" (sut.midi-coord-str (sut.midi-number->coord 0)))
  (assert-eq "C0" (sut.midi-coord-str (sut.midi-number->coord 12)))
  (assert-eq "C1" (sut.midi-coord-str (sut.midi-number->coord 24)))
  (assert-eq "B1" (sut.midi-coord-str (sut.midi-number->coord 35)))
  (assert-eq "G9" (sut.midi-coord-str (sut.midi-number->coord 127)))
  ;(is (thrown? AssertionError (sut/midi-coord-str (sut/midi-number->coord -1))))
  ;(is (thrown? AssertionError (sut/midi-coord-str (sut/midi-number->coord 128))))
  )

(deftest parse-midi-coord-test
  (assert-eq {:midi-name "C" :octave -1} (sut.parse-midi-coord "C-1"))
  (assert-eq {:midi-name "C#" :octave 0} (sut.parse-midi-coord "C#0"))
  (assert-eq {:midi-name "C" :octave 4} (sut.parse-midi-coord "C4")))

(deftest midi-coord->number-test
  (assert-eq 0 (sut.midi-coord->number {:midi-name "C" :octave -1}))
  (assert-eq 1 (sut.midi-coord->number {:midi-name "C#" :octave -1}))
  (assert-eq 12 (sut.midi-coord->number {:midi-name "C" :octave 0}))
  (assert-eq 35 (sut.midi-coord->number {:midi-name "B" :octave 1}))
  (assert-eq 36 (sut.midi-coord->number {:midi-name "C" :octave 2}))
  (assert-eq 127 (sut.midi-coord->number {:midi-name "G" :octave 9})))

(deftest coord-str-constraints->midi-number-constraints-test
  (assert-eq {62 ["HP" "CB"]
              64 ["K2"]
              65 ["K1"]
              67 ["T5"]
              69 ["T4"]
              71 ["T3"]
              72 ["RS" "SC" "SS"]
              74 ["T2"]
              76 ["T1"]
              77 ["RM" "RB" "RE"]
              79 ["HC" "HH" "HO" "C2"]
              81 ["C1" "SP"]
              83 ["CH"]}
             (sut.coord-str-constraints->midi-number-constraints
               (. gp8.drum-notation-map1 :notation-map))))

(deftest c-major-midi-name?-test
  (assert-eq {true ["C" "D" "E" "F" "G" "A" "B"]
              false ["C#" "D#" "F#" "G#" "A#"]}
             (clj.group-by sut.c-major-midi-name? sut.midi-names)))

(deftest c-major-midi-number?-test
  (assert-eq {true [0 2 4 5 7 9 11]
              false [1 3 6 8 10]}
             (clj.group-by sut.c-major-midi-number? (clj.range 0 12))))

(deftest accidental-relative-to
  ;(is (thrown? AssertionError (sut/accidental-relative-to 60 57)))
  ;(is (thrown? AssertionError (sut/accidental-relative-to 60 63)))
  (assert-eq ["doubleflat" "flat" "natural" "sharp" "doublesharp"]
             (clj.mapv #(sut.accidental-relative-to 60 $) (clj.range 58 63))))

(deftest notated-midi-num-for-test
  (assert-eq 60 (sut.notated-midi-num-for 58 "doubleflat"))
  (assert-eq 59 (sut.notated-midi-num-for 59 "natural"))
  (assert-eq 60 (sut.notated-midi-num-for 59 "flat"))
  (assert-eq 60 (sut.notated-midi-num-for 60 "natural"))
  (assert-eq 60 (sut.notated-midi-num-for 61 "sharp"))
  (assert-eq 60 (sut.notated-midi-num-for 62 "doublesharp"))
  (assert-eq 62 (sut.notated-midi-num-for 62 "natural"))
  ;(is (thrown? AssertionError (sut/notated-midi-num-for 0 "flat")))
  ;(is (thrown? AssertionError (sut/notated-midi-num-for 61 "natural")))
  ;(is (thrown? AssertionError (sut/notated-midi-num-for 127 "flat")))
  )

(deftest enharmonically-respellable?-test
  (assert-eq {true [58 59 60 61 62]
              false [55 56 57 63 64 65]}
             (clj.group-by #(sut.enharmonically-respellable? 60 $)
                           (clj.range 55 66))))
