(local demo
       (dofile (.. (reaper.GetResourcePath)
                   "/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua")))

(local ctx (reaper.ImGui_CreateContext "My script"))

(fn loop [] (demo.PushStyle ctx) (demo.ShowDemoWindow ctx)
  (when (reaper.ImGui_Begin ctx "Dear ImGui Style Editor")
    (demo.ShowStyleEditor ctx)
    (reaper.ImGui_End ctx))
  (demo.PopStyle ctx)
  (reaper.defer loop))

(reaper.defer loop)

