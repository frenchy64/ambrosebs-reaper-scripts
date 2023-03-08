(ns reascript-test.drum-notation-test
  (:require [clojure.test :refer [deftest is testing]]
            [reascript-test.drum-notation :as sut]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]))

(deftest drum-notation-test
  (testing "Guitar Pro 8 mapping"
    (is (= (sut/infer-notation-mappings gp8/drum-notation-map1)
           1))))
