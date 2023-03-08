(ns reascript-test.drum-notation.pretty
  (:require [clojure.data :as data]
            [reascript-test.drum-notation.rep :refer :all]
            [clojure.string :as str]))

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
