(ns reascript-test.drum-notation.solve-test
  (:require [clojure.test :refer [deftest is testing]]
            [reascript-test.drum-notation.solve :as sut]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]))

(deftest find-solutions-test
  (is (= [(sorted-map 62 {:instrument-id "HP",
                          :accidental "natural"},
                      63 {:instrument-id "CB",
                          :accidental "flat"})]
         (sut/find-solutions
           {:midi-name "D"
            :octave 4}
           {"D4" ["HP", "CB"]})))
  (is (contains?
        (sut/find-solutions
          {:midi-name "D"
           :octave 4}
          (:notation-map gp8/drum-notation-map1))
        gp8/drum-notation-map1-solution)))
