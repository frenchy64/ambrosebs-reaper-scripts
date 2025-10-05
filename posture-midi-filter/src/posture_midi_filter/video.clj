(ns posture-midi-filter.video
  "Video capture layer for webcam access"
  (:require [clojure.tools.logging :as log])
  (:import [com.github.sarxos.webcam Webcam WebcamResolution]
           [java.awt.image BufferedImage]))

(defn get-default-webcam
  "Get the default webcam device"
  []
  (let [webcam (Webcam/getDefault)]
    (when-not webcam
      (throw (ex-info "No webcam found" {})))
    webcam))

(defn open-webcam
  "Open a webcam and set its resolution"
  [webcam]
  (doto webcam
    (.setViewSize (.getSize WebcamResolution/VGA))
    (.open))
  (log/info "Webcam opened successfully")
  webcam)

(defn capture-frame
  "Capture a single frame from the webcam"
  [^Webcam webcam]
  (.getImage webcam))

(defn close-webcam
  "Close the webcam"
  [^Webcam webcam]
  (when (.isOpen webcam)
    (.close webcam)
    (log/info "Webcam closed")))

(defn start-webcam
  "Start webcam and return it"
  []
  (try
    (-> (get-default-webcam)
        (open-webcam))
    (catch Exception e
      (log/error "Failed to initialize webcam:" (.getMessage e))
      (throw e))))
