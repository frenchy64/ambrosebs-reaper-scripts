(require-macros :fennel-test)
(local sut (require :test/midi-editor/drum-notation/test-helpers))
(deftest deep-coerce-keys-test
  (assert-eq {12 :a}
             (sut.deep-coerce-keys
               {"12" :a}))
  (assert-eq [1 2 "3"]
             (sut.deep-coerce-keys
               [1 2 "3"]))
  (assert-eq {:solution {62 {:accidental "natural" :instrument-id "HP"}
                         63 {:accidental "sharp" :instrument-id "CB"}}
              :type "solution"}
             (sut.deep-coerce-keys
               {:solution {:62 {:accidental "natural" :instrument-id "HP"}
                           :63 {:accidental "sharp" :instrument-id "CB"}} :type "solution"}))
  (assert-eq [{:args [{:midi-name "D" :octave 4} {:D4 ["HP" "CB"]}]
               :id "small"
               :result {:solution {62 {:accidental "natural" :instrument-id "HP"}
                                   63 {:accidental "sharp" :instrument-id "CB"}}
                        :type "solution"}}]
             (sut.deep-coerce-keys
               [{:args [{:midi-name "D" :octave 4} {:D4 ["HP" "CB"]}]
                 :id "small"
                 :result {:solution {:62 {:accidental "natural" :instrument-id "HP"}
                                     :63 {:accidental "sharp" :instrument-id "CB"}}
                          :type "solution"}}])))
