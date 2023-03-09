(ns reascript-test.drum-notation.solve-test
  (:require [clojure.test :refer [deftest is testing]]
            [reascript-test.drum-notation.solve :as sut]
            [reascript-test.drum-notation.rep :refer :all]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]
            [reascript-test.drum-notation.pretty :refer [pretty-solution]]
            [reascript-test.drum-notation.test-helpers :as th]))

(deftest enharmonic-midi-numbers
  (is (= [58 59 60 61 62]
         (sut/enharmonic-midi-numbers 58 60)
         (sut/enharmonic-midi-numbers 0 60)))
  (is (= [59 60 61 62]
         (sut/enharmonic-midi-numbers 59 60)))
  (is (= [60 61 62]
         (sut/enharmonic-midi-numbers 60 60)))
  (is (thrown? AssertionError (sut/enharmonic-midi-numbers 61 60))))

(deftest possible-allocations-test
  (is (= [[{62 "HP"}]]
         (sut/possible-allocations 62
                                   (sorted-map 62 ["HP"]))))
  (is (= [[{62 "HP", 63 "CB"}]]
         (sut/possible-allocations 62
                                   (sorted-map 62 ["HP" "CB"]))))
  (is (= [[{62 "HP", 63 "CB"}]
          [{64 "K2"}]]
         (sut/possible-allocations 62
                                   (sorted-map 62 ["HP" "CB"]
                                               64 ["K2"]))))
  (is (= [[{60 "L1", 61 "L2", 62 "HP", 63 "CB"}]
          [{64 "K2"}]]
         (sut/possible-allocations 60
                                   (sorted-map 62 ["L1" "L2" "HP" "CB"]
                                               64 ["K2"]))))
  (is (= [[{62 "HP", 63 "CB"}]
          [{64 "K2"}]
          [{65 "K1"}]]
         (sut/possible-allocations (midi-coord->number (:root gp8/drum-notation-map1))
                                   (into (sorted-map)
                                         (select-keys (coord-str-constraints->midi-number-constraints (:notation-map gp8/drum-notation-map1))
                                                      (range 62 66))))))
  (is (= [[{62 "HP", 63 "CB"}]
          [{64 "K2"}]
          [{65 "K1"}]
          [{66 "T5"}]
          [{67 "T4"}]
          [{69 "T3"}]
          [{70 "RS", 71 "SC", 72 "SS"}
           {70 "RS", 71 "SC", 73 "SS"}
           {70 "RS", 71 "SC", 74 "SS"}
           {70 "RS", 72 "SC", 73 "SS"}
           {70 "RS", 72 "SC", 74 "SS"}
           {70 "RS", 73 "SC", 74 "SS"}
           {71 "RS", 72 "SC", 73 "SS"}
           {71 "RS", 72 "SC", 74 "SS"}
           {71 "RS", 73 "SC", 74 "SS"}
           {72 "RS", 73 "SC", 74 "SS"}]
          [{75 "T2"}] ;;hmm too restrictive?
          [{76 "T1"}]
          ;;TODO 75 not possible 
          [{75 "RM", 77 "RB", 78 "RE"}
           {75 "RM", 77 "RB", 79 "RE"}
           {75 "RM", 78 "RB", 79 "RE"}
           {77 "RM", 78 "RB", 79 "RE"}]
          [{77 "HC", 78 "HH", 79 "HO", 80 "C2"}
           {77 "HC", 78 "HH", 79 "HO", 81 "C2"}
           {77 "HC", 78 "HH", 80 "HO", 81 "C2"}
           {77 "HC", 79 "HH", 80 "HO", 81 "C2"}
           {78 "HC", 79 "HH", 80 "HO", 81 "C2"}]
          [{79 "C1", 80 "SP"}
           {79 "C1", 81 "SP"}
           {79 "C1", 82 "SP"}
           {79 "C1", 83 "SP"}
           {80 "C1", 81 "SP"}
           {80 "C1", 82 "SP"}
           {80 "C1", 83 "SP"}
           {81 "C1", 82 "SP"}
           {81 "C1", 83 "SP"}
           {82 "C1", 83 "SP"}]
          [{84 "CH"}]]
         (sut/possible-allocations (midi-coord->number (:root gp8/drum-notation-map1))
                                   (coord-str-constraints->midi-number-constraints (:notation-map gp8/drum-notation-map1))))))

(deftest find-solutions-test
  (is (= [{62 {:instrument-id "HP", :accidental "natural"}, 63 {:instrument-id "CB", :accidental "sharp"}}
          {62 {:instrument-id "HP", :accidental "natural"}, 64 {:instrument-id "CB", :accidental "doublesharp"}}
          {63 {:instrument-id "HP", :accidental "sharp"}, 64 {:instrument-id "CB", :accidental "doublesharp"}}]
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
                 "|  | |♮| |𝄪 |  | | | | | |  |"
                 "|  | | | |  |  | | | | | |  |"
                 "|  | | | |  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |HP |CB |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]
                ["_C4__________________________"
                 "|  | | |♯|𝄪 |  | | | | | |  |"
                 "|  | | |H|  |  | | | | | |  |"
                 "|  | | |P|  |  | | | | | |  |"
                 "|  |_| |_|  |  |_| |_| |_|  |"
                 "|   |   |CB |   |   |   |   |"
                 "|___|___|___|___|___|___|___|"]])
         (mapv pretty-solution
               (sut/find-solutions
                 {:midi-name "D"
                  :octave 4}
                 {"D4" ["HP", "CB"]}))))
  ;;FIXME this is wrong. missing HP
  (is (= {62 {:instrument-id "K2", :accidental "doubleflat"}
          63 {:instrument-id "K1", :accidental "doubleflat"}
          65 {:instrument-id "T5", :accidental "doubleflat"}
          67 {:instrument-id "T4", :accidental "doubleflat"}
          69 {:instrument-id "T3", :accidental "doubleflat"}
          70 {:instrument-id "RS", :accidental "doubleflat"}
          71 {:instrument-id "SC", :accidental "flat"}
          72 {:instrument-id "T2", :accidental "doubleflat"}
          74 {:instrument-id "T1", :accidental "doubleflat"}
          75 {:instrument-id "RM", :accidental "doubleflat"}
          76 {:instrument-id "RB", :accidental "flat"}
          77 {:instrument-id "HC", :accidental "doubleflat"}
          78 {:instrument-id "HH", :accidental "flat"}
          79 {:instrument-id "C1", :accidental "doubleflat"}
          80 {:instrument-id "SP", :accidental "flat"}
          81 {:instrument-id "CH", :accidental "doubleflat"}}
         (first
           (sut/find-solutions
             {:midi-name "D"
              :octave 4}
             (:notation-map gp8/drum-notation-map1))))))

(deftest possible-allocations-for-staff-position-test
  ;; root cuts off some options
  (is (= [{60 "HP"
           61 "CB"}
          {60 "HP"
           62 "CB"}
          {61 "HP"
           62 "CB"}]
         (sut/possible-allocations-for-staff-position nil 60 60 ["HP" "CB"])
         (sut/possible-allocations-for-staff-position [{60 "K1"} {61 "K1"}] 60 60 ["HP" "CB"])))
  ;; root allows all respellings
  (is (= [{58 "HP"}
          {59 "HP"}
          {60 "HP"}
          {61 "HP"}
          {62 "HP"}]
         (sut/possible-allocations-for-staff-position nil 58 60 ["HP"])))
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
          {60 "HP"
           62 "CB"}
          {61 "HP"
           62 "CB"}]
         (sut/possible-allocations-for-staff-position nil 58 60 ["HP" "CB"])))
  (is (= [{58 "HP"
           59 "CB"
           60 "K1"
           61 "K2"}
          {58 "HP"
           59 "CB"
           60 "K1"
           62 "K2"}
          {58 "HP"
           59 "CB"
           61 "K1"
           62 "K2"}
          {58 "HP"
           60 "CB"
           61 "K1"
           62 "K2"}
          {59 "HP"
           60 "CB"
           61 "K1"
           62 "K2"}]
         (sut/possible-allocations-for-staff-position nil 58 60 ["HP" "CB" "K1" "K2"])))
  (is (= [{58 "HP"
           59 "CB"
           60 "K1"
           61 "K2"
           62 "T5"}]
         (sut/possible-allocations-for-staff-position nil 58 60 ["HP" "CB" "K1" "K2" "T5"])))
  ;; trim states based on previous allocations
  (is (= [{59 "HP"}
          {60 "HP"}
          {61 "HP"}
          {62 "HP"}]
         (sut/possible-allocations-for-staff-position [{58 "CB"}] 58 60 ["HP"])
         (sut/possible-allocations-for-staff-position [{58 "CB" 60 "K1"} {58 "CB" 61 "K1"}] 58 60 ["HP"])))
  (is (= [{60 "HP"}
          {61 "HP"}
          {62 "HP"}]
         (sut/possible-allocations-for-staff-position [{58 "CB" 59 "K1"}] 58 60 ["HP"])
         (sut/possible-allocations-for-staff-position [{58 "CB" 59 "K1" 60 "K2"}
                                                       {58 "CB" 59 "K1" 61 "K2"}]
                                                      58 60 ["HP"]))))
