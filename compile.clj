#!/usr/bin/env bb

(require '[babashka.process :as p :refer [process]]
         '[babashka.tasks :as tasks]
         '[clojure.string :as str])

(defn fnl-header-as-lua [fnl]
  (->> (slurp fnl)
       str/split-lines
       (take-while #(str/starts-with? % ";;"))
       (map #(str/replace-first % ";;" "--"))
       (str/join "\n")))

(defn compile-reapack-fnl-script [path-no-ext]
  {:pre [(string? path-no-ext)]}
  (let [fnl (str path-no-ext ".fnl")
        lua (str path-no-ext ".lua")]
    (tasks/shell {:out lua} "./fennel --require-as-include --compile" fnl)
    (spit lua
          (str/join "\n"
                    [(fnl-header-as-lua fnl)
                     (format "-- compiled from '%s'" fnl)
                     (slurp lua)]))))

(compile-reapack-fnl-script
  "MIDI Editor/ambrosebs_Go forward 4 bars in Notation, otherwise decrease pitch cursor one semitone")
