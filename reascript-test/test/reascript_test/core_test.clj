(ns reascript-test.core-test
  (:require [clojure.test :refer :all]
            [reascript-test.core :refer :all]
            [clojure.data :as data]
            [clojure.pprint :refer [pprint] :as pp]
            [clojure.string :as str]))

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
   :instruments {"C1" {:name "Crash High"},
                 "C2" {:name "Crash Medium"},
                 "CB" {:name "Cowbell"},
                 "CH" {:name "China"},
                 "HC" {:name "Hi-Hat Closed"},
                 "HH" {:name "Hi-Hat Half"},
                 "HO" {:name "Hi-Hat Open"},
                 "HP" {:name "Hi-Hat Pedal"},
                 "K1" {:name "Kick 1"},
                 "K2" {:name "Kick 2"},
                 "RB" {:name "Ride Bell"},
                 "RE" {:name "Ride Edge"},
                 "RM" {:name "Ride Middle"},
                 "RS" {:name "Snare Rim Shot"},
                 "SC" {:name "Snare Center"},
                 "SP" {:name "Splash"},
                 "SS" {:name "Snare Stick"},
                 "T1" {:name "High Floor Tom"},
                 "T2" {:name "High Tom"},
                 "T3" {:name "Mid Tom"},
                 "T4" {:name "Low Tom"},
                 "T5" {:name "Very Low Tom"}}
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

;; TODO assert alphanumeric, no unicode
(defn instrument-id? [id]
  (and (string? id)
       (= 2 (count id))))

(def reaper-accidental->string
  {"flat" "♭"
   "doubleflat" "𝄫"
   "natural" "♮"
   "sharp" "♯"
   "doublesharp" "𝄪"})

(defn reaper-accidental? [r]
  (contains? reaper-accidental->string r))

;; :printed-note + :accidental are redundant for readability
;; {midi-note-number info}
(def drum-notation-map1-solution
  (into (sorted-map)
        {62 {:instrument-id "HP",
             #_#_:printed-note "D4"
             :accidental "natural"},
         63 {:instrument-id "CB",
             #_#_:printed-note "Db4"
             :accidental "flat"},
         64 {:instrument-id "K2",
             #_#_:printed-note "E4"
             :accidental "natural"},
         65 {:instrument-id "K1",
             #_#_:printed-note "F4"
             :accidental "natural"},
         66 {:instrument-id "T5",
             #_#_:printed-note "Gb4"
             :accidental "flat"}
         67 {:instrument-id "T4",
             #_#_:printed-note "Abb4"
             :accidental "doubleflat"}
         69 {:instrument-id "T3"
             #_#_:printed-note "Bbb4"
             :accidental "doubleflat"}
         70 {:instrument-id "SC"
             #_#_:printed-note "Cbb5"
             :accidental "doubleflat"}
         71 {:instrument-id "SS"
             #_#_:printed-note "Cb5"
             :accidental "flat"}
         72 {:instrument-id "SR"
             #_#_:printed-note "C5"
             :accidental "natural"}
         73 {:instrument-id "T2"
             #_#_:printed-note "Db5"
             :accidental "flat"}
         74 {:instrument-id "T1"
             #_#_:printed-note "Ebb5"
             :accidental "doubleflat"}
         75 {:instrument-id "RB"
             #_#_:printed-note "Fbb5"
             :accidental "doubleflat"}
         76 {:instrument-id "RE"
             #_#_:printed-note "Fb5"
             :accidental "flat"}
         77 {:instrument-id "RM"
             #_#_:printed-note "F5"
             :accidental "natural"}
         78 {:instrument-id "HH"
             #_#_:printed-note "Gb5"
             :accidental "flat"}
         79 {:instrument-id "HC"
             #_#_:printed-note "G5"
             :accidental "natural"}
         80 {:instrument-id "HO"
             #_#_:printed-note "G#5"
             :accidental "sharp"}
         81 {:instrument-id "C2"
             #_#_:printed-note "G##5"
             :accidental "doublesharp"}
         82 {:instrument-id "C1"
             #_#_:printed-note "A#5"
             :accidental "sharp"}
         83 {:instrument-id "SP"
             #_#_:printed-note "A##5"
             :accidental "doublesharp"}
         84 {:instrument-id "CH"
             #_#_:printed-note "B#5"
             :accidental "sharp"}}))

(assert (apply distinct? (map :instrument-id (vals drum-notation-map1-solution))))
;; TODO stronger consistency check by combining midi note number + accidental
;(assert (apply distinct? (map :printed-note (vals drum-notation-map1-solution))))

#_
(deftest drum-notation-test
  (testing "Guitar Pro 8 mapping"
    (is (= (infer-notation-mappings drum-notation-map1)
           1))))
