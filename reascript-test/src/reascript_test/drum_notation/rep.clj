(ns reascript-test.drum-notation.rep
  (:require [clojure.data :as data]
            [clojure.string :as str]))

(def midi-names ["C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B"])
(def midi-names-set (set midi-names))
(defn midi-name? [n]
  (contains? midi-names-set n))

(assert (apply distinct? midi-names))
(assert (= 12 (count midi-names)))

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

(defn parse-midi-name [s]
  (let [trailing (Integer/parseInt (nth s (dec (count s))))
        negative? (= \- (nth s (- (count s) 2)))
        octave (cond-> trailing
                 negative? -)
        nme (subs s 0 (cond-> (dec (count s))
                        negative? dec))]
    (->midi-coord nme octave)))

(defn midi-number->coord [n]
  {:pre [(midi-number? n)]
   :post [(midi-coord? %)]}
  (->midi-coord (nth midi-names (mod n (count midi-names)))
                (+ lowest-midi-octave
                   (quot n (count midi-names)))))

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

(defn instruments-map? [m]
  (and (map? m)
       (every? instrument-id? (keys m))
       (every? (every-pred map? (comp string? :name))
               (vals m))))

(defn notation-constraints? [m]
  (and (map? m)
       (every? instrument-id? (keys m))
       (every? (every-pred vector?
                           #(every? instrument-id? %))
               (vals m))))

(defn notation-spec? [m]
  (and (map? m)
       (string? (:name m))
       (midi-coord? (:root m))
       (instruments-map? (:instruments m))
       (notation-constraints? (:notation-map m))))

(defn solution? [m]
  (and (map? m)
       (sorted? m)
       (pos? (count m))
       (every? midi-number? (keys m))
       (apply distinct? (map :instrument-id (vals m)))
       ;; TODO stronger consistency check by combining midi note number + accidental
       ;(apply distinct? (map :printed-note (vals m)))
       (every? (every-pred map?
                           (comp instrument-id? :instrument-id)
                           (comp reaper-accidental? :accidental))
               (vals m))))
