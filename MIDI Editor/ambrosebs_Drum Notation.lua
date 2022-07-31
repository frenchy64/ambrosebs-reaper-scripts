-- @noindex
-- @version 0.0

-- TODO suggest (or provide constrait for) middle for Virtual MIDI keyboard
notation_name = "D5 Enharmonic Drum Notation"
root = "D4"
-- ordering preference (soft constraint)
-- {Xnatural, Xdoubleflat?, Xflat?, Xsharp?, Xdoublesharp?} -- X# note
notation_map = {
  {"Hi-Hat Pedal (HP)", "Cowbell (CB)"}, -- D4
  {"Kick 2 (K2)"}, -- E4
  {"Kick 1 (K1)"}, -- F4
  {"Very Low Tom (T5)"},  -- G4
  {"Low Tom (T4)"}, -- A4
  {"Mid Tom (T3)"}, -- B4
  {"Snare (Rim Shot)", "Snare Center (SC)", "Snare Stick (SS)"}, -- C5
  {"High Tom (T2)"}, -- D5
  {"High Floor Tom (T1)"}, -- E5
  {"Ride Middle (RM)", "Ride Bell (RB)", "Ride Edge (RE)"}, -- F5
  {"Hi-Hat Closed (HC)", "Hi-Hat Half (HH)", "Hi-Hat Open (HO)", "Crash Medium (C2)"}, -- G5
  {"Crash High (C1)", "Splash"}, -- A5
  {"China"} -- B5
  }

solution = 
