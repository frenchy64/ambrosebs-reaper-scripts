local demo = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua')
local ctx = reaper.ImGui_CreateContext('My script')
local function loop()
  demo.PushStyle(ctx)
  demo.ShowDemoWindow(ctx)
  if reaper.ImGui_Begin(ctx, 'Dear ImGui Style Editor') then
    demo.ShowStyleEditor(ctx)
    reaper.ImGui_End(ctx)
  end
  demo.PopStyle(ctx)
  reaper.defer(loop)
end
reaper.defer(loop)
