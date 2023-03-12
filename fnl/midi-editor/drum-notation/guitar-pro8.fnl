(local {: notation-constraints? : instruments-map? : notation-spec? : solution?} (require :midi-editor/drum-notation/rep))

(local drum-notation-map1
  {:name "D5 Enharmonic Drum Notation"
   :root {:midi-name "D"
          :octave 4}
   ;:virtual-midi-keyboard-middle "D5"
   :instruments {"C1" {:name "Crash High"}
                 "C2" {:name "Crash Medium"}
                 "CB" {:name "Cowbell"}
                 "CH" {:name "China"}
                 "HC" {:name "Hi-Hat Closed"}
                 "HH" {:name "Hi-Hat Half"}
                 "HO" {:name "Hi-Hat Open"}
                 "HP" {:name "Hi-Hat Pedal"}
                 "K1" {:name "Kick 1"}
                 "K2" {:name "Kick 2"}
                 "RB" {:name "Ride Bell"}
                 "RE" {:name "Ride Edge"}
                 "RM" {:name "Ride Middle"}
                 "RS" {:name "Snare Rim Shot"}
                 "SC" {:name "Snare Center"}
                 "SP" {:name "Splash"}
                 "SS" {:name "Snare Stick"}
                 "T1" {:name "High Floor Tom"}
                 "T2" {:name "High Tom"}
                 "T3" {:name "Mid Tom"}
                 "T4" {:name "Low Tom"}
                 "T5" {:name "Very Low Tom"}}
   :notation-map {"D4" ["HP" "CB"]
                  "E4" ["K2"]
                  "F4" ["K1"]
                  "G4" ["T5"] 
                  "A4" ["T4"]
                  "B4" ["T3"]
                  "C5" ["RS" "SC" "SS"]
                  "D5" ["T2"]
                  "E5" ["T1"]
                  "F5" ["RM" "RB" "RE"]
                  "G5" ["HC" "HH" "HO" "C2"]
                  "A5" ["C1" "SP"]
                  "B5" ["CH"]}})

(assert (notation-spec? drum-notation-map1) "drum-notation-map1")

;; {midi-note-number info}
(local drum-notation-map1-solution
       {62 {:instrument-id "HP"
            :accidental "natural"}
        63 {:instrument-id "CB"
            :accidental "flat"}
        64 {:instrument-id "K2"
            :accidental "natural"}
        65 {:instrument-id "K1"
            :accidental "natural"}
        66 {:instrument-id "T5"
            :accidental "flat"}
        67 {:instrument-id "T4"
            :accidental "doubleflat"}
        69 {:instrument-id "T3"
            :accidental "doubleflat"}
        70 {:instrument-id "SC"
            :accidental "doubleflat"}
        71 {:instrument-id "SS"
            :accidental "flat"}
        72 {:instrument-id "SR"
            :accidental "natural"}
        73 {:instrument-id "T2"
            :accidental "flat"}
        74 {:instrument-id "T1"
            :accidental "doubleflat"}
        75 {:instrument-id "RB"
            :accidental "doubleflat"}
        76 {:instrument-id "RE"
            :accidental "flat"}
        77 {:instrument-id "RM"
            :accidental "natural"}
        78 {:instrument-id "HH"
            :accidental "flat"}
        79 {:instrument-id "HC"
            :accidental "natural"}
        80 {:instrument-id "HO"
            :accidental "sharp"}
        81 {:instrument-id "C2"
            :accidental "doublesharp"}
        82 {:instrument-id "C1"
            :accidental "sharp"}
        83 {:instrument-id "SP"
            :accidental "doublesharp"}
        84 {:instrument-id "CH"
            :accidental "sharp"}})

(assert (solution? drum-notation-map1-solution) "drum-notation-map1-solution")

{
 : drum-notation-map1
 : drum-notation-map1-solution
}
