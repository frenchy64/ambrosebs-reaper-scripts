#!/usr/bin/env bb

(require '[babashka.pods :as pods]
         '[babashka.tasks :as tasks])

(pods/load-pod 'org.babashka/fswatcher "0.0.3")
(require '[pod.babashka.fswatcher :as fw])

(let [running (atom false)]
  (defn run-tests []
    (when (= [false true] (reset-vals! running true))
      (future 
        (try (tasks/shell "./run-tests")
             (finally (reset! running false)))))))

(run-tests)

(mapv #(fw/watch % (fn [event]
                     (prn event)
                     (run-tests))
                 {:recursive true})
      ["clj" "fnl" "common"])

@(promise)
