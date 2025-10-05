(ns posture-midi-filter.midi
  "MIDI CC output for posture status"
  (:require [clojure.tools.logging :as log])
  (:import [javax.sound.midi MidiDevice MidiSystem ShortMessage Receiver]))

(def ^:const POSTURE_CC_NUMBER 20)
(def ^:const GOOD_POSTURE_VALUE 127)
(def ^:const BAD_POSTURE_VALUE 0)
(def ^:const MIDI_CHANNEL 0)

(defn find-virtual-midi-output
  "Find a virtual MIDI output device or return the first available output"
  []
  (let [infos (MidiSystem/getMidiDeviceInfo)
        devices (for [info infos]
                  (try
                    (let [device (MidiSystem/getMidiDevice info)]
                      (when (and (instance? MidiDevice device)
                                 (not (.isOpen device))
                                 (pos? (.getMaxReceivers device)))
                        {:info info :device device}))
                    (catch Exception e
                      (log/debug "Could not access MIDI device:" (.getName info))
                      nil)))
        available-devices (filter identity devices)]
    (if (empty? available-devices)
      (do
        (log/warn "No MIDI output devices found. MIDI output will be simulated.")
        nil)
      (let [selected (first available-devices)]
        (log/info "Selected MIDI output device:" (.getName (:info selected)))
        selected))))

(defn open-midi-output
  "Open a MIDI output device and return its receiver"
  []
  (if-let [device-info (find-virtual-midi-output)]
    (let [device (:device device-info)]
      (.open device)
      {:device device
       :receiver (.getReceiver device)})
    (do
      (log/info "Using simulated MIDI output")
      {:device nil
       :receiver nil})))

(defn send-cc
  "Send a MIDI Control Change message"
  [midi-output cc-number value]
  (let [{:keys [receiver]} midi-output]
    (if receiver
      (try
        (let [msg (ShortMessage.)]
          (.setMessage msg ShortMessage/CONTROL_CHANGE MIDI_CHANNEL cc-number value)
          (.send receiver msg -1))
        (catch Exception e
          (log/error e "Failed to send MIDI CC message")))
      (log/debug "Simulated MIDI CC:" cc-number "=" value))))

(defn send-posture-status
  "Send posture status as MIDI CC#20 (127 = good, 0 = bad)"
  [midi-output good-posture?]
  (let [value (if good-posture? GOOD_POSTURE_VALUE BAD_POSTURE_VALUE)]
    (send-cc midi-output POSTURE_CC_NUMBER value)
    (log/info "Sent posture MIDI CC:" POSTURE_CC_NUMBER "=" value)))

(defn close-midi-output
  "Close the MIDI output device"
  [midi-output]
  (when-let [device (:device midi-output)]
    (when (.isOpen device)
      (.close device)
      (log/info "MIDI output closed"))))
