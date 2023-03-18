--[[ (local demo (dofile (.. (reaper.GetResourcePath) "/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua"))) (local ctx (reaper.ImGui_CreateContext "My script")) (fn loop [] (demo.PushStyle ctx) (demo.ShowDemoWindow ctx) (when (reaper.ImGui_Begin ctx "Dear ImGui Style Editor") (demo.ShowStyleEditor ctx) (reaper.ImGui_End ctx)) (demo.PopStyle ctx) (reaper.defer loop)) (reaper.defer loop) ]]
local ImGui
do
  local tbl_14_auto = {}
  for name, func in pairs(reaper) do
    local k_15_auto, v_16_auto = nil, nil
    do
      local name0 = name:match("^ImGui_(.+)$")
      if name0 then
        k_15_auto, v_16_auto = name0, func
      else
        k_15_auto, v_16_auto = nil
      end
    end
    if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
      tbl_14_auto[k_15_auto] = v_16_auto
    else
    end
  end
  ImGui = tbl_14_auto
end
local ctx = nil
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = ImGui.GetVersion()
local demo = {open = true, menu = {b = true, enabled = true, f = 0.5, n = 0}, no_resize = false, no_menu = false, no_move = false, no_close = false, unsaved_document = false, no_titlebar = false, no_scrollbar = false, no_docking = false, no_background = false, no_nav = false, no_collapse = false}
local show_app = {about = false, window_titles = false, simple_overlay = false, property_editor = false, style_editor = false, stack_tool = false, custom_rendering = false, log = false, layout = false, fullscreen = false, constrained_resize = false, metrics = false, console = false, documents = false, debug_log = false, long_text = false, auto_resize = false}
local config = {}
local widgets = {}
local layout = {}
local popups = {}
local tables = {}
local misc = {}
local app = {}
local cache = {}
demo.loop = function()
  demo.PushStyle()
  demo.open = demo.ShowDemoWindow(true)
  demo.PopStyle()
  if demo.open then
    return reaper.defer(demo.loop)
  else
    return nil
  end
end
if (select(2, reaper.get_action_context()) == ((debug.getinfo(1, "S")).source):sub(2)) then
  _G.demo = demo
  _G.widgets = widgets
  _G.layout = layout
  _G.popups = popups
  _G.tables = tables
  _G.misc = misc
  _G.app = app
  ctx = ImGui.CreateContext("ReaImGui Demo", ImGui.ConfigFlags_DockingEnable())
  reaper.defer(demo.loop)
else
end
demo.HelpMarker = function(desc)
  ImGui.TextDisabled(ctx, "(?)")
  if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayShort()) then
    ImGui.BeginTooltip(ctx)
    ImGui.PushTextWrapPos(ctx, (ImGui.GetFontSize(ctx) * 35.0))
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    return ImGui.EndTooltip(ctx)
  else
    return nil
  end
end
demo.RgbaToArgb = function(rgba)
  return (((rgba >> 8) & 16777215) | ((rgba << 24) & 4278190080))
end
demo.ArgbToRgba = function(argb)
  return (((argb << 8) & 4294967040) | ((argb >> 24) & 255))
end
demo.round = function(n)
  return math.floor((n + 0.5))
end
demo.clamp = function(v, mn, mx)
  if (v < mn) then
    return mn
  elseif (v > mx) then
    return mx
  else
    return v
  end
end
demo.Link = function(url)
  if not reaper.CF_ShellExecute then
    ImGui.Text(ctx, url)
    return nil
  else
    local color = ImGui.GetStyleColor(ctx, ImGui.Col_CheckMark())
    ImGui.TextColored(ctx, color, url)
    if ImGui.IsItemClicked(ctx) then
      return reaper.CF_ShellExecute(url)
    elseif ImGui.IsItemHovered(ctx) then
      return ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand())
    else
      return nil
    end
  end
end
demo.HSV = function(h, s, v, a)
  local r, g, b = ImGui.ColorConvertHSVtoRGB(h, s, v)
  return ImGui.ColorConvertDouble4ToU32(r, g, b, (a or 1.0))
end
demo.EachEnum = function(enum)
  local enum_cache = cache[enum]
  if not enum_cache then
    enum_cache = {}
    cache[enum] = enum_cache
    for func_name, func in pairs(reaper) do
      local enum_name = func_name:match(("^ImGui_%s_(.+)$"):format(enum))
      if enum_name then
        table.insert(enum_cache, {func(), enum_name})
      else
      end
    end
    local function _10_(a, b)
      return (a[1] < b[1])
    end
    table.sort(enum_cache, _10_)
  else
  end
  local i = 0
  local function _12_()
    i = (i + 1)
    if enum_cache[i] then
      return table.unpack(enum_cache[i])
    else
      return nil
    end
  end
  return _12_
end
demo.DockName = function(dock_id)
  if (dock_id == 0) then
    return "Floating"
  elseif (dock_id > 0) then
    return ("ImGui docker %d"):format(dock_id)
  else
    local positions = {"Left", "Top", "Right", "Floating", [0] = "Bottom"}
    local position
    local function _14_()
      if reaper.DockGetPosition then
        return positions[reaper.DockGetPosition(~dock_id)]
      else
        return nil
      end
    end
    position = (_14_() or "Unknown")
    return ("REAPER docker %d (%s)"):format(( - dock_id), position)
  end
end
demo.ShowDemoWindow = function(open)
  local open0 = open
  if show_app.documents then
    show_app.documents = demo.ShowExampleAppDocuments()
  else
  end
  if show_app.console then
    show_app.console = demo.ShowExampleAppConsole()
  else
  end
  if show_app.log then
    show_app.log = demo.ShowExampleAppLog()
  else
  end
  if show_app.layout then
    show_app.layout = demo.ShowExampleAppLayout()
  else
  end
  if show_app.property_editor then
    show_app.property_editor = demo.ShowExampleAppPropertyEditor()
  else
  end
  if show_app.long_text then
    show_app.long_text = demo.ShowExampleAppLongText()
  else
  end
  if show_app.auto_resize then
    show_app.auto_resize = demo.ShowExampleAppAutoResize()
  else
  end
  if show_app.constrained_resize then
    show_app.constrained_resize = demo.ShowExampleAppConstrainedResize()
  else
  end
  if show_app.simple_overlay then
    show_app.simple_overlay = demo.ShowExampleAppSimpleOverlay()
  else
  end
  if show_app.fullscreen then
    show_app.fullscreen = demo.ShowExampleAppFullscreen()
  else
  end
  if show_app.window_titles then
    demo.ShowExampleAppWindowTitles()
  else
  end
  if show_app.custom_rendering then
    show_app.custom_rendering = demo.ShowExampleAppCustomRendering()
  else
  end
  if show_app.metrics then
    show_app.metrics = ImGui.ShowMetricsWindow(ctx, show_app.metrics)
  else
  end
  if show_app.debug_log then
    show_app.debug_log = ImGui.ShowDebugLogWindow(ctx, show_app.debug_log)
  else
  end
  if show_app.stack_tool then
    show_app.stack_tool = ImGui.ShowStackToolWindow(ctx, show_app.stack_tool)
  else
  end
  if show_app.about then
    show_app.about = ImGui.ShowAboutWindow(ctx, show_app.about)
  else
  end
  if show_app.style_editor then
    local _35_
    do
      local rv_34_, arg1_33_ = nil, nil
      do
        local arg1_33_0 = show_app.style_editor
        rv_34_, arg1_33_ = ImGui.Begin(ctx, "Dear ImGui Style Editor", true)
      end
      show_app.style_editor = arg1_33_
      _35_ = rv_34_
    end
    if _35_ then
      demo.ShowStyleEditor()
      ImGui.End(ctx)
    else
    end
  else
  end
  local window_flags = ImGui.WindowFlags_None()
  if demo.no_titlebar then
    window_flags = (window_flags | ImGui.WindowFlags_NoTitleBar())
  else
  end
  if demo.no_scrollbar then
    window_flags = (window_flags | ImGui.WindowFlags_NoScrollbar())
  else
  end
  if not demo.no_menu then
    window_flags = (window_flags | ImGui.WindowFlags_MenuBar())
  else
  end
  if demo.no_move then
    window_flags = (window_flags | ImGui.WindowFlags_NoMove())
  else
  end
  if demo.no_resize then
    window_flags = (window_flags | ImGui.WindowFlags_NoResize())
  else
  end
  if demo.no_collapse then
    window_flags = (window_flags | ImGui.WindowFlags_NoCollapse())
  else
  end
  if demo.no_nav then
    window_flags = (window_flags | ImGui.WindowFlags_NoNav())
  else
  end
  if demo.no_background then
    window_flags = (window_flags | ImGui.WindowFlags_NoBackground())
  else
  end
  if demo.no_docking then
    window_flags = (window_flags | ImGui.WindowFlags_NoDocking())
  else
  end
  if demo.topmost then
    window_flags = (window_flags | ImGui.WindowFlags_TopMost())
  else
  end
  if demo.unsaved_document then
    window_flags = (window_flags | ImGui.WindowFlags_UnsavedDocument())
  else
  end
  if demo.no_close then
    open0 = false
  else
  end
  local main_viewport = ImGui.GetMainViewport(ctx)
  local work_pos = {ImGui.Viewport_GetWorkPos(main_viewport)}
  ImGui.SetNextWindowPos(ctx, (work_pos[1] + 20), (work_pos[2] + 20), ImGui.Cond_FirstUseEver())
  ImGui.SetNextWindowSize(ctx, 550, 680, ImGui.Cond_FirstUseEver())
  if demo.set_dock_id then
    ImGui.SetNextWindowDockID(ctx, demo.set_dock_id)
    demo.set_dock_id = nil
  else
  end
  local _53_
  do
    local rv_52_, arg1_51_ = nil, nil
    do
      local arg1_51_0 = open0
      local _24 = arg1_51_0
      rv_52_, arg1_51_ = ImGui.Begin(ctx, "Dear ImGui Demo", _24, window_flags)
    end
    open0 = arg1_51_
    _53_ = rv_52_
  end
  if _53_ then
    ImGui.PushItemWidth(ctx, (ImGui.GetFontSize(ctx) * ( - 12)))
    if ImGui.BeginMenuBar(ctx) then
      if ImGui.BeginMenu(ctx, "Menu") then
        demo.ShowExampleMenuFile()
        ImGui.EndMenu(ctx)
      else
      end
      if ImGui.BeginMenu(ctx, "Examples") then
        do
          local rv_56_, arg1_55_ = nil, nil
          do
            local arg1_55_0 = show_app.console
            local _24 = arg1_55_0
            rv_56_, arg1_55_ = ImGui.MenuItem(ctx, "Console", nil, _24, false)
          end
          show_app.console = arg1_55_
        end
        do
          local rv_58_, arg1_57_ = nil, nil
          do
            local arg1_57_0 = show_app.log
            local _24 = arg1_57_0
            rv_58_, arg1_57_ = ImGui.MenuItem(ctx, "Log", nil, _24)
          end
          show_app.log = arg1_57_
        end
        do
          local rv_60_, arg1_59_ = nil, nil
          do
            local arg1_59_0 = show_app.layout
            local _24 = arg1_59_0
            rv_60_, arg1_59_ = ImGui.MenuItem(ctx, "Simple layout", nil, _24)
          end
          show_app.layout = arg1_59_
        end
        do
          local rv_62_, arg1_61_ = nil, nil
          do
            local arg1_61_0 = show_app.property_editor
            local _24 = arg1_61_0
            rv_62_, arg1_61_ = ImGui.MenuItem(ctx, "Property editor", nil, _24)
          end
          show_app.property_editor = arg1_61_
        end
        do
          local rv_64_, arg1_63_ = nil, nil
          do
            local arg1_63_0 = show_app.long_text
            local _24 = arg1_63_0
            rv_64_, arg1_63_ = ImGui.MenuItem(ctx, "Long text display", nil, _24)
          end
          show_app.long_text = arg1_63_
        end
        do
          local rv_66_, arg1_65_ = nil, nil
          do
            local arg1_65_0 = show_app.auto_resize
            local _24 = arg1_65_0
            rv_66_, arg1_65_ = ImGui.MenuItem(ctx, "Auto-resizing window", nil, _24)
          end
          show_app.auto_resize = arg1_65_
        end
        do
          local rv_68_, arg1_67_ = nil, nil
          do
            local arg1_67_0 = show_app.constrained_resize
            local _24 = arg1_67_0
            rv_68_, arg1_67_ = ImGui.MenuItem(ctx, "Constrained-resizing window", nil, _24)
          end
          show_app.constrained_resize = arg1_67_
        end
        do
          local rv_70_, arg1_69_ = nil, nil
          do
            local arg1_69_0 = show_app.simple_overlay
            local _24 = arg1_69_0
            rv_70_, arg1_69_ = ImGui.MenuItem(ctx, "Simple overlay", nil, _24)
          end
          show_app.simple_overlay = arg1_69_
        end
        do
          local rv_72_, arg1_71_ = nil, nil
          do
            local arg1_71_0 = show_app.fullscreen
            local _24 = arg1_71_0
            rv_72_, arg1_71_ = ImGui.MenuItem(ctx, "Fullscreen window", nil, _24)
          end
          show_app.fullscreen = arg1_71_
        end
        do
          local rv_74_, arg1_73_ = nil, nil
          do
            local arg1_73_0 = show_app.window_titles
            local _24 = arg1_73_0
            rv_74_, arg1_73_ = ImGui.MenuItem(ctx, "Manipulating window titles", nil, _24)
          end
          show_app.window_titles = arg1_73_
        end
        do
          local rv_76_, arg1_75_ = nil, nil
          do
            local arg1_75_0 = show_app.custom_rendering
            local _24 = arg1_75_0
            rv_76_, arg1_75_ = ImGui.MenuItem(ctx, "Custom rendering", nil, _24)
          end
          show_app.custom_rendering = arg1_75_
        end
        do
          local rv_78_, arg1_77_ = nil, nil
          do
            local arg1_77_0 = show_app.documents
            local _24 = arg1_77_0
            rv_78_, arg1_77_ = ImGui.MenuItem(ctx, "Documents", nil, _24, false)
          end
          show_app.documents = arg1_77_
        end
        ImGui.EndMenu(ctx)
      else
      end
      if ImGui.BeginMenu(ctx, "Tools") then
        do
          local rv_81_, arg1_80_ = nil, nil
          do
            local arg1_80_0 = show_app.metrics
            local _24 = arg1_80_0
            rv_81_, arg1_80_ = ImGui.MenuItem(ctx, "Metrics/Debugger", nil, _24)
          end
          show_app.metrics = arg1_80_
        end
        do
          local rv_83_, arg1_82_ = nil, nil
          do
            local arg1_82_0 = show_app.debug_log
            local _24 = arg1_82_0
            rv_83_, arg1_82_ = ImGui.MenuItem(ctx, "Debug Log", nil, _24)
          end
          show_app.debug_log = arg1_82_
        end
        do
          local rv_85_, arg1_84_ = nil, nil
          do
            local arg1_84_0 = show_app.stack_tool
            local _24 = arg1_84_0
            rv_85_, arg1_84_ = ImGui.MenuItem(ctx, "Stack Tool", nil, _24)
          end
          show_app.stack_tool = arg1_84_
        end
        do
          local rv_87_, arg1_86_ = nil, nil
          do
            local arg1_86_0 = show_app.style_editor
            local _24 = arg1_86_0
            rv_87_, arg1_86_ = ImGui.MenuItem(ctx, "Style Editor", nil, _24)
          end
          show_app.style_editor = arg1_86_
        end
        do
          local rv_89_, arg1_88_ = nil, nil
          do
            local arg1_88_0 = show_app.about
            local _24 = arg1_88_0
            rv_89_, arg1_88_ = ImGui.MenuItem(ctx, "About Dear ImGui", nil, _24)
          end
          show_app.about = arg1_88_
        end
        ImGui.EndMenu(ctx)
      else
      end
      if ImGui.SmallButton(ctx, "Documentation") then
        local doc = ("%s/Data/reaper_imgui_doc.html"):format(reaper.GetResourcePath())
        if reaper.CF_ShellExecute then
          reaper.CF_ShellExecute(doc)
        else
          reaper.MB(doc, "ReaImGui Documentation", 0)
        end
      else
      end
      ImGui.EndMenuBar(ctx)
    else
    end
    ImGui.Text(ctx, ("dear imgui says hello. (%s) (%d) (ReaImGui %s)"):format(IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION))
    ImGui.Spacing(ctx)
    if ImGui.CollapsingHeader(ctx, "Help") then
      ImGui.Text(ctx, "ABOUT THIS DEMO:")
      ImGui.BulletText(ctx, "Sections below are demonstrating many aspects of the library.")
      ImGui.BulletText(ctx, "The \"Examples\" menu above leads to more demo contents.")
      ImGui.BulletText(ctx, ("The \"Tools\" menu above gives access to: About Box, Style Editor, " .. "and Metrics/Debugger (general purpose Dear ImGui debugging tool)."))
      ImGui.Separator(ctx)
      ImGui.Text(ctx, "PROGRAMMER GUIDE:")
      ImGui.BulletText(ctx, "See the ShowDemoWindow() code in ReaImGui_Demo.lua. <- you are here!")
      ImGui.BulletText(ctx, "See example scripts in the examples/ folder.")
      ImGui.Indent(ctx)
      demo.Link("https://github.com/cfillion/reaimgui/tree/master/examples")
      ImGui.Unindent(ctx)
      ImGui.BulletText(ctx, "Read the FAQ at ")
      ImGui.SameLine(ctx, 0, 0)
      demo.Link("https://www.dearimgui.org/faq/")
      ImGui.Separator(ctx)
      ImGui.Text(ctx, "USER GUIDE:")
      demo.ShowUserGuide()
    else
    end
    if ImGui.CollapsingHeader(ctx, "Configuration") then
      if ImGui.TreeNode(ctx, "Configuration##2") then
        local function config_var_checkbox(name)
          local conf_var = assert(reaper[("ImGui_%s"):format(name)], "unknown var")()
          local rv, val = ImGui.Checkbox(ctx, name, ImGui.GetConfigVar(ctx, conf_var))
          if rv then
            local function _95_()
              if val then
                return 1
              else
                return 0
              end
            end
            return ImGui.SetConfigVar(ctx, conf_var, _95_())
          else
            return nil
          end
        end
        config.flags = ImGui.GetConfigVar(ctx, ImGui.ConfigVar_Flags())
        ImGui.SeparatorText(ctx, "General")
        do
          local rv_98_, arg1_97_ = nil, nil
          do
            local arg1_97_0 = config.flags
            local _24 = arg1_97_0
            rv_98_, arg1_97_ = ImGui.CheckboxFlags(ctx, "ConfigFlags_NavEnableKeyboard", _24, ImGui.ConfigFlags_NavEnableKeyboard())
          end
          config.flags = arg1_97_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Enable keyboard controls.")
        do
          local rv_100_, arg1_99_ = nil, nil
          do
            local arg1_99_0 = config.flags
            local _24 = arg1_99_0
            rv_100_, arg1_99_ = ImGui.CheckboxFlags(ctx, "ConfigFlags_NavEnableSetMousePos", _24, ImGui.ConfigFlags_NavEnableSetMousePos())
          end
          config.flags = arg1_99_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Instruct navigation to move the mouse cursor.")
        do
          local rv_102_, arg1_101_ = nil, nil
          do
            local arg1_101_0 = config.flags
            local _24 = arg1_101_0
            rv_102_, arg1_101_ = ImGui.CheckboxFlags(ctx, "ConfigFlags_NoMouse", _24, ImGui.ConfigFlags_NoMouse())
          end
          config.flags = arg1_101_
        end
        if ((config.flags & ImGui.ConfigFlags_NoMouse()) ~= 0) then
          if ((ImGui.GetTime(ctx) % 0.4) < 0.2) then
            ImGui.SameLine(ctx)
            ImGui.Text(ctx, "<<PRESS SPACE TO DISABLE>>")
          else
          end
          if ImGui.IsKeyPressed(ctx, ImGui.Key_Space()) then
            config.flags = (config.flags & ~ImGui.ConfigFlags_NoMouse())
          else
          end
        else
        end
        do
          local rv_107_, arg1_106_ = nil, nil
          do
            local arg1_106_0 = config.flags
            local _24 = arg1_106_0
            rv_107_, arg1_106_ = ImGui.CheckboxFlags(ctx, "ConfigFlags_NoMouseCursorChange", _24, ImGui.ConfigFlags_NoMouseCursorChange())
          end
          config.flags = arg1_106_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Instruct backend to not alter mouse cursor shape and visibility.")
        do
          local rv_109_, arg1_108_ = nil, nil
          do
            local arg1_108_0 = config.flags
            local _24 = arg1_108_0
            rv_109_, arg1_108_ = ImGui.CheckboxFlags(ctx, "ConfigFlags_NoSavedSettings", _24, ImGui.ConfigFlags_NoSavedSettings())
          end
          config.flags = arg1_108_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Globally disable loading and saving state to an .ini file")
        do
          local rv_111_, arg1_110_ = nil, nil
          do
            local arg1_110_0 = config.flags
            local _24 = arg1_110_0
            rv_111_, arg1_110_ = ImGui.CheckboxFlags(ctx, "ConfigFlags_DockingEnable", _24, ImGui.ConfigFlags_DockingEnable())
          end
          config.flags = arg1_110_
        end
        ImGui.SameLine(ctx)
        local function _112_()
          if ImGui.GetConfigVar(ctx, ImGui.ConfigVar_DockingWithShift()) then
            return "enable"
          else
            return "disable"
          end
        end
        demo.HelpMarker(format("Drag from window title bar or their tab to dock/undock. Hold SHIFT to %s docking.\n\nDrag from window menu button (upper-left button) to undock an entire node (all windows).", _112_()))
        if (0 ~= (config.flags & ImGui.ConfigFlags_DockingEnable())) then
          ImGui.Indent(ctx)
          config_var_checkbox("ConfigVar_DockingNoSplit")
          ImGui.SameLine(ctx)
          demo.HelpMarker("Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.")
          config_var_checkbox("ConfigVar_DockingWithShift")
          ImGui.SameLine(ctx)
          demo.HelpMarker("Enable docking when holding Shift only (allow to drop in wider space, reduce visual noise)")
          config_var_checkbox("ConfigVar_DockingTransparentPayload")
          ImGui.SameLine(ctx)
          demo.HelpMarker("Make window or viewport transparent when docking and only display docking boxes on the target viewport.")
          ImGui.Unindent(ctx)
        else
        end
        config_var_checkbox("ConfigVar_ViewportsNoDecoration")
        config_var_checkbox("ConfigVar_InputTrickleEventQueue")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.")
        ImGui.SeparatorText(ctx, "Widgets")
        config_var_checkbox("ConfigVar_InputTextCursorBlink")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Enable blinking cursor (optional as some users consider it to be distracting).")
        config_var_checkbox("ConfigVar_InputTextEnterKeepActive")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Pressing Enter will keep item active and select contents (single-line only).")
        config_var_checkbox("ConfigVar_DragClickToInputText")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving).")
        config_var_checkbox("ConfigVar_WindowsResizeFromEdges")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Enable resizing of windows from their edges and from the lower-left corner.")
        config_var_checkbox("ConfigVar_WindowsMoveFromTitleBarOnly")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Does not apply to windows without a title bar.")
        config_var_checkbox("ConfigVar_MacOSXBehaviors")
        ImGui.Text(ctx, "Also see Style->Rendering for rendering options.")
        ImGui.SetConfigVar(ctx, ImGui.ConfigVar_Flags(), config.flags)
        ImGui.TreePop(ctx)
        ImGui.Spacing(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Style") then
        demo.HelpMarker("The same contents can be accessed in 'Tools->Style Editor'.")
        demo.ShowStyleEditor()
        ImGui.TreePop(ctx)
        ImGui.Spacing(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Capture/Logging") then
        if not config.logging then
          config.logging = {auto_open_depth = 2}
        else
        end
        demo.HelpMarker("The logging API redirects all text output so you can easily capture the content of a window or a block. Tree nodes can be automatically expanded.\nTry opening any of the contents below in this window and then click one of the \"Log To\" button.")
        ImGui.PushID(ctx, "LogButtons")
        do
          local log_to_tty = ImGui.Button(ctx, "Log To TTY")
          local _ = ImGui.SameLine(ctx)
          local log_to_file = ImGui.Button(ctx, "Log To File")
          local _0 = ImGui.SameLine(ctx)
          local log_to_clipboard = ImGui.Button(ctx, "Log To Clipboard")
          local _1
          do
            ImGui.SameLine(ctx)
            ImGui.PushAllowKeyboardFocus(ctx, false)
            ImGui.SetNextItemWidth(ctx, 80)
            do
              local rv_118_, arg1_117_ = nil, nil
              do
                local arg1_117_0 = config.logging.auto_open_depth
                local _24 = arg1_117_0
                rv_118_, arg1_117_ = ImGui.SliderInt(ctx, "Open Depth", _24, 0, 9)
              end
              config.logging.auto_open_depth = arg1_117_
            end
            ImGui.PopAllowKeyboardFocus(ctx)
            _1 = ImGui.PopID(ctx)
          end
          local depth = config.logging.auto_open_depth
          if log_to_tty then
            ImGui.LogToTTY(ctx, depth)
          else
          end
          if log_to_file then
            ImGui.LogToFile(ctx, depth)
          else
          end
          if log_to_clipboard then
            ImGui.LogToClipboard(ctx, depth)
          else
          end
        end
        demo.HelpMarker("You can also call ImGui.LogText() to output directly to the log without a visual output.")
        if ImGui.Button(ctx, "Copy \"Hello, world!\" to clipboard") then
          ImGui.LogToClipboard(ctx, depth)
          ImGui.LogText(ctx, "Hello, world!")
          ImGui.LogFinish(ctx)
        else
        end
        ImGui.TreePop(ctx)
      else
      end
    else
    end
    if ImGui.CollapsingHeader(ctx, "Window options") then
      if ImGui.BeginTable(ctx, "split", 3) then
        ImGui.TableNextColumn(ctx)
        do
          ImGui.TableNextColumn(ctx)
          _, demo.topmost = ImGui.Checkbox(ctx, "Always on top", demo.topmost)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_titlebar = ImGui.Checkbox(ctx, "No titlebar", demo.no_titlebar)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_scrollbar = ImGui.Checkbox(ctx, "No scrollbar", demo.no_scrollbar)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_menu = ImGui.Checkbox(ctx, "No menu", demo.no_menu)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_move = ImGui.Checkbox(ctx, "No move", demo.no_move)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_resize = ImGui.Checkbox(ctx, "No resize", demo.no_resize)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_collapse = ImGui.Checkbox(ctx, "No collapse", demo.no_collapse)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_close = ImGui.Checkbox(ctx, "No close", demo.no_close)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_nav = ImGui.Checkbox(ctx, "No nav", demo.no_nav)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_background = ImGui.Checkbox(ctx, "No background", demo.no_background)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.no_docking = ImGui.Checkbox(ctx, "No docking", demo.no_docking)
        end
        do
          ImGui.TableNextColumn(ctx)
          _, demo.unsaved_document = ImGui.Checkbox(ctx, "Unsaved document", demo.unsaved_document)
        end
        ImGui.EndTable(ctx)
      else
      end
      local flags = ImGui.GetConfigVar(ctx, ImGui.ConfigVar_Flags())
      local docking_disabled = (demo.no_docking or ((flags & ImGui.ConfigFlags_DockingEnable()) == 0))
      ImGui.Spacing(ctx)
      if docking_disabled then
        ImGui.BeginDisabled(ctx)
      else
      end
      do
        local dock_id = ImGui.GetWindowDockID(ctx)
        ImGui.AlignTextToFramePadding(ctx)
        ImGui.Text(ctx, "Dock in docker:")
        ImGui.SameLine(ctx)
        ImGui.SetNextItemWidth(ctx, 222)
        if ImGui.BeginCombo(ctx, "##docker", demo.DockName(dock_id)) then
          if ImGui.Selectable(ctx, "Floating", (dock_id == 0)) then
            demo.set_dock_id = 0
          else
          end
          for id = -1, -16, -1 do
            if ImGui.Selectable(ctx, demo.DockName(id), (dock_id == id)) then
              demo.set_dock_id = id
            else
            end
          end
          ImGui.EndCombo(ctx)
        else
        end
      end
      if docking_disabled then
        ImGui.SameLine(ctx)
        local function _130_()
          if demo.no_docking then
            return "WindowFlags"
          else
            return "ConfigFlags"
          end
        end
        ImGui.Text(ctx, ("Disabled via %s"):format(_130_()))
        ImGui.EndDisabled(ctx)
      else
      end
    else
    end
    demo.ShowDemoWindowWidgets()
    demo.ShowDemoWindowLayout()
    demo.ShowDemoWindowPopups()
    demo.ShowDemoWindowTables()
    demo.ShowDemoWindowInputs()
    ImGui.PopItemWidth(ctx)
    ImGui.End(ctx)
    return open0
  else
    return nil
  end
end
demo.ShowDemoWindowWidgets = function()
  if ImGui.CollapsingHeader(ctx, "Widgets") then
    if widgets.disable_all then
      ImGui.BeginDisabled(ctx)
    else
    end
    local rv = nil
    if ImGui.TreeNode(ctx, "Basic") then
      if not widgets.basic then
        widgets.basic = {angle = 0, check = true, clicked = 0, col1 = 16711731, col2 = 1722941567, counter = 0, curitem = 0, d0 = 999999.00000001, d1 = 10000000000, d2 = 1, d3 = 0.0067, d4 = 0.123, d5 = 0, elem = 1, i0 = 123, i1 = 50, i2 = 42, i3 = 0, listcur = 0, radio = 0, str0 = "Hello, world!", str1 = "", tooltip = reaper.new_array({0.6, 0.1, 1, 0.5, 0.92, 0.1, 0.2}), vec4a = reaper.new_array({0.1, 0.2, 0.3, 0.44})}
      else
      end
      ImGui.SeparatorText(ctx, "General")
      if ImGui.Button(ctx, "Button") then
        widgets.basic.clicked = (widgets.basic.clicked + 1)
      else
      end
      if ((widgets.basic.clicked & 1) ~= 0) then
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Thanks for clicking me!")
      else
      end
      do
        local rv_139_, arg1_138_ = nil, nil
        do
          local arg1_138_0 = widgets.basic.check
          local _24 = arg1_138_0
          rv_139_, arg1_138_ = ImGui.Checkbox(ctx, "checkbox", _24)
        end
        widgets.basic.check = arg1_138_
      end
      do
        local rv_141_, arg1_140_ = nil, nil
        do
          local arg1_140_0 = widgets.basic.radio
          local _24 = arg1_140_0
          rv_141_, arg1_140_ = ImGui.RadioButtonEx(ctx, "radio a", _24, 0)
        end
        widgets.basic.radio = arg1_140_
      end
      ImGui.SameLine(ctx)
      do
        local rv_143_, arg1_142_ = nil, nil
        do
          local arg1_142_0 = widgets.basic.radio
          local _24 = arg1_142_0
          rv_143_, arg1_142_ = ImGui.RadioButtonEx(ctx, "radio b", _24, 1)
        end
        widgets.basic.radio = arg1_142_
      end
      ImGui.SameLine(ctx)
      do
        local rv_145_, arg1_144_ = nil, nil
        do
          local arg1_144_0 = widgets.basic.radio
          local _24 = arg1_144_0
          rv_145_, arg1_144_ = ImGui.RadioButtonEx(ctx, "radio c", _24, 2)
        end
        widgets.basic.radio = arg1_144_
      end
      for i = 0, 6 do
        if (i > 0) then
          ImGui.SameLine(ctx)
        else
        end
        ImGui.PushID(ctx, i)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(), demo.HSV((i / 7), 0.6, 0.6, 1))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), demo.HSV((i / 7), 0.7, 0.7, 1))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), demo.HSV((i / 7), 0.8, 0.8, 1))
        ImGui.Button(ctx, "Click")
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopID(ctx)
      end
      ImGui.AlignTextToFramePadding(ctx)
      ImGui.Text(ctx, "Hold to repeat:")
      ImGui.SameLine(ctx)
      local spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing())
      ImGui.PushButtonRepeat(ctx, true)
      if ImGui.ArrowButton(ctx, "##left", ImGui.Dir_Left()) then
        widgets.basic.counter = (widgets.basic.counter - 1)
      else
      end
      ImGui.SameLine(ctx, 0, spacing)
      if ImGui.ArrowButton(ctx, "##right", ImGui.Dir_Right()) then
        widgets.basic.counter = (widgets.basic.counter + 1)
      else
      end
      ImGui.PopButtonRepeat(ctx)
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, ("%d"):format(widgets.basic.counter))
      do
        ImGui.Text(ctx, "Tooltips:")
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Button")
        if ImGui.IsItemHovered(ctx) then
          ImGui.SetTooltip(ctx, "I am a tooltip")
        else
        end
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Fancy")
        if ImGui.IsItemHovered(ctx) then
          ImGui.BeginTooltip(ctx)
          ImGui.Text(ctx, "I am a fancy tooltip")
          ImGui.PlotLines(ctx, "Curve", widgets.basic.tooltip)
          ImGui.Text(ctx, ("Sin(time) = %f"):format(math.sin(ImGui.GetTime(ctx))))
          ImGui.EndTooltip(ctx)
        else
        end
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Delayed")
        if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayNormal()) then
          ImGui.SetTooltip(ctx, "I am a tooltip with a delay.")
        else
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Tooltip are created by using the IsItemHovered() function over any kind of item.")
      end
      ImGui.LabelText(ctx, "label", "Value")
      ImGui.SeparatorText(ctx, "Inputs")
      do
        do
          local rv_153_, arg1_152_ = nil, nil
          do
            local arg1_152_0 = widgets.basic.str0
            local _24 = arg1_152_0
            rv_153_, arg1_152_ = ImGui.InputText(ctx, "input text", _24)
          end
          widgets.basic.str0 = arg1_152_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("USER:\n        Hold SHIFT or use mouse to select text.\n        CTRL+Left/Right to word jump.\n        CTRL+A or double-click to select all.\n        CTRL+X,CTRL+C,CTRL+V clipboard.\n        CTRL+Z,CTRL+Y undo/redo.\n        ESCAPE to revert.\n\n        ")
        do
          local rv_155_, arg1_154_ = nil, nil
          do
            local arg1_154_0 = widgets.basic.str1
            local _24 = arg1_154_0
            rv_155_, arg1_154_ = ImGui.InputTextWithHint(ctx, "input text (w/ hint)", "enter text here", _24)
          end
          widgets.basic.str1 = arg1_154_
        end
        do
          local rv_157_, arg1_156_ = nil, nil
          do
            local arg1_156_0 = widgets.basic.i0
            local _24 = arg1_156_0
            rv_157_, arg1_156_ = ImGui.InputInt(ctx, "input int", _24)
          end
          widgets.basic.i0 = arg1_156_
        end
        do
          local rv_159_, arg1_158_ = nil, nil
          do
            local arg1_158_0 = widgets.basic.d0
            local _24 = arg1_158_0
            rv_159_, arg1_158_ = ImGui.InputDouble(ctx, "input double", _24, 0.01, 1, "%.8f")
          end
          widgets.basic.d0 = arg1_158_
        end
        do
          local rv_161_, arg1_160_ = nil, nil
          do
            local arg1_160_0 = widgets.basic.d1
            local _24 = arg1_160_0
            rv_161_, arg1_160_ = ImGui.InputDouble(ctx, "input scientific", _24, 0, 0, "%e")
          end
          widgets.basic.d1 = arg1_160_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("You can input value using the scientific notation,\n        e.g. \"1e+8\" becomes \"100000000\".")
        ImGui.InputDoubleN(ctx, "input reaper.array", widgets.basic.vec4a)
      end
      ImGui.SeparatorText(ctx, "Drags")
      do
        rv, widgets.basic.i1 = ImGui.DragInt(ctx, "drag int", widgets.basic.i1, 1)
        ImGui.SameLine(ctx)
        demo.HelpMarker("Click and drag to edit value.\n        Hold SHIFT/ALT for faster/slower edit.\n        Double-click or CTRL+click to input value.")
        rv, widgets.basic.i2 = ImGui.DragInt(ctx, "drag int 0..100", widgets.basic.i2, 1, 0, 100, "%d%%", ImGui.SliderFlags_AlwaysClamp())
        rv, widgets.basic.d2 = ImGui.DragDouble(ctx, "drag double", widgets.basic.d2, 0.005)
        rv, widgets.basic.d3 = ImGui.DragDouble(ctx, "drag small double", widgets.basic.d3, 0.0001, 0, 0, "%.06f ns")
      end
      ImGui.SeparatorText(ctx, "Sliders")
      do
        rv, widgets.basic.i3 = ImGui.SliderInt(ctx, "slider int", widgets.basic.i3, ( - 1), 3)
        ImGui.SameLine(ctx)
        demo.HelpMarker("CTRL+click to input value.")
        rv, widgets.basic.d4 = ImGui.SliderDouble(ctx, "slider double", widgets.basic.d4, 0, 1, "ratio = %.3f")
        rv, widgets.basic.d5 = ImGui.SliderDouble(ctx, "slider double (log)", widgets.basic.d5, ( - 10), 10, "%.4f", ImGui.SliderFlags_Logarithmic())
        rv, widgets.basic.angle = ImGui.SliderAngle(ctx, "slider angle", widgets.basic.angle)
        local elements = {"Fire", "Earth", "Air", "Water"}
        local current_elem = (elements[widgets.basic.elem] or "Unknown")
        rv, widgets.basic.elem = ImGui.SliderInt(ctx, "slider enum", widgets.basic.elem, 1, #elements, current_elem)
        ImGui.SameLine(ctx)
        demo.HelpMarker("Using the format string parameter to display a name instead of the underlying integer.")
      end
      ImGui.SeparatorText(ctx, "Selectors/Pickers")
      do
        foo = widgets.basic.col1
        rv, widgets.basic.col1 = ImGui.ColorEdit3(ctx, "color 1", widgets.basic.col1)
        ImGui.SameLine(ctx)
        demo.HelpMarker("Click on the color square to open a color picker.\n        Click and hold to use drag and drop.\n        Right-click on the color square to show options.\n        CTRL+click on individual component to input value.")
        rv, widgets.basic.col2 = ImGui.ColorEdit4(ctx, "color 2", widgets.basic.col2)
      end
      do
        local items = "AAAA\0BBBB\0CCCC\0DDDD\0EEEE\0FFFF\0GGGG\0HHHH\0IIIIIII\0JJJJ\0KKKKKKK\0"
        rv, widgets.basic.curitem = ImGui.Combo(ctx, "combo", widgets.basic.curitem, items)
        ImGui.SameLine(ctx)
        demo.HelpMarker(("Using the simplified one-liner Combo API here.\n" .. "Refer to the \"Combo\" section below for an explanation of how to use the more flexible and general BeginCombo/EndCombo API."))
      end
      do
        local items = "Apple\0Banana\0Cherry\0Kiwi\0Mango\0Orange\0Pineapple\0Strawberry\0Watermelon\0"
        rv, widgets.basic.listcur = ImGui.ListBox(ctx, "listbox\n(single select)", widgets.basic.listcur, items, 4)
        ImGui.SameLine(ctx)
        demo.HelpMarker("Using the simplified one-liner ListBox API here.\n        Refer to the \"List boxes\" section below for an explanation of how to usethe more flexible and general BeginListBox/EndListBox API.")
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Trees") then
      if not widgets.trees then
        widgets.trees = {base_flags = (ImGui.TreeNodeFlags_OpenOnArrow() | ImGui.TreeNodeFlags_OpenOnDoubleClick() | ImGui.TreeNodeFlags_SpanAvailWidth()), selection_mask = (1 << 2), test_drag_and_drop = false, align_label_with_current_x_position = false}
      else
      end
      if ImGui.TreeNode(ctx, "Basic trees") then
        for i = 0, 4 do
          if (i == 0) then
            ImGui.SetNextItemOpen(ctx, true, ImGui.Cond_Once())
          else
          end
          if ImGui.TreeNodeEx(ctx, i, ("Child %d"):format(i)) then
            ImGui.Text(ctx, "blah blah")
            ImGui.SameLine(ctx)
            if ImGui.SmallButton(ctx, "button") then
            else
            end
            ImGui.TreePop(ctx)
          else
          end
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Advanced, with Selectable nodes") then
        demo.HelpMarker("This is a more typical looking tree with selectable nodes.\n        Click to select, CTRL+Click to toggle, click on arrows or double-click to open.")
        do
          local rv_169_, arg1_168_ = nil, nil
          do
            local arg1_168_0 = widgets.trees.base_flags
            local _24 = arg1_168_0
            rv_169_, arg1_168_ = ImGui.CheckboxFlags(ctx, "ImGui_TreeNodeFlags_OpenOnArrow", _24, ImGui.TreeNodeFlags_OpenOnArrow())
          end
          widgets.trees.base_flags = arg1_168_
        end
        do
          local rv_171_, arg1_170_ = nil, nil
          do
            local arg1_170_0 = widgets.trees.base_flags
            local _24 = arg1_170_0
            rv_171_, arg1_170_ = ImGui.CheckboxFlags(ctx, "ImGui_TreeNodeFlags_OpenOnDoubleClick", _24, ImGui.TreeNodeFlags_OpenOnDoubleClick())
          end
          widgets.trees.base_flags = arg1_170_
        end
        do
          local rv_173_, arg1_172_ = nil, nil
          do
            local arg1_172_0 = widgets.trees.base_flags
            local _24 = arg1_172_0
            rv_173_, arg1_172_ = ImGui.CheckboxFlags(ctx, "ImGui_TreeNodeFlags_SpanAvailWidth", _24, ImGui.TreeNodeFlags_SpanAvailWidth())
          end
          widgets.trees.base_flags = arg1_172_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Extend hit area to all available width instead of allowing more items to be laid out after the node.")
        do
          local rv_175_, arg1_174_ = nil, nil
          do
            local arg1_174_0 = widgets.trees.base_flags
            local _24 = arg1_174_0
            rv_175_, arg1_174_ = ImGui.CheckboxFlags(ctx, "ImGuiTreeNodeFlags_SpanFullWidth", _24, ImGui.TreeNodeFlags_SpanFullWidth())
          end
          widgets.trees.base_flags = arg1_174_
        end
        do
          local rv_177_, arg1_176_ = nil, nil
          do
            local arg1_176_0 = widgets.trees.align_label_with_current_x_position
            local _24 = arg1_176_0
            rv_177_, arg1_176_ = ImGui.Checkbox(ctx, "Align label with current X position", _24)
          end
          widgets.trees.align_label_with_current_x_position = arg1_176_
        end
        do
          local rv_179_, arg1_178_ = nil, nil
          do
            local arg1_178_0 = widgets.trees.test_drag_and_drop
            local _24 = arg1_178_0
            rv_179_, arg1_178_ = ImGui.Checkbox(ctx, "Test tree node as drag source", _24)
          end
          widgets.trees.test_drag_and_drop = arg1_178_
        end
        ImGui.Text(ctx, "Hello!")
        if widgets.trees.align_label_with_current_x_position then
          ImGui.Unindent(ctx, ImGui.GetTreeNodeToLabelSpacing(ctx))
        else
        end
        local node_clicked = -1
        for i = 0, 5 do
          local node_flags = widgets.trees.base_flags
          do
            local is_selected = ((widgets.trees.selection_mask & (1 << i)) ~= 0)
            if is_selected then
              node_flags = (node_flags | ImGui.TreeNodeFlags_Selected())
            else
            end
          end
          if (i < 3) then
            local node_open = ImGui.TreeNodeEx(ctx, i, ("Selectable Node %d"):format(i), node_flags)
            if (ImGui.IsItemClicked(ctx) and not ImGui.IsItemToggledOpen(ctx)) then
              node_clicked = i
            else
            end
            if (widgets.trees.test_drag_and_drop and ImGui.BeginDragDropSource(ctx)) then
              ImGui.SetDragDropPayload(ctx, "_TREENODE", nil, 0)
              ImGui.Text(ctx, "This is a drag and drop source")
              ImGui.EndDragDropSource(ctx)
            else
            end
            if node_open then
              ImGui.BulletText(ctx, "Blah blah\nBlah Blah")
              ImGui.TreePop(ctx)
            else
            end
          else
            node_flags = (node_flags | ImGui.TreeNodeFlags_Leaf() | ImGui.TreeNodeFlags_NoTreePushOnOpen())
            ImGui.TreeNodeEx(ctx, i, ("Selectable Leaf %d"):format(i), node_flags)
            if (ImGui.IsItemClicked(ctx) and not ImGui.IsItemToggledOpen(ctx)) then
              node_clicked = i
            else
            end
            if (widgets.trees.test_drag_and_drop and ImGui.BeginDragDropSource(ctx)) then
              ImGui.SetDragDropPayload(ctx, "_TREENODE", nil, 0)
              ImGui.Text(ctx, "This is a drag and drop source")
              ImGui.EndDragDropSource(ctx)
            else
            end
          end
        end
        if (node_clicked ~= -1) then
          if ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl()) then
            widgets.trees.selection_mask = (widgets.trees.selection_mask ~ (1 << node_clicked))
          elseif ((widgets.trees.selection_mask & (1 << node_clicked)) == 0) then
            widgets.trees.selection_mask = (1 << node_clicked)
          else
          end
        else
        end
        if widgets.trees.align_label_with_current_x_position then
          ImGui.Indent(ctx, ImGui.GetTreeNodeToLabelSpacing(ctx))
        else
        end
        ImGui.TreePop(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Collapsing Headers") then
      if not widgets.cheads then
        widgets.cheads = {closable_group = true}
      else
      end
      do
        local rv_195_, arg1_194_ = nil, nil
        do
          local arg1_194_0 = widgets.cheads.closable_group
          local _24 = arg1_194_0
          rv_195_, arg1_194_ = ImGui.Checkbox(ctx, "Show 2nd header", _24)
        end
        widgets.cheads.closable_group = arg1_194_
      end
      if ImGui.CollapsingHeader(ctx, "Header", nil, ImGui.TreeNodeFlags_None()) then
        ImGui.Text(ctx, ("IsItemHovered: %s"):format(ImGui.IsItemHovered(ctx)))
        for i = 0, 4 do
          ImGui.Text(ctx, ("Some content %s"):format(i))
        end
      else
      end
      if widgets.cheads.closable_group then
        local _199_
        do
          local rv_198_, arg1_197_ = nil, nil
          do
            local arg1_197_0 = widgets.cheads.closable_group
            rv_198_, arg1_197_ = ImGui.CollapsingHeader(ctx, "Header with a close button", true)
          end
          widgets.cheads.closable_group = arg1_197_
          _199_ = rv_198_
        end
        if _199_ then
          ImGui.Text(ctx, ("IsItemHovered: %s"):format(ImGui.IsItemHovered(ctx)))
          for i = 0, 4 do
            ImGui.Text(ctx, ("More content %d"):format(i))
          end
        else
        end
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Bullets") then
      ImGui.BulletText(ctx, "Bullet point 1")
      ImGui.BulletText(ctx, "Bullet point 2\nOn multiple lines")
      if ImGui.TreeNode(ctx, "Tree node") then
        ImGui.BulletText(ctx, "Another bullet point")
        ImGui.TreePop(ctx)
      else
      end
      ImGui.Bullet(ctx)
      ImGui.Text(ctx, "Bullet point 3 (two calls)")
      ImGui.Bullet(ctx)
      ImGui.SmallButton(ctx, "Button")
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Text") then
      if not widgets.text then
        widgets.text = {utf8 = "\230\151\165\230\156\172\232\170\158", wrap_width = 200}
      else
      end
      if ImGui.TreeNode(ctx, "Colorful Text") then
        ImGui.TextColored(ctx, 4278255615, "Pink")
        ImGui.TextColored(ctx, 4294902015, "Yellow")
        ImGui.TextDisabled(ctx, "Disabled")
        ImGui.SameLine(ctx)
        demo.HelpMarker("The TextDisabled color is stored in ImGuiStyle.")
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Word Wrapping") then
        ImGui.TextWrapped(ctx, ("This text should automatically wrap on the edge of the window. The current implementation " .. "for text wrapping follows simple rules suitable for English and possibly other languages."))
        ImGui.Spacing(ctx)
        do
          local rv_208_, arg1_207_ = nil, nil
          do
            local arg1_207_0 = widgets.text.wrap_width
            local _24 = arg1_207_0
            rv_208_, arg1_207_ = ImGui.SliderDouble(ctx, "Wrap width", _24, ( - 20), 600, "%.0f")
          end
          widgets.text.wrap_width = arg1_207_
        end
        local draw_list = ImGui.GetWindowDrawList(ctx)
        for n = 0, 1 do
          ImGui.Text(ctx, ("Test paragraph %d:"):format(n))
          local screen_x, screen_y = ImGui.GetCursorScreenPos(ctx)
          local marker_min_x = (screen_x + widgets.text.wrap_width)
          local marker_min_y = screen_y
          local marker_max_x = (screen_x + widgets.text.wrap_width + 10)
          local marker_max_y = (screen_y + ImGui.GetTextLineHeight(ctx))
          local window_x, window_y = ImGui.GetCursorPos(ctx)
          ImGui.PushTextWrapPos(ctx, (window_x + widgets.text.wrap_width))
          if (n == 0) then
            ImGui.Text(ctx, ("The lazy dog is a good dog. This paragraph should fit within %.0f pixels. Testing a 1 character word. The quick brown fox jumps over the lazy dog."):format(widgets.text.wrap_width))
          else
            ImGui.Text(ctx, "aaaaaaaa bbbbbbbb, c cccccccc,dddddddd. d eeeeeeee   ffffffff. gggggggg!hhhhhhhh")
          end
          local text_min_x, text_min_y = ImGui.GetItemRectMin(ctx)
          local text_max_x, text_max_y = ImGui.GetItemRectMax(ctx)
          ImGui.DrawList_AddRect(draw_list, text_min_x, text_min_y, text_max_x, text_max_y, 4294902015)
          ImGui.DrawList_AddRectFilled(draw_list, marker_min_x, marker_min_y, marker_max_x, marker_max_y, 4278255615)
          ImGui.PopTextWrapPos(ctx)
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "UTF-8 Text") then
        ImGui.TextWrapped(ctx, "CJK text cannot be rendered due to current limitations regarding font rasterization. It is however safe to copy & paste from/into another application.")
        demo.Link("https://github.com/cfillion/reaimgui/issues/5")
        ImGui.Spacing(ctx)
        ImGui.Text(ctx, "Hiragana: \227\129\139\227\129\141\227\129\143\227\129\145\227\129\147 (kakikukeko)")
        ImGui.Text(ctx, "Kanjis: \230\151\165\230\156\172\232\170\158 (nihongo)")
        rv, widgets.text.utf8 = ImGui.InputText(ctx, "UTF-8 input", widgets.text.utf8)
        ImGui.TreePop(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Images") then
      if not widgets.images then
        widgets.images = {pressed_count = 0, use_text_color_for_tint = false}
      else
      end
      if not ImGui.ValidatePtr(widgets.images.bitmap, "ImGui_Image*") then
        widgets.images.bitmap = ImGui.CreateImageFromMem("\137PNG\13\n             \26\n             \0\0\0\13IHDR\0\0\1\157\0\0\0E\8\0\0\0\0\180\174d\136\0\0\6-IDATx\218\237\157\191n\2276\28\199\191\195\1w\195\25G/\9ph!\8\135\0032\20\8$ \30:\164\3\129+\208\1770\244\6\234\24d\226\212\177\131\243\0\29\184v\244\208\23\224+\232\21\244\n             z\133_\7J\178\157\136\180\164#m\218\229oI\":$\205\143\249\251K\201\160!Q\20%\4\193\208\197\18\219\1842\161\210)\1\214\196\165\9\147\142\0\1282.M\144t\20\0\0u\\\155\16\233\164\154N\220<!\210\217\2\0D\137hy\2\164\179\6\192\20)H\7\189\243\255\221zJ\233\149\14\0V\17\17\184\143\222\175^\132\240I\167\2t\176\3\23\170-\210q\187~\n             \237\166\1T\164\19\26\29\209Q\1D\164\19\30\157\180\179?e\164\19\26\157m\187ej\184p\11\"\29\215vGtaO\164\19 \29mvJ`\29\233\156\157N\197\15$C\1989\231\143\239\128\132\127\183\128\251\150\199\236\241\240\239/K\224C\194O \217\207\3\23\19\23C?<p\158eY\246\215\235Ow\1735\155\192\133x\212\234p\154\27v\186,\225\160S\235d\239pN\4\0\2\131c6\12`tqt\1545:i\174\147N\190&\157l+/\143\14\239\225\160\186N:e\218\230\169\235\139\163#wp\24]'\29\137\186fp\146)pL\167\217p \21f:\249\142\142\24\221\193e\209\169\177\201\1\164Mht\134\13\254>\157\29\156\188\25\221\193e\209ik\163n\206L\185\163c2\248\251t\222\217\224\184\247\24\206B\135\195\149^sI\199d\240\247\233$\157Zk&t\0166\157F\29\2023\0d\202*\255>\23\143Y\241\167:*P\142\228y\183\182\31\15\26^\240\210\255\158\253\254\21\248Z\2523\169\131\249\130b\224bQ8\2329\203\148\2\128?P\139\3\249\6\0\183O\194\"O\247x\255\173(\138\213m!\142\8\196Dy\250%\1>\173\222\\\191\221-\238ac\129\221$\18\203|\140\29\28\25\216\246\230\134^\189Z\137\239\151$\17\2\0\n             \188v\129\142:\211\21\3\211/hr\233X\179\25\13\183\209\224\239k6n1\150\30<\134\147\219\157\138\29\165S\179\206*5\"g\181K:f\195\173\140\6\127,\29\15\30\195\169\2334)\0\182\197\230\136y\222\246\225E\233\146\142\217p+\163\193\31K\199\131\1990\153\206a\170s2\29\14\0\146RK\237\160\234\221\237-\128\174\144:\137\142)(\180\132\250\138\203\28\200Em\205\21\216\232\240gC\7#r\12\134\9O\166\131\3\153JGh8TZ\254S\244\0310yl\12\3\29\163\138\183\132\250\138\143\201\228X\233X\218\142\228\24L\19>-\157\170\155\194\214\18\139\242\190\227\0268Z?\197\4\21_Y\12\183_:V\143\193<\225\211\210\225\0r\"\162\198\18\140\238u,\25\242j*\29\139m\177\24n\191t\172\30\131y\194'\165#\129\206U\206\249\24:sr\0056\219b1\220~\233\216<\6\203\132OA\167\175\\/\0|\209\133\211\5\150\159\147\135\225Z4\128\17\245\232\182\128\252\230\149\139\221\236^\151x\179\229\221\2X$C\245\224li,\31\235J;\231\156\243ef\158\144\181\237G\227\192\182\9\31^x\188\187Y\0\248\248\131\131\202\245r\169\23\250W\236\171}NDTu{9U\179\247NgH1A\197+\139\13\243\187wf\218\164\131\189#\24\0Q\211\253\189\151x\167;IP1\171\7\195G\208\177\4w\152c[\206I\199b\147\246\150\167\201\1\240\154\136\158\239\188\208\225\218%\168\217\190n,-\0305\17\17\149jZp\1359\182\229\156t,6i\143\206\26`:D\23k/tr@\234q\144\11\206d\201\208g\5\6\163Q\"\162\134M3\164\4i\12\n             \195\164c\137bwt\20\176n\218\15\239\198\11\29\157^\171\1&\137\4\26\173\159RK&\135\1366|bp\1359\4\206JG\141\200\228\148\237\173hU\238\230f\245!:\169N\207l\250\247\\\234\212\129)\11JT\165\245\196\224\238:\233\164\178\215\250N\202\150Cv\135S\127\11B\27\143\242\161\227\186\187\n             B\149\14\6\163\204\18\220]'\29\16\17\169\220\217\153\133\183t\214-\29\189\14:\17Z\15\1669\155\18L*\181-yeN\197\25\130\187\235\164\147o\168*\1\164\142n\26}\27\141&Xr\2063\232\184\239\230C\23\139\13\198\154w\201\205\210\16\174r\206\205Q\165\237`\1819\226\244\30\141\206k\219E\163\15K\0\203\207?\185:\161=\20\141\230DDL\1555\129\246\135\227\243\130\215\185w\\\203@\158-GMDB\143\217\190i\161\145E:g\167#\245h9$\17\213\218Y+]\31\230\143tf\210\161\28\21\0175\28e?t\n             \21\233\132A\167j]\224\141h_@\18\174\31\214\17\233\204\165Cr/BY\231D\13cU\164\19\n             \29\146].\143H\128\234\28\146\"\157`\232\144J\193e\221\250\8\140\185\127<h\1643\141\206\225I\221\167\213'\0\201-\128\247\171'\225\\,Gw\139dN\219\216\147\186\30\218\176\18\158dwR\247\245)w\245wQdE\241\219\222\233q\135b9\246\254\146\205k\27yp\252\197}\155w\169M\170\166qos\188h\182\209\202\194\131\214\243/8\173V\141t\230/W\179\17\155&\210\9\147\142b\221\131\13#\157\224\2324\186l\198\3\164\227W.\130\206\6{O\162\174\131\242\n    \"\157\190\166\217\222\255\161\"\157\0\247\142>\229T2\138tB\162\211\222\162!\181\13*OM\135\228\185\214@\210\5\208!\142\148\175\245l\214\158\190\7\225\226\30\167\23\14\157\170\175\24\148\1902|\145\206\252\229\146\12\162\"\218roO\159\187\184G\239\11\n    \134NwwH\26\191\186*\12y\243\228I)D\252\214\183P\228?\184\169h\6\27Ew\150\0\0\0\0IEND\174B`\130")
      else
      end
      ImGui.TextWrapped(ctx, "Hover the texture for a zoomed view!")
      local my_tex_w, my_tex_h = ImGui.Image_GetSize(widgets.images.bitmap)
      do
        rv, widgets.images.use_text_color_for_tint = ImGui.Checkbox(ctx, "Use Text Color for Tint", widgets.images.use_text_color_for_tint)
        ImGui.Text(ctx, ("%.0fx%.0f"):format(my_tex_w, my_tex_h))
        local pos_x, pos_y = ImGui.GetCursorScreenPos(ctx)
        local uv_min_x, uv_min_y = 0, 0
        local uv_max_x, uv_max_y = 1, 1
        local tint_col = ((widgets.images.use_text_color_for_tint and ImGui.GetStyleColor(ctx, ImGui.Col_Text())) or 4294967295)
        local border_col = ImGui.GetStyleColor(ctx, ImGui.Col_Border())
        ImGui.Image(ctx, widgets.images.bitmap, my_tex_w, my_tex_h, uv_min_x, uv_min_y, uv_max_x, uv_max_y, tint_col, border_col)
        if ImGui.IsItemHovered(ctx) then
          ImGui.BeginTooltip(ctx)
          local region_sz = 32
          local mouse_x, mouse_y = ImGui.GetMousePos(ctx)
          local region_x = ((mouse_x - pos_x) - (region_sz * 0.5))
          local region_y = ((mouse_y - pos_y) - (region_sz * 0.5))
          local zoom = 4
          if (region_x < 0) then
            region_x = 0
          elseif (region_x > (my_tex_w - region_sz)) then
            region_x = (my_tex_w - region_sz)
          else
          end
          if (region_y < 0) then
            region_y = 0
          elseif (region_y > (my_tex_h - region_sz)) then
            region_y = (my_tex_h - region_sz)
          else
          end
          ImGui.Text(ctx, ("Min: (%.2f, %.2f)"):format(region_x, region_y))
          ImGui.Text(ctx, ("Max: (%.2f, %.2f)"):format((region_x + region_sz), (region_y + region_sz)))
          local uv0_x, uv0_y = (region_x / my_tex_w), (region_y / my_tex_h)
          local uv1_x, uv1_y = ((region_x + region_sz) / my_tex_w), ((region_y + region_sz) / my_tex_h)
          ImGui.Image(ctx, widgets.images.bitmap, (region_sz * zoom), (region_sz * zoom), uv0_x, uv0_y, uv1_x, uv1_y, tint_col, border_col)
          ImGui.EndTooltip(ctx)
        else
        end
      end
      ImGui.TextWrapped(ctx, "And now some textured buttons...")
      for i = 0, 8 do
        if (i > 0) then
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), (i - 1), (i - 1))
        else
        end
        local size_w, size_h = 32, 32
        local uv0_x, uv0_y = 0, 0
        local uv1_x, uv1_y = (32 / my_tex_w), (32 / my_tex_h)
        local bg_col = 255
        local tint_col = 4294967295
        if ImGui.ImageButton(ctx, i, widgets.images.bitmap, size_w, size_h, uv0_x, uv0_y, uv1_x, uv1_y, bg_col, tint_col) then
          widgets.images.pressed_count = (widgets.images.pressed_count + 1)
        else
        end
        if (i > 0) then
          ImGui.PopStyleVar(ctx)
        else
        end
        ImGui.SameLine(ctx)
      end
      ImGui.NewLine(ctx)
      ImGui.Text(ctx, ("Pressed %d times."):format(widgets.images.pressed_count))
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Combo") then
      if not widgets.combos then
        widgets.combos = {current_item1 = 1, current_item2 = 0, current_item3 = ( - 1), flags = ImGui.ComboFlags_None()}
      else
      end
      rv, widgets.combos.flags = ImGui.CheckboxFlags(ctx, "ImGuiComboFlags_PopupAlignLeft", widgets.combos.flags, ImGui.ComboFlags_PopupAlignLeft())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Only makes a difference if the popup is larger than the combo")
      rv, widgets.combos.flags = ImGui.CheckboxFlags(ctx, "ImGuiComboFlags_NoArrowButton", widgets.combos.flags, ImGui.ComboFlags_NoArrowButton())
      if rv then
        widgets.combos.flags = (widgets.combos.flags & ~ImGui.ComboFlags_NoPreview())
      else
      end
      rv, widgets.combos.flags = ImGui.CheckboxFlags(ctx, "ImGuiComboFlags_NoPreview", widgets.combos.flags, ImGui.ComboFlags_NoPreview())
      if rv then
        widgets.combos.flags = (widgets.combos.flags & ~ImGui.ComboFlags_NoArrowButton())
      else
      end
      local combo_items = {"AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ", "KKKK", "LLLLLLL", "MMMM", "OOOOOOO"}
      local combo_preview_value = combo_items[widgets.combos.current_item1]
      if ImGui.BeginCombo(ctx, "combo 1", combo_preview_value, widgets.combos.flags) then
        for i, v in ipairs(combo_items) do
          local is_selected = (widgets.combos.current_item1 == i)
          if ImGui.Selectable(ctx, combo_items[i], is_selected) then
            widgets.combos.current_item1 = i
          else
          end
          if is_selected then
            ImGui.SetItemDefaultFocus(ctx)
          else
          end
        end
        ImGui.EndCombo(ctx)
      else
      end
      combo_items = "aaaa\0bbbb\0cccc\0dddd\0eeee\0"
      rv, widgets.combos.current_item2 = ImGui.Combo(ctx, "combo 2 (one-liner)", widgets.combos.current_item2, combo_items)
      rv, widgets.combos.current_item3 = ImGui.Combo(ctx, "combo 3 (out of range)", widgets.combos.current_item3, combo_items)
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "List boxes") then
      if not widgets.lists then
        widgets.lists = {current_idx = 1}
      else
      end
      local items = {"AAAA", "BBBB", "CCCC", "DDDD", "EEEE", "FFFF", "GGGG", "HHHH", "IIII", "JJJJ", "KKKK", "LLLLLLL", "MMMM", "OOOOOOO"}
      if ImGui.BeginListBox(ctx, "listbox 1") then
        for n, v in ipairs(items) do
          local is_selected = (widgets.lists.current_idx == n)
          if ImGui.Selectable(ctx, v, is_selected) then
            widgets.lists.current_idx = n
          else
          end
          if is_selected then
            ImGui.SetItemDefaultFocus(ctx)
          else
          end
        end
        ImGui.EndListBox(ctx)
      else
      end
      ImGui.Text(ctx, "Full-width:")
      if ImGui.BeginListBox(ctx, "##listbox 2", ( - FLT_MIN), (5 * ImGui.GetTextLineHeightWithSpacing(ctx))) then
        for n, v in ipairs(items) do
          local is_selected = (widgets.lists.current_idx == n)
          if ImGui.Selectable(ctx, v, is_selected) then
            widgets.lists.current_idx = n
          else
          end
          if is_selected then
            ImGui.SetItemDefaultFocus(ctx)
          else
          end
        end
        ImGui.EndListBox(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Selectables") then
      if not widgets.selectables then
        widgets.selectables = {align = {{true, false, true}, {false, true, false}, {true, false, true}}, basic = {false, false, false, false, false}, columns = {false, false, false, false, false, false, false, false, false, false}, grid = {{true, false, false, false}, {false, true, false, false}, {false, false, true, false}, {false, false, false, true}}, multiple = {false, false, false, false, false}, sameline = {false, false, false}, single = ( - 1)}
      else
      end
      if ImGui.TreeNode(ctx, "Basic") then
        local b1 = nil
        local b2 = nil
        local b4 = nil
        rv, b1 = ImGui.Selectable(ctx, "1. I am selectable", widgets.selectables.basic[1])
        do end (widgets.selectables.basic)[1] = b1
        rv, b2 = ImGui.Selectable(ctx, "2. I am selectable", widgets.selectables.basic[2])
        do end (widgets.selectables.basic)[2] = b2
        ImGui.Text(ctx, "(I am not selectable)")
        rv, b4 = ImGui.Selectable(ctx, "4. I am selectable", widgets.selectables.basic[4])
        do end (widgets.selectables.basic)[4] = b4
        if ImGui.Selectable(ctx, "5. I am double clickable", widgets.selectables.basic[5], ImGui.SelectableFlags_AllowDoubleClick()) then
          if ImGui.IsMouseDoubleClicked(ctx, 0) then
            widgets.selectables.basic[5] = not widgets.selectables.basic[5]
          else
          end
        else
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Selection State: Single Selection") then
        for i = 0, 4 do
          if ImGui.Selectable(ctx, ("Object %d"):format(i), (widgets.selectables.single == i)) then
            widgets.selectables.single = i
          else
          end
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Selection State: Multiple Selection") then
        demo.HelpMarker("Hold CTRL and click to select multiple items.")
        for i, sel in ipairs(widgets.selectables.multiple) do
          if ImGui.Selectable(ctx, ("Object %d"):format((i - 1)), sel) then
            if not ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl()) then
              for j = 1, #widgets.selectables.multiple do
                widgets.selectables.multiple[j] = false
              end
            else
            end
            widgets.selectables.multiple[i] = not sel
          else
          end
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Rendering more text into the same line") then
        local s1 = nil
        local s2 = nil
        local s3 = nil
        rv, s1 = ImGui.Selectable(ctx, "main.c", widgets.selectables.sameline[1])
        do end (widgets.selectables.sameline)[1] = s1
        ImGui.SameLine(ctx, 300)
        ImGui.Text(ctx, " 2,345 bytes")
        rv, s2 = ImGui.Selectable(ctx, "Hello.cpp", widgets.selectables.sameline[2])
        do end (widgets.selectables.sameline)[2] = s2
        ImGui.SameLine(ctx, 300)
        ImGui.Text(ctx, "12,345 bytes")
        rv, s3 = ImGui.Selectable(ctx, "Hello.h", widgets.selectables.sameline[3])
        do end (widgets.selectables.sameline)[3] = s3
        ImGui.SameLine(ctx, 300)
        ImGui.Text(ctx, " 2,345 bytes")
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "In columns") then
        if ImGui.BeginTable(ctx, "split1", 3, (ImGui.TableFlags_Resizable() | ImGui.TableFlags_NoSavedSettings() | ImGui.TableFlags_Borders())) then
          for i, sel in ipairs(widgets.selectables.columns) do
            ImGui.TableNextColumn(ctx)
            local ci = nil
            rv, ci = ImGui.Selectable(ctx, ("Item %d"):format((i - 1)), sel)
            do end (widgets.selectables.columns)[i] = ci
          end
          ImGui.EndTable(ctx)
        else
        end
        ImGui.Spacing(ctx)
        if ImGui.BeginTable(ctx, "split2", 3, (ImGui.TableFlags_Resizable() | ImGui.TableFlags_NoSavedSettings() | ImGui.TableFlags_Borders())) then
          for i, sel in ipairs(widgets.selectables.columns) do
            ImGui.TableNextRow(ctx)
            ImGui.TableNextColumn(ctx)
            local ci = nil
            rv, ci = ImGui.Selectable(ctx, ("Item %d"):format((i - 1)), sel, ImGui.SelectableFlags_SpanAllColumns())
            do end (widgets.selectables.columns)[i] = ci
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "Some other contents")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "123456")
          end
          ImGui.EndTable(ctx)
        else
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Grid") then
        local winning_state = true
        for _, row in ipairs(widgets.selectables.grid) do
          if not winning_state then break end
          for _0, sel in ipairs(row) do
            if not winning_state then break end
            if not sel then
              winning_state = false
            else
            end
          end
        end
        if winning_state then
          local time = ImGui.GetTime(ctx)
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign(), (0.5 + (0.5 * math.cos((time * 2)))), (0.5 + (0.5 * math.sin((time * 3)))))
        else
        end
        for ri, row in ipairs(widgets.selectables.grid) do
          for ci, col in ipairs(row) do
            if (ci > 1) then
              ImGui.SameLine(ctx)
            else
            end
            ImGui.PushID(ctx, ((ri * #widgets.selectables.grid) + ci))
            if ImGui.Selectable(ctx, "Sailor", col, 0, 50, 50) then
              row[ci] = not row[ci]
              if (ci > 1) then
                row[(ci - 1)] = not row[(ci - 1)]
              else
              end
              if (ci < 4) then
                row[(ci + 1)] = not row[(ci + 1)]
              else
              end
              if (ri > 1) then
                widgets.selectables.grid[(ri - 1)][ci] = not widgets.selectables.grid[(ri - 1)][ci]
              else
              end
              if (ri < 4) then
                widgets.selectables.grid[(ri + 1)][ci] = not widgets.selectables.grid[(ri + 1)][ci]
              else
              end
            else
            end
            ImGui.PopID(ctx)
          end
        end
        if winning_state then
          ImGui.PopStyleVar(ctx)
        else
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Alignment") then
        demo.HelpMarker("By default, Selectables uses style.SelectableTextAlign but it can be overridden on a per-item basis using PushStyleVar(). You'll probably want to always keep your default situation to left-align otherwise it becomes difficult to layout multiple items on a same line")
        for y = 1, 3 do
          for x = 1, 3 do
            local align_x, align_y = ((x - 1) / 2), ((y - 1) / 2)
            local name = ("(%.1f,%.1f)"):format(align_x, align_y)
            if (x > 1) then
              ImGui.SameLine(ctx)
            else
            end
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_SelectableTextAlign(), align_x, align_y)
            local row = widgets.selectables.align[y]
            do
              local _, rx = ImGui.Selectable(ctx, name, row[x], ImGui.SelectableFlags_None(), 80, 80)
              do end (row)[x] = rx
            end
            ImGui.PopStyleVar(ctx)
          end
        end
        ImGui.TreePop(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Text Input") then
      if not widgets.input then
        widgets.input = {buf = {"", "", "", "", ""}, flags = ImGui.InputTextFlags_AllowTabInput(), multiline = {text = "/*\n     The Pentium F00F bug, shorthand for F0 0F C7 C8,\n     the hexadecimal encoding of one offending instruction,\n     more formally, the invalid operand with locked CMPXCHG8B\n     instruction bug, is a design flaw in the majority of\n     Intel Pentium, Pentium MMX, and Pentium OverDrive\n     processors (all in the P5 microarchitecture).\n    */\n\n    label:\n    \9lock cmpxchg8b eax\n    "}, password = "hunter2"}
      else
      end
      if ImGui.TreeNode(ctx, "Multi-line Text Input") then
        do
          local rv_265_, arg1_264_ = nil, nil
          do
            local arg1_264_0 = widgets.input.multiline.flags
            local _24 = arg1_264_0
            rv_265_, arg1_264_ = ImGui.CheckboxFlags(ctx, "ImGuiInputTextFlags_ReadOnly", _24, ImGui.InputTextFlags_ReadOnly())
          end
          widgets.input.multiline.flags = arg1_264_
        end
        do
          local rv_267_, arg1_266_ = nil, nil
          do
            local arg1_266_0 = widgets.input.multiline.flags
            local _24 = arg1_266_0
            rv_267_, arg1_266_ = ImGui.CheckboxFlags(ctx, "ImGuiInputTextFlags_AllowTabInput", _24, ImGui.InputTextFlags_AllowTabInput())
          end
          widgets.input.multiline.flags = arg1_266_
        end
        do
          local rv_269_, arg1_268_ = nil, nil
          do
            local arg1_268_0 = widgets.input.multiline.flags
            local _24 = arg1_268_0
            rv_269_, arg1_268_ = ImGui.CheckboxFlags(ctx, "ImGuiInputTextFlags_CtrlEnterForNewLine", _24, ImGui.InputTextFlags_CtrlEnterForNewLine())
          end
          widgets.input.multiline.flags = arg1_268_
        end
        do
          local rv_271_, arg1_270_ = nil, nil
          do
            local arg1_270_0 = widgets.input.multiline.text
            local _24 = arg1_270_0
            rv_271_, arg1_270_ = ImGui.InputTextMultiline(ctx, "##source", _24, ( - FLT_MIN), (ImGui.GetTextLineHeight(ctx) * 16), widgets.input.multiline.flags)
          end
          widgets.input.multiline.text = arg1_270_
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Filtered Text Input") then
        do
          local v1_22_auto = nil
          local v2_23_auto = nil
          do
            local _24 = widgets.input.buf[i]
            v1_22_auto, v2_23_auto = ImGui.InputText(ctx, "default", _24)
          end
          widgets.input.buf[1] = v2_23_auto
        end
        do
          local v1_22_auto = nil
          local v2_23_auto = nil
          do
            local _24 = widgets.input.buf[i]
            v1_22_auto, v2_23_auto = ImGui.InputText(ctx, "decimal", _24, ImGui.InputTextFlags_CharsDecimal())
          end
          widgets.input.buf[2] = v2_23_auto
        end
        do
          local v1_22_auto = nil
          local v2_23_auto = nil
          do
            local _24 = widgets.input.buf[i]
            v1_22_auto, v2_23_auto = ImGui.InputText(ctx, "hexadecimal", _24, (ImGui.InputTextFlags_CharsHexadecimal() | ImGui.InputTextFlags_CharsUppercase()))
          end
          widgets.input.buf[3] = v2_23_auto
        end
        do
          local v1_22_auto = nil
          local v2_23_auto = nil
          do
            local _24 = widgets.input.buf[i]
            v1_22_auto, v2_23_auto = ImGui.InputText(ctx, "uppercase", _24, ImGui.InputTextFlags_CharsUppercase())
          end
          widgets.input.buf[4] = v2_23_auto
        end
        do
          local v1_22_auto = nil
          local v2_23_auto = nil
          do
            local _24 = widgets.input.buf[i]
            v1_22_auto, v2_23_auto = ImGui.InputText(ctx, "no blank", _24, ImGui.InputTextFlags_CharsNoBlank())
          end
          widgets.input.buf[5] = v2_23_auto
        end
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Password Input") then
        do
          local rv_275_, arg1_274_ = nil, nil
          do
            local arg1_274_0 = widgets.input.password
            local _24 = arg1_274_0
            rv_275_, arg1_274_ = ImGui.InputText(ctx, "password", _24, ImGui.InputTextFlags_Password())
          end
          widgets.input.password = arg1_274_
        end
        ImGui.SameLine(ctx)
        demo.HelpMarker("Display all characters as '*'.\n    Disable clipboard cut and copy.\n    Disable logging.\n    ")
        do
          local rv_277_, arg1_276_ = nil, nil
          do
            local arg1_276_0 = widgets.input.password
            local _24 = arg1_276_0
            rv_277_, arg1_276_ = ImGui.InputTextWithHint(ctx, "password (w/ hint)", "<password>", _24, ImGui.InputTextFlags_Password())
          end
          widgets.input.password = arg1_276_
        end
        do
          local rv_279_, arg1_278_ = nil, nil
          do
            local arg1_278_0 = widgets.input.password
            local _24 = arg1_278_0
            rv_279_, arg1_278_ = ImGui.InputText(ctx, "password (clear)", _24)
          end
          widgets.input.password = arg1_278_
        end
        ImGui.TreePop(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Tabs") then
      if not widgets.tabs then
        widgets.tabs = {active = {1, 2, 3}, flags1 = ImGui.TabBarFlags_Reorderable(), flags2 = (ImGui.TabBarFlags_AutoSelectNewTabs() | ImGui.TabBarFlags_Reorderable() | ImGui.TabBarFlags_FittingPolicyResizeDown()), next_id = 4, opened = {true, true, true, true}, show_leading_button = true, show_trailing_button = true}
      else
      end
      local fitting_policy_mask = (ImGui.TabBarFlags_FittingPolicyResizeDown() | ImGui.TabBarFlags_FittingPolicyScroll())
      if ImGui.TreeNode(ctx, "Basic") then
        if ImGui.BeginTabBar(ctx, "MyTabBar", ImGui.TabBarFlags_None()) then
          if ImGui.BeginTabItem(ctx, "Avocado") then
            ImGui.Text(ctx, "This is the Avocado tab!\nblah blah blah blah blah")
            ImGui.EndTabItem(ctx)
          else
          end
          if ImGui.BeginTabItem(ctx, "Broccoli") then
            ImGui.Text(ctx, "This is the Broccoli tab!\nblah blah blah blah blah")
            ImGui.EndTabItem(ctx)
          else
          end
          if ImGui.BeginTabItem(ctx, "Cucumber") then
            ImGui.Text(ctx, "This is the Cucumber tab!\nblah blah blah blah blah")
            ImGui.EndTabItem(ctx)
          else
          end
          ImGui.EndTabBar(ctx)
        else
        end
        ImGui.Separator(ctx)
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "Advanced & Close Button") then
        do
          local rv_289_, arg1_288_ = nil, nil
          do
            local arg1_288_0 = widgets.tabs.flags1
            local _24 = arg1_288_0
            rv_289_, arg1_288_ = ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_Reorderable", _24, ImGui.TabBarFlags_Reorderable())
          end
          widgets.tabs.flags1 = arg1_288_
        end
        do
          local rv_291_, arg1_290_ = nil, nil
          do
            local arg1_290_0 = widgets.tabs.flags1
            local _24 = arg1_290_0
            rv_291_, arg1_290_ = ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_AutoSelectNewTabs", _24, ImGui.TabBarFlags_AutoSelectNewTabs())
          end
          widgets.tabs.flags1 = arg1_290_
        end
        do
          local rv_293_, arg1_292_ = nil, nil
          do
            local arg1_292_0 = widgets.tabs.flags1
            local _24 = arg1_292_0
            rv_293_, arg1_292_ = ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_TabListPopupButton", _24, ImGui.TabBarFlags_TabListPopupButton())
          end
          widgets.tabs.flags1 = arg1_292_
        end
        do
          local rv_295_, arg1_294_ = nil, nil
          do
            local arg1_294_0 = widgets.tabs.flags1
            local _24 = arg1_294_0
            rv_295_, arg1_294_ = ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_NoCloseWithMiddleMouseButton", _24, ImGui.TabBarFlags_NoCloseWithMiddleMouseButton())
          end
          widgets.tabs.flags1 = arg1_294_
        end
        if (0 == (widgets.tabs.flags1 & fitting_policy_mask)) then
          widgets.tabs.flags1 = (widgets.tabs.flags1 | ImGui.TabBarFlags_FittingPolicyResizeDown())
        else
        end
        if ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_FittingPolicyResizeDown", widgets.tabs.flags1, ImGui.TabBarFlags_FittingPolicyResizeDown()) then
          widgets.tabs.flags1 = ((widgets.tabs.flags1 & ~fitting_policy_mask) | ImGui.TabBarFlags_FittingPolicyResizeDown())
        else
        end
        if ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_FittingPolicyScroll", widgets.tabs.flags1, ImGui.TabBarFlags_FittingPolicyScroll()) then
          widgets.tabs.flags1 = ((widgets.tabs.flags1 & ~fitting_policy_mask) | ImGui.TabBarFlags_FittingPolicyScroll())
        else
        end
        local names = {"Artichoke", "Beetroot", "Celery", "Daikon"}
        for n, opened in ipairs(widgets.tabs.opened) do
          if (n > 1) then
            ImGui.SameLine(ctx)
          else
          end
          local _, on = ImGui.Checkbox(ctx, names[n], opened)
          do end (widgets.tabs.opened)[n] = on
        end
        if ImGui.BeginTabBar(ctx, "MyTabBar", widgets.tabs.flags1) then
          for n, opened in ipairs(widgets.tabs.opened) do
            if opened then
              do
                local _, on = ImGui.BeginTabItem(ctx, names[n], true, ImGui.TabItemFlags_None())
                do end (widgets.tabs.opened)[n] = on
              end
              if rv then
                ImGui.Text(ctx, ("This is the %s tab!"):format(names[n]))
                if (0 == (n & 1)) then
                  ImGui.Text(ctx, "I am an odd tab.")
                else
                end
                ImGui.EndTabItem(ctx)
              else
              end
            else
            end
          end
          ImGui.EndTabBar(ctx)
        else
        end
        ImGui.Separator(ctx)
        ImGui.TreePop(ctx)
      else
      end
      if ImGui.TreeNode(ctx, "TabItemButton & Leading/Trailing flags") then
        do
          local rv_306_, arg1_305_ = nil, nil
          do
            local arg1_305_0 = widgets.tabs.show_leading_button
            local _24 = arg1_305_0
            rv_306_, arg1_305_ = ImGui.Checkbox(ctx, "Show Leading TabItemButton()", _24)
          end
          widgets.tabs.show_leading_button = arg1_305_
        end
        do
          local rv_308_, arg1_307_ = nil, nil
          do
            local arg1_307_0 = widgets.tabs.show_trailing_button
            local _24 = arg1_307_0
            rv_308_, arg1_307_ = ImGui.Checkbox(ctx, "Show Trailing TabItemButton()", _24)
          end
          widgets.tabs.show_trailing_button = arg1_307_
        end
        do
          local rv_310_, arg1_309_ = nil, nil
          do
            local arg1_309_0 = widgets.tabs.flags2
            local _24 = arg1_309_0
            rv_310_, arg1_309_ = ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_TabListPopupButton", _24, ImGui.TabBarFlags_TabListPopupButton())
          end
          widgets.tabs.flags2 = arg1_309_
        end
        if ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_FittingPolicyResizeDown", widgets.tabs.flags2, ImGui.TabBarFlags_FittingPolicyResizeDown()) then
          widgets.tabs.flags2 = ((widgets.tabs.flags2 & ~fitting_policy_mask) | ImGui.TabBarFlags_FittingPolicyResizeDown())
        else
        end
        if ImGui.CheckboxFlags(ctx, "ImGuiTabBarFlags_FittingPolicyScroll", widgets.tabs.flags2, ImGui.TabBarFlags_FittingPolicyScroll()) then
          widgets.tabs.flags2 = ((widgets.tabs.flags2 & ~fitting_policy_mask) | ImGui.TabBarFlags_FittingPolicyScroll())
        else
        end
        if ImGui.BeginTabBar(ctx, "MyTabBar", widgets.tabs.flags2) then
          if widgets.tabs.show_leading_button then
            if ImGui.TabItemButton(ctx, "?", (ImGui.TabItemFlags_Leading() | ImGui.TabItemFlags_NoTooltip())) then
              ImGui.OpenPopup(ctx, "MyHelpMenu")
            else
            end
          else
          end
          if ImGui.BeginPopup(ctx, "MyHelpMenu") then
            ImGui.Selectable(ctx, "Hello!")
            ImGui.EndPopup(ctx)
          else
          end
          if widgets.tabs.show_trailing_button then
            if ImGui.TabItemButton(ctx, "+", (ImGui.TabItemFlags_Trailing() | ImGui.TabItemFlags_NoTooltip())) then
              table.insert(widgets.tabs.active, widgets.tabs.next_id)
              widgets.tabs.next_id = (1 + widgets.tabs.next_id)
            else
            end
          else
          end
          local n = 1
          while (n <= #widgets.tabs.active) do
            local name = ("%04d"):format((widgets.tabs.active[n] - 1))
            local rv0, open = ImGui.BeginTabItem(ctx, name, true, ImGui.TabItemFlags_None())
            if rv0 then
              ImGui.Text(ctx, ("This is the %s tab!"):format(name))
              ImGui.EndTabItem(ctx)
            else
            end
            if open then
              n = (n + 1)
            else
              table.remove(widgets.tabs.active, n)
            end
          end
          ImGui.EndTabBar(ctx)
        else
        end
        ImGui.Separator(ctx)
        ImGui.TreePop(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Plotting") then
      local PLOT1_SIZE = 90
      local plot2_funcs
      local function _323_(_241)
        return math.sin((_241 * 0.1))
      end
      local function _324_(_241)
        if ((_241 & 1) == 1) then
          return 1.0
        else
          return -1.0
        end
      end
      plot2_funcs = {_323_, _324_}
      if not widgets.plots then
        widgets.plots = {animate = true, frame_times = reaper.new_array({0.6, 0.1, 1, 0.5, 0.92, 0.1, 0.2}), plot1 = {data = reaper.new_array(PLOT1_SIZE), offset = 1, phase = 0, refresh_time = 0}, plot2 = {data = reaper.new_array(1), fill = true, func = 0, size = 70}, progress = 0, progress_dir = 1}
      else
      end
      do
        local rv_328_, arg1_327_ = nil, nil
        do
          local arg1_327_0 = widgets.plots.animate
          local _24 = arg1_327_0
          rv_328_, arg1_327_ = ImGui.Checkbox(ctx, "Animate", _24)
        end
        widgets.plots.animate = arg1_327_
      end
      ImGui.PlotLines(ctx, "Frame Times", widgets.plots.frame_times)
      ImGui.PlotHistogram(ctx, "Histogram", widgets.plots.frame_times, 0, nil, 0, 1, 0, 80)
      if (not widgets.plots.animate or (0 == widgets.plots.plot1.refresh_time)) then
        widgets.plots.plot1.refresh_time = ImGui.GetTime(ctx)
      else
      end
      while (widgets.plots.plot1.refresh_time < ImGui.GetTime(ctx)) do
        widgets.plots.plot1.data[widgets.plots.plot1.offset] = math.cos(widgets.plots.plot1.phase)
        widgets.plots.plot1.offset = (1 + (widgets.plots.plot1.offset % PLOT1_SIZE))
        widgets.plots.plot1.phase = (widgets.plots.plot1.phase + (0.1 * widgets.plots.plot1.offset))
        widgets.plots.plot1.refresh_time = (widgets.plots.plot1.refresh_time + (1.0 / 60.0))
      end
      do
        local average = 0.0
        for n = 1, PLOT1_SIZE do
          average = (average + (widgets.plots.plot1.data)[n])
        end
        average = (average / PLOT1_SIZE)
        local overlay = ("avg %f"):format(average)
        ImGui.PlotLines(ctx, "Lines", widgets.plots.plot1.data, (widgets.plots.plot1.offset - 1), overlay, -1.0, 1.0, 0, 80.0)
      end
      ImGui.SeparatorText(ctx, "Functions")
      ImGui.SetNextItemWidth(ctx, (ImGui.GetFontSize(ctx) * 8))
      do
        local func_changed
        do
          local rv_331_, arg1_330_ = nil, nil
          do
            local arg1_330_0 = widgets.plots.plot2.func
            local _24 = arg1_330_0
            rv_331_, arg1_330_ = ImGui.Combo(ctx, "func", _24, "Sin\0Saw\0")
          end
          widgets.plots.plot2.func = arg1_330_
          func_changed = rv_331_, arg1_330_
        end
        local _ = ImGui.SameLine(ctx)
        local rv0
        do
          local rv_333_, arg1_332_ = nil, nil
          do
            local arg1_332_0 = widgets.plots.plot2.size
            local _24 = arg1_332_0
            rv_333_, arg1_332_ = ImGui.SliderInt(ctx, "Sample count", _24, 1, 400)
          end
          widgets.plots.plot2.size = arg1_332_
          rv0 = rv_333_, arg1_332_
        end
        if (func_changed or rv0 or widgets.plots.plot2.fill) then
          widgets.plots.plot2.fill = false
          widgets.plots.plot2.data = reaper.new_array(widgets.plots.plot2.size)
          for n = 1, widgets.plots.plot2.size do
            widgets.plots.plot2.data[n] = (plot2_funcs)[(1 + widgets.plots.plot2.func)]((n - 1))
          end
        else
        end
      end
      ImGui.PlotLines(ctx, "Lines", widgets.plots.plot2.data, 0, nil, -1.0, 1.0, 0, 80)
      ImGui.PlotHistogram(ctx, "Histogram", widgets.plots.plot2.data, 0, nil, -1.0, 1.0, 0, 80)
      ImGui.Separator(ctx)
      if widgets.plots.animate then
        widgets.plots.progress = (widgets.plots.progress + (widgets.plots.progress_dir * 0.4 * ImGui.GetDeltaTime(ctx)))
        if (widgets.plots.progress >= 1.1) then
          widgets.plots.progress = 1.1
          widgets.plots.progress_dir = (-1 * widgets.plots.progress_dir)
        elseif (widgets.plots.progress <= -0.1) then
          widgets.plots.progress = -0.1
          widgets.plots.progress_dir = (-1 * widgets.plots.progress_dir)
        else
        end
      else
      end
      ImGui.ProgressBar(ctx, widgets.plots.progress, 0, 0)
      ImGui.SameLine(ctx, 0, ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing()))
      ImGui.Text(ctx, "Progress Bar")
      do
        local progress_saturated = demo.clamp(widgets.plots.progress, 0, 1)
        local buf = ("%d/%d"):format(math.floor((progress_saturated * 1753)), 1753)
        ImGui.ProgressBar(ctx, widgets.plots.progress, 0, 0, buf)
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Color/Picker Widgets") then
      if not widgets.colors then
        widgets.colors = {alpha = true, alpha_bar = true, alpha_preview = true, backup_color = nil, display_mode = 0, drag_and_drop = true, hsva = 1006632959, options_menu = true, picker_mode = 0, raw_hsv = reaper.new_array(4), ref_color_rgba = 4278255488, rgba = 1922079432, saved_palette = nil, side_preview = true, no_border = false, alpha_half_preview = false, ref_color = false}
      else
      end
      ImGui.SeparatorText(ctx, "Options")
      do
        local rv_340_, arg1_339_ = nil, nil
        do
          local arg1_339_0 = widgets.colors.alpha_preview
          local _24 = arg1_339_0
          rv_340_, arg1_339_ = ImGui.Checkbox(ctx, "With Alpha Preview", _24)
        end
        widgets.colors.alpha_preview = arg1_339_
      end
      do
        local rv_342_, arg1_341_ = nil, nil
        do
          local arg1_341_0 = widgets.colors.alpha_half_preview
          local _24 = arg1_341_0
          rv_342_, arg1_341_ = ImGui.Checkbox(ctx, "With Half Alpha Preview", _24)
        end
        widgets.colors.alpha_half_preview = arg1_341_
      end
      do
        local rv_344_, arg1_343_ = nil, nil
        do
          local arg1_343_0 = widgets.colors.drag_and_drop
          local _24 = arg1_343_0
          rv_344_, arg1_343_ = ImGui.Checkbox(ctx, "With Drag and Drop", _24)
        end
        widgets.colors.drag_and_drop = arg1_343_
      end
      do
        local rv_346_, arg1_345_ = nil, nil
        do
          local arg1_345_0 = widgets.colors.options_menu
          local _24 = arg1_345_0
          rv_346_, arg1_345_ = ImGui.Checkbox(ctx, "With Options Menu", _24)
        end
        widgets.colors.options_menu = arg1_345_
      end
      ImGui.SameLine(ctx)
      demo.HelpMarker("Right-click on the individual color widget to show options.")
      local misc_flags
      local _347_
      if widgets.colors.drag_and_drop then
        _347_ = 0
      else
        _347_ = ImGui.ColorEditFlags_NoDragDrop()
      end
      local _349_
      if widgets.colors.alpha_half_preview then
        _349_ = ImGui.ColorEditFlags_AlphaPreviewHalf()
      elseif widgets.colors.alpha_preview then
        _349_ = ImGui.ColorEditFlags_AlphaPreview()
      else
        _349_ = 0
      end
      local function _351_()
        if widgets.colors.options_menu then
          return 0
        else
          return ImGui.ColorEditFlags_NoOptions()
        end
      end
      misc_flags = (_347_ | _349_ | _351_())
      ImGui.SeparatorText(ctx, "Inline color editor")
      ImGui.Text(ctx, "Color widget:")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Click on the color square to open a color picker.\n\n           CTRL+click on individual component to input value.\n")
    else
    end
    local argb = demo.RgbaToArgb(widgets.colors.rgba)
    local _355_
    do
      local rv_354_, arg1_353_ = nil, nil
      do
        local arg1_353_0 = argb
        local _24 = arg1_353_0
        rv_354_, arg1_353_ = ImGui.ColorEdit3(ctx, "MyColor##1", _24, __fnl_global__misc_2dflags)
      end
      argb = arg1_353_
      _355_ = rv_354_
    end
    if _355_ then
      widgets.colors.rgba = demo.ArgbToRgba(argb)
    else
    end
    ImGui.Text(ctx, "Color widget HSV with Alpha:")
    do
      local rv_358_, arg1_357_ = nil, nil
      do
        local arg1_357_0 = widgets.colors.rgba
        local _24 = arg1_357_0
        rv_358_, arg1_357_ = ImGui.ColorEdit4(ctx, "MyColor##2", _24, (ImGui.ColorEditFlags_DisplayHSV() | __fnl_global__misc_2dflags))
      end
      widgets.colors.rgba = arg1_357_
    end
    ImGui.Text(ctx, "Color widget with Float Display:")
    do
      local rv_360_, arg1_359_ = nil, nil
      do
        local arg1_359_0 = widgets.colors.rgba
        local _24 = arg1_359_0
        rv_360_, arg1_359_ = ImGui.ColorEdit4(ctx, "MyColor##2f", _24, (ImGui.ColorEditFlags_Float() | __fnl_global__misc_2dflags))
      end
      widgets.colors.rgba = arg1_359_
    end
    ImGui.Text(ctx, "Color button with Picker:")
    ImGui.SameLine(ctx)
    demo.HelpMarker("With the ImGuiColorEditFlags_NoInputs flag you can hide all the slider/text inputs.\n    With the ImGuiColorEditFlags_NoLabel flag you can pass a non-empty label which will only be used for the tooltip and picker popup.")
    do
      local rv_362_, arg1_361_ = nil, nil
      do
        local arg1_361_0 = widgets.colors.rgba
        local _24 = arg1_361_0
        rv_362_, arg1_361_ = ImGui.ColorEdit4(ctx, "MyColor##3", _24, (ImGui.ColorEditFlags_NoInputs() | ImGui.ColorEditFlags_NoLabel() | __fnl_global__misc_2dflags))
      end
      widgets.colors.rgba = arg1_361_
    end
    ImGui.Text(ctx, "Color button with Custom Picker Popup:")
    if not widgets.colors.saved_palette then
      widgets.colors.saved_palette = {}
      for n = 0, 31 do
        table.insert(widgets.colors.saved_palette, demo.HSV((n / 31.0), 0.8, 0.8))
      end
    else
    end
    local open_popup = ImGui.ColorButton(ctx, "MyColor##3b", widgets.colors.rgba, __fnl_global__misc_2dflags)
    ImGui.SameLine(ctx, 0, ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing()))
    open_popup = (ImGui.Button(ctx, "Palette") or open_popup)
    if open_popup then
      ImGui.OpenPopup(ctx, "mypicker")
      widgets.colors.backup_color = widgets.colors.rgba
    else
    end
    if ImGui.BeginPopup(ctx, "mypicker") then
      ImGui.Text(ctx, "MY CUSTOM COLOR PICKER WITH AN AMAZING PALETTE!")
      ImGui.Separator(ctx)
      rv, widgets.colors.rgba = ImGui.ColorPicker4(ctx, "##picker", widgets.colors.rgba, (__fnl_global__misc_2dflags | ImGui.ColorEditFlags_NoSidePreview() | ImGui.ColorEditFlags_NoSmallPreview()))
      ImGui.SameLine(ctx)
      ImGui.BeginGroup(ctx)
      ImGui.Text(ctx, "Current")
      ImGui.ColorButton(ctx, "##current", widgets.colors.rgba, (ImGui.ColorEditFlags_NoPicker() | ImGui.ColorEditFlags_AlphaPreviewHalf()), 60, 40)
      ImGui.Text(ctx, "Previous")
      if ImGui.ColorButton(ctx, "##previous", widgets.colors.backup_color, (ImGui.ColorEditFlags_NoPicker() | ImGui.ColorEditFlags_AlphaPreviewHalf()), 60, 40) then
        widgets.colors.rgba = widgets.colors.backup_color
      else
      end
      ImGui.Separator(ctx)
      ImGui.Text(ctx, "Palette")
      local palette_button_flags = (ImGui.ColorEditFlags_NoAlpha() | ImGui.ColorEditFlags_NoPicker() | ImGui.ColorEditFlags_NoTooltip())
      for n, c in ipairs(widgets.colors.saved_palette) do
        ImGui.PushID(ctx, n)
        if (0 ~= ((n - 1) % 8)) then
          ImGui.SameLine(ctx, 0, select(2, ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing())))
        else
        end
        if ImGui.ColorButton(ctx, "##palette", c, palette_button_flags, 20, 20) then
          widgets.colors.rgba = ((c << 8) | (widgets.colors.rgba & 255))
        else
        end
        if ImGui.BeginDragDropTarget(ctx) then
          local rv0, drop_color = ImGui.AcceptDragDropPayloadRGB(ctx)
          local _
          if rv0 then
            widgets.colors.saved_palette[n] = drop_color
            _ = nil
          else
            _ = nil
          end
          local rv1, drop_color0 = ImGui.AcceptDragDropPayloadRGBA(ctx)
          local _0
          if rv1 then
            widgets.colors.saved_palette[n] = (drop_color0 >> 8)
            _0 = nil
          else
            _0 = nil
          end
          ImGui.EndDragDropTarget(ctx)
        else
        end
        ImGui.PopID(ctx)
      end
      ImGui.EndGroup(ctx)
      ImGui.EndPopup(ctx)
    else
    end
    ImGui.Text(ctx, "Color button only:")
    do
      local rv_373_, arg1_372_ = nil, nil
      do
        local arg1_372_0 = widgets.colors.no_border
        local _24 = arg1_372_0
        rv_373_, arg1_372_ = ImGui.Checkbox(ctx, "ImGuiColorEditFlags_NoBorder", _24)
      end
      widgets.colors.no_border = arg1_372_
    end
    local function _374_()
      if widgets.colors.no_border then
        return ImGui.ColorEditFlags_NoBorder()
      else
        return 0
      end
    end
    ImGui.ColorButton(ctx, "MyColor##3c", widgets.colors.rgba, (__fnl_global__misc_2dflags | _374_()), 80, 80)
    ImGui.SeparatorText(ctx, "Color picker")
    do
      local rv_376_, arg1_375_ = nil, nil
      do
        local arg1_375_0 = widgets.colors.alpha
        local _24 = arg1_375_0
        rv_376_, arg1_375_ = ImGui.Checkbox(ctx, "With Alpha", _24)
      end
      widgets.colors.alpha = arg1_375_
    end
    do
      local rv_378_, arg1_377_ = nil, nil
      do
        local arg1_377_0 = widgets.colors.alpha_bar
        local _24 = arg1_377_0
        rv_378_, arg1_377_ = ImGui.Checkbox(ctx, "With Alpha Bar", _24)
      end
      widgets.colors.alpha_bar = arg1_377_
    end
    do
      local rv_380_, arg1_379_ = nil, nil
      do
        local arg1_379_0 = widgets.colors.side_preview
        local _24 = arg1_379_0
        rv_380_, arg1_379_ = ImGui.Checkbox(ctx, "With Side Preview", _24)
      end
      widgets.colors.side_preview = arg1_379_
    end
    if widgets.colors.side_preview then
      ImGui.SameLine(ctx)
      do
        local rv_382_, arg1_381_ = nil, nil
        do
          local arg1_381_0 = widgets.colors.ref_color
          local _24 = arg1_381_0
          rv_382_, arg1_381_ = ImGui.Checkbox(ctx, "With Ref Color", _24)
        end
        widgets.colors.ref_color = arg1_381_
      end
      if widgets.colors.ref_color then
        ImGui.SameLine(ctx)
        local rv_384_, arg1_383_ = nil, nil
        do
          local arg1_383_0 = widgets.colors.ref_color_rgba
          local _24 = arg1_383_0
          rv_384_, arg1_383_ = ImGui.ColorEdit4(ctx, "##RefColor", _24, (ImGui.ColorEditFlags_NoInputs() | __fnl_global__misc_2dflags))
        end
        widgets.colors.ref_color_rgba = arg1_383_
      else
      end
    else
    end
    do
      local rv_388_, arg1_387_ = nil, nil
      do
        local arg1_387_0 = widgets.colors.display_mode
        local _24 = arg1_387_0
        rv_388_, arg1_387_ = ImGui.Combo(ctx, "Display Mode", _24, "Auto/Current\0None\0RGB Only\0HSV Only\0Hex Only\0")
      end
      widgets.colors.display_mode = arg1_387_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("ColorEdit defaults to displaying RGB inputs if you don't specify a display mode, \n           but the user can change it with a right-click on those inputs.\n\nColorPicker defaults to displaying RGB+HSV+Hex \n           if you don't specify a display mode.\n\nYou can change the defaults using SetColorEditOptions().")
    do
      local rv_390_, arg1_389_ = nil, nil
      do
        local arg1_389_0 = widgets.colors.picker_mode
        local _24 = arg1_389_0
        rv_390_, arg1_389_ = ImGui.Combo(ctx, "Picker Mode", _24, "Auto/Current\0Hue bar + SV rect\0Hue wheel + SV triangle\0")
      end
      widgets.colors.picker_mode = arg1_389_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("When not specified explicitly (Auto/Current mode), user can right-click the picker to change mode.")
    local flags = __fnl_global__misc_2dflags
    if not widgets.colors.alpha then
      flags = (flags | ImGui.ColorEditFlags_NoAlpha())
    else
    end
    if widgets.colors.alpha_bar then
      flags = (flags | ImGui.ColorEditFlags_AlphaBar())
    else
    end
    if not widgets.colors.side_preview then
      flags = (flags | ImGui.ColorEditFlags_NoSidePreview())
    else
    end
    do
      local _394_ = widgets.colors.picker_mode
      if (_394_ == 1) then
        flags = (flags | ImGui.ColorEditFlags_PickerHueBar())
      elseif (_394_ == 2) then
        flags = (flags | ImGui.ColorEditFlags_PickerHueWheel())
      else
      end
    end
    do
      local _396_ = widgets.colors.display_mode
      if (_396_ == 1) then
        flags = (flags | ImGui.ColorEditFlags_NoInputs())
      elseif (_396_ == 2) then
        flags = (flags | ImGui.ColorEditFlags_DisplayRGB())
      elseif (_396_ == 3) then
        flags = (flags | ImGui.ColorEditFlags_DisplayHSV())
      elseif (_396_ == 4) then
        flags = (flags | ImGui.ColorEditFlags_DisplayHex())
      else
      end
    end
    local color
    if widgets.colors.alpha then
      color = widgets.colors.rgba
    else
      color = demo.RgbaToArgb(widgets.colors.rgba)
    end
    local ref_color = ((widgets.colors.alpha and widgets.colors.ref_color_rgba) or demo.RgbaToArgb(widgets.colors.ref_color_rgba))
    local _401_
    do
      local rv_400_, arg1_399_ = nil, nil
      do
        local arg1_399_0 = color
        local _24 = arg1_399_0
        local function _402_()
          if widgets.colors.ref_color then
            return ref_color
          else
            return nil
          end
        end
        rv_400_, arg1_399_ = ImGui.ColorPicker4(ctx, "MyColor##4", _24, flags, _402_())
      end
      color = arg1_399_
      _401_ = rv_400_
    end
    if _401_ then
      if widgets.colors.alpha then
        widgets.colors.rgba = color
      else
        widgets.colors.rgba = demo.ArgbToRgba(color)
      end
    else
    end
    ImGui.Text(ctx, "Set defaults in code:")
    ImGui.SameLine(ctx)
    demo.HelpMarker("SetColorEditOptions() is designed to allow you to set boot-time default.\n    We don't have Push/Pop functions because you can force options on a per-widget basis if needed,and the user can change non-forced ones with the options menu.\n    We don't have a getter to avoidencouraging you to persistently save values that aren't forward-compatible.")
    if ImGui.Button(ctx, "Default: Uint8 + HSV + Hue Bar") then
      ImGui.SetColorEditOptions(ctx, (ImGui.ColorEditFlags_Uint8() | ImGui.ColorEditFlags_DisplayHSV() | ImGui.ColorEditFlags_PickerHueBar()))
    else
    end
    if ImGui.Button(ctx, "Default: Float + Hue Wheel") then
      ImGui.SetColorEditOptions(ctx, (ImGui.ColorEditFlags_Float() | ImGui.ColorEditFlags_PickerHueWheel()))
    else
    end
    local color0 = demo.RgbaToArgb(widgets.colors.rgba)
    ImGui.Text(ctx, "Both types:")
    local w = ((ImGui.GetContentRegionAvail(ctx) - select(2, ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing()))) * 0.4)
    ImGui.SetNextItemWidth(ctx, w)
    local _409_
    do
      local rv_408_, arg1_407_ = nil, nil
      do
        local arg1_407_0 = color0
        local _24 = arg1_407_0
        rv_408_, arg1_407_ = ImGui.ColorPicker3(ctx, "##MyColor##5", _24, (ImGui.ColorEditFlags_PickerHueBar() | ImGui.ColorEditFlags_NoSidePreview() | ImGui.ColorEditFlags_NoInputs() | ImGui.ColorEditFlags_NoAlpha()))
      end
      color0 = arg1_407_
      _409_ = rv_408_
    end
    if _409_ then
      widgets.colors.rgba = demo.ArgbToRgba(color0)
    else
    end
    ImGui.SameLine(ctx)
    ImGui.SetNextItemWidth(ctx, w)
    local _413_
    do
      local rv_412_, arg1_411_ = nil, nil
      do
        local arg1_411_0 = color0
        local _24 = arg1_411_0
        rv_412_, arg1_411_ = ImGui.ColorPicker3(ctx, "##MyColor##6", _24, (ImGui.ColorEditFlags_PickerHueWheel() | ImGui.ColorEditFlags_NoSidePreview() | ImGui.ColorEditFlags_NoInputs() | ImGui.ColorEditFlags_NoAlpha()))
      end
      color0 = arg1_411_
      _413_ = rv_412_
    end
    if _413_ then
      widgets.colors.rgba = demo.ArgbToRgba(color0)
    else
    end
    ImGui.Spacing(ctx)
    ImGui.Text(ctx, "HSV encoded colors")
    ImGui.SameLine(ctx)
    demo.HelpMarker("By default, colors are given to ColorEdit and ColorPicker in RGB, but ImGuiColorEditFlags_InputHSV allows you to store colors as HSV and pass them to ColorEdit and ColorPicker as HSV. This comes with the added benefit that you can manipulate hue values with the picker even when saturation or value are zero.")
    ImGui.Text(ctx, "Color widget with InputHSV:")
    do
      local rv_416_, arg1_415_ = nil, nil
      do
        local arg1_415_0 = widgets.colors.hsva
        local _24 = arg1_415_0
        rv_416_, arg1_415_ = ImGui.ColorEdit4(ctx, "HSV shown as RGB##1", _24, (ImGui.ColorEditFlags_DisplayRGB() | ImGui.ColorEditFlags_InputHSV() | ImGui.ColorEditFlags_Float()))
      end
      widgets.colors.hsva = arg1_415_
    end
    do
      local rv_418_, arg1_417_ = nil, nil
      do
        local arg1_417_0 = widgets.colors.hsva
        local _24 = arg1_417_0
        rv_418_, arg1_417_ = ImGui.ColorEdit4(ctx, "HSV shown as HSV##1", _24, (ImGui.ColorEditFlags_DisplayHSV() | ImGui.ColorEditFlags_InputHSV() | ImGui.ColorEditFlags_Float()))
      end
      widgets.colors.hsva = arg1_417_
    end
    local raw_hsv = widgets.colors.raw_hsv
    do
      raw_hsv[1] = (((widgets.colors.hsva >> 24) & 255) / 255.0)
      do end (raw_hsv)[2] = (((widgets.colors.hsva >> 16) & 255) / 255.0)
      do end (raw_hsv)[3] = (((widgets.colors.hsva >> 8) & 255) / 255.0)
      do end (raw_hsv)[4] = ((widgets.colors.hsva & 255) / 255.0)
    end
    if ImGui.DragDoubleN(ctx, "Raw HSV values", raw_hsv, 0.01, 0.0, 1.0) then
      widgets.colors.hsva = ((demo.round((raw_hsv[1] * 255)) << 24) | (demo.round((raw_hsv[2] * 255)) << 16) | (demo.round((raw_hsv[3] * 255)) << 8) | demo.round((raw_hsv[4] * 255)))
    else
    end
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Drag/Slider Flags") then
    if not widgets.sliders then
      widgets.sliders = {drag_d = 0.5, drag_i = 50, flags = ImGui.SliderFlags_None(), slider_d = 0.5, slider_i = 50}
    else
    end
    do
      local rv_423_, arg1_422_ = nil, nil
      do
        local arg1_422_0 = widgets.sliders.flags
        local _24 = arg1_422_0
        rv_423_, arg1_422_ = ImGui.CheckboxFlags(ctx, "ImGuiSliderFlags_AlwaysClamp", _24, ImGui.SliderFlags_AlwaysClamp())
      end
      widgets.sliders.flags = arg1_422_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("Always clamp value to min/max bounds (if any) when input manually with CTRL+Click.")
    do
      local rv_425_, arg1_424_ = nil, nil
      do
        local arg1_424_0 = widgets.sliders.flags
        local _24 = arg1_424_0
        rv_425_, arg1_424_ = ImGui.CheckboxFlags(ctx, "ImGuiSliderFlags_Logarithmic", _24, ImGui.SliderFlags_Logarithmic())
      end
      widgets.sliders.flags = arg1_424_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("Enable logarithmic editing (more precision for small values).")
    do
      local rv_427_, arg1_426_ = nil, nil
      do
        local arg1_426_0 = widgets.sliders.flags
        local _24 = arg1_426_0
        rv_427_, arg1_426_ = ImGui.CheckboxFlags(ctx, "ImGuiSliderFlags_NoRoundToFormat", _24, ImGui.SliderFlags_NoRoundToFormat())
      end
      widgets.sliders.flags = arg1_426_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("Disable rounding underlying value to match precision of the format string (e.g. %.3f values are rounded to those 3 digits).")
    do
      local rv_429_, arg1_428_ = nil, nil
      do
        local arg1_428_0 = widgets.sliders.flags
        local _24 = arg1_428_0
        rv_429_, arg1_428_ = ImGui.CheckboxFlags(ctx, "ImGuiSliderFlags_NoInput", _24, ImGui.SliderFlags_NoInput())
      end
      widgets.sliders.flags = arg1_428_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("Disable CTRL+Click or Enter key allowing to input text directly into the widget.")
    do
      local DBL_MIN = 2.22507e-308
      local DBL_MAX = 1.79769e+308
      ImGui.Text(ctx, ("Underlying double value: %f"):format(widgets.sliders.drag_d))
      do
        local rv_431_, arg1_430_ = nil, nil
        do
          local arg1_430_0 = widgets.sliders.drag_d
          local _24 = arg1_430_0
          rv_431_, arg1_430_ = ImGui.DragDouble(ctx, "DragDouble (0 -> 1)", _24, 0.005, 0.0, 1.0, "%.3f", widgets.sliders.flags)
        end
        widgets.sliders.drag_d = arg1_430_
      end
      do
        local rv_433_, arg1_432_ = nil, nil
        do
          local arg1_432_0 = widgets.sliders.drag_d
          local _24 = arg1_432_0
          rv_433_, arg1_432_ = ImGui.DragDouble(ctx, "DragDouble (0 -> +inf)", _24, 0.005, 0.0, DBL_MAX, "%.3f", widgets.sliders.flags)
        end
        widgets.sliders.drag_d = arg1_432_
      end
      do
        local rv_435_, arg1_434_ = nil, nil
        do
          local arg1_434_0 = widgets.sliders.drag_d
          local _24 = arg1_434_0
          rv_435_, arg1_434_ = ImGui.DragDouble(ctx, "DragDouble (-inf -> 1)", _24, 0.005, ( - DBL_MAX), 1, "%.3f", widgets.sliders.flags)
        end
        widgets.sliders.drag_d = arg1_434_
      end
      do
        local rv_437_, arg1_436_ = nil, nil
        do
          local arg1_436_0 = widgets.sliders.drag_d
          local _24 = arg1_436_0
          rv_437_, arg1_436_ = ImGui.DragDouble(ctx, "DragDouble (-inf -> +inf)", _24, 0.005, ( - DBL_MAX), DBL_MAX, "%.3f", widgets.sliders.flags)
        end
        widgets.sliders.drag_d = arg1_436_
      end
      local rv_439_, arg1_438_ = nil, nil
      do
        local arg1_438_0 = widgets.sliders.drag_i
        local _24 = arg1_438_0
        rv_439_, arg1_438_ = ImGui.DragInt(ctx, "DragInt (0 -> 100)", _24, 0.5, 0, 100, "%d", widgets.sliders.flags)
      end
      widgets.sliders.drag_i = arg1_438_
    end
    ImGui.Text(ctx, ("Underlying float value: %f"):format(widgets.sliders.slider_d))
    do
      local rv_441_, arg1_440_ = nil, nil
      do
        local arg1_440_0 = widgets.sliders.slider_d
        local _24 = arg1_440_0
        rv_441_, arg1_440_ = ImGui.SliderDouble(ctx, "SliderDouble (0 -> 1)", _24, 0, 1, "%.3f", widgets.sliders.flags)
      end
      widgets.sliders.slider_d = arg1_440_
    end
    do
      local rv_443_, arg1_442_ = nil, nil
      do
        local arg1_442_0 = widgets.sliders.slider_i
        local _24 = arg1_442_0
        rv_443_, arg1_442_ = ImGui.SliderInt(ctx, "SliderInt (0 -> 100)", _24, 0, 100, "%d", widgets.sliders.flags)
      end
      widgets.sliders.slider_i = arg1_442_
    end
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Range Widgets") then
    if not widgets.range then
      widgets.range = {begin_f = 10.0, end_f = 90.0, begin_i = 100, end_i = 1000}
    else
    end
    _, widgets.range.begin_f, widgets.range.end_f = ImGui.DragFloatRange2(ctx, "range float", widgets.range.begin_f, widgets.range.end_f, 0.25, 0, 100, "Min: %.1f %%", "Max: %.1f %%", ImGui.SliderFlags_AlwaysClamp())
    _, widgets.range.begin_i, widgets.range.end_i = ImGui.DragIntRange2(ctx, "range int", widgets.range.begin_i, widgets.range.end_i, 5, 0, 1000, "Min: %d units", "Max: %d units")
    _, widgets.range.begin_i, widgets.range.end_i = ImGui.DragIntRange2(ctx, "range int (no bounds)", widgets.range.begin_i, widgets.range.end_i, 5, 0, 0, "Min: %d units", "Max: %d units")
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Multi-component Widgets") then
    if not widgets.multi_component then
      widgets.multi_component = {vec4a = reaper.new_array({0.1, 0.2, 0.3, 0.44}), vec4d = {0.1, 0.2, 0.3, 0.44}, vec4i = {1, 5, 100, 255}}
    else
    end
    local vec4d = widgets.multi_component.vec4d
    local vec4i = widgets.multi_component.vec4i
    ImGui.SeparatorText(ctx, "2-wide")
    local vec4d1 = nil
    local vec4d2 = nil
    local vec4d3 = nil
    local vec4d4 = nil
    local vec4i1 = nil
    local vec4i2 = nil
    local vec4i3 = nil
    local vec4i4 = nil
    _, vec4d1, vec4d2 = ImGui.InputDouble2(ctx, "input double2", (vec4d)[1], (vec4d)[2])
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    _, vec4d1, vec4d2 = ImGui.DragDouble2(ctx, "drag double2", (vec4d)[1], (vec4d)[2], 0.01, 0, 1)
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    _, vec4d1, vec4d2 = ImGui.SliderDouble2(ctx, "slider double2", (vec4d)[1], (vec4d)[2], 0, 1)
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    _, vec4i1, vec4i2 = ImGui.InputInt2(ctx, "input int2", (vec4i)[1], (vec4i)[2])
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    _, vec4i1, vec4i2 = ImGui.DragInt2(ctx, "drag int2", (vec4i)[1], (vec4i)[2], 1, 0, 255)
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    _, vec4i1, vec4i2 = ImGui.SliderInt2(ctx, "slider int2", (vec4i)[1], (vec4i)[2], 0, 255)
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    ImGui.SeparatorText(ctx, "3-wide")
    _, vec4d1, vec4d2, vec4d3 = ImGui.InputDouble3(ctx, "input double3", (vec4d)[1], (vec4d)[2], (vec4d)[3])
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    vec4d[3] = vec4d3
    _, vec4d1, vec4d2, vec4d3 = ImGui.DragDouble3(ctx, "drag double3", (vec4d)[1], (vec4d)[2], (vec4d)[3], 0.01, 0, 1)
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    vec4d[3] = vec4d3
    _, vec4d1, vec4d2, vec4d3 = ImGui.SliderDouble3(ctx, "slider double3", (vec4d)[1], (vec4d)[2], (vec4d)[3], 0, 1)
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    vec4d[3] = vec4d3
    _, vec4i1, vec4i2, vec4i3 = ImGui.InputInt3(ctx, "input int3", (vec4i)[1], (vec4i)[2], (vec4i)[3])
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    vec4i[3] = vec4i3
    _, vec4i1, vec4i2, vec4i3 = ImGui.DragInt3(ctx, "drag int3", (vec4i)[1], (vec4i)[2], (vec4i)[3], 1, 0, 255)
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    vec4i[3] = vec4i3
    _, vec4i1, vec4i2, vec4i3 = ImGui.SliderInt3(ctx, "slider int3", (vec4i)[1], (vec4i)[2], (vec4i)[3], 0, 255)
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    vec4i[3] = vec4i3
    ImGui.SeparatorText(ctx, "4-wide")
    _, vec4d1, vec4d2, vec4d3, vec4d4 = ImGui.InputDouble4(ctx, "input double4", (vec4d)[1], (vec4d)[2], (vec4d)[3], (vec4d)[4])
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    vec4d[3] = vec4d3
    vec4d[4] = vec4d4
    _, vec4d1, vec4d2, vec4d3, vec4d4 = ImGui.DragDouble4(ctx, "drag double4", (vec4d)[1], (vec4d)[2], (vec4d)[3], (vec4d)[4], 0.01, 0, 1)
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    vec4d[3] = vec4d3
    vec4d[4] = vec4d4
    _, vec4d1, vec4d2, vec4d3, vec4d4 = ImGui.SliderDouble4(ctx, "slider double4", (vec4d)[1], (vec4d)[2], (vec4d)[3], (vec4d)[4], 0, 1)
    do end (vec4d)[1] = vec4d1
    vec4d[2] = vec4d2
    vec4d[3] = vec4d3
    vec4d[4] = vec4d4
    _, vec4i1, vec4i2, vec4i3, vec4i4 = ImGui.InputInt4(ctx, "input int4", (vec4i)[1], (vec4i)[2], (vec4i)[3], (vec4i)[4])
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    vec4i[3] = vec4i3
    vec4i[4] = vec4i4
    _, vec4i1, vec4i2, vec4i3, vec4i4 = ImGui.DragInt4(ctx, "drag int4", (vec4i)[1], (vec4i)[2], (vec4i)[3], (vec4i)[4], 1, 0, 255)
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    vec4i[3] = vec4i3
    vec4i[4] = vec4i4
    _, vec4i1, vec4i2, vec4i3, vec4i4 = ImGui.SliderInt4(ctx, "slider int4", (vec4i)[1], (vec4i)[2], (vec4i)[3], (vec4i)[4], 0, 255)
    do end (vec4i)[1] = vec4i1
    vec4i[2] = vec4i2
    vec4i[3] = vec4i3
    vec4i[4] = vec4i4
    ImGui.Spacing(ctx)
    ImGui.InputDoubleN(ctx, "input reaper.array", widgets.multi_component.vec4a)
    ImGui.DragDoubleN(ctx, "drag reaper.array", widgets.multi_component.vec4a, 0.01, 0.0, 1.0)
    ImGui.SliderDoubleN(ctx, "slider reaper.array", widgets.multi_component.vec4a, 0.0, 1.0)
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Vertical Sliders") then
    if not widgets.vsliders then
      widgets.vsliders = {int_value = 0, values = {0.0, 0.6, 0.35, 0.9, 0.7, 0.2, 0.0}, values2 = {0.2, 0.8, 0.4, 0.25}}
    else
    end
    local spacing = 4
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), spacing, spacing)
    do
      local rv_451_, arg1_450_ = nil, nil
      do
        local arg1_450_0 = widgets.vsliders.int_value
        local _24 = arg1_450_0
        rv_451_, arg1_450_ = ImGui.VSliderInt(ctx, "##int", 18, 160, _24, 0, 5)
      end
      widgets.vsliders.int_value = arg1_450_
    end
    ImGui.SameLine(ctx)
    ImGui.PushID(ctx, "set1")
    for i, v in ipairs(widgets.vsliders.values) do
      if (i > 1) then
        ImGui.SameLine(ctx)
      else
      end
      ImGui.PushID(ctx, i)
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg(), demo.HSV(((i - 1) / 7.0), 0.5, 0.5, 1.0))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered(), demo.HSV(((i - 1) / 7.0), 0.6, 0.5, 1.0))
      ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive(), demo.HSV(((i - 1) / 7.0), 0.7, 0.5, 1.0))
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab(), demo.HSV(((i - 1) / 7.0), 0.9, 0.9, 1.0))
      do
        local _, vi = ImGui.VSliderDouble(ctx, "##v", 18, 160, v, 0, 1, " ")
        do end (widgets.vsliders.values)[i] = vi
      end
      if (ImGui.IsItemActive(ctx) or ImGui.IsItemHovered(ctx)) then
        ImGui.SetTooltip(ctx, ("%.3f"):format(v))
      else
      end
      ImGui.PopStyleColor(ctx, 4)
      ImGui.PopID(ctx)
    end
    ImGui.PopID(ctx)
    ImGui.SameLine(ctx)
    ImGui.PushID(ctx, "set2")
    do
      local rows = 3
      local small_slider_w = 18
      local small_slider_h = ((160 - ((rows - 1) * spacing)) / rows)
      for nx, v2 in ipairs(widgets.vsliders.values2) do
        if (nx > 1) then
          ImGui.SameLine(ctx)
        else
        end
        ImGui.BeginGroup(ctx)
        for ny = 0, (rows - 1) do
          ImGui.PushID(ctx, ((nx * rows) + ny))
          local rv, v20 = ImGui.VSliderDouble(ctx, "##v", small_slider_w, small_slider_h, v2, 0.0, 1.0, " ")
          if rv then
            widgets.vsliders.values2[nx] = v20
          else
          end
          if (ImGui.IsItemActive(ctx) or ImGui.IsItemHovered(ctx)) then
            ImGui.SetTooltip(ctx, ("%.3f"):format(v20))
          else
          end
          ImGui.PopID(ctx)
        end
        ImGui.EndGroup(ctx)
      end
      ImGui.PopID(ctx)
    end
    ImGui.SameLine(ctx)
    ImGui.PushID(ctx, "set3")
    for i = 1, 4 do
      local v = widgets.vsliders.values[i]
      if (i > 1) then
        ImGui.SameLine(ctx)
      else
      end
      ImGui.PushID(ctx, i)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize(), 40)
      do
        local _, vi = ImGui.VSliderDouble(ctx, "##v", 40, 160, v, 0, 1, "%.2f sec")
        do end (widgets.vsliders.values)[i] = vi
      end
      ImGui.PopStyleVar(ctx)
      ImGui.PopID(ctx)
    end
    ImGui.PopID(ctx)
    ImGui.PopStyleVar(ctx)
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Drag and Drop") then
    if not widgets.dragdrop then
      widgets.dragdrop = {color1 = 16711731, color2 = 1723007104, files = {}, items = {"Item One", "Item Two", "Item Three", "Item Four", "Item Five"}, mode = 0, names = {"Bobby", "Beatrice", "Betty", "Brianna", "Barry", "Bernard", "Bibi", "Blaine", "Bryn"}}
    else
    end
    if ImGui.TreeNode(ctx, "Drag and drop in standard widgets") then
      demo.HelpMarker("You can drag from the color squares.")
      do
        local rv_461_, arg1_460_ = nil, nil
        do
          local arg1_460_0 = widgets.dragdrop.color1
          local _24 = arg1_460_0
          rv_461_, arg1_460_ = ImGui.ColorEdit3(ctx, "color 1", _24)
        end
        widgets.dragdrop.color1 = arg1_460_
      end
      do
        local rv_463_, arg1_462_ = nil, nil
        do
          local arg1_462_0 = widgets.dragdrop.color2
          local _24 = arg1_462_0
          rv_463_, arg1_462_ = ImGui.ColorEdit4(ctx, "color 2", _24)
        end
        widgets.dragdrop.color2 = arg1_462_
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Drag and drop to copy/swap items") then
      local mode_copy = 0
      local mode_move = 1
      local mode_swap = 2
      if ImGui.RadioButton(ctx, "Copy", (widgets.dragdrop.mode == mode_copy)) then
        widgets.dragdrop.mode = mode_copy
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.RadioButton(ctx, "Move", (widgets.dragdrop.mode == mode_move)) then
        widgets.dragdrop.mode = mode_move
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.RadioButton(ctx, "Swap", (widgets.dragdrop.mode == mode_swap)) then
        widgets.dragdrop.mode = mode_swap
      else
      end
      for n, name in ipairs(widgets.dragdrop.names) do
        ImGui.PushID(ctx, n)
        if (((n - 1) % 3) ~= 0) then
          ImGui.SameLine(ctx)
        else
        end
        ImGui.Button(ctx, name, 60, 60)
        if ImGui.BeginDragDropSource(ctx, ImGui.DragDropFlags_None()) then
          ImGui.SetDragDropPayload(ctx, "DND_DEMO_CELL", tostring(n))
          do
            local _469_ = widgets.dragdrop.mode
            if (nil ~= _469_) then
              local mode_copy0 = _469_
              ImGui.Text(ctx, ("Copy %s"):format(name))
            elseif (nil ~= _469_) then
              local mode_move0 = _469_
              ImGui.Text(ctx, ("Move %s"):format(name))
            elseif (nil ~= _469_) then
              local mode_swap0 = _469_
              ImGui.Text(ctx, ("Swap %s"):format(name))
            else
            end
          end
          ImGui.EndDragDropSource(ctx)
        else
        end
        if ImGui.BeginDragDropTarget(ctx) then
          local rv, payload = ImGui.AcceptDragDropPayload(ctx, "DND_DEMO_CELL")
          if rv then
            local payload0 = tonumber(payload)
            local _472_ = widgets.dragdrop.mode
            if (nil ~= _472_) then
              local mode_copy0 = _472_
              widgets.dragdrop.names[n] = widgets.dragdrop.names[payload0]
            elseif (nil ~= _472_) then
              local mode_move0 = _472_
              widgets.dragdrop.names[n] = widgets.dragdrop.names[payload0]
              widgets.dragdrop.names[payload0] = ""
            elseif (nil ~= _472_) then
              local mode_swap0 = _472_
              widgets.dragdrop.names[n] = widgets.dragdrop.names[payload0]
              widgets.dragdrop.names[payload0] = name
            else
            end
          else
          end
          ImGui.EndDragDropTarget(ctx)
        else
        end
        ImGui.PopID(ctx)
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Drag to reorder items (simple)") then
      demo.HelpMarker("We don't use the drag and drop api at all here! Instead we query when the item is held but not hovered, and order items accordingly.")
      for n, item in ipairs(widgets.dragdrop.items) do
        ImGui.Selectable(ctx, item)
        if (ImGui.IsItemActive(ctx) and not ImGui.IsItemHovered(ctx)) then
          local mouse_delta = select(2, ImGui.GetMouseDragDelta(ctx, ImGui.MouseButton_Left()))
          local n_next = (n + (((mouse_delta < 0) and ( - 1)) or 1))
          if (function(_477_,_478_,_479_) return (_477_ <= _478_) and (_478_ <= _479_) end)(1,n_next,#widgets.dragdrop.items) then
            widgets.dragdrop.items[n] = widgets.dragdrop.items[n_next]
            widgets.dragdrop.items[n_next] = item
            ImGui.ResetMouseDragDelta(ctx, ImGui.MouseButton_Left())
          else
          end
        else
        end
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Drag and drop files") then
      if ImGui.BeginChildFrame(ctx, "##drop_files", ( - FLT_MIN), 100) then
        if (#widgets.dragdrop.files == 0) then
          ImGui.Text(ctx, "Drag and drop files here...")
        else
          ImGui.Text(ctx, ("Received %d file(s):"):format(#widgets.dragdrop.files))
          ImGui.SameLine(ctx)
          if ImGui.SmallButton(ctx, "Clear") then
            widgets.dragdrop.files = {}
          else
          end
        end
        for _, file in ipairs(widgets.dragdrop.files) do
          ImGui.Bullet(ctx)
          ImGui.TextWrapped(ctx, file)
        end
        ImGui.EndChildFrame(ctx)
      else
      end
      if ImGui.BeginDragDropTarget(ctx) then
        local rv, count = ImGui.AcceptDragDropPayloadFiles(ctx)
        if rv then
          widgets.dragdrop.files = {}
          for i = 0, (count - 1) do
            local _, filename = ImGui.GetDragDropPayloadFile(ctx, i)
            table.insert(widgets.dragdrop.files, filename)
          end
        else
        end
        ImGui.EndDragDropTarget(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Querying Item Status (Edited/Active/Hovered etc.)") then
    if not widgets.query_item then
      widgets.query_item = {color = 4286578943, current = 1, d4a = {1.0, 0.5, 0.0, 1.0}, item_type = 1, str = "", b = false}
    else
    end
    rv, widgets.query_item.item_type = ImGui.Combo(ctx, "Item Type", widgets.query_item.item_type, "Text\0Button\0Button (w/ repeat)\0Checkbox\0SliderDouble\0\n                      InputText\0InputTextMultiline\0InputDouble\0InputDouble3\0ColorEdit4\0\n                      Selectable\0MenuItem\0TreeNode\0TreeNode (w/ double-click)\0Combo\0ListBox\0")
    ImGui.SameLine(ctx)
    demo.HelpMarker("Testing how various types of items are interacting with the IsItemXXX \n       functions. Note that the bool return value of most ImGui function is \n       generally equivalent to calling ImGui.IsItemHovered().")
    if widgets.query_item.item_disabled then
      ImGui.BeginDisabled(ctx, true)
    else
    end
    do
      local rv
      do
        local _492_ = widgets.query_item.item_type
        if (_492_ == 0) then
          rv = ImGui.Text(ctx, "ITEM: Text")
        elseif (_492_ == 1) then
          rv = ImGui.Button(ctx, "ITEM: Button")
        elseif (_492_ == 2) then
          local _ = ImGui.PushButtonRepeat(ctx, true)
          local rv0 = ImGui.Button(ctx, "ITEM: Button")
          local _0 = ImGui.PopButtonRepeat(ctx)
          rv = rv0
        elseif (_492_ == 3) then
          local rv_494_, arg1_493_ = nil, nil
          do
            local arg1_493_0 = widgets.query_item.b
            local _24 = arg1_493_0
            rv_494_, arg1_493_ = ImGui.Checkbox(ctx, "ITEM: Checkbox", _24)
          end
          widgets.query_item.b = arg1_493_
          rv = rv_494_, arg1_493_
        elseif (_492_ == 4) then
          local rv0, da41 = ImGui.SliderDouble(ctx, "ITEM: SliderDouble", (widgets.query_item.d4a)[1], 0, 1)
          do end (widgets.query_item.d4a)[1] = da41
          rv = rv0
        elseif (_492_ == 5) then
          local rv_496_, arg1_495_ = nil, nil
          do
            local arg1_495_0 = widgets.query_item.str
            local _24 = arg1_495_0
            rv_496_, arg1_495_ = ImGui.InputText(ctx, "ITEM: InputText", _24)
          end
          widgets.query_item.str = arg1_495_
          rv = rv_496_, arg1_495_
        elseif (_492_ == 6) then
          local rv_498_, arg1_497_ = nil, nil
          do
            local arg1_497_0 = widgets.query_item.str
            local _24 = arg1_497_0
            rv_498_, arg1_497_ = ImGui.InputTextMultiline(ctx, "ITEM: InputTextMultiline", _24)
          end
          widgets.query_item.str = arg1_497_
          rv = rv_498_, arg1_497_
        elseif (_492_ == 7) then
          local rv0, d4a1 = ImGui.InputDouble(ctx, "ITEM: InputDouble", (widgets.query_item.d4a)[1], 1)
          do end (widgets.query_item.d4a)[1] = d4a1
          rv = rv0
        elseif (_492_ == 8) then
          local d4a = widgets.query_item.d4a
          local rv0, d4a1, d4a2, d4a3 = ImGui.InputDouble3(ctx, "ITEM: InputDouble3", (d4a)[1], (d4a)[2], (d4a)[3])
          do end (d4a)[1] = d4a1
          d4a[2] = d4a2
          d4a[3] = d4a3
          rv = rv0
        elseif (_492_ == 9) then
          local rv_500_, arg1_499_ = nil, nil
          do
            local arg1_499_0 = widgets.query_item.color
            local _24 = arg1_499_0
            rv_500_, arg1_499_ = ImGui.ColorEdit4(ctx, "ITEM: ColorEdit", _24)
          end
          widgets.query_item.color = arg1_499_
          rv = rv_500_, arg1_499_
        elseif (_492_ == 10) then
          rv = ImGui.Selectable(ctx, "ITEM: Selectable")
        elseif (_492_ == 11) then
          rv = ImGui.MenuItem(ctx, "ITEM: MenuItem")
        elseif (_492_ == 12) then
          local rv0 = ImGui.TreeNode(ctx, "ITEM: TreeNode")
          if rv0 then
            ImGui.TreePop(ctx)
          else
          end
          rv = rv0
        elseif (_492_ == 13) then
          rv = ImGui.TreeNode(ctx, "ITEM: TreeNode w/ ImGuiTreeNodeFlags_OpenOnDoubleClick", (ImGui.TreeNodeFlags_OpenOnDoubleClick() | ImGui.TreeNodeFlags_NoTreePushOnOpen()))
        elseif (_492_ == 14) then
          local rv_503_, arg1_502_ = nil, nil
          do
            local arg1_502_0 = widgets.query_item.current
            local _24 = arg1_502_0
            rv_503_, arg1_502_ = ImGui.Combo(ctx, "ITEM: Combo", _24, "Apple\0Banana\0Cherry\0Kiwi\0")
          end
          widgets.query_item.current = arg1_502_
          rv = rv_503_, arg1_502_
        elseif (_492_ == 15) then
          local rv_505_, arg1_504_ = nil, nil
          do
            local arg1_504_0 = widgets.query_item.current
            local _24 = arg1_504_0
            rv_505_, arg1_504_ = ImGui.ListBox(ctx, "ITEM: ListBox", _24, "Apple\0Banana\0Cherry\0Kiwi\0")
          end
          widgets.query_item.current = arg1_504_
          rv = rv_505_, arg1_504_
        else
          rv = nil
        end
      end
      local hovered_delay_none = ImGui.IsItemHovered(ctx)
      local hovered_delay_short = ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayShort())
      local hovered_delay_normal = ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayNormal())
      ImGui.BulletText(ctx, ("Return value = %s\nIsItemFocused() = %s\nIsItemHovered() = %s\nIsItemHovered(_AllowWhenBlockedByPopup) = %s\nIsItemHovered(_AllowWhenBlockedByActiveItem) = %s\nIsItemHovered(_AllowWhenOverlapped) = %s\nIsItemHovered(_AllowWhenDisabled) = %s\nIsItemHovered(_RectOnly) = %s\nIsItemActive() = %s\nIsItemEdited() = %s\nIsItemActivated() = %s\nIsItemDeactivated() = %s\nIsItemDeactivatedAfterEdit() = %s\nIsItemVisible() = %s\nIsItemClicked() = %s\nIsItemToggledOpen() = %s\nGetItemRectMin() = (%.1f, %.1f)\nGetItemRectMax() = (%.1f, %.1f)\nGetItemRectSize() = (%.1f, %.1f)"):format(rv, ImGui.IsItemFocused(ctx), ImGui.IsItemHovered(ctx), ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenBlockedByPopup()), ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenBlockedByActiveItem()), ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenOverlapped()), ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_AllowWhenDisabled()), ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_RectOnly()), ImGui.IsItemActive(ctx), ImGui.IsItemEdited(ctx), ImGui.IsItemActivated(ctx), ImGui.IsItemDeactivated(ctx), ImGui.IsItemDeactivatedAfterEdit(ctx), ImGui.IsItemVisible(ctx), ImGui.IsItemClicked(ctx), ImGui.IsItemToggledOpen(ctx), ImGui.GetItemRectMin(ctx), select(2, ImGui.GetItemRectMin(ctx)), ImGui.GetItemRectMax(ctx), select(2, ImGui.GetItemRectMax(ctx)), ImGui.GetItemRectSize(ctx), select(2, ImGui.GetItemRectSize(ctx))))
      ImGui.BulletText(ctx, ("w/ Hovering Delay: None = %s, Fast = %s, Normal = %s"):format(hovered_delay_none, hovered_delay_short, hovered_delay_normal))
    end
    if widgets.query_item.item_disabled then
      ImGui.EndDisabled(ctx)
    else
    end
    ImGui.InputText(ctx, "unused", "", ImGui.InputTextFlags_ReadOnly())
    ImGui.SameLine(ctx)
    demo.HelpMarker("This widget is only here to be able to tab-out of the widgets above and see e.g. Deactivated() status.")
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Querying Window Status (Focused/Hovered etc.)") then
    if not widgets.query_window then
      widgets.query_window = {test_window = false, embed_all_inside_a_child_window = false}
    else
    end
    do
      local rv_511_, arg1_510_ = nil, nil
      do
        local arg1_510_0 = widgets.query_window.embed_all_inside_a_child_window
        local _24 = arg1_510_0
        rv_511_, arg1_510_ = ImGui.Checkbox(ctx, "Embed everything inside a child window for testing _RootWindow flag.", _24)
      end
      widgets.query_window.embed_all_inside_a_child_window = arg1_510_
    end
    do
      local visible = (not widgets.query_window.embed_all_inside_a_child_window or ImGui.BeginChild(ctx, "outer_child", 0, (ImGui.GetFontSize(ctx) * 20), true))
      if visible then
        ImGui.BulletText(ctx, ("IsWindowFocused() = %s\n  IsWindowFocused(_ChildWindows) = %s\n  IsWindowFocused(_ChildWindows|_NoPopupHierarchy) = %s\n  IsWindowFocused(_ChildWindows|_DockHierarchy) = %s\n  IsWindowFocused(_ChildWindows|_RootWindow) = %s\n  IsWindowFocused(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %s\n  IsWindowFocused(_ChildWindows|_RootWindow|_DockHierarchy) = %s\n  IsWindowFocused(_RootWindow) = %s\n  IsWindowFocused(_RootWindow|_NoPopupHierarchy) = %s\n  IsWindowFocused(_RootWindow|_DockHierarchy) = %s\n  IsWindowFocused(_AnyWindow) = %s"):format(ImGui.IsWindowFocused(ctx), ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_ChildWindows()), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_ChildWindows() | ImGui.FocusedFlags_NoPopupHierarchy())), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_ChildWindows() | ImGui.FocusedFlags_DockHierarchy())), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_ChildWindows() | ImGui.FocusedFlags_RootWindow())), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_ChildWindows() | ImGui.FocusedFlags_RootWindow() | ImGui.FocusedFlags_NoPopupHierarchy())), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_ChildWindows() | ImGui.FocusedFlags_RootWindow() | ImGui.FocusedFlags_DockHierarchy())), ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootWindow()), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_RootWindow() | ImGui.FocusedFlags_NoPopupHierarchy())), ImGui.IsWindowFocused(ctx, (ImGui.FocusedFlags_RootWindow() | ImGui.FocusedFlags_DockHierarchy())), ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_AnyWindow())))
        ImGui.BulletText(ctx, ("IsWindowHovered() = %s\n IsWindowHovered(_AllowWhenBlockedByPopup) = %s\n IsWindowHovered(_AllowWhenBlockedByActiveItem) = %s\n IsWindowHovered(_ChildWindows) = %s\n IsWindowHovered(_ChildWindows|_NoPopupHierarchy) = %s\n IsWindowHovered(_ChildWindows|_DockHierarchy) = %s\n IsWindowHovered(_ChildWindows|_RootWindow) = %s\n IsWindowHovered(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %s\n IsWindowHovered(_ChildWindows|_RootWindow|_DockHierarchy) = %s\n IsWindowHovered(_RootWindow) = %s\n IsWindowHovered(_RootWindow|_NoPopupHierarchy) = %s\n IsWindowHovered(_RootWindow|_DockHierarchy) = %s\n IsWindowHovered(_ChildWindows|_AllowWhenBlockedByPopup) = %s\n IsWindowHovered(_AnyWindow) = %s"):format(ImGui.IsWindowHovered(ctx), ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_AllowWhenBlockedByPopup()), ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_AllowWhenBlockedByActiveItem()), ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_ChildWindows()), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_ChildWindows() | ImGui.HoveredFlags_NoPopupHierarchy())), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_ChildWindows() | ImGui.HoveredFlags_DockHierarchy())), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_ChildWindows() | ImGui.HoveredFlags_RootWindow())), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_ChildWindows() | ImGui.HoveredFlags_RootWindow() | ImGui.HoveredFlags_NoPopupHierarchy())), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_ChildWindows() | ImGui.HoveredFlags_RootWindow() | ImGui.HoveredFlags_DockHierarchy())), ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootWindow()), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_RootWindow() | ImGui.HoveredFlags_NoPopupHierarchy())), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_RootWindow() | ImGui.HoveredFlags_DockHierarchy())), ImGui.IsWindowHovered(ctx, (ImGui.HoveredFlags_ChildWindows() | ImGui.HoveredFlags_AllowWhenBlockedByPopup())), ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_AnyWindow())))
        if ImGui.BeginChild(ctx, "child", 0, 50, true) then
          ImGui.Text(ctx, "This is another child window for testing the _ChildWindows flag.")
          ImGui.EndChild(ctx)
        else
        end
        if widgets.query_window.embed_all_inside_a_child_window then
          ImGui.EndChild(ctx)
        else
        end
      else
      end
    end
    do
      local rv_516_, arg1_515_ = nil, nil
      do
        local arg1_515_0 = widgets.query_window.test_window
        local _24 = arg1_515_0
        rv_516_, arg1_515_ = ImGui.Checkbox(ctx, "Hovered/Active tests after Begin() for title bar testing", _24)
      end
      widgets.query_window.test_window = arg1_515_
    end
    if widgets.query_window.test_window then
      local rv = nil
      rv, widgets.query_window.test_window = ImGui.Begin(ctx, "Title bar Hovered/Active tests", true)
      if rv then
        if ImGui.BeginPopupContextItem(ctx) then
          if ImGui.MenuItem(ctx, "Close") then
            widgets.query_window.test_window = false
          else
          end
          ImGui.EndPopup(ctx)
        else
        end
        ImGui.Text(ctx, ("IsItemHovered() after begin = %s (== is title bar hovered)\n\n                        IsItemActive() after begin = %s (== is window being clicked/moved)\n"):format(ImGui.IsItemHovered(ctx), ImGui.IsItemActive(ctx)))
        ImGui.End(ctx)
      else
      end
    else
    end
    ImGui.TreePop(ctx)
  else
  end
  if widgets.disable_all then
    ImGui.EndDisabled(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Disable block") then
    do
      local rv_524_, arg1_523_ = nil, nil
      do
        local arg1_523_0 = widgets.disable_all
        local _24 = arg1_523_0
        rv_524_, arg1_523_ = ImGui.Checkbox(ctx, "Disable entire section above", _24)
      end
      widgets.disable_all = arg1_523_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("Demonstrate using BeginDisabled()/EndDisabled() across this section.")
    ImGui.TreePop(ctx)
  else
  end
  if ImGui.TreeNode(ctx, "Text Filter") then
    if not widgets.filtering then
      widgets.filtering = {inst = nil, text = ""}
    else
    end
    if not ImGui.ValidatePtr(widgets.filtering.inst, "ImGui_TextFilter*") then
      widgets.filtering.inst = ImGui.CreateTextFilter(widgets.filtering.text)
    else
    end
    demo.HelpMarker("Not a widget per-se, but ImGui_TextFilter is a helper to perform simple filtering on text strings.")
    ImGui.Text(ctx, "Filter usage:\n  \"\"         display all lines\n  \"xxx\"      display lines containing \"xxx\"\n  \"xxx,yyy\"  display lines containing \"xxx\" or \"yyy\"\n  \"-xxx\"     hide lines containing \"xxx\"")
    if ImGui.TextFilter_Draw(widgets.filtering.inst, ctx) then
      widgets.filtering.text = ImGui.TextFilter_Get(widgets.filtering.inst)
    else
    end
    local lines = {"aaa1.c", "bbb1.c", "ccc1.c", "aaa2.cpp", "bbb2.cpp", "ccc2.cpp", "abc.h", "hello, world"}
    for i, line in ipairs(lines) do
      if ImGui.TextFilter_PassFilter(widgets.filtering.inst, line) then
        ImGui.BulletText(ctx, line)
      else
      end
    end
    return ImGui.TreePop(ctx)
  else
    return nil
  end
end
demo.ShowDemoWindowLayout = function()
  if ImGui.CollapsingHeader(ctx, "Layout & Scrolling") then
    local rv = nil
    if ImGui.TreeNode(ctx, "Child windows") then
      if not layout.child then
        layout.child = {offset_x = 0, disable_menu = false, disable_mouse_wheel = false}
      else
      end
      ImGui.SeparatorText(ctx, "Child windows")
      demo.HelpMarker("Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window.")
      do
        local rv_533_, arg1_532_ = nil, nil
        do
          local arg1_532_0 = layout.child.disable_mouse_wheel
          local _24 = arg1_532_0
          rv_533_, arg1_532_ = ImGui.Checkbox(ctx, "Disable Mouse Wheel", _24)
        end
        layout.child.disable_mouse_wheel = arg1_532_
      end
      do
        local rv_535_, arg1_534_ = nil, nil
        do
          local arg1_534_0 = layout.child.disable_menu
          local _24 = arg1_534_0
          rv_535_, arg1_534_ = ImGui.Checkbox(ctx, "Disable Menu", _24)
        end
        layout.child.disable_menu = arg1_534_
      end
      do
        local window_flags
        local function _536_()
          if layout.child.disable_mouse_wheel then
            return ImGui.WindowFlags_NoScrollWithMouse()
          else
            return 0
          end
        end
        window_flags = (ImGui.WindowFlags_HorizontalScrollbar() | _536_())
        if ImGui.BeginChild(ctx, "ChildL", (ImGui.GetContentRegionAvail(ctx) * 0.5), 260, false, window_flags) then
          for i = 0, 99 do
            ImGui.Text(ctx, ("%04d: scrollable region"):format(i))
          end
          ImGui.EndChild(ctx)
        else
        end
      end
      ImGui.SameLine(ctx)
      do
        local window_flags
        local _538_
        if layout.child.disable_mouse_wheel then
          _538_ = ImGui.WindowFlags_NoScrollWithMouse()
        else
          _538_ = 0
        end
        local function _540_()
          if not layout.child.disable_menu then
            return ImGui.WindowFlags_MenuBar()
          else
            return 0
          end
        end
        window_flags = (ImGui.WindowFlags_None() | _538_ | _540_())
        local _ = ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildRounding(), 5)
        local visible = ImGui.BeginChild(ctx, "ChildR", 0, 260, true, window_flags)
        if visible then
          if (not layout.child.disable_menu and ImGui.BeginMenuBar(ctx)) then
            if ImGui.BeginMenu(ctx, "Menu") then
              demo.ShowExampleMenuFile()
              ImGui.EndMenu(ctx)
            else
            end
            ImGui.EndMenuBar(ctx)
          else
          end
          if ImGui.BeginTable(ctx, "split", 2, (ImGui.TableFlags_Resizable() | ImGui.TableFlags_NoSavedSettings())) then
            for i = 0, 99 do
              ImGui.TableNextColumn(ctx)
              ImGui.Button(ctx, ("%03d"):format(i), ( - FLT_MIN), 0)
            end
            ImGui.EndTable(ctx)
          else
          end
          ImGui.EndChild(ctx)
        else
        end
        ImGui.PopStyleVar(ctx)
      end
      ImGui.SeparatorText(ctx, "Misc/Advanced")
      do
        ImGui.SetNextItemWidth(ctx, (ImGui.GetFontSize(ctx) * 8))
        assert(layout.child.offset_x, "offset_x is nil! before")
        do
          local v, v1 = nil, nil
          do
            local rv_546_, arg1_545_ = nil, nil
            do
              local arg1_545_0 = layout.child.offset_x
              local _24 = arg1_545_0
              rv_546_, arg1_545_ = ImGui.DragInt(ctx, "Offset X", _24, 1.0, -1000, 1000)
            end
            layout.child.offset_x = arg1_545_
            v, v1 = rv_546_, arg1_545_
          end
          assert(v1, ("v1 is nil! " .. tostring(rv)))
        end
        assert(layout.child.offset_x, "offset_x is nil! after")
        ImGui.SetCursorPosX(ctx, (ImGui.GetCursorPosX(ctx) + layout.child.offset_x))
        ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg(), 4278190180)
        do
          local visible = ImGui.BeginChild(ctx, "Red", 200, 100, true, ImGui.WindowFlags_None())
          ImGui.PopStyleColor(ctx)
          if visible then
            for n = 0, 49 do
              ImGui.Text(ctx, ("Some test %d"):format(n))
            end
            ImGui.EndChild(ctx)
          else
          end
        end
        local child_is_hovered = ImGui.IsItemHovered(ctx)
        local child_rect_min_x, child_rect_min_y = ImGui.GetItemRectMin(ctx)
        local child_rect_max_x, child_rect_max_y = ImGui.GetItemRectMax(ctx)
        ImGui.Text(ctx, ("Hovered: %s"):format(child_is_hovered))
        ImGui.Text(ctx, ("Rect of child window is: (%.0f,%.0f) (%.0f,%.0f)"):format(child_rect_min_x, child_rect_min_y, child_rect_max_x, child_rect_max_y))
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Widgets Width") then
      if not layout.width then
        layout.width = {d = 0, show_indented_items = true}
      else
      end
      do
        local rv_551_, arg1_550_ = nil, nil
        do
          local arg1_550_0 = layout.width.show_indented_items
          local _24 = arg1_550_0
          rv_551_, arg1_550_ = ImGui.Checkbox(ctx, "Show indented items", _24)
        end
        layout.width.show_indented_items = arg1_550_
      end
      ImGui.Text(ctx, "SetNextItemWidth/PushItemWidth(100)")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Fixed width.")
      ImGui.PushItemWidth(ctx, 100)
      do
        local rv_553_, arg1_552_ = nil, nil
        do
          local arg1_552_0 = layout.width.d
          local _24 = arg1_552_0
          rv_553_, arg1_552_ = ImGui.DragDouble(ctx, "float##1b", _24)
        end
        layout.width.d = arg1_552_
      end
      if layout.width.show_indented_items then
        ImGui.Indent(ctx)
        do
          local rv_555_, arg1_554_ = nil, nil
          do
            local arg1_554_0 = layout.width.d
            local _24 = arg1_554_0
            rv_555_, arg1_554_ = ImGui.DragDouble(ctx, "float (indented)##1b", _24)
          end
          layout.width.d = arg1_554_
        end
        ImGui.Unindent(ctx)
      else
      end
      ImGui.PopItemWidth(ctx)
      ImGui.Text(ctx, "SetNextItemWidth/PushItemWidth(-100)")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Align to right edge minus 100")
      ImGui.PushItemWidth(ctx, ( - 100))
      do
        local rv_558_, arg1_557_ = nil, nil
        do
          local arg1_557_0 = layout.width.d
          local _24 = arg1_557_0
          rv_558_, arg1_557_ = ImGui.DragDouble(ctx, "float##2a", _24)
        end
        layout.width.d = arg1_557_
      end
      if layout.width.show_indented_items then
        ImGui.Indent(ctx)
        do
          local rv_560_, arg1_559_ = nil, nil
          do
            local arg1_559_0 = layout.width.d
            local _24 = arg1_559_0
            rv_560_, arg1_559_ = ImGui.DragDouble(ctx, "float (indented)##2b", _24)
          end
          layout.width.d = arg1_559_
        end
        ImGui.Unindent(ctx)
      else
      end
      ImGui.PopItemWidth(ctx)
      ImGui.Text(ctx, "SetNextItemWidth/PushItemWidth(GetContentRegionAvail().x * 0.5)")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Half of available width.\n(~ right-cursor_pos)\n(works within a column set)")
      ImGui.PushItemWidth(ctx, (ImGui.GetContentRegionAvail(ctx) * 0.5))
      do
        local rv_563_, arg1_562_ = nil, nil
        do
          local arg1_562_0 = layout.width.d
          local _24 = arg1_562_0
          rv_563_, arg1_562_ = ImGui.DragDouble(ctx, "float##3a", _24)
        end
        layout.width.d = arg1_562_
      end
      if layout.width.show_indented_items then
        ImGui.Indent(ctx)
        do
          local rv_565_, arg1_564_ = nil, nil
          do
            local arg1_564_0 = layout.width.d
            local _24 = arg1_564_0
            rv_565_, arg1_564_ = ImGui.DragDouble(ctx, "float (indented)##3b", _24)
          end
          layout.width.d = arg1_564_
        end
        ImGui.Unindent(ctx)
      else
      end
      ImGui.PopItemWidth(ctx)
      ImGui.Text(ctx, "SetNextItemWidth/PushItemWidth(-GetContentRegionAvail().x * 0.5)")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Align to right edge minus half")
      ImGui.PushItemWidth(ctx, (( - ImGui.GetContentRegionAvail(ctx)) * 0.5))
      do
        local rv_568_, arg1_567_ = nil, nil
        do
          local arg1_567_0 = layout.width.d
          local _24 = arg1_567_0
          rv_568_, arg1_567_ = ImGui.DragDouble(ctx, "float##4a", _24)
        end
        layout.width.d = arg1_567_
      end
      if layout.width.show_indented_items then
        ImGui.Indent(ctx)
        do
          local rv_570_, arg1_569_ = nil, nil
          do
            local arg1_569_0 = layout.width.d
            local _24 = arg1_569_0
            rv_570_, arg1_569_ = ImGui.DragDouble(ctx, "float (indented)##4b", _24)
          end
          layout.width.d = arg1_569_
        end
        ImGui.Unindent(ctx)
      else
      end
      ImGui.PopItemWidth(ctx)
      ImGui.Text(ctx, "SetNextItemWidth/PushItemWidth(-FLT_MIN)")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Align to right edge")
      ImGui.PushItemWidth(ctx, ( - FLT_MIN))
      do
        local rv_573_, arg1_572_ = nil, nil
        do
          local arg1_572_0 = layout.width.d
          local _24 = arg1_572_0
          rv_573_, arg1_572_ = ImGui.DragDouble(ctx, "##float5a", _24)
        end
        layout.width.d = arg1_572_
      end
      if layout.width.show_indented_items then
        ImGui.Indent(ctx)
        do
          local rv_575_, arg1_574_ = nil, nil
          do
            local arg1_574_0 = layout.width.d
            local _24 = arg1_574_0
            rv_575_, arg1_574_ = ImGui.DragDouble(ctx, "float (indented)##5b", _24)
          end
          layout.width.d = arg1_574_
        end
        ImGui.Unindent(ctx)
      else
      end
      ImGui.PopItemWidth(ctx)
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Basic Horizontal Layout") then
      if not layout.horizontal then
        layout.horizontal = {d0 = 1.0, d1 = 2.0, d2 = 3.0, item = -1, selection = {0, 1, 2, 3}, c3 = false, c4 = false, c2 = false, c1 = false}
      else
      end
      ImGui.TextWrapped(ctx, "(Use ImGui.SameLine() to keep adding items to the right of the preceding item)")
      ImGui.Text(ctx, "Two items: Hello")
      ImGui.SameLine(ctx)
      ImGui.TextColored(ctx, 4294902015, "Sailor")
      ImGui.Text(ctx, "More spacing: Hello")
      ImGui.SameLine(ctx, 0, 20)
      ImGui.TextColored(ctx, 4294902015, "Sailor")
      ImGui.AlignTextToFramePadding(ctx)
      ImGui.Text(ctx, "Normal buttons")
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "Banana")
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "Apple")
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "Corniflower")
      ImGui.Text(ctx, "Small buttons")
      ImGui.SameLine(ctx)
      ImGui.SmallButton(ctx, "Like this one")
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, "can fit within a text block.")
      ImGui.Text(ctx, "Aligned")
      ImGui.SameLine(ctx, 150)
      ImGui.Text(ctx, "x=150")
      ImGui.SameLine(ctx, 300)
      ImGui.Text(ctx, "x=300")
      ImGui.Text(ctx, "Aligned")
      ImGui.SameLine(ctx, 150)
      ImGui.SmallButton(ctx, "x=150")
      ImGui.SameLine(ctx, 300)
      ImGui.SmallButton(ctx, "x=300")
      do
        local rv_580_, arg1_579_ = nil, nil
        do
          local arg1_579_0 = layout.horizontal.c1
          local _24 = arg1_579_0
          rv_580_, arg1_579_ = ImGui.Checkbox(ctx, "My", _24)
        end
        layout.horizontal.c1 = arg1_579_
      end
      ImGui.SameLine(ctx)
      do
        local rv_582_, arg1_581_ = nil, nil
        do
          local arg1_581_0 = layout.horizontal.c2
          local _24 = arg1_581_0
          rv_582_, arg1_581_ = ImGui.Checkbox(ctx, "Tailor", _24)
        end
        layout.horizontal.c2 = arg1_581_
      end
      ImGui.SameLine(ctx)
      do
        local rv_584_, arg1_583_ = nil, nil
        do
          local arg1_583_0 = layout.horizontal.c3
          local _24 = arg1_583_0
          rv_584_, arg1_583_ = ImGui.Checkbox(ctx, "Is", _24)
        end
        layout.horizontal.c3 = arg1_583_
      end
      ImGui.SameLine(ctx)
      do
        local rv_586_, arg1_585_ = nil, nil
        do
          local arg1_585_0 = layout.horizontal.c4
          local _24 = arg1_585_0
          rv_586_, arg1_585_ = ImGui.Checkbox(ctx, "Rich", _24)
        end
        layout.horizontal.c4 = arg1_585_
      end
      ImGui.PushItemWidth(ctx, 80)
      local items = "AAAA\0BBBB\0CCCC\0DDDD\0"
      do
        local rv_588_, arg1_587_ = nil, nil
        do
          local arg1_587_0 = layout.horizontal.item
          local _24 = arg1_587_0
          rv_588_, arg1_587_ = ImGui.Combo(ctx, "Combo", _24, items)
        end
        layout.horizontal.item = arg1_587_
      end
      ImGui.SameLine(ctx)
      do
        local rv_590_, arg1_589_ = nil, nil
        do
          local arg1_589_0 = layout.horizontal.d0
          local _24 = arg1_589_0
          rv_590_, arg1_589_ = ImGui.SliderDouble(ctx, "X", _24, 0, 5)
        end
        layout.horizontal.d0 = arg1_589_
      end
      ImGui.SameLine(ctx)
      do
        local rv_592_, arg1_591_ = nil, nil
        do
          local arg1_591_0 = layout.horizontal.d1
          local _24 = arg1_591_0
          rv_592_, arg1_591_ = ImGui.SliderDouble(ctx, "Y", _24, 0, 5)
        end
        layout.horizontal.d1 = arg1_591_
      end
      ImGui.SameLine(ctx)
      do
        local rv_594_, arg1_593_ = nil, nil
        do
          local arg1_593_0 = layout.horizontal.d2
          local _24 = arg1_593_0
          rv_594_, arg1_593_ = ImGui.SliderDouble(ctx, "Z", _24, 0, 5)
        end
        layout.horizontal.d2 = arg1_593_
      end
      ImGui.PopItemWidth(ctx)
      ImGui.PushItemWidth(ctx, 80)
      ImGui.Text(ctx, "Lists:")
      for i, sel in ipairs(layout.horizontal.selection) do
        if (i > 1) then
          ImGui.SameLine(ctx)
        else
        end
        ImGui.PushID(ctx, i)
        do
          local _, si = ImGui.ListBox(ctx, "", sel, items)
          do end (layout.horizontal.selection)[i] = si
        end
        ImGui.PopID(ctx)
      end
      ImGui.PopItemWidth(ctx)
      local button_sz = {40, 40}
      ImGui.Button(ctx, "A", table.unpack(button_sz))
      ImGui.SameLine(ctx)
      ImGui.Dummy(ctx, table.unpack(button_sz))
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "B", table.unpack(button_sz))
      ImGui.Text(ctx, "Manual wrapping:")
      do
        local item_spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing())
        local buttons_count = 20
        local window_visible_x2 = (ImGui.GetWindowPos(ctx) + ImGui.GetWindowContentRegionMax(ctx))
        for n = 0, (buttons_count - 1) do
          ImGui.PushID(ctx, n)
          ImGui.Button(ctx, "Box", table.unpack(button_sz))
          do
            local last_button_x2 = ImGui.GetItemRectMax(ctx)
            local next_button_x2 = (last_button_x2 + item_spacing_x + button_sz[1])
            if (((n + 1) < buttons_count) and (next_button_x2 < window_visible_x2)) then
              ImGui.SameLine(ctx)
            else
            end
          end
          ImGui.PopID(ctx)
        end
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Groups") then
      if not widgets.groups then
        widgets.groups = {values = reaper.new_array({0.5, 0.2, 0.8, 0.6, 0.25})}
      else
      end
      demo.HelpMarker("BeginGroup() basically locks the horizontal position for new line. \n        EndGroup() bundles the whole group so that you can use ", item, " functions such as \n        IsItemHovered()/IsItemActive() or SameLine() etc. on the whole group.")
      ImGui.BeginGroup(ctx)
      ImGui.BeginGroup(ctx)
      ImGui.Button(ctx, "AAA")
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "BBB")
      ImGui.SameLine(ctx)
      ImGui.BeginGroup(ctx)
      ImGui.Button(ctx, "CCC")
      ImGui.Button(ctx, "DDD")
      ImGui.EndGroup(ctx)
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "EEE")
      ImGui.EndGroup(ctx)
      if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, "First group hovered")
      else
      end
      local size = {ImGui.GetItemRectSize(ctx)}
      local item_spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing())
      ImGui.PlotHistogram(ctx, "##values", widgets.groups.values, 0, nil, 0, 1, table.unpack(size))
      ImGui.Button(ctx, "ACTION", ((size[1] - item_spacing_x) * 0.5), size[2])
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "REACTION", ((size[1] - item_spacing_x) * 0.5), size[2])
      ImGui.EndGroup(ctx)
      ImGui.SameLine(ctx)
      ImGui.Button(ctx, "LEVERAGE\nBUZZWORD", table.unpack(size))
      ImGui.SameLine(ctx)
      if ImGui.BeginListBox(ctx, "List", table.unpack(size)) then
        ImGui.Selectable(ctx, "Selected", true)
        ImGui.Selectable(ctx, "Not Selected", false)
        ImGui.EndListBox(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Text Baseline Alignment") then
      do
        ImGui.BulletText(ctx, "Text baseline:")
        ImGui.SameLine(ctx)
        demo.HelpMarker("This is testing the vertical alignment that gets applied on text to keep it aligned with widgets. Lines only composed of text or \"small\" widgets use less vertical space than lines with framed widgets.")
        ImGui.Indent(ctx)
        ImGui.Text(ctx, "KO Blahblah")
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Some framed item")
        ImGui.SameLine(ctx)
        demo.HelpMarker("Baseline of button will look misaligned with text..")
        ImGui.AlignTextToFramePadding(ctx)
        ImGui.Text(ctx, "OK Blahblah")
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Some framed item")
        ImGui.SameLine(ctx)
        demo.HelpMarker("We call AlignTextToFramePadding() to vertically align the text baseline by +FramePadding.y")
        ImGui.Button(ctx, "TEST##1")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "TEST")
        ImGui.SameLine(ctx)
        ImGui.SmallButton(ctx, "TEST##2")
        ImGui.AlignTextToFramePadding(ctx)
        ImGui.Text(ctx, "Text aligned to framed item")
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Item##1")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Item")
        ImGui.SameLine(ctx)
        ImGui.SmallButton(ctx, "Item##2")
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Item##3")
        ImGui.Unindent(ctx)
      end
      ImGui.Spacing(ctx)
      do
        ImGui.BulletText(ctx, "Multi-line text:")
        ImGui.Indent(ctx)
        ImGui.Text(ctx, "One\nTwo\nThree")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Hello\nWorld")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Banana")
        ImGui.Text(ctx, "Banana")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Hello\nWorld")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "One\nTwo\nThree")
        ImGui.Button(ctx, "HOP##1")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Banana")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Hello\nWorld")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Banana")
        ImGui.Button(ctx, "HOP##2")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Hello\nWorld")
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "Banana")
        ImGui.Unindent(ctx)
      end
      ImGui.Spacing(ctx)
      do
        ImGui.BulletText(ctx, "Misc items:")
        ImGui.Indent(ctx)
        ImGui.Button(ctx, "80x80", 80, 80)
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "50x50", 50, 50)
        ImGui.SameLine(ctx)
        ImGui.Button(ctx, "Button()")
        ImGui.SameLine(ctx)
        ImGui.SmallButton(ctx, "SmallButton()")
        local spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing())
        ImGui.Button(ctx, "Button##1")
        ImGui.SameLine(ctx, 0, spacing)
        if ImGui.TreeNode(ctx, "Node##1") then
          for i = 0, 5 do
            ImGui.BulletText(ctx, ("Item %d.."):format(i))
          end
          ImGui.TreePop(ctx)
        else
        end
        ImGui.AlignTextToFramePadding(ctx)
        do
          local node_open = ImGui.TreeNode(ctx, "Node##2")
          ImGui.SameLine(ctx, 0, spacing)
          ImGui.Button(ctx, "Button##2")
          if node_open then
            for i = 0, 5 do
              ImGui.BulletText(ctx, ("Item %d.."):format(i))
            end
            ImGui.TreePop(ctx)
          else
          end
        end
        ImGui.Button(ctx, "Button##3")
        ImGui.SameLine(ctx, 0, spacing)
        ImGui.BulletText(ctx, "Bullet text")
        ImGui.AlignTextToFramePadding(ctx)
        ImGui.BulletText(ctx, "Node")
        ImGui.SameLine(ctx, 0, spacing)
        ImGui.Button(ctx, "Button##4")
        ImGui.Unindent(ctx)
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Scrolling") then
      if not layout.scrolling then
        layout.scrolling = {enable_track = true, lines = 7, scroll_to_off_px = 0.0, scroll_to_pos_px = 200.0, track_item = 50, enable_extra_decorations = false, show_horizontal_contents_size_demo_window = false}
      else
      end
      demo.HelpMarker("Use SetScrollHereY() or SetScrollFromPosY() to scroll to a given vertical position.")
      do
        local rv_607_, arg1_606_ = nil, nil
        do
          local arg1_606_0 = layout.scrolling.enable_extra_decorations
          local _24 = arg1_606_0
          rv_607_, arg1_606_ = ImGui.Checkbox(ctx, "Decoration", _24)
        end
        layout.scrolling.enable_extra_decorations = arg1_606_
      end
      do
        local rv_609_, arg1_608_ = nil, nil
        do
          local arg1_608_0 = layout.scrolling.enable_track
          local _24 = arg1_608_0
          rv_609_, arg1_608_ = ImGui.Checkbox(ctx, "Track", _24)
        end
        layout.scrolling.enable_track = arg1_608_
      end
      ImGui.PushItemWidth(ctx, 100)
      ImGui.SameLine(ctx, 140)
      local _612_
      do
        local rv_611_, arg1_610_ = nil, nil
        do
          local arg1_610_0 = layout.scrolling.track_item
          local _24 = arg1_610_0
          rv_611_, arg1_610_ = ImGui.DragInt(ctx, "##item", _24, 0.25, 0, 99, "Item = %d")
        end
        layout.scrolling.track_item = arg1_610_
        _612_ = rv_611_
      end
      if _612_ then
        layout.scrolling.enable_track = true
      else
      end
      do
        local scroll_to_off = ImGui.Button(ctx, "Scroll Offset")
        local _ = ImGui.SameLine(ctx, 140)
        local rv0
        do
          local rv_615_, arg1_614_ = nil, nil
          do
            local arg1_614_0 = layout.scrolling.scroll_to_off_px
            local _24 = arg1_614_0
            rv_615_, arg1_614_ = ImGui.DragDouble(ctx, "##off", _24, 1, 0, FLT_MAX, "+%.0f px")
          end
          layout.scrolling.scroll_to_off_px = arg1_614_
          rv0 = rv_615_, arg1_614_
        end
        local scroll_to_off0
        if rv0 then
          scroll_to_off0 = true
        else
          scroll_to_off0 = scroll_to_off
        end
        local scroll_to_pos = ImGui.Button(ctx, "Scroll To Pos")
        local _0 = ImGui.SameLine(ctx, 140)
        local rv1
        do
          local rv_618_, arg1_617_ = nil, nil
          do
            local arg1_617_0 = layout.scrolling.scroll_to_pos_px
            local _24 = arg1_617_0
            rv_618_, arg1_617_ = ImGui.DragDouble(ctx, "##pos", _24, 1, ( - 10), FLT_MAX, "X/Y = %.0f px")
          end
          layout.scrolling.scroll_to_pos_px = arg1_617_
          rv1 = rv_618_, arg1_617_
        end
        local scroll_to_pos0
        if rv1 then
          scroll_to_pos0 = true
        else
          scroll_to_pos0 = scroll_to_pos
        end
        ImGui.PopItemWidth(ctx)
        if (scroll_to_off0 or scroll_to_pos0) then
          layout.scrolling.enable_track = false
        else
        end
      end
      do
        local names = {"Top", "25%", "Center", "75%", "Bottom"}
        local item_spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing())
        local child_w = math.max(1.0, ((ImGui.GetContentRegionAvail(ctx) - (4 * item_spacing_x)) / #names))
        local child_flags
        if layout.scrolling.enable_extra_decorations then
          child_flags = ImGui.WindowFlags_MenuBar()
        else
          child_flags = ImGui.WindowFlags_None()
        end
        ImGui.PushID(ctx, "##VerticalScrolling")
        for i, name in ipairs(names) do
          if (i > 1) then
            ImGui.SameLine(ctx)
          else
          end
          ImGui.BeginGroup(ctx)
          ImGui.Text(ctx, name)
          if ImGui.BeginChild(ctx, i, child_w, 200.0, true, child_flags) then
            if ImGui.BeginMenuBar(ctx) then
              ImGui.Text(ctx, "abc")
              ImGui.EndMenuBar(ctx)
            else
            end
            if __fnl_global__scroll_2dto_2doff then
              ImGui.SetScrollY(ctx, layout.scrolling.scroll_to_off_px)
            else
            end
            if __fnl_global__scroll_2dto_2dpos then
              ImGui.SetScrollFromPosY(ctx, (select(2, ImGui.GetCursorStartPos(ctx)) + layout.scrolling.scroll_to_pos_px), ((i - 1) * 0.25))
            else
            end
            for item = 0, 99 do
              if (layout.scrolling.enable_track and (item == layout.scrolling.track_item)) then
                ImGui.TextColored(ctx, 4294902015, ("Item %d"):format(item))
                ImGui.SetScrollHereY(ctx, ((i - 1) * 0.25))
              else
                ImGui.Text(ctx, ("Item %d"):format(item))
              end
            end
            local scroll_y = ImGui.GetScrollY(ctx)
            local scroll_max_y = ImGui.GetScrollMaxY(ctx)
            ImGui.EndChild(ctx)
            ImGui.Text(ctx, ("%.0f/%.0f"):format(scroll_y, scroll_max_y))
          else
            ImGui.Text(ctx, "N/A")
          end
          ImGui.EndGroup(ctx)
        end
        ImGui.PopID(ctx)
        ImGui.Spacing(ctx)
        demo.HelpMarker("Use SetScrollHereX() or SetScrollFromPosX() to scroll to a given horizontal position.\n\n\n          Because the clipping rectangle of most window hides half worth of WindowPadding on the \n          left/right, using SetScrollFromPosX(+1) will usually result in clipped text whereas the \n          equivalent SetScrollFromPosY(+1) wouldn't.")
        ImGui.PushID(ctx, "##HorizontalScrolling")
        local scrollbar_size = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ScrollbarSize())
        local window_padding_y = select(2, ImGui.GetStyleVar(ctx, ImGui.StyleVar_WindowPadding()))
        local child_height = (ImGui.GetTextLineHeight(ctx) + scrollbar_size + (window_padding_y * 2))
        local child_flags0
        local function _628_()
          if layout.scrolling.enable_extra_decorations then
            return ImGui.WindowFlags_AlwaysVerticalScrollbar()
          else
            return 0
          end
        end
        child_flags0 = (ImGui.WindowFlags_HorizontalScrollbar() | _628_())
        for i, name in ipairs(names) do
          local scroll_x, scroll_max_x = 0.0, 0.0
          if ImGui.BeginChild(ctx, i, -100, child_height, true, child_flags0) then
            if __fnl_global__scroll_2dto_2doff then
              ImGui.SetScrollX(ctx, layout.scrolling.scroll_to_off_px)
            else
            end
            if __fnl_global__scroll_2dto_2dpos then
              ImGui.SetScrollFromPosX(ctx, (ImGui.GetCursorStartPos(ctx) + layout.scrolling.scroll_to_pos_px), ((i - 1) * 0.25))
            else
            end
            for item = 0, 99 do
              if (item > 0) then
                ImGui.SameLine(ctx)
              else
              end
              if (layout.scrolling.enable_track and (item == layout.scrolling.track_item)) then
                ImGui.TextColored(ctx, 4294902015, ("Item %d"):format(item))
                ImGui.SetScrollHereX(ctx, ((i - 1) * 0.25))
              else
                ImGui.Text(ctx, ("Item %d"):format(item))
              end
            end
            scroll_x = ImGui.GetScrollX(ctx)
            scroll_max_x = ImGui.GetScrollMaxX(ctx)
            ImGui.EndChild(ctx)
          else
          end
          ImGui.SameLine(ctx)
          ImGui.Text(ctx, ("%s\n%.0f/%.0f"):format(name, scroll_x, scroll_max_x))
          ImGui.Spacing(ctx)
        end
      end
      ImGui.PopID(ctx)
      demo.HelpMarker("Horizontal scrolling for a window is enabled via the ImGuiWindowFlags_HorizontalScrollbar flag.\n\n    You may want to also explicitly specify content width by using SetNextWindowContentWidth() before Begin().")
      do
        local rv_635_, arg1_634_ = nil, nil
        do
          local arg1_634_0 = layout.scrolling.lines
          local _24 = arg1_634_0
          rv_635_, arg1_634_ = ImGui.SliderInt(ctx, "Lines", _24, 1, 15)
        end
        layout.scrolling.lines = arg1_634_
      end
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding(), 3)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 2, 1)
      local scrolling_child_width = ((ImGui.GetFrameHeightWithSpacing(ctx) * 7) + 30)
      local scroll_x, scroll_max_x = 0, 0
      if ImGui.BeginChild(ctx, "scrolling", 0, scrolling_child_width, true, ImGui.WindowFlags_HorizontalScrollbar()) then
        for line = 0, (layout.scrolling.lines - 1) do
          local num_buttons = (10 + ((((line & 1) ~= 0) and (line * 9)) or (line * 3)))
          for n = 0, (num_buttons - 1) do
            if (n > 0) then
              ImGui.SameLine(ctx)
            else
            end
            ImGui.PushID(ctx, (n + (line * 1000)))
            local label
            if ((n % 15) == 0) then
              label = "FizzBuzz"
            elseif ((n % 3) == 0) then
              label = "Fizz"
            elseif ((n % 5) == 0) then
              label = "Buzz"
            else
              label = tostring(n)
            end
            local hue = (n * 0.05)
            ImGui.PushStyleColor(ctx, ImGui.Col_Button(), demo.HSV(hue, 0.6, 0.6))
            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered(), demo.HSV(hue, 0.7, 0.7))
            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive(), demo.HSV(hue, 0.8, 0.8))
            ImGui.Button(ctx, label, (40.0 + (math.sin((line + n)) * 20.0)), 0.0)
            ImGui.PopStyleColor(ctx, 3)
            ImGui.PopID(ctx)
          end
        end
        scroll_x = ImGui.GetScrollX(ctx)
        scroll_max_x = ImGui.GetScrollMaxX(ctx)
        ImGui.EndChild(ctx)
      else
      end
      ImGui.PopStyleVar(ctx, 2)
      local scroll_x_delta = 0
      ImGui.SmallButton(ctx, "<<")
      if ImGui.IsItemActive(ctx) then
        scroll_x_delta = ((0 - ImGui.GetDeltaTime(ctx)) * 1000.0)
      else
      end
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, "Scroll from code")
      ImGui.SameLine(ctx)
      ImGui.SmallButton(ctx, ">>")
      if ImGui.IsItemActive(ctx) then
        scroll_x_delta = (ImGui.GetDeltaTime(ctx) * 1000.0)
      else
      end
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, ("%.0f/%.0f"):format(scroll_x, scroll_max_x))
      if (scroll_x_delta ~= 0.0) then
        if ImGui.BeginChild(ctx, "scrolling") then
          ImGui.SetScrollX(ctx, (ImGui.GetScrollX(ctx) + scroll_x_delta))
          ImGui.EndChild(ctx)
        else
        end
      else
      end
      ImGui.Spacing(ctx)
      do
        local rv_644_, arg1_643_ = nil, nil
        do
          local arg1_643_0 = layout.scrolling.show_horizontal_contents_size_demo_window
          local _24 = arg1_643_0
          rv_644_, arg1_643_ = ImGui.Checkbox(ctx, "Show Horizontal contents size demo window", _24)
        end
        layout.scrolling.show_horizontal_contents_size_demo_window = arg1_643_
      end
      if layout.scrolling.show_horizontal_contents_size_demo_window then
        if not layout.horizontal_window then
          layout.horizontal_window = {contents_size_x = 300.0, show_button = true, show_columns = true, show_h_scrollbar = true, show_tab_bar = true, show_tree_nodes = true, show_child = false, explicit_content_size = false, show_text_wrapped = false}
        else
        end
        if layout.horizontal_window.explicit_content_size then
          ImGui.SetNextWindowContentSize(ctx, layout.horizontal_window.contents_size_x, 0)
        else
        end
        local _649_
        do
          local rv_648_, arg1_647_ = nil, nil
          do
            local arg1_647_0 = layout.scrolling.show_horizontal_contents_size_demo_window
            local function _650_()
              if layout.horizontal_window.show_h_scrollbar then
                return ImGui.WindowFlags_HorizontalScrollbar()
              else
                return ImGui.WindowFlags_None()
              end
            end
            rv_648_, arg1_647_ = ImGui.Begin(ctx, "Horizontal contents size demo window", true, _650_())
          end
          layout.scrolling.show_horizontal_contents_size_demo_window = arg1_647_
          _649_ = rv_648_
        end
        if _649_ then
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), 2, 0)
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 2, 0)
          demo.HelpMarker("Test of different widgets react and impact the work rectangle growing when horizontal scrolling is enabled.\n\nUse 'Metrics->Tools->Show windows rectangles' to visualize rectangles.")
          do
            local rv_652_, arg1_651_ = nil, nil
            do
              local arg1_651_0 = layout.horizontal_window.show_h_scrollbar
              local _24 = arg1_651_0
              rv_652_, arg1_651_ = ImGui.Checkbox(ctx, "H-scrollbar", _24)
            end
            layout.horizontal_window.show_h_scrollbar = arg1_651_
          end
          do
            local rv_654_, arg1_653_ = nil, nil
            do
              local arg1_653_0 = layout.horizontal_window.show_button
              local _24 = arg1_653_0
              rv_654_, arg1_653_ = ImGui.Checkbox(ctx, "Button", _24)
            end
            layout.horizontal_window.show_button = arg1_653_
          end
          do
            local rv_656_, arg1_655_ = nil, nil
            do
              local arg1_655_0 = layout.horizontal_window.show_tree_nodes
              local _24 = arg1_655_0
              rv_656_, arg1_655_ = ImGui.Checkbox(ctx, "Tree nodes", _24)
            end
            layout.horizontal_window.show_tree_nodes = arg1_655_
          end
          do
            local rv_658_, arg1_657_ = nil, nil
            do
              local arg1_657_0 = layout.horizontal_window.show_text_wrapped
              local _24 = arg1_657_0
              rv_658_, arg1_657_ = ImGui.Checkbox(ctx, "Text wrapped", _24)
            end
            layout.horizontal_window.show_text_wrapped = arg1_657_
          end
          do
            local rv_660_, arg1_659_ = nil, nil
            do
              local arg1_659_0 = layout.horizontal_window.show_columns
              local _24 = arg1_659_0
              rv_660_, arg1_659_ = ImGui.Checkbox(ctx, "Columns", _24)
            end
            layout.horizontal_window.show_columns = arg1_659_
          end
          do
            local rv_662_, arg1_661_ = nil, nil
            do
              local arg1_661_0 = layout.horizontal_window.show_tab_bar
              local _24 = arg1_661_0
              rv_662_, arg1_661_ = ImGui.Checkbox(ctx, "Tab bar", _24)
            end
            layout.horizontal_window.show_tab_bar = arg1_661_
          end
          do
            local rv_664_, arg1_663_ = nil, nil
            do
              local arg1_663_0 = layout.horizontal_window.show_child
              local _24 = arg1_663_0
              rv_664_, arg1_663_ = ImGui.Checkbox(ctx, "Child", _24)
            end
            layout.horizontal_window.show_child = arg1_663_
          end
          do
            local rv_666_, arg1_665_ = nil, nil
            do
              local arg1_665_0 = layout.horizontal_window.explicit_content_size
              local _24 = arg1_665_0
              rv_666_, arg1_665_ = ImGui.Checkbox(ctx, "Explicit content size", _24)
            end
            layout.horizontal_window.explicit_content_size = arg1_665_
          end
          ImGui.Text(ctx, ("Scroll %.1f/%.1f %.1f/%.1f"):format(ImGui.GetScrollX(ctx), ImGui.GetScrollMaxX(ctx), ImGui.GetScrollY(ctx), ImGui.GetScrollMaxY(ctx)))
          if layout.horizontal_window.explicit_content_size then
            ImGui.SameLine(ctx)
            ImGui.SetNextItemWidth(ctx, 100)
            do
              local rv_668_, arg1_667_ = nil, nil
              do
                local arg1_667_0 = layout.horizontal_window.contents_size_x
                local _24 = arg1_667_0
                rv_668_, arg1_667_ = ImGui.DragDouble(ctx, "##csx", _24)
              end
              layout.horizontal_window.contents_size_x = arg1_667_
            end
            local x, y = ImGui.GetCursorScreenPos(ctx)
            local draw_list = ImGui.GetWindowDrawList(ctx)
            ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + 10), (y + 10), 4294967295)
            ImGui.DrawList_AddRectFilled(draw_list, ((x + layout.horizontal_window.contents_size_x) - 10), y, (x + layout.horizontal_window.contents_size_x), (y + 10), 4294967295)
            ImGui.Dummy(ctx, 0, 10)
          else
          end
          ImGui.PopStyleVar(ctx, 2)
          ImGui.Separator(ctx)
          if layout.horizontal_window.show_button then
            ImGui.Button(ctx, "this is a 300-wide button", 300, 0)
          else
          end
          if layout.horizontal_window.show_tree_nodes then
            if ImGui.TreeNode(ctx, "this is a tree node") then
              if ImGui.TreeNode(ctx, "another one of those tree node...") then
                ImGui.Text(ctx, "Some tree contents")
                ImGui.TreePop(ctx)
              else
              end
              ImGui.TreePop(ctx)
            else
            end
            ImGui.CollapsingHeader(ctx, "CollapsingHeader", true)
          else
          end
          if layout.horizontal_window.show_text_wrapped then
            ImGui.TextWrapped(ctx, "This text should automatically wrap on the edge of the work rectangle.")
          else
          end
          if layout.horizontal_window.show_columns then
            ImGui.Text(ctx, "Tables:")
            if ImGui.BeginTable(ctx, "table", 4, ImGui.TableFlags_Borders()) then
              for n = 0, 3 do
                ImGui.TableNextColumn(ctx)
                ImGui.Text(ctx, ("Width %.2f"):format(ImGui.GetContentRegionAvail(ctx)))
              end
              ImGui.EndTable(ctx)
            else
            end
          else
          end
          if (layout.horizontal_window.show_tab_bar and ImGui.BeginTabBar(ctx, "Hello")) then
            if ImGui.BeginTabItem(ctx, "OneOneOne") then
              ImGui.EndTabItem(ctx)
            else
            end
            if ImGui.BeginTabItem(ctx, "TwoTwoTwo") then
              ImGui.EndTabItem(ctx)
            else
            end
            if ImGui.BeginTabItem(ctx, "ThreeThreeThree") then
              ImGui.EndTabItem(ctx)
            else
            end
            if ImGui.BeginTabItem(ctx, "FourFourFour") then
              ImGui.EndTabItem(ctx)
            else
            end
            ImGui.EndTabBar(ctx)
          else
          end
          if (layout.horizontal_window.show_child and ImGui.BeginChild(ctx, "child", 0, 0, true)) then
            ImGui.EndChild(ctx)
          else
          end
          ImGui.End(ctx)
        else
        end
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Clipping") then
      if not layout.clipping then
        layout.clipping = {offset = {30.0, 30.0}, size = {100.0, 100.0}}
      else
      end
      do
        local _, s1, s2 = ImGui.DragDouble2(ctx, "size", layout.clipping.size[1], layout.clipping.size[2], 0.5, 1, 200, "%.0f")
        do end (layout.clipping.size)[1] = s1
        layout.clipping.size[2] = s2
      end
      ImGui.TextWrapped(ctx, "(Click and drag to scroll)")
      demo.HelpMarker("(Left) Using ImGui_PushClipRect():\n\n        Will alter ImGui hit-testing logic + DrawList rendering.\n\n        (use this if you want your clipping rectangle to affect interactions)\n\n\n        (Center) Using ImGui_DrawList_PushClipRect():\n\n        Will alter DrawList rendering only.\n\n        (use this as a shortcut if you are only using DrawList calls)\n\n\n        (Right) Using ImGui_DrawList_AddText() with a fine ClipRect:\n\n        Will alter only this specific ImGui_DrawList_AddText() rendering.\n\n        This is often used internally to avoid altering the clipping rectangle and minimize draw calls.")
      for n = 0, 2 do
        if (n > 0) then
          ImGui.SameLine(ctx)
        else
        end
        ImGui.PushID(ctx, n)
        ImGui.InvisibleButton(ctx, "##canvas", table.unpack(layout.clipping.size))
        if (ImGui.IsItemActive(ctx) and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left())) then
          local mouse_delta = {ImGui.GetMouseDelta(ctx)}
          layout.clipping.offset[1] = (layout.clipping.offset[1] + mouse_delta[1])
          do end (layout.clipping.offset)[2] = (layout.clipping.offset[2] + mouse_delta[2])
        else
        end
        ImGui.PopID(ctx)
        if ImGui.IsItemVisible(ctx) then
          local p0_x, p0_y = ImGui.GetItemRectMin(ctx)
          local p1_x, p1_y = ImGui.GetItemRectMax(ctx)
          local text_str = "Line 1 hello\nLine 2 clip me!"
          local text_pos = {(p0_x + layout.clipping.offset[1]), (p0_y + layout.clipping.offset[2])}
          local draw_list = ImGui.GetWindowDrawList(ctx)
          if (n == 0) then
            ImGui.PushClipRect(ctx, p0_x, p0_y, p1_x, p1_y, true)
            ImGui.DrawList_AddRectFilled(draw_list, p0_x, p0_y, p1_x, p1_y, 1515878655)
            ImGui.DrawList_AddText(draw_list, text_pos[1], text_pos[2], 4294967295, text_str)
            ImGui.PopClipRect(ctx)
          elseif (n == 1) then
            ImGui.DrawList_PushClipRect(draw_list, p0_x, p0_y, p1_x, p1_y, true)
            ImGui.DrawList_AddRectFilled(draw_list, p0_x, p0_y, p1_x, p1_y, 1515878655)
            ImGui.DrawList_AddText(draw_list, text_pos[1], text_pos[2], 4294967295, text_str)
            ImGui.DrawList_PopClipRect(draw_list)
          elseif (n == 2) then
            local clip_rect = {p0_x, p0_y, p1_x, p1_y}
            ImGui.DrawList_AddRectFilled(draw_list, p0_x, p0_y, p1_x, p1_y, 1515878655)
            ImGui.DrawList_AddTextEx(draw_list, ImGui.GetFont(ctx), ImGui.GetFontSize(ctx), text_pos[1], text_pos[2], 4294967295, text_str, 0, table.unpack(clip_rect))
          else
          end
        else
        end
      end
      return ImGui.TreePop(ctx)
    else
      return nil
    end
  else
    return nil
  end
end
demo.ShowDemoWindowPopups = function()
  if ImGui.CollapsingHeader(ctx, "Popups & Modal windows") then
    if ImGui.TreeNode(ctx, "Popups") then
      if not popups.popups then
        popups.popups = {selected_fish = -1, toggles = {true, false, false, false, false}}
      else
      end
      ImGui.TextWrapped(ctx, "When a popup is active, it inhibits interacting with windows that are behind the popup. Clicking outside the popup closes it.")
      local names = {"Bream", "Haddock", "Mackerel", "Pollock", "Tilefish"}
      if ImGui.Button(ctx, "Select..") then
        ImGui.OpenPopup(ctx, "my_select_popup")
      else
      end
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, (names[popups.popups.selected_fish] or "<None>"))
      if ImGui.BeginPopup(ctx, "my_select_popup") then
        ImGui.SeparatorText(ctx, "Aquarium")
        for i, fish in ipairs(names) do
          if ImGui.Selectable(ctx, fish) then
            popups.popups.selected_fish = i
          else
          end
        end
        ImGui.EndPopup(ctx)
      else
      end
      if ImGui.Button(ctx, "Toggle..") then
        ImGui.OpenPopup(ctx, "my_toggle_popup")
      else
      end
      if ImGui.BeginPopup(ctx, "my_toggle_popup") then
        for i, fish in ipairs(names) do
          local _, ti = ImGui.MenuItem(ctx, fish, "", popups.popups.toggles[i])
          do end (popups.popups.toggles)[i] = ti
        end
        if ImGui.BeginMenu(ctx, "Sub-menu") then
          ImGui.MenuItem(ctx, "Click me")
          ImGui.EndMenu(ctx)
        else
        end
        ImGui.Separator(ctx)
        ImGui.Text(ctx, "Tooltip here")
        if ImGui.IsItemHovered(ctx) then
          ImGui.SetTooltip(ctx, "I am a tooltip over a popup")
        else
        end
        if ImGui.Button(ctx, "Stacked Popup") then
          ImGui.OpenPopup(ctx, "another popup")
        else
        end
        if ImGui.BeginPopup(ctx, "another popup") then
          for i, fish in ipairs(names) do
            local _, ti = ImGui.MenuItem(ctx, fish, "", popups.popups.toggles[i])
            do end (popups.popups.toggles)[i] = ti
          end
          if ImGui.BeginMenu(ctx, "Sub-menu") then
            ImGui.MenuItem(ctx, "Click me")
            if ImGui.Button(ctx, "Stacked Popup") then
              ImGui.OpenPopup(ctx, "another popup")
            else
            end
            if ImGui.BeginPopup(ctx, "another popup") then
              ImGui.Text(ctx, "I am the last one here.")
              ImGui.EndPopup(ctx)
            else
            end
            ImGui.EndMenu(ctx)
          else
          end
          ImGui.EndPopup(ctx)
        else
        end
        ImGui.EndPopup(ctx)
      else
      end
      if ImGui.Button(ctx, "With a menu..") then
        ImGui.OpenPopup(ctx, "my_file_popup")
      else
      end
      if ImGui.BeginPopup(ctx, "my_file_popup", ImGui.WindowFlags_MenuBar()) then
        if ImGui.BeginMenuBar(ctx) then
          if ImGui.BeginMenu(ctx, "File") then
            demo.ShowExampleMenuFile()
            ImGui.EndMenu(ctx)
          else
          end
          if ImGui.BeginMenu(ctx, "Edit") then
            ImGui.MenuItem(ctx, "Dummy")
            ImGui.EndMenu(ctx)
          else
          end
          ImGui.EndMenuBar(ctx)
        else
        end
        ImGui.Text(ctx, "Hello from popup!")
        ImGui.Button(ctx, "This is a dummy button..")
        ImGui.EndPopup(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Context menus") then
      if not popups.context then
        popups.context = {name = "Label1", selected = 0, value = 0.5}
      else
      end
      demo.HelpMarker("\"Context\" functions are simple helpers to associate a Popup to a given Item or Window identifier.")
      do
        local names = {"Label1", "Label2", "Label3", "Label4", "Label5"}
        for n, name in ipairs(names) do
          if ImGui.Selectable(ctx, name, (popups.context.selected == n)) then
            popups.context.selected = n
          else
          end
          if ImGui.BeginPopupContextItem(ctx) then
            popups.context.selected = n
            ImGui.Text(ctx, ("This a popup for \"%s\"!"):format(name))
            if ImGui.Button(ctx, "Close") then
              ImGui.CloseCurrentPopup(ctx)
            else
            end
            ImGui.EndPopup(ctx)
          else
          end
          if ImGui.IsItemHovered(ctx) then
            ImGui.SetTooltip(ctx, "Right-click to open popup")
          else
          end
        end
      end
      do
        demo.HelpMarker("Text() elements don't have stable identifiers so we need to provide one.")
        ImGui.Text(ctx, ("Value = %.6f <-- (1) right-click this text"):format(popups.context.value))
        if ImGui.BeginPopupContextItem(ctx, "my popup") then
          if ImGui.Selectable(ctx, "Set to zero") then
            popups.context.value = 0
          else
          end
          if ImGui.Selectable(ctx, "Set to PI") then
            popups.context.value = 3.141592
          else
          end
          ImGui.SetNextItemWidth(ctx, ( - FLT_MIN))
          do
            local rv_720_, arg1_719_ = nil, nil
            do
              local arg1_719_0 = popups.context.value
              local _24 = arg1_719_0
              rv_720_, arg1_719_ = ImGui.DragDouble(ctx, "##Value", _24, 0.1, 0.0, 0.0)
            end
            popups.context.value = arg1_719_
          end
          ImGui.EndPopup(ctx)
        else
        end
        ImGui.Text(ctx, "(2) Or right-click this text")
        ImGui.OpenPopupOnItemClick(ctx, "my popup", ImGui.PopupFlags_MouseButtonRight())
        if ImGui.Button(ctx, "(3) Or click this button") then
          ImGui.OpenPopup(ctx, "my popup")
        else
        end
      end
      do
        demo.HelpMarker("Showcase using a popup ID linked to item ID, with the item having a changing label + stable ID using the ### operator.")
        ImGui.Button(ctx, ("Button: %s###Button"):format(popups.context.name))
        if ImGui.BeginPopupContextItem(ctx) then
          ImGui.Text(ctx, "Edit name:")
          do
            local rv_724_, arg1_723_ = nil, nil
            do
              local arg1_723_0 = popups.context.name
              local _24 = arg1_723_0
              rv_724_, arg1_723_ = ImGui.InputText(ctx, "##edit", _24)
            end
            popups.context.name = arg1_723_
          end
          if ImGui.Button(ctx, "Close") then
            ImGui.CloseCurrentPopup(ctx)
          else
          end
          ImGui.EndPopup(ctx)
        else
        end
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, "(<-- right-click here)")
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Modals") then
      if not popups.modal then
        popups.modal = {color = 1723007104, item = 1, dont_ask_me_next_time = false}
      else
      end
      ImGui.TextWrapped(ctx, "Modal windows are like popups but the user cannot close them by clicking outside.")
      if ImGui.Button(ctx, "Delete..") then
        ImGui.OpenPopup(ctx, "Delete?")
      else
      end
      do
        local center = {ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))}
        ImGui.SetNextWindowPos(ctx, center[1], center[2], ImGui.Cond_Appearing(), 0.5, 0.5)
      end
      if ImGui.BeginPopupModal(ctx, "Delete?", nil, ImGui.WindowFlags_AlwaysAutoResize()) then
        ImGui.Text(ctx, "All those beautiful files will be deleted.\nThis operation cannot be undone!")
        ImGui.Separator(ctx)
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 0, 0)
        do
          local rv_731_, arg1_730_ = nil, nil
          do
            local arg1_730_0 = popups.modal.dont_ask_me_next_time
            local _24 = arg1_730_0
            rv_731_, arg1_730_ = ImGui.Checkbox(ctx, "Don't ask me next time", _24)
          end
          popups.modal.dont_ask_me_next_time = arg1_730_
        end
        ImGui.PopStyleVar(ctx)
        if ImGui.Button(ctx, "OK", 120, 0) then
          ImGui.CloseCurrentPopup(ctx)
        else
        end
        ImGui.SetItemDefaultFocus(ctx)
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Cancel", 120, 0) then
          ImGui.CloseCurrentPopup(ctx)
        else
        end
        ImGui.EndPopup(ctx)
      else
      end
      if ImGui.Button(ctx, "Stacked modals..") then
        ImGui.OpenPopup(ctx, "Stacked 1")
      else
      end
      if ImGui.BeginPopupModal(ctx, "Stacked 1", nil, ImGui.WindowFlags_MenuBar()) then
        if ImGui.BeginMenuBar(ctx) then
          if ImGui.BeginMenu(ctx, "File") then
            if ImGui.MenuItem(ctx, "Some menu item") then
            else
            end
            ImGui.EndMenu(ctx)
          else
          end
          ImGui.EndMenuBar(ctx)
        else
        end
        ImGui.Text(ctx, "Hello from Stacked The First\nUsing style.Colors[ImGuiCol_ModalWindowDimBg] behind it.")
        do
          local rv_740_, arg1_739_ = nil, nil
          do
            local arg1_739_0 = popups.modal.item
            local _24 = arg1_739_0
            rv_740_, arg1_739_ = ImGui.Combo(ctx, "Combo", _24, "aaaa\0bbbb\0cccc\0dddd\0eeee\0")
          end
          popups.modal.item = arg1_739_
        end
        do
          local rv_742_, arg1_741_ = nil, nil
          do
            local arg1_741_0 = popups.modal.color
            local _24 = arg1_741_0
            rv_742_, arg1_741_ = ImGui.ColorEdit4(ctx, "color", _24)
          end
          popups.modal.color = arg1_741_
        end
        if ImGui.Button(ctx, "Add another modal..") then
          ImGui.OpenPopup(ctx, "Stacked 2")
        else
        end
        local unused_open = true
        if ImGui.BeginPopupModal(ctx, "Stacked 2", unused_open) then
          ImGui.Text(ctx, "Hello from Stacked The Second!")
          if ImGui.Button(ctx, "Close") then
            ImGui.CloseCurrentPopup(ctx)
          else
          end
          ImGui.EndPopup(ctx)
        else
        end
        if ImGui.Button(ctx, "Close") then
          ImGui.CloseCurrentPopup(ctx)
        else
        end
        ImGui.EndPopup(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Menus inside a regular window") then
      ImGui.TextWrapped(ctx, "Below we are testing adding menu items to a regular window. It's rather unusual but should work!")
      ImGui.Separator(ctx)
      ImGui.MenuItem(ctx, "Menu item", "CTRL+M")
      if ImGui.BeginMenu(ctx, "Menu inside a regular window") then
        demo.ShowExampleMenuFile()
        ImGui.EndMenu(ctx)
      else
      end
      ImGui.Separator(ctx)
      return ImGui.TreePop(ctx)
    else
      return nil
    end
  else
    return nil
  end
end
local My_item_column_iD_ID = 4
local My_item_column_iD_Name = 5
local My_item_column_iD_Quantity = 6
local My_item_column_iD_Description = 7
demo.CompareTableItems = function(a, b)
  local res = nil
  for next_id = 0, math.huge do
    if not (nil == res) then break end
    local ok, col_user_id, col_idx, sort_order, sort_direction = ImGui.TableGetColumnSortSpecs(ctx, next_id)
    if not ok then
      res = (a.id < b.id)
    else
      local key
      local function _752_()
        if (nil ~= col_user_id) then
          local My_item_column_iD_ID0 = col_user_id
          return "id"
        elseif (nil ~= col_user_id) then
          local My_item_column_iD_Name0 = col_user_id
          return "name"
        elseif (nil ~= col_user_id) then
          local My_item_column_iD_Quantity0 = col_user_id
          return "quantity"
        elseif (nil ~= col_user_id) then
          local My_item_column_iD_Description0 = col_user_id
          return "name"
        else
          return nil
        end
      end
      key = (_752_() or error("unknown user column ID"))
      local is_ascending = (sort_direction == ImGui.SortDirection_Ascending())
      if (a[key] < b[key]) then
        res = is_ascending
      elseif (a[key] > b[key]) then
        res = not is_ascending
      else
        res = nil
      end
    end
  end
  return res
end
demo.PushStyleCompact = function()
  local frame_padding_x, frame_padding_y = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding())
  local item_spacing_x, item_spacing_y = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing())
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), frame_padding_x, math.floor((frame_padding_y * 0.6)))
  return ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), item_spacing_x, math.floor((item_spacing_y * 0.6)))
end
demo.PopStyleCompact = function()
  return ImGui.PopStyleVar(ctx, 2)
end
demo.EditTableSizingFlags = function(flags)
  local flags0 = flags
  local policies = {{name = "Default", tooltip = "Use default sizing policy:\n- ImGuiTableFlags_SizingFixedFit if ScrollX is on or if host window has ImGuiWindowFlags_AlwaysAutoResize.\n- ImGuiTableFlags_SizingStretchSame otherwise.", value = ImGui.TableFlags_None()}, {name = "ImGuiTableFlags_SizingFixedFit", tooltip = "Columns default to _WidthFixed (if resizable) or _WidthAuto (if not resizable), matching contents width.", value = ImGui.TableFlags_SizingFixedFit()}, {name = "ImGuiTableFlags_SizingFixedSame", tooltip = "Columns are all the same width, matching the maximum contents width.\nImplicitly disable ImGuiTableFlags_Resizable and enable ImGuiTableFlags_NoKeepColumnsVisible.", value = ImGui.TableFlags_SizingFixedSame()}, {name = "ImGuiTableFlags_SizingStretchProp", tooltip = "Columns default to _WidthStretch with weights proportional to their widths.", value = ImGui.TableFlags_SizingStretchProp()}, {name = "ImGuiTableFlags_SizingStretchSame", tooltip = "Columns default to _WidthStretch with same weights.", value = ImGui.TableFlags_SizingStretchSame()}}
  local sizing_mask = (ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_SizingFixedSame() | ImGui.TableFlags_SizingStretchProp() | ImGui.TableFlags_SizingStretchSame())
  local idx
  do
    local acc = 1
    for idx0 = 2, #policies do
      if (policies[acc].value == (flags0 & sizing_mask)) then break end
      acc = idx0
    end
    idx = acc
  end
  local preview_text = ""
  if (idx <= #policies) then
    preview_text = policies[idx].name
    if (idx > 1) then
      preview_text = preview_text:sub((("ImGuiTableFlags"):len() + 1))
    else
    end
  else
  end
  if ImGui.BeginCombo(ctx, "Sizing Policy", preview_text) then
    for n, policy in ipairs(policies) do
      if ImGui.Selectable(ctx, policy.name, (idx == n)) then
        flags0 = ((flags0 & ~sizing_mask) | policy.value)
      else
      end
    end
    ImGui.EndCombo(ctx)
  else
  end
  ImGui.SameLine(ctx)
  ImGui.TextDisabled(ctx, "(?)")
  if ImGui.IsItemHovered(ctx) then
    ImGui.BeginTooltip(ctx)
    ImGui.PushTextWrapPos(ctx, (ImGui.GetFontSize(ctx) * 50))
    for m, policy in ipairs(policies) do
      ImGui.Separator(ctx)
      ImGui.Text(ctx, ("%s:"):format(policy.name))
      ImGui.Separator(ctx)
      do
        local indent_spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_IndentSpacing())
        ImGui.SetCursorPosX(ctx, (ImGui.GetCursorPosX(ctx) + (indent_spacing * 0.5)))
      end
      ImGui.Text(ctx, policy.tooltip)
    end
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  else
  end
  return flags0
end
demo.EditTableColumnsFlags = function(flags)
  local flags0 = flags
  local width_mask = (ImGui.TableColumnFlags_WidthStretch() | ImGui.TableColumnFlags_WidthFixed())
  do
    local rv_762_, arg1_761_ = nil, nil
    do
      local arg1_761_0 = flags0
      local _24 = arg1_761_0
      rv_762_, arg1_761_ = ImGui.CheckboxFlags(ctx, "_Disabled", _24, ImGui.TableColumnFlags_Disabled())
    end
    flags0 = arg1_761_
  end
  ImGui.SameLine(ctx)
  demo.HelpMarker("Master disable flag (also hide from context menu)")
  do
    local rv_764_, arg1_763_ = nil, nil
    do
      local arg1_763_0 = flags0
      local _24 = arg1_763_0
      rv_764_, arg1_763_ = ImGui.CheckboxFlags(ctx, "_DefaultHide", _24, ImGui.TableColumnFlags_DefaultHide())
    end
    flags0 = arg1_763_
  end
  do
    local rv_766_, arg1_765_ = nil, nil
    do
      local arg1_765_0 = flags0
      local _24 = arg1_765_0
      rv_766_, arg1_765_ = ImGui.CheckboxFlags(ctx, "_DefaultSort", _24, ImGui.TableColumnFlags_DefaultSort())
    end
    flags0 = arg1_765_
  end
  local _769_
  do
    local rv_768_, arg1_767_ = nil, nil
    do
      local arg1_767_0 = flags0
      local _24 = arg1_767_0
      rv_768_, arg1_767_ = ImGui.CheckboxFlags(ctx, "_WidthStretch", _24, ImGui.TableColumnFlags_WidthStretch())
    end
    flags0 = arg1_767_
    _769_ = rv_768_
  end
  if _769_ then
    flags0 = (flags0 & ~(width_mask ^ ImGui.TableColumnFlags_WidthStretch()))
  else
  end
  local _773_
  do
    local rv_772_, arg1_771_ = nil, nil
    do
      local arg1_771_0 = flags0
      local _24 = arg1_771_0
      rv_772_, arg1_771_ = ImGui.CheckboxFlags(ctx, "_WidthFixed", _24, ImGui.TableColumnFlags_WidthFixed())
    end
    flags0 = arg1_771_
    _773_ = rv_772_
  end
  if _773_ then
    flags0 = (flags0 & ~(width_mask ^ ImGui.TableColumnFlags_WidthFixed()))
  else
  end
  do
    local rv_776_, arg1_775_ = nil, nil
    do
      local arg1_775_0 = flags0
      local _24 = arg1_775_0
      rv_776_, arg1_775_ = ImGui.CheckboxFlags(ctx, "_NoResize", _24, ImGui.TableColumnFlags_NoResize())
    end
    flags0 = arg1_775_
  end
  do
    local rv_778_, arg1_777_ = nil, nil
    do
      local arg1_777_0 = flags0
      local _24 = arg1_777_0
      rv_778_, arg1_777_ = ImGui.CheckboxFlags(ctx, "_NoReorder", _24, ImGui.TableColumnFlags_NoReorder())
    end
    flags0 = arg1_777_
  end
  do
    local rv_780_, arg1_779_ = nil, nil
    do
      local arg1_779_0 = flags0
      local _24 = arg1_779_0
      rv_780_, arg1_779_ = ImGui.CheckboxFlags(ctx, "_NoHide", _24, ImGui.TableColumnFlags_NoHide())
    end
    flags0 = arg1_779_
  end
  do
    local rv_782_, arg1_781_ = nil, nil
    do
      local arg1_781_0 = flags0
      local _24 = arg1_781_0
      rv_782_, arg1_781_ = ImGui.CheckboxFlags(ctx, "_NoClip", _24, ImGui.TableColumnFlags_NoClip())
    end
    flags0 = arg1_781_
  end
  do
    local rv_784_, arg1_783_ = nil, nil
    do
      local arg1_783_0 = flags0
      local _24 = arg1_783_0
      rv_784_, arg1_783_ = ImGui.CheckboxFlags(ctx, "_NoSort", _24, ImGui.TableColumnFlags_NoSort())
    end
    flags0 = arg1_783_
  end
  do
    local rv_786_, arg1_785_ = nil, nil
    do
      local arg1_785_0 = flags0
      local _24 = arg1_785_0
      rv_786_, arg1_785_ = ImGui.CheckboxFlags(ctx, "_NoSortAscending", _24, ImGui.TableColumnFlags_NoSortAscending())
    end
    flags0 = arg1_785_
  end
  do
    local rv_788_, arg1_787_ = nil, nil
    do
      local arg1_787_0 = flags0
      local _24 = arg1_787_0
      rv_788_, arg1_787_ = ImGui.CheckboxFlags(ctx, "_NoSortDescending", _24, ImGui.TableColumnFlags_NoSortDescending())
    end
    flags0 = arg1_787_
  end
  do
    local rv_790_, arg1_789_ = nil, nil
    do
      local arg1_789_0 = flags0
      local _24 = arg1_789_0
      rv_790_, arg1_789_ = ImGui.CheckboxFlags(ctx, "_NoHeaderLabel", _24, ImGui.TableColumnFlags_NoHeaderLabel())
    end
    flags0 = arg1_789_
  end
  do
    local rv_792_, arg1_791_ = nil, nil
    do
      local arg1_791_0 = flags0
      local _24 = arg1_791_0
      rv_792_, arg1_791_ = ImGui.CheckboxFlags(ctx, "_NoHeaderWidth", _24, ImGui.TableColumnFlags_NoHeaderWidth())
    end
    flags0 = arg1_791_
  end
  do
    local rv_794_, arg1_793_ = nil, nil
    do
      local arg1_793_0 = flags0
      local _24 = arg1_793_0
      rv_794_, arg1_793_ = ImGui.CheckboxFlags(ctx, "_PreferSortAscending", _24, ImGui.TableColumnFlags_PreferSortAscending())
    end
    flags0 = arg1_793_
  end
  do
    local rv_796_, arg1_795_ = nil, nil
    do
      local arg1_795_0 = flags0
      local _24 = arg1_795_0
      rv_796_, arg1_795_ = ImGui.CheckboxFlags(ctx, "_PreferSortDescending", _24, ImGui.TableColumnFlags_PreferSortDescending())
    end
    flags0 = arg1_795_
  end
  do
    local rv_798_, arg1_797_ = nil, nil
    do
      local arg1_797_0 = flags0
      local _24 = arg1_797_0
      rv_798_, arg1_797_ = ImGui.CheckboxFlags(ctx, "_IndentEnable", _24, ImGui.TableColumnFlags_IndentEnable())
    end
    flags0 = arg1_797_
  end
  ImGui.SameLine(ctx)
  demo.HelpMarker("Default for column 0")
  do
    local rv_800_, arg1_799_ = nil, nil
    do
      local arg1_799_0 = flags0
      local _24 = arg1_799_0
      rv_800_, arg1_799_ = ImGui.CheckboxFlags(ctx, "_IndentDisable", _24, ImGui.TableColumnFlags_IndentDisable())
    end
    flags0 = arg1_799_
  end
  ImGui.SameLine(ctx)
  demo.HelpMarker("Default for column >0")
  return flags0
end
demo.ShowTableColumnsStatusFlags = function(flags)
  ImGui.CheckboxFlags(ctx, "_IsEnabled", flags, ImGui.TableColumnFlags_IsEnabled())
  ImGui.CheckboxFlags(ctx, "_IsVisible", flags, ImGui.TableColumnFlags_IsVisible())
  ImGui.CheckboxFlags(ctx, "_IsSorted", flags, ImGui.TableColumnFlags_IsSorted())
  return ImGui.CheckboxFlags(ctx, "_IsHovered", flags, ImGui.TableColumnFlags_IsHovered())
end
demo.ShowDemoWindowTables = function()
  if ImGui.CollapsingHeader(ctx, "Tables") then
    local rv = nil
    local TEXT_BASE_WIDTH = ImGui.CalcTextSize(ctx, "A")
    local TEXT_BASE_HEIGHT = ImGui.GetTextLineHeightWithSpacing(ctx)
    ImGui.PushID(ctx, "Tables")
    local open_action = ( - 1)
    if ImGui.Button(ctx, "Open all") then
      open_action = 1
    else
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Close all") then
      open_action = 0
    else
    end
    ImGui.SameLine(ctx)
    if (tables.disable_indent == nil) then
      tables.disable_indent = false
    else
    end
    do
      local rv_805_, arg1_804_ = nil, nil
      do
        local arg1_804_0 = tables.disable_indent
        local _24 = arg1_804_0
        rv_805_, arg1_804_ = ImGui.Checkbox(ctx, "Disable tree indentation", _24)
      end
      tables.disable_indent = arg1_804_
    end
    ImGui.SameLine(ctx)
    demo.HelpMarker("Disable the indenting of tree nodes so demo tables can use the full window width.")
    ImGui.Separator(ctx)
    if tables.disable_indent then
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing(), 0)
    else
    end
    local function Do_open_action()
      if (open_action ~= -1) then
        return ImGui.SetNextItemOpen(ctx, (open_action ~= 0))
      else
        return nil
      end
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Basic") then
      demo.HelpMarker("Using TableNextRow() + calling TableSetColumnIndex() _before_ each cell, in a loop.")
      if ImGui.BeginTable(ctx, "table1", 3) then
        for row = 0, 3 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Row %d Column %d"):format(row, column))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      demo.HelpMarker("Using TableNextRow() + calling TableNextColumn() _before_ each cell, manually.")
      if ImGui.BeginTable(ctx, "table2", 3) then
        for row = 0, 3 do
          ImGui.TableNextRow(ctx)
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, ("Row %d"):format(row))
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, "Some contents")
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, "123.456")
        end
        ImGui.EndTable(ctx)
      else
      end
      demo.HelpMarker("Only using TableNextColumn(), which tends to be convenient for tables where every cell contains the same type of contents.\n\n      This is also more similar to the old NextColumn() function of the Columns API, and provided to facilitate the Columns->Tables API transition.")
      if ImGui.BeginTable(ctx, "table3", 3) then
        for item = 0, 13 do
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, ("Item %d"):format(item))
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Borders, background") then
      if not tables.borders_bg then
        tables.borders_bg = {contents_type = 0, flags = (ImGui.TableFlags_Borders() | ImGui.TableFlags_RowBg()), display_headers = false}
      else
      end
      demo.PushStyleCompact()
      do
        local rv_814_, arg1_813_ = nil, nil
        do
          local arg1_813_0 = tables.borders_bg.flags
          local _24 = arg1_813_0
          rv_814_, arg1_813_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_RowBg", _24, ImGui.TableFlags_RowBg())
        end
        tables.borders_bg.flags = arg1_813_
      end
      do
        local rv_816_, arg1_815_ = nil, nil
        do
          local arg1_815_0 = tables.borders_bg.flags
          local _24 = arg1_815_0
          rv_816_, arg1_815_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Borders", _24, ImGui.TableFlags_Borders())
        end
        tables.borders_bg.flags = arg1_815_
      end
      ImGui.SameLine(ctx)
      demo.HelpMarker("ImGuiTableFlags_Borders\n      = ImGuiTableFlags_BordersInnerV\n      | ImGuiTableFlags_BordersOuterV\n      | ImGuiTableFlags_BordersInnerV\n      | ImGuiTableFlags_BordersOuterH")
      ImGui.Indent(ctx)
      do
        local rv_818_, arg1_817_ = nil, nil
        do
          local arg1_817_0 = tables.borders_bg.flags
          local _24 = arg1_817_0
          rv_818_, arg1_817_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersH", _24, ImGui.TableFlags_BordersH())
        end
        tables.borders_bg.flags = arg1_817_
      end
      ImGui.Indent(ctx)
      do
        local rv_820_, arg1_819_ = nil, nil
        do
          local arg1_819_0 = tables.borders_bg.flags
          local _24 = arg1_819_0
          rv_820_, arg1_819_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuterH", _24, ImGui.TableFlags_BordersOuterH())
        end
        tables.borders_bg.flags = arg1_819_
      end
      do
        local rv_822_, arg1_821_ = nil, nil
        do
          local arg1_821_0 = tables.borders_bg.flags
          local _24 = arg1_821_0
          rv_822_, arg1_821_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInnerH", _24, ImGui.TableFlags_BordersInnerH())
        end
        tables.borders_bg.flags = arg1_821_
      end
      ImGui.Unindent(ctx)
      do
        local rv_824_, arg1_823_ = nil, nil
        do
          local arg1_823_0 = tables.borders_bg.flags
          local _24 = arg1_823_0
          rv_824_, arg1_823_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersV", _24, ImGui.TableFlags_BordersV())
        end
        tables.borders_bg.flags = arg1_823_
      end
      ImGui.Indent(ctx)
      do
        local rv_826_, arg1_825_ = nil, nil
        do
          local arg1_825_0 = tables.borders_bg.flags
          local _24 = arg1_825_0
          rv_826_, arg1_825_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuterV", _24, ImGui.TableFlags_BordersOuterV())
        end
        tables.borders_bg.flags = arg1_825_
      end
      do
        local rv_828_, arg1_827_ = nil, nil
        do
          local arg1_827_0 = tables.borders_bg.flags
          local _24 = arg1_827_0
          rv_828_, arg1_827_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInnerV", _24, ImGui.TableFlags_BordersInnerV())
        end
        tables.borders_bg.flags = arg1_827_
      end
      ImGui.Unindent(ctx)
      do
        local rv_830_, arg1_829_ = nil, nil
        do
          local arg1_829_0 = tables.borders_bg.flags
          local _24 = arg1_829_0
          rv_830_, arg1_829_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuter", _24, ImGui.TableFlags_BordersOuter())
        end
        tables.borders_bg.flags = arg1_829_
      end
      do
        local rv_832_, arg1_831_ = nil, nil
        do
          local arg1_831_0 = tables.borders_bg.flags
          local _24 = arg1_831_0
          rv_832_, arg1_831_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInner", _24, ImGui.TableFlags_BordersInner())
        end
        tables.borders_bg.flags = arg1_831_
      end
      ImGui.Unindent(ctx)
      ImGui.AlignTextToFramePadding(ctx)
      ImGui.Text(ctx, "Cell contents:")
      ImGui.SameLine(ctx)
      do
        local rv_834_, arg1_833_ = nil, nil
        do
          local arg1_833_0 = tables.borders_bg.contents_type
          local _24 = arg1_833_0
          rv_834_, arg1_833_ = ImGui.RadioButtonEx(ctx, "Text", _24, 0)
        end
        tables.borders_bg.contents_type = arg1_833_
      end
      ImGui.SameLine(ctx)
      do
        local rv_836_, arg1_835_ = nil, nil
        do
          local arg1_835_0 = tables.borders_bg.contents_type
          local _24 = arg1_835_0
          rv_836_, arg1_835_ = ImGui.RadioButtonEx(ctx, "FillButton", _24, 1)
        end
        tables.borders_bg.contents_type = arg1_835_
      end
      do
        local rv_838_, arg1_837_ = nil, nil
        do
          local arg1_837_0 = tables.borders_bg.display_headers
          local _24 = arg1_837_0
          rv_838_, arg1_837_ = ImGui.Checkbox(ctx, "Display headers", _24)
        end
        tables.borders_bg.display_headers = arg1_837_
      end
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table1", 3, tables.borders_bg.flags) then
        if tables.borders_bg.display_headers then
          ImGui.TableSetupColumn(ctx, "One")
          ImGui.TableSetupColumn(ctx, "Two")
          ImGui.TableSetupColumn(ctx, "Three")
          ImGui.TableHeadersRow(ctx)
        else
        end
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            local buf = ("Hello %d,%d"):format(column, row)
            if (tables.borders_bg.contents_type == 0) then
              ImGui.Text(ctx, buf)
            elseif (tables.borders_bg.contents_type == 1) then
              ImGui.Button(ctx, buf, ( - FLT_MIN), 0)
            else
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Resizable, stretch") then
      if not tables.resz_stretch then
        tables.resz_stretch = {flags = (ImGui.TableFlags_SizingStretchSame() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV() | ImGui.TableFlags_ContextMenuInBody())}
      else
      end
      demo.PushStyleCompact()
      do
        local rv_845_, arg1_844_ = nil, nil
        do
          local arg1_844_0 = tables.resz_stretch.flags
          local _24 = arg1_844_0
          rv_845_, arg1_844_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", _24, ImGui.TableFlags_Resizable())
        end
        tables.resz_stretch.flags = arg1_844_
      end
      do
        local rv_847_, arg1_846_ = nil, nil
        do
          local arg1_846_0 = tables.resz_stretch.flags
          local _24 = arg1_846_0
          rv_847_, arg1_846_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersV", _24, ImGui.TableFlags_BordersV())
        end
        tables.resz_stretch.flags = arg1_846_
      end
      ImGui.SameLine(ctx)
      demo.HelpMarker("Using the _Resizable flag automatically enables the _BordersInnerV flag as well, this is why the resize borders are still showing when unchecking this.")
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table1", 3, tables.resz_stretch.flags) then
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Hello %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Resizable, fixed") then
      if not tables.resz_fixed then
        tables.resz_fixed = {flags = (ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV() | ImGui.TableFlags_ContextMenuInBody())}
      else
      end
      demo.HelpMarker("Using _Resizable + _SizingFixedFit flags.\n\n      Fixed-width columns generally makes more sense if you want to use horizontal scrolling.\n\n\n      Double-click a column border to auto-fit the column to its contents.")
      demo.PushStyleCompact()
      do
        local rv_852_, arg1_851_ = nil, nil
        do
          local arg1_851_0 = tables.resz_fixed.flags
          local _24 = arg1_851_0
          rv_852_, arg1_851_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoHostExtendX", _24, ImGui.TableFlags_NoHostExtendX())
        end
        tables.resz_fixed.flags = arg1_851_
      end
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table1", 3, tables.resz_fixed.flags) then
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Hello %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Resizable, mixed") then
      if not tables.resz_mixed then
        tables.resz_mixed = {flags = (ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_Borders() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable())}
      else
      end
      demo.HelpMarker("Using TableSetupColumn() to alter resizing policy on a per-column basis.\n\n\n      When combining Fixed and Stretch columns, generally you only want one, maybe two trailing columns to use _WidthStretch.")
      if ImGui.BeginTable(ctx, "table1", 3, tables.resz_mixed.flags) then
        ImGui.TableSetupColumn(ctx, "AAA", ImGui.TableColumnFlags_WidthFixed())
        ImGui.TableSetupColumn(ctx, "BBB", ImGui.TableColumnFlags_WidthFixed())
        ImGui.TableSetupColumn(ctx, "CCC", ImGui.TableColumnFlags_WidthStretch())
        ImGui.TableHeadersRow(ctx)
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            local _856_
            if (column == 2) then
              _856_ = "Stretch"
            else
              _856_ = "Fixed"
            end
            ImGui.Text(ctx, ("%s %d,%d"):format(_856_, column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      if ImGui.BeginTable(ctx, "table2", 6, tables.resz_mixed.flags) then
        ImGui.TableSetupColumn(ctx, "AAA", ImGui.TableColumnFlags_WidthFixed())
        ImGui.TableSetupColumn(ctx, "BBB", ImGui.TableColumnFlags_WidthFixed())
        ImGui.TableSetupColumn(ctx, "CCC", (ImGui.TableColumnFlags_WidthFixed() | ImGui.TableColumnFlags_DefaultHide()))
        ImGui.TableSetupColumn(ctx, "DDD", ImGui.TableColumnFlags_WidthStretch())
        ImGui.TableSetupColumn(ctx, "EEE", ImGui.TableColumnFlags_WidthStretch())
        ImGui.TableSetupColumn(ctx, "FFF", (ImGui.TableColumnFlags_WidthStretch() | ImGui.TableColumnFlags_DefaultHide()))
        ImGui.TableHeadersRow(ctx)
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 5 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("%s %d,%d"):format((((column >= 3) and "Stretch") or "Fixed"), column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Reorderable, hideable, with headers") then
      if not tables.reorder then
        tables.reorder = {flags = (ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV())}
      else
      end
      demo.HelpMarker("Click and drag column headers to reorder columns.\n\n\n      Right-click on a header to open a context menu.")
      demo.PushStyleCompact()
      do
        local rv_863_, arg1_862_ = nil, nil
        do
          local arg1_862_0 = tables.reorder.flags
          local _24 = arg1_862_0
          rv_863_, arg1_862_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", _24, ImGui.TableFlags_Resizable())
        end
        tables.reorder.flags = arg1_862_
      end
      do
        local rv_865_, arg1_864_ = nil, nil
        do
          local arg1_864_0 = tables.reorder.flags
          local _24 = arg1_864_0
          rv_865_, arg1_864_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Reorderable", _24, ImGui.TableFlags_Reorderable())
        end
        tables.reorder.flags = arg1_864_
      end
      do
        local rv_867_, arg1_866_ = nil, nil
        do
          local arg1_866_0 = tables.reorder.flags
          local _24 = arg1_866_0
          rv_867_, arg1_866_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Hideable", _24, ImGui.TableFlags_Hideable())
        end
        tables.reorder.flags = arg1_866_
      end
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table1", 3, tables.reorder.flags) then
        ImGui.TableSetupColumn(ctx, "One")
        ImGui.TableSetupColumn(ctx, "Two")
        ImGui.TableSetupColumn(ctx, "Three")
        ImGui.TableHeadersRow(ctx)
        for row = 0, 5 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Hello %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      if ImGui.BeginTable(ctx, "table2", 3, (tables.reorder.flags | ImGui.TableFlags_SizingFixedFit()), 0.0, 0.0) then
        ImGui.TableSetupColumn(ctx, "One")
        ImGui.TableSetupColumn(ctx, "Two")
        ImGui.TableSetupColumn(ctx, "Three")
        ImGui.TableHeadersRow(ctx)
        for row = 0, 5 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Fixed %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Padding") then
      if not tables.padding then
        tables.padding = {cell_padding = {0, 0}, flags1 = ImGui.TableFlags_BordersV(), flags2 = (ImGui.TableFlags_Borders() | ImGui.TableFlags_RowBg()), show_widget_frame_bg = true, text_bufs = {}, show_headers = false}
      else
      end
      demo.HelpMarker("We often want outer padding activated when any using features which makes the edges of a column visible:\n      e.g.:\n      - BorderOuterV\n      - any form of row selection\n      Because of this, activating BorderOuterV sets the default to PadOuterX. Using PadOuterX or NoPadOuterX you can override the default.\n\n      Actual padding values are using style.CellPadding.\n\n      In this demo we don't show horizontal borders to emphasize how they don't affect default horizontal padding.")
      demo.PushStyleCompact()
      rv, tables.padding.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_PadOuterX", tables.padding.flags1, ImGui.TableFlags_PadOuterX())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Enable outer-most padding (default if ImGuiTableFlags_BordersOuterV is set)")
      rv, tables.padding.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoPadOuterX", tables.padding.flags1, ImGui.TableFlags_NoPadOuterX())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Disable outer-most padding (default if ImGuiTableFlags_BordersOuterV is not set)")
      rv, tables.padding.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoPadInnerX", tables.padding.flags1, ImGui.TableFlags_NoPadInnerX())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off)")
      rv, tables.padding.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuterV", tables.padding.flags1, ImGui.TableFlags_BordersOuterV())
      rv, tables.padding.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInnerV", tables.padding.flags1, ImGui.TableFlags_BordersInnerV())
      rv, tables.padding.show_headers = ImGui.Checkbox(ctx, "show_headers", tables.padding.show_headers)
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table_padding", 3, tables.padding.flags1) then
        if tables.padding.show_headers then
          ImGui.TableSetupColumn(ctx, "One")
          ImGui.TableSetupColumn(ctx, "Two")
          ImGui.TableSetupColumn(ctx, "Three")
          ImGui.TableHeadersRow(ctx)
        else
        end
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            if (row == 0) then
              ImGui.Text(ctx, ("Avail %.2f"):format(ImGui.GetContentRegionAvail(ctx)))
            else
              local buf = ("Hello %d,%d"):format(column, row)
              ImGui.Button(ctx, buf, ( - FLT_MIN), 0)
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      demo.HelpMarker("Setting style.CellPadding to (0,0) or a custom value.")
      demo.PushStyleCompact()
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Borders", tables.padding.flags2, ImGui.TableFlags_Borders())
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersH", tables.padding.flags2, ImGui.TableFlags_BordersH())
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersV", tables.padding.flags2, ImGui.TableFlags_BordersV())
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInner", tables.padding.flags2, ImGui.TableFlags_BordersInner())
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuter", tables.padding.flags2, ImGui.TableFlags_BordersOuter())
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_RowBg", tables.padding.flags2, ImGui.TableFlags_RowBg())
      rv, tables.padding.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", tables.padding.flags2, ImGui.TableFlags_Resizable())
      rv, tables.padding.show_widget_frame_bg = ImGui.Checkbox(ctx, "show_widget_frame_bg", tables.padding.show_widget_frame_bg)
      rv, cp1, cp2 = ImGui.SliderDouble2(ctx, "CellPadding", tables.padding.cell_padding[1], tables.padding.cell_padding[2], 0, 10, "%.0f")
      do end (tables.padding.cell_padding)[1] = cp1
      tables.padding.cell_padding[2] = cp2
      demo.PopStyleCompact()
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding(), table.unpack(tables.padding.cell_padding))
      if ImGui.BeginTable(ctx, "table_padding_2", 3, tables.padding.flags2) then
        if not tables.padding.show_widget_frame_bg then
          ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg(), 0)
        else
        end
        for cell = 1, (3 * 5) do
          ImGui.TableNextColumn(ctx)
          ImGui.SetNextItemWidth(ctx, ( - FLT_MIN))
          ImGui.PushID(ctx, cell)
          rv, tbc = ImGui.InputText(ctx, "##cell", tables.padding.text_bufs[cell])
          do end (tables.padding.text_bufs)[cell] = tbc
          ImGui.PopID(ctx)
        end
        if not tables.padding.show_widget_frame_bg then
          ImGui.PopStyleColor(ctx)
        else
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.PopStyleVar(ctx)
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Sizing policies") then
      if not tables.sz_policies then
        tables.sz_policies = {column_count = 3, contents_type = 0, flags1 = (ImGui.TableFlags_BordersV() | ImGui.TableFlags_BordersOuterH() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_ContextMenuInBody()), flags2 = (ImGui.TableFlags_ScrollY() | ImGui.TableFlags_Borders() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_Resizable()), sizing_policy_flags = {ImGui.TableFlags_SizingFixedFit(), ImGui.TableFlags_SizingFixedSame(), ImGui.TableFlags_SizingStretchProp(), ImGui.TableFlags_SizingStretchSame()}, text_buf = ""}
      else
      end
      demo.PushStyleCompact()
      rv, tables.sz_policies.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", tables.sz_policies.flags1, ImGui.TableFlags_Resizable())
      rv, tables.sz_policies.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoHostExtendX", tables.sz_policies.flags1, ImGui.TableFlags_NoHostExtendX())
      demo.PopStyleCompact()
      for table_n, sizing_flags in ipairs(tables.sz_policies.sizing_policy_flags) do
        ImGui.PushID(ctx, table_n)
        ImGui.SetNextItemWidth(ctx, (TEXT_BASE_WIDTH * 30))
        sizing_flags = demo.EditTableSizingFlags(sizing_flags)
        do end (tables.sz_policies.sizing_policy_flags)[table_n] = sizing_flags
        if ImGui.BeginTable(ctx, "table1", 3, (sizing_flags | tables.sz_policies.flags1)) then
          for row = 0, 2 do
            ImGui.TableNextRow(ctx)
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "Oh dear")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "Oh dear")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "Oh dear")
          end
          ImGui.EndTable(ctx)
        else
        end
        if ImGui.BeginTable(ctx, "table2", 3, (sizing_flags | tables.sz_policies.flags1)) then
          for row = 0, 2 do
            ImGui.TableNextRow(ctx)
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "AAAA")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "BBBBBBBB")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, "CCCCCCCCCCCC")
          end
          ImGui.EndTable(ctx)
        else
        end
        ImGui.PopID(ctx)
      end
      ImGui.Spacing(ctx)
      ImGui.Text(ctx, "Advanced")
      ImGui.SameLine(ctx)
      demo.HelpMarker("This section allows you to interact and see the effect of various sizing policies depending on whether Scroll is enabled and the contents of your columns.")
      demo.PushStyleCompact()
      ImGui.PushID(ctx, "Advanced")
      ImGui.PushItemWidth(ctx, (TEXT_BASE_WIDTH * 30))
      tables.sz_policies.flags2 = demo.EditTableSizingFlags(tables.sz_policies.flags2)
      rv, tables.sz_policies.contents_type = ImGui.Combo(ctx, "Contents", tables.sz_policies.contents_type, "Show width\0Short Text\0Long Text\0Button\0Fill Button\0InputText\0")
      if (tables.sz_policies.contents_type == 4) then
        ImGui.SameLine(ctx)
        demo.HelpMarker("Be mindful that using right-alignment (e.g. size.x = -FLT_MIN) creates a feedback loop where contents width can feed into auto-column width can feed into contents width.")
      else
      end
      rv, tables.sz_policies.column_count = ImGui.DragInt(ctx, "Columns", tables.sz_policies.column_count, 0.1, 1, 64, "%d", ImGui.SliderFlags_AlwaysClamp())
      rv, tables.sz_policies.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", tables.sz_policies.flags2, ImGui.TableFlags_Resizable())
      rv, tables.sz_policies.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_PreciseWidths", tables.sz_policies.flags2, ImGui.TableFlags_PreciseWidths())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
      rv, tables.sz_policies.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollX", tables.sz_policies.flags2, ImGui.TableFlags_ScrollX())
      rv, tables.sz_policies.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollY", tables.sz_policies.flags2, ImGui.TableFlags_ScrollY())
      rv, tables.sz_policies.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoClip", tables.sz_policies.flags2, ImGui.TableFlags_NoClip())
      ImGui.PopItemWidth(ctx)
      ImGui.PopID(ctx)
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table2", tables.sz_policies.column_count, tables.sz_policies.flags2, 0, (TEXT_BASE_HEIGHT * 7)) then
        for cell = 1, (10 * tables.sz_policies.column_count) do
          ImGui.TableNextColumn(ctx)
          local column = ImGui.TableGetColumnIndex(ctx)
          local row = ImGui.TableGetRowIndex(ctx)
          ImGui.PushID(ctx, cell)
          local label = ("Hello %d,%d"):format(column, row)
          local contents_type = tables.sz_policies.contents_type
          if (contents_type == 1) then
            ImGui.Text(ctx, label)
          elseif (contents_type == 2) then
            ImGui.Text(ctx, ("Some %s text %d,%d\nOver two lines.."):format((((column == 0) and "long") or "longeeer"), column, row))
          elseif (contents_type == 0) then
            ImGui.Text(ctx, ("W: %.1f"):format(ImGui.GetContentRegionAvail(ctx)))
          elseif (contents_type == 3) then
            ImGui.Button(ctx, label)
          elseif (contents_type == 4) then
            ImGui.Button(ctx, label, ( - FLT_MIN), 0)
          elseif (contents_type == 5) then
            ImGui.SetNextItemWidth(ctx, ( - FLT_MIN))
            rv, tables.sz_policies.text_buf = ImGui.InputText(ctx, "##", tables.sz_policies.text_buf)
          else
          end
          ImGui.PopID(ctx)
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Vertical scrolling, with clipping") then
      if not tables.vertical then
        tables.vertical = {flags = (ImGui.TableFlags_ScrollY() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable())}
      else
      end
      demo.HelpMarker("Here we activate ScrollY, which will create a child window container to allow hosting scrollable contents.\n\n      We also demonstrate using ImGuiListClipper to virtualize the submission of many items.")
      demo.PushStyleCompact()
      rv, tables.vertical.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollY", tables.vertical.flags, ImGui.TableFlags_ScrollY())
      demo.PopStyleCompact()
      local outer_size = {0, (TEXT_BASE_HEIGHT * 8)}
      if ImGui.BeginTable(ctx, "table_scrolly", 3, tables.vertical.flags, table.unpack(outer_size)) then
        ImGui.TableSetupScrollFreeze(ctx, 0, 1)
        ImGui.TableSetupColumn(ctx, "One", ImGui.TableColumnFlags_None())
        ImGui.TableSetupColumn(ctx, "Two", ImGui.TableColumnFlags_None())
        ImGui.TableSetupColumn(ctx, "Three", ImGui.TableColumnFlags_None())
        ImGui.TableHeadersRow(ctx)
        local clipper = ImGui.CreateListClipper(ctx)
        ImGui.ListClipper_Begin(clipper, 1000)
        while ImGui.ListClipper_Step(clipper) do
          local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
          for row = display_start, (display_end - 1) do
            ImGui.TableNextRow(ctx)
            for column = 0, 2 do
              ImGui.TableSetColumnIndex(ctx, column)
              ImGui.Text(ctx, ("Hello %d,%d"):format(column, row))
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Horizontal scrolling") then
      if not tables.horizontal then
        tables.horizontal = {flags1 = (ImGui.TableFlags_ScrollX() | ImGui.TableFlags_ScrollY() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable()), flags2 = (ImGui.TableFlags_SizingStretchSame() | ImGui.TableFlags_ScrollX() | ImGui.TableFlags_ScrollY() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_ContextMenuInBody()), freeze_cols = 1, freeze_rows = 1, inner_width = 1000}
      else
      end
      demo.HelpMarker("When ScrollX is enabled, the default sizing policy becomes ImGuiTableFlags_SizingFixedFit, as automatically stretching columns doesn't make much sense with horizontal scrolling.\n\n      Also note that as of the current version, you will almost always want to enable ScrollY along with ScrollX,because the container window won't automatically extend vertically to fix contents (this may be improved in future versions).")
      demo.PushStyleCompact()
      rv, tables.horizontal.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", tables.horizontal.flags1, ImGui.TableFlags_Resizable())
      rv, tables.horizontal.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollX", tables.horizontal.flags1, ImGui.TableFlags_ScrollX())
      rv, tables.horizontal.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollY", tables.horizontal.flags1, ImGui.TableFlags_ScrollY())
      ImGui.SetNextItemWidth(ctx, ImGui.GetFrameHeight(ctx))
      rv, tables.horizontal.freeze_cols = ImGui.DragInt(ctx, "freeze_cols", tables.horizontal.freeze_cols, 0.2, 0, 9, nil, ImGui.SliderFlags_NoInput())
      ImGui.SetNextItemWidth(ctx, ImGui.GetFrameHeight(ctx))
      rv, tables.horizontal.freeze_rows = ImGui.DragInt(ctx, "freeze_rows", tables.horizontal.freeze_rows, 0.2, 0, 9, nil, ImGui.SliderFlags_NoInput())
      demo.PopStyleCompact()
      local outer_size = {0, (TEXT_BASE_HEIGHT * 8)}
      if ImGui.BeginTable(ctx, "table_scrollx", 7, tables.horizontal.flags1, table.unpack(outer_size)) then
        ImGui.TableSetupScrollFreeze(ctx, tables.horizontal.freeze_cols, tables.horizontal.freeze_rows)
        ImGui.TableSetupColumn(ctx, "Line #", ImGui.TableColumnFlags_NoHide())
        ImGui.TableSetupColumn(ctx, "One")
        ImGui.TableSetupColumn(ctx, "Two")
        ImGui.TableSetupColumn(ctx, "Three")
        ImGui.TableSetupColumn(ctx, "Four")
        ImGui.TableSetupColumn(ctx, "Five")
        ImGui.TableSetupColumn(ctx, "Six")
        ImGui.TableHeadersRow(ctx)
        for row = 0, 19 do
          ImGui.TableNextRow(ctx)
          for column = 0, 6 do
            if (ImGui.TableSetColumnIndex(ctx, column) or (column == 0)) then
              if (column == 0) then
                ImGui.Text(ctx, ("Line %d"):format(row))
              else
                ImGui.Text(ctx, ("Hello world %d,%d"):format(column, row))
              end
            else
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.Spacing(ctx)
      ImGui.Text(ctx, "Stretch + ScrollX")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Showcase using Stretch columns + ScrollX together: this is rather unusual and only makes sense when specifying an 'inner_width' for the table!\n      Without an explicit value, inner_width is == outer_size.x and therefore using Stretch columns + ScrollX together doesn't make sense.")
      demo.PushStyleCompact()
      ImGui.PushID(ctx, "flags3")
      ImGui.PushItemWidth(ctx, (TEXT_BASE_WIDTH * 30))
      rv, tables.horizontal.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollX", tables.horizontal.flags2, ImGui.TableFlags_ScrollX())
      rv, tables.horizontal.inner_width = ImGui.DragDouble(ctx, "inner_width", tables.horizontal.inner_width, 1, 0, FLT_MAX, "%.1f")
      ImGui.PopItemWidth(ctx)
      ImGui.PopID(ctx)
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table2", 7, tables.horizontal.flags2, outer_size[1], outer_size[2], tables.horizontal.inner_width) then
        for cell = 1, (20 * 7) do
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, ("Hello world %d,%d"):format(ImGui.TableGetColumnIndex(ctx), ImGui.TableGetRowIndex(ctx)))
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Columns flags") then
      if not tables.col_flags then
        tables.col_flags = {columns = {{flags = ImGui.TableColumnFlags_DefaultSort(), flags_out = 0, name = "One"}, {flags = ImGui.TableColumnFlags_None(), flags_out = 0, name = "Two"}, {flags = ImGui.TableColumnFlags_DefaultHide(), flags_out = 0, name = "Three"}}}
      else
      end
      if ImGui.BeginTable(ctx, "table_columns_flags_checkboxes", #tables.col_flags.columns, ImGui.TableFlags_None()) then
        demo.PushStyleCompact()
        for i, column in ipairs(tables.col_flags.columns) do
          ImGui.TableNextColumn(ctx)
          ImGui.PushID(ctx, i)
          ImGui.AlignTextToFramePadding(ctx)
          ImGui.Text(ctx, ("'%s'"):format(column.name))
          ImGui.Spacing(ctx)
          ImGui.Text(ctx, "Input flags:")
          column.flags = demo.EditTableColumnsFlags(column.flags)
          ImGui.Spacing(ctx)
          ImGui.Text(ctx, "Output flags:")
          ImGui.BeginDisabled(ctx)
          demo.ShowTableColumnsStatusFlags(column.flags_out)
          ImGui.EndDisabled(ctx)
          ImGui.PopID(ctx)
        end
        demo.PopStyleCompact()
        ImGui.EndTable(ctx)
      else
      end
      local flags = (ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_ScrollX() | ImGui.TableFlags_ScrollY() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable())
      local outer_size = {0, (TEXT_BASE_HEIGHT * 9)}
      if ImGui.BeginTable(ctx, "table_columns_flags", #tables.col_flags.columns, flags, table.unpack(outer_size)) then
        for i, column in ipairs(tables.col_flags.columns) do
          ImGui.TableSetupColumn(ctx, column.name, column.flags)
        end
        ImGui.TableHeadersRow(ctx)
        for i, column in ipairs(tables.col_flags.columns) do
          column.flags_out = ImGui.TableGetColumnFlags(ctx, (i - 1))
        end
        local indent_step = (TEXT_BASE_WIDTH / 2)
        for row = 0, 7 do
          ImGui.Indent(ctx, indent_step)
          ImGui.TableNextRow(ctx)
          for column = 0, (#tables.col_flags.columns - 1) do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("%s %s"):format((((column == 0) and "Indented") or "Hello"), ImGui.TableGetColumnName(ctx, column)))
          end
        end
        ImGui.Unindent(ctx, (indent_step * 8))
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Columns widths") then
      if not tables.col_widths then
        tables.col_widths = {flags1 = ImGui.TableFlags_Borders(), flags2 = ImGui.TableFlags_None()}
      else
      end
      demo.HelpMarker("Using TableSetupColumn() to setup default width.")
      demo.PushStyleCompact()
      rv, tables.col_widths.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", tables.col_widths.flags1, ImGui.TableFlags_Resizable())
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table1", 3, tables.col_widths.flags1) then
        ImGui.TableSetupColumn(ctx, "one", ImGui.TableColumnFlags_WidthFixed(), 100)
        ImGui.TableSetupColumn(ctx, "two", ImGui.TableColumnFlags_WidthFixed(), 200)
        ImGui.TableSetupColumn(ctx, "three", ImGui.TableColumnFlags_WidthFixed())
        ImGui.TableHeadersRow(ctx)
        for row = 0, 3 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableSetColumnIndex(ctx, column)
            if (row == 0) then
              ImGui.Text(ctx, ("(w: %5.1f)"):format(ImGui.GetContentRegionAvail(ctx)))
            else
              ImGui.Text(ctx, ("Hello %d,%d"):format(column, row))
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      demo.HelpMarker("Using TableSetupColumn() to setup explicit width.\n\n      Unless _NoKeepColumnsVisible is set, fixed columns with set width may still be shrunk down if there's not enough space in the host.")
      demo.PushStyleCompact()
      rv, tables.col_widths.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoKeepColumnsVisible", tables.col_widths.flags2, ImGui.TableFlags_NoKeepColumnsVisible())
      rv, tables.col_widths.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInnerV", tables.col_widths.flags2, ImGui.TableFlags_BordersInnerV())
      rv, tables.col_widths.flags2 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuterV", tables.col_widths.flags2, ImGui.TableFlags_BordersOuterV())
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table2", 4, tables.col_widths.flags2) then
        ImGui.TableSetupColumn(ctx, "", ImGui.TableColumnFlags_WidthFixed(), 100)
        ImGui.TableSetupColumn(ctx, "", ImGui.TableColumnFlags_WidthFixed(), (TEXT_BASE_WIDTH * 15))
        ImGui.TableSetupColumn(ctx, "", ImGui.TableColumnFlags_WidthFixed(), (TEXT_BASE_WIDTH * 30))
        ImGui.TableSetupColumn(ctx, "", ImGui.TableColumnFlags_WidthFixed(), (TEXT_BASE_WIDTH * 15))
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 3 do
            ImGui.TableSetColumnIndex(ctx, column)
            if (row == 0) then
              ImGui.Text(ctx, ("(w: %5.1f)"):format(ImGui.GetContentRegionAvail(ctx)))
            else
              ImGui.Text(ctx, ("Hello %d,%d"):format(column, row))
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Nested tables") then
      demo.HelpMarker("This demonstrates embedding a table into another table cell.")
      local flags = (ImGui.TableFlags_Borders() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable())
      if ImGui.BeginTable(ctx, "table_nested1", 2, flags) then
        ImGui.TableSetupColumn(ctx, "A0")
        ImGui.TableSetupColumn(ctx, "A1")
        ImGui.TableHeadersRow(ctx)
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx, "A0 Row 0")
        local rows_height = (TEXT_BASE_HEIGHT * 2)
        if ImGui.BeginTable(ctx, "table_nested2", 2, flags) then
          ImGui.TableSetupColumn(ctx, "B0")
          ImGui.TableSetupColumn(ctx, "B1")
          ImGui.TableHeadersRow(ctx)
          ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None(), rows_height)
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, "B0 Row 0")
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, "B0 Row 1")
          ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None(), rows_height)
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, "B1 Row 0")
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, "B1 Row 1")
          ImGui.EndTable(ctx)
        else
        end
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx, "A0 Row 1")
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx, "A1 Row 0")
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx, "A1 Row 1")
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Row height") then
      demo.HelpMarker("You can pass a 'min_row_height' to TableNextRow().\n\n      Rows are padded with 'ImGui_StyleVar_CellPadding.y' on top and bottom, so effectively the minimum row height will always be >= 'ImGui_StyleVar_CellPadding.y * 2.0'.\n\n      We cannot honor a _maximum_ row height as that would require a unique clipping rectangle per row.")
      if ImGui.BeginTable(ctx, "table_row_height", 1, (ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersInnerV())) then
        for row = 0, 9 do
          local min_row_height = ((TEXT_BASE_HEIGHT * 0.3) * row)
          ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None(), min_row_height)
          ImGui.TableNextColumn(ctx)
          ImGui.Text(ctx, ("min_row_height = %.2f"):format(min_row_height))
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Outer size") then
      if not tables.outer_sz then
        tables.outer_sz = {flags = (ImGui.TableFlags_Borders() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_ContextMenuInBody() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_NoHostExtendX())}
      else
      end
      ImGui.Text(ctx, "Using NoHostExtendX and NoHostExtendY:")
      demo.PushStyleCompact()
      rv, tables.outer_sz.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoHostExtendX", tables.outer_sz.flags, ImGui.TableFlags_NoHostExtendX())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Make outer width auto-fit to columns, overriding outer_size.x value.\n\n      Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
      rv, tables.outer_sz.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoHostExtendY", tables.outer_sz.flags, ImGui.TableFlags_NoHostExtendY())
      ImGui.SameLine(ctx)
      demo.HelpMarker("Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\n      Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
      demo.PopStyleCompact()
      local outer_size = {0, (TEXT_BASE_HEIGHT * 5.5)}
      if ImGui.BeginTable(ctx, "table1", 3, tables.outer_sz.flags, table.unpack(outer_size)) then
        for row = 0, 9 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("Cell %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.SameLine(ctx)
      ImGui.Text(ctx, "Hello!")
      ImGui.Spacing(ctx)
      local flags = (ImGui.TableFlags_Borders() | ImGui.TableFlags_RowBg())
      ImGui.Text(ctx, "Using explicit size:")
      if ImGui.BeginTable(ctx, "table2", 3, flags, (TEXT_BASE_WIDTH * 30), 0) then
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("Cell %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.BeginTable(ctx, "table3", 3, flags, (TEXT_BASE_WIDTH * 30), 0) then
        for row = 0, 2 do
          ImGui.TableNextRow(ctx, 0, (TEXT_BASE_HEIGHT * 1.5))
          for column = 0, 2 do
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("Cell %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Background color") then
      if not tables.bg_col then
        tables.bg_col = {cell_bg_type = 1, flags = ImGui.TableFlags_RowBg(), row_bg_target = 1, row_bg_type = 1}
      else
      end
      demo.PushStyleCompact()
      rv, tables.bg_col.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Borders", tables.bg_col.flags, ImGui.TableFlags_Borders())
      rv, tables.bg_col.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_RowBg", tables.bg_col.flags, ImGui.TableFlags_RowBg())
      ImGui.SameLine(ctx)
      demo.HelpMarker("ImGuiTableFlags_RowBg automatically sets RowBg0 to alternative colors pulled from the Style.")
      rv, tables.bg_col.row_bg_type = ImGui.Combo(ctx, "row bg type", tables.bg_col.row_bg_type, "None\0Red\0Gradient\0")
      rv, tables.bg_col.row_bg_target = ImGui.Combo(ctx, "row bg target", tables.bg_col.row_bg_target, "RowBg0\0RowBg1\0")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Target RowBg0 to override the alternating odd/even colors,\n      Target RowBg1 to blend with them.")
      rv, tables.bg_col.cell_bg_type = ImGui.Combo(ctx, "cell bg type", tables.bg_col.cell_bg_type, "None\0Blue\0")
      ImGui.SameLine(ctx)
      demo.HelpMarker("We are colorizing cells to B1->C2 here.")
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table1", 5, tables.bg_col.flags) then
        for row = 0, 5 do
          ImGui.TableNextRow(ctx)
          if (tables.bg_col.row_bg_type ~= 0) then
            local row_bg_color = nil
            if (tables.bg_col.row_bg_type == 1) then
              row_bg_color = 3008187814
            else
              row_bg_color = 858993574
              row_bg_color = (row_bg_color + (demo.round(((row * 0.1) * 255)) << 24))
            end
            ImGui.TableSetBgColor(ctx, (ImGui.TableBgTarget_RowBg0() + tables.bg_col.row_bg_target), row_bg_color)
          else
          end
          for column = 0, 4 do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("%c%c"):format((string.byte("A") + row), (string.byte("0") + column)))
            if (((((row >= 1) and (row <= 2)) and (column >= 1)) and (column <= 2)) and (tables.bg_col.cell_bg_type == 1)) then
              ImGui.TableSetBgColor(ctx, ImGui.TableBgTarget_CellBg(), 1296937894)
            else
            end
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Tree view") then
      local flags = (ImGui.TableFlags_BordersV() | ImGui.TableFlags_BordersOuterH() | ImGui.TableFlags_Resizable() | ImGui.TableFlags_RowBg())
      if ImGui.BeginTable(ctx, "3ways", 3, flags) then
        ImGui.TableSetupColumn(ctx, "Name", ImGui.TableColumnFlags_NoHide())
        ImGui.TableSetupColumn(ctx, "Size", ImGui.TableColumnFlags_WidthFixed(), (TEXT_BASE_WIDTH * 12))
        ImGui.TableSetupColumn(ctx, "Type", ImGui.TableColumnFlags_WidthFixed(), (TEXT_BASE_WIDTH * 18))
        ImGui.TableHeadersRow(ctx)
        local nodes = {{child_count = 3, child_idx = 1, name = "Root", size = ( - 1), type = "Folder"}, {child_count = 2, child_idx = 4, name = "Music", size = ( - 1), type = "Folder"}, {child_count = 3, child_idx = 6, name = "Textures", size = ( - 1), type = "Folder"}, {child_count = ( - 1), child_idx = ( - 1), name = "desktop.ini", size = 1024, type = "System file"}, {child_count = ( - 1), child_idx = ( - 1), name = "File1_a.wav", size = 123000, type = "Audio file"}, {child_count = ( - 1), child_idx = ( - 1), name = "File1_b.wav", size = 456000, type = "Audio file"}, {child_count = ( - 1), child_idx = ( - 1), name = "Image001.png", size = 203128, type = "Image file"}, {child_count = ( - 1), child_idx = ( - 1), name = "Copy of Image001.png", size = 203256, type = "Image file"}, {child_count = ( - 1), child_idx = ( - 1), name = "Copy of Image001 (Final2).png", size = 203512, type = "Image file"}}
        local function Display_node(node)
          ImGui.TableNextRow(ctx)
          ImGui.TableNextColumn(ctx)
          local is_folder = (node.child_count > 0)
          if is_folder then
            local open = ImGui.TreeNode(ctx, node.name, ImGui.TreeNodeFlags_SpanFullWidth())
            ImGui.TableNextColumn(ctx)
            ImGui.TextDisabled(ctx, "--")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, node.type)
            if open then
              for child_n = 1, node.child_count do
                Display_node(nodes[(node.child_idx + child_n)])
              end
              return ImGui.TreePop(ctx)
            else
              return nil
            end
          else
            ImGui.TreeNode(ctx, node.name, (ImGui.TreeNodeFlags_Leaf() | ImGui.TreeNodeFlags_Bullet() | ImGui.TreeNodeFlags_NoTreePushOnOpen() | ImGui.TreeNodeFlags_SpanFullWidth()))
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("%d"):format(node.size))
            ImGui.TableNextColumn(ctx)
            return ImGui.Text(ctx, node.type)
          end
        end
        Display_node(nodes[1])
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Item width") then
      if not tables.item_width then
        tables.item_width = {dummy_d = 0}
      else
      end
      demo.HelpMarker("Showcase using PushItemWidth() and how it is preserved on a per-column basis.\n\n      Note that on auto-resizing non-resizable fixed columns, querying the content width for e.g. right-alignment doesn't make sense.")
      if ImGui.BeginTable(ctx, "table_item_width", 3, ImGui.TableFlags_Borders()) then
        ImGui.TableSetupColumn(ctx, "small")
        ImGui.TableSetupColumn(ctx, "half")
        ImGui.TableSetupColumn(ctx, "right-align")
        ImGui.TableHeadersRow(ctx)
        for row = 0, 2 do
          ImGui.TableNextRow(ctx)
          if (row == 0) then
            ImGui.TableSetColumnIndex(ctx, 0)
            ImGui.PushItemWidth(ctx, (TEXT_BASE_WIDTH * 3))
            ImGui.TableSetColumnIndex(ctx, 1)
            ImGui.PushItemWidth(ctx, (0 - (ImGui.GetContentRegionAvail(ctx) * 0.5)))
            ImGui.TableSetColumnIndex(ctx, 2)
            ImGui.PushItemWidth(ctx, ( - FLT_MIN))
          else
          end
          ImGui.PushID(ctx, row)
          ImGui.TableSetColumnIndex(ctx, 0)
          rv, tables.item_width.dummy_d = ImGui.SliderDouble(ctx, "double0", tables.item_width.dummy_d, 0, 1)
          ImGui.TableSetColumnIndex(ctx, 1)
          rv, tables.item_width.dummy_d = ImGui.SliderDouble(ctx, "double1", tables.item_width.dummy_d, 0, 1)
          ImGui.TableSetColumnIndex(ctx, 2)
          rv, tables.item_width.dummy_d = ImGui.SliderDouble(ctx, "##double2", tables.item_width.dummy_d, 0, 1)
          ImGui.PopID(ctx)
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Custom headers") then
      if not tables.headers then
        tables.headers = {column_selected = {false, false, false}}
      else
      end
      local COLUMNS_COUNT = 3
      if ImGui.BeginTable(ctx, "table_custom_headers", COLUMNS_COUNT, (ImGui.TableFlags_Borders() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable())) then
        ImGui.TableSetupColumn(ctx, "Apricot")
        ImGui.TableSetupColumn(ctx, "Banana")
        ImGui.TableSetupColumn(ctx, "Cherry")
        ImGui.TableNextRow(ctx, ImGui.TableRowFlags_Headers())
        for column = 0, (COLUMNS_COUNT - 1) do
          ImGui.TableSetColumnIndex(ctx, column)
          local column_name = ImGui.TableGetColumnName(ctx, column)
          ImGui.PushID(ctx, column)
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 0, 0)
          rv, cs1 = ImGui.Checkbox(ctx, "##checkall", tables.headers.column_selected[(column + 1)])
          do end (tables.headers.column_selected)[(column + 1)] = cs1
          ImGui.PopStyleVar(ctx)
          ImGui.SameLine(ctx, 0, ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing()))
          ImGui.TableHeader(ctx, column_name)
          ImGui.PopID(ctx)
        end
        for row = 0, 4 do
          ImGui.TableNextRow(ctx)
          for column = 0, 2 do
            local buf = ("Cell %d,%d"):format(column, row)
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Selectable(ctx, buf, tables.headers.column_selected[(column + 1)])
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Context menus") then
      if not tables.ctx_menus then
        tables.ctx_menus = {flags1 = (ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable() | ImGui.TableFlags_Borders() | ImGui.TableFlags_ContextMenuInBody())}
      else
      end
      demo.HelpMarker("By default, right-clicking over a TableHeadersRow()/TableHeader() line will open the default context-menu.\n      Using ImGuiTableFlags_ContextMenuInBody we also allow right-clicking over columns body.")
      demo.PushStyleCompact()
      rv, tables.ctx_menus.flags1 = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ContextMenuInBody", tables.ctx_menus.flags1, ImGui.TableFlags_ContextMenuInBody())
      demo.PopStyleCompact()
      local COLUMNS_COUNT = 3
      if ImGui.BeginTable(ctx, "table_context_menu", COLUMNS_COUNT, tables.ctx_menus.flags1) then
        ImGui.TableSetupColumn(ctx, "One")
        ImGui.TableSetupColumn(ctx, "Two")
        ImGui.TableSetupColumn(ctx, "Three")
        ImGui.TableHeadersRow(ctx)
        for row = 0, 3 do
          ImGui.TableNextRow(ctx)
          for column = 0, (COLUMNS_COUNT - 1) do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Cell %d,%d"):format(column, row))
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      demo.HelpMarker("Demonstrate mixing table context menu (over header), item context button (over button) and custom per-colum context menu (over column body).")
      local flags2 = (ImGui.TableFlags_Resizable() | ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable() | ImGui.TableFlags_Borders())
      if ImGui.BeginTable(ctx, "table_context_menu_2", COLUMNS_COUNT, flags2) then
        ImGui.TableSetupColumn(ctx, "One")
        ImGui.TableSetupColumn(ctx, "Two")
        ImGui.TableSetupColumn(ctx, "Three")
        ImGui.TableHeadersRow(ctx)
        for row = 0, 3 do
          ImGui.TableNextRow(ctx)
          for column = 0, (COLUMNS_COUNT - 1) do
            ImGui.TableSetColumnIndex(ctx, column)
            ImGui.Text(ctx, ("Cell %d,%d"):format(column, row))
            ImGui.SameLine(ctx)
            ImGui.PushID(ctx, ((row * COLUMNS_COUNT) + column))
            ImGui.SmallButton(ctx, "..")
            if ImGui.BeginPopupContextItem(ctx) then
              ImGui.Text(ctx, ("This is the popup for Button(\"..\") in Cell %d,%d"):format(column, row))
              if ImGui.Button(ctx, "Close") then
                ImGui.CloseCurrentPopup(ctx)
              else
              end
              ImGui.EndPopup(ctx)
            else
            end
            ImGui.PopID(ctx)
          end
        end
        local hovered_column = ( - 1)
        for column = 0, COLUMNS_COUNT do
          ImGui.PushID(ctx, column)
          if ((ImGui.TableGetColumnFlags(ctx, column) & ImGui.TableColumnFlags_IsHovered()) ~= 0) then
            hovered_column = column
          else
          end
          if (((hovered_column == column) and not ImGui.IsAnyItemHovered(ctx)) and ImGui.IsMouseReleased(ctx, 1)) then
            ImGui.OpenPopup(ctx, "MyPopup")
          else
          end
          if ImGui.BeginPopup(ctx, "MyPopup") then
            if (column == COLUMNS_COUNT) then
              ImGui.Text(ctx, "This is a custom popup for unused space after the last column.")
            else
              ImGui.Text(ctx, ("This is a custom popup for Column %d"):format(column))
            end
            if ImGui.Button(ctx, "Close") then
              ImGui.CloseCurrentPopup(ctx)
            else
            end
            ImGui.EndPopup(ctx)
          else
          end
          ImGui.PopID(ctx)
        end
        ImGui.EndTable(ctx)
        ImGui.Text(ctx, ("Hovered column: %d"):format(hovered_column))
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Synced instances") then
      if not tables.synced then
        tables.synced = {flags = (ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable() | ImGui.TableFlags_Borders() | ImGui.TableFlags_SizingFixedFit() | ImGui.TableFlags_NoSavedSettings())}
      else
      end
      demo.HelpMarker("Multiple tables with the same identifier will share their settings, width, visibility, order etc.")
      do
        local rv_945_, arg1_944_ = nil, nil
        do
          local arg1_944_0 = tables.synced.flags
          local _24 = arg1_944_0
          rv_945_, arg1_944_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollY", _24, ImGui.TableFlags_ScrollY())
        end
        tables.synced.flags = arg1_944_
      end
      do
        local rv_947_, arg1_946_ = nil, nil
        do
          local arg1_946_0 = tables.synced.flags
          local _24 = arg1_946_0
          rv_947_, arg1_946_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_SizingFixedFit", _24, ImGui.TableFlags_SizingFixedFit())
        end
        tables.synced.flags = arg1_946_
      end
      for n = 0, 2 do
        local buf = ("Synced Table %d"):format(n)
        local open = ImGui.CollapsingHeader(ctx, buf, nil, ImGui.TreeNodeFlags_DefaultOpen())
        if (open and ImGui.BeginTable(ctx, "Table", 3, tables.synced.flags, 0, (ImGui.GetTextLineHeightWithSpacing(ctx) * 5))) then
          ImGui.TableSetupColumn(ctx, "One")
          ImGui.TableSetupColumn(ctx, "Two")
          ImGui.TableSetupColumn(ctx, "Three")
          ImGui.TableHeadersRow(ctx)
          local cell_count = (((n == 1) and 27) or 9)
          for cell = 0, cell_count do
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("this cell %d"):format(cell))
          end
          ImGui.EndTable(ctx)
        else
        end
      end
      ImGui.TreePop(ctx)
    else
    end
    local template_items_names = {"Banana", "Apple", "Cherry", "Watermelon", "Grapefruit", "Strawberry", "Mango", "Kiwi", "Orange", "Pineapple", "Blueberry", "Plum", "Coconut", "Pear", "Apricot"}
    Do_open_action()
    if ImGui.TreeNode(ctx, "Sorting") then
      if not tables.sorting then
        tables.sorting = {flags = (ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable() | ImGui.TableFlags_Sortable() | ImGui.TableFlags_SortMulti() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_BordersV() | ImGui.TableFlags_ScrollY()), items = {}}
        for n = 0, 49 do
          local template_n = (n % #template_items_names)
          local item = {id = n, name = template_items_names[(template_n + 1)], quantity = (((n * n) - n) % 20)}
          table.insert(tables.sorting.items, item)
        end
      else
      end
      demo.PushStyleCompact()
      rv, tables.sorting.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_SortMulti", tables.sorting.flags, ImGui.TableFlags_SortMulti())
      ImGui.SameLine(ctx)
      demo.HelpMarker("When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
      rv, tables.sorting.flags = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_SortTristate", tables.sorting.flags, ImGui.TableFlags_SortTristate())
      ImGui.SameLine(ctx)
      demo.HelpMarker("When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
      demo.PopStyleCompact()
      if ImGui.BeginTable(ctx, "table_sorting", 4, tables.sorting.flags, 0, (TEXT_BASE_HEIGHT * 15), 0) then
        ImGui.TableSetupColumn(ctx, "ID", (ImGui.TableColumnFlags_DefaultSort() | ImGui.TableColumnFlags_WidthFixed()), 0, My_item_column_iD_ID)
        ImGui.TableSetupColumn(ctx, "Name", ImGui.TableColumnFlags_WidthFixed(), 0, My_item_column_iD_Name)
        ImGui.TableSetupColumn(ctx, "Action", (ImGui.TableColumnFlags_NoSort() | ImGui.TableColumnFlags_WidthFixed()), 0, __fnl_global__My_2ditem_2dcolumn_2diD_5fAction)
        ImGui.TableSetupColumn(ctx, "Quantity", (ImGui.TableColumnFlags_PreferSortDescending() | ImGui.TableColumnFlags_WidthStretch()), 0, My_item_column_iD_Quantity)
        ImGui.TableSetupScrollFreeze(ctx, 0, 1)
        ImGui.TableHeadersRow(ctx)
        if ImGui.TableNeedSort(ctx) then
          table.sort(tables.sorting.items, demo.CompareTableItems)
        else
        end
        local clipper = ImGui.CreateListClipper(ctx)
        ImGui.ListClipper_Begin(clipper, #tables.sorting.items)
        while ImGui.ListClipper_Step(clipper) do
          local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
          for row_n = display_start, (display_end - 1) do
            local item = tables.sorting.items[(row_n + 1)]
            ImGui.PushID(ctx, item.id)
            ImGui.TableNextRow(ctx)
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("%04d"):format(item.id))
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, item.name)
            ImGui.TableNextColumn(ctx)
            ImGui.SmallButton(ctx, "None")
            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, ("%d"):format(item.quantity))
            ImGui.PopID(ctx)
          end
        end
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    Do_open_action()
    if ImGui.TreeNode(ctx, "Advanced") then
      if not tables.advanced then
        tables.advanced = {contents_type = 5, flags = (ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() | ImGui.TableFlags_Hideable() | ImGui.TableFlags_Sortable() | ImGui.TableFlags_SortMulti() | ImGui.TableFlags_RowBg() | ImGui.TableFlags_Borders() | ImGui.TableFlags_ScrollX() | ImGui.TableFlags_ScrollY() | ImGui.TableFlags_SizingFixedFit()), freeze_cols = 1, freeze_rows = 1, inner_width_with_scroll = 0, items = {}, items_count = (#template_items_names * 2), outer_size_enabled = true, outer_size_value = {0, (TEXT_BASE_HEIGHT * 12)}, row_min_height = 0, show_headers = true, items_need_sort = false, show_wrapped_text = false}
      else
      end
      if ImGui.TreeNode(ctx, "Options") then
        demo.PushStyleCompact()
        ImGui.PushItemWidth(ctx, (TEXT_BASE_WIDTH * 28))
        if ImGui.TreeNode(ctx, "Features:", ImGui.TreeNodeFlags_DefaultOpen()) then
          do
            local rv_956_, arg1_955_ = nil, nil
            do
              local arg1_955_0 = tables.advanced.flags
              local _24 = arg1_955_0
              rv_956_, arg1_955_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Resizable", _24, ImGui.TableFlags_Resizable())
            end
            tables.advanced.flags = arg1_955_
          end
          do
            local rv_958_, arg1_957_ = nil, nil
            do
              local arg1_957_0 = tables.advanced.flags
              local _24 = arg1_957_0
              rv_958_, arg1_957_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Reorderable", _24, ImGui.TableFlags_Reorderable())
            end
            tables.advanced.flags = arg1_957_
          end
          do
            local rv_960_, arg1_959_ = nil, nil
            do
              local arg1_959_0 = tables.advanced.flags
              local _24 = arg1_959_0
              rv_960_, arg1_959_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Hideable", _24, ImGui.TableFlags_Hideable())
            end
            tables.advanced.flags = arg1_959_
          end
          do
            local rv_962_, arg1_961_ = nil, nil
            do
              local arg1_961_0 = tables.advanced.flags
              local _24 = arg1_961_0
              rv_962_, arg1_961_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_Sortable", _24, ImGui.TableFlags_Sortable())
            end
            tables.advanced.flags = arg1_961_
          end
          do
            local rv_964_, arg1_963_ = nil, nil
            do
              local arg1_963_0 = tables.advanced.flags
              local _24 = arg1_963_0
              rv_964_, arg1_963_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoSavedSettings", _24, ImGui.TableFlags_NoSavedSettings())
            end
            tables.advanced.flags = arg1_963_
          end
          do
            local rv_966_, arg1_965_ = nil, nil
            do
              local arg1_965_0 = tables.advanced.flags
              local _24 = arg1_965_0
              rv_966_, arg1_965_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ContextMenuInBody", _24, ImGui.TableFlags_ContextMenuInBody())
            end
            tables.advanced.flags = arg1_965_
          end
          ImGui.TreePop(ctx)
        else
        end
        if ImGui.TreeNode(ctx, "Decorations:", ImGui.TreeNodeFlags_DefaultOpen()) then
          do
            local rv_969_, arg1_968_ = nil, nil
            do
              local arg1_968_0 = tables.advanced.flags
              local _24 = arg1_968_0
              rv_969_, arg1_968_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_RowBg", _24, ImGui.TableFlags_RowBg())
            end
            tables.advanced.flags = arg1_968_
          end
          do
            local rv_971_, arg1_970_ = nil, nil
            do
              local arg1_970_0 = tables.advanced.flags
              local _24 = arg1_970_0
              rv_971_, arg1_970_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersV", _24, ImGui.TableFlags_BordersV())
            end
            tables.advanced.flags = arg1_970_
          end
          do
            local rv_973_, arg1_972_ = nil, nil
            do
              local arg1_972_0 = tables.advanced.flags
              local _24 = arg1_972_0
              rv_973_, arg1_972_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuterV", _24, ImGui.TableFlags_BordersOuterV())
            end
            tables.advanced.flags = arg1_972_
          end
          do
            local rv_975_, arg1_974_ = nil, nil
            do
              local arg1_974_0 = tables.advanced.flags
              local _24 = arg1_974_0
              rv_975_, arg1_974_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInnerV", _24, ImGui.TableFlags_BordersInnerV())
            end
            tables.advanced.flags = arg1_974_
          end
          do
            local rv_977_, arg1_976_ = nil, nil
            do
              local arg1_976_0 = tables.advanced.flags
              local _24 = arg1_976_0
              rv_977_, arg1_976_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersH", _24, ImGui.TableFlags_BordersH())
            end
            tables.advanced.flags = arg1_976_
          end
          do
            local rv_979_, arg1_978_ = nil, nil
            do
              local arg1_978_0 = tables.advanced.flags
              local _24 = arg1_978_0
              rv_979_, arg1_978_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersOuterH", _24, ImGui.TableFlags_BordersOuterH())
            end
            tables.advanced.flags = arg1_978_
          end
          do
            local rv_981_, arg1_980_ = nil, nil
            do
              local arg1_980_0 = tables.advanced.flags
              local _24 = arg1_980_0
              rv_981_, arg1_980_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_BordersInnerH", _24, ImGui.TableFlags_BordersInnerH())
            end
            tables.advanced.flags = arg1_980_
          end
          ImGui.TreePop(ctx)
        else
        end
        if ImGui.TreeNode(ctx, "Sizing:", ImGui.TreeNodeFlags_DefaultOpen()) then
          tables.advanced.flags = demo.EditTableSizingFlags(tables.advanced.flags)
          ImGui.SameLine(ctx)
          demo.HelpMarker("In the Advanced demo we override the policy of each column so those table-wide settings have less effect that typical.")
          do
            local rv_984_, arg1_983_ = nil, nil
            do
              local arg1_983_0 = tables.advanced.flags
              local _24 = arg1_983_0
              rv_984_, arg1_983_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoHostExtendX", _24, ImGui.TableFlags_NoHostExtendX())
            end
            tables.advanced.flags = arg1_983_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("Make outer width auto-fit to columns, overriding outer_size.x value.\n\n          Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
          do
            local rv_986_, arg1_985_ = nil, nil
            do
              local arg1_985_0 = tables.advanced.flags
              local _24 = arg1_985_0
              rv_986_, arg1_985_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoHostExtendY", _24, ImGui.TableFlags_NoHostExtendY())
            end
            tables.advanced.flags = arg1_985_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).\n\n          Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
          do
            local rv_988_, arg1_987_ = nil, nil
            do
              local arg1_987_0 = tables.advanced.flags
              local _24 = arg1_987_0
              rv_988_, arg1_987_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoKeepColumnsVisible", _24, ImGui.TableFlags_NoKeepColumnsVisible())
            end
            tables.advanced.flags = arg1_987_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("Only available if ScrollX is disabled.")
          do
            local rv_990_, arg1_989_ = nil, nil
            do
              local arg1_989_0 = tables.advanced.flags
              local _24 = arg1_989_0
              rv_990_, arg1_989_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_PreciseWidths", _24, ImGui.TableFlags_PreciseWidths())
            end
            tables.advanced.flags = arg1_989_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
          do
            local rv_992_, arg1_991_ = nil, nil
            do
              local arg1_991_0 = tables.advanced.flags
              local _24 = arg1_991_0
              rv_992_, arg1_991_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoClip", _24, ImGui.TableFlags_NoClip())
            end
            tables.advanced.flags = arg1_991_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ScrollFreeze options.")
          ImGui.TreePop(ctx)
        else
        end
        if ImGui.TreeNode(ctx, "Padding:", ImGui.TreeNodeFlags_DefaultOpen()) then
          do
            local rv_995_, arg1_994_ = nil, nil
            do
              local arg1_994_0 = tables.advanced.flags
              local _24 = arg1_994_0
              rv_995_, arg1_994_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_PadOuterX", _24, ImGui.TableFlags_PadOuterX())
            end
            tables.advanced.flags = arg1_994_
          end
          do
            local rv_997_, arg1_996_ = nil, nil
            do
              local arg1_996_0 = tables.advanced.flags
              local _24 = arg1_996_0
              rv_997_, arg1_996_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoPadOuterX", _24, ImGui.TableFlags_NoPadOuterX())
            end
            tables.advanced.flags = arg1_996_
          end
          do
            local rv_999_, arg1_998_ = nil, nil
            do
              local arg1_998_0 = tables.advanced.flags
              local _24 = arg1_998_0
              rv_999_, arg1_998_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_NoPadInnerX", _24, ImGui.TableFlags_NoPadInnerX())
            end
            tables.advanced.flags = arg1_998_
          end
          ImGui.TreePop(ctx)
        else
        end
        if ImGui.TreeNode(ctx, "Scrolling:", ImGui.TreeNodeFlags_DefaultOpen()) then
          do
            local rv_1002_, arg1_1001_ = nil, nil
            do
              local arg1_1001_0 = tables.advanced.flags
              local _24 = arg1_1001_0
              rv_1002_, arg1_1001_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollX", _24, ImGui.TableFlags_ScrollX())
            end
            tables.advanced.flags = arg1_1001_
          end
          ImGui.SameLine(ctx)
          ImGui.SetNextItemWidth(ctx, ImGui.GetFrameHeight(ctx))
          do
            local rv_1004_, arg1_1003_ = nil, nil
            do
              local arg1_1003_0 = tables.advanced.freeze_cols
              local _24 = arg1_1003_0
              rv_1004_, arg1_1003_ = ImGui.DragInt(ctx, "freeze_cols", _24, 0.2, 0, 9, nil, ImGui.SliderFlags_NoInput())
            end
            tables.advanced.freeze_cols = arg1_1003_
          end
          do
            local rv_1006_, arg1_1005_ = nil, nil
            do
              local arg1_1005_0 = tables.advanced.flags
              local _24 = arg1_1005_0
              rv_1006_, arg1_1005_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_ScrollY", _24, ImGui.TableFlags_ScrollY())
            end
            tables.advanced.flags = arg1_1005_
          end
          ImGui.SameLine(ctx)
          ImGui.SetNextItemWidth(ctx, ImGui.GetFrameHeight(ctx))
          rv, tables.advanced.freeze_rows = ImGui.DragInt(ctx, "freeze_rows", tables.advanced.freeze_rows, 0.2, 0, 9, nil, ImGui.SliderFlags_NoInput())
          ImGui.TreePop(ctx)
        else
        end
        if ImGui.TreeNode(ctx, "Sorting:", ImGui.TreeNodeFlags_DefaultOpen()) then
          do
            local rv_1009_, arg1_1008_ = nil, nil
            do
              local arg1_1008_0 = tables.advanced.flags
              local _24 = arg1_1008_0
              rv_1009_, arg1_1008_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_SortMulti", _24, ImGui.TableFlags_SortMulti())
            end
            tables.advanced.flags = arg1_1008_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
          do
            local rv_1011_, arg1_1010_ = nil, nil
            do
              local arg1_1010_0 = tables.advanced.flags
              local _24 = arg1_1010_0
              rv_1011_, arg1_1010_ = ImGui.CheckboxFlags(ctx, "ImGuiTableFlags_SortTristate", _24, ImGui.TableFlags_SortTristate())
            end
            tables.advanced.flags = arg1_1010_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
          ImGui.TreePop(ctx)
        else
        end
        if ImGui.TreeNode(ctx, "Other:", ImGui.TreeNodeFlags_DefaultOpen()) then
          do
            local rv_1014_, arg1_1013_ = nil, nil
            do
              local arg1_1013_0 = tables.advanced.show_headers
              local _24 = arg1_1013_0
              rv_1014_, arg1_1013_ = ImGui.Checkbox(ctx, "show_headers", _24)
            end
            tables.advanced.show_headers = arg1_1013_
          end
          do
            local rv_1016_, arg1_1015_ = nil, nil
            do
              local arg1_1015_0 = tables.advanced.show_wrapped_text
              local _24 = arg1_1015_0
              rv_1016_, arg1_1015_ = ImGui.Checkbox(ctx, "show_wrapped_text", _24)
            end
            tables.advanced.show_wrapped_text = arg1_1015_
          end
          rv, osv1, osv2 = ImGui.DragDouble2(ctx, "##OuterSize", table.unpack(tables.advanced.outer_size_value))
          do end (tables.advanced.outer_size_value)[1] = osv1
          tables.advanced.outer_size_value[2] = osv2
          ImGui.SameLine(ctx, 0, ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing()))
          do
            local rv_1018_, arg1_1017_ = nil, nil
            do
              local arg1_1017_0 = tables.advanced.outer_size_enabled
              local _24 = arg1_1017_0
              rv_1018_, arg1_1017_ = ImGui.Checkbox(ctx, "outer_size", _24)
            end
            tables.advanced.outer_size_enabled = arg1_1017_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("If scrolling is disabled (ScrollX and ScrollY not set):\n      - The table is output directly in the parent window.\n      - OuterSize.x < 0.0 will right-align the table.\n      - OuterSize.x = 0.0 will narrow fit the table unless there are any Stretch columns.\n      - OuterSize.y then becomes the minimum size for the table, which will extend vertically if there are more rows (unless NoHostExtendY is set).")
          do
            local rv_1020_, arg1_1019_ = nil, nil
            do
              local arg1_1019_0 = tables.advanced.inner_width_with_scroll
              local _24 = arg1_1019_0
              rv_1020_, arg1_1019_ = ImGui.DragDouble(ctx, "inner_width (when ScrollX active)", _24, 1, 0, FLT_MAX)
            end
            tables.advanced.inner_width_with_scroll = arg1_1019_
          end
          do
            local rv_1022_, arg1_1021_ = nil, nil
            do
              local arg1_1021_0 = tables.advanced.row_min_height
              local _24 = arg1_1021_0
              rv_1022_, arg1_1021_ = ImGui.DragDouble(ctx, "row_min_height", _24, 1, 0, FLT_MAX)
            end
            tables.advanced.row_min_height = arg1_1021_
          end
          ImGui.SameLine(ctx)
          demo.HelpMarker("Specify height of the Selectable item.")
          do
            local rv_1024_, arg1_1023_ = nil, nil
            do
              local arg1_1023_0 = tables.advanced.items_count
              local _24 = arg1_1023_0
              rv_1024_, arg1_1023_ = ImGui.DragInt(ctx, "items_count", _24, 0.1, 0, 9999)
            end
            tables.advanced.items_count = arg1_1023_
          end
          do
            local rv_1026_, arg1_1025_ = nil, nil
            do
              local arg1_1025_0 = tables.advanced.contents_type
              local _24 = arg1_1025_0
              rv_1026_, arg1_1025_ = ImGui.Combo(ctx, "items_type (first column)", _24, "Text\0Button\0SmallButton\0FillButton\0Selectable\0Selectable (span row)\0")
            end
            tables.advanced.contents_type = arg1_1025_
          end
          ImGui.TreePop(ctx)
        else
        end
        ImGui.PopItemWidth(ctx)
        demo.PopStyleCompact()
        ImGui.Spacing(ctx)
        ImGui.TreePop(ctx)
      else
      end
      if (#tables.advanced.items ~= tables.advanced.items_count) then
        tables.advanced.items = {}
        for n = 0, (tables.advanced.items_count - 1) do
          local template_n = (n % #template_items_names)
          local item = {id = n, name = template_items_names[(template_n + 1)], quantity = (((template_n == 3) and 10) or (((template_n == 4) and 20) or 0))}
          table.insert(tables.advanced.items, item)
        end
      else
      end
      local inner_width_to_use
      local function _1030_()
        if ((tables.advanced.flags & ImGui.TableFlags_ScrollX()) ~= 0) then
          return tables.advanced.inner_width_with_scroll
        else
          return nil
        end
      end
      inner_width_to_use = (_1030_() or 0)
      local w, h = 0, 0
      if tables.advanced.outer_size_enabled then
        w, h = table.unpack(tables.advanced.outer_size_value)
      else
      end
      if ImGui.BeginTable(ctx, "table_advanced", 6, tables.advanced.flags, w, h, inner_width_to_use) then
        ImGui.TableSetupColumn(ctx, "ID", (ImGui.TableColumnFlags_DefaultSort() | ImGui.TableColumnFlags_WidthFixed() | ImGui.TableColumnFlags_NoHide()), 0, My_item_column_iD_ID)
        ImGui.TableSetupColumn(ctx, "Name", ImGui.TableColumnFlags_WidthFixed(), 0, My_item_column_iD_Name)
        ImGui.TableSetupColumn(ctx, "Action", (ImGui.TableColumnFlags_NoSort() | ImGui.TableColumnFlags_WidthFixed()), 0, __fnl_global__My_2ditem_2dcolumn_2diD_5fAction)
        ImGui.TableSetupColumn(ctx, "Quantity", ImGui.TableColumnFlags_PreferSortDescending(), 0, My_item_column_iD_Quantity)
        ImGui.TableSetupColumn(ctx, "Description", ((((tables.advanced.flags & ImGui.TableFlags_NoHostExtendX()) ~= 0) and 0) or ImGui.TableColumnFlags_WidthStretch()), 0, My_item_column_iD_Description)
        ImGui.TableSetupColumn(ctx, "Hidden", (ImGui.TableColumnFlags_DefaultHide() | ImGui.TableColumnFlags_NoSort()))
        ImGui.TableSetupScrollFreeze(ctx, tables.advanced.freeze_cols, tables.advanced.freeze_rows)
        local specs_dirty, has_specs = ImGui.TableNeedSort(ctx)
        if (has_specs and (specs_dirty or tables.advanced.items_need_sort)) then
          table.sort(tables.advanced.items, demo.CompareTableItems)
          tables.advanced.items_need_sort = false
        else
        end
        local sorts_specs_using_quantity = ((ImGui.TableGetColumnFlags(ctx, 3) & ImGui.TableColumnFlags_IsSorted()) ~= 0)
        if tables.advanced.show_headers then
          ImGui.TableHeadersRow(ctx)
        else
        end
        ImGui.PushButtonRepeat(ctx, true)
        local clipper = ImGui.CreateListClipper(ctx)
        ImGui.ListClipper_Begin(clipper, #tables.advanced.items)
        while ImGui.ListClipper_Step(clipper) do
          local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
          for row_n = display_start, (display_end - 1) do
            local item = tables.advanced.items[(row_n + 1)]
            ImGui.PushID(ctx, item.id)
            ImGui.TableNextRow(ctx, ImGui.TableRowFlags_None(), tables.advanced.row_min_height)
            ImGui.TableSetColumnIndex(ctx, 0)
            local label = ("%04d"):format(item.id)
            local contents_type = tables.advanced.contents_type
            if (contents_type == 0) then
              ImGui.Text(ctx, label)
            elseif (contents_type == 1) then
              ImGui.Button(ctx, label)
            elseif (contents_type == 2) then
              ImGui.SmallButton(ctx, label)
            elseif (contents_type == 3) then
              ImGui.Button(ctx, label, ( - FLT_MIN), 0)
            elseif ((contents_type == 4) or (contents_type == 5)) then
              local selectable_flags = (((contents_type == 5) and (ImGui.SelectableFlags_SpanAllColumns() | ImGui.SelectableFlags_AllowItemOverlap())) or ImGui.SelectableFlags_None())
              if ImGui.Selectable(ctx, label, item.is_selected, selectable_flags, 0, tables.advanced.row_min_height) then
                if ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl()) then
                  item.is_selected = not item.is_selected
                else
                  for _, it in ipairs(tables.advanced.items) do
                    it.is_selected = (it == item)
                  end
                end
              else
              end
            else
            end
            if ImGui.TableSetColumnIndex(ctx, 1) then
              ImGui.Text(ctx, item.name)
            else
            end
            if ImGui.TableSetColumnIndex(ctx, 2) then
              if ImGui.SmallButton(ctx, "Chop") then
                item.quantity = (item.quantity + 1)
              else
              end
              if (sorts_specs_using_quantity and ImGui.IsItemDeactivated(ctx)) then
                tables.advanced.items_need_sort = true
              else
              end
              ImGui.SameLine(ctx)
              if ImGui.SmallButton(ctx, "Eat") then
                item.quantity = (item.quantity - 1)
              else
              end
              if (sorts_specs_using_quantity and ImGui.IsItemDeactivated(ctx)) then
                tables.advanced.items_need_sort = true
              else
              end
            else
            end
            if ImGui.TableSetColumnIndex(ctx, 3) then
              ImGui.Text(ctx, ("%d"):format(item.quantity))
            else
            end
            ImGui.TableSetColumnIndex(ctx, 4)
            if tables.advanced.show_wrapped_text then
              ImGui.TextWrapped(ctx, "Lorem ipsum dolor sit amet")
            else
              ImGui.Text(ctx, "Lorem ipsum dolor sit amet")
            end
            if ImGui.TableSetColumnIndex(ctx, 5) then
              ImGui.Text(ctx, "1234")
            else
            end
            ImGui.PopID(ctx)
          end
        end
        ImGui.PopButtonRepeat(ctx)
        ImGui.EndTable(ctx)
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    ImGui.PopID(ctx)
    if tables.disable_indent then
      return ImGui.PopStyleVar(ctx)
    else
      return nil
    end
  else
    return nil
  end
end
demo.ShowDemoWindowInputs = function()
  local rv = nil
  if ImGui.CollapsingHeader(ctx, "Inputs & Focus") then
    ImGui.SetNextItemOpen(ctx, true, ImGui.Cond_Once())
    if ImGui.TreeNode(ctx, "Inputs") then
      demo.HelpMarker("This is a simplified view. See more detailed input state:\n- in 'Tools->Metrics/Debugger->Inputs'.\n- in 'Tools->Debug Log->IO'.")
      if ImGui.IsMousePosValid(ctx) then
        ImGui.Text(ctx, ("Mouse pos: (%g, %g)"):format(ImGui.GetMousePos(ctx)))
      else
        ImGui.Text(ctx, "Mouse pos: <INVALID>")
      end
      ImGui.Text(ctx, ("Mouse delta: (%g, %g)"):format(ImGui.GetMouseDelta(ctx)))
      local buttons = 4
      ImGui.Text(ctx, "Mouse down:")
      for button = 0, buttons do
        if ImGui.IsMouseDown(ctx, button) then
          local duration = ImGui.GetMouseDownDuration(ctx, button)
          ImGui.SameLine(ctx)
          ImGui.Text(ctx, ("b%d (%.02f secs)"):format(button, duration))
        else
        end
      end
      ImGui.Text(ctx, ("Mouse wheel: %.1f %.1f"):format(ImGui.GetMouseWheel(ctx)))
      ImGui.Text(ctx, "Keys down:")
      for key, name in demo.EachEnum("Key") do
        if ImGui.IsKeyDown(ctx, key) then
          local duration = ImGui.GetKeyDownDuration(ctx, key)
          ImGui.SameLine(ctx)
          ImGui.Text(ctx, ("\"%s\" %d (%.02f secs)"):format(name, key, duration))
        else
        end
      end
      ImGui.Text(ctx, ("Keys mods: %s%s%s%s"):format(((ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl()) and "CTRL ") or ""), ((ImGui.IsKeyDown(ctx, ImGui.Mod_Shift()) and "SHIFT ") or ""), ((ImGui.IsKeyDown(ctx, ImGui.Mod_Alt()) and "ALT ") or ""), ((ImGui.IsKeyDown(ctx, ImGui.Mod_Super()) and "SUPER ") or "")))
      ImGui.Text(ctx, "Chars queue:")
      for next_id = 0, math.huge do
        local rv0, c = ImGui.GetInputQueueCharacter(ctx, next_id)
        if not rv0 then
          break
        else
        end
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, ("'%s' (0x%04X)"):format(utf8.char(c), c))
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "WantCapture override") then
      if not misc.capture_override then
        misc.capture_override = {keyboard = ( - 1), mouse = ( - 1)}
      else
      end
      demo.HelpMarker("SetNextFrameWantCaptureXXX instructs ReaImGui how to route inputs.\n\nCapturing the keyboard allows receiving input from REAPER's global scope.\n\nHovering the colored canvas will call SetNextFrameWantCaptureXXX.")
      local capture_override_desc = {"None", "Set to false", "Set to true"}
      ImGui.SetNextItemWidth(ctx, (ImGui.GetFontSize(ctx) * 15))
      do
        local rv_1058_, arg1_1057_ = nil, nil
        do
          local arg1_1057_0 = misc.capture_override.keyboard
          local _24 = arg1_1057_0
          rv_1058_, arg1_1057_ = ImGui.SliderInt(ctx, "SetNextFrameWantCaptureKeyboard() on hover", _24, ( - 1), 1, capture_override_desc[(_24 + 2)], ImGui.SliderFlags_AlwaysClamp())
        end
        misc.capture_override.keyboard = arg1_1057_
      end
      ImGui.ColorButton(ctx, "##panel", 2988028671, (ImGui.ColorEditFlags_NoTooltip() | ImGui.ColorEditFlags_NoDragDrop()), 128, 96)
      if (ImGui.IsItemHovered(ctx) and (misc.capture_override.keyboard ~= -1)) then
        ImGui.SetNextFrameWantCaptureKeyboard(ctx, (1 == misc.capture_override.keyboard))
      else
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Mouse Cursors") then
      do
        local current = ImGui.GetMouseCursor(ctx)
        for cursor, name in demo.EachEnum("MouseCursor") do
          if (cursor == current) then
            ImGui.Text(ctx, ("Current mouse cursor = %d: %s"):format(current, name))
            break
          else
          end
        end
      end
      ImGui.Text(ctx, "Hover to see mouse cursors:")
      for i, name in demo.EachEnum("MouseCursor") do
        local label = ("Mouse cursor %d: %s"):format(i, name)
        ImGui.Bullet(ctx)
        ImGui.Selectable(ctx, label, false)
        if ImGui.IsItemHovered(ctx) then
          ImGui.SetMouseCursor(ctx, i)
        else
        end
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Tabbing") then
      if not misc.tabbing then
        misc.tabbing = {buf = "hello"}
      else
      end
      ImGui.Text(ctx, "Use TAB/SHIFT+TAB to cycle through keyboard editable fields.")
      do
        local rv_1066_, arg1_1065_ = nil, nil
        do
          local arg1_1065_0 = misc.tabbing.buf
          local _24 = arg1_1065_0
          rv_1066_, arg1_1065_ = ImGui.InputText(ctx, "1", _24)
        end
        misc.tabbing.buf = arg1_1065_
      end
      do
        local rv_1068_, arg1_1067_ = nil, nil
        do
          local arg1_1067_0 = misc.tabbing.buf
          local _24 = arg1_1067_0
          rv_1068_, arg1_1067_ = ImGui.InputText(ctx, "2", _24)
        end
        misc.tabbing.buf = arg1_1067_
      end
      do
        local rv_1070_, arg1_1069_ = nil, nil
        do
          local arg1_1069_0 = misc.tabbing.buf
          local _24 = arg1_1069_0
          rv_1070_, arg1_1069_ = ImGui.InputText(ctx, "3", _24)
        end
        misc.tabbing.buf = arg1_1069_
      end
      ImGui.PushAllowKeyboardFocus(ctx, false)
      do
        local rv_1072_, arg1_1071_ = nil, nil
        do
          local arg1_1071_0 = misc.tabbing.buf
          local _24 = arg1_1071_0
          rv_1072_, arg1_1071_ = ImGui.InputText(ctx, "4 (tab skip)", _24)
        end
        misc.tabbing.buf = arg1_1071_
      end
      ImGui.SameLine(ctx)
      demo.HelpMarker("Item won't be cycled through when using TAB or Shift+Tab.")
      ImGui.PopAllowKeyboardFocus(ctx)
      do
        local rv_1074_, arg1_1073_ = nil, nil
        do
          local arg1_1073_0 = misc.tabbing.buf
          local _24 = arg1_1073_0
          rv_1074_, arg1_1073_ = ImGui.InputText(ctx, "5", _24)
        end
        misc.tabbing.buf = arg1_1073_
      end
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Focus from code") then
      if not misc.focus then
        misc.focus = {buf = "click on a button to set focus", d3 = {0, 0, 0}}
      else
      end
      local focus_1 = ImGui.Button(ctx, "Focus on 1")
      ImGui.SameLine(ctx)
      local focus_2 = ImGui.Button(ctx, "Focus on 2")
      ImGui.SameLine(ctx)
      local focus_3 = ImGui.Button(ctx, "Focus on 3")
      local has_focus = 0
      if focus_1 then
        ImGui.SetKeyboardFocusHere(ctx)
      else
      end
      do
        local rv_1079_, arg1_1078_ = nil, nil
        do
          local arg1_1078_0 = misc.focus.buf
          local _24 = arg1_1078_0
          rv_1079_, arg1_1078_ = ImGui.InputText(ctx, "1", _24)
        end
        misc.focus.buf = arg1_1078_
      end
      if ImGui.IsItemActive(ctx) then
        has_focus = 1
      else
      end
      if focus_2 then
        ImGui.SetKeyboardFocusHere(ctx)
      else
      end
      do
        local rv_1083_, arg1_1082_ = nil, nil
        do
          local arg1_1082_0 = misc.focus.buf
          local _24 = arg1_1082_0
          rv_1083_, arg1_1082_ = ImGui.InputText(ctx, "2", _24)
        end
        misc.focus.buf = arg1_1082_
      end
      if ImGui.IsItemActive(ctx) then
        has_focus = 2
      else
      end
      ImGui.PushAllowKeyboardFocus(ctx, false)
      if focus_3 then
        ImGui.SetKeyboardFocusHere(ctx)
      else
      end
      do
        local rv_1087_, arg1_1086_ = nil, nil
        do
          local arg1_1086_0 = misc.focus.buf
          local _24 = arg1_1086_0
          rv_1087_, arg1_1086_ = ImGui.InputText(ctx, "3 (tab skip)", _24)
        end
        misc.focus.buf = arg1_1086_
      end
      if ImGui.IsItemActive(ctx) then
        has_focus = 3
      else
      end
      ImGui.SameLine(ctx)
      demo.HelpMarker("Item won't be cycled through when using TAB or Shift+Tab.")
      ImGui.PopAllowKeyboardFocus(ctx)
      if (has_focus > 0) then
        ImGui.Text(ctx, ("Item with focus: %d"):format(has_focus))
      else
        ImGui.Text(ctx, "Item with focus: <none>")
      end
      local focus_ahead = -1
      if ImGui.Button(ctx, "Focus on X") then
        focus_ahead = 0
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, "Focus on Y") then
        focus_ahead = 1
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, "Focus on Z") then
        focus_ahead = 2
      else
      end
      if (-1 ~= focus_ahead) then
        ImGui.SetKeyboardFocusHere(ctx, focus_ahead)
      else
      end
      rv, d31, d32, d33 = ImGui.SliderDouble3(ctx, "Float3", (misc.focus.d3)[1], (misc.focus.d3)[2], (misc.focus.d3)[3], 0, 1)
      do end (misc.focus.d3)[1] = d31
      misc.focus.d3[2] = d32
      misc.focus.d3[3] = d33
      ImGui.TextWrapped(ctx, "NB: Cursor & selection are preserved when refocusing last used item in code.")
      ImGui.TreePop(ctx)
    else
    end
    if ImGui.TreeNode(ctx, "Dragging") then
      ImGui.TextWrapped(ctx, "You can use GetMouseDragDelta(0) to query for the dragged amount on any widget.")
      for button = 0, 2 do
        ImGui.Text(ctx, ("IsMouseDragging(%d):"):format(button))
        ImGui.Text(ctx, ("  w/ default threshold: %s,"):format(ImGui.IsMouseDragging(ctx, button)))
        ImGui.Text(ctx, ("  w/ zero threshold: %s,"):format(ImGui.IsMouseDragging(ctx, button, 0)))
        ImGui.Text(ctx, ("  w/ large threshold: %s,"):format(ImGui.IsMouseDragging(ctx, button, 20)))
      end
      ImGui.Button(ctx, "Drag Me")
      if ImGui.IsItemActive(ctx) then
        local draw_list = ImGui.GetForegroundDrawList(ctx)
        local mouse_pos = {ImGui.GetMousePos(ctx)}
        local click_pos = {ImGui.GetMouseClickedPos(ctx, 0)}
        local color = ImGui.GetColor(ctx, ImGui.Col_Button())
        ImGui.DrawList_AddLine(draw_list, click_pos[1], click_pos[2], mouse_pos[1], mouse_pos[2], color, 4)
      else
      end
      local value_raw = {ImGui.GetMouseDragDelta(ctx, 0, 0, ImGui.MouseButton_Left(), 0)}
      local value_with_lock_threshold = {ImGui.GetMouseDragDelta(ctx, 0, 0, ImGui.MouseButton_Left())}
      local mouse_delta = {ImGui.GetMouseDelta(ctx)}
      ImGui.Text(ctx, "GetMouseDragDelta(0):")
      ImGui.Text(ctx, ("  w/ default threshold: (%.1f, %.1f)"):format(table.unpack(value_with_lock_threshold)))
      ImGui.Text(ctx, ("  w/ zero threshold: (%.1f, %.1f)"):format(table.unpack(value_raw)))
      ImGui.Text(ctx, ("GetMouseDelta() (%.1f, %.1f)"):format(table.unpack(mouse_delta)))
      return ImGui.TreePop(ctx)
    else
      return nil
    end
  else
    return nil
  end
end
demo.GetStyleData = function()
  local data = {colors = {}, vars = {}}
  local vec2 = {"ButtonTextAlign", "SelectableTextAlign", "CellPadding", "ItemSpacing", "ItemInnerSpacing", "FramePadding", "WindowPadding", "WindowMinSize", "WindowTitleAlign", "SeparatorTextAlign", "SeparatorTextPadding"}
  for i, name in demo.EachEnum("StyleVar") do
    local rv = {ImGui.GetStyleVar(ctx, i)}
    local is_vec2 = false
    for _, vec2_name in ipairs(vec2) do
      if (vec2_name == name) then
        is_vec2 = true
        break
      else
      end
    end
    local _1099_
    if is_vec2 then
      _1099_ = rv
    else
      _1099_ = rv[1]
    end
    data.vars[i] = _1099_
  end
  for i in demo.EachEnum("Col") do
    data.colors[i] = ImGui.GetStyleColor(ctx, i)
  end
  return data
end
demo.CopyStyleData = function(source, target)
  for i, value in pairs(source.vars) do
    local _1101_
    if (type(value) == "table") then
      _1101_ = {table.unpack(value)}
    else
      _1101_ = value
    end
    target.vars[i] = _1101_
  end
  for i, value in pairs(source.colors) do
    target.colors[i] = value
  end
  return nil
end
demo.PushStyle = function()
  if app.style_editor then
    app.style_editor.push_count = (app.style_editor.push_count + 1)
    for i, value in pairs(app.style_editor.style.vars) do
      local function _1103_()
        if ("table" == type(value)) then
          return table.unpack(value)
        else
          return value
        end
      end
      ImGui.PushStyleVar(ctx, i, _1103_())
    end
    for i, value in pairs(app.style_editor.style.colors) do
      ImGui.PushStyleColor(ctx, i, value)
    end
    return nil
  else
    return nil
  end
end
demo.PopStyle = function()
  if (app.style_editor and (app.style_editor.push_count > 0)) then
    app.style_editor.push_count = (app.style_editor.push_count - 1)
    ImGui.PopStyleColor(ctx, #cache.Col)
    return ImGui.PopStyleVar(ctx, #cache.StyleVar)
  else
    return nil
  end
end
demo.ShowStyleEditor = function()
  local rv = nil
  if not app.style_editor then
    app.style_editor = {output_dest = 0, output_only_modified = true, push_count = 0, ref = demo.GetStyleData(), style = demo.GetStyleData()}
  else
  end
  ImGui.PushItemWidth(ctx, (ImGui.GetWindowWidth(ctx) * 0.5))
  local Frame_rounding, Grab_rounding = ImGui.StyleVar_FrameRounding(), ImGui.StyleVar_GrabRounding()
  rv, vfr = ImGui.SliderDouble(ctx, "FrameRounding", app.style_editor.style.vars[Frame_rounding], 0, 12, "%.0f")
  do end (app.style_editor.style.vars)[Frame_rounding] = vfr
  if rv then
    app.style_editor.style.vars[Grab_rounding] = app.style_editor.style.vars[Frame_rounding]
  else
  end
  local borders = {"WindowBorder", "FrameBorder", "PopupBorder"}
  for i, name in ipairs(borders) do
    local ___var___ = ImGui[("StyleVar_%sSize"):format(name)]()
    local enable = (app.style_editor.style.vars[___var___] > 0)
    if (i > 1) then
      ImGui.SameLine(ctx)
    else
    end
    rv, enable = ImGui.Checkbox(ctx, name, enable)
    if rv then
      app.style_editor.style.vars[___var___] = ((enable and 1) or 0)
    else
    end
  end
  if ImGui.Button(ctx, "Save Ref") then
    demo.CopyStyleData(app.style_editor.style, app.style_editor.ref)
  else
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, "Revert Ref") then
    demo.CopyStyleData(app.style_editor.ref, app.style_editor.style)
  else
  end
  ImGui.SameLine(ctx)
  demo.HelpMarker("Save/Revert in local non-persistent storage. Default Colors definition are not affected. Use \"Export\" below to save them somewhere.")
  local function export(enum_name, func_suffix, cur_table, ref_table, is_equal, format_value)
    local lines, name_maxlen = {}, 0
    for i, name in demo.EachEnum(enum_name) do
      if (not app.style_editor.output_only_modified or not is_equal(cur_table[i], ref_table[i])) then
        table.insert(lines, {name, cur_table[i]})
        name_maxlen = math.max(name_maxlen, name:len())
      else
      end
    end
    if (app.style_editor.output_dest == 0) then
      ImGui.LogToClipboard(ctx)
    else
      ImGui.LogToTTY(ctx)
    end
    for _, line in ipairs(lines) do
      local pad = string.rep(" ", (name_maxlen - (line[1]):len()))
      ImGui.LogText(ctx, ("ImGui.Push%s(ctx, ImGui.%s_%s(),%s %s)\n"):format(func_suffix, enum_name, line[1], pad, format_value(line[2])))
    end
    if (#lines == 1) then
      ImGui.LogText(ctx, ("\nImGui.Pop%s(ctx)\n"):format(func_suffix))
    elseif (#lines > 1) then
      ImGui.LogText(ctx, ("\nImGui.Pop%s(ctx, %d)\n"):format(func_suffix, #lines))
    else
    end
    return ImGui.LogFinish(ctx)
  end
  if ImGui.Button(ctx, "Export Vars") then
    local function _1115_(a, b)
      if (type(a) == "table") then
        return ((a[1] == b[1]) and (a[2] == b[2]))
      else
        return (a == b)
      end
    end
    local function _1117_(val)
      if (type(val) == "table") then
        return ("%g, %g"):format(table.unpack(val))
      else
        return ("%g"):format(val)
      end
    end
    export("StyleVar", "StyleVar", app.style_editor.style.vars, app.style_editor.ref.vars, _1115_, _1117_)
  else
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, "Export Colors") then
    local function _1120_(a, b)
      return (a == b)
    end
    local function _1121_(val)
      return ("0x%08X"):format((val & 4294967295))
    end
    export("Col", "StyleColor", app.style_editor.style.colors, app.style_editor.ref.colors, _1120_, _1121_)
  else
  end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 120)
  rv, app.style_editor.output_dest = ImGui.Combo(ctx, "##output_type", app.style_editor.output_dest, "To Clipboard\0To TTY\0")
  ImGui.SameLine(ctx)
  rv, app.style_editor.output_only_modified = ImGui.Checkbox(ctx, "Only Modified", app.style_editor.output_only_modified)
  ImGui.Separator(ctx)
  if ImGui.BeginTabBar(ctx, "##tabs", ImGui.TabBarFlags_None()) then
    if ImGui.BeginTabItem(ctx, "Sizes") then
      local function slider(varname, min, max, format)
        local func = ImGui[("StyleVar_" .. varname)]
        assert(func, ("%s is not exposed as a StyleVar"):format(varname))
        local ___var___ = func()
        if (type(app.style_editor.style.vars[___var___]) == "table") then
          local rv0, val1, val2 = ImGui.SliderDouble2(ctx, varname, app.style_editor.style.vars[___var___][1], app.style_editor.style.vars[___var___][2], min, max, format)
          if rv0 then
            app.style_editor.style.vars[___var___] = {val1, val2}
            return nil
          else
            return nil
          end
        else
          local rv0, val = ImGui.SliderDouble(ctx, varname, app.style_editor.style.vars[___var___], min, max, format)
          if rv0 then
            app.style_editor.style.vars[___var___] = val
            return nil
          else
            return nil
          end
        end
      end
      ImGui.SeparatorText(ctx, "Main")
      slider("WindowPadding", 0, 20, "%.0f")
      slider("FramePadding", 0, 20, "%.0f")
      slider("CellPadding", 0, 20, "%.0f")
      slider("ItemSpacing", 0, 20, "%.0f")
      slider("ItemInnerSpacing", 0, 20, "%.0f")
      slider("IndentSpacing", 0, 30, "%.0f")
      slider("ScrollbarSize", 1, 20, "%.0f")
      slider("GrabMinSize", 1, 20, "%.0f")
      ImGui.SeparatorText(ctx, "Borders")
      slider("WindowBorderSize", 0, 1, "%.0f")
      slider("ChildBorderSize", 0, 1, "%.0f")
      slider("PopupBorderSize", 0, 1, "%.0f")
      slider("FrameBorderSize", 0, 1, "%.0f")
      ImGui.SeparatorText(ctx, "Rounding")
      slider("WindowRounding", 0, 12, "%.0f")
      slider("ChildRounding", 0, 12, "%.0f")
      slider("FrameRounding", 0, 12, "%.0f")
      slider("PopupRounding", 0, 12, "%.0f")
      slider("ScrollbarRounding", 0, 12, "%.0f")
      slider("GrabRounding", 0, 12, "%.0f")
      slider("TabRounding", 0, 12, "%.0f")
      ImGui.SeparatorText(ctx, "Widgets")
      slider("WindowTitleAlign", 0, 1, "%.2f")
      slider("ButtonTextAlign", 0, 1, "%.2f")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Alignment applies when a button is larger than its text content.")
      slider("SelectableTextAlign", 0, 1, "%.2f")
      ImGui.SameLine(ctx)
      demo.HelpMarker("Alignment applies when a selectable is larger than its text content.")
      slider("SeparatorTextBorderSize", 0, 10, "%.0f")
      slider("SeparatorTextAlign", 0, 1, "%.2f")
      slider("SeparatorTextPadding", 0, 40, "%.0f")
      ImGui.EndTabItem(ctx)
    else
    end
    if ImGui.BeginTabItem(ctx, "Colors") then
      if not app.style_editor.colors then
        app.style_editor.colors = {alpha_flags = ImGui.ColorEditFlags_None(), filter = {inst = nil, text = ""}}
      else
      end
      if not ImGui.ValidatePtr(app.style_editor.colors.filter.inst, "ImGui_TextFilter*") then
        app.style_editor.colors.filter.inst = ImGui.CreateTextFilter(app.style_editor.colors.filter.text)
      else
      end
      if ImGui.TextFilter_Draw(app.style_editor.colors.filter.inst, ctx, "Filter colors", (ImGui.GetFontSize(ctx) * 16)) then
        app.style_editor.colors.filter.text = ImGui.TextFilter_Get(app.style_editor.colors.filter.inst)
      else
      end
      if ImGui.RadioButton(ctx, "Opaque", (app.style_editor.colors.alpha_flags == ImGui.ColorEditFlags_None())) then
        app.style_editor.colors.alpha_flags = ImGui.ColorEditFlags_None()
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.RadioButton(ctx, "Alpha", (app.style_editor.colors.alpha_flags == ImGui.ColorEditFlags_AlphaPreview())) then
        app.style_editor.colors.alpha_flags = ImGui.ColorEditFlags_AlphaPreview()
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.RadioButton(ctx, "Both", (app.style_editor.colors.alpha_flags == ImGui.ColorEditFlags_AlphaPreviewHalf())) then
        app.style_editor.colors.alpha_flags = ImGui.ColorEditFlags_AlphaPreviewHalf()
      else
      end
      ImGui.SameLine(ctx)
      demo.HelpMarker("In the color list:\nLeft-click on color square to open color picker,\nRight-click to open edit options menu.")
      if ImGui.BeginChild(ctx, "##colors", 0, 0, true, (ImGui.WindowFlags_AlwaysVerticalScrollbar() | ImGui.WindowFlags_AlwaysHorizontalScrollbar() | 0)) then
        ImGui.PushItemWidth(ctx, ( - 160))
        local inner_spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing())
        for i, name in demo.EachEnum("Col") do
          if ImGui.TextFilter_PassFilter(app.style_editor.colors.filter.inst, name) then
            ImGui.PushID(ctx, i)
            rv, ci = ImGui.ColorEdit4(ctx, "##color", app.style_editor.style.colors[i], (ImGui.ColorEditFlags_AlphaBar() | app.style_editor.colors.alpha_flags))
            do end (app.style_editor.style.colors)[i] = ci
            if (app.style_editor.style.colors[i] ~= app.style_editor.ref.colors[i]) then
              ImGui.SameLine(ctx, 0, inner_spacing)
              if ImGui.Button(ctx, "Save") then
                app.style_editor.ref.colors[i] = app.style_editor.style.colors[i]
              else
              end
              ImGui.SameLine(ctx, 0, inner_spacing)
              if ImGui.Button(ctx, "Revert") then
                app.style_editor.style.colors[i] = app.style_editor.ref.colors[i]
              else
              end
            else
            end
            ImGui.SameLine(ctx, 0, inner_spacing)
            ImGui.Text(ctx, name)
            ImGui.PopID(ctx)
          else
          end
        end
        ImGui.PopItemWidth(ctx)
        ImGui.EndChild(ctx)
      else
      end
      ImGui.EndTabItem(ctx)
    else
    end
    if ImGui.BeginTabItem(ctx, "Rendering") then
      ImGui.PushItemWidth(ctx, (ImGui.GetFontSize(ctx) * 8))
      local Alpha, Disabled_alpha = ImGui.StyleVar_Alpha(), ImGui.StyleVar_DisabledAlpha()
      rv, __fnl_global__v_2da = ImGui.DragDouble(ctx, "Global Alpha", app.style_editor.style.vars[Alpha], 0.005, 0.2, 1, "%.2f")
      do end (app.style_editor.style.vars)[Alpha] = __fnl_global__v_2da
      rv, __fnl_global__v_2ddA = ImGui.DragDouble(ctx, "Disabled Alpha", app.style_editor.style.vars[Disabled_alpha], 0.005, 0, 1, "%.2f")
      do end (app.style_editor.style.vars)[Disabled_alpha] = __fnl_global__v_2ddA
      ImGui.SameLine(ctx)
      demo.HelpMarker("Additional alpha multiplier for disabled items (multiply over current value of Alpha).")
      ImGui.PopItemWidth(ctx)
      ImGui.EndTabItem(ctx)
    else
    end
    ImGui.EndTabBar(ctx)
  else
  end
  return ImGui.PopItemWidth(ctx)
end
demo.ShowUserGuide = function()
  ImGui.BulletText(ctx, "Double-click on title bar to collapse window.")
  ImGui.BulletText(ctx, "Click and drag on lower corner to resize window\n(double-click to auto fit window to its contents).")
  ImGui.BulletText(ctx, "CTRL+Click on a slider or drag box to input value as text.")
  ImGui.BulletText(ctx, "TAB/SHIFT+TAB to cycle through keyboard editable fields.")
  ImGui.BulletText(ctx, "CTRL+Tab to select a window.")
  ImGui.BulletText(ctx, "While inputing text:\n")
  ImGui.Indent(ctx)
  ImGui.BulletText(ctx, "CTRL+Left/Right to word jump.")
  ImGui.BulletText(ctx, "CTRL+A or double-click to select all.")
  ImGui.BulletText(ctx, "CTRL+X/C/V to use clipboard cut/copy/paste.")
  ImGui.BulletText(ctx, "CTRL+Z,CTRL+Y to undo/redo.")
  ImGui.BulletText(ctx, "ESCAPE to revert.")
  ImGui.Unindent(ctx)
  ImGui.BulletText(ctx, "With keyboard navigation enabled:")
  ImGui.Indent(ctx)
  ImGui.BulletText(ctx, "Arrow keys to navigate.")
  ImGui.BulletText(ctx, "Space to activate a widget.")
  ImGui.BulletText(ctx, "Return to input text into a widget.")
  ImGui.BulletText(ctx, "Escape to deactivate a widget, close popup, exit child window.")
  ImGui.BulletText(ctx, "Alt to jump to the menu layer of a window.")
  return ImGui.Unindent(ctx)
end
demo.ShowExampleMenuFile = function()
  local rv = nil
  ImGui.MenuItem(ctx, "(demo menu)", nil, false, false)
  if ImGui.MenuItem(ctx, "New") then
  else
  end
  if ImGui.MenuItem(ctx, "Open", "Ctrl+O") then
  else
  end
  if ImGui.BeginMenu(ctx, "Open Recent") then
    ImGui.MenuItem(ctx, "fish_hat.c")
    ImGui.MenuItem(ctx, "fish_hat.inl")
    ImGui.MenuItem(ctx, "fish_hat.h")
    if ImGui.BeginMenu(ctx, "More..") then
      ImGui.MenuItem(ctx, "Hello")
      ImGui.MenuItem(ctx, "Sailor")
      if ImGui.BeginMenu(ctx, "Recurse..") then
        demo.ShowExampleMenuFile()
        ImGui.EndMenu(ctx)
      else
      end
      ImGui.EndMenu(ctx)
    else
    end
    ImGui.EndMenu(ctx)
  else
  end
  if ImGui.MenuItem(ctx, "Save", "Ctrl+S") then
  else
  end
  if ImGui.MenuItem(ctx, "Save As..") then
  else
  end
  ImGui.Separator(ctx)
  if ImGui.BeginMenu(ctx, "Options") then
    rv, demo.menu.enabled = ImGui.MenuItem(ctx, "Enabled", "", demo.menu.enabled)
    if ImGui.BeginChild(ctx, "child", 0, 60, true) then
      for i = 0, 9 do
        ImGui.Text(ctx, ("Scrolling Text %d"):format(i))
      end
      ImGui.EndChild(ctx)
    else
    end
    rv, demo.menu.f = ImGui.SliderDouble(ctx, "Value", demo.menu.f, 0, 1)
    rv, demo.menu.f = ImGui.InputDouble(ctx, "Input", demo.menu.f, 0.1)
    rv, demo.menu.n = ImGui.Combo(ctx, "Combo", demo.menu.n, "Yes\0No\0Maybe\0")
    ImGui.EndMenu(ctx)
  else
  end
  if ImGui.BeginMenu(ctx, "Colors") then
    local sz = ImGui.GetTextLineHeight(ctx)
    local draw_list = ImGui.GetWindowDrawList(ctx)
    for i, name in demo.EachEnum("Col") do
      local x, y = ImGui.GetCursorScreenPos(ctx)
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + sz), (y + sz), ImGui.GetColor(ctx, i))
      ImGui.Dummy(ctx, sz, sz)
      ImGui.SameLine(ctx)
      ImGui.MenuItem(ctx, name)
    end
    ImGui.EndMenu(ctx)
  else
  end
  if ImGui.BeginMenu(ctx, "Options") then
    rv, demo.menu.b = ImGui.Checkbox(ctx, "SomeOption", demo.menu.b)
    ImGui.EndMenu(ctx)
  else
  end
  if ImGui.BeginMenu(ctx, "Disabled", false) then
    error("never called")
  else
  end
  if ImGui.MenuItem(ctx, "Checked", nil, true) then
  else
  end
  ImGui.Separator(ctx)
  if ImGui.MenuItem(ctx, "Quit", "Alt+F4") then
    return nil
  else
    return nil
  end
end
local Example_app_log = {}
Example_app_log.new = function(self, ctx0)
  local instance = {auto_scroll = true, ctx = ctx0, filter = {inst = nil, text = ""}, lines = {}}
  self.__index = self
  return setmetatable(instance, self)
end
Example_app_log.clear = function(self)
  self.lines = {}
  return nil
end
Example_app_log.add_log = function(self, fmt, ...)
  local text = fmt:format(...)
  for line in text:gmatch("[^\13\n]+") do
    table.insert(self.lines, line)
  end
  return nil
end
Example_app_log.draw = function(self, title, p_open)
  local rv, p_open0 = ImGui.Begin(self.ctx, title, p_open)
  if rv then
    if not ImGui.ValidatePtr(self.filter.inst, "ImGui_TextFilter*") then
      self.filter.inst = ImGui.CreateTextFilter(self.filter.text)
    else
    end
    if ImGui.BeginPopup(self.ctx, "Options") then
      do
        local rv_1157_, arg1_1156_ = nil, nil
        do
          local arg1_1156_0 = self.auto_scroll
          local _24 = arg1_1156_0
          rv_1157_, arg1_1156_ = ImGui.Checkbox(self.ctx, "Auto-scroll", _24)
        end
        self.auto_scroll = arg1_1156_
      end
      ImGui.EndPopup(self.ctx)
    else
    end
    if ImGui.Button(self.ctx, "Options") then
      ImGui.OpenPopup(self.ctx, "Options")
    else
    end
    ImGui.SameLine(self.ctx)
    local clear = ImGui.Button(self.ctx, "Clear")
    ImGui.SameLine(self.ctx)
    local copy = ImGui.Button(self.ctx, "Copy")
    ImGui.SameLine(self.ctx)
    if ImGui.TextFilter_Draw(self.filter.inst, ctx, "Filter", ( - 100)) then
      self.filter.text = ImGui.TextFilter_Get(self.filter.inst)
    else
    end
    ImGui.Separator(self.ctx)
    if ImGui.BeginChild(self.ctx, "scrolling", 0, 0, false, ImGui.WindowFlags_HorizontalScrollbar()) then
      if clear then
        self:clear()
      else
      end
      if copy then
        ImGui.LogToClipboard(self.ctx)
      else
      end
      ImGui.PushStyleVar(self.ctx, ImGui.StyleVar_ItemSpacing(), 0, 0)
      if ImGui.TextFilter_IsActive(self.filter.inst) then
        for line_no, line in ipairs(self.lines) do
          if ImGui.TextFilter_PassFilter(self.filter.inst, line) then
            ImGui.Text(ctx, line)
          else
          end
        end
      else
        local clipper = ImGui.CreateListClipper(self.ctx)
        ImGui.ListClipper_Begin(clipper, #self.lines)
        while ImGui.ListClipper_Step(clipper) do
          local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
          for line_no = display_start, (display_end - 1) do
            ImGui.Text(self.ctx, self.lines[(line_no + 1)])
          end
        end
        ImGui.ListClipper_End(clipper)
      end
      ImGui.PopStyleVar(self.ctx)
      if (self.auto_scroll and (ImGui.GetScrollY(self.ctx) >= ImGui.GetScrollMaxY(self.ctx))) then
        ImGui.SetScrollHereY(self.ctx, 1)
      else
      end
      ImGui.EndChild(self.ctx)
    else
    end
    ImGui.End(self.ctx)
  else
  end
  return p_open0
end
demo.ShowExampleAppLog = function()
  if not app.log then
    local _1168_ = Example_app_log:new(ctx)
    do end (_1168_)["counter"] = 0
    app.log = _1168_
  else
  end
  ImGui.SetNextWindowSize(ctx, 500, 400, ImGui.Cond_FirstUseEver())
  local rv, open = ImGui.Begin(ctx, "Example: Log", true)
  if rv then
    if ImGui.SmallButton(ctx, "[Debug] Add 5 entries") then
      local categories = {"info", "warn", "error"}
      local words = {"Bumfuzzled", "Cattywampus", "Snickersnee", "Abibliophobia", "Absquatulate", "Nincompoop", "Pauciloquent"}
      for n = 0, (5 - 1) do
        local category = categories[((app.log.counter % #categories) + 1)]
        local word = words[((app.log.counter % #words) + 1)]
        do end (app.log):add_log("[%05d] [%s] Hello, current time is %.1f, here's a word: '%s'\n          ", ImGui.GetFrameCount(ctx), category, ImGui.GetTime(ctx), word)
        app.log.counter = (app.log.counter + 1)
      end
    else
    end
    ImGui.End(ctx)
    do end (app.log):draw("Example: Log")
  else
  end
  return open
end
demo.ShowExampleAppLayout = function()
  if not app.layout then
    app.layout = {selected = 0}
  else
  end
  ImGui.SetNextWindowSize(ctx, 500, 440, ImGui.Cond_FirstUseEver())
  local rv, open = ImGui.Begin(ctx, "Example: Simple layout", true, ImGui.WindowFlags_MenuBar())
  if rv then
    if ImGui.BeginMenuBar(ctx) then
      if ImGui.BeginMenu(ctx, "File") then
        if ImGui.MenuItem(ctx, "Close", "Ctrl+W") then
          open = false
        else
        end
        ImGui.EndMenu(ctx)
      else
      end
      ImGui.EndMenuBar(ctx)
    else
    end
    if ImGui.BeginChild(ctx, "left pane", 150, 0, true) then
      for i = 0, (100 - 1) do
        if ImGui.Selectable(ctx, ("MyObject %d"):format(i), (app.layout.selected == i)) then
          app.layout.selected = i
        else
        end
      end
      ImGui.EndChild(ctx)
    else
    end
    ImGui.SameLine(ctx)
    ImGui.BeginGroup(ctx)
    if ImGui.BeginChild(ctx, "item view", 0, ( - ImGui.GetFrameHeightWithSpacing(ctx))) then
      ImGui.Text(ctx, ("MyObject: %d"):format(app.layout.selected))
      ImGui.Separator(ctx)
      if ImGui.BeginTabBar(ctx, "##Tabs", ImGui.TabBarFlags_None()) then
        if ImGui.BeginTabItem(ctx, "Description") then
          ImGui.TextWrapped(ctx, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ")
          ImGui.EndTabItem(ctx)
        else
        end
        if ImGui.BeginTabItem(ctx, "Details") then
          ImGui.Text(ctx, "ID: 0123456789")
          ImGui.EndTabItem(ctx)
        else
        end
        ImGui.EndTabBar(ctx)
      else
      end
      ImGui.EndChild(ctx)
    else
    end
    if ImGui.Button(ctx, "Revert") then
    else
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Save") then
    else
    end
    ImGui.EndGroup(ctx)
    ImGui.End(ctx)
  else
  end
  return open
end
demo.ShowPlaceholderObject = function(prefix, uid)
  ImGui.PushID(ctx, uid)
  ImGui.TableNextRow(ctx)
  ImGui.TableSetColumnIndex(ctx, 0)
  ImGui.AlignTextToFramePadding(ctx)
  local node_open = ImGui.TreeNodeEx(ctx, "Object", ("%s_%u"):format(prefix, uid))
  ImGui.TableSetColumnIndex(ctx, 1)
  ImGui.Text(ctx, "my sailor is rich")
  if node_open then
    for i = 0, (#app.property_editor.placeholder_members - 1) do
      ImGui.PushID(ctx, i)
      if (i < 2) then
        demo.ShowPlaceholderObject("Child", 424242)
      else
        ImGui.TableNextRow(ctx)
        ImGui.TableSetColumnIndex(ctx, 0)
        ImGui.AlignTextToFramePadding(ctx)
        do
          local flags = (ImGui.TreeNodeFlags_Leaf() | ImGui.TreeNodeFlags_NoTreePushOnOpen() | ImGui.TreeNodeFlags_Bullet())
          ImGui.TreeNodeEx(ctx, "Field", ("Field_%d"):format(i), flags)
        end
        ImGui.TableSetColumnIndex(ctx, 1)
        ImGui.SetNextItemWidth(ctx, ( - FLT_MIN))
        local function _1185_()
          if (i >= 5) then
            return 1
          else
            return 0.01
          end
        end
        _, pmi = ImGui.DragDouble(ctx, "##value", app.property_editor.placeholder_members[i], _1185_())
        do end (app.property_editor.placeholder_members)[i] = pmi
      end
      ImGui.PopID(ctx)
    end
    ImGui.TreePop(ctx)
  else
  end
  return ImGui.PopID(ctx)
end
demo.ShowExampleAppPropertyEditor = function()
  if not app.property_editor then
    app.property_editor = {placeholder_members = {0, 0, 1, 3.1416, 100, 999, 0, 0}}
  else
  end
  ImGui.SetNextWindowSize(ctx, 430, 450, ImGui.Cond_FirstUseEver())
  local rv, open = ImGui.Begin(ctx, "Example: Property editor", true)
  if rv then
    demo.HelpMarker("This example shows how you may implement a property editor using two columns.\n      All objects/fields data are dummies here.\n      Remember that in many simple cases, you can use ImGui.SameLine(xxx) to position\n      your cursor horizontally instead of using the Columns() API.")
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 2, 2)
    if ImGui.BeginTable(ctx, "split", 2, (ImGui.TableFlags_BordersOuter() | ImGui.TableFlags_Resizable())) then
      for obj_i = 0, (4 - 1) do
        demo.ShowPlaceholderObject("Object", obj_i)
      end
      ImGui.EndTable(ctx)
    else
    end
    ImGui.PopStyleVar(ctx)
    ImGui.End(ctx)
  else
  end
  return open
end
demo.ShowExampleAppLongText = function()
  if not app.long_text then
    app.long_text = {lines = 0, log = "", test_type = 0}
  else
  end
  ImGui.SetNextWindowSize(ctx, 520, 600, ImGui.Cond_FirstUseEver())
  local rv, open = ImGui.Begin(ctx, "Example: Long text display", true)
  if rv then
    ImGui.Text(ctx, "Printing unusually long amount of text.")
    do
      local rv_1193_, arg1_1192_ = nil, nil
      do
        local arg1_1192_0 = app.long_text.test_type
        local _24 = arg1_1192_0
        rv_1193_, arg1_1192_ = ImGui.Combo(ctx, "Test type", _24, "Single call to Text()\0\n                                Multiple calls to Text(), clipped\0\n                                Multiple calls to Text(), not clipped (slow)\0")
      end
      app.long_text.test_type = arg1_1192_
    end
    ImGui.Text(ctx, ("Buffer contents: %d lines, %d bytes"):format(app.long_text.lines, (app.long_text.log):len()))
    if ImGui.Button(ctx, "Clear") then
      app.long_text.log = ""
      app.long_text.lines = 0
    else
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "Add 1000 lines") then
      local new_lines = ""
      for i = 0, (1000 - 1) do
        new_lines = (new_lines .. ("%i The quick brown fox jumps over the lazy dog\n          "):format((app.long_text.lines + i)))
      end
      app.long_text.log = (app.long_text.log .. new_lines)
      app.long_text.lines = (app.long_text.lines + 1000)
    else
    end
    if ImGui.BeginChild(ctx, "Log") then
      do
        local _1196_ = app.long_text.test_type
        if (_1196_ == 0) then
          ImGui.Text(ctx, app.long_text.log)
        elseif (_1196_ == 1) then
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), 0, 0)
          local clipper = ImGui.CreateListClipper(ctx)
          ImGui.ListClipper_Begin(clipper, app.long_text.lines)
          while ImGui.ListClipper_Step(clipper) do
            local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
            for i = display_start, (display_end - 1) do
              ImGui.Text(ctx, ("%i The quick brown fox jumps over the lazy dog"):format(i))
            end
          end
          ImGui.PopStyleVar(ctx)
        elseif (_1196_ == 2) then
          ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), 0, 0)
          for i = 0, app.long_text.lines do
            ImGui.Text(ctx, ("%i The quick brown fox jumps over the lazy dog"):format(i))
          end
          ImGui.PopStyleVar(ctx)
        else
        end
      end
      ImGui.EndChild(ctx)
    else
    end
    ImGui.End(ctx)
  else
  end
  return open
end
demo.ShowExampleAppAutoResize = function()
  if not app.auto_resize then
    app.auto_resize = {lines = 10}
  else
  end
  local rv, open = ImGui.Begin(ctx, "Example: Auto-resizing window", true, ImGui.WindowFlags_AlwaysAutoResize())
  if rv then
    ImGui.Text(ctx, "Window will resize every-frame to the size of its content.\n                  Note that you probably don't want to query the window size to\n                  output your content because that would create a feedback loop.")
    do
      local rv_1202_, arg1_1201_ = nil, nil
      do
        local arg1_1201_0 = app.auto_resize.lines
        local _24 = arg1_1201_0
        rv_1202_, arg1_1201_ = ImGui.SliderInt(ctx, "Number of lines", _24, 1, 20)
      end
      app.auto_resize.lines = arg1_1201_
    end
    for i = 1, app.auto_resize.lines do
      ImGui.Text(ctx, ("%sThis is line %d"):format((" "):rep((i * 4)), i))
    end
    ImGui.End(ctx)
  else
  end
  return open
end
demo.ShowExampleAppConstrainedResize = function()
  if not app.constrained_resize then
    app.constrained_resize = {display_lines = 10, type = 0, window_padding = true, auto_resize = false}
  else
  end
  do
    local _1205_ = app.constrained_resize.type
    if (_1205_ == 0) then
      ImGui.SetNextWindowSizeConstraints(ctx, 100, 100, 500, 500)
    elseif (_1205_ == 1) then
      ImGui.SetNextWindowSizeConstraints(ctx, 100, 100, FLT_MAX, FLT_MAX)
    elseif (_1205_ == 2) then
      ImGui.SetNextWindowSizeConstraints(ctx, -1, 0, -1, FLT_MAX)
    elseif (_1205_ == 3) then
      ImGui.SetNextWindowSizeConstraints(ctx, 0, -1, FLT_MAX, -1)
    elseif (_1205_ == 4) then
      ImGui.SetNextWindowSizeConstraints(ctx, 400, -1, 500, -1)
    else
    end
  end
  if not app.constrained_resize.window_padding then
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding(), 0, 0)
  else
  end
  local window_flags
  if app.constrained_resize.auto_resize then
    window_flags = ImGui.WindowFlags_AlwaysAutoResize()
  else
    window_flags = 0
  end
  local visible, open = ImGui.Begin(ctx, "Example: Constrained Resize", true, window_flags)
  if not app.constrained_resize.window_padding then
    ImGui.PopStyleVar(ctx)
  else
  end
  if visible then
    if ImGui.IsKeyDown(ctx, ImGui.Mod_Shift()) then
      local avail_size_w, avail_size_h = ImGui.GetContentRegionAvail(ctx)
      local pos_x, pos_y = ImGui.GetCursorScreenPos(ctx)
      ImGui.ColorButton(ctx, "viewport", 2134081535, (ImGui.ColorEditFlags_NoTooltip() | ImGui.ColorEditFlags_NoDragDrop()), avail_size_w, avail_size_h)
      ImGui.SetCursorScreenPos(ctx, (pos_x + 10), (pos_y + 10))
      ImGui.Text(ctx, ("%.2f x %.2f"):format(avail_size_w, avail_size_h))
    else
      ImGui.Text(ctx, "(Hold SHIFT to display a dummy viewport)")
      if ImGui.IsWindowDocked(ctx) then
        ImGui.Text(ctx, "Warning: Sizing Constraints won't work if the window is docked!")
      else
      end
      if ImGui.Button(ctx, "Set 200x200") then
        ImGui.SetWindowSize(ctx, 200, 200)
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, "Set 500x500") then
        ImGui.SetWindowSize(ctx, 500, 500)
      else
      end
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, "Set 800x200") then
        ImGui.SetWindowSize(ctx, 800, 200)
      else
      end
      ImGui.SetNextItemWidth(ctx, (ImGui.GetFontSize(ctx) * 20))
      do
        local rv_1215_, arg1_1214_ = nil, nil
        do
          local arg1_1214_0 = app.constrained_resize.type
          local _24 = arg1_1214_0
          rv_1215_, arg1_1214_ = ImGui.Combo(ctx, "Constraint", _24, "Between 100x100 and 500x500\0\n                                   At least 100x100\0\n                                   Resize vertical only\0\n                                   Resize horizontal only\0\n                                   Width Between 400 and 500\0")
        end
        app.constrained_resize.type = arg1_1214_
      end
      ImGui.SetNextItemWidth(ctx, (ImGui.GetFontSize(ctx) * 20))
      do
        local rv_1217_, arg1_1216_ = nil, nil
        do
          local arg1_1216_0 = app.constrained_resize.display_lines
          local _24 = arg1_1216_0
          rv_1217_, arg1_1216_ = ImGui.DragInt(ctx, "Lines", _24, 0.2, 1, 100)
        end
        app.constrained_resize.display_lines = arg1_1216_
      end
      do
        local rv_1219_, arg1_1218_ = nil, nil
        do
          local arg1_1218_0 = app.constrained_resize.auto_resize
          local _24 = arg1_1218_0
          rv_1219_, arg1_1218_ = ImGui.Checkbox(ctx, "Auto-resize", _24)
        end
        app.constrained_resize.auto_resize = arg1_1218_
      end
      do
        local rv_1221_, arg1_1220_ = nil, nil
        do
          local arg1_1220_0 = app.constrained_resize.window_padding
          local _24 = arg1_1220_0
          rv_1221_, arg1_1220_ = ImGui.Checkbox(ctx, "Window padding", _24)
        end
        app.constrained_resize.window_padding = arg1_1220_
      end
      for i = 1, app.constrained_resize.display_lines do
        ImGui.Text(ctx, ("%sHello, sailor! Making this line long enough for the example."):format((" "):rep((i * 4))))
      end
    end
    ImGui.End(ctx)
  else
  end
  return open
end
demo.ShowExampleAppSimpleOverlay = function()
  if not app.simple_overlay then
    app.simple_overlay = {location = 0}
  else
  end
  local window_flags = (ImGui.WindowFlags_NoDecoration() | ImGui.WindowFlags_NoDocking() | ImGui.WindowFlags_AlwaysAutoResize() | ImGui.WindowFlags_NoSavedSettings() | ImGui.WindowFlags_NoFocusOnAppearing() | ImGui.WindowFlags_NoNav())
  if (app.simple_overlay.location >= 0) then
    local PAD = 10
    local viewport = ImGui.GetMainViewport(ctx)
    local work_pos_x, work_pos_y = ImGui.Viewport_GetWorkPos(viewport)
    local work_size_w, work_size_h = ImGui.Viewport_GetWorkSize(viewport)
    local window_pos_x = ((((app.simple_overlay.location & 1) ~= 0) and ((work_pos_x + work_size_w) - PAD)) or (work_pos_x + PAD))
    local window_pos_y = ((((app.simple_overlay.location & 2) ~= 0) and ((work_pos_y + work_size_h) - PAD)) or (work_pos_y + PAD))
    local window_pos_pivot_x
    if (0 == (1 & app.simple_overlay.location)) then
      window_pos_pivot_x = 0
    else
      window_pos_pivot_x = 1
    end
    local window_pos_pivot_y
    if (0 == (2 & app.simple_overlay.location)) then
      window_pos_pivot_y = 0
    else
      window_pos_pivot_y = 1
    end
    ImGui.SetNextWindowPos(ctx, window_pos_x, window_pos_y, ImGui.Cond_Always(), window_pos_pivot_x, window_pos_pivot_y)
    window_flags = (window_flags | ImGui.WindowFlags_NoMove())
  elseif (app.simple_overlay.location == -2) then
    local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetMainViewport(ctx))
    ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Always(), 0.5, 0.5)
    window_flags = (window_flags | ImGui.WindowFlags_NoMove())
  else
  end
  ImGui.SetNextWindowBgAlpha(ctx, 0.35)
  local rv, open = ImGui.Begin(ctx, "Example: Simple overlay", true, window_flags)
  if not rv then
    return open
  else
  end
  ImGui.Text(ctx, "Simple overlay\n(right-click to change position)")
  ImGui.Separator(ctx)
  if ImGui.IsMousePosValid(ctx) then
    ImGui.Text(ctx, ("Mouse Position: (%.1f,%.1f)"):format(ImGui.GetMousePos(ctx)))
  else
    ImGui.Text(ctx, "Mouse Position: <invalid>")
  end
  if ImGui.BeginPopupContextWindow(ctx) then
    if ImGui.MenuItem(ctx, "Custom", nil, (app.simple_overlay.location == -1)) then
      app.simple_overlay.location = -1
    else
    end
    if ImGui.MenuItem(ctx, "Center", nil, (app.simple_overlay.location == -2)) then
      app.simple_overlay.location = -2
    else
    end
    if ImGui.MenuItem(ctx, "Top-left", nil, (app.simple_overlay.location == 0)) then
      app.simple_overlay.location = 0
    else
    end
    if ImGui.MenuItem(ctx, "Top-right", nil, (app.simple_overlay.location == 1)) then
      app.simple_overlay.location = 1
    else
    end
    if ImGui.MenuItem(ctx, "Bottom-left", nil, (app.simple_overlay.location == 2)) then
      app.simple_overlay.location = 2
    else
    end
    if ImGui.MenuItem(ctx, "Bottom-right", nil, (app.simple_overlay.location == 3)) then
      app.simple_overlay.location = 3
    else
    end
    if ImGui.MenuItem(ctx, "Close") then
      open = false
    else
    end
    ImGui.EndPopup(ctx)
  else
  end
  ImGui.End(ctx)
  return open
end
demo.ShowExampleAppFullscreen = function()
  if not app.fullscreen then
    app.fullscreen = {flags = (ImGui.WindowFlags_NoDecoration() | ImGui.WindowFlags_NoMove() | ImGui.WindowFlags_NoSavedSettings()), use_work_area = true}
  else
  end
  local viewport = ImGui.GetMainViewport(ctx)
  local get_viewport_pos
  if app.fullscreen.use_work_area then
    get_viewport_pos = ImGui.Viewport_GetWorkPos
  else
    get_viewport_pos = ImGui.Viewport_GetPos
  end
  local get_viewport_size = ((app.fullscreen.use_work_area and ImGui.Viewport_GetWorkSize) or ImGui.Viewport_GetSize)
  ImGui.SetNextWindowPos(ctx, get_viewport_pos(viewport))
  ImGui.SetNextWindowSize(ctx, get_viewport_size(viewport))
  local rv, open = ImGui.Begin(ctx, "Example: Fullscreen window", true, app.fullscreen.flags)
  if rv then
    rv, app.fullscreen.use_work_area = ImGui.Checkbox(ctx, "Use work area instead of main area", app.fullscreen.use_work_area)
    ImGui.SameLine(ctx)
    demo.HelpMarker("Main Area = entire viewport,\n    Work Area = entire viewport minus sections used by the main menu bars, task bars etc.\n\n    Enable the main-menu bar in Examples menu to see the difference.")
    do
      local rv_1241_, arg1_1240_ = nil, nil
      do
        local arg1_1240_0 = app.fullscreen.flags
        local _24 = arg1_1240_0
        rv_1241_, arg1_1240_ = ImGui.CheckboxFlags(ctx, "ImGuiWindowFlags_NoBackground", _24, ImGui.WindowFlags_NoBackground())
      end
      app.fullscreen.flags = arg1_1240_
    end
    do
      local rv_1243_, arg1_1242_ = nil, nil
      do
        local arg1_1242_0 = app.fullscreen.flags
        local _24 = arg1_1242_0
        rv_1243_, arg1_1242_ = ImGui.CheckboxFlags(ctx, "ImGuiWindowFlags_NoDecoration", _24, ImGui.WindowFlags_NoDecoration())
      end
      app.fullscreen.flags = arg1_1242_
    end
    ImGui.Indent(ctx)
    do
      local rv_1245_, arg1_1244_ = nil, nil
      do
        local arg1_1244_0 = app.fullscreen.flags
        local _24 = arg1_1244_0
        rv_1245_, arg1_1244_ = ImGui.CheckboxFlags(ctx, "ImGuiWindowFlags_NoTitleBar", _24, ImGui.WindowFlags_NoTitleBar())
      end
      app.fullscreen.flags = arg1_1244_
    end
    do
      local rv_1247_, arg1_1246_ = nil, nil
      do
        local arg1_1246_0 = app.fullscreen.flags
        local _24 = arg1_1246_0
        rv_1247_, arg1_1246_ = ImGui.CheckboxFlags(ctx, "ImGuiWindowFlags_NoCollapse", _24, ImGui.WindowFlags_NoCollapse())
      end
      app.fullscreen.flags = arg1_1246_
    end
    do
      local rv_1249_, arg1_1248_ = nil, nil
      do
        local arg1_1248_0 = app.fullscreen.flags
        local _24 = arg1_1248_0
        rv_1249_, arg1_1248_ = ImGui.CheckboxFlags(ctx, "ImGuiWindowFlags_NoScrollbar", _24, ImGui.WindowFlags_NoScrollbar())
      end
      app.fullscreen.flags = arg1_1248_
    end
    ImGui.Unindent(ctx)
    if ImGui.Button(ctx, "Close this window") then
      open = false
    else
    end
    ImGui.End(ctx)
  else
  end
  return open
end
demo.ShowExampleAppWindowTitles = function()
  local viewport = ImGui.GetMainViewport(ctx)
  local base_pos = {ImGui.Viewport_GetPos(viewport)}
  ImGui.SetNextWindowPos(ctx, (base_pos[1] + 100), (base_pos[2] + 100), ImGui.Cond_FirstUseEver())
  if ImGui.Begin(ctx, "Same title as another window##1") then
    ImGui.Text(ctx, "This is window 1.\nMy title is the same as window 2, but my identifier is unique.")
    ImGui.End(ctx)
  else
  end
  ImGui.SetNextWindowPos(ctx, (base_pos[1] + 100), (base_pos[2] + 200), ImGui.Cond_FirstUseEver())
  if ImGui.Begin(ctx, "Same title as another window##2") then
    ImGui.Text(ctx, "This is window 2.\nMy title is the same as window 1, but my identifier is unique.")
    ImGui.End(ctx)
  else
  end
  ImGui.SetNextWindowPos(ctx, (base_pos[1] + 100), (base_pos[2] + 300), ImGui.Cond_FirstUseEver())
  spinners = {"|", "/", "-", "\\"}
  local spinner = (math.floor((ImGui.GetTime(ctx) / 0.25)) & 3)
  if ImGui.Begin(ctx, ("Animated title %s %d###AnimatedTitle"):format(spinners[(spinner + 1)], ImGui.GetFrameCount(ctx))) then
    ImGui.Text(ctx, "This window has a changing title.")
    return ImGui.End(ctx)
  else
    return nil
  end
end
demo.ShowExampleAppCustomRendering = function()
  if not app.rendering then
    app.rendering = {circle_segments_override_v = 12, col = 4294928127, curve_segments_override_v = 8, draw_bg = true, draw_fg = true, ngon_sides = 6, opt_enable_context_menu = true, opt_enable_grid = true, points = {}, scrolling = {0, 0}, sz = 36, thickness = 3, curve_segments_override = false, circle_segments_override = false, adding_line = false}
  else
  end
  local rv, open = ImGui.Begin(ctx, "Example: Custom rendering", true)
  if not rv then
    return open
  else
  end
  if ImGui.BeginTabBar(ctx, "##TabBar") then
    if ImGui.BeginTabItem(ctx, "Primitives") then
      ImGui.PushItemWidth(ctx, (( - ImGui.GetFontSize(ctx)) * 15))
      local draw_list = ImGui.GetWindowDrawList(ctx)
      ImGui.Text(ctx, "Gradients")
      local gradient_size = {ImGui.CalcItemWidth(ctx), ImGui.GetFrameHeight(ctx)}
      local p0 = {ImGui.GetCursorScreenPos(ctx)}
      local p1 = {((p0)[1] + gradient_size[1]), ((p0)[2] + gradient_size[2])}
      local col_a = ImGui.GetColorEx(ctx, 16711935)
      local col_b = ImGui.GetColorEx(ctx, 4278190335)
      ImGui.DrawList_AddRectFilledMultiColor(draw_list, (p0)[1], (p0)[2], (p1)[1], (p1)[2], col_a, col_b, col_b, col_a)
      ImGui.InvisibleButton(ctx, "##gradient1", gradient_size[1], gradient_size[2])
      local p00 = {ImGui.GetCursorScreenPos(ctx)}
      local p10 = {((p00)[1] + gradient_size[1]), ((p00)[2] + gradient_size[2])}
      local col_a0 = ImGui.GetColorEx(ctx, 16711935)
      local col_b0 = ImGui.GetColorEx(ctx, 4278190335)
      ImGui.DrawList_AddRectFilledMultiColor(draw_list, (p00)[1], (p00)[2], (p10)[1], (p10)[2], col_a0, col_b0, col_b0, col_a0)
      ImGui.InvisibleButton(ctx, "##gradient2", gradient_size[1], gradient_size[2])
      local item_inner_spacing_x = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing())
      ImGui.Text(ctx, "All primitives")
      do
        local rv_1258_, arg1_1257_ = nil, nil
        do
          local arg1_1257_0 = app.rendering.sz
          local _24 = arg1_1257_0
          rv_1258_, arg1_1257_ = ImGui.DragDouble(ctx, "Size", _24, 0.2, 2, 100, "%.0f")
        end
        app.rendering.sz = arg1_1257_
      end
      do
        local rv_1260_, arg1_1259_ = nil, nil
        do
          local arg1_1259_0 = app.rendering.thickness
          local _24 = arg1_1259_0
          rv_1260_, arg1_1259_ = ImGui.DragDouble(ctx, "Thickness", _24, 0.05, 1, 8, "%.02f")
        end
        app.rendering.thickness = arg1_1259_
      end
      do
        local rv_1262_, arg1_1261_ = nil, nil
        do
          local arg1_1261_0 = app.rendering.ngon_sides
          local _24 = arg1_1261_0
          rv_1262_, arg1_1261_ = ImGui.SliderInt(ctx, "N-gon sides", _24, 3, 12)
        end
        app.rendering.ngon_sides = arg1_1261_
      end
      do
        local rv_1264_, arg1_1263_ = nil, nil
        do
          local arg1_1263_0 = app.rendering.circle_segments_override
          local _24 = arg1_1263_0
          rv_1264_, arg1_1263_ = ImGui.Checkbox(ctx, "##circlesegmentoverride", _24)
        end
        app.rendering.circle_segments_override = arg1_1263_
      end
      ImGui.SameLine(ctx, 0, item_inner_spacing_x)
      rv, app.rendering.circle_segments_override_v = ImGui.SliderInt(ctx, "Circle segments override", app.rendering.circle_segments_override_v, 3, 40)
      if rv then
        app.rendering.circle_segments_override = true
      else
      end
      do
        local rv_1267_, arg1_1266_ = nil, nil
        do
          local arg1_1266_0 = app.rendering.curve_segments_override
          local _24 = arg1_1266_0
          rv_1267_, arg1_1266_ = ImGui.Checkbox(ctx, "##curvessegmentoverride", _24)
        end
        app.rendering.curve_segments_override = arg1_1266_
      end
      ImGui.SameLine(ctx, 0, item_inner_spacing_x)
      rv, app.rendering.curve_segments_override_v = ImGui.SliderInt(ctx, "Curves segments override", app.rendering.curve_segments_override_v, 3, 40)
      if rv then
        app.rendering.curve_segments_override = true
      else
      end
      do
        local rv_1270_, arg1_1269_ = nil, nil
        do
          local arg1_1269_0 = app.rendering.col
          local _24 = arg1_1269_0
          rv_1270_, arg1_1269_ = ImGui.ColorEdit4(ctx, "Color", _24)
        end
        app.rendering.col = arg1_1269_
      end
      local p = {ImGui.GetCursorScreenPos(ctx)}
      local spacing = 10
      local corners_tl_br = (ImGui.DrawFlags_RoundCornersTopLeft() | ImGui.DrawFlags_RoundCornersBottomRight())
      local col = app.rendering.col
      local sz = app.rendering.sz
      local rounding = (sz / 5)
      local circle_segments = ((app.rendering.circle_segments_override and app.rendering.circle_segments_override_v) or 0)
      local curve_segments = ((app.rendering.curve_segments_override and app.rendering.curve_segments_override_v) or 0)
      local x = (p[1] + 4)
      local y = (p[2] + 4)
      for n = 1, 2 do
        local th = (((n == 1) and 1) or app.rendering.thickness)
        ImGui.DrawList_AddNgon(draw_list, (x + (sz * 0.5)), (y + (sz * 0.5)), (sz * 0.5), col, app.rendering.ngon_sides, th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddCircle(draw_list, (x + (sz * 0.5)), (y + (sz * 0.5)), (sz * 0.5), col, circle_segments, th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddRect(draw_list, x, y, (x + sz), (y + sz), col, 0, ImGui.DrawFlags_None(), th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddRect(draw_list, x, y, (x + sz), (y + sz), col, rounding, ImGui.DrawFlags_None(), th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddRect(draw_list, x, y, (x + sz), (y + sz), col, rounding, corners_tl_br, th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddTriangle(draw_list, (x + (sz * 0.5)), y, (x + sz), ((y + sz) - 0.5), x, ((y + sz) - 0.5), col, th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddLine(draw_list, x, y, (x + sz), y, col, th)
        x = ((x + sz) + spacing)
        ImGui.DrawList_AddLine(draw_list, x, y, x, (y + sz), col, th)
        x = (x + spacing)
        ImGui.DrawList_AddLine(draw_list, x, y, (x + sz), (y + sz), col, th)
        x = ((x + sz) + spacing)
        local cp3 = {{x, (y + (sz * 0.6))}, {(x + (sz * 0.5)), (y - (sz * 0.4))}, {(x + sz), (y + sz)}}
        ImGui.DrawList_AddBezierQuadratic(draw_list, ((cp3)[1])[1], ((cp3)[1])[2], ((cp3)[2])[1], ((cp3)[2])[2], ((cp3)[3])[1], ((cp3)[3])[2], col, th, curve_segments)
        x = (x + sz + spacing)
        local cp4 = {{x, y}, {(x + (sz * 1.3)), (y + (sz * 0.3))}, {((x + sz) - (sz * 1.3)), ((y + sz) - (sz * 0.3))}, {(x + sz), (y + sz)}}
        ImGui.DrawList_AddBezierCubic(draw_list, ((cp4)[1])[1], ((cp4)[1])[2], ((cp4)[2])[1], ((cp4)[2])[2], ((cp4)[3])[1], ((cp4)[3])[2], ((cp4)[4])[1], ((cp4)[4])[2], col, th, curve_segments)
        x = (p[1] + 4)
        y = ((y + sz) + spacing)
      end
      ImGui.DrawList_AddNgonFilled(draw_list, (x + (sz * 0.5)), (y + (sz * 0.5)), (sz * 0.5), col, app.rendering.ngon_sides)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddCircleFilled(draw_list, (x + (sz * 0.5)), (y + (sz * 0.5)), (sz * 0.5), col, circle_segments)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + sz), (y + sz), col)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + sz), (y + sz), col, 10)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + sz), (y + sz), col, 10, corners_tl_br)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddTriangleFilled(draw_list, (x + (sz * 0.5)), y, (x + sz), ((y + sz) - 0.5), x, ((y + sz) - 0.5), col)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + sz), (y + app.rendering.thickness), col)
      x = ((x + sz) + spacing)
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + app.rendering.thickness), (y + sz), col)
      x = (x + (spacing * 2))
      ImGui.DrawList_AddRectFilled(draw_list, x, y, (x + 1), (y + 1), col)
      x = (x + sz)
      ImGui.DrawList_AddRectFilledMultiColor(draw_list, x, y, (x + sz), (y + sz), 255, 4278190335, 4294902015, 16711935)
      ImGui.Dummy(ctx, ((sz + spacing) * 10.2), ((sz + spacing) * 3))
      ImGui.PopItemWidth(ctx)
      ImGui.EndTabItem(ctx)
    else
    end
    if ImGui.BeginTabItem(ctx, "Canvas") then
      rv, app.rendering.opt_enable_grid = ImGui.Checkbox(ctx, "Enable grid", app.rendering.opt_enable_grid)
      rv, app.rendering.opt_enable_context_menu = ImGui.Checkbox(ctx, "Enable context menu", app.rendering.opt_enable_context_menu)
      ImGui.Text(ctx, "Mouse Left: drag to add lines,\nMouse Right: drag to scroll, click for context menu.")
      local canvas_p0 = {ImGui.GetCursorScreenPos(ctx)}
      local canvas_sz = {ImGui.GetContentRegionAvail(ctx)}
      if (canvas_sz[1] < 50) then
        canvas_sz[1] = 50
      else
      end
      if (canvas_sz[2] < 50) then
        canvas_sz[2] = 50
      else
      end
      local canvas_p1 = {((canvas_p0)[1] + canvas_sz[1]), ((canvas_p0)[2] + canvas_sz[2])}
      local mouse_pos = {ImGui.GetMousePos(ctx)}
      local draw_list = ImGui.GetWindowDrawList(ctx)
      ImGui.DrawList_AddRectFilled(draw_list, (canvas_p0)[1], (canvas_p0)[2], (canvas_p1)[1], (canvas_p1)[2], 842150655)
      ImGui.DrawList_AddRect(draw_list, (canvas_p0)[1], (canvas_p0)[2], (canvas_p1)[1], (canvas_p1)[2], 4294967295)
      ImGui.InvisibleButton(ctx, "canvas", canvas_sz[1], canvas_sz[2], (ImGui.ButtonFlags_MouseButtonLeft() | ImGui.ButtonFlags_MouseButtonRight()))
      local is_hovered = ImGui.IsItemHovered(ctx)
      local is_active = ImGui.IsItemActive(ctx)
      local origin = {((canvas_p0)[1] + app.rendering.scrolling[1]), ((canvas_p0)[2] + app.rendering.scrolling[2])}
      local mouse_pos_in_canvas = {(mouse_pos[1] - origin[1]), (mouse_pos[2] - origin[2])}
      if ((is_hovered and not app.rendering.adding_line) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left())) then
        table.insert(app.rendering.points, mouse_pos_in_canvas)
        table.insert(app.rendering.points, mouse_pos_in_canvas)
        app.rendering.adding_line = true
      else
      end
      if app.rendering.adding_line then
        app.rendering.points[#app.rendering.points] = mouse_pos_in_canvas
        if not ImGui.IsMouseDown(ctx, ImGui.MouseButton_Left()) then
          app.rendering.adding_line = false
        else
        end
      else
      end
      local mouse_threshold_for_pan = ((app.rendering.opt_enable_context_menu and ( - 1)) or 0)
      if (is_active and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Right(), mouse_threshold_for_pan)) then
        local mouse_delta = {ImGui.GetMouseDelta(ctx)}
        app.rendering.scrolling[1] = (app.rendering.scrolling[1] + mouse_delta[1])
        do end (app.rendering.scrolling)[2] = (app.rendering.scrolling[2] + mouse_delta[2])
      else
      end
      local function remove_last_line()
        table.remove(app.rendering.points)
        return table.remove(app.rendering.points)
      end
      local drag_delta = {ImGui.GetMouseDragDelta(ctx, 0, 0, ImGui.MouseButton_Right())}
      if ((app.rendering.opt_enable_context_menu and (drag_delta[1] == 0)) and (drag_delta[2] == 0)) then
        ImGui.OpenPopupOnItemClick(ctx, "context", ImGui.PopupFlags_MouseButtonRight())
      else
      end
      if ImGui.BeginPopup(ctx, "context") then
        if app.rendering.adding_line then
          remove_last_line()
          app.rendering.adding_line = false
        else
        end
        if ImGui.MenuItem(ctx, "Remove one", nil, false, (#app.rendering.points > 0)) then
          remove_last_line()
        else
        end
        if ImGui.MenuItem(ctx, "Remove all", nil, false, (#app.rendering.points > 0)) then
          app.rendering.points = {}
        else
        end
        ImGui.EndPopup(ctx)
      else
      end
      ImGui.DrawList_PushClipRect(draw_list, (canvas_p0)[1], (canvas_p0)[2], (canvas_p1)[1], (canvas_p1)[2], true)
      if app.rendering.opt_enable_grid then
        local GRID_STEP = 64
        local x = math.fmod(app.rendering.scrolling[1], GRID_STEP)
        while (x < canvas_sz[1]) do
          ImGui.DrawList_AddLine(draw_list, ((canvas_p0)[1] + x), (canvas_p0)[2], ((canvas_p0)[1] + x), (canvas_p1)[2], 3368601640)
          x = (x + GRID_STEP)
        end
        local y = math.fmod(app.rendering.scrolling[2], GRID_STEP)
        while (y < canvas_sz[2]) do
          ImGui.DrawList_AddLine(draw_list, (canvas_p0)[1], ((canvas_p0)[2] + y), (canvas_p1)[1], ((canvas_p0)[2] + y), 3368601640)
          y = (y + GRID_STEP)
        end
      else
      end
      local n = 1
      while (n < #app.rendering.points) do
        ImGui.DrawList_AddLine(draw_list, (origin[1] + app.rendering.points[n][1]), (origin[2] + app.rendering.points[n][2]), (origin[1] + (app.rendering.points[(n + 1)])[1]), (origin[2] + (app.rendering.points[(n + 1)])[2]), 4294902015, 2)
        n = (n + 2)
      end
      ImGui.DrawList_PopClipRect(draw_list)
      ImGui.EndTabItem(ctx)
    else
    end
    if ImGui.BeginTabItem(ctx, "BG/FG draw lists") then
      rv, app.rendering.draw_bg = ImGui.Checkbox(ctx, "Draw in Background draw list", app.rendering.draw_bg)
      ImGui.SameLine(ctx)
      demo.HelpMarker("The Background draw list will be rendered below every Dear ImGui windows.")
      rv, app.rendering.draw_fg = ImGui.Checkbox(ctx, "Draw in Foreground draw list", app.rendering.draw_fg)
      ImGui.SameLine(ctx)
      demo.HelpMarker("The Foreground draw list will be rendered over every Dear ImGui windows.")
      local window_pos = {ImGui.GetWindowPos(ctx)}
      local window_size = {ImGui.GetWindowSize(ctx)}
      local window_center = {(window_pos[1] + (window_size[1] * 0.5)), (window_pos[2] + (window_size[2] * 0.5))}
      if app.rendering.draw_bg then
        ImGui.DrawList_AddCircle(ImGui.GetBackgroundDrawList(ctx), window_center[1], window_center[2], (window_size[1] * 0.6), 4278190280, nil, (10 + 4))
      else
      end
      if app.rendering.draw_fg then
        ImGui.DrawList_AddCircle(ImGui.GetForegroundDrawList(ctx), window_center[1], window_center[2], (window_size[2] * 0.6), 16711880, nil, 10)
      else
      end
      ImGui.EndTabItem(ctx)
    else
    end
    ImGui.EndTabBar(ctx)
  else
  end
  ImGui.End(ctx)
  return open
end
local tbl_14_auto = {}
for _, f in ipairs({"ShowDemoWindow", "ShowStyleEditor", "PushStyle", "PopStyle"}) do
  local k_15_auto, v_16_auto = nil, nil
  local function _1289_(user_ctx, ...)
    ctx = user_ctx
    return demo[f](...)
  end
  k_15_auto, v_16_auto = f, _1289_
  if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
    tbl_14_auto[k_15_auto] = v_16_auto
  else
  end
end
return tbl_14_auto
