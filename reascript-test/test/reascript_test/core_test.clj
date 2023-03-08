(ns reascript-test.core-test
  (:require [clojure.test :refer :all]
            [reascript-test.core :refer :all]
            [clojure.data :as data]
            [clojure.pprint :refer [pprint] :as pp]
            [clojure.string :as str]))

#_
(deftest drum-notation-test
  (testing "Guitar Pro 8 mapping"
    (is (= (infer-notation-mappings drum-notation-map1)
           1))))
