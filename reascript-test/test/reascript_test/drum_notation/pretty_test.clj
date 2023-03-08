(ns reascript-test.drum-notation.pretty-test
  (:require [clojure.data :as data]
            [clojure.string :as str]
            [clojure.test :refer [deftest is]]
            [reascript-test.drum-notation.guitar-pro8 :as gp8]
            [reascript-test.drum-notation.pretty :as sut]))

(defmacro is-string= [s1 s2]
  `(let [s1# ~s1
         s2# ~s2]
     (is (= s1# s2#)
         (pr-str (data/diff (str/split-lines s1#)
                            (str/split-lines s2#))))))

(defn- str->str-join-expr [s]
  (list 'str/join "\n" (str/split-lines s)))

(def example-piano-ascii
  (str/join "\n"
            ["_____________________________"
             "|  | | | |  |  | | | | | |  |"
             "|  | | | |  |  | | | | | |  |"
             "|  | | | |  |  | | | | | |  |"
             "|  |_| |_|  |  |_| |_| |_|  |"
             "|   |   |   |   |   |   |   |"
             "|___|___|___|___|___|___|___|"]))

(def example-piano-C->E
  (str/join "\n"
            (map #(subs % 0 13)
                 (str/split-lines example-piano-ascii))))

(def example-piano-E->B
  (str/join "\n"
            (map #(subs % 12)
                 (str/split-lines example-piano-ascii))))

(comment
  (println example-piano-C->E)
  (println example-piano-E->B)
  )

(deftest piano-ascii-kw-template-test
  (is (= ["_" :H :H :H "_________________________\n|"
          :1 " |" :2 "|" :3 "|" :4 "|" :5 " |" :6 " |" :7 "|" :8 "|" :9 "|" :0 "|" :i "|" :j " |\n|  |"
          :C "| |" :D "|  |  |" :F "| |" :G "| |" :A "|  |\n|  |" :C "| |" :D "|  |  |" :F "| |" :G "| |" :A
          "|  |\n|  |_| |_|  |  |_| |_| |_|  |\n|" :c :c " |" :d :d " |" :e :e " |" :f :f " |" :g :g " |"
          :a :a " |" :b :b " |\n|___|___|___|___|___|___|___|"]
         sut/piano-ascii-kw-template)))

(deftest instantiate-piano-ascii-test
  (is (= example-piano-ascii
         (sut/instantiate-piano-ascii {\H ["_" "_" "_"]})))
  (is (str/includes? (sut/instantiate-piano-ascii {\H ["_" "_" "_"]
                                                   \A ["𝄪"]})
                     "𝄪")))

(deftest ->piano-ascii-test
  (is-string= (str/join "\n"
                        ["_C4__________________________"
                         "|  | | | |  |  | | | |♭| |  |"
                         "|  | | | |  |  | | | | | |  |"
                         "|  | | | |  |  | | | | | |  |"
                         "|  |_| |_|  |  |_| |_| |_|  |"
                         "|   |   |   |   |   |K2 |   |"
                         "|___|___|___|___|___|___|___|"])
              (let [r (sut/->piano-ascii 4 {"A" {:instrument-id "K2"
                                                 :accidental "flat"}})] 
                (with-out-str
                  (print r))))
  (is-string= (str/join "\n"
                        ["_C-1_________________________"
                         "|  |𝄪|♮| |  |  | | | |♭|𝄫|♭ |"
                         "|  |D| | |  |  | | | | |K|  |"
                         "|  |2| | |  |  | | | | |1|  |"
                         "|  |_| |_|  |  |_| |_| |_|  |"
                         "|   |EE |   |   |   |K2 |C2 |"
                         "|___|___|___|___|___|___|___|"])
              (let [r (sut/->piano-ascii -1 {"A" {:instrument-id "K2"
                                                  :accidental "flat"}
                                             "A#" {:instrument-id "K1"
                                                   :accidental "doubleflat"}
                                             "B" {:instrument-id "C2"
                                                  :accidental "flat"}
                                             "C#" {:instrument-id "D2"
                                                   :accidental "doublesharp"}
                                             "D" {:instrument-id "EE"
                                                  :accidental "natural"}})] 
                (with-out-str
                  (print r)))))

(deftest pretty-solution-test
  (is (= (str/join "\n"
                   ["_C4__________________________"
                    "|  | |♮|♭|♮ |♮ | | | | | |  |"
                    "|  | | |C|  |  | | | | | |  |"
                    "|  | | |B|  |  | | | | | |  |"
                    "|  |_| |_|  |  |_| |_| |_|  |"
                    "|   |HP |K2 |K1 |   |   |   |"
                    "|___|___|___|___|___|___|___|"])
         (sut/pretty-solution
           (into (sorted-map)
                 (select-keys gp8/drum-notation-map1-solution [62 63 64 65])))))

  (is-string= (str/join "\n" ["_C4__________________________C5__________________________"
                              "|  | |♮| |  |  | | | | | |  |  |♭| | |  |  | | | | | |  |"
                              "|  | | | |  |  | | | | | |  |  |T| | |  |  | | | | | |  |"
                              "|  | | | |  |  | | | | | |  |  |2| | |  |  | | | | | |  |"
                              "|  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |"
                              "|   |HP |   |   |   |   |   |   |   |   |   |   |   |   |"
                              "|___|___|___|___|___|___|___|___|___|___|___|___|___|___|"])
              (sut/pretty-solution
                (into (sorted-map)
                      (select-keys gp8/drum-notation-map1-solution [62 73]))))
  (is-string= (str/join "\n" ["_C4__________________________C5__________________________C6__________________________"
                              "|  | |♮|♭|♮ |♮ |♭|𝄫| |𝄫|𝄫|♭ |♮ |♭|𝄫|𝄫|♭ |♮ |♭|♮|♯|𝄪|♯|𝄪 |♯ | | | |  |  | | | | | |  |"
                              "|  | | |C|  |  |T| | | |S|  |  |T| |R|  |  |H| |H| |C|  |  | | | |  |  | | | | | |  |"
                              "|  | | |B|  |  |5| | | |C|  |  |2| |B|  |  |H| |O| |1|  |  | | | |  |  | | | | | |  |"
                              "|  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |  |_| |_|  |  |_| |_| |_|  |"
                              "|   |HP |K2 |K1 |T4 |T3 |SS |SR |T1 |RE |RM |HC |C2 |SP |CH |   |   |   |   |   |   |"
                              "|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|"])
              (sut/pretty-solution gp8/drum-notation-map1-solution)))
