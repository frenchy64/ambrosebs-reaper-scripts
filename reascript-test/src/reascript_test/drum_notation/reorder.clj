(ns reascript-test.drum-notation.reorder
  (:require [reascript-test.drum-notation.rep :refer :all]
            [clojure.set :as set]))

(defn reorder-solution
  [solution from to]
  {:pre [(solution? solution)
         ((every-pred midi-number?) from to)]
   :post [(solution-or-error? %)]}
  (let [from-info (solution from)]
    (if-not from-info
      {:type :error
       :data {:from from}
       :message "Nothing to move from."}
      (let [from-notated (notated-midi-num-for from (:accidental from-info))
            to-info (solution to)]
        (if-not to-info
          (if-not (enharmonically-respellable? from-notated to)
            {:type :error
             :data {:from from-notated :to to}
             :message "Cannot move note outside of its staff line"}
            {:type :solution
             :solution (-> solution
                           (dissoc from)
                           (assoc to (assoc from-info :accidental (accidental-relative-to from-notated to))))})
          (let [to-notated (notated-midi-num-for to (:accidental to-info))]
            (if (not= from-notated to-notated)
              {:type :error
               :data {:from from-notated :to to-notated}
               :message "Notes much be notated on the same staff line"}
              {:type :solution
               :solution (assoc solution
                                from (into to-info (select-keys from-info [:accidental]))
                                to (into from-info (select-keys to-info [:accidental])))})))))))
