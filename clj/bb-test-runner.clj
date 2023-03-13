#!/usr/bin/env bb

(require '[clojure.test :as t]
         '[babashka.classpath :as cp])

(cp/add-classpath "src:test")

(def test-namespaces
  '{"test/reascript_test/drum_notation_test.clj" reascript-test.drum-notation-test
    "test/reascript_test/drum_notation/pretty_test.clj" reascript-test.drum-notation.pretty-test
    "test/reascript_test/drum_notation/reorder_test.clj" reascript-test.drum-notation.reorder-test
    "test/reascript_test/drum_notation/rep_test.clj" reascript-test.drum-notation.rep-test
    "test/reascript_test/drum_notation/solve_test.clj" reascript-test.drum-notation.solve-test})

(let [fs (into #{}
               (keep (fn [^File f]
                       (when (.isFile f)
                         (.getPath f))))
               (file-seq (File. "test")))
      exclusions #{"test/reascript_test/drum_notation/test_helpers.clj"}
      missing (set/difference fs (into exclusions (keys test-namespaces)))]
  (assert (empty? missing)
          (str "Don't forget to add these namespaces to clj/bb-test-runner.clj: "
               (pr-str missing))))

(apply require (vals test-namespaces))

(def test-results
  (apply t/run-tests (vals test-namespaces)))

(def failures-and-errors
  (let [{:keys [fail error]} test-results]
    (+ fail error)))

(System/exit (min 1 failures-and-errors))
