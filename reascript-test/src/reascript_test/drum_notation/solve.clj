(ns reascript-test.drum-notation.solve
  (:require [reascript-test.drum-notation.rep :refer :all]))

;; 
(defn find-solutions [root-coord cs]
  {:pre [(midi-coord? root-coord)
         (notation-constraints? cs)]}
  (let [root-num (midi-coord->number root-coord)
        ]
    ))
