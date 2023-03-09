(ns reascript-test.drum-notation.reorder-test
  (:require [clojure.test :refer [deftest is testing]]
            [reascript-test.drum-notation.reorder :as sut]
            [reascript-test.drum-notation.rep :refer :all]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]
            [reascript-test.drum-notation.pretty :refer [pretty-solution]]
            [reascript-test.drum-notation.test-helpers :as th]))

(deftest reorder-solution-test
  (is (= {:type :solution
          :solution (sorted-map 62 {:instrument-id "CB", :accidental "natural"}
                                63 {:instrument-id "HP", :accidental "sharp"})}
         (sut/reorder-solution
           (sorted-map 62 {:instrument-id "HP", :accidental "natural"}
                       63 {:instrument-id "CB", :accidental "sharp"})
           62 63)
         (sut/reorder-solution
           (sorted-map 62 {:instrument-id "HP", :accidental "natural"}
                       63 {:instrument-id "CB", :accidental "sharp"})
           63 62)))
  (is (= {:type :solution
          :solution (sorted-map 63 {:instrument-id "CB", :accidental "sharp"}
                                64 {:instrument-id "HP", :accidental "doublesharp"})}
         (sut/reorder-solution
           (sorted-map 62 {:instrument-id "HP", :accidental "natural"}
                       63 {:instrument-id "CB", :accidental "sharp"})
           62 64))))
