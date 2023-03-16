local ImGui = {}
local ctx = nil
local show_app = {console = false}
demo.ShowDemoWindow = function(open)
  if ImGui.BeginMenuBar(ctx) then
    if ImGui.BeginMenu(ctx, "Examples") then
      local rv_2_, arg1_1_ = nil, nil
      do
        local arg1_1_ = show_app.console
        local _24 = arg1_1_
        local _241 = arg1_1_
        rv_2_, arg1_1_ = ImGui.MenuItem(ctx, "Console", nil, _24, false)
      end
      show_app.console = arg1_1_
      return rv_2_, arg1_1_
    else
      return nil
    end
  else
    return nil
  end
end
return demo.ShowDemoWindow
