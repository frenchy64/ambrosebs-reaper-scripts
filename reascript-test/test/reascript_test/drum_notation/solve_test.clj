(ns reascript-test.drum-notation.solve-test
  (:require [clojure.test :refer [deftest is testing]]
            [reascript-test.drum-notation.solve :as sut]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]
            [reascript-test.drum-notation.pretty :refer [pretty-solution]]
            [reascript-test.drum-notation.test-helpers :as th]))

(deftest enharmonic-midi-numbers
  (is (= (sorted-set 58 59 60 61 62)
         (sut/enharmonic-midi-numbers 58 60)
         (sut/enharmonic-midi-numbers 0 60)))
  (is (= (sorted-set 59 60 61 62)
         (sut/enharmonic-midi-numbers 59 60)))
  (is (= (sorted-set 60 61 62)
         (sut/enharmonic-midi-numbers 60 60)))
  (is (thrown? AssertionError (sut/enharmonic-midi-numbers 61 60))))

(deftest find-solutions-test
  (is (= [{62 {:instrument-id "HP", :accidental "natural"}, 63 {:instrument-id "CB", :accidental "sharp"}}
          {62 {:instrument-id "CB", :accidental "natural"}, 63 {:instrument-id "HP", :accidental "sharp"}}
          {62 {:instrument-id "HP", :accidental "natural"}, 64 {:instrument-id "CB", :accidental "doublesharp"}}
          {62 {:instrument-id "CB", :accidental "natural"}, 64 {:instrument-id "HP", :accidental "doublesharp"}}
          {63 {:instrument-id "HP", :accidental "sharp"}, 64 {:instrument-id "CB", :accidental "doublesharp"}}
          {63 {:instrument-id "CB", :accidental "sharp"}, 64 {:instrument-id "HP", :accidental "doublesharp"}}]
         (sut/find-solutions
           {:midi-name "D"
            :octave 4}
           {"D4" ["HP", "CB"]})))
  (is (= (mapv th/join-lines
               [["_C4__________________________"
                 "|  | |♮|♯|  |  | | | | | |  |"
                 "|  | | |C|  |  | | | | | |  |"
                 "|  | | |B|  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |HP |   |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]
                ["_C4__________________________"
                 "|  | |♮|♯|  |  | | | | | |  |"
                 "|  | | |H|  |  | | | | | |  |"
                 "|  | | |P|  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |CB |   |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]
                ["_C4__________________________"
                 "|  | |♮| |𝄪 |  | | | | | |  |"
                 "|  | | | |  |  | | | | | |  |"
                 "|  | | | |  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |HP |CB |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]
                ["_C4__________________________"
                 "|  | |♮| |𝄪 |  | | | | | |  |"
                 "|  | | | |  |  | | | | | |  |"
                 "|  | | | |  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |CB |HP |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]
                ["_C4__________________________"
                 "|  | | |♯|𝄪 |  | | | | | |  |"
                 "|  | | |H|  |  | | | | | |  |"
                 "|  | | |P|  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |   |CB |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]
                ["_C4__________________________"
                 "|  | | |♯|𝄪 |  | | | | | |  |"
                 "|  | | |C|  |  | | | | | |  |"
                 "|  | | |B|  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |   |HP |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]])
         (mapv pretty-solution
               (sut/find-solutions
                 {:midi-name "D"
                  :octave 4}
                 {"D4" ["HP", "CB"]}))))
  (is (contains?
        (sut/find-solutions
          {:midi-name "D"
           :octave 4}
          (:notation-map gp8/drum-notation-map1))
        gp8/drum-notation-map1-solution)))

(deftest possible-allocations-for-staff-position-test
  ;; root cuts off some options
  (is (= [{60 "HP"
           61 "CB"}
          {60 "HP"
           62 "CB"}]
         (sut/possible-allocations-for-staff-position 60 60 ["HP" "CB"])))
  ;; root allows all respellings
  (is (= [{58 "HP"}
          {59 "HP"}
          {60 "HP"}
          {61 "HP"}
          {62 "HP"}]
         (sut/possible-allocations-for-staff-position 58 60 ["HP"])))
  (is (= [{58 "HP"
           59 "CB"}
          {58 "HP"
           60 "CB"}
          {58 "HP"
           61 "CB"}
          {58 "HP"
           62 "CB"}
          {59 "HP"
           60 "CB"}
          {59 "HP"
           61 "CB"}
          {59 "HP"
           62 "CB"}
          {60 "HP"
           61 "CB"}
          {61 "HP"
           62 "CB"}]
         (sut/possible-allocations-for-staff-position 58 60 ["HP" "CB"])))
  (is (= [{58 "HP"
           59 "CB"
           60 "K1"
           61 "K2"}
          {58 "HP"
           59 "CB"
           60 "K1"
           62 "K2"}
          {58 "HP"
           60 "CB"
           61 "K1"
           62 "K2"}
          {59 "HP"
           60 "CB"
           61 "K1"
           62 "K2"}]
         (sut/possible-allocations-for-staff-position 58 60 ["HP" "CB" "K1" "K2"])))
  (is (= [{58 "HP"
           59 "CB"
           60 "K1"
           61 "K2"
           62 "T5"}]
         (sut/possible-allocations-for-staff-position 58 60 ["HP" "CB" "K1" "K2" "T5"]))))
