(ns reascript-test.drum-notation.rep
  (:require [clojure.test :refer [deftest is testing]]
            [clojure.data :as data]
            [clojure.string :as str]
            [reascript-test.drum-notation.rep :as sut]))

(deftest midi-coord-str-test
  (is (= "C-1" (sut/midi-coord-str (sut/->midi-coord "C" -1))))
  (is (= "C0" (sut/midi-coord-str (sut/->midi-coord "C" 0))))
  (is (= "G9" (sut/midi-coord-str (sut/->midi-coord "G" 9)))))

(deftest midi-number->coord-test
  (is (= "C-1" (sut/midi-coord-str (sut/midi-number->coord 0))))
  (is (= "B1" (sut/midi-coord-str (sut/midi-number->coord 35))))
  (is (= "G9" (sut/midi-coord-str (sut/midi-number->coord 127))))
  (is (thrown? AssertionError (sut/midi-coord-str (sut/midi-number->coord -1))))
  (is (thrown? AssertionError (sut/midi-coord-str (sut/midi-number->coord 128)))))
