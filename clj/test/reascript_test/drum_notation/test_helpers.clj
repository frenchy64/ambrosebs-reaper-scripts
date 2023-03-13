(ns reascript-test.drum-notation.test-helpers
  (:require [clojure.data :as data]
            [clojure.string :as str]
            [clojure.test :refer [is testing]]
            [clojure.pprint :refer [pprint]]
            [cheshire.core :as json]))

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

(def common-json (-> (slurp "../generated/test-cases.json")
                     json/parse-string))
(defn test-common-cases [tests-id f & {:keys [coerce-result coerce-args]
                                       :or {coerce-result identity
                                            coerce-args identity}}]
  (let [cases (get common-json tests-id)]
    (assert (seq cases) (str "Bad tests id: " tests-id))
    (doseq [{:strs [id result args]} cases
            :let [result (coerce-result result)
                  args (coerce-args args)]]
      (testing id
        (is (= result (apply f args))
            (format "(%s %s)" tests-id (str/join " " args)))))))
