# Arturia MiniLab MkII + REAPER: Infinite (Relative) Knob Mapping

## Goal
Map MiniLab MkII knobs in **relative/infinite encoder mode** to REAPER sliders or plugin parameters, for smooth, endless, incremental control (not limited to 0–127).

---

## Steps

### 1. Configure MiniLab MkII Knob for Relative Mode

1. **Open Arturia MIDI Control Center**
2. Connect your MiniLab MkII and select it.
3. Select the knob you wish to use.
4. Set **Mode/Type** to:
   - **Relative #2** *(this is the compatible mode for REAPER's Relative #1)*
5. Save and sync changes to the controller.

---

### 2. Map the Knob in REAPER

1. In REAPER, add a track and a plugin (or select any automatable slider/parameter).
2. **Right-click** the slider or plugin parameter you want to control.
3. Select **“Learn…”** or **“MIDI Learn”**.
4. Turn the MiniLab knob—REAPER should detect the MIDI CC.
5. In the MIDI Learn dialog:
   - Set the mode to **Relative #1** *(matches Arturia's Relative #2)*.
6. Confirm the mapping.

---

### 3. Test Infinite Movement

- Turn the MiniLab knob continuously.
- The REAPER slider/parameter should move up/down incrementally, with no physical end point.
- Both slow and fast turns should respond smoothly.

---

## Troubleshooting

- If the slider moves erratically, try a different relative mode in REAPER.
- If movement is reversed, invert in MIDI Learn dialog.
- Double-check Arturia MIDI Control Center settings and re-sync.
- For absolute mode mapping (full knob range), use “Absolute” mode in both Arturia and REAPER.

---

## Quick Reference

| Arturia MIDI Control Center | REAPER MIDI Learn Dialog |
|----------------------------|-------------------------|
| Relative #2                | Relative #1             |
| Absolute                   | Absolute                |
