(ns reascript-test.drum-notation-test
  (:require [clojure.test :refer [deftest is testing]]
            [reascript-test.drum-notation :as sut]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]
            [reascript-test.drum-notation.pretty :refer [pretty-solution]]
            [reascript-test.drum-notation.test-helpers :as th]))

(comment
  (th/str->str-join-expr (pretty-solution gp8/drum-notation-map1-solution))
(th/join-lines
 ["_C4__________________________C5__________________________C6__________________________"
  "|  | |♮|♭|♮ |♮ |♭|𝄫| |𝄫|𝄫|♭ |♮ |♭|𝄫|𝄫|♭ |♮ |♭|♮|♯|𝄪|♯|𝄪 |♯ | | | |  |  | | | | | |  |"
  "|  | | |C|  |  |T| | | |S|  |  |T| |R|  |  |H| |H| |C|  |  | | | |  |  | | | | | |  |"
  "|  | | |B|  |  |5| | | |C|  |  |2| |B|  |  |H| |O| |1|  |  | | | |  |  | | | | | |  |"
  "|  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |"
  "|   |HP |K2 |K1 |T4 |T3 |SS |SR |T1 |RE |RM |HC |C2 |SP |CH |   |   |   |   |   |   |"
  "|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|"])
  )

(deftest drum-notation-test
  (testing "Guitar Pro 8 mapping"
    (is (= {:type :solution,
            :solution
            {62 {:instrument-id "HP", :accidental "natural"},
             63 {:instrument-id "CB", :accidental "sharp"},
             64 {:instrument-id "K2", :accidental "natural"},
             65 {:instrument-id "K1", :accidental "natural"},
             66 {:instrument-id "T5", :accidental "flat"},
             67 {:instrument-id "T4", :accidental "doubleflat"},
             69 {:instrument-id "T3", :accidental "doubleflat"},
             70 {:instrument-id "RS", :accidental "doubleflat"},
             71 {:instrument-id "SC", :accidental "flat"},
             72 {:instrument-id "SS", :accidental "natural"},
             73 {:instrument-id "T2", :accidental "flat"},
             74 {:instrument-id "T1", :accidental "doubleflat"},
             75 {:instrument-id "RM", :accidental "doubleflat"},
             76 {:instrument-id "RB", :accidental "flat"},
             77 {:instrument-id "RE", :accidental "natural"},
             78 {:instrument-id "HC", :accidental "flat"},
             79 {:instrument-id "HH", :accidental "natural"},
             80 {:instrument-id "HO", :accidental "sharp"},
             81 {:instrument-id "C2", :accidental "doublesharp"},
             82 {:instrument-id "C1", :accidental "sharp"},
             83 {:instrument-id "SP", :accidental "doublesharp"},
             84 {:instrument-id "CH", :accidental "sharp"}}}
           (sut/infer-notation-mappings gp8/drum-notation-map1)))
    (is (= (th/join-lines
             ["_C4__________________________C5__________________________C6__________________________"
              "|  | |♮|♯|♮ |♮ |♭|𝄫| |𝄫|𝄫|♭ |♮ |♭|𝄫|𝄫|♭ |♮ |♭|♮|♯|𝄪|♯|𝄪 |♯ | | | |  |  | | | | | |  |"
              "|  | | |C|  |  |T| | | |R|  |  |T| |R|  |  |H| |H| |C|  |  | | | |  |  | | | | | |  |"
              "|  | | |B|  |  |5| | | |S|  |  |2| |M|  |  |C| |O| |1|  |  | | | |  |  | | | | | |  |"
              "|  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |"
              "|   |HP |K2 |K1 |T4 |T3 |SC |SS |T1 |RB |RE |HH |C2 |SP |CH |   |   |   |   |   |   |"
              "|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|"])
          (pretty-solution
            (:solution (sut/infer-notation-mappings gp8/drum-notation-map1)))))))
