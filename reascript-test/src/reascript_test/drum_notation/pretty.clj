(ns reascript-test.drum-notation.pretty
  (:require [clojure.data :as data]
            [reascript-test.drum-notation.rep :refer :all]
            [clojure.string :as str]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASCII printing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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


(defn pretty-solution [soln]
  {:pre [(solution? soln)]}
  (let [;; TODO include more octaves if enharmonic respellings spill outside these bounds
        ;; check for Cb, Cbb, B#, B##
        starting-octave (-> soln first key midi-number->coord :octave)
        ending-octave (-> soln rseq first key midi-number->coord :octave)
        split-piano-octaves (mapv (fn [octave]
                                    (let [annotations (into {} (keep (fn [[k v]]
                                                                       (let [coord (midi-number->coord k)]
                                                                         (when (= octave (:octave coord))
                                                                           {(:midi-name coord) v}))))
                                                            soln)]
                                      (str/split-lines (->piano-ascii octave annotations))))
                                  (range starting-octave (inc ending-octave)))
        nlines (-> split-piano-octaves first count)]
    (str/join "\n"
              (map (fn [line]
                     (apply str (concat (map (fn [ss]
                                               (let [s (nth ss line)]
                                                 (subs s 0 (dec (count s)))))
                                             (pop split-piano-octaves))
                                        (nth (peek split-piano-octaves) line))))
                   (range nlines)))))
