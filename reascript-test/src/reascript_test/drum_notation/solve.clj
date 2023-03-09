(ns reascript-test.drum-notation.solve
  (:require [reascript-test.drum-notation.rep :refer :all]
            [clojure.math.combinatorics :as comb]))

(defn enharmonic-midi-numbers
  "Return the possible midi numbers representing enharmonic
  respellings for the given C major note."
  [root n]
  {:pre [(midi-number? root)
         (<= root n)
         (c-major-midi-number? n)]}
  (into (sorted-set)
        (range (max root (- n 2))
               (+ n 3))))

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

;; 
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
        max-midi-number (apply max (mapcat :allowed-midi-numbers (vals instrument->allowed-midi-numbers)))
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
