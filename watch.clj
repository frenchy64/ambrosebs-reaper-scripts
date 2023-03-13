#!/usr/bin/env bb

(require '[babashka.pods :as pods]
         '[babashka.tasks :as tasks])

(pods/load-pod 'org.babashka/filewatcher "0.0.1")
(require '[pod.babashka.filewatcher :as fw])

(let [running (atom false)]
  (defn run-tests []
    (when (= [false true] (reset-vals! running true))
      (try (tasks/shell "./run-tests")
           (finally (reset! running false))))))

(run-tests)

(def cwd (System/getProperty "user.dir"))

(require '[clojure.java.io :as io])

(fw/watch "src" (fn [event]
                  (when (= :write (:type event))
                    (run-tests))))

@(promise)
