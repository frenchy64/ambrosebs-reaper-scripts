#!/usr/bin/env bb

(require '[clojure.test :as t]
         '[babashka.classpath :as cp])

(cp/add-classpath "src:test")

(def test-nses
  '[reascript-test.drum-notation-test
    reascript-test.drum-notation.pretty-test
    reascript-test.drum-notation.reorder-test
    reascript-test.drum-notation.rep-test
    reascript-test.drum-notation.solve-test])

(apply require test-nses)

(def test-results (apply t/run-tests test-nses))

(def failures-and-errors
  (let [{:keys [fail error]} test-results]
    (+ fail error)))

(System/exit (max 1 failures-and-errors))
