(ns reascript-test.drum-notation.reorder
  (:require [reascript-test.drum-notation.rep :refer :all]
            [clojure.set :as set]))

(defn reorder-solution
  [root-num solution from to]
  {:pre [(solution? solution)
         ((every-pred midi-number?) root-num from to)]
   :post [(solution-or-error? %)]}
  (let [from-info (solution from)]
    (if-not from-info
      {:type :error
       :data {:from from}
       :message "Nothing to move from."}
      (let [from-notated (notated-midi-num-for from (:accidental from-info))
            to-info (solution to)
            to-notated (when to-info
                         (notated-midi-num-for to (:accidental to-info)))]
        (if (some-> from-notated (not= to-info))
          {:type :error
           :data {:from from-notated :to to-notated}
           :message "Notes much be notated on the same staff line"}
          (assoc solution
                 from (into to-info (select-keys from-info [:accidental]))
                 to (into from-info (select-keys to-info [:accidental]))))))))
