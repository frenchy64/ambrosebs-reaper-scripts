(ns reascript-test.core-test
  (:require [clojure.test :refer :all]
            [reascript-test.core :refer :all]
            [clojure.data :as data]
            [clojure.pprint :refer [pprint] :as pp]
            [clojure.string :as str]))

;;;;;;;;;;;;;;;;;;;;;;
;; MIDI representation
;;;;;;;;;;;;;;;;;;;;;;

(def midi-names ["C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B"])
(let [name-set (set midi-names)]
  (defn midi-name? [n]
    (contains? name-set n)))

;; 0 => C-1
(def lowest-midi-name (first midi-names))
(def lowest-midi-octave -1)
(def highest-midi-octave 9)
(def lowest-midi-note 0)
(def highest-midi-note 127)

(defn midi-number? [n]
  (and (nat-int? n)
       (<= lowest-midi-note n highest-midi-note)))

(defn midi-octave? [o]
  (<= lowest-midi-octave
      o
      highest-midi-octave))

(defn midi-coord? [{:keys [midi-name octave] :as v}]
  (and (map v)
       (= 2 (count v))
       (midi-name? midi-name)
       (midi-octave? octave)))

(defn ->midi-coord [midi-name octave]
  {:pre [(midi-name? midi-name)
         (midi-octave? octave)]
   :post [(midi-coord? %)]}
  {:midi-name midi-name
   :octave octave})

(defn midi-coord-str [{:keys [midi-name octave] :as v}]
  {:pre [(midi-coord? v)]}
  (str midi-name octave))

(deftest midi-coord-str-test
  (is (= "C-1" (midi-coord-str (->midi-coord "C" -1))))
  (is (= "C0" (midi-coord-str (->midi-coord "C" 0))))
  (is (= "G9" (midi-coord-str (->midi-coord "G" 9)))))

(defn midi-number->coord [n]
  {:pre [(midi-number? n)]
   :post [(midi-coord? %)]}
  (->midi-coord (nth midi-names (mod n (count midi-names)))
                (+ lowest-midi-octave
                   (quot n (count midi-names)))))

(deftest midi-number->coord-test
  (is (= "C-1" (midi-coord-str (midi-number->coord 0))))
  (is (= "B1" (midi-coord-str (midi-number->coord 35))))
  (is (= "G9" (midi-coord-str (midi-number->coord 127))))
  (is (thrown? AssertionError (midi-coord-str (midi-number->coord -1))))
  (is (thrown? AssertionError (midi-coord-str (midi-number->coord 128)))))

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

(defn solution? [m]
  (and (map? m)
       (sorted? m)
       (pos? (count m))
       (every? midi-number? (keys m))
       (every? (every-pred :instrument-id :accidental) (vals m))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASCII printing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def example-piano-ascii
  (str/join "\n"
            ["_____________________________"
             "|  | | | |  |  | | | | | |  |"
             "|  | | | |  |  | | | | | |  |"
             "|  | | | |  |  | | | | | |  |"
             "|  |_| |_|  |  |_| |_| |_|  |"
             "|   |   |   |   |   |   |   |"
             "|___|___|___|___|___|___|___|"]))

(def example-piano-C->E
  (str/join "\n"
            (map #(subs % 0 13)
                 (str/split-lines example-piano-ascii))))

(def example-piano-E->B
  (str/join "\n"
            (map #(subs % 12)
                 (str/split-lines example-piano-ascii))))

(comment
  (println example-piano-C->E)
  (println example-piano-E->B)
  )


;; https://asciiart.website/index.php?art=music/pianos
;; by Alexander Craxton
(def piano-ascii-template
  (str/join "\n"
            ["_HHH_________________________"
             "|1 |2|3|4|5 |6 |7|8|9|0|i|j |"
             "|  |C| |D|  |  |F| |G| |A|  |"
             "|  |C| |D|  |  |F| |G| |A|  |"
             "|  |_| |_|  |  |_| |_| |_|  |"
             "|cc |dd |ee |ff |gg |aa |bb |"
             "|___|___|___|___|___|___|___|"]))

(def note-name->piano-template-accidental
  {"C"  \1
   "C#" \2
   "D"  \3
   "D#" \4
   "E"  \5
   "F"  \6
   "F#" \7
   "G"  \8
   "G#" \9
   "A"  \0
   "A#" \i
   "B"  \j})

(def note-name->piano-template-instrument-id
  {"C"  \c
   "C#" \C
   "D"  \d
   "D#" \D
   "E"  \e
   "F"  \f
   "F#" \F
   "G"  \g
   "G#" \G
   "A"  \a
   "A#" \A
   "B"  \b})

(assert (= (set midi-names)
           (set (keys note-name->piano-template-accidental))
           (set (keys note-name->piano-template-instrument-id))))

(def all-piano-template-variables
  (-> (set (vals note-name->piano-template-accidental))
      (into (vals note-name->piano-template-instrument-id))
      (conj \H)))

(def piano-ascii-kw-template
  (into [] (comp (map (fn [c]
                        (cond-> c
                          (all-piano-template-variables c) (-> str keyword))))
                 (partition-by keyword?)
                 (mapcat (fn [ps]
                           (cond-> ps
                             (char? (first ps)) (->> (apply str) list)))))
        piano-ascii-template))

(deftest piano-ascii-kw-template-test
  (is (= ["_" :H :H :H "_________________________\n|"
          :1 " |" :2 "|" :3 "|" :4 "|" :5 " |" :6 " |" :7 "|" :8 "|" :9 "|" :0 "|" :i "|" :j " |\n|  |"
          :C "| |" :D "|  |  |" :F "| |" :G "| |" :A "|  |\n|  |" :C "| |" :D "|  |  |" :F "| |" :G "| |" :A
          "|  |\n|  |_| |_|  |  |_| |_| |_|  |\n|" :c :c " |" :d :d " |" :e :e " |" :f :f " |" :g :g " |"
          :a :a " |" :b :b " |\n|___|___|___|___|___|___|___|"]
         piano-ascii-kw-template)))

(defn piano-ascii-instantiation? [replacements]
  (and (map? replacements)
       (every? char? (keys replacements))
       (every? #(every? string? %) (vals replacements))))

(defn instantiate-piano-ascii [replacements]
  {:pre [(piano-ascii-instantiation? replacements)]}
  (let [state (atom replacements)]
    (reduce (fn [acc template]
              (str acc
                   (if (simple-keyword? template)
                     (let [k (first (name template))
                           _ (assert (char? k) template)
                           [prev-state] (swap-vals! state update k next)
                           subst (-> prev-state (get k) first)]
                       (when subst (assert (string? subst) (pr-str (class subst))))
                       (or subst " "))
                     template)))
            ""
            piano-ascii-kw-template)))

(deftest instantiate-piano-ascii-test
  (is (= example-piano-ascii
         (instantiate-piano-ascii {\H ["_" "_" "_"]})))
  (is (str/includes? (instantiate-piano-ascii {\H ["_" "_" "_"]
                                               \A ["𝄪"]})
                     "𝄪")))

(defn piano-note-annotations? [annotations]
  (and (map? annotations)
       (every? midi-name? (keys annotations))
       (every? (every-pred map?
                           (comp instrument-id? :instrument-id)
                           (comp reaper-accidental? :accidental))
               (vals annotations))))

(defn ->piano-ascii [octave annotations]
  {:pre [(piano-note-annotations? annotations)
         (midi-octave? octave)]}
  (let [padded-C-octave (-> ["C"] ;; can't be in template since C is a template variable
                            (into (mapv str (str octave))))
        padded-C-octave (cond-> padded-C-octave
                          (= 2 (count padded-C-octave)) (conj "_"))
        _ (assert (= 3 (count padded-C-octave)) octave)
        replacements (into {\H padded-C-octave}
                           (map (fn [[note-name {:keys [instrument-id accidental] :as info}]]
                                  {:pre [(midi-name? note-name)
                                         (instrument-id? instrument-id)
                                         (reaper-accidental? accidental)
                                         (= 2 (count info))]}
                                  (-> ;; C => {\c ["K" "1"]}
                                      {(get note-name->piano-template-instrument-id note-name)
                                       ;; TODO allow unicode in instrument-id. figure out how to split by unicode char.
                                       (mapv str instrument-id)}
                                      (into (when accidental
                                              (let [astr (get reaper-accidental->string accidental)
                                                    _ (assert astr accidental)
                                                    accidental-id (get note-name->piano-template-accidental note-name)]
                                                (assert accidental-id note-name)
                                                ;; flat => ["1" "𝄫"]
                                                {accidental-id [astr]}))))))
                           annotations)]
    (instantiate-piano-ascii replacements)))

(defn- str->str-join-expr [s]
  (list 'str/join "\n" (str/split-lines s)))

(defmacro is-string= [s1 s2]
  `(let [s1# ~s1
         s2# ~s2]
     (is (= s1# s2#)
         (pr-str (data/diff (str/split-lines s1#)
                            (str/split-lines s2#))))))

(deftest ->piano-ascii-test
  (is-string= (str/join "\n"
                        ["_C4__________________________"
                         "|  | | | |  |  | | | |♭| |  |"
                         "|  | | | |  |  | | | | | |  |"
                         "|  | | | |  |  | | | | | |  |"
                         "|  |_| |_|  |  |_| |_| |_|  |"
                         "|   |   |   |   |   |K2 |   |"
                         "|___|___|___|___|___|___|___|"])
              (let [r (->piano-ascii 4 {"A" {:instrument-id "K2"
                                             :accidental "flat"}})] 
                (with-out-str
                  (print r))))
  (is-string= (str/join "\n"
                        ["_C-1_________________________"
                         "|  |𝄪|♮| |  |  | | | |♭|𝄫|♭ |"
                         "|  |D| | |  |  | | | | |K|  |"
                         "|  |2| | |  |  | | | | |1|  |"
                         "|  |_| |_|  |  |_| |_| |_|  |"
                         "|   |EE |   |   |   |K2 |C2 |"
                         "|___|___|___|___|___|___|___|"])
              (let [r (->piano-ascii -1 {"A" {:instrument-id "K2"
                                              :accidental "flat"}
                                         "A#" {:instrument-id "K1"
                                               :accidental "doubleflat"}
                                         "B" {:instrument-id "C2"
                                              :accidental "flat"}
                                         "C#" {:instrument-id "D2"
                                               :accidental "doublesharp"}
                                         "D" {:instrument-id "EE"
                                              :accidental "natural"}})] 
                (with-out-str
                  (print r)))))

(assert (apply distinct? midi-names))
(assert (= 12 (count midi-names)))

(defn pretty-solution [soln]
  {:pre [(solution? soln)]}
  (let [;; TODO include more octaves if enharmonic respellings spill outside these bounds
        ;; check for Cb, Cbb, B#, B##
        starting-octave (-> soln first key midi-number->coord :octave)
        ending-octave (-> soln rseq first key midi-number->coord :octave)
        annotations (update-keys soln #(-> % midi-number->coord :midi-name))]
    (assert (= starting-octave ending-octave) "NYI")
    (->piano-ascii starting-octave annotations)))

(deftest pretty-solution-test
  (is (= (str/join "\n"
                   ["_C4__________________________"
                    "|  | |♮|♭|♮ |♮ | | | | | |  |"
                    "|  | | |C|  |  | | | | | |  |"
                    "|  | | |B|  |  | | | | | |  |"
                    "|  |_| |_|  |  |_| |_| |_|  |"
                    "|   |HP |K2 |K1 |   |   |   |"
                    "|___|___|___|___|___|___|___|"])
         (pretty-solution
           (into (sorted-map)
                 (select-keys drum-notation-map1-solution [62 63 64 65]))))))

(assert (apply distinct? (map :instrument-id (vals drum-notation-map1-solution))))
;; TODO stronger consistency check by combining midi note number + accidental
;(assert (apply distinct? (map :printed-note (vals drum-notation-map1-solution))))

#_
(deftest drum-notation-test
  (testing "Guitar Pro 8 mapping"
    (is (= (infer-notation-mappings drum-notation-map1)
           1))))
