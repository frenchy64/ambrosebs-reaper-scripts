# Copilot Instructions for Ambrose's REAPER Scripts

This repository contains Lua scripts and JSFX effects for REAPER, a digital audio workstation. These scripts are distributed via ReaPack.

## Project Overview

- **Primary Language**: Lua (for REAPER scripts), JSFX (for effects)
- **Purpose**: Custom MIDI Editor actions and effects for music production
- **Distribution**: ReaPack package manager (index.xml)
- **Target**: REAPER 6.0+

## Code Style and Conventions

### Lua Scripts

1. **File Headers**: All Lua scripts must include ReaPack metadata comments:
   ```lua
   -- @description Brief description of what the script does
   -- @author Ambrose Bonnaire-Sergeant
   -- @version X.Y
   -- @about
   --    Detailed description of the script's purpose and usage
   ```

2. **Library Files**: Use `@noindex` tag for library files that should not appear in ReaPack:
   ```lua
   -- @noindex
   ```

3. **Module Loading**: Use the following pattern for loading local libraries:
   ```lua
   package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
   require "ambrosebs_Module_Name"
   ```

4. **REAPER API Patterns**:
   - Use `reaper.` prefix for all REAPER API calls
   - Get active MIDI editor: `reaper.MIDIEditor_GetActive()`
   - Execute MIDI editor commands: `reaper.MIDIEditor_OnCommand(editor, command_id)`
   - Use descriptive comments for numeric command IDs:
     ```lua
     40682 -- Navigate: Move edit cursor right one measure
     ```

5. **Naming Conventions**:
   - Prefix all script files with `ambrosebs_`
   - Use PascalCase for function names: `GoDown()`, `InMusicalNotation()`
   - Use descriptive names that explain the action

### JSFX Effects

1. **File Headers**: Include metadata at the top:
   ```
   desc: Effect Name
   author: Ambrose Bonnaire-Sergeant
   version: X.Y
   changelog:
     * Change description
   about:
     # Effect Name
     Description
   ```

2. **JSFX files** should be placed in the `MIDI` directory

## Directory Structure

```
├── MIDI/                    # JSFX effects
│   └── *.jsfx
├── MIDI Editor/            # Lua scripts for MIDI Editor
│   ├── *_lib.lua          # Library files (with @noindex)
│   └── *.lua              # Action scripts
├── .github/               # GitHub configuration
├── index.xml             # ReaPack index (auto-generated)
└── reapack-index.sh      # Script to rebuild index
```

## Development Workflow

1. **Adding New Scripts**:
   - Place MIDI Editor scripts in `MIDI Editor/` directory
   - Place JSFX effects in `MIDI/` directory
   - Include proper metadata headers
   - Ensure scripts follow the naming convention

2. **Library Files**:
   - Mark with `@noindex` tag
   - Keep them in the same directory as scripts that use them
   - Use consistent function names across library files

3. **Testing**:
   - Test scripts manually in REAPER
   - Verify MIDI Editor modes (notation view vs. other modes)
   - Check that library dependencies load correctly

4. **ReaPack Index**:
   - Run `./reapack-index.sh` to regenerate `index.xml`
   - The index should be committed along with script changes
   - Dependencies: cmake, pandoc, ruby (with bundler)

## REAPER-Specific Context

### MIDI Editor Modes
- Mode 2: Musical notation view (staff view)
- Other modes: Piano roll, event list, etc.
- Scripts should adapt behavior based on current mode

### Common REAPER Command IDs
- 40049: Edit: Increase pitch cursor one semitone
- 40050: Edit: Decrease pitch cursor one semitone
- 40682: Navigate: Move edit cursor right one measure
- 40683: Navigate: Move edit cursor left one measure

### MIDI Note Handling
- Use `reaper.MIDI_GetNote()` to read note properties
- Use `reaper.MIDI_SetNote()` to modify notes
- Always call `reaper.MIDI_Sort(take)` after modifications
- Mark items dirty: `reaper.MarkTrackItemsDirty()`

## Best Practices

1. **Error Handling**: Check for valid MIDI editor and take objects
2. **Undo Blocks**: Wrap modifications in `reaper.Undo_BeginBlock()` / `reaper.Undo_EndBlock()`
3. **User Feedback**: Use `reaper.ShowConsoleMsg()` for debugging
4. **Comments**: Use inline comments to explain REAPER command IDs and complex logic
5. **Modularity**: Extract common functionality into library files

## Don't

- Don't modify `index.xml` manually (it's auto-generated)
- Don't remove ReaPack metadata tags from scripts
- Don't use absolute paths in scripts (they must work on any system)
- Don't break the module loading pattern (scripts must find libraries)
- Don't add dependencies beyond the REAPER API unless necessary

## References

- REAPER API Documentation: https://www.reaper.fm/sdk/reascript/reascripthelp.html
- ReaPack Documentation: https://github.com/cfillion/reapack-index
- JSFX Documentation: https://www.reaper.fm/sdk/js/js.php
