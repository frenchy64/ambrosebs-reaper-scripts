;; Lua/ReaImGui port of Dear ImGui's C++ demo code (v1.89.3)
;;
;;This file can be imported in other scripts to help during development:

(import-macros {: doimgui} :imgui-macros)

(local ImGui {})
(var ctx nil)
(local show-app {:console false})

(fn demo.ShowDemoWindow [open]
  (when (ImGui.BeginMenuBar ctx)
    (when (ImGui.BeginMenu ctx :Examples)
      (doimgui show-app.console (ImGui.MenuItem ctx :Console nil $ false)))))
