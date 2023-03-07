(ns reascript-test.core-test
  (:require [clojure.test :refer :all]
            [reascript-test.core :refer :all]
            [clojure.data :as data]
            [clojure.pprint :refer [pprint] :as pp]))
;-- TODO suggest (or provide constrait for) middle for Virtual MIDI keyboard
;notation_name = "D5 Enharmonic Drum Notation"
;root = "D4"
;-- ordering preference (soft constraint)
;-- {Xnatural, Xdoubleflat?, Xflat?, Xsharp?, Xdoublesharp?} -- X# note
;notation_map = {
;  {"Hi-Hat Pedal (HP)", "Cowbell (CB)"}, -- D4
;  {"Kick 2 (K2)"}, -- E4
;  {"Kick 1 (K1)"}, -- F4
;  {"Very Low Tom (T5)"},  -- G4
;  {"Low Tom (T4)"}, -- A4
;  {"Mid Tom (T3)"}, -- B4
;  {"Snare (Rim Shot)", "Snare Center (SC)", "Snare Stick (SS)"}, -- C5
;  {"High Tom (T2)"}, -- D5
;  {"High Floor Tom (T1)"}, -- E5
;  {"Ride Middle (RM)", "Ride Bell (RB)", "Ride Edge (RE)"}, -- F5
;  {"Hi-Hat Closed (HC)", "Hi-Hat Half (HH)", "Hi-Hat Open (HO)", "Crash Medium (C2)"}, -- G5
;  {"Crash High (C1)", "Splash"}, -- A5
;  {"China"} -- B5
;  }

;; drum notation

(def drum-notation-map1
  {:name "D5 Enharmonic Drum Notation"
   :root "D4"
   :virtual-midi-keyboard-middle "D5"
   :instruments {"CH" {:name "China"},
                 "HH" {:name "Hi-Hat Half"},
                 "SC" {:name "Snare Center"},
                 "HO" {:name "Hi-Hat Open"},
                 "C1" {:name "Crash High"},
                 "T3" {:name "Mid Tom"},
                 "K1" {:name "Kick 1"},
                 "C2" {:name "Crash Medium"},
                 "T2" {:name "High Tom"},
                 "CB" {:name "Cowbell"},
                 "RB" {:name "Ride Bell"},
                 "K2" {:name "Kick 2"},
                 "T5" {:name "Very Low Tom"},
                 "HC" {:name "Hi-Hat Closed"},
                 "HP" {:name "Hi-Hat Pedal"},
                 "RE" {:name "Ride Edge"},
                 "T4" {:name "Low Tom"},
                 "SS" {:name "Snare Stick"},
                 "RS" {:name "Snare Rim Shot"},
                 "T1" {:name "High Floor Tom"},
                 "SP" {:name "Splash"},
                 "RM" {:name "Ride Middle"}}
   :notation-map {"D4" ["HP", "CB"]
                  "E4" ["K2"],
                  "F4" ["K1"],
                  "G4" ["T5"], 
                  "A4" ["T4"],
                  "B4" ["T3"],
                  "C5" ["RS", "SC", "SS"],
                  "D5" ["T2"],
                  "E5" ["T1"],
                  "F5" ["RM", "RB", "RE"],
                  "G5" ["HC", "HH", "HO", "C2"],
                  "A5" ["C1", "SP"],
                  "B5" ["CH"]}})

(def drum-notation-map1-solution
  {62 {:instrument-id "HP",
       :printed-note "D4"},
   63 {:instrument-id "CB",
       :printed-note "Db4"},
   64 {:instrument-id "K2",
       :printed-note "E4"},
   65 {:instrument-id "K1",
       :printed-note "F4"},
   66 {:instrument-id "T5",
       :printed-note "Gb4"}})

(let [midi-note-numbers (mapv :midi-note-number drum-notation-map1-solution)]
  (assert (apply < midi-note-numbers) midi-note-numbers))

(defn multi-frequencies [c]
  (into {} (remove (comp #{1} val))
        (frequencies c)))

(let [constraint-names (mapcat identity (:notation-map drum-notation-map1))
      solution-names (map :name drum-notation-map1-solution)]
  (assert (apply distinct? constraint-names)
          (multi-frequencies constraint-names))
  (assert (apply distinct? solution-names)
          (multi-frequencies solution-names))
  (assert (= (set constraint-names) (set solution-names))
          (let [[only-in-constraints only-in-solution] (data/diff constraint-names solution-names)]
            (str "Only in constraints: " (pr-str only-in-constraints) "\n"
                 "Only in solution: " (pr-str only-in-solution)))))


(deftest drum-notation-test
  (testing "FIXME, I fail."
    (is (= 0 1))))
