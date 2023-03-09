(ns reascript-test.drum-notation.solve
  (:require [reascript-test.drum-notation.rep :refer :all]
            [clojure.math.combinatorics :as comb]
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

(defn allocation? [v]
  (and (map? v)
       (every? midi-number? (keys v))
       (every? instrument-id? (vals v))
       (apply distinct? (vals v))))

(defn possible-allocations-for-staff-position
  [previous-allocations root notated instrument-ids]
  {:pre [(every? allocation? previous-allocations)
         (midi-number? root)
         (c-major-midi-number? notated)
         (<= root notated) ;;TODO see note in enharmonic-midi-numbers
         (every? instrument-id? instrument-ids)
         (vector? instrument-ids)
         (apply distinct? instrument-ids)]
   :post [(every? allocation? %)]}
  (let [;; heuristic: trim states that contain allocations that are impossible based on the previous note's possible allocations
        impossible-allocations (when (seq previous-allocations)
                                 ;; TODO if the NEXT allocation is very sparse, then don't bother adding doublesharp, it's probably useless
                                 (let []
                                   (not-empty
                                     (-> ;; if the previous allocation always chooses a particular midi note, cull allocations that include that note
                                         (apply set/intersection (map (comp set keys) previous-allocations))
                                         ))))
        possible-midi-nums (enharmonic-midi-numbers root notated)
        n-instruments (count instrument-ids)]
    ;; heuristic: try and pack notes to the left first
    (cond
      ;; pack initial allocation to the left (if they fit at all)
      (empty? previous-allocations) (cond-> [] 
                                      (<= n-instruments (count possible-midi-nums))
                                      (conj (zipmap possible-midi-nums instrument-ids)))
      :else
      (if-some [always-available (let [previous-min (apply min (mapcat keys previous-allocations))]
                                   (when (= 1 n-instruments)
                                     (some #(when (and (<= previous-min %)
                                                       (not-any? (fn [allocation]
                                                                   (allocation %))
                                                                 previous-allocations))
                                              %)
                                           possible-midi-nums)))]
        ;; choose left-most slot that's always available and not less than the minimum of the previous allocation
        [{always-available (first instrument-ids)}]
        (into [] (keep (fn [ns]
                         (when (or (not impossible-allocations)
                                   (empty? (set/intersection (set ns) impossible-allocations)))
                           (zipmap ns instrument-ids))))
              ;; heuristic: trim states where two instruments are interchanged for no reason
              (comb/combinations
                possible-midi-nums
                n-instruments))))))

(defn possible-allocations
  [root num-cs]
  {:pre [(midi-number? root)
         (midi-number-constraints? num-cs)]
   :post [(vector? %)
          (every? (every-pred vector? #(every? allocation? %))
                  %)]}
  (reduce (fn [acc [n is]]
            (conj acc
                  (possible-allocations-for-staff-position (peek acc) root n is)))
          [] num-cs))

(defn find-solutions [root-coord str-cs]
  {:pre [(midi-coord? root-coord)
         (notation-constraints? str-cs)]}
  (let [root-num (midi-coord->number root-coord)
        num-cs (coord-str-constraints->midi-number-constraints str-cs)
        instrument-set (into #{} cat (vals num-cs))
        instrument->notated-num (into {} (map (fn [[n is]]
                                                (zipmap is (repeat n))))
                                      num-cs)
        possible-states (possible-allocations root-num num-cs)
        all-states (apply comb/cartesian-product possible-states)
        all-solutions (keep (fn [state]
                              (when (apply distinct? (mapcat keys state))
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
                                                                            (instrument->notated-num instrument-id)
                                                                            midi-num)}})))))
                                      state)))
                            all-states)]
    all-solutions))
