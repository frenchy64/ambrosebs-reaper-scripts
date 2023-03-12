(ns reascript-test.drum-notation.solve
  (:require [reascript-test.drum-notation.rep :refer :all]
            [clojure.set :as set]))

(defn enharmonic-midi-numbers
  "Return the possible midi numbers representing enharmonic
  respellings for the given C major note."
  [root notated]
  {:pre [(midi-number? root)
         ;;TODO what does the root-num mean? is it the lowest note
         ;; than can be written on the staff, the lowest note allocatable
         ;; to an instrument, or both?
         (<= root notated)
         (c-major-midi-number? notated)]
   :post [(vector? %)
          (every? midi-number? %)]}
  (vec (range (max root (- notated 2))
              (+ notated 3))))

(defn find-solution [root-coord str-cs]
  {:pre [(midi-coord? root-coord)
         (notation-constraints? str-cs)]
   :post [(solution-or-error? %)]}
  (let [root-num (midi-coord->number root-coord)
        num-cs (coord-str-constraints->midi-number-constraints str-cs)
        instrument->notated-num (mapcat (fn [[n is]]
                                          (map vector is (repeat n)))
                                        num-cs)]
    (loop [solution (sorted-map)
           [[id notated-num] & instrument->notated-num] instrument->notated-num]
      (when (seq solution)
        (assert (solution? solution) (pr-str solution)))
      (assert (instrument-id? id) (pr-str id))
      (assert (midi-number? notated-num))
      (let [next-free-midi-num (if (seq solution)
                                 (-> solution rseq first key inc)
                                 root-num)]
        (if-not (midi-number? next-free-midi-num)
          {:type :error
           :data {:instrument-clashes #{id}}
           :message "Could not fit instrument into MIDI range"}
          (let [allocated-midi-num (some #(when (<= next-free-midi-num %)
                                            %)
                                         (enharmonic-midi-numbers root-num notated-num))]
            (if-not allocated-midi-num
              {:type :error
               :data {:instrument-clashes #{id (-> solution rseq first val :instrument-id)}}
               :message "Insufficient room for instruments"})
            (let [solution (assoc solution allocated-midi-num
                                  {:instrument-id id
                                   :accidental (accidental-relative-to notated-num allocated-midi-num)})]
              (if instrument->notated-num
                (recur solution instrument->notated-num)
                {:type :solution
                 :solution solution}))))))))
