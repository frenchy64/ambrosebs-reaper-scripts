(ns reascript-test.drum-notation.rep
  (:require [clojure.data :as data]
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

(defn midi-number->coord [n]
  {:pre [(midi-number? n)]
   :post [(midi-coord? %)]}
  (->midi-coord (nth midi-names (mod n (count midi-names)))
                (+ lowest-midi-octave
                   (quot n (count midi-names)))))

(defn solution? [m]
  (and (map? m)
       (sorted? m)
       (pos? (count m))
       (every? midi-number? (keys m))
       (every? (every-pred :instrument-id :accidental) (vals m))))
