(ns reascript-test.drum-notation.solve
  (:require [reascript-test.drum-notation.rep :refer :all]))

;; 
(defn find-solutions [root cs]
  {:pre [(midi-coord? root)
         (notation-constraints? cs)]}
  1)
