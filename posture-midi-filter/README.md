# E-Drum Posture MIDI Filter

## Motivation

Practicing electronic drums (e-drums) is not just about timing and accuracy—body posture is critical for technique, comfort, and long-term health. Many drummers develop habits such as craning the neck, hunching the shoulders, or slumping the back, which can lead to tension and injury over time. 

While tools exist to train timing and accuracy (for example, [ambrosebs_MIDI Drum Trainer.jsfx](https://github.com/frenchy64/ambrosebs-reaper-scripts/blob/main/MIDI/ambrosebs_MIDI%20Drum%20Trainer.jsfx)), there is no integration of posture awareness into the feedback loop. The goal of this project is to bridge that gap: **to use real-time video posture analysis to influence MIDI output and encourage good drumming posture.**

## Project Goals

- **Monitor** the drummer's posture in real time using a webcam.
- **Detect** specific "bad posture" patterns (e.g., forward head posture, excessive neck tension).
- **Integrate** with music production software (REAPER) by sending MIDI Control Change (CC) messages to indicate posture status.
- **Filter MIDI notes** in existing REAPER scripts (like the Drum Trainer) so drum hits are only registered when good posture is maintained.
- **Be modular and easy to expand**: The posture detection logic and MIDI communication should remain decoupled for flexibility.

## Planned Architecture

```
[Webcam]
    │
    ▼
[Video Capture Layer]
    │
    ▼
[Pose Estimation Model]
    │
    ▼
[Posture Analysis Logic]
    │
    ▼
[MIDI CC Output to Virtual Port]
    │
    ▼
[REAPER or DAW]
    │
    ▼
[Drum Trainer JSFX / MIDI Filtering Script]
```

### Components

- **Video Capture Layer**
  - Captures video frames from a webcam.
  - Implemented using JVM-friendly libraries (e.g., [Webcam Capture](https://github.com/sarxos/webcam-capture) or [JavaCV](https://github.com/bytedeco/javacv)).
- **Pose Estimation Model**
  - Analyzes video frames to extract keypoints (head, neck, shoulders, etc.).
  - Uses a Java-accessible model such as [MoveNet](https://www.tensorflow.org/hub/tutorials/movenet) or PoseNet via [Deep Java Library (DJL)](https://djl.ai/).
- **Posture Analysis Logic**
  - Applies heuristics or ML to the pose keypoints to classify posture as "good" or "bad."
  - Examples: Detecting excessive forward head, slouching, or neck tension.
- **MIDI CC Output**
  - Outputs a MIDI Control Change message (e.g., CC#20) to signal posture status (127 = good, 0 = bad).
  - Uses the Java standard `javax.sound.midi` library to send MIDI on a virtual port.
- **DAW Integration**
  - REAPER (or any DAW) receives the MIDI CC.
  - Existing JSFX scripts (like the Drum Trainer) can be easily modified to filter MIDI notes based on posture CC value.

### Example Workflow

1. **Start the posture monitor app.**
2. **App analyzes webcam feed in real time.**
3. **If posture is "bad", app sends MIDI CC#20 = 0. If posture is "good", app sends MIDI CC#20 = 127.**
4. **In REAPER, a JSFX script (or MIDI routing) blocks drum notes if CC#20 = 0.**
5. **Drummer receives immediate feedback, encouraging good posture.**

## Implementation Notes

- **Language:** Clojure on the JVM, using stable Java libraries for video and MIDI.
- **Modularity:** Video/posture logic and MIDI output are decoupled from the DAW, making it easy to swap in new posture heuristics or models.
- **Extensibility:** The posture monitoring app can be extended to support more nuanced feedback, other instruments, or even visual/audio alerts.

## Status

**This project is in the initial implementation stage.**  

The Leiningen project has been set up with the following components:

- ✅ **Project Structure**: Leiningen project with `project.clj` and proper namespaces
- ✅ **Video Capture Layer**: Using Webcam Capture library for webcam access
- ✅ **Pose Estimation**: Stub implementation ready for integration with DJL/MoveNet
- ✅ **Posture Analysis**: Heuristic-based posture analysis (forward head posture detection)
- ✅ **MIDI Output**: MIDI CC output using `javax.sound.midi`
- ✅ **Integration**: Main application loop that connects all components

### Running the Application

To run the application, you need:
- A webcam connected to your system
- Java 8 or higher
- Leiningen installed

Run the application with:
```bash
lein run
```

Alternatively, build a standalone jar:
```bash
lein uberjar
java -jar target/uberjar/posture-midi-filter-0.1.0-SNAPSHOT-standalone.jar
```

### Current Limitations

- Pose estimation currently uses mock keypoints (placeholder for actual ML model integration)
- Requires v4l2 libraries on Linux for webcam access
- MIDI output will use simulated output if no MIDI devices are available

### Next Steps

- Integrate actual pose estimation model (DJL with MoveNet)
- Refine posture analysis heuristics
- Add configuration options for CC number, thresholds, etc.
- Create visual feedback UI

---

## License

Eclipse Public License 1.0

---

## References

- [ambrosebs_MIDI Drum Trainer.jsfx](https://github.com/frenchy64/ambrosebs-reaper-scripts/blob/main/MIDI/ambrosebs_MIDI%20Drum%20Trainer.jsfx)
- [Deep Java Library (DJL)](https://djl.ai/)
- [Webcam Capture](https://github.com/sarxos/webcam-capture)
- [JavaCV](https://github.com/bytedeco/javacv)
- [javax.sound.midi](https://docs.oracle.com/javase/8/docs/api/javax/sound/midi/package-summary.html)
