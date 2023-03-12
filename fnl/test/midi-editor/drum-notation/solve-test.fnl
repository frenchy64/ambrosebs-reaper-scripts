(require-macros :fennel-test)
(local clj (require :cljlib))
(import-macros cljm :cljlib)
(local rep (require :midi-editor/drum-notation/rep))
(local gp8 (require :midi-editor/drum-notation/guitar-pro8))
(local sut (require :midi-editor/drum-notation/solve))

;(ns reascript-test.drum-notation.solve-test
;  (:require [clojure.test :refer [deftest is testing]]
;            [reascript-test.drum-notation.solve :as sut]
;            [reascript-test.drum-notation.rep :refer :all]
;            [reascript-test.drum-notation.guitar-pro8 :as gp8]
;            [reascript-test.drum-notation.pretty :refer [pretty-solution]]
;            [reascript-test.drum-notation.test-helpers :as th]))

(deftest enharmonic-midi-numbers
  (assert-eq [58 59 60 61 62]
             (sut.enharmonic-midi-numbers 58 60)
             (sut.enharmonic-midi-numbers 0 60))
  (assert-eq [59 60 61 62]
             (sut.enharmonic-midi-numbers 59 60))
  (assert-eq [60 61 62]
             (sut.enharmonic-midi-numbers 60 60))
  ;(is (thrown? AssertionError (sut.enharmonic-midi-numbers 61 60)))
  )

(deftest find-solution-test
  (assert-eq {:type :solution
              :solution {62 {:instrument-id "HP" :accidental "natural"} 63 {:instrument-id "CB" :accidental "sharp"}}}
             (sut.find-solution
               {:midi-name "D"
                :octave 4}
               {"D4" ["HP" "CB"]}))
;  (is (= (th/join-lines
;           ["_C4__________________________"
;            "|  | |♮|♯|  |  | | | | | |  |"
;            "|  | | |C|  |  | | | | | |  |"
;            "|  | | |B|  |  | | | | | |  |"
;            "|  |_| |_|  |  |_| |_| |_|  |"
;            "|   |HP |   |   |   |   |   |"
;            "|___|___|___|___|___|___|___|"])
;         (pretty-solution
;           (:solution
;             (sut.find-solution
;               {:midi-name "D"
;                :octave 4}
;               {"D4" ["HP" "CB"]})))))
(assert-eq {:type :solution
            :solution
            {62 {:instrument-id "HP" :accidental "natural"}
             63 {:instrument-id "CB" :accidental "sharp"}
             64 {:instrument-id "K2" :accidental "natural"}
             65 {:instrument-id "K1" :accidental "natural"}
             66 {:instrument-id "T5" :accidental "flat"}
             67 {:instrument-id "T4" :accidental "doubleflat"}
             69 {:instrument-id "T3" :accidental "doubleflat"}
             70 {:instrument-id "RS" :accidental "doubleflat"}
             71 {:instrument-id "SC" :accidental "flat"}
             72 {:instrument-id "SS" :accidental "natural"}
             73 {:instrument-id "T2" :accidental "flat"}
             74 {:instrument-id "T1" :accidental "doubleflat"}
             75 {:instrument-id "RM" :accidental "doubleflat"}
             76 {:instrument-id "RB" :accidental "flat"}
             77 {:instrument-id "RE" :accidental "natural"}
             78 {:instrument-id "HC" :accidental "flat"}
             79 {:instrument-id "HH" :accidental "natural"}
             80 {:instrument-id "HO" :accidental "sharp"}
             81 {:instrument-id "C2" :accidental "doublesharp"}
             82 {:instrument-id "C1" :accidental "sharp"}
             83 {:instrument-id "SP" :accidental "doublesharp"}
             84 {:instrument-id "CH" :accidental "sharp"}}}
           (sut.find-solution
             {:midi-name "D"
              :octave 4}
             (:notation-map gp8.drum-notation-map1)))
; (is (= (th/join-lines
;          ["_C4__________________________C5__________________________C6__________________________"
;           "|  | |♮|♯|♮ |♮ |♭|𝄫| |𝄫|𝄫|♭ |♮ |♭|𝄫|𝄫|♭ |♮ |♭|♮|♯|𝄪|♯|𝄪 |♯ | | | |  |  | | | | | |  |"
;           "|  | | |C|  |  |T| | | |R|  |  |T| |R|  |  |H| |H| |C|  |  | | | |  |  | | | | | |  |"
;           "|  | | |B|  |  |5| | | |S|  |  |2| |M|  |  |C| |O| |1|  |  | | | |  |  | | | | | |  |"
;           "|  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |"
;           "|   |HP |K2 |K1 |T4 |T3 |SC |SS |T1 |RB |RE |HH |C2 |SP |CH |   |   |   |   |   |   |"
;           "|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|"])
;        (pretty-solution
;          (:solution
;            (sut.find-solution
;              {:midi-name "D"
;               :octave 4}
;              (:notation-map gp8/drum-notation-map1))))))
 )
