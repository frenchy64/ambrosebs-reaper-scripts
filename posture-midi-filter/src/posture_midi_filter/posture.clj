(ns posture-midi-filter.posture
  "Posture analysis logic based on pose keypoints"
  (:require [clojure.tools.logging :as log]
            [posture-midi-filter.pose :as pose]))

(defn calculate-forward-head-angle
  "Calculate forward head posture angle from keypoints.
   Returns angle in degrees where higher values indicate worse posture."
  [keypoints]
  (let [nose (:nose keypoints)
        left-shoulder (:left-shoulder keypoints)
        right-shoulder (:right-shoulder keypoints)
        shoulder-mid-y (/ (+ (:y left-shoulder) (:y right-shoulder)) 2)]
    ;; Simple heuristic: if nose is significantly above shoulders, posture is good
    ;; If nose is at or below shoulder level, posture is bad
    (- shoulder-mid-y (:y nose))))

(defn check-shoulder-alignment
  "Check if shoulders are level (not tilted)"
  [keypoints]
  (let [left-shoulder (:left-shoulder keypoints)
        right-shoulder (:right-shoulder keypoints)
        y-diff (Math/abs (- (:y left-shoulder) (:y right-shoulder)))]
    ;; Shoulders should be within 20 pixels of each other vertically
    (< y-diff 20)))

(defn analyze-posture
  "Analyze posture from keypoints and return posture status.
   Returns {:status :good/:bad :confidence float :details map}"
  [keypoints]
  (if-not (pose/keypoints-detected? keypoints)
    {:status :unknown
     :confidence 0.0
     :details {:error "No keypoints detected"}}
    (let [head-angle (calculate-forward-head-angle keypoints)
          shoulders-aligned? (check-shoulder-alignment keypoints)
          ;; Good posture: head angle > 40 pixels above shoulders
          good-head-posture? (> head-angle 40)
          good-posture? (and good-head-posture? shoulders-aligned?)]
      {:status (if good-posture? :good :bad)
       :confidence (if good-posture? 0.85 0.80)
       :details {:head-angle head-angle
                 :shoulders-aligned shoulders-aligned?
                 :good-head-posture good-head-posture?}})))

(defn posture-good?
  "Simple predicate to check if posture is good"
  [posture-analysis]
  (= :good (:status posture-analysis)))
