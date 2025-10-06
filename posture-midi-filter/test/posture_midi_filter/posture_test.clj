(ns posture-midi-filter.posture-test
  (:require [clojure.test :refer :all]
            [posture-midi-filter.posture :as posture]
            [posture-midi-filter.pose :as pose]))

(deftest test-posture-analysis
  (testing "Posture analysis with good posture"
    (let [keypoints (pose/->Keypoints
                      {:x 320 :y 200 :confidence 0.9}  ; nose high
                      {:x 280 :y 280 :confidence 0.85} ; left shoulder
                      {:x 360 :y 280 :confidence 0.85} ; right shoulder
                      {:x 300 :y 220 :confidence 0.8}  ; left ear
                      {:x 340 :y 220 :confidence 0.8}) ; right ear
          analysis (posture/analyze-posture keypoints)]
      (is (= :good (:status analysis)))
      (is (posture/posture-good? analysis))))
  
  (testing "Posture analysis with bad posture (forward head)"
    (let [keypoints (pose/->Keypoints
                      {:x 320 :y 270 :confidence 0.9}  ; nose low (forward head)
                      {:x 280 :y 280 :confidence 0.85} ; left shoulder
                      {:x 360 :y 280 :confidence 0.85} ; right shoulder
                      {:x 300 :y 275 :confidence 0.8}  ; left ear
                      {:x 340 :y 275 :confidence 0.8}) ; right ear
          analysis (posture/analyze-posture keypoints)]
      (is (= :bad (:status analysis)))
      (is (not (posture/posture-good? analysis))))))

(deftest test-shoulder-alignment
  (testing "Level shoulders"
    (let [keypoints (pose/->Keypoints
                      {:x 320 :y 200 :confidence 0.9}
                      {:x 280 :y 280 :confidence 0.85}
                      {:x 360 :y 280 :confidence 0.85}  ; same y as left
                      {:x 300 :y 220 :confidence 0.8}
                      {:x 340 :y 220 :confidence 0.8})]
      (is (posture/check-shoulder-alignment keypoints))))
  
  (testing "Tilted shoulders"
    (let [keypoints (pose/->Keypoints
                      {:x 320 :y 200 :confidence 0.9}
                      {:x 280 :y 260 :confidence 0.85}
                      {:x 360 :y 300 :confidence 0.85}  ; 40 pixels difference
                      {:x 300 :y 220 :confidence 0.8}
                      {:x 340 :y 220 :confidence 0.8})]
      (is (not (posture/check-shoulder-alignment keypoints))))))

(deftest test-forward-head-calculation
  (testing "Calculate forward head angle"
    (let [keypoints (pose/->Keypoints
                      {:x 320 :y 200 :confidence 0.9}
                      {:x 280 :y 280 :confidence 0.85}
                      {:x 360 :y 280 :confidence 0.85}
                      {:x 300 :y 220 :confidence 0.8}
                      {:x 340 :y 220 :confidence 0.8})
          angle (posture/calculate-forward-head-angle keypoints)]
      ;; Nose at 200, shoulders at 280, so angle should be 80
      (is (= 80 angle)))))
