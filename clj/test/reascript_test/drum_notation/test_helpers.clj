(ns reascript-test.drum-notation.test-helpers
  (:require [clojure.data :as data]
            [clojure.string :as str]
            [clojure.test :refer [is]]
            [clojure.pprint :refer [pprint]]))

(defmacro is-string= [s1 s2]
  `(let [s1# ~s1
         s2# ~s2]
     (is (= s1# s2#)
         (pr-str (data/diff (str/split-lines s1#)
                            (str/split-lines s2#))))))

(defn str->str-join-expr [s]
  {:pre [(string? s)]}
  (pprint (list 'th/join-lines (str/split-lines s))))

(defn join-lines [ss]
  (str/join "\n" ss))

(defn strs->str-join-exprs [ss]
  {:pre [(every? string? ss)]}
  (pprint (list 'mapv 'th/join-lines (mapv str/split-lines ss))))
