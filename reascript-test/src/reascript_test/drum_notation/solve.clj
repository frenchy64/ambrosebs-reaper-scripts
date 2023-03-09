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

(defn allocation? [v]
  (and (map? v)
       (every? midi-number? (keys v))
       (every? instrument-id? (vals v))
       (apply distinct? (vals v))))

(defn possible-allocations-for-staff-position
  [root notated instrument-ids]
  {:pre [(midi-number? root)
         (c-major-midi-number? notated)
         (<= root notated) ;;TODO see note in enharmonic-midi-numbers
         (every? instrument-id? instrument-ids)
         (vector? instrument-ids)
         (apply distinct? instrument-ids)]
   :post [(every? allocation? %)]}
  (->> (comb/combinations
         (vec (enharmonic-midi-numbers root notated))
         (count instrument-ids))
       (mapv (fn [ns]
               (zipmap ns instrument-ids)))))

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
        ;; heuristic: try and pack notes to the left first (handled by `possible-allocations-for-staff-position`)
        ;; heuristic: trim states where two instruments are interchanged for no reason (handled by `possible-allocations-for-staff-position`)
        possible-states (map (fn [[n is]]
                               (possible-allocations-for-staff-position root-num
                                                                        n
                                                                        is))
                             num-cs)
        all-states (apply comb/cartesian-product possible-states)
        all-solutions (keep (fn [state]
                              (when (apply distinct? (map keys state))
                                (into (sorted-map)
                                      (mapcat (fn [allocation]
                                                {:pre [(allocation? allocation)]}
                                                (->> allocation
                                                     (map (fn [[midi-num instrument-id]]
                                                            {:pre [(instrument-id? instrument-id)
                                                                   (midi-number? midi-num)]}
                                                            {midi-num
                                                             {:instrument-id instrument-id
                                                              :accidental (accidental-relative-to
                                                                            (get-in instrument->allowed-midi-numbers [instrument-id :notated-number])
                                                                            midi-num)}})))))
                                      state)))
                            all-states)]
    all-solutions))
