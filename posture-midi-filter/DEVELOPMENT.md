# Developer Guide

## Project Structure

```
posture-midi-filter/
├── project.clj              # Leiningen project configuration
├── src/
│   └── posture_midi_filter/
│       ├── core.clj         # Main application entry point
│       ├── video.clj        # Video capture layer
│       ├── pose.clj         # Pose estimation
│       ├── posture.clj      # Posture analysis logic
│       └── midi.clj         # MIDI CC output
├── test/
│   └── posture_midi_filter/
│       └── posture_test.clj # Unit tests
└── README.md                # Project documentation
```

## Development Workflow

### Building the Project

```bash
# Download dependencies
lein deps

# Compile the project
lein compile

# Build standalone jar
lein uberjar
```

### Running the Application

```bash
# Run with Leiningen
lein run

# Or run the standalone jar
java -jar target/uberjar/posture-midi-filter-0.1.0-SNAPSHOT-standalone.jar

# Or use the convenience script
./run.sh
```

### Testing

```bash
# Run all tests
lein test

# Run specific test
lein test posture-midi-filter.posture-test
```

## Component Details

### Video Capture (`video.clj`)

Uses the Webcam Capture library to access the webcam. Key functions:
- `start-webcam`: Initialize and open webcam
- `capture-frame`: Get a single frame
- `close-webcam`: Clean up resources

### Pose Estimation (`pose.clj`)

Currently uses mock keypoints. In production, this should integrate with DJL and MoveNet:
- `analyze-frame`: Extract pose keypoints from frame
- `keypoints-detected?`: Validate keypoint confidence

### Posture Analysis (`posture.clj`)

Implements heuristics to classify posture as good or bad:
- `calculate-forward-head-angle`: Measure forward head posture
- `check-shoulder-alignment`: Detect shoulder tilt
- `analyze-posture`: Combine heuristics for overall status

### MIDI Output (`midi.clj`)

Sends MIDI CC messages using javax.sound.midi:
- `open-midi-output`: Find and open MIDI device
- `send-posture-status`: Send CC#20 (127=good, 0=bad)
- `close-midi-output`: Clean up MIDI resources

### Main Application (`core.clj`)

Integrates all components:
- Captures video frames at ~10 FPS
- Analyzes posture in real-time
- Sends MIDI CC when posture status changes
- Handles graceful shutdown

## Configuration

Current hardcoded values (future config file):
- Frame rate: 10 FPS (100ms delay)
- MIDI CC number: 20
- Good posture threshold: 40 pixels head above shoulders
- Shoulder alignment threshold: 20 pixels

## Dependencies

Key libraries used:
- `webcam-capture 0.3.12`: Webcam access
- `javacv-platform 1.5.9`: Advanced video processing
- `djl/api 0.25.0`: Deep learning framework
- `javax.sound.midi`: MIDI output (Java standard library)

## Future Enhancements

1. **Replace mock pose estimation with real ML model**
   - Integrate DJL with MoveNet or PoseNet
   - Load pre-trained model from DJL model zoo

2. **Add configuration file**
   - Make thresholds configurable
   - Allow selection of MIDI device and CC number
   
3. **Improve posture heuristics**
   - Add more sophisticated angle calculations
   - Consider temporal smoothing to reduce jitter
   
4. **Add visual feedback**
   - Display webcam feed with overlay
   - Show keypoints and posture status
   
5. **Performance optimization**
   - Adjust frame rate based on system capabilities
   - Add frame skipping if processing falls behind
