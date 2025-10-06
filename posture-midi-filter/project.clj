(defproject posture-midi-filter "0.1.0-SNAPSHOT"
  :description "E-Drum Posture MIDI Filter - Real-time posture monitoring for drummers"
  :url "https://github.com/frenchy64/ambrosebs-reaper-scripts"
  :license {:name "Eclipse Public License 1.0"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.11.1"]
                 ;; Video capture using Webcam Capture library
                 [com.github.sarxos/webcam-capture "0.3.12"]
                 ;; MIDI support (part of Java standard library, but including for clarity)
                 ;; JavaCV for advanced video processing if needed
                 [org.bytedeco/javacv-platform "1.5.9"]
                 ;; Deep Java Library for pose estimation
                 [ai.djl/api "0.25.0"]
                 [ai.djl/model-zoo "0.25.0"]
                 [ai.djl.mxnet/mxnet-engine "0.25.0"]
                 [ai.djl.mxnet/mxnet-model-zoo "0.25.0"]
                 ;; Logging
                 [org.clojure/tools.logging "1.2.4"]
                 [ch.qos.logback/logback-classic "1.4.14"]]
  :main ^:skip-aot posture-midi-filter.core
  :target-path "target/%s"
  :aliases {"run" ["with-profile" "uberjar" "trampoline" "run"]}
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})
