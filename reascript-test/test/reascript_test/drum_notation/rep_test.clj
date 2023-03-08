(ns reascript-test.drum-notation.rep-test
  (:require [clojure.test :refer [deftest is testing]]
            [clojure.data :as data]
            [clojure.string :as str]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]
            [reascript-test.drum-notation.rep :as sut]))

(deftest midi-coord-str-test
  (is (= "C-1" (sut/midi-coord-str (sut/->midi-coord "C" -1))))
  (is (= "C0" (sut/midi-coord-str (sut/->midi-coord "C" 0))))
  (is (= "G9" (sut/midi-coord-str (sut/->midi-coord "G" 9)))))

(deftest midi-number->coord-test
  (is (= "C-1" (sut/midi-coord-str (sut/midi-number->coord 0))))
  (is (= "C0" (sut/midi-coord-str (sut/midi-number->coord 12))))
  (is (= "C1" (sut/midi-coord-str (sut/midi-number->coord 24))))
  (is (= "B1" (sut/midi-coord-str (sut/midi-number->coord 35))))
  (is (= "G9" (sut/midi-coord-str (sut/midi-number->coord 127))))
  (is (thrown? AssertionError (sut/midi-coord-str (sut/midi-number->coord -1))))
  (is (thrown? AssertionError (sut/midi-coord-str (sut/midi-number->coord 128)))))

(deftest parse-midi-coord-test
  (is (= {:midi-name "C" :octave -1} (sut/parse-midi-coord "C-1")))
  (is (= {:midi-name "C#" :octave 0} (sut/parse-midi-coord "C#0")))
  (is (= {:midi-name "C" :octave 4} (sut/parse-midi-coord "C4"))))

(deftest midi-coord->number-test
  (is (= 0 (sut/midi-coord->number {:midi-name "C" :octave -1})))
  (is (= 1 (sut/midi-coord->number {:midi-name "C#" :octave -1})))
  (is (= 12 (sut/midi-coord->number {:midi-name "C" :octave 0})))
  (is (= 35 (sut/midi-coord->number {:midi-name "B" :octave 1})))
  (is (= 36 (sut/midi-coord->number {:midi-name "C" :octave 2})))
  (is (= 127 (sut/midi-coord->number {:midi-name "G" :octave 9}))))

(deftest coord-str-constraints->midi-number-constraints-test
  (is (= {62 ["HP" "CB"]
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
        (sut/coord-str-constraints->midi-number-constraints (:notation-map gp8/drum-notation-map1)))))
