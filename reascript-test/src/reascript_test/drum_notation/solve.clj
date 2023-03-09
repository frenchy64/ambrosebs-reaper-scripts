(ns reascript-test.drum-notation.solve
  (:require [reascript-test.drum-notation.rep :refer :all]
            [clojure.math.combinatorics :as comb]))


(defn enharmonic-midi-numbers
  "Return the possible midi numbers representing enharmonic
  respellings for the given C major note."
  [root notated]
  {:pre [(midi-number? root)
         ;;TODO what does the root-num mean? is it the lowest note
         ;; than can be written on the staff, the lowest note allocatable
         ;; to an instrument, or both?
         (<= root notated)
         (c-major-midi-number? notated)]}
  (into (sorted-set)
        (range (max root (- notated 2))
               (+ notated 3))))

(defn solution-score [soln]
  {:pre [(solution? soln)]}
  (->> (vals soln)
       (map :accidental)
       frequencies
       (map (fn [[accidental n]]
              (* n (case accidental
                     "natural" 0
                     ("flat" "sharp") 1
                     ("doubleflat" "doublesharp") 2))))
       (apply +)))

(defn possible-allocations-for-staff-position
  [root notated instrument-ids]
  {:pre [(midi-number? root)
         (c-major-midi-number? notated)
         (<= root notated) ;;TODO see note in enharmonic-midi-numbers
         (every? instrument-id? instrument-ids)
         (vector? instrument-ids)
         (apply distinct? instrument-ids)]}
  (let [allowed-nums (enharmonic-midi-numbers root notated)]
    (comb/combinations
      (map )
      (count instrument-ids))
    ))

(defn find-solutions [root-coord str-cs]
  {:pre [(midi-coord? root-coord)
         (notation-constraints? str-cs)]}
  (let [root-num (midi-coord->number root-coord)
        num-cs (coord-str-constraints->midi-number-constraints str-cs)
        instrument->allowed-midi-numbers (into {} (map (fn [[n is]]
                                                         (zipmap is (repeat
                                                                      {:notated-number n
                                                                       :allowed-midi-numbers (enharmonic-midi-numbers root-num n)}))))
                                               num-cs)
        possible-states (into [] (mapcat (fn [[n is]]
                                           (possible-allocations-for-staff-position root-num
                                                                                    n
                                                                                    is)))
                              num-cs)
        max-midi-number (apply max (mapcat :allowed-midi-numbers (vals instrument->allowed-midi-numbers)))
        ;; heuristic: try and pack notes to the left first
        ;; heuristic: trim states where two instruments are interchanged for no reason
        all-states (apply comb/cartesian-product
                          (map (fn [[id {:keys [allowed-midi-numbers]}]]
                                 {:pre [(instrument-id? id)
                                        (every? midi-number? allowed-midi-numbers)]}
                                 (mapv #(vector id %) allowed-midi-numbers))
                               instrument->allowed-midi-numbers))
        all-solutions (keep (fn [solution]
                              (when (apply distinct? (map second solution))
                                (into (sorted-map) (map (fn [[k v]] {v {:instrument-id k
                                                                        :accidental (accidental-relative-to
                                                                                      (get-in instrument->allowed-midi-numbers [k :notated-number])
                                                                                      v)}}))
                                      solution)))
                            all-states)]
    (sort-by solution-score all-solutions)))
