#!/usr/bin/env bb

(require '[cheshire.core :as json])

(def test-cases
  {:midi-editor.drum-notation.solve/find-solution
   [{:id :small
     :result {:type :solution
              :solution {62 {:instrument-id "HP" :accidental "natural"}
                         63 {:instrument-id "CB" :accidental "sharp"}}}
     :args [{:midi-name "D"
             :octave 4}
            {"D4" ["HP" "CB"]}]}]})

(doseq [[tests-id cases] test-cases]
  (assert (vector? cases))
  (assert (seq cases))
  (assert (every? (comp keyword? :id) cases))
  (assert (apply distinct? (map :id cases)))
  (assert (every? :result cases))
  (assert (every? (comp vector? :args) cases)))

(spit "test-cases.json"
      (json/generate-string test-cases {:pretty true}))
