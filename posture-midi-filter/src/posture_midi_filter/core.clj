(ns posture-midi-filter.core
  "Main entry point for the E-Drum Posture MIDI Filter"
  (:require [clojure.tools.logging :as log]
            [posture-midi-filter.video :as video]
            [posture-midi-filter.pose :as pose]
            [posture-midi-filter.posture :as posture]
            [posture-midi-filter.midi :as midi])
  (:gen-class))

(def running (atom true))
(def frame-delay-ms 100) ; Process ~10 frames per second

(defn process-frame
  "Process a single video frame and update MIDI output"
  [webcam midi-output last-status]
  (try
    (let [frame (video/capture-frame webcam)
          keypoints (pose/analyze-frame frame)
          posture-analysis (posture/analyze-posture keypoints)
          current-status (:status posture-analysis)]
      
      ;; Log posture details periodically
      (when (not= current-status @last-status)
        (log/info "Posture status changed:" current-status)
        (log/debug "Details:" (:details posture-analysis))
        (reset! last-status current-status))
      
      ;; Send MIDI CC if status changed
      (when (not= current-status @last-status)
        (midi/send-posture-status midi-output (posture/posture-good? posture-analysis)))
      
      posture-analysis)
    (catch Exception e
      (log/error e "Error processing frame")
      nil)))

(defn monitoring-loop
  "Main monitoring loop that captures video and outputs MIDI"
  [webcam midi-output]
  (log/info "Starting posture monitoring loop...")
  (log/info "Press Ctrl+C to stop")
  (let [last-status (atom nil)]
    (while @running
      (process-frame webcam midi-output last-status)
      (Thread/sleep frame-delay-ms))
    (log/info "Monitoring loop stopped")))

(defn shutdown-hook
  "Cleanup function to be called on shutdown"
  [webcam midi-output]
  (fn []
    (log/info "Shutting down...")
    (reset! running false)
    (Thread/sleep 200) ; Give monitoring loop time to exit
    (video/close-webcam webcam)
    (midi/close-midi-output midi-output)
    (log/info "Shutdown complete")))

(defn -main
  "Main entry point for the application"
  [& args]
  (log/info "=== E-Drum Posture MIDI Filter ===")
  (log/info "Starting posture monitoring system...")
  
  (let [webcam (try
                 (video/start-webcam)
                 (catch Exception e
                   (log/error "Failed to start webcam:" (.getMessage e))
                   (log/warn "Running in demo mode without webcam")
                   nil))
        midi-output (midi/open-midi-output)]
    
    (if webcam
      (do
        ;; Register shutdown hook
        (.addShutdownHook (Runtime/getRuntime)
                          (Thread. (shutdown-hook webcam midi-output)))
        
        ;; Start monitoring
        (try
          (monitoring-loop webcam midi-output)
          (catch InterruptedException e
            (log/info "Monitoring interrupted"))
          (catch Exception e
            (log/error e "Error in monitoring loop"))))
      (do
        (log/error "Cannot start without webcam")
        (log/info "Please ensure a webcam is connected and accessible")
        (System/exit 1)))))
