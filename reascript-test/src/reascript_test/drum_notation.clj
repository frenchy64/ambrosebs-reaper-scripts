(ns reascript-test.drum-notation
  (:require [reascript-test.drum-notation.rep :refer :all]
            [reascript-test.drum-notation.solve :as solve]))

(defn infer-notation-mappings [spec]
  {:pre [(notation-spec? spec)]}
  (solve/find-solution (:root spec)
                       (:notation-map spec)))
