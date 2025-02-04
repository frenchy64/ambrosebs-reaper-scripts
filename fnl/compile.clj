#!/usr/bin/env bb

(require '[babashka.process :as p :refer [process]]
         '[babashka.tasks :as tasks]
         '[clojure.string :as str]
         '[selmer.parser :as sp :refer [render render-file]])

(sp/cache-off!)

(defn expand-template [fnl ])

(defn fnl-header-as-lua [fnl]
  (->> (slurp fnl)
       str/split-lines
       (take-while #(str/starts-with? % ";;"))
       (map #(str/replace-first % ";;" "--"))
       (str/join "\n")))

(def fnl-dir->reapack-dir
  {"midi-editor" "MIDI Editor"})

(def fnl-description-preamble ";; @description ")

(defn fnl-description [fnl]
  {:post [(string? %)
          (seq %)]}
  (-> (slurp fnl)
      str/split-lines
      (->> (drop-while #(not (str/starts-with? % fnl-description-preamble))))
      first
      (subs (count fnl-description-preamble))))

(defn compile-reapack-fnl-script [path-no-ext]
  {:pre [(string? path-no-ext)]}
  (let [[fnl-dir :as splits] (str/split path-no-ext #"/")
        _ (assert (= 2 (count splits)) [path-no-ext splits])
        fnl (str path-no-ext ".fnl")
        lua-dir (get fnl-dir->reapack-dir fnl-dir)
        _ (assert lua-dir fnl-dir)
        lua (str "../" lua-dir "/ambrosebs_" (fnl-description fnl) ".lua")]
    (p/shell {:out lua} "./fennel deps --require-as-include --compile" fnl)
    (spit lua
          (str/join "\n"
                    [(fnl-header-as-lua fnl)
                     (format "-- compiled from https://github.com/frenchy64/ambrosebs-reaper-scripts/blob/%s/%s"
                             (-> (tasks/shell {:out :string} "git rev-parse --short HEAD")
                                 :out
                                 str/trim)
                             (str "fnl/" fnl))
                     (slurp lua)]))))

(compile-reapack-fnl-script
  "midi-editor/notation")
