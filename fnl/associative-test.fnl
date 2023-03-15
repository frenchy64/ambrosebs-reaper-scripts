(local Im-gui {})

(each [name func (pairs reaper)]
  (set-forcibly! name (name:match "^ImGui_(.+)$"))
  (when name (tset Im-gui name func)))

(var ctx nil)

(local (FLT_MIN FLT_MAX) (Im-gui.NumericLimits_Float))

(local (IMGUI_VERSION IMGUI_VERSION_NUM REAIMGUI_VERSION) (Im-gui.GetVersion))

(local demo {:menu {:b true :enabled true :f 0.5 :n 0}
             :no_background false
             :no_close false
             :no_collapse false
             :no_docking false
             :no_menu false
             :no_move false
             :no_nav false
             :no_resize false
             :no_scrollbar false
             :no_titlebar false
             :open true
             :unsaved_document false})

(local show-app {:about false
                 :auto_resize false
                 :console false
                 :constrained_resize false
                 :custom_rendering false
                 :debug_log false
                 :documents false
                 :fullscreen false
                 :layout false
                 :log false
                 :long_text false
                 :metrics false
                 :property_editor false
                 :simple_overlay false
                 :stack_tool false
                 :style_editor false
                 :window_titles false})

(local config {})

(local widgets {})

(local layout {})

(local popups {})

(local tables {})

(local misc {})

(local app {})

(local cache {})

(fn demo.loop [] (demo.PushStyle) (set demo.open (demo.ShowDemoWindow true))
  (demo.PopStyle)
  (when demo.open (reaper.defer demo.loop)))

(when (= (select 2 (reaper.get_action_context))
         (: (. (debug.getinfo 1 :S) :source) :sub 2))
  (set _G.demo demo)
  (set _G.widgets widgets)
  (set _G.layout layout)
  (set _G.popups popups)
  (set _G.tables tables)
  (set _G.misc misc)
  (set _G.app app)
  (set ctx (Im-gui.CreateContext "ReaImGui Demo"
                                 (Im-gui.ConfigFlags_DockingEnable)))
  (reaper.defer demo.loop))

(fn demo.HelpMarker [desc]
  (Im-gui.TextDisabled ctx "(?)")
  (when (Im-gui.IsItemHovered ctx (Im-gui.HoveredFlags_DelayShort))
    (Im-gui.BeginTooltip ctx)
    (Im-gui.PushTextWrapPos ctx (* (Im-gui.GetFontSize ctx) 35))
    (Im-gui.Text ctx desc)
    (Im-gui.PopTextWrapPos ctx)
    (Im-gui.EndTooltip ctx)))

(fn demo.RgbaToArgb [rgba]
  (bor (band (rshift rgba 8) 16777215) (band (lshift rgba 24) 4278190080)))

(fn demo.ArgbToRgba [argb]
  (bor (band (lshift argb 8) 4294967040) (band (rshift argb 24) 255)))

(fn demo.round [n] (math.floor (+ n 0.5)))

(fn demo.clamp [v mn mx] (when (< v mn) (lua "return mn"))
  (when (> v mx) (lua "return mx"))
  v)

(fn demo.Link [url]
  (when (not reaper.CF_ShellExecute) (Im-gui.Text ctx url) (lua "return "))
  (local color (Im-gui.GetStyleColor ctx (Im-gui.Col_CheckMark)))
  (Im-gui.TextColored ctx color url)
  (if (Im-gui.IsItemClicked ctx) (reaper.CF_ShellExecute url)
      (Im-gui.IsItemHovered ctx) (Im-gui.SetMouseCursor ctx
                                                        (Im-gui.MouseCursor_Hand))))

(fn demo.HSV [h s v a]
  (let [(r g b) (Im-gui.ColorConvertHSVtoRGB h s v)]
    (Im-gui.ColorConvertDouble4ToU32 r g b (or a 1))))

(fn demo.EachEnum [enum]
  (var enum-cache (. cache enum))
  (when (not enum-cache)
    (set enum-cache {})
    (tset cache enum enum-cache)
    (each [func-name func (pairs reaper)]
      (local enum-name (func-name:match (: "^ImGui_%s_(.+)$" :format enum)))
      (when enum-name
        (table.insert enum-cache [(func) enum-name])))
    (table.sort enum-cache (fn [a b] (< (. a 1) (. b 1)))))
  (var i 0)
  (fn []
    (set i (+ i 1))
    (when (not (. enum-cache i)) (lua "return "))
    (table.unpack (. enum-cache i))))

(fn demo.DockName [dock-id]
  (if (= dock-id 0) (lua "return \"Floating\"") (> dock-id 0)
      (let [___antifnl_rtn_1___ (: "ImGui docker %d" :format dock-id)]
        (lua "return ___antifnl_rtn_1___")))
  (local positions {0 :Bottom 1 :Left 2 :Top 3 :Right 4 :Floating})
  (local position (or (and reaper.DockGetPosition
                           (. positions (reaper.DockGetPosition (bnot dock-id))))
                      :Unknown))
  (: "REAPER docker %d (%s)" :format (- dock-id) position))

(fn demo.ShowDemoWindow [open]
  (var rv nil)
  (when show-app.documents
    (set show-app.documents (demo.ShowExampleAppDocuments)))
  (when show-app.console (set show-app.console (demo.ShowExampleAppConsole)))
  (when show-app.log (set show-app.log (demo.ShowExampleAppLog)))
  (when show-app.layout (set show-app.layout (demo.ShowExampleAppLayout)))
  (when show-app.property_editor
    (set show-app.property_editor (demo.ShowExampleAppPropertyEditor)))
  (when show-app.long_text
    (set show-app.long_text (demo.ShowExampleAppLongText)))
  (when show-app.auto_resize
    (set show-app.auto_resize (demo.ShowExampleAppAutoResize)))
  (when show-app.constrained_resize
    (set show-app.constrained_resize (demo.ShowExampleAppConstrainedResize)))
  (when show-app.simple_overlay
    (set show-app.simple_overlay (demo.ShowExampleAppSimpleOverlay)))
  (when show-app.fullscreen
    (set show-app.fullscreen (demo.ShowExampleAppFullscreen)))
  (when show-app.window_titles (demo.ShowExampleAppWindowTitles))
  (when show-app.custom_rendering
    (set show-app.custom_rendering (demo.ShowExampleAppCustomRendering)))
  (when show-app.metrics
    (set show-app.metrics (Im-gui.ShowMetricsWindow ctx show-app.metrics)))
  (when show-app.debug_log
    (set show-app.debug_log (Im-gui.ShowDebugLogWindow ctx show-app.debug_log)))
  (when show-app.stack_tool
    (set show-app.stack_tool
         (Im-gui.ShowStackToolWindow ctx show-app.stack_tool)))
  (when show-app.about
    (set show-app.about (Im-gui.ShowAboutWindow ctx show-app.about)))
  (when show-app.style_editor
    (set (rv show-app.style_editor)
         (Im-gui.Begin ctx "Dear ImGui Style Editor" true))
    (when rv (demo.ShowStyleEditor) (Im-gui.End ctx)))
  (var window-flags (Im-gui.WindowFlags_None))
  (when demo.no_titlebar
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoTitleBar))))
  (when demo.no_scrollbar
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoScrollbar))))
  (when (not demo.no_menu)
    (set window-flags (bor window-flags (Im-gui.WindowFlags_MenuBar))))
  (when demo.no_move
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoMove))))
  (when demo.no_resize
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoResize))))
  (when demo.no_collapse
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoCollapse))))
  (when demo.no_nav
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoNav))))
  (when demo.no_background
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoBackground))))
  (when demo.no_docking
    (set window-flags (bor window-flags (Im-gui.WindowFlags_NoDocking))))
  (when demo.topmost
    (set window-flags (bor window-flags (Im-gui.WindowFlags_TopMost))))
  (when demo.unsaved_document
    (set window-flags (bor window-flags (Im-gui.WindowFlags_UnsavedDocument))))
  (when demo.no_close (set-forcibly! open false))
  (local main-viewport (Im-gui.GetMainViewport ctx))
  (local work-pos [(Im-gui.Viewport_GetWorkPos main-viewport)])
  (Im-gui.SetNextWindowPos ctx (+ (. work-pos 1) 20) (+ (. work-pos 2) 20)
                           (Im-gui.Cond_FirstUseEver))
  (Im-gui.SetNextWindowSize ctx 550 680 (Im-gui.Cond_FirstUseEver))
  (when demo.set_dock_id (Im-gui.SetNextWindowDockID ctx demo.set_dock_id)
    (set demo.set_dock_id nil))
  (set-forcibly! (rv open)
                 (Im-gui.Begin ctx "Dear ImGui Demo" open window-flags))
  (when (not rv) (lua "return open"))
  (Im-gui.PushItemWidth ctx (* (Im-gui.GetFontSize ctx) (- 12)))
  (when (Im-gui.BeginMenuBar ctx)
    (when (Im-gui.BeginMenu ctx :Menu) (demo.ShowExampleMenuFile)
      (Im-gui.EndMenu ctx))
    (when (Im-gui.BeginMenu ctx :Examples)
      (set (rv show-app.console)
           (Im-gui.MenuItem ctx :Console nil show-app.console false))
      (set (rv show-app.log) (Im-gui.MenuItem ctx :Log nil show-app.log))
      (set (rv show-app.layout)
           (Im-gui.MenuItem ctx "Simple layout" nil show-app.layout))
      (set (rv show-app.property_editor)
           (Im-gui.MenuItem ctx "Property editor" nil show-app.property_editor))
      (set (rv show-app.long_text)
           (Im-gui.MenuItem ctx "Long text display" nil show-app.long_text))
      (set (rv show-app.auto_resize)
           (Im-gui.MenuItem ctx "Auto-resizing window" nil show-app.auto_resize))
      (set (rv show-app.constrained_resize)
           (Im-gui.MenuItem ctx "Constrained-resizing window" nil
                            show-app.constrained_resize))
      (set (rv show-app.simple_overlay)
           (Im-gui.MenuItem ctx "Simple overlay" nil show-app.simple_overlay))
      (set (rv show-app.fullscreen)
           (Im-gui.MenuItem ctx "Fullscreen window" nil show-app.fullscreen))
      (set (rv show-app.window_titles)
           (Im-gui.MenuItem ctx "Manipulating window titles" nil
                            show-app.window_titles))
      (set (rv show-app.custom_rendering)
           (Im-gui.MenuItem ctx "Custom rendering" nil
                            show-app.custom_rendering))
      (set (rv show-app.documents)
           (Im-gui.MenuItem ctx :Documents nil show-app.documents false))
      (Im-gui.EndMenu ctx))
    (when (Im-gui.BeginMenu ctx :Tools)
      (set (rv show-app.metrics)
           (Im-gui.MenuItem ctx :Metrics/Debugger nil show-app.metrics))
      (set (rv show-app.debug_log)
           (Im-gui.MenuItem ctx "Debug Log" nil show-app.debug_log))
      (set (rv show-app.stack_tool)
           (Im-gui.MenuItem ctx "Stack Tool" nil show-app.stack_tool))
      (set (rv show-app.style_editor)
           (Im-gui.MenuItem ctx "Style Editor" nil show-app.style_editor))
      (set (rv show-app.about)
           (Im-gui.MenuItem ctx "About Dear ImGui" nil show-app.about))
      (Im-gui.EndMenu ctx))
    (when (Im-gui.SmallButton ctx :Documentation)
      (local doc (: "%s/Data/reaper_imgui_doc.html" :format
                    (reaper.GetResourcePath)))
      (if reaper.CF_ShellExecute (reaper.CF_ShellExecute doc)
          (reaper.MB doc "ReaImGui Documentation" 0)))
    (Im-gui.EndMenuBar ctx))
  (Im-gui.Text ctx
               (: "dear imgui says hello. (%s) (%d) (ReaImGui %s)" :format
                  IMGUI_VERSION IMGUI_VERSION_NUM REAIMGUI_VERSION))
  (Im-gui.Spacing ctx)
  (when (Im-gui.CollapsingHeader ctx :Help)
    (Im-gui.Text ctx "ABOUT THIS DEMO:")
    (Im-gui.BulletText ctx
                       "Sections below are demonstrating many aspects of the library.")
    (Im-gui.BulletText ctx
                       "The \"Examples\" menu above leads to more demo contents.")
    (Im-gui.BulletText ctx
                       (.. "The \"Tools\" menu above gives access to: About Box, Style Editor,
"
                           "and Metrics/Debugger (general purpose Dear ImGui debugging tool)."))
    (Im-gui.Separator ctx)
    (Im-gui.Text ctx "PROGRAMMER GUIDE:")
    (Im-gui.BulletText ctx
                       "See the ShowDemoWindow() code in ReaImGui_Demo.lua. <- you are here!")
    (Im-gui.BulletText ctx "See example scripts in the examples/ folder.")
    (Im-gui.Indent ctx)
    (demo.Link "https://github.com/cfillion/reaimgui/tree/master/examples")
    (Im-gui.Unindent ctx)
    (Im-gui.BulletText ctx "Read the FAQ at ")
    (Im-gui.SameLine ctx 0 0)
    (demo.Link "https://www.dearimgui.org/faq/")
    (Im-gui.Separator ctx)
    (Im-gui.Text ctx "USER GUIDE:")
    (demo.ShowUserGuide))
  (when (Im-gui.CollapsingHeader ctx :Configuration)
    (when (Im-gui.TreeNode ctx "Configuration##2")
      (fn config-var-checkbox [name]
        (let [___var___ ((assert (. reaper (: "ImGui_%s" :format name))
                                 "unknown var"))
              (rv val) (Im-gui.Checkbox ctx name
                                        (Im-gui.GetConfigVar ctx ___var___))]
          (when rv
            (Im-gui.SetConfigVar ctx ___var___ (or (and val 1) 0)))))

      (set config.flags (Im-gui.GetConfigVar ctx (Im-gui.ConfigVar_Flags)))
      (Im-gui.SeparatorText ctx :General)
      (set (rv config.flags)
           (Im-gui.CheckboxFlags ctx :ConfigFlags_NavEnableKeyboard
                                 config.flags
                                 (Im-gui.ConfigFlags_NavEnableKeyboard)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Enable keyboard controls.")
      (set (rv config.flags)
           (Im-gui.CheckboxFlags ctx :ConfigFlags_NavEnableSetMousePos
                                 config.flags
                                 (Im-gui.ConfigFlags_NavEnableSetMousePos)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Instruct navigation to move the mouse cursor.")
      (set (rv config.flags)
           (Im-gui.CheckboxFlags ctx :ConfigFlags_NoMouse config.flags
                                 (Im-gui.ConfigFlags_NoMouse)))
      (when (not= (band config.flags (Im-gui.ConfigFlags_NoMouse)) 0)
        (when (< (% (Im-gui.GetTime ctx) 0.4) 0.2)
          (Im-gui.SameLine ctx)
          (Im-gui.Text ctx "<<PRESS SPACE TO DISABLE>>"))
        (when (Im-gui.IsKeyPressed ctx (Im-gui.Key_Space))
          (set config.flags
               (band config.flags (bnot (Im-gui.ConfigFlags_NoMouse))))))
      (set (rv config.flags)
           (Im-gui.CheckboxFlags ctx :ConfigFlags_NoMouseCursorChange
                                 config.flags
                                 (Im-gui.ConfigFlags_NoMouseCursorChange)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Instruct backend to not alter mouse cursor shape and visibility.")
      (set (rv config.flags)
           (Im-gui.CheckboxFlags ctx :ConfigFlags_NoSavedSettings config.flags
                                 (Im-gui.ConfigFlags_NoSavedSettings)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Globally disable loading and saving state to an .ini file")
      (set (rv config.flags)
           (Im-gui.CheckboxFlags ctx :ConfigFlags_DockingEnable config.flags
                                 (Im-gui.ConfigFlags_DockingEnable)))
      (Im-gui.SameLine ctx)
      (if (Im-gui.GetConfigVar ctx (Im-gui.ConfigVar_DockingWithShift))
          (demo.HelpMarker "Drag from window title bar or their tab to dock/undock. Hold SHIFT to enable docking.

Drag from window menu button (upper-left button) to undock an entire node (all windows).")
          (demo.HelpMarker "Drag from window title bar or their tab to dock/undock. Hold SHIFT to disable docking.

Drag from window menu button (upper-left button) to undock an entire node (all windows)."))
      (when (not= (band config.flags (Im-gui.ConfigFlags_DockingEnable)) 0)
        (Im-gui.Indent ctx)
        (config-var-checkbox :ConfigVar_DockingNoSplit)
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.")
        (config-var-checkbox :ConfigVar_DockingWithShift)
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Enable docking when holding Shift only (allow to drop in wider space, reduce visual noise)")
        (config-var-checkbox :ConfigVar_DockingTransparentPayload)
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Make window or viewport transparent when docking and only display docking boxes on the target viewport.")
        (Im-gui.Unindent ctx))
      (config-var-checkbox :ConfigVar_ViewportsNoDecoration)
      (config-var-checkbox :ConfigVar_InputTrickleEventQueue)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.")
      (Im-gui.SeparatorText ctx :Widgets)
      (config-var-checkbox :ConfigVar_InputTextCursorBlink)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Enable blinking cursor (optional as some users consider it to be distracting).")
      (config-var-checkbox :ConfigVar_InputTextEnterKeepActive)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Pressing Enter will keep item active and select contents (single-line only).")
      (config-var-checkbox :ConfigVar_DragClickToInputText)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving).")
      (config-var-checkbox :ConfigVar_WindowsResizeFromEdges)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Enable resizing of windows from their edges and from the lower-left corner.")
      (config-var-checkbox :ConfigVar_WindowsMoveFromTitleBarOnly)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Does not apply to windows without a title bar.")
      (config-var-checkbox :ConfigVar_MacOSXBehaviors)
      (Im-gui.Text ctx "Also see Style->Rendering for rendering options.")
      (Im-gui.SetConfigVar ctx (Im-gui.ConfigVar_Flags) config.flags)
      (Im-gui.TreePop ctx)
      (Im-gui.Spacing ctx))
    (when (Im-gui.TreeNode ctx :Style)
      (demo.HelpMarker "The same contents can be accessed in 'Tools->Style Editor'.")
      (demo.ShowStyleEditor)
      (Im-gui.TreePop ctx)
      (Im-gui.Spacing ctx))
    (when (Im-gui.TreeNode ctx :Capture/Logging)
      (when (not config.logging) (set config.logging {:auto_open_depth 2}))
      (demo.HelpMarker "The logging API redirects all text output so you can easily capture the content of a window or a block. Tree nodes can be automatically expanded.
Try opening any of the contents below in this window and then click one of the \"Log To\" button.")
      (Im-gui.PushID ctx :LogButtons)
      (local log-to-tty (Im-gui.Button ctx "Log To TTY"))
      (Im-gui.SameLine ctx)
      (local log-to-file (Im-gui.Button ctx "Log To File"))
      (Im-gui.SameLine ctx)
      (local log-to-clipboard (Im-gui.Button ctx "Log To Clipboard"))
      (Im-gui.SameLine ctx)
      (Im-gui.PushAllowKeyboardFocus ctx false)
      (Im-gui.SetNextItemWidth ctx 80)
      (set (rv config.logging.auto_open_depth)
           (Im-gui.SliderInt ctx "Open Depth" config.logging.auto_open_depth 0
                             9))
      (Im-gui.PopAllowKeyboardFocus ctx)
      (Im-gui.PopID ctx)
      (local depth config.logging.auto_open_depth)
      (when log-to-tty (Im-gui.LogToTTY ctx depth))
      (when log-to-file (Im-gui.LogToFile ctx depth))
      (when log-to-clipboard (Im-gui.LogToClipboard ctx depth))
      (demo.HelpMarker "You can also call ImGui.LogText() to output directly to the log without a visual output.")
      (when (Im-gui.Button ctx "Copy \"Hello, world!\" to clipboard")
        (Im-gui.LogToClipboard ctx depth)
        (Im-gui.LogText ctx "Hello, world!")
        (Im-gui.LogFinish ctx))
      (Im-gui.TreePop ctx)))
  (when (Im-gui.CollapsingHeader ctx "Window options")
    (when (Im-gui.BeginTable ctx :split 3) (Im-gui.TableNextColumn ctx)
      (set (rv demo.topmost) (Im-gui.Checkbox ctx "Always on top" demo.topmost))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_titlebar)
           (Im-gui.Checkbox ctx "No titlebar" demo.no_titlebar))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_scrollbar)
           (Im-gui.Checkbox ctx "No scrollbar" demo.no_scrollbar))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_menu) (Im-gui.Checkbox ctx "No menu" demo.no_menu))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_move) (Im-gui.Checkbox ctx "No move" demo.no_move))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_resize) (Im-gui.Checkbox ctx "No resize" demo.no_resize))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_collapse)
           (Im-gui.Checkbox ctx "No collapse" demo.no_collapse))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_close) (Im-gui.Checkbox ctx "No close" demo.no_close))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_nav) (Im-gui.Checkbox ctx "No nav" demo.no_nav))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_background)
           (Im-gui.Checkbox ctx "No background" demo.no_background))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.no_docking)
           (Im-gui.Checkbox ctx "No docking" demo.no_docking))
      (Im-gui.TableNextColumn ctx)
      (set (rv demo.unsaved_document)
           (Im-gui.Checkbox ctx "Unsaved document" demo.unsaved_document))
      (Im-gui.EndTable ctx))
    (local flags (Im-gui.GetConfigVar ctx (Im-gui.ConfigVar_Flags)))
    (local docking-disabled (or demo.no_docking
                                (= (band flags
                                         (Im-gui.ConfigFlags_DockingEnable))
                                   0)))
    (Im-gui.Spacing ctx)
    (when docking-disabled (Im-gui.BeginDisabled ctx))
    (local dock-id (Im-gui.GetWindowDockID ctx))
    (Im-gui.AlignTextToFramePadding ctx)
    (Im-gui.Text ctx "Dock in docker:")
    (Im-gui.SameLine ctx)
    (Im-gui.SetNextItemWidth ctx 222)
    (when (Im-gui.BeginCombo ctx "##docker" (demo.DockName dock-id))
      (when (Im-gui.Selectable ctx :Floating (= dock-id 0))
        (set demo.set_dock_id 0))
      (for [id (- 1) (- 16) (- 1)]
        (when (Im-gui.Selectable ctx (demo.DockName id) (= dock-id id))
          (set demo.set_dock_id id)))
      (Im-gui.EndCombo ctx))
    (when docking-disabled
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx
                   (: "Disabled via %s" :format
                      (or (and demo.no_docking :WindowFlags) :ConfigFlags)))
      (Im-gui.EndDisabled ctx)))
  (demo.ShowDemoWindowWidgets)
  (demo.ShowDemoWindowLayout)
  (demo.ShowDemoWindowPopups)
  (demo.ShowDemoWindowTables)
  (demo.ShowDemoWindowInputs)
  (Im-gui.PopItemWidth ctx)
  (Im-gui.End ctx)
  open)

(fn demo.ShowDemoWindowWidgets []
  (when (not (Im-gui.CollapsingHeader ctx :Widgets)) (lua "return "))
  (when widgets.disable_all (Im-gui.BeginDisabled ctx))
  (var rv nil)
  (when (Im-gui.TreeNode ctx :Basic)
    (when (not widgets.basic)
      (set widgets.basic
           {:angle 0
            :check true
            :clicked 0
            :col1 16711731
            :col2 1722941567
            :counter 0
            :curitem 0
            :d0 999999.00000001
            :d1 10000000000
            :d2 1
            :d3 0.0067
            :d4 0.123
            :d5 0
            :elem 1
            :i0 123
            :i1 50
            :i2 42
            :i3 0
            :listcur 0
            :radio 0
            :str0 "Hello, world!"
            :str1 ""
            :tooltip (reaper.new_array [0.6 0.1 1 0.5 0.92 0.1 0.2])
            :vec4a (reaper.new_array [0.1 0.2 0.3 0.44])}))
    (Im-gui.SeparatorText ctx :General)
    (when (Im-gui.Button ctx :Button)
      (set widgets.basic.clicked (+ widgets.basic.clicked 1)))
    (when (not= (band widgets.basic.clicked 1) 0) (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "Thanks for clicking me!"))
    (set (rv widgets.basic.check)
         (Im-gui.Checkbox ctx :checkbox widgets.basic.check))
    (set (rv widgets.basic.radio)
         (Im-gui.RadioButtonEx ctx "radio a" widgets.basic.radio 0))
    (Im-gui.SameLine ctx)
    (set (rv widgets.basic.radio)
         (Im-gui.RadioButtonEx ctx "radio b" widgets.basic.radio 1))
    (Im-gui.SameLine ctx)
    (set (rv widgets.basic.radio)
         (Im-gui.RadioButtonEx ctx "radio c" widgets.basic.radio 2))
    (for [i 0 6]
      (when (> i 0) (Im-gui.SameLine ctx))
      (Im-gui.PushID ctx i)
      (Im-gui.PushStyleColor ctx (Im-gui.Col_Button)
                             (demo.HSV (/ i 7) 0.6 0.6 1))
      (Im-gui.PushStyleColor ctx (Im-gui.Col_ButtonHovered)
                             (demo.HSV (/ i 7) 0.7 0.7 1))
      (Im-gui.PushStyleColor ctx (Im-gui.Col_ButtonActive)
                             (demo.HSV (/ i 7) 0.8 0.8 1))
      (Im-gui.Button ctx :Click)
      (Im-gui.PopStyleColor ctx 3)
      (Im-gui.PopID ctx))
    (Im-gui.AlignTextToFramePadding ctx)
    (Im-gui.Text ctx "Hold to repeat:")
    (Im-gui.SameLine ctx)
    (local spacing (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemInnerSpacing)))
    (Im-gui.PushButtonRepeat ctx true)
    (when (Im-gui.ArrowButton ctx "##left" (Im-gui.Dir_Left))
      (set widgets.basic.counter (- widgets.basic.counter 1)))
    (Im-gui.SameLine ctx 0 spacing)
    (when (Im-gui.ArrowButton ctx "##right" (Im-gui.Dir_Right))
      (set widgets.basic.counter (+ widgets.basic.counter 1)))
    (Im-gui.PopButtonRepeat ctx)
    (Im-gui.SameLine ctx)
    (Im-gui.Text ctx (: "%d" :format widgets.basic.counter))
    (do
      (Im-gui.Text ctx "Tooltips:")
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx :Button)
      (when (Im-gui.IsItemHovered ctx) (Im-gui.SetTooltip ctx "I am a tooltip"))
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx :Fancy)
      (when (Im-gui.IsItemHovered ctx)
        (Im-gui.BeginTooltip ctx)
        (Im-gui.Text ctx "I am a fancy tooltip")
        (Im-gui.PlotLines ctx :Curve widgets.basic.tooltip)
        (Im-gui.Text ctx
                     (: "Sin(time) = %f" :format
                        (math.sin (Im-gui.GetTime ctx))))
        (Im-gui.EndTooltip ctx))
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx :Delayed)
      (when (Im-gui.IsItemHovered ctx (Im-gui.HoveredFlags_DelayNormal))
        (Im-gui.SetTooltip ctx "I am a tooltip with a delay."))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Tooltip are created by using the IsItemHovered() function over any kind of item."))
    (Im-gui.LabelText ctx :label :Value)
    (Im-gui.SeparatorText ctx :Inputs)
    (do
      (set (rv widgets.basic.str0)
           (Im-gui.InputText ctx "input text" widgets.basic.str0))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "USER:
Hold SHIFT or use mouse to select text.
CTRL+Left/Right to word jump.
CTRL+A or double-click to select all.
CTRL+X,CTRL+C,CTRL+V clipboard.
CTRL+Z,CTRL+Y undo/redo.
ESCAPE to revert.

")
      (set (rv widgets.basic.str1)
           (Im-gui.InputTextWithHint ctx "input text (w/ hint)"
                                     "enter text here" widgets.basic.str1))
      (set (rv widgets.basic.i0)
           (Im-gui.InputInt ctx "input int" widgets.basic.i0))
      (set (rv widgets.basic.d0)
           (Im-gui.InputDouble ctx "input double" widgets.basic.d0 0.01 1
                               "%.8f"))
      (set (rv widgets.basic.d1)
           (Im-gui.InputDouble ctx "input scientific" widgets.basic.d1 0 0 "%e"))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "You can input value using the scientific notation,
e.g. \"1e+8\" becomes \"100000000\".")
      (Im-gui.InputDoubleN ctx "input reaper.array" widgets.basic.vec4a))
    (Im-gui.SeparatorText ctx :Drags)
    (do
      (set (rv widgets.basic.i1)
           (Im-gui.DragInt ctx "drag int" widgets.basic.i1 1))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Click and drag to edit value.
Hold SHIFT/ALT for faster/slower edit.
Double-click or CTRL+click to input value.")
      (set (rv widgets.basic.i2)
           (Im-gui.DragInt ctx "drag int 0..100" widgets.basic.i2 1 0 100
                           "%d%%" (Im-gui.SliderFlags_AlwaysClamp)))
      (set (rv widgets.basic.d2)
           (Im-gui.DragDouble ctx "drag double" widgets.basic.d2 0.005))
      (set (rv widgets.basic.d3)
           (Im-gui.DragDouble ctx "drag small double" widgets.basic.d3 0.0001 0
                              0 "%.06f ns")))
    (Im-gui.SeparatorText ctx :Sliders)
    (do
      (set (rv widgets.basic.i3)
           (Im-gui.SliderInt ctx "slider int" widgets.basic.i3 (- 1) 3))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "CTRL+click to input value.")
      (set (rv widgets.basic.d4)
           (Im-gui.SliderDouble ctx "slider double" widgets.basic.d4 0 1
                                "ratio = %.3f"))
      (set (rv widgets.basic.d5)
           (Im-gui.SliderDouble ctx "slider double (log)" widgets.basic.d5
                                (- 10) 10 "%.4f"
                                (Im-gui.SliderFlags_Logarithmic)))
      (set (rv widgets.basic.angle)
           (Im-gui.SliderAngle ctx "slider angle" widgets.basic.angle))
      (local elements [:Fire :Earth :Air :Water])
      (local current-elem (or (. elements widgets.basic.elem) :Unknown))
      (set (rv widgets.basic.elem)
           (Im-gui.SliderInt ctx "slider enum" widgets.basic.elem 1
                             (length elements) current-elem))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Using the format string parameter to display a name instead of the underlying integer."))
    (Im-gui.SeparatorText ctx :Selectors/Pickers)
    (do
      (global foo widgets.basic.col1)
      (set (rv widgets.basic.col1)
           (Im-gui.ColorEdit3 ctx "color 1" widgets.basic.col1))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Click on the color square to open a color picker.
Click and hold to use drag and drop.
Right-click on the color square to show options.
CTRL+click on individual component to input value.")
      (set (rv widgets.basic.col2)
           (Im-gui.ColorEdit4 ctx "color 2" widgets.basic.col2)))
    (let [items "AAAA\000BBBB\000CCCC\000DDDD\000EEEE\000FFFF\000GGGG\000HHHH\000IIIIIII\000JJJJ\000KKKKKKK\000"]
      (set (rv widgets.basic.curitem)
           (Im-gui.Combo ctx :combo widgets.basic.curitem items))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker (.. "Using the simplified one-liner Combo API here.\n"
                           "Refer to the \"Combo\" section below for an explanation of how to use the more flexible and general BeginCombo/EndCombo API.")))
    (let [items "Apple\000Banana\000Cherry\000Kiwi\000Mango\000Orange\000Pineapple\000Strawberry\000Watermelon\000"]
      (set (rv widgets.basic.listcur)
           (Im-gui.ListBox ctx "listbox\n(single select)" widgets.basic.listcur
                           items 4))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Using the simplified one-liner ListBox API here.
Refer to the \"List boxes\" section below for an explanation of how to usethe more flexible and general BeginListBox/EndListBox API."))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Trees)
    (when (not widgets.trees)
      (set widgets.trees {:align_label_with_current_x_position false
                          :base_flags (bor (Im-gui.TreeNodeFlags_OpenOnArrow)
                                           (Im-gui.TreeNodeFlags_OpenOnDoubleClick)
                                           (Im-gui.TreeNodeFlags_SpanAvailWidth))
                          :selection_mask (lshift 1 2)
                          :test_drag_and_drop false}))
    (when (Im-gui.TreeNode ctx "Basic trees")
      (for [i 0 4]
        (when (= i 0) (Im-gui.SetNextItemOpen ctx true (Im-gui.Cond_Once)))
        (when (Im-gui.TreeNodeEx ctx i (: "Child %d" :format i))
          (Im-gui.Text ctx "blah blah")
          (Im-gui.SameLine ctx)
          (when (Im-gui.SmallButton ctx :button) nil)
          (Im-gui.TreePop ctx)))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Advanced, with Selectable nodes")
      (demo.HelpMarker "This is a more typical looking tree with selectable nodes.
Click to select, CTRL+Click to toggle, click on arrows or double-click to open.")
      (set (rv widgets.trees.base_flags)
           (Im-gui.CheckboxFlags ctx :ImGui_TreeNodeFlags_OpenOnArrow
                                 widgets.trees.base_flags
                                 (Im-gui.TreeNodeFlags_OpenOnArrow)))
      (set (rv widgets.trees.base_flags)
           (Im-gui.CheckboxFlags ctx :ImGui_TreeNodeFlags_OpenOnDoubleClick
                                 widgets.trees.base_flags
                                 (Im-gui.TreeNodeFlags_OpenOnDoubleClick)))
      (set (rv widgets.trees.base_flags)
           (Im-gui.CheckboxFlags ctx :ImGui_TreeNodeFlags_SpanAvailWidth
                                 widgets.trees.base_flags
                                 (Im-gui.TreeNodeFlags_SpanAvailWidth)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Extend hit area to all available width instead of allowing more items to be laid out after the node.")
      (set (rv widgets.trees.base_flags)
           (Im-gui.CheckboxFlags ctx :ImGuiTreeNodeFlags_SpanFullWidth
                                 widgets.trees.base_flags
                                 (Im-gui.TreeNodeFlags_SpanFullWidth)))
      (set (rv widgets.trees.align_label_with_current_x_position)
           (Im-gui.Checkbox ctx "Align label with current X position"
                            widgets.trees.align_label_with_current_x_position))
      (set (rv widgets.trees.test_drag_and_drop)
           (Im-gui.Checkbox ctx "Test tree node as drag source"
                            widgets.trees.test_drag_and_drop))
      (Im-gui.Text ctx :Hello!)
      (when widgets.trees.align_label_with_current_x_position
        (Im-gui.Unindent ctx (Im-gui.GetTreeNodeToLabelSpacing ctx)))
      (var node-clicked (- 1))
      (for [i 0 5]
        (var node-flags widgets.trees.base_flags)
        (local is-selected (not= (band widgets.trees.selection_mask
                                       (lshift 1 i))
                                 0))
        (when is-selected
          (set node-flags (bor node-flags (Im-gui.TreeNodeFlags_Selected))))
        (if (< i 3) (let [node-open (Im-gui.TreeNodeEx ctx i
                                                       (: "Selectable Node %d"
                                                          :format i)
                                                       node-flags)]
                      (when (and (Im-gui.IsItemClicked ctx)
                                 (not (Im-gui.IsItemToggledOpen ctx)))
                        (set node-clicked i))
                      (when (and widgets.trees.test_drag_and_drop
                                 (Im-gui.BeginDragDropSource ctx))
                        (Im-gui.SetDragDropPayload ctx :_TREENODE nil 0)
                        (Im-gui.Text ctx "This is a drag and drop source")
                        (Im-gui.EndDragDropSource ctx))
                      (when node-open
                        (Im-gui.BulletText ctx "Blah blah\nBlah Blah")
                        (Im-gui.TreePop ctx)))
            (do
              (set node-flags
                   (bor node-flags (Im-gui.TreeNodeFlags_Leaf)
                        (Im-gui.TreeNodeFlags_NoTreePushOnOpen)))
              (Im-gui.TreeNodeEx ctx i (: "Selectable Leaf %d" :format i)
                                 node-flags)
              (when (and (Im-gui.IsItemClicked ctx)
                         (not (Im-gui.IsItemToggledOpen ctx)))
                (set node-clicked i))
              (when (and widgets.trees.test_drag_and_drop
                         (Im-gui.BeginDragDropSource ctx))
                (Im-gui.SetDragDropPayload ctx :_TREENODE nil 0)
                (Im-gui.Text ctx "This is a drag and drop source")
                (Im-gui.EndDragDropSource ctx)))))
      (when (not= node-clicked (- 1))
        (if (Im-gui.IsKeyDown ctx (Im-gui.Mod_Ctrl))
            (set widgets.trees.selection_mask
                 (bxor widgets.trees.selection_mask (lshift 1 node-clicked)))
            (= (band widgets.trees.selection_mask (lshift 1 node-clicked)) 0)
            (set widgets.trees.selection_mask (lshift 1 node-clicked))))
      (when widgets.trees.align_label_with_current_x_position
        (Im-gui.Indent ctx (Im-gui.GetTreeNodeToLabelSpacing ctx)))
      (Im-gui.TreePop ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Collapsing Headers")
    (when (not widgets.cheads) (set widgets.cheads {:closable_group true}))
    (set (rv widgets.cheads.closable_group)
         (Im-gui.Checkbox ctx "Show 2nd header" widgets.cheads.closable_group))
    (when (Im-gui.CollapsingHeader ctx :Header nil (Im-gui.TreeNodeFlags_None))
      (Im-gui.Text ctx (: "IsItemHovered: %s" :format
                          (Im-gui.IsItemHovered ctx)))
      (for [i 0 4] (Im-gui.Text ctx (: "Some content %s" :format i))))
    (when widgets.cheads.closable_group
      (set (rv widgets.cheads.closable_group)
           (Im-gui.CollapsingHeader ctx "Header with a close button" true))
      (when rv
        (Im-gui.Text ctx
                     (: "IsItemHovered: %s" :format (Im-gui.IsItemHovered ctx)))
        (for [i 0 4] (Im-gui.Text ctx (: "More content %d" :format i)))))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Bullets) (Im-gui.BulletText ctx "Bullet point 1")
    (Im-gui.BulletText ctx "Bullet point 2\nOn multiple lines")
    (when (Im-gui.TreeNode ctx "Tree node")
      (Im-gui.BulletText ctx "Another bullet point")
      (Im-gui.TreePop ctx))
    (Im-gui.Bullet ctx)
    (Im-gui.Text ctx "Bullet point 3 (two calls)")
    (Im-gui.Bullet ctx)
    (Im-gui.SmallButton ctx :Button)
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Text)
    (when (not widgets.text)
      (set widgets.text {:utf8 "日本語" :wrap_width 200}))
    (when (Im-gui.TreeNode ctx "Colorful Text")
      (Im-gui.TextColored ctx 4278255615 :Pink)
      (Im-gui.TextColored ctx 4294902015 :Yellow)
      (Im-gui.TextDisabled ctx :Disabled)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "The TextDisabled color is stored in ImGuiStyle.")
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Word Wrapping")
      (Im-gui.TextWrapped ctx
                          (.. "This text should automatically wrap on the edge of the window. The current implementation "
                              "for text wrapping follows simple rules suitable for English and possibly other languages."))
      (Im-gui.Spacing ctx)
      (set (rv widgets.text.wrap_width)
           (Im-gui.SliderDouble ctx "Wrap width" widgets.text.wrap_width (- 20)
                                600 "%.0f"))
      (local draw-list (Im-gui.GetWindowDrawList ctx))
      (for [n 0 1]
        (Im-gui.Text ctx (: "Test paragraph %d:" :format n))
        (local (screen-x screen-y) (Im-gui.GetCursorScreenPos ctx))
        (local (marker-min-x marker-min-y)
               (values (+ screen-x widgets.text.wrap_width) screen-y))
        (local (marker-max-x marker-max-y)
               (values (+ screen-x widgets.text.wrap_width 10)
                       (+ screen-y (Im-gui.GetTextLineHeight ctx))))
        (local (window-x window-y) (Im-gui.GetCursorPos ctx))
        (Im-gui.PushTextWrapPos ctx (+ window-x widgets.text.wrap_width))
        (if (= n 0)
            (Im-gui.Text ctx
                         (: "The lazy dog is a good dog. This paragraph should fit within %.0f pixels. Testing a 1 character word. The quick brown fox jumps over the lazy dog."
                            :format widgets.text.wrap_width))
            (Im-gui.Text ctx
                         "aaaaaaaa bbbbbbbb, c cccccccc,dddddddd. d eeeeeeee   ffffffff. gggggggg!hhhhhhhh"))
        (local (text-min-x text-min-y) (Im-gui.GetItemRectMin ctx))
        (local (text-max-x text-max-y) (Im-gui.GetItemRectMax ctx))
        (Im-gui.DrawList_AddRect draw-list text-min-x text-min-y text-max-x
                                 text-max-y 4294902015)
        (Im-gui.DrawList_AddRectFilled draw-list marker-min-x marker-min-y
                                       marker-max-x marker-max-y 4278255615)
        (Im-gui.PopTextWrapPos ctx))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "UTF-8 Text")
      (Im-gui.TextWrapped ctx
                          "CJK text cannot be rendered due to current limitations regarding font rasterization. It is however safe to copy & paste from/into another application.")
      (demo.Link "https://github.com/cfillion/reaimgui/issues/5")
      (Im-gui.Spacing ctx)
      (Im-gui.Text ctx "Hiragana: かきくけこ (kakikukeko)")
      (Im-gui.Text ctx "Kanjis: 日本語 (nihongo)")
      (set (rv widgets.text.utf8)
           (Im-gui.InputText ctx "UTF-8 input" widgets.text.utf8))
      (Im-gui.TreePop ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Images)
    (when (not widgets.images)
      (set widgets.images {:pressed_count 0 :use_text_color_for_tint false}))
    (when (not (Im-gui.ValidatePtr widgets.images.bitmap :ImGui_Image*))
      (set widgets.images.bitmap
           (Im-gui.CreateImageFromMem "\137PNG\r
\026
\000\000\000\rIHDR\000\000\001\157\000\000\000E\b\000\000\000\000\180\174d\136\000\000\006-IDATx\218흿n\2276\028ǿ\195\001w\195\025G/\tph!\b\135\0032\020\b$ \030:\164\003\129+б0\244\006\234\024d\226Ա\131\243\000\029\184v\244\208\023\224+\232\021\244
z\133_\aJ\178\157\136\180\164#m\218\229oI\":$͏\249\251Kɠ!Q\020%\004\193\208\197\018۸2\161\210)\001\214ĥ\t\147\142\000\1282.M\144t\020\000\000u\\\155\016餚N\220<!\210\217\002\000D\137hy\002\164\179\006\192\020)H\a\189\243\255\221zJ\233\149\014\000V\017\017\184\143ޯ^\132\240I\167\002t\176\003\023\170-\210q\187~
\237\166\001T\164\019\026\029\209Q\001D\164\019\030\157\180\179?e\164\019\026\157m\187ej\184p\v\"\029\215vGtaO\164\019 \029mvJ`\029霝N\197\015$C\1989\231\143\127\183\128\251\150\199\236\241\240\239/K\224C\194O \217\207\003\023\019\023C?<p\158eY\246\215\235Ow\1735\155\192\133x\212\234p\154\027v\186,\225\160S\235d\239pN\004\000\002\131c6\f`tqt\1545:i\174\147N\190&\157l+/\143\014\239ᠺN:e\218\230\169닣#wp\024]'\029\137\186fp\146)pL\167\217p \021f:\249\142\142\024\221\193eѩ\177\201\001\164Mht\134\r\254>\157\029\156\188\025\221\193e\209ik\163n\206L\185\163c2\248\251t\222\217\224\184\247\024\206B\135Õ^sI\199d\240\247\233$\157Zk&t\0166\157F\029\2023\000d\202*\255>\023\143Y\241\167:*P\142\228y\183\182\031\015\026^\240\210\255\158\253\254\021\248Z\2523\169\131\249\130b\224bQ8\2329˔\002\128?P\139\003\249\006\000\183O\194\"O\247x\255\173(\138\213m!\142\b\196Dy\250%\001>\173\222\\\191\221-\238ac\129\221$\018\203|\140\029\028\025\216\246\230\134^\189Z\137\239\151$\017\002\000
\188v\129\142:\211\021\003\211/hr\233X\179\025\r\183\209\224\239k6n1\150\030<\134\147۝\138\029\165S\179\206*5\"g\181K:fí\140\006\127,\029\015\030é\2334)\000\182\197\230\136y\222\246\225E钎\217p+\163\193\031Kǃ\1990\153\206a\170s2\029\014\000\146RK\237\160\234\221\237-\128\174\144:\137\142)(\180\132\250\138\203\028\200Em\205\021\216\232\240gC\a#r\f\134\tO\166\131\003\153JGh8TZ\254S\244\0310yl\f\003\029\163\138\183\132\250\138\143\201\228X\233Xڎ\228\024L\019>-\157\170\155\194\214\018\139\242\190\227\0268Z?\197\004\021_Y\f\183_:V\143\193<\225\211\210\225\000r\"\162\198\018\140\238u,\025\242j*\029\139m\177\024n\191t\172\030\131y\194'\165#\129\206U\206\249\024:sr\0056\219b1\220~\233\216<\006˄OA\167\175\\/\000|х\211\005\150\159\147\135\225Z4\128\017\245趀\252敋\221\236^\151x\179\229\221\002X$C\245\224li,\031\235J;\231\156\243ef\158\144\181\237G\227\192\182\t\031^x\188\187Y\000\248\248\131\131\202\245r\169\023\250W\236\171}NDTu{9U\179\247NgH1A\197+\139\r\243\187wfڤ\131\189#\024\000Q\211\253\189\151x\167;IP1\171\a\195Gб\004w\152c[\206I\199b\147\246\150\167\201\001𚈞\239\188\208\225\218%\168پn,-\0305\017\017\149jZp\1359\182\229\156t,6i\143\206\026`:D\023k/tr@\234q\144\v\206d\201\208g\005\006\163Q\"\162\134M3\164\004i\f
äc\137bwt\020\176n\218\015\239\198\v\029\157^\171\001&\137\004\026\173\159RK&\135\1366|bp\1359\004\206JG\141\200\228\148\237\173hU\238\230f\245!:\169N\207l\250\247\\\234ԁ)\vJT\165\245\196\224\238:餲\215\250NʖCv\135S\127\vB\027\143\242\161㺻
B\149\014\006\163\204\018\220]'\029\016\017\169\220ٙ\133\183t\214-\029\189\014:\017Z\015\1669\155\018L*\181-yeN\197\025\130\187뤓o\168*\001\164\142n\026}\027\141&Xr\2063\232\184\239\230C\023\139\rƚw\201\205\210\016\174r\206\205Q\165\237`\1819\226\244\030\141\206k\219E\163\015K\000\203\207?\185:\161=\020\141\230DDL\1555\129\246\135\227\243\130׹w\\\203@\158-GMDB\143پi\161\145E:g\167#\245h9$\017\213\218Y+]\031\230\143tfҡ\028\021\0175\028e?t
\021\233\132A\167j]\224\141h_@\018\174\031\214\017\233̥Cr/BY\231D\rcU\164\019
\029\146].\143H\128\234\028\146\"\157`\232\144J\193e\221\250\b\140\185\127<h\1643\141\206\225Iݧ\213'\000\201-\128\247\171'\225\\,Gw\139dN\219ؓ\186\030ڰ\018\158dwR\247\245)w\245wQdE\241\219\222\233q\135b9\246\254\146\205k\027yp\252\197}\155w\169M\170\166qos\188h\182\209\202\214\243/8\173V\141t\230/W\179\017\155&\210\t\147\142b݃\r#\157\224\2324\186l\198\003\164\227W.\130\206\006{O\162\174\131\242
\"\157\190\166\217\222\255\161\"\157\000\247\142>\229T2\138tB\162\211ޢ!\181\r*OM\135\228\185\214@\210\005\208!\142\148\175\245l֞\190\a\225\226\030\167\023\014\157\170\175\024\148\1902|\145\206\252\229\146\f\162\"\218roO\159\187\184G\239\v
\134NwwH\026\191\186*\fy\243\228I)D\252ַP\228?\184\169h\006\027Ew\150\000\000\000\000IEND\174B`\130")))
    (Im-gui.TextWrapped ctx "Hover the texture for a zoomed view!")
    (local (my-tex-w my-tex-h) (Im-gui.Image_GetSize widgets.images.bitmap))
    (do
      (set (rv widgets.images.use_text_color_for_tint)
           (Im-gui.Checkbox ctx "Use Text Color for Tint"
                            widgets.images.use_text_color_for_tint))
      (Im-gui.Text ctx (: "%.0fx%.0f" :format my-tex-w my-tex-h))
      (local (pos-x pos-y) (Im-gui.GetCursorScreenPos ctx))
      (local (uv-min-x uv-min-y) (values 0 0))
      (local (uv-max-x uv-max-y) (values 1 1))
      (local tint-col (or (and widgets.images.use_text_color_for_tint
                               (Im-gui.GetStyleColor ctx (Im-gui.Col_Text)))
                          4294967295))
      (local border-col (Im-gui.GetStyleColor ctx (Im-gui.Col_Border)))
      (Im-gui.Image ctx widgets.images.bitmap my-tex-w my-tex-h uv-min-x
                    uv-min-y uv-max-x uv-max-y tint-col border-col)
      (when (Im-gui.IsItemHovered ctx)
        (Im-gui.BeginTooltip ctx)
        (local region-sz 32)
        (local (mouse-x mouse-y) (Im-gui.GetMousePos ctx))
        (var region-x (- (- mouse-x pos-x) (* region-sz 0.5)))
        (var region-y (- (- mouse-y pos-y) (* region-sz 0.5)))
        (local zoom 4)
        (if (< region-x 0) (set region-x 0)
            (> region-x (- my-tex-w region-sz)) (set region-x
                                                     (- my-tex-w region-sz)))
        (if (< region-y 0) (set region-y 0)
            (> region-y (- my-tex-h region-sz)) (set region-y
                                                     (- my-tex-h region-sz)))
        (Im-gui.Text ctx (: "Min: (%.2f, %.2f)" :format region-x region-y))
        (Im-gui.Text ctx (: "Max: (%.2f, %.2f)" :format (+ region-x region-sz)
                            (+ region-y region-sz)))
        (local (uv0-x uv0-y)
               (values (/ region-x my-tex-w) (/ region-y my-tex-h)))
        (local (uv1-x uv1-y)
               (values (/ (+ region-x region-sz) my-tex-w)
                       (/ (+ region-y region-sz) my-tex-h)))
        (Im-gui.Image ctx widgets.images.bitmap (* region-sz zoom)
                      (* region-sz zoom) uv0-x uv0-y uv1-x uv1-y tint-col
                      border-col)
        (Im-gui.EndTooltip ctx)))
    (Im-gui.TextWrapped ctx "And now some textured buttons...")
    (for [i 0 8]
      (when (> i 0)
        (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) (- i 1) (- i 1)))
      (local (size-w size-h) (values 32 32))
      (local (uv0-x uv0-y) (values 0 0))
      (local (uv1-x uv1-y) (values (/ 32 my-tex-w) (/ 32 my-tex-h)))
      (local bg-col 255)
      (local tint-col 4294967295)
      (when (Im-gui.ImageButton ctx i widgets.images.bitmap size-w size-h uv0-x
                                uv0-y uv1-x uv1-y bg-col tint-col)
        (set widgets.images.pressed_count (+ widgets.images.pressed_count 1)))
      (when (> i 0) (Im-gui.PopStyleVar ctx))
      (Im-gui.SameLine ctx))
    (Im-gui.NewLine ctx)
    (Im-gui.Text ctx (: "Pressed %d times." :format
                        widgets.images.pressed_count))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Combo)
    (when (not widgets.combos)
      (set widgets.combos
           {:current_item1 1
            :current_item2 0
            :current_item3 (- 1)
            :flags (Im-gui.ComboFlags_None)}))
    (set (rv widgets.combos.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiComboFlags_PopupAlignLeft
                               widgets.combos.flags
                               (Im-gui.ComboFlags_PopupAlignLeft)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Only makes a difference if the popup is larger than the combo")
    (set (rv widgets.combos.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiComboFlags_NoArrowButton
                               widgets.combos.flags
                               (Im-gui.ComboFlags_NoArrowButton)))
    (when rv
      (set widgets.combos.flags
           (band widgets.combos.flags (bnot (Im-gui.ComboFlags_NoPreview)))))
    (set (rv widgets.combos.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiComboFlags_NoPreview
                               widgets.combos.flags
                               (Im-gui.ComboFlags_NoPreview)))
    (when rv
      (set widgets.combos.flags
           (band widgets.combos.flags (bnot (Im-gui.ComboFlags_NoArrowButton)))))
    (var combo-items [:AAAA
                      :BBBB
                      :CCCC
                      :DDDD
                      :EEEE
                      :FFFF
                      :GGGG
                      :HHHH
                      :IIII
                      :JJJJ
                      :KKKK
                      :LLLLLLL
                      :MMMM
                      :OOOOOOO])
    (local combo-preview-value (. combo-items widgets.combos.current_item1))
    (when (Im-gui.BeginCombo ctx "combo 1" combo-preview-value
                             widgets.combos.flags)
      (each [i v (ipairs combo-items)]
        (local is-selected (= widgets.combos.current_item1 i))
        (when (Im-gui.Selectable ctx (. combo-items i) is-selected)
          (set widgets.combos.current_item1 i))
        (when is-selected (Im-gui.SetItemDefaultFocus ctx)))
      (Im-gui.EndCombo ctx))
    (set combo-items "aaaa\000bbbb\000cccc\000dddd\000eeee\000")
    (set (rv widgets.combos.current_item2)
         (Im-gui.Combo ctx "combo 2 (one-liner)" widgets.combos.current_item2
                       combo-items))
    (set (rv widgets.combos.current_item3)
         (Im-gui.Combo ctx "combo 3 (out of range)"
                       widgets.combos.current_item3 combo-items))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "List boxes")
    (when (not widgets.lists) (set widgets.lists {:current_idx 1}))
    (local items [:AAAA
                  :BBBB
                  :CCCC
                  :DDDD
                  :EEEE
                  :FFFF
                  :GGGG
                  :HHHH
                  :IIII
                  :JJJJ
                  :KKKK
                  :LLLLLLL
                  :MMMM
                  :OOOOOOO])
    (when (Im-gui.BeginListBox ctx "listbox 1")
      (each [n v (ipairs items)]
        (local is-selected (= widgets.lists.current_idx n))
        (when (Im-gui.Selectable ctx v is-selected)
          (set widgets.lists.current_idx n))
        (when is-selected (Im-gui.SetItemDefaultFocus ctx)))
      (Im-gui.EndListBox ctx))
    (Im-gui.Text ctx "Full-width:")
    (when (Im-gui.BeginListBox ctx "##listbox 2" (- FLT_MIN)
                               (* 5 (Im-gui.GetTextLineHeightWithSpacing ctx)))
      (each [n v (ipairs items)]
        (local is-selected (= widgets.lists.current_idx n))
        (when (Im-gui.Selectable ctx v is-selected)
          (set widgets.lists.current_idx n))
        (when is-selected (Im-gui.SetItemDefaultFocus ctx)))
      (Im-gui.EndListBox ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Selectables)
    (when (not widgets.selectables)
      (set widgets.selectables {:align [[true false true]
                                        [false true false]
                                        [true false true]]
                                :basic [false false false false false]
                                :columns [false
                                          false
                                          false
                                          false
                                          false
                                          false
                                          false
                                          false
                                          false
                                          false]
                                :grid [[true false false false]
                                       [false true false false]
                                       [false false true false]
                                       [false false false true]]
                                :multiple [false false false false false]
                                :sameline [false false false]
                                :single (- 1)}))
    (when (Im-gui.TreeNode ctx :Basic)
      (set-forcibly! (rv b1)
                     (Im-gui.Selectable ctx "1. I am selectable"
                                        (. widgets.selectables.basic 1)))
      (tset widgets.selectables.basic 1 b1)
      (set-forcibly! (rv b2)
                     (Im-gui.Selectable ctx "2. I am selectable"
                                        (. widgets.selectables.basic 2)))
      (tset widgets.selectables.basic 2 b2)
      (Im-gui.Text ctx "(I am not selectable)")
      (set-forcibly! (rv b4)
                     (Im-gui.Selectable ctx "4. I am selectable"
                                        (. widgets.selectables.basic 4)))
      (tset widgets.selectables.basic 4 b4)
      (when (Im-gui.Selectable ctx "5. I am double clickable"
                               (. widgets.selectables.basic 5)
                               (Im-gui.SelectableFlags_AllowDoubleClick))
        (when (Im-gui.IsMouseDoubleClicked ctx 0)
          (tset widgets.selectables.basic 5
                (not (. widgets.selectables.basic 5)))))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Selection State: Single Selection")
      (for [i 0 4]
        (when (Im-gui.Selectable ctx (: "Object %d" :format i)
                                 (= widgets.selectables.single i))
          (set widgets.selectables.single i)))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Selection State: Multiple Selection")
      (demo.HelpMarker "Hold CTRL and click to select multiple items.")
      (each [i sel (ipairs widgets.selectables.multiple)]
        (when (Im-gui.Selectable ctx (: "Object %d" :format (- i 1)) sel)
          (when (not (Im-gui.IsKeyDown ctx (Im-gui.Mod_Ctrl)))
            (for [j 1 (length widgets.selectables.multiple)]
              (tset widgets.selectables.multiple j false)))
          (tset widgets.selectables.multiple i (not sel))))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Rendering more text into the same line")
      (set-forcibly! (rv s1)
                     (Im-gui.Selectable ctx :main.c
                                        (. widgets.selectables.sameline 1)))
      (tset widgets.selectables.sameline 1 s1)
      (Im-gui.SameLine ctx 300)
      (Im-gui.Text ctx " 2,345 bytes")
      (set-forcibly! (rv s2)
                     (Im-gui.Selectable ctx :Hello.cpp
                                        (. widgets.selectables.sameline 2)))
      (tset widgets.selectables.sameline 2 s2)
      (Im-gui.SameLine ctx 300)
      (Im-gui.Text ctx "12,345 bytes")
      (set-forcibly! (rv s3)
                     (Im-gui.Selectable ctx :Hello.h
                                        (. widgets.selectables.sameline 3)))
      (tset widgets.selectables.sameline 3 s3)
      (Im-gui.SameLine ctx 300)
      (Im-gui.Text ctx " 2,345 bytes")
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "In columns")
      (when (Im-gui.BeginTable ctx :split1 3
                               (bor (Im-gui.TableFlags_Resizable)
                                    (Im-gui.TableFlags_NoSavedSettings)
                                    (Im-gui.TableFlags_Borders)))
        (each [i sel (ipairs widgets.selectables.columns)]
          (Im-gui.TableNextColumn ctx)
          (set-forcibly! (rv ci)
                         (Im-gui.Selectable ctx (: "Item %d" :format (- i 1))
                                            sel))
          (tset widgets.selectables.columns i ci))
        (Im-gui.EndTable ctx))
      (Im-gui.Spacing ctx)
      (when (Im-gui.BeginTable ctx :split2 3
                               (bor (Im-gui.TableFlags_Resizable)
                                    (Im-gui.TableFlags_NoSavedSettings)
                                    (Im-gui.TableFlags_Borders)))
        (each [i sel (ipairs widgets.selectables.columns)]
          (Im-gui.TableNextRow ctx)
          (Im-gui.TableNextColumn ctx)
          (set-forcibly! (rv ci)
                         (Im-gui.Selectable ctx (: "Item %d" :format (- i 1))
                                            sel
                                            (Im-gui.SelectableFlags_SpanAllColumns)))
          (tset widgets.selectables.columns i ci)
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx "Some other contents")
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx :123456))
        (Im-gui.EndTable ctx))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx :Grid)
      (var winning-state true)
      (each [ri row (ipairs widgets.selectables.grid)]
        (each [ci sel (ipairs row)]
          (when (not sel) (set winning-state false) (lua :break))))
      (when winning-state
        (local time (Im-gui.GetTime ctx))
        (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_SelectableTextAlign)
                             (+ 0.5 (* 0.5 (math.cos (* time 2))))
                             (+ 0.5 (* 0.5 (math.sin (* time 3))))))
      (each [ri row (ipairs widgets.selectables.grid)]
        (each [ci col (ipairs row)]
          (when (> ci 1) (Im-gui.SameLine ctx))
          (Im-gui.PushID ctx (+ (* ri (length widgets.selectables.grid)) ci))
          (when (Im-gui.Selectable ctx :Sailor col 0 50 50)
            (tset row ci (not (. row ci)))
            (when (> ci 1)
              (tset row (- ci 1) (not (. row (- ci 1)))))
            (when (< ci 4)
              (tset row (+ ci 1) (not (. row (+ ci 1)))))
            (when (> ri 1)
              (tset (. widgets.selectables.grid (- ri 1)) ci
                    (not (. (. widgets.selectables.grid (- ri 1)) ci))))
            (when (< ri 4)
              (tset (. widgets.selectables.grid (+ ri 1)) ci
                    (not (. (. widgets.selectables.grid (+ ri 1)) ci)))))
          (Im-gui.PopID ctx)))
      (when winning-state (Im-gui.PopStyleVar ctx))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx :Alignment)
      (demo.HelpMarker "By default, Selectables uses style.SelectableTextAlign but it can be overridden on a per-item basis using PushStyleVar(). You'll probably want to always keep your default situation to left-align otherwise it becomes difficult to layout multiple items on a same line")
      (for [y 1 3]
        (for [x 1 3]
          (local (align-x align-y) (values (/ (- x 1) 2) (/ (- y 1) 2)))
          (local name (: "(%.1f,%.1f)" :format align-x align-y))
          (when (> x 1) (Im-gui.SameLine ctx))
          (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_SelectableTextAlign)
                               align-x align-y)
          (local row (. widgets.selectables.align y))
          (set-forcibly! (rv rx)
                         (Im-gui.Selectable ctx name (. row x)
                                            (Im-gui.SelectableFlags_None) 80 80))
          (tset row x rx)
          (Im-gui.PopStyleVar ctx)))
      (Im-gui.TreePop ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Text Input")
    (when (not widgets.input)
      (set widgets.input {:buf ["" "" "" "" ""]
                          :flags (Im-gui.InputTextFlags_AllowTabInput)
                          :multiline {:text "/*
 The Pentium F00F bug, shorthand for F0 0F C7 C8,
 the hexadecimal encoding of one offending instruction,
 more formally, the invalid operand with locked CMPXCHG8B
 instruction bug, is a design flaw in the majority of
 Intel Pentium, Pentium MMX, and Pentium OverDrive
 processors (all in the P5 microarchitecture).
*/

label:
\tlock cmpxchg8b eax
"}
                          :password :hunter2}))
    (when (Im-gui.TreeNode ctx "Multi-line Text Input")
      (set (rv widgets.input.multiline.flags)
           (Im-gui.CheckboxFlags ctx :ImGuiInputTextFlags_ReadOnly
                                 widgets.input.multiline.flags
                                 (Im-gui.InputTextFlags_ReadOnly)))
      (set (rv widgets.input.multiline.flags)
           (Im-gui.CheckboxFlags ctx :ImGuiInputTextFlags_AllowTabInput
                                 widgets.input.multiline.flags
                                 (Im-gui.InputTextFlags_AllowTabInput)))
      (set (rv widgets.input.multiline.flags)
           (Im-gui.CheckboxFlags ctx :ImGuiInputTextFlags_CtrlEnterForNewLine
                                 widgets.input.multiline.flags
                                 (Im-gui.InputTextFlags_CtrlEnterForNewLine)))
      (set (rv widgets.input.multiline.text)
           (Im-gui.InputTextMultiline ctx "##source"
                                      widgets.input.multiline.text (- FLT_MIN)
                                      (* (Im-gui.GetTextLineHeight ctx) 16)
                                      widgets.input.multiline.flags))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Filtered Text Input")
      (set-forcibly! (rv b1)
                     (Im-gui.InputText ctx :default (. widgets.input.buf 1)))
      (tset widgets.input.buf 1 b1)
      (set-forcibly! (rv b2)
                     (Im-gui.InputText ctx :decimal (. widgets.input.buf 2)
                                       (Im-gui.InputTextFlags_CharsDecimal)))
      (tset widgets.input.buf 2 b2)
      (set-forcibly! (rv b3)
                     (Im-gui.InputText ctx :hexadecimal (. widgets.input.buf 3)
                                       (bor (Im-gui.InputTextFlags_CharsHexadecimal)
                                            (Im-gui.InputTextFlags_CharsUppercase))))
      (tset widgets.input.buf 3 b3)
      (set-forcibly! (rv b4)
                     (Im-gui.InputText ctx :uppercase (. widgets.input.buf 4)
                                       (Im-gui.InputTextFlags_CharsUppercase)))
      (tset widgets.input.buf 4 b4)
      (set-forcibly! (rv b5)
                     (Im-gui.InputText ctx "no blank" (. widgets.input.buf 5)
                                       (Im-gui.InputTextFlags_CharsNoBlank)))
      (tset widgets.input.buf 5 b5)
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Password Input")
      (set (rv widgets.input.password)
           (Im-gui.InputText ctx :password widgets.input.password
                             (Im-gui.InputTextFlags_Password)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Display all characters as '*'.
Disable clipboard cut and copy.
Disable logging.
")
      (set (rv widgets.input.password)
           (Im-gui.InputTextWithHint ctx "password (w/ hint)" :<password>
                                     widgets.input.password
                                     (Im-gui.InputTextFlags_Password)))
      (set (rv widgets.input.password)
           (Im-gui.InputText ctx "password (clear)" widgets.input.password))
      (Im-gui.TreePop ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Tabs)
    (when (not widgets.tabs)
      (set widgets.tabs {:active [1 2 3]
                         :flags1 (Im-gui.TabBarFlags_Reorderable)
                         :flags2 (bor (Im-gui.TabBarFlags_AutoSelectNewTabs)
                                      (Im-gui.TabBarFlags_Reorderable)
                                      (Im-gui.TabBarFlags_FittingPolicyResizeDown))
                         :next_id 4
                         :opened [true true true true]
                         :show_leading_button true
                         :show_trailing_button true}))
    (local fitting-policy-mask
           (bor (Im-gui.TabBarFlags_FittingPolicyResizeDown)
                (Im-gui.TabBarFlags_FittingPolicyScroll)))
    (when (Im-gui.TreeNode ctx :Basic)
      (when (Im-gui.BeginTabBar ctx :MyTabBar (Im-gui.TabBarFlags_None))
        (when (Im-gui.BeginTabItem ctx :Avocado)
          (Im-gui.Text ctx "This is the Avocado tab!\nblah blah blah blah blah")
          (Im-gui.EndTabItem ctx))
        (when (Im-gui.BeginTabItem ctx :Broccoli)
          (Im-gui.Text ctx
                       "This is the Broccoli tab!\nblah blah blah blah blah")
          (Im-gui.EndTabItem ctx))
        (when (Im-gui.BeginTabItem ctx :Cucumber)
          (Im-gui.Text ctx
                       "This is the Cucumber tab!\nblah blah blah blah blah")
          (Im-gui.EndTabItem ctx))
        (Im-gui.EndTabBar ctx))
      (Im-gui.Separator ctx)
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Advanced & Close Button")
      (set (rv widgets.tabs.flags1)
           (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_Reorderable
                                 widgets.tabs.flags1
                                 (Im-gui.TabBarFlags_Reorderable)))
      (set (rv widgets.tabs.flags1)
           (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_AutoSelectNewTabs
                                 widgets.tabs.flags1
                                 (Im-gui.TabBarFlags_AutoSelectNewTabs)))
      (set (rv widgets.tabs.flags1)
           (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_TabListPopupButton
                                 widgets.tabs.flags1
                                 (Im-gui.TabBarFlags_TabListPopupButton)))
      (set (rv widgets.tabs.flags1)
           (Im-gui.CheckboxFlags ctx
                                 :ImGuiTabBarFlags_NoCloseWithMiddleMouseButton
                                 widgets.tabs.flags1
                                 (Im-gui.TabBarFlags_NoCloseWithMiddleMouseButton)))
      (when (= (band widgets.tabs.flags1 fitting-policy-mask) 0)
        (set widgets.tabs.flags1
             (bor widgets.tabs.flags1
                  (Im-gui.TabBarFlags_FittingPolicyResizeDown))))
      (when (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyResizeDown
                                  widgets.tabs.flags1
                                  (Im-gui.TabBarFlags_FittingPolicyResizeDown))
        (set widgets.tabs.flags1
             (bor (band widgets.tabs.flags1 (bnot fitting-policy-mask))
                  (Im-gui.TabBarFlags_FittingPolicyResizeDown))))
      (when (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyScroll
                                  widgets.tabs.flags1
                                  (Im-gui.TabBarFlags_FittingPolicyScroll))
        (set widgets.tabs.flags1
             (bor (band widgets.tabs.flags1 (bnot fitting-policy-mask))
                  (Im-gui.TabBarFlags_FittingPolicyScroll))))
      (local names [:Artichoke :Beetroot :Celery :Daikon])
      (each [n opened (ipairs widgets.tabs.opened)]
        (when (> n 1) (Im-gui.SameLine ctx))
        (set-forcibly! (rv on) (Im-gui.Checkbox ctx (. names n) opened))
        (tset widgets.tabs.opened n on))
      (when (Im-gui.BeginTabBar ctx :MyTabBar widgets.tabs.flags1)
        (each [n opened (ipairs widgets.tabs.opened)]
          (when opened
            (set-forcibly! (rv on)
                           (Im-gui.BeginTabItem ctx (. names n) true
                                                (Im-gui.TabItemFlags_None)))
            (tset widgets.tabs.opened n on)
            (when rv
              (Im-gui.Text ctx (: "This is the %s tab!" :format (. names n)))
              (when (= (band n 1) 0) (Im-gui.Text ctx "I am an odd tab."))
              (Im-gui.EndTabItem ctx))))
        (Im-gui.EndTabBar ctx))
      (Im-gui.Separator ctx)
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "TabItemButton & Leading/Trailing flags")
      (set (rv widgets.tabs.show_leading_button)
           (Im-gui.Checkbox ctx "Show Leading TabItemButton()"
                            widgets.tabs.show_leading_button))
      (set (rv widgets.tabs.show_trailing_button)
           (Im-gui.Checkbox ctx "Show Trailing TabItemButton()"
                            widgets.tabs.show_trailing_button))
      (set (rv widgets.tabs.flags2)
           (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_TabListPopupButton
                                 widgets.tabs.flags2
                                 (Im-gui.TabBarFlags_TabListPopupButton)))
      (when (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyResizeDown
                                  widgets.tabs.flags2
                                  (Im-gui.TabBarFlags_FittingPolicyResizeDown))
        (set widgets.tabs.flags2
             (bor (band widgets.tabs.flags2 (bnot fitting-policy-mask))
                  (Im-gui.TabBarFlags_FittingPolicyResizeDown))))
      (when (Im-gui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyScroll
                                  widgets.tabs.flags2
                                  (Im-gui.TabBarFlags_FittingPolicyScroll))
        (set widgets.tabs.flags2
             (bor (band widgets.tabs.flags2 (bnot fitting-policy-mask))
                  (Im-gui.TabBarFlags_FittingPolicyScroll))))
      (when (Im-gui.BeginTabBar ctx :MyTabBar widgets.tabs.flags2)
        (when widgets.tabs.show_leading_button
          (when (Im-gui.TabItemButton ctx "?"
                                      (bor (Im-gui.TabItemFlags_Leading)
                                           (Im-gui.TabItemFlags_NoTooltip)))
            (Im-gui.OpenPopup ctx :MyHelpMenu)))
        (when (Im-gui.BeginPopup ctx :MyHelpMenu)
          (Im-gui.Selectable ctx :Hello!)
          (Im-gui.EndPopup ctx))
        (when widgets.tabs.show_trailing_button
          (when (Im-gui.TabItemButton ctx "+"
                                      (bor (Im-gui.TabItemFlags_Trailing)
                                           (Im-gui.TabItemFlags_NoTooltip)))
            (table.insert widgets.tabs.active widgets.tabs.next_id)
            (set widgets.tabs.next_id (+ widgets.tabs.next_id 1))))
        (var n 1)
        (while (<= n (length widgets.tabs.active))
          (local name (: "%04d" :format (- (. widgets.tabs.active n) 1)))
          (var open nil)
          (set (rv open)
               (Im-gui.BeginTabItem ctx name true (Im-gui.TabItemFlags_None)))
          (when rv (Im-gui.Text ctx (: "This is the %s tab!" :format name))
            (Im-gui.EndTabItem ctx))
          (if open (set n (+ n 1)) (table.remove widgets.tabs.active n)))
        (Im-gui.EndTabBar ctx))
      (Im-gui.Separator ctx)
      (Im-gui.TreePop ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Plotting)
    (local PLOT1-SIZE 90)
    (local plot2-funcs
           [(fn [i] (math.sin (* i 0.1)))
            (fn [i]
              (or (and (= (band i 1) 1) 1) (- 1)))])
    (when (not widgets.plots)
      (set widgets.plots {:animate true
                          :frame_times (reaper.new_array [0.6
                                                          0.1
                                                          1
                                                          0.5
                                                          0.92
                                                          0.1
                                                          0.2])
                          :plot1 {:data (reaper.new_array PLOT1-SIZE)
                                  :offset 1
                                  :phase 0
                                  :refresh_time 0}
                          :plot2 {:data (reaper.new_array 1)
                                  :fill true
                                  :func 0
                                  :size 70}
                          :progress 0
                          :progress_dir 1})
      (widgets.plots.plot1.data.clear))
    (set (rv widgets.plots.animate)
         (Im-gui.Checkbox ctx :Animate widgets.plots.animate))
    (Im-gui.PlotLines ctx "Frame Times" widgets.plots.frame_times)
    (Im-gui.PlotHistogram ctx :Histogram widgets.plots.frame_times 0 nil 0 1 0
                          80)
    (when (or (not widgets.plots.animate)
              (= widgets.plots.plot1.refresh_time 0))
      (set widgets.plots.plot1.refresh_time (Im-gui.GetTime ctx)))
    (while (< widgets.plots.plot1.refresh_time (Im-gui.GetTime ctx))
      (tset widgets.plots.plot1.data widgets.plots.plot1.offset
            (math.cos widgets.plots.plot1.phase))
      (set widgets.plots.plot1.offset
           (+ (% widgets.plots.plot1.offset PLOT1-SIZE) 1))
      (set widgets.plots.plot1.phase
           (+ widgets.plots.plot1.phase (* 0.1 widgets.plots.plot1.offset)))
      (set widgets.plots.plot1.refresh_time
           (+ widgets.plots.plot1.refresh_time (/ 1 60))))
    (do
      (var average 0)
      (for [n 1 PLOT1-SIZE]
        (set average (+ average (. widgets.plots.plot1.data n))))
      (set average (/ average PLOT1-SIZE))
      (local overlay (: "avg %f" :format average))
      (Im-gui.PlotLines ctx :Lines widgets.plots.plot1.data
                        (- widgets.plots.plot1.offset 1) overlay (- 1) 1 0 80))
    (Im-gui.SeparatorText ctx :Functions)
    (Im-gui.SetNextItemWidth ctx (* (Im-gui.GetFontSize ctx) 8))
    (set (rv widgets.plots.plot2.func)
         (Im-gui.Combo ctx :func widgets.plots.plot2.func "Sin\000Saw\000"))
    (local func-changed rv)
    (Im-gui.SameLine ctx)
    (set (rv widgets.plots.plot2.size)
         (Im-gui.SliderInt ctx "Sample count" widgets.plots.plot2.size 1 400))
    (when (or (or func-changed rv) widgets.plots.plot2.fill)
      (set widgets.plots.plot2.fill false)
      (set widgets.plots.plot2.data (reaper.new_array widgets.plots.plot2.size))
      (for [n 1 widgets.plots.plot2.size]
        (tset widgets.plots.plot2.data n
              ((. plot2-funcs (+ widgets.plots.plot2.func 1)) (- n 1)))))
    (Im-gui.PlotLines ctx :Lines widgets.plots.plot2.data 0 nil (- 1) 1 0 80)
    (Im-gui.PlotHistogram ctx :Histogram widgets.plots.plot2.data 0 nil (- 1) 1
                          0 80)
    (Im-gui.Separator ctx)
    (when widgets.plots.animate
      (set widgets.plots.progress
           (+ widgets.plots.progress
              (* widgets.plots.progress_dir 0.4 (Im-gui.GetDeltaTime ctx))))
      (if (>= widgets.plots.progress 1.1)
          (do
            (set widgets.plots.progress 1.1)
            (set widgets.plots.progress_dir
                 (* widgets.plots.progress_dir (- 1))))
          (<= widgets.plots.progress (- 0.1))
          (do
            (set widgets.plots.progress (- 0.1))
            (set widgets.plots.progress_dir
                 (* widgets.plots.progress_dir (- 1))))))
    (Im-gui.ProgressBar ctx widgets.plots.progress 0 0)
    (Im-gui.SameLine ctx 0
                     (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemInnerSpacing)))
    (Im-gui.Text ctx "Progress Bar")
    (local progress-saturated (demo.clamp widgets.plots.progress 0 1))
    (local buf
           (: "%d/%d" :format (math.floor (* progress-saturated 1753)) 1753))
    (Im-gui.ProgressBar ctx widgets.plots.progress 0 0 buf)
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Color/Picker Widgets")
    (when (not widgets.colors)
      (set widgets.colors {:alpha true
                           :alpha_bar true
                           :alpha_half_preview false
                           :alpha_preview true
                           :backup_color nil
                           :display_mode 0
                           :drag_and_drop true
                           :hsva 1006632959
                           :no_border false
                           :options_menu true
                           :picker_mode 0
                           :raw_hsv (reaper.new_array 4)
                           :ref_color false
                           :ref_color_rgba 4278255488
                           :rgba 1922079432
                           :saved_palette nil
                           :side_preview true}))
    (Im-gui.SeparatorText ctx :Options)
    (set (rv widgets.colors.alpha_preview)
         (Im-gui.Checkbox ctx "With Alpha Preview" widgets.colors.alpha_preview))
    (set (rv widgets.colors.alpha_half_preview)
         (Im-gui.Checkbox ctx "With Half Alpha Preview"
                          widgets.colors.alpha_half_preview))
    (set (rv widgets.colors.drag_and_drop)
         (Im-gui.Checkbox ctx "With Drag and Drop" widgets.colors.drag_and_drop))
    (set (rv widgets.colors.options_menu)
         (Im-gui.Checkbox ctx "With Options Menu" widgets.colors.options_menu))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Right-click on the individual color widget to show options.")
    (local misc-flags
           (bor (or (and widgets.colors.drag_and_drop 0)
                    (Im-gui.ColorEditFlags_NoDragDrop))
                (or (and widgets.colors.alpha_half_preview
                         (Im-gui.ColorEditFlags_AlphaPreviewHalf))
                    (or (and widgets.colors.alpha_preview
                             (Im-gui.ColorEditFlags_AlphaPreview))
                        0))
                (or (and widgets.colors.options_menu 0)
                    (Im-gui.ColorEditFlags_NoOptions))))
    (Im-gui.SeparatorText ctx "Inline color editor")
    (Im-gui.Text ctx "Color widget:")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Click on the color square to open a color picker.
CTRL+click on individual component to input value.
")
    (var argb (demo.RgbaToArgb widgets.colors.rgba))
    (set (rv argb) (Im-gui.ColorEdit3 ctx "MyColor##1" argb misc-flags))
    (when rv (set widgets.colors.rgba (demo.ArgbToRgba argb)))
    (Im-gui.Text ctx "Color widget HSV with Alpha:")
    (set (rv widgets.colors.rgba)
         (Im-gui.ColorEdit4 ctx "MyColor##2" widgets.colors.rgba
                            (bor (Im-gui.ColorEditFlags_DisplayHSV) misc-flags)))
    (Im-gui.Text ctx "Color widget with Float Display:")
    (set (rv widgets.colors.rgba)
         (Im-gui.ColorEdit4 ctx "MyColor##2f" widgets.colors.rgba
                            (bor (Im-gui.ColorEditFlags_Float) misc-flags)))
    (Im-gui.Text ctx "Color button with Picker:")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "With the ImGuiColorEditFlags_NoInputs flag you can hide all the slider/text inputs.
With the ImGuiColorEditFlags_NoLabel flag you can pass a non-empty label which will only be used for the tooltip and picker popup.")
    (set (rv widgets.colors.rgba)
         (Im-gui.ColorEdit4 ctx "MyColor##3" widgets.colors.rgba
                            (bor (Im-gui.ColorEditFlags_NoInputs)
                                 (Im-gui.ColorEditFlags_NoLabel) misc-flags)))
    (Im-gui.Text ctx "Color button with Custom Picker Popup:")
    (when (not widgets.colors.saved_palette)
      (set widgets.colors.saved_palette {})
      (for [n 0 31]
        (table.insert widgets.colors.saved_palette (demo.HSV (/ n 31) 0.8 0.8))))
    (var open-popup (Im-gui.ColorButton ctx "MyColor##3b" widgets.colors.rgba
                                        misc-flags))
    (Im-gui.SameLine ctx 0
                     (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemInnerSpacing)))
    (set open-popup (or (Im-gui.Button ctx :Palette) open-popup))
    (when open-popup (Im-gui.OpenPopup ctx :mypicker)
      (set widgets.colors.backup_color widgets.colors.rgba))
    (when (Im-gui.BeginPopup ctx :mypicker)
      (Im-gui.Text ctx "MY CUSTOM COLOR PICKER WITH AN AMAZING PALETTE!")
      (Im-gui.Separator ctx)
      (set (rv widgets.colors.rgba)
           (Im-gui.ColorPicker4 ctx "##picker" widgets.colors.rgba
                                (bor misc-flags
                                     (Im-gui.ColorEditFlags_NoSidePreview)
                                     (Im-gui.ColorEditFlags_NoSmallPreview))))
      (Im-gui.SameLine ctx)
      (Im-gui.BeginGroup ctx)
      (Im-gui.Text ctx :Current)
      (Im-gui.ColorButton ctx "##current" widgets.colors.rgba
                          (bor (Im-gui.ColorEditFlags_NoPicker)
                               (Im-gui.ColorEditFlags_AlphaPreviewHalf))
                          60 40)
      (Im-gui.Text ctx :Previous)
      (when (Im-gui.ColorButton ctx "##previous" widgets.colors.backup_color
                                (bor (Im-gui.ColorEditFlags_NoPicker)
                                     (Im-gui.ColorEditFlags_AlphaPreviewHalf))
                                60 40)
        (set widgets.colors.rgba widgets.colors.backup_color))
      (Im-gui.Separator ctx)
      (Im-gui.Text ctx :Palette)
      (local palette-button-flags
             (bor (Im-gui.ColorEditFlags_NoAlpha)
                  (Im-gui.ColorEditFlags_NoPicker)
                  (Im-gui.ColorEditFlags_NoTooltip)))
      (each [n c (ipairs widgets.colors.saved_palette)]
        (Im-gui.PushID ctx n)
        (when (not= (% (- n 1) 8) 0)
          (Im-gui.SameLine ctx 0
                           (select 2
                                   (Im-gui.GetStyleVar ctx
                                                       (Im-gui.StyleVar_ItemSpacing)))))
        (when (Im-gui.ColorButton ctx "##palette" c palette-button-flags 20 20)
          (set widgets.colors.rgba
               (bor (lshift c 8) (band widgets.colors.rgba 255))))
        (when (Im-gui.BeginDragDropTarget ctx)
          (var drop-color nil)
          (set (rv drop-color) (Im-gui.AcceptDragDropPayloadRGB ctx))
          (when rv (tset widgets.colors.saved_palette n drop-color))
          (set (rv drop-color) (Im-gui.AcceptDragDropPayloadRGBA ctx))
          (when rv (tset widgets.colors.saved_palette n (rshift drop-color 8)))
          (Im-gui.EndDragDropTarget ctx))
        (Im-gui.PopID ctx))
      (Im-gui.EndGroup ctx)
      (Im-gui.EndPopup ctx))
    (Im-gui.Text ctx "Color button only:")
    (set (rv widgets.colors.no_border)
         (Im-gui.Checkbox ctx :ImGuiColorEditFlags_NoBorder
                          widgets.colors.no_border))
    (Im-gui.ColorButton ctx "MyColor##3c" widgets.colors.rgba
                        (bor misc-flags
                             (or (and widgets.colors.no_border
                                      (Im-gui.ColorEditFlags_NoBorder))
                                 0)) 80 80)
    (Im-gui.SeparatorText ctx "Color picker")
    (set (rv widgets.colors.alpha)
         (Im-gui.Checkbox ctx "With Alpha" widgets.colors.alpha))
    (set (rv widgets.colors.alpha_bar)
         (Im-gui.Checkbox ctx "With Alpha Bar" widgets.colors.alpha_bar))
    (set (rv widgets.colors.side_preview)
         (Im-gui.Checkbox ctx "With Side Preview" widgets.colors.side_preview))
    (when widgets.colors.side_preview
      (Im-gui.SameLine ctx)
      (set (rv widgets.colors.ref_color)
           (Im-gui.Checkbox ctx "With Ref Color" widgets.colors.ref_color))
      (when widgets.colors.ref_color
        (Im-gui.SameLine ctx)
        (set (rv widgets.colors.ref_color_rgba)
             (Im-gui.ColorEdit4 ctx "##RefColor" widgets.colors.ref_color_rgba
                                (bor (Im-gui.ColorEditFlags_NoInputs)
                                     misc-flags)))))
    (set (rv widgets.colors.display_mode)
         (Im-gui.Combo ctx "Display Mode" widgets.colors.display_mode
                       "Auto/Current\000None\000RGB Only\000HSV Only\000Hex Only\000"))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "ColorEdit defaults to displaying RGB inputs if you don't specify a display mode, but the user can change it with a right-click on those inputs.

ColorPicker defaults to displaying RGB+HSV+Hex if you don't specify a display mode.

You can change the defaults using SetColorEditOptions().")
    (set (rv widgets.colors.picker_mode)
         (Im-gui.Combo ctx "Picker Mode" widgets.colors.picker_mode
                       "Auto/Current\000Hue bar + SV rect\000Hue wheel + SV triangle\000"))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "When not specified explicitly (Auto/Current mode), user can right-click the picker to change mode.")
    (var flags misc-flags)
    (when (not widgets.colors.alpha)
      (set flags (bor flags (Im-gui.ColorEditFlags_NoAlpha))))
    (when widgets.colors.alpha_bar
      (set flags (bor flags (Im-gui.ColorEditFlags_AlphaBar))))
    (when (not widgets.colors.side_preview)
      (set flags (bor flags (Im-gui.ColorEditFlags_NoSidePreview))))
    (when (= widgets.colors.picker_mode 1)
      (set flags (bor flags (Im-gui.ColorEditFlags_PickerHueBar))))
    (when (= widgets.colors.picker_mode 2)
      (set flags (bor flags (Im-gui.ColorEditFlags_PickerHueWheel))))
    (when (= widgets.colors.display_mode 1)
      (set flags (bor flags (Im-gui.ColorEditFlags_NoInputs))))
    (when (= widgets.colors.display_mode 2)
      (set flags (bor flags (Im-gui.ColorEditFlags_DisplayRGB))))
    (when (= widgets.colors.display_mode 3)
      (set flags (bor flags (Im-gui.ColorEditFlags_DisplayHSV))))
    (when (= widgets.colors.display_mode 4)
      (set flags (bor flags (Im-gui.ColorEditFlags_DisplayHex))))
    (var color (or (and widgets.colors.alpha widgets.colors.rgba)
                   (demo.RgbaToArgb widgets.colors.rgba)))
    (local ref-color
           (or (and widgets.colors.alpha widgets.colors.ref_color_rgba)
               (demo.RgbaToArgb widgets.colors.ref_color_rgba)))
    (set (rv color) (Im-gui.ColorPicker4 ctx "MyColor##4" color flags
                                         (or (and widgets.colors.ref_color
                                                  ref-color)
                                             nil)))
    (when rv
      (set widgets.colors.rgba
           (or (and widgets.colors.alpha color) (demo.ArgbToRgba color))))
    (Im-gui.Text ctx "Set defaults in code:")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "SetColorEditOptions() is designed to allow you to set boot-time default.
We don't have Push/Pop functions because you can force options on a per-widget basis if needed,and the user can change non-forced ones with the options menu.
We don't have a getter to avoidencouraging you to persistently save values that aren't forward-compatible.")
    (when (Im-gui.Button ctx "Default: Uint8 + HSV + Hue Bar")
      (Im-gui.SetColorEditOptions ctx
                                  (bor (Im-gui.ColorEditFlags_Uint8)
                                       (Im-gui.ColorEditFlags_DisplayHSV)
                                       (Im-gui.ColorEditFlags_PickerHueBar))))
    (when (Im-gui.Button ctx "Default: Float + Hue Wheel")
      (Im-gui.SetColorEditOptions ctx
                                  (bor (Im-gui.ColorEditFlags_Float)
                                       (Im-gui.ColorEditFlags_PickerHueWheel))))
    (var color (demo.RgbaToArgb widgets.colors.rgba))
    (Im-gui.Text ctx "Both types:")
    (local w (* (- (Im-gui.GetContentRegionAvail ctx)
                   (select 2
                           (Im-gui.GetStyleVar ctx
                                               (Im-gui.StyleVar_ItemSpacing))))
                0.4))
    (Im-gui.SetNextItemWidth ctx w)
    (set (rv color)
         (Im-gui.ColorPicker3 ctx "##MyColor##5" color
                              (bor (Im-gui.ColorEditFlags_PickerHueBar)
                                   (Im-gui.ColorEditFlags_NoSidePreview)
                                   (Im-gui.ColorEditFlags_NoInputs)
                                   (Im-gui.ColorEditFlags_NoAlpha))))
    (when rv (set widgets.colors.rgba (demo.ArgbToRgba color)))
    (Im-gui.SameLine ctx)
    (Im-gui.SetNextItemWidth ctx w)
    (set (rv color)
         (Im-gui.ColorPicker3 ctx "##MyColor##6" color
                              (bor (Im-gui.ColorEditFlags_PickerHueWheel)
                                   (Im-gui.ColorEditFlags_NoSidePreview)
                                   (Im-gui.ColorEditFlags_NoInputs)
                                   (Im-gui.ColorEditFlags_NoAlpha))))
    (when rv (set widgets.colors.rgba (demo.ArgbToRgba color)))
    (Im-gui.Spacing ctx)
    (Im-gui.Text ctx "HSV encoded colors")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "By default, colors are given to ColorEdit and ColorPicker in RGB, but ImGuiColorEditFlags_InputHSV allows you to store colors as HSV and pass them to ColorEdit and ColorPicker as HSV. This comes with the added benefit that you can manipulate hue values with the picker even when saturation or value are zero.")
    (Im-gui.Text ctx "Color widget with InputHSV:")
    (set (rv widgets.colors.hsva)
         (Im-gui.ColorEdit4 ctx "HSV shown as RGB##1" widgets.colors.hsva
                            (bor (Im-gui.ColorEditFlags_DisplayRGB)
                                 (Im-gui.ColorEditFlags_InputHSV)
                                 (Im-gui.ColorEditFlags_Float))))
    (set (rv widgets.colors.hsva)
         (Im-gui.ColorEdit4 ctx "HSV shown as HSV##1" widgets.colors.hsva
                            (bor (Im-gui.ColorEditFlags_DisplayHSV)
                                 (Im-gui.ColorEditFlags_InputHSV)
                                 (Im-gui.ColorEditFlags_Float))))
    (local raw-hsv widgets.colors.raw_hsv)
    (tset raw-hsv 1 (/ (band (rshift widgets.colors.hsva 24) 255) 255))
    (tset raw-hsv 2 (/ (band (rshift widgets.colors.hsva 16) 255) 255))
    (tset raw-hsv 3 (/ (band (rshift widgets.colors.hsva 8) 255) 255))
    (tset raw-hsv 4 (/ (band widgets.colors.hsva 255) 255))
    (when (Im-gui.DragDoubleN ctx "Raw HSV values" raw-hsv 0.01 0 1)
      (set widgets.colors.hsva
           (bor (lshift (demo.round (* (. raw-hsv 1) 255)) 24)
                (lshift (demo.round (* (. raw-hsv 2) 255)) 16)
                (lshift (demo.round (* (. raw-hsv 3) 255)) 8)
                (demo.round (* (. raw-hsv 4) 255)))))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Drag/Slider Flags")
    (when (not widgets.sliders)
      (set widgets.sliders {:drag_d 0.5
                            :drag_i 50
                            :flags (Im-gui.SliderFlags_None)
                            :slider_d 0.5
                            :slider_i 50}))
    (set (rv widgets.sliders.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiSliderFlags_AlwaysClamp
                               widgets.sliders.flags
                               (Im-gui.SliderFlags_AlwaysClamp)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Always clamp value to min/max bounds (if any) when input manually with CTRL+Click.")
    (set (rv widgets.sliders.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiSliderFlags_Logarithmic
                               widgets.sliders.flags
                               (Im-gui.SliderFlags_Logarithmic)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Enable logarithmic editing (more precision for small values).")
    (set (rv widgets.sliders.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiSliderFlags_NoRoundToFormat
                               widgets.sliders.flags
                               (Im-gui.SliderFlags_NoRoundToFormat)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Disable rounding underlying value to match precision of the format string (e.g. %.3f values are rounded to those 3 digits).")
    (set (rv widgets.sliders.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiSliderFlags_NoInput
                               widgets.sliders.flags
                               (Im-gui.SliderFlags_NoInput)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Disable CTRL+Click or Enter key allowing to input text directly into the widget.")
    (local (DBL_MIN DBL_MAX) (values 2.22507e-308 1.79769e+308))
    (Im-gui.Text ctx (: "Underlying double value: %f" :format
                        widgets.sliders.drag_d))
    (set (rv widgets.sliders.drag_d)
         (Im-gui.DragDouble ctx "DragDouble (0 -> 1)" widgets.sliders.drag_d
                            0.005 0 1 "%.3f" widgets.sliders.flags))
    (set (rv widgets.sliders.drag_d)
         (Im-gui.DragDouble ctx "DragDouble (0 -> +inf)" widgets.sliders.drag_d
                            0.005 0 DBL_MAX "%.3f" widgets.sliders.flags))
    (set (rv widgets.sliders.drag_d)
         (Im-gui.DragDouble ctx "DragDouble (-inf -> 1)" widgets.sliders.drag_d
                            0.005 (- DBL_MAX) 1 "%.3f" widgets.sliders.flags))
    (set (rv widgets.sliders.drag_d)
         (Im-gui.DragDouble ctx "DragDouble (-inf -> +inf)"
                            widgets.sliders.drag_d 0.005 (- DBL_MAX) DBL_MAX
                            "%.3f" widgets.sliders.flags))
    (set (rv widgets.sliders.drag_i)
         (Im-gui.DragInt ctx "DragInt (0 -> 100)" widgets.sliders.drag_i 0.5 0
                         100 "%d" widgets.sliders.flags))
    (Im-gui.Text ctx (: "Underlying float value: %f" :format
                        widgets.sliders.slider_d))
    (set (rv widgets.sliders.slider_d)
         (Im-gui.SliderDouble ctx "SliderDouble (0 -> 1)"
                              widgets.sliders.slider_d 0 1 "%.3f"
                              widgets.sliders.flags))
    (set (rv widgets.sliders.slider_i)
         (Im-gui.SliderInt ctx "SliderInt (0 -> 100)" widgets.sliders.slider_i
                           0 100 "%d" widgets.sliders.flags))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Range Widgets")
    (when (not widgets.range)
      (set widgets.range {:begin_f 10 :begin_i 100 :end_f 90 :end_i 1000}))
    (set (rv widgets.range.begin_f widgets.range.end_f)
         (Im-gui.DragFloatRange2 ctx "range float" widgets.range.begin_f
                                 widgets.range.end_f 0.25 0 100 "Min: %.1f %%"
                                 "Max: %.1f %%" (Im-gui.SliderFlags_AlwaysClamp)))
    (set (rv widgets.range.begin_i widgets.range.end_i)
         (Im-gui.DragIntRange2 ctx "range int" widgets.range.begin_i
                               widgets.range.end_i 5 0 1000 "Min: %d units"
                               "Max: %d units"))
    (set (rv widgets.range.begin_i widgets.range.end_i)
         (Im-gui.DragIntRange2 ctx "range int (no bounds)"
                               widgets.range.begin_i widgets.range.end_i 5 0 0
                               "Min: %d units" "Max: %d units"))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Multi-component Widgets")
    (when (not widgets.multi_component)
      (set widgets.multi_component
           {:vec4a (reaper.new_array [0.1 0.2 0.3 0.44])
            :vec4d [0.1 0.2 0.3 0.44]
            :vec4i [1 5 100 255]}))
    (local vec4d widgets.multi_component.vec4d)
    (local vec4i widgets.multi_component.vec4i)
    (Im-gui.SeparatorText ctx :2-wide)
    (set-forcibly! (rv vec4d1 vec4d2)
                   (Im-gui.InputDouble2 ctx "input double2" (. vec4d 1)
                                        (. vec4d 2)))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (set-forcibly! (rv vec4d1 vec4d2)
                   (Im-gui.DragDouble2 ctx "drag double2" (. vec4d 1)
                                       (. vec4d 2) 0.01 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (set-forcibly! (rv vec4d1 vec4d2)
                   (Im-gui.SliderDouble2 ctx "slider double2" (. vec4d 1)
                                         (. vec4d 2) 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (set-forcibly! (rv vec4i1 vec4i2)
                   (Im-gui.InputInt2 ctx "input int2" (. vec4i 1) (. vec4i 2)))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (set-forcibly! (rv vec4i1 vec4i2)
                   (Im-gui.DragInt2 ctx "drag int2" (. vec4i 1) (. vec4i 2) 1 0
                                    255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (set-forcibly! (rv vec4i1 vec4i2)
                   (Im-gui.SliderInt2 ctx "slider int2" (. vec4i 1) (. vec4i 2)
                                      0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (Im-gui.SeparatorText ctx :3-wide)
    (set-forcibly! (rv vec4d1 vec4d2 vec4d3)
                   (Im-gui.InputDouble3 ctx "input double3" (. vec4d 1)
                                        (. vec4d 2) (. vec4d 3)))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (set-forcibly! (rv vec4d1 vec4d2 vec4d3)
                   (Im-gui.DragDouble3 ctx "drag double3" (. vec4d 1)
                                       (. vec4d 2) (. vec4d 3) 0.01 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (set-forcibly! (rv vec4d1 vec4d2 vec4d3)
                   (Im-gui.SliderDouble3 ctx "slider double3" (. vec4d 1)
                                         (. vec4d 2) (. vec4d 3) 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (set-forcibly! (rv vec4i1 vec4i2 vec4i3)
                   (Im-gui.InputInt3 ctx "input int3" (. vec4i 1) (. vec4i 2)
                                     (. vec4i 3)))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (set-forcibly! (rv vec4i1 vec4i2 vec4i3)
                   (Im-gui.DragInt3 ctx "drag int3" (. vec4i 1) (. vec4i 2)
                                    (. vec4i 3) 1 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (set-forcibly! (rv vec4i1 vec4i2 vec4i3)
                   (Im-gui.SliderInt3 ctx "slider int3" (. vec4i 1) (. vec4i 2)
                                      (. vec4i 3) 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (Im-gui.SeparatorText ctx :4-wide)
    (set-forcibly! (rv vec4d1 vec4d2 vec4d3 vec4d4)
                   (Im-gui.InputDouble4 ctx "input double4" (. vec4d 1)
                                        (. vec4d 2) (. vec4d 3) (. vec4d 4)))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (tset vec4d 4 vec4d4)
    (set-forcibly! (rv vec4d1 vec4d2 vec4d3 vec4d4)
                   (Im-gui.DragDouble4 ctx "drag double4" (. vec4d 1)
                                       (. vec4d 2) (. vec4d 3) (. vec4d 4) 0.01
                                       0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (tset vec4d 4 vec4d4)
    (set-forcibly! (rv vec4d1 vec4d2 vec4d3 vec4d4)
                   (Im-gui.SliderDouble4 ctx "slider double4" (. vec4d 1)
                                         (. vec4d 2) (. vec4d 3) (. vec4d 4) 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (tset vec4d 4 vec4d4)
    (set-forcibly! (rv vec4i1 vec4i2 vec4i3 vec4i4)
                   (Im-gui.InputInt4 ctx "input int4" (. vec4i 1) (. vec4i 2)
                                     (. vec4i 3) (. vec4i 4)))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (tset vec4i 4 vec4i4)
    (set-forcibly! (rv vec4i1 vec4i2 vec4i3 vec4i4)
                   (Im-gui.DragInt4 ctx "drag int4" (. vec4i 1) (. vec4i 2)
                                    (. vec4i 3) (. vec4i 4) 1 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (tset vec4i 4 vec4i4)
    (set-forcibly! (rv vec4i1 vec4i2 vec4i3 vec4i4)
                   (Im-gui.SliderInt4 ctx "slider int4" (. vec4i 1) (. vec4i 2)
                                      (. vec4i 3) (. vec4i 4) 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (tset vec4i 4 vec4i4)
    (Im-gui.Spacing ctx)
    (Im-gui.InputDoubleN ctx "input reaper.array" widgets.multi_component.vec4a)
    (Im-gui.DragDoubleN ctx "drag reaper.array" widgets.multi_component.vec4a
                        0.01 0 1)
    (Im-gui.SliderDoubleN ctx "slider reaper.array"
                          widgets.multi_component.vec4a 0 1)
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Vertical Sliders")
    (when (not widgets.vsliders)
      (set widgets.vsliders
           {:int_value 0
            :values [0 0.6 0.35 0.9 0.7 0.2 0]
            :values2 [0.2 0.8 0.4 0.25]}))
    (local spacing 4)
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_ItemSpacing) spacing spacing)
    (set (rv widgets.vsliders.int_value)
         (Im-gui.VSliderInt ctx "##int" 18 160 widgets.vsliders.int_value 0 5))
    (Im-gui.SameLine ctx)
    (Im-gui.PushID ctx :set1)
    (each [i v (ipairs widgets.vsliders.values)]
      (when (> i 1) (Im-gui.SameLine ctx))
      (Im-gui.PushID ctx i)
      (Im-gui.PushStyleColor ctx (Im-gui.Col_FrameBg)
                             (demo.HSV (/ (- i 1) 7) 0.5 0.5 1))
      (Im-gui.PushStyleColor ctx (Im-gui.Col_FrameBgHovered)
                             (demo.HSV (/ (- i 1) 7) 0.6 0.5 1))
      (Im-gui.PushStyleColor ctx (Im-gui.Col_FrameBgActive)
                             (demo.HSV (/ (- i 1) 7) 0.7 0.5 1))
      (Im-gui.PushStyleColor ctx (Im-gui.Col_SliderGrab)
                             (demo.HSV (/ (- i 1) 7) 0.9 0.9 1))
      (set-forcibly! (rv vi) (Im-gui.VSliderDouble ctx "##v" 18 160 v 0 1 " "))
      (tset widgets.vsliders.values i vi)
      (when (or (Im-gui.IsItemActive ctx) (Im-gui.IsItemHovered ctx))
        (Im-gui.SetTooltip ctx (: "%.3f" :format v)))
      (Im-gui.PopStyleColor ctx 4)
      (Im-gui.PopID ctx))
    (Im-gui.PopID ctx)
    (Im-gui.SameLine ctx)
    (Im-gui.PushID ctx :set2)
    (local rows 3)
    (local (small-slider-w small-slider-h)
           (values 18 (/ (- 160 (* (- rows 1) spacing)) rows)))
    (each [nx v2 (ipairs widgets.vsliders.values2)]
      (when (> nx 1) (Im-gui.SameLine ctx))
      (Im-gui.BeginGroup ctx)
      (for [ny 0 (- rows 1)]
        (Im-gui.PushID ctx (+ (* nx rows) ny))
        (set-forcibly! (rv v2)
                       (Im-gui.VSliderDouble ctx "##v" small-slider-w
                                             small-slider-h v2 0 1 " "))
        (when rv (tset widgets.vsliders.values2 nx v2))
        (when (or (Im-gui.IsItemActive ctx) (Im-gui.IsItemHovered ctx))
          (Im-gui.SetTooltip ctx (: "%.3f" :format v2)))
        (Im-gui.PopID ctx))
      (Im-gui.EndGroup ctx))
    (Im-gui.PopID ctx)
    (Im-gui.SameLine ctx)
    (Im-gui.PushID ctx :set3)
    (for [i 1 4] (local v (. widgets.vsliders.values i))
      (when (> i 1) (Im-gui.SameLine ctx))
      (Im-gui.PushID ctx i)
      (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_GrabMinSize) 40)
      (set-forcibly! (rv vi) (Im-gui.VSliderDouble ctx "##v" 40 160 v 0 1 "%.2f
sec"))
      (tset widgets.vsliders.values i vi)
      (Im-gui.PopStyleVar ctx)
      (Im-gui.PopID ctx))
    (Im-gui.PopID ctx)
    (Im-gui.PopStyleVar ctx)
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Drag and Drop")
    (when (not widgets.dragdrop)
      (set widgets.dragdrop {:color1 16711731
                             :color2 1723007104
                             :files {}
                             :items ["Item One"
                                     "Item Two"
                                     "Item Three"
                                     "Item Four"
                                     "Item Five"]
                             :mode 0
                             :names [:Bobby
                                     :Beatrice
                                     :Betty
                                     :Brianna
                                     :Barry
                                     :Bernard
                                     :Bibi
                                     :Blaine
                                     :Bryn]}))
    (when (Im-gui.TreeNode ctx "Drag and drop in standard widgets")
      (demo.HelpMarker "You can drag from the color squares.")
      (set (rv widgets.dragdrop.color1)
           (Im-gui.ColorEdit3 ctx "color 1" widgets.dragdrop.color1))
      (set (rv widgets.dragdrop.color2)
           (Im-gui.ColorEdit4 ctx "color 2" widgets.dragdrop.color2))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Drag and drop to copy/swap items")
      (local (mode-copy mode-move mode-swap) (values 0 1 2))
      (when (Im-gui.RadioButton ctx :Copy (= widgets.dragdrop.mode mode-copy))
        (set widgets.dragdrop.mode mode-copy))
      (Im-gui.SameLine ctx)
      (when (Im-gui.RadioButton ctx :Move (= widgets.dragdrop.mode mode-move))
        (set widgets.dragdrop.mode mode-move))
      (Im-gui.SameLine ctx)
      (when (Im-gui.RadioButton ctx :Swap (= widgets.dragdrop.mode mode-swap))
        (set widgets.dragdrop.mode mode-swap))
      (each [n name (ipairs widgets.dragdrop.names)]
        (Im-gui.PushID ctx n)
        (when (not= (% (- n 1) 3) 0)
          (Im-gui.SameLine ctx))
        (Im-gui.Button ctx name 60 60)
        (when (Im-gui.BeginDragDropSource ctx (Im-gui.DragDropFlags_None))
          (Im-gui.SetDragDropPayload ctx :DND_DEMO_CELL (tostring n))
          (when (= widgets.dragdrop.mode mode-copy)
            (Im-gui.Text ctx (: "Copy %s" :format name)))
          (when (= widgets.dragdrop.mode mode-move)
            (Im-gui.Text ctx (: "Move %s" :format name)))
          (when (= widgets.dragdrop.mode mode-swap)
            (Im-gui.Text ctx (: "Swap %s" :format name)))
          (Im-gui.EndDragDropSource ctx))
        (when (Im-gui.BeginDragDropTarget ctx)
          (var payload nil)
          (set (rv payload) (Im-gui.AcceptDragDropPayload ctx :DND_DEMO_CELL))
          (when rv
            (local payload-n (tonumber payload))
            (when (= widgets.dragdrop.mode mode-copy)
              (tset widgets.dragdrop.names n
                    (. widgets.dragdrop.names payload-n)))
            (when (= widgets.dragdrop.mode mode-move)
              (tset widgets.dragdrop.names n
                    (. widgets.dragdrop.names payload-n))
              (tset widgets.dragdrop.names payload-n ""))
            (when (= widgets.dragdrop.mode mode-swap)
              (tset widgets.dragdrop.names n
                    (. widgets.dragdrop.names payload-n))
              (tset widgets.dragdrop.names payload-n name)))
          (Im-gui.EndDragDropTarget ctx))
        (Im-gui.PopID ctx))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Drag to reorder items (simple)")
      (demo.HelpMarker "We don't use the drag and drop api at all here! Instead we query when the item is held but not hovered, and order items accordingly.")
      (each [n item (ipairs widgets.dragdrop.items)]
        (Im-gui.Selectable ctx item)
        (when (and (Im-gui.IsItemActive ctx) (not (Im-gui.IsItemHovered ctx)))
          (local mouse-delta
                 (select 2
                         (Im-gui.GetMouseDragDelta ctx
                                                   (Im-gui.MouseButton_Left))))
          (local n-next (+ n (or (and (< mouse-delta 0) (- 1)) 1)))
          (when (and (>= n-next 1) (<= n-next (length widgets.dragdrop.items)))
            (tset widgets.dragdrop.items n (. widgets.dragdrop.items n-next))
            (tset widgets.dragdrop.items n-next item)
            (Im-gui.ResetMouseDragDelta ctx (Im-gui.MouseButton_Left)))))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Drag and drop files")
      (when (Im-gui.BeginChildFrame ctx "##drop_files" (- FLT_MIN) 100)
        (if (= (length widgets.dragdrop.files) 0)
            (Im-gui.Text ctx "Drag and drop files here...")
            (do
              (Im-gui.Text ctx
                           (: "Received %d file(s):" :format
                              (length widgets.dragdrop.files)))
              (Im-gui.SameLine ctx)
              (when (Im-gui.SmallButton ctx :Clear)
                (set widgets.dragdrop.files {}))))
        (each [_ file (ipairs widgets.dragdrop.files)] (Im-gui.Bullet ctx)
          (Im-gui.TextWrapped ctx file))
        (Im-gui.EndChildFrame ctx))
      (when (Im-gui.BeginDragDropTarget ctx)
        (var (rv count) (Im-gui.AcceptDragDropPayloadFiles ctx))
        (when rv
          (set widgets.dragdrop.files {})
          (for [i 0 (- count 1)] (var filename nil)
            (set (rv filename) (Im-gui.GetDragDropPayloadFile ctx i))
            (table.insert widgets.dragdrop.files filename)))
        (Im-gui.EndDragDropTarget ctx))
      (Im-gui.TreePop ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx
                         "Querying Item Status (Edited/Active/Hovered etc.)")
    (when (not widgets.query_item)
      (set widgets.query_item {:b false
                               :color 4286578943
                               :current 1
                               :d4a [1 0.5 0 1]
                               :item_type 1
                               :str ""}))
    (set (rv widgets.query_item.item_type)
         (Im-gui.Combo ctx "Item Type" widgets.query_item.item_type
                       "Text\000Button\000Button (w/ repeat)\000Checkbox\000SliderDouble\000InputText\000InputTextMultiline\000InputDouble\000InputDouble3\000ColorEdit4\000Selectable\000MenuItem\000TreeNode\000TreeNode (w/ double-click)\000Combo\000ListBox\000"))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Testing how various types of items are interacting with the IsItemXXX functions. Note that the bool return value of most ImGui function is generally equivalent to calling ImGui.IsItemHovered().")
    (when widgets.query_item.item_disabled (Im-gui.BeginDisabled ctx true))
    (local item-type widgets.query_item.item_type)
    (when (= item-type 0) (Im-gui.Text ctx "ITEM: Text"))
    (when (= item-type 1) (set rv (Im-gui.Button ctx "ITEM: Button")))
    (when (= item-type 2) (Im-gui.PushButtonRepeat ctx true)
      (set rv (Im-gui.Button ctx "ITEM: Button"))
      (Im-gui.PopButtonRepeat ctx))
    (when (= item-type 3)
      (set (rv widgets.query_item.b)
           (Im-gui.Checkbox ctx "ITEM: Checkbox" widgets.query_item.b)))
    (when (= item-type 4)
      (set-forcibly! (rv da41)
                     (Im-gui.SliderDouble ctx "ITEM: SliderDouble"
                                          (. widgets.query_item.d4a 1) 0 1))
      (tset widgets.query_item.d4a 1 da41))
    (when (= item-type 5)
      (set (rv widgets.query_item.str)
           (Im-gui.InputText ctx "ITEM: InputText" widgets.query_item.str)))
    (when (= item-type 6)
      (set (rv widgets.query_item.str)
           (Im-gui.InputTextMultiline ctx "ITEM: InputTextMultiline"
                                      widgets.query_item.str)))
    (when (= item-type 7)
      (set-forcibly! (rv d4a1)
                     (Im-gui.InputDouble ctx "ITEM: InputDouble"
                                         (. widgets.query_item.d4a 1) 1))
      (tset widgets.query_item.d4a 1 d4a1))
    (when (= item-type 8)
      (local d4a widgets.query_item.d4a)
      (set-forcibly! (rv d4a1 d4a2 d4a3)
                     (Im-gui.InputDouble3 ctx "ITEM: InputDouble3" (. d4a 1)
                                          (. d4a 2) (. d4a 3)))
      (tset d4a 1 d4a1)
      (tset d4a 2 d4a2)
      (tset d4a 3 d4a3))
    (when (= item-type 9)
      (set (rv widgets.query_item.color)
           (Im-gui.ColorEdit4 ctx "ITEM: ColorEdit" widgets.query_item.color)))
    (when (= item-type 10) (set rv (Im-gui.Selectable ctx "ITEM: Selectable")))
    (when (= item-type 11) (set rv (Im-gui.MenuItem ctx "ITEM: MenuItem")))
    (when (= item-type 12) (set rv (Im-gui.TreeNode ctx "ITEM: TreeNode"))
      (when rv (Im-gui.TreePop ctx)))
    (when (= item-type 13)
      (set rv
           (Im-gui.TreeNode ctx
                            "ITEM: TreeNode w/ ImGuiTreeNodeFlags_OpenOnDoubleClick"
                            (bor (Im-gui.TreeNodeFlags_OpenOnDoubleClick)
                                 (Im-gui.TreeNodeFlags_NoTreePushOnOpen)))))
    (when (= item-type 14)
      (set (rv widgets.query_item.current)
           (Im-gui.Combo ctx "ITEM: Combo" widgets.query_item.current
                         "Apple\000Banana\000Cherry\000Kiwi\000")))
    (when (= item-type 15)
      (set (rv widgets.query_item.current)
           (Im-gui.ListBox ctx "ITEM: ListBox" widgets.query_item.current
                           "Apple\000Banana\000Cherry\000Kiwi\000")))
    (local hovered-delay-none (Im-gui.IsItemHovered ctx))
    (local hovered-delay-short
           (Im-gui.IsItemHovered ctx (Im-gui.HoveredFlags_DelayShort)))
    (local hovered-delay-normal
           (Im-gui.IsItemHovered ctx (Im-gui.HoveredFlags_DelayNormal)))
    (Im-gui.BulletText ctx
                       (: "Return value = %s
IsItemFocused() = %s
IsItemHovered() = %s
IsItemHovered(_AllowWhenBlockedByPopup) = %s
IsItemHovered(_AllowWhenBlockedByActiveItem) = %s
IsItemHovered(_AllowWhenOverlapped) = %s
IsItemHovered(_AllowWhenDisabled) = %s
IsItemHovered(_RectOnly) = %s
IsItemActive() = %s
IsItemEdited() = %s
IsItemActivated() = %s
IsItemDeactivated() = %s
IsItemDeactivatedAfterEdit() = %s
IsItemVisible() = %s
IsItemClicked() = %s
IsItemToggledOpen() = %s
GetItemRectMin() = (%.1f, %.1f)
GetItemRectMax() = (%.1f, %.1f)
GetItemRectSize() = (%.1f, %.1f)" :format rv
                          (Im-gui.IsItemFocused ctx) (Im-gui.IsItemHovered ctx)
                          (Im-gui.IsItemHovered ctx
                                                (Im-gui.HoveredFlags_AllowWhenBlockedByPopup))
                          (Im-gui.IsItemHovered ctx
                                                (Im-gui.HoveredFlags_AllowWhenBlockedByActiveItem))
                          (Im-gui.IsItemHovered ctx
                                                (Im-gui.HoveredFlags_AllowWhenOverlapped))
                          (Im-gui.IsItemHovered ctx
                                                (Im-gui.HoveredFlags_AllowWhenDisabled))
                          (Im-gui.IsItemHovered ctx
                                                (Im-gui.HoveredFlags_RectOnly))
                          (Im-gui.IsItemActive ctx) (Im-gui.IsItemEdited ctx)
                          (Im-gui.IsItemActivated ctx)
                          (Im-gui.IsItemDeactivated ctx)
                          (Im-gui.IsItemDeactivatedAfterEdit ctx)
                          (Im-gui.IsItemVisible ctx) (Im-gui.IsItemClicked ctx)
                          (Im-gui.IsItemToggledOpen ctx)
                          (Im-gui.GetItemRectMin ctx)
                          (select 2 (Im-gui.GetItemRectMin ctx))
                          (Im-gui.GetItemRectMax ctx)
                          (select 2 (Im-gui.GetItemRectMax ctx))
                          (Im-gui.GetItemRectSize ctx)
                          (select 2 (Im-gui.GetItemRectSize ctx))))
    (Im-gui.BulletText ctx (: "w/ Hovering Delay: None = %s, Fast = %s, Normal = %s"
                              :format hovered-delay-none hovered-delay-short
                              hovered-delay-normal))
    (when widgets.query_item.item_disabled (Im-gui.EndDisabled ctx))
    (Im-gui.InputText ctx :unused "" (Im-gui.InputTextFlags_ReadOnly))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "This widget is only here to be able to tab-out of the widgets above and see e.g. Deactivated() status.")
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Querying Window Status (Focused/Hovered etc.)")
    (when (not widgets.query_window)
      (set widgets.query_window
           {:embed_all_inside_a_child_window false :test_window false}))
    (set (rv widgets.query_window.embed_all_inside_a_child_window)
         (Im-gui.Checkbox ctx
                          "Embed everything inside a child window for testing _RootWindow flag."
                          widgets.query_window.embed_all_inside_a_child_window))
    (var visible true)
    (when widgets.query_window.embed_all_inside_a_child_window
      (set visible
           (Im-gui.BeginChild ctx :outer_child 0
                              (* (Im-gui.GetFontSize ctx) 20) true)))
    (when visible
      (Im-gui.BulletText ctx
                         (: "IsWindowFocused() = %s
  IsWindowFocused(_ChildWindows) = %s
  IsWindowFocused(_ChildWindows|_NoPopupHierarchy) = %s
  IsWindowFocused(_ChildWindows|_DockHierarchy) = %s
  IsWindowFocused(_ChildWindows|_RootWindow) = %s
  IsWindowFocused(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %s
  IsWindowFocused(_ChildWindows|_RootWindow|_DockHierarchy) = %s
  IsWindowFocused(_RootWindow) = %s
  IsWindowFocused(_RootWindow|_NoPopupHierarchy) = %s
  IsWindowFocused(_RootWindow|_DockHierarchy) = %s
  IsWindowFocused(_AnyWindow) = %s" :format
                            (Im-gui.IsWindowFocused ctx)
                            (Im-gui.IsWindowFocused ctx
                                                    (Im-gui.FocusedFlags_ChildWindows))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_ChildWindows)
                                                         (Im-gui.FocusedFlags_NoPopupHierarchy)))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_ChildWindows)
                                                         (Im-gui.FocusedFlags_DockHierarchy)))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_ChildWindows)
                                                         (Im-gui.FocusedFlags_RootWindow)))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_ChildWindows)
                                                         (Im-gui.FocusedFlags_RootWindow)
                                                         (Im-gui.FocusedFlags_NoPopupHierarchy)))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_ChildWindows)
                                                         (Im-gui.FocusedFlags_RootWindow)
                                                         (Im-gui.FocusedFlags_DockHierarchy)))
                            (Im-gui.IsWindowFocused ctx
                                                    (Im-gui.FocusedFlags_RootWindow))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_RootWindow)
                                                         (Im-gui.FocusedFlags_NoPopupHierarchy)))
                            (Im-gui.IsWindowFocused ctx
                                                    (bor (Im-gui.FocusedFlags_RootWindow)
                                                         (Im-gui.FocusedFlags_DockHierarchy)))
                            (Im-gui.IsWindowFocused ctx
                                                    (Im-gui.FocusedFlags_AnyWindow))))
      (Im-gui.BulletText ctx
                         (: "IsWindowHovered() = %s
  IsWindowHovered(_AllowWhenBlockedByPopup) = %s
  IsWindowHovered(_AllowWhenBlockedByActiveItem) = %s
  IsWindowHovered(_ChildWindows) = %s
  IsWindowHovered(_ChildWindows|_NoPopupHierarchy) = %s
  IsWindowHovered(_ChildWindows|_DockHierarchy) = %s
  IsWindowHovered(_ChildWindows|_RootWindow) = %s
  IsWindowHovered(_ChildWindows|_RootWindow|_NoPopupHierarchy) = %s
  IsWindowHovered(_ChildWindows|_RootWindow|_DockHierarchy) = %s
  IsWindowHovered(_RootWindow) = %s
  IsWindowHovered(_RootWindow|_NoPopupHierarchy) = %s
  IsWindowHovered(_RootWindow|_DockHierarchy) = %s
  IsWindowHovered(_ChildWindows|_AllowWhenBlockedByPopup) = %s
  IsWindowHovered(_AnyWindow) = %s" :format
                            (Im-gui.IsWindowHovered ctx)
                            (Im-gui.IsWindowHovered ctx
                                                    (Im-gui.HoveredFlags_AllowWhenBlockedByPopup))
                            (Im-gui.IsWindowHovered ctx
                                                    (Im-gui.HoveredFlags_AllowWhenBlockedByActiveItem))
                            (Im-gui.IsWindowHovered ctx
                                                    (Im-gui.HoveredFlags_ChildWindows))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_ChildWindows)
                                                         (Im-gui.HoveredFlags_NoPopupHierarchy)))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_ChildWindows)
                                                         (Im-gui.HoveredFlags_DockHierarchy)))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_ChildWindows)
                                                         (Im-gui.HoveredFlags_RootWindow)))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_ChildWindows)
                                                         (Im-gui.HoveredFlags_RootWindow)
                                                         (Im-gui.HoveredFlags_NoPopupHierarchy)))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_ChildWindows)
                                                         (Im-gui.HoveredFlags_RootWindow)
                                                         (Im-gui.HoveredFlags_DockHierarchy)))
                            (Im-gui.IsWindowHovered ctx
                                                    (Im-gui.HoveredFlags_RootWindow))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_RootWindow)
                                                         (Im-gui.HoveredFlags_NoPopupHierarchy)))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_RootWindow)
                                                         (Im-gui.HoveredFlags_DockHierarchy)))
                            (Im-gui.IsWindowHovered ctx
                                                    (bor (Im-gui.HoveredFlags_ChildWindows)
                                                         (Im-gui.HoveredFlags_AllowWhenBlockedByPopup)))
                            (Im-gui.IsWindowHovered ctx
                                                    (Im-gui.HoveredFlags_AnyWindow))))
      (when (Im-gui.BeginChild ctx :child 0 50 true)
        (Im-gui.Text ctx
                     "This is another child window for testing the _ChildWindows flag.")
        (Im-gui.EndChild ctx))
      (when widgets.query_window.embed_all_inside_a_child_window
        (Im-gui.EndChild ctx)))
    (set (rv widgets.query_window.test_window)
         (Im-gui.Checkbox ctx
                          "Hovered/Active tests after Begin() for title bar testing"
                          widgets.query_window.test_window))
    (when widgets.query_window.test_window
      (set (rv widgets.query_window.test_window)
           (Im-gui.Begin ctx "Title bar Hovered/Active tests" true))
      (when rv
        (when (Im-gui.BeginPopupContextItem ctx)
          (when (Im-gui.MenuItem ctx :Close)
            (set widgets.query_window.test_window false))
          (Im-gui.EndPopup ctx))
        (Im-gui.Text ctx (: "IsItemHovered() after begin = %s (== is title bar hovered)
IsItemActive() after begin = %s (== is window being clicked/moved)
" :format (Im-gui.IsItemHovered ctx)
                            (Im-gui.IsItemActive ctx)))
        (Im-gui.End ctx)))
    (Im-gui.TreePop ctx))
  (when widgets.disable_all (Im-gui.EndDisabled ctx))
  (when (Im-gui.TreeNode ctx "Disable block")
    (set (rv widgets.disable_all)
         (Im-gui.Checkbox ctx "Disable entire section above"
                          widgets.disable_all))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Demonstrate using BeginDisabled()/EndDisabled() across this section.")
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Text Filter")
    (when (not widgets.filtering) (set widgets.filtering {:inst nil :text ""}))
    (when (not (Im-gui.ValidatePtr widgets.filtering.inst :ImGui_TextFilter*))
      (set widgets.filtering.inst
           (Im-gui.CreateTextFilter widgets.filtering.text)))
    (demo.HelpMarker "Not a widget per-se, but ImGui_TextFilter is a helper to perform simple filtering on text strings.")
    (Im-gui.Text ctx "Filter usage:
  \"\"         display all lines
  \"xxx\"      display lines containing \"xxx\"
  \"xxx,yyy\"  display lines containing \"xxx\" or \"yyy\"
  \"-xxx\"     hide lines containing \"xxx\"")
    (when (Im-gui.TextFilter_Draw widgets.filtering.inst ctx)
      (set widgets.filtering.text
           (Im-gui.TextFilter_Get widgets.filtering.inst)))
    (local lines [:aaa1.c
                  :bbb1.c
                  :ccc1.c
                  :aaa2.cpp
                  :bbb2.cpp
                  :ccc2.cpp
                  :abc.h
                  "hello, world"])
    (each [i line (ipairs lines)]
      (when (Im-gui.TextFilter_PassFilter widgets.filtering.inst line)
        (Im-gui.BulletText ctx line)))
    (Im-gui.TreePop ctx)))

(fn demo.ShowDemoWindowLayout []
  (when (not (Im-gui.CollapsingHeader ctx "Layout & Scrolling"))
    (lua "return "))
  (var rv nil)
  (when (Im-gui.TreeNode ctx "Child windows")
    (when (not layout.child)
      (set layout.child {:disable_menu false
                         :disable_mouse_wheel false
                         :offset_x 0}))
    (Im-gui.SeparatorText ctx "Child windows")
    (demo.HelpMarker "Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window.")
    (set (rv layout.child.disable_mouse_wheel)
         (Im-gui.Checkbox ctx "Disable Mouse Wheel"
                          layout.child.disable_mouse_wheel))
    (set (rv layout.child.disable_menu)
         (Im-gui.Checkbox ctx "Disable Menu" layout.child.disable_menu))
    (do
      (var window-flags (Im-gui.WindowFlags_HorizontalScrollbar))
      (when layout.child.disable_mouse_wheel
        (set window-flags
             (bor window-flags (Im-gui.WindowFlags_NoScrollWithMouse))))
      (when (Im-gui.BeginChild ctx :ChildL
                               (* (Im-gui.GetContentRegionAvail ctx) 0.5) 260
                               false window-flags)
        (for [i 0 99] (Im-gui.Text ctx (: "%04d: scrollable region" :format i)))
        (Im-gui.EndChild ctx)))
    (Im-gui.SameLine ctx)
    (do
      (var window-flags (Im-gui.WindowFlags_None))
      (when layout.child.disable_mouse_wheel
        (set window-flags
             (bor window-flags (Im-gui.WindowFlags_NoScrollWithMouse))))
      (when (not layout.child.disable_menu)
        (set window-flags (bor window-flags (Im-gui.WindowFlags_MenuBar))))
      (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_ChildRounding) 5)
      (local visible (Im-gui.BeginChild ctx :ChildR 0 260 true window-flags))
      (when visible
        (when (and (not layout.child.disable_menu) (Im-gui.BeginMenuBar ctx))
          (when (Im-gui.BeginMenu ctx :Menu) (demo.ShowExampleMenuFile)
            (Im-gui.EndMenu ctx))
          (Im-gui.EndMenuBar ctx))
        (when (Im-gui.BeginTable ctx :split 2
                                 (bor (Im-gui.TableFlags_Resizable)
                                      (Im-gui.TableFlags_NoSavedSettings)))
          (for [i 0 99] (Im-gui.TableNextColumn ctx)
            (Im-gui.Button ctx (: "%03d" :format i) (- FLT_MIN) 0))
          (Im-gui.EndTable ctx))
        (Im-gui.EndChild ctx))
      (Im-gui.PopStyleVar ctx))
    (Im-gui.SeparatorText ctx :Misc/Advanced)
    (do
      (Im-gui.SetNextItemWidth ctx (* (Im-gui.GetFontSize ctx) 8))
      (set (rv layout.child.offset_x)
           (Im-gui.DragInt ctx "Offset X" layout.child.offset_x 1 (- 1000) 1000))
      (Im-gui.SetCursorPosX ctx
                            (+ (Im-gui.GetCursorPosX ctx) layout.child.offset_x))
      (Im-gui.PushStyleColor ctx (Im-gui.Col_ChildBg) 4278190180)
      (local visible
             (Im-gui.BeginChild ctx :Red 200 100 true (Im-gui.WindowFlags_None)))
      (Im-gui.PopStyleColor ctx)
      (when visible
        (for [n 0 49] (Im-gui.Text ctx (: "Some test %d" :format n)))
        (Im-gui.EndChild ctx))
      (local child-is-hovered (Im-gui.IsItemHovered ctx))
      (local (child-rect-min-x child-rect-min-y) (Im-gui.GetItemRectMin ctx))
      (local (child-rect-max-x child-rect-max-y) (Im-gui.GetItemRectMax ctx))
      (Im-gui.Text ctx (: "Hovered: %s" :format child-is-hovered))
      (Im-gui.Text ctx
                   (: "Rect of child window is: (%.0f,%.0f) (%.0f,%.0f)"
                      :format child-rect-min-x child-rect-min-y child-rect-max-x
                      child-rect-max-y)))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Widgets Width")
    (when (not layout.width)
      (set layout.width {:d 0 :show_indented_items true}))
    (set (rv layout.width.show_indented_items)
         (Im-gui.Checkbox ctx "Show indented items"
                          layout.width.show_indented_items))
    (Im-gui.Text ctx "SetNextItemWidth/PushItemWidth(100)")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Fixed width.")
    (Im-gui.PushItemWidth ctx 100)
    (set (rv layout.width.d) (Im-gui.DragDouble ctx "float##1b" layout.width.d))
    (when layout.width.show_indented_items (Im-gui.Indent ctx)
      (set (rv layout.width.d)
           (Im-gui.DragDouble ctx "float (indented)##1b" layout.width.d))
      (Im-gui.Unindent ctx))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.Text ctx "SetNextItemWidth/PushItemWidth(-100)")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Align to right edge minus 100")
    (Im-gui.PushItemWidth ctx (- 100))
    (set (rv layout.width.d) (Im-gui.DragDouble ctx "float##2a" layout.width.d))
    (when layout.width.show_indented_items (Im-gui.Indent ctx)
      (set (rv layout.width.d)
           (Im-gui.DragDouble ctx "float (indented)##2b" layout.width.d))
      (Im-gui.Unindent ctx))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.Text ctx
                 "SetNextItemWidth/PushItemWidth(GetContentRegionAvail().x * 0.5)")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Half of available width.
(~ right-cursor_pos)
(works within a column set)")
    (Im-gui.PushItemWidth ctx (* (Im-gui.GetContentRegionAvail ctx) 0.5))
    (set (rv layout.width.d) (Im-gui.DragDouble ctx "float##3a" layout.width.d))
    (when layout.width.show_indented_items (Im-gui.Indent ctx)
      (set (rv layout.width.d)
           (Im-gui.DragDouble ctx "float (indented)##3b" layout.width.d))
      (Im-gui.Unindent ctx))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.Text ctx
                 "SetNextItemWidth/PushItemWidth(-GetContentRegionAvail().x * 0.5)")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Align to right edge minus half")
    (Im-gui.PushItemWidth ctx (* (- (Im-gui.GetContentRegionAvail ctx)) 0.5))
    (set (rv layout.width.d) (Im-gui.DragDouble ctx "float##4a" layout.width.d))
    (when layout.width.show_indented_items (Im-gui.Indent ctx)
      (set (rv layout.width.d)
           (Im-gui.DragDouble ctx "float (indented)##4b" layout.width.d))
      (Im-gui.Unindent ctx))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.Text ctx "SetNextItemWidth/PushItemWidth(-FLT_MIN)")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Align to right edge")
    (Im-gui.PushItemWidth ctx (- FLT_MIN))
    (set (rv layout.width.d) (Im-gui.DragDouble ctx "##float5a" layout.width.d))
    (when layout.width.show_indented_items (Im-gui.Indent ctx)
      (set (rv layout.width.d)
           (Im-gui.DragDouble ctx "float (indented)##5b" layout.width.d))
      (Im-gui.Unindent ctx))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Basic Horizontal Layout")
    (when (not layout.horizontal)
      (set layout.horizontal
           {:c1 false
            :c2 false
            :c3 false
            :c4 false
            :d0 1
            :d1 2
            :d2 3
            :item (- 1)
            :selection [0 1 2 3]}))
    (Im-gui.TextWrapped ctx
                        "(Use ImGui.SameLine() to keep adding items to the right of the preceding item)")
    (Im-gui.Text ctx "Two items: Hello")
    (Im-gui.SameLine ctx)
    (Im-gui.TextColored ctx 4294902015 :Sailor)
    (Im-gui.Text ctx "More spacing: Hello")
    (Im-gui.SameLine ctx 0 20)
    (Im-gui.TextColored ctx 4294902015 :Sailor)
    (Im-gui.AlignTextToFramePadding ctx)
    (Im-gui.Text ctx "Normal buttons")
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :Banana)
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :Apple)
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :Corniflower)
    (Im-gui.Text ctx "Small buttons")
    (Im-gui.SameLine ctx)
    (Im-gui.SmallButton ctx "Like this one")
    (Im-gui.SameLine ctx)
    (Im-gui.Text ctx "can fit within a text block.")
    (Im-gui.Text ctx :Aligned)
    (Im-gui.SameLine ctx 150)
    (Im-gui.Text ctx :x=150)
    (Im-gui.SameLine ctx 300)
    (Im-gui.Text ctx :x=300)
    (Im-gui.Text ctx :Aligned)
    (Im-gui.SameLine ctx 150)
    (Im-gui.SmallButton ctx :x=150)
    (Im-gui.SameLine ctx 300)
    (Im-gui.SmallButton ctx :x=300)
    (set (rv layout.horizontal.c1)
         (Im-gui.Checkbox ctx :My layout.horizontal.c1))
    (Im-gui.SameLine ctx)
    (set (rv layout.horizontal.c2)
         (Im-gui.Checkbox ctx :Tailor layout.horizontal.c2))
    (Im-gui.SameLine ctx)
    (set (rv layout.horizontal.c3)
         (Im-gui.Checkbox ctx :Is layout.horizontal.c3))
    (Im-gui.SameLine ctx)
    (set (rv layout.horizontal.c4)
         (Im-gui.Checkbox ctx :Rich layout.horizontal.c4))
    (Im-gui.PushItemWidth ctx 80)
    (local items "AAAA\000BBBB\000CCCC\000DDDD\000")
    (set (rv layout.horizontal.item)
         (Im-gui.Combo ctx :Combo layout.horizontal.item items))
    (Im-gui.SameLine ctx)
    (set (rv layout.horizontal.d0)
         (Im-gui.SliderDouble ctx :X layout.horizontal.d0 0 5))
    (Im-gui.SameLine ctx)
    (set (rv layout.horizontal.d1)
         (Im-gui.SliderDouble ctx :Y layout.horizontal.d1 0 5))
    (Im-gui.SameLine ctx)
    (set (rv layout.horizontal.d2)
         (Im-gui.SliderDouble ctx :Z layout.horizontal.d2 0 5))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.PushItemWidth ctx 80)
    (Im-gui.Text ctx "Lists:")
    (each [i sel (ipairs layout.horizontal.selection)]
      (when (> i 1) (Im-gui.SameLine ctx))
      (Im-gui.PushID ctx i)
      (set-forcibly! (rv si) (Im-gui.ListBox ctx "" sel items))
      (tset layout.horizontal.selection i si)
      (Im-gui.PopID ctx))
    (Im-gui.PopItemWidth ctx)
    (local button-sz [40 40])
    (Im-gui.Button ctx :A (table.unpack button-sz))
    (Im-gui.SameLine ctx)
    (Im-gui.Dummy ctx (table.unpack button-sz))
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :B (table.unpack button-sz))
    (Im-gui.Text ctx "Manual wrapping:")
    (local item-spacing-x
           (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemSpacing)))
    (local buttons-count 20)
    (local window-visible-x2
           (+ (Im-gui.GetWindowPos ctx) (Im-gui.GetWindowContentRegionMax ctx)))
    (for [n 0 (- buttons-count 1)]
      (Im-gui.PushID ctx n)
      (Im-gui.Button ctx :Box (table.unpack button-sz))
      (local last-button-x2 (Im-gui.GetItemRectMax ctx))
      (local next-button-x2 (+ last-button-x2 item-spacing-x (. button-sz 1)))
      (when (and (< (+ n 1) buttons-count) (< next-button-x2 window-visible-x2))
        (Im-gui.SameLine ctx))
      (Im-gui.PopID ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Groups)
    (when (not widgets.groups)
      (set widgets.groups {:values (reaper.new_array [0.5 0.2 0.8 0.6 0.25])}))
    (demo.HelpMarker "BeginGroup() basically locks the horizontal position for new line. EndGroup() bundles the whole group so that you can use \"item\" functions such as IsItemHovered()/IsItemActive() or SameLine() etc. on the whole group.")
    (Im-gui.BeginGroup ctx)
    (Im-gui.BeginGroup ctx)
    (Im-gui.Button ctx :AAA)
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :BBB)
    (Im-gui.SameLine ctx)
    (Im-gui.BeginGroup ctx)
    (Im-gui.Button ctx :CCC)
    (Im-gui.Button ctx :DDD)
    (Im-gui.EndGroup ctx)
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :EEE)
    (Im-gui.EndGroup ctx)
    (when (Im-gui.IsItemHovered ctx)
      (Im-gui.SetTooltip ctx "First group hovered"))
    (local size [(Im-gui.GetItemRectSize ctx)])
    (local item-spacing-x
           (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemSpacing)))
    (Im-gui.PlotHistogram ctx "##values" widgets.groups.values 0 nil 0 1
                          (table.unpack size))
    (Im-gui.Button ctx :ACTION (* (- (. size 1) item-spacing-x) 0.5) (. size 2))
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx :REACTION (* (- (. size 1) item-spacing-x) 0.5)
                   (. size 2))
    (Im-gui.EndGroup ctx)
    (Im-gui.SameLine ctx)
    (Im-gui.Button ctx "LEVERAGE\nBUZZWORD" (table.unpack size))
    (Im-gui.SameLine ctx)
    (when (Im-gui.BeginListBox ctx :List (table.unpack size))
      (Im-gui.Selectable ctx :Selected true)
      (Im-gui.Selectable ctx "Not Selected" false)
      (Im-gui.EndListBox ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Text Baseline Alignment")
    (do
      (Im-gui.BulletText ctx "Text baseline:") (Im-gui.SameLine ctx)
      (demo.HelpMarker "This is testing the vertical alignment that gets applied on text to keep it aligned with widgets. Lines only composed of text or \"small\" widgets use less vertical space than lines with framed widgets.")
      (Im-gui.Indent ctx)
      (Im-gui.Text ctx "KO Blahblah")
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx "Some framed item")
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Baseline of button will look misaligned with text..")
      (Im-gui.AlignTextToFramePadding ctx)
      (Im-gui.Text ctx "OK Blahblah")
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx "Some framed item")
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "We call AlignTextToFramePadding() to vertically align the text baseline by +FramePadding.y")
      (Im-gui.Button ctx "TEST##1")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx :TEST)
      (Im-gui.SameLine ctx)
      (Im-gui.SmallButton ctx "TEST##2")
      (Im-gui.AlignTextToFramePadding ctx)
      (Im-gui.Text ctx "Text aligned to framed item")
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx "Item##1")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx :Item)
      (Im-gui.SameLine ctx)
      (Im-gui.SmallButton ctx "Item##2")
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx "Item##3")
      (Im-gui.Unindent ctx))
    (Im-gui.Spacing ctx)
    (do
      (Im-gui.BulletText ctx "Multi-line text:") (Im-gui.Indent ctx)
      (Im-gui.Text ctx "One\nTwo\nThree")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "Hello\nWorld")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx :Banana)
      (Im-gui.Text ctx :Banana)
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "Hello\nWorld")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "One\nTwo\nThree")
      (Im-gui.Button ctx "HOP##1")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx :Banana)
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "Hello\nWorld")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx :Banana)
      (Im-gui.Button ctx "HOP##2")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "Hello\nWorld")
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx :Banana)
      (Im-gui.Unindent ctx))
    (Im-gui.Spacing ctx)
    (do
      (Im-gui.BulletText ctx "Misc items:")
      (Im-gui.Indent ctx)
      (Im-gui.Button ctx :80x80 80 80)
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx :50x50 50 50)
      (Im-gui.SameLine ctx)
      (Im-gui.Button ctx "Button()")
      (Im-gui.SameLine ctx)
      (Im-gui.SmallButton ctx "SmallButton()")
      (local spacing
             (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemInnerSpacing)))
      (Im-gui.Button ctx "Button##1")
      (Im-gui.SameLine ctx 0 spacing)
      (when (Im-gui.TreeNode ctx "Node##1")
        (for [i 0 5] (Im-gui.BulletText ctx (: "Item %d.." :format i)))
        (Im-gui.TreePop ctx))
      (Im-gui.AlignTextToFramePadding ctx)
      (local node-open (Im-gui.TreeNode ctx "Node##2"))
      (Im-gui.SameLine ctx 0 spacing)
      (Im-gui.Button ctx "Button##2")
      (when node-open
        (for [i 0 5] (Im-gui.BulletText ctx (: "Item %d.." :format i)))
        (Im-gui.TreePop ctx))
      (Im-gui.Button ctx "Button##3")
      (Im-gui.SameLine ctx 0 spacing)
      (Im-gui.BulletText ctx "Bullet text")
      (Im-gui.AlignTextToFramePadding ctx)
      (Im-gui.BulletText ctx :Node)
      (Im-gui.SameLine ctx 0 spacing)
      (Im-gui.Button ctx "Button##4")
      (Im-gui.Unindent ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Scrolling)
    (when (not layout.scrolling)
      (set layout.scrolling {:enable_extra_decorations false
                             :enable_track true
                             :lines 7
                             :scroll_to_off_px 0
                             :scroll_to_pos_px 200
                             :show_horizontal_contents_size_demo_window false
                             :track_item 50}))
    (demo.HelpMarker "Use SetScrollHereY() or SetScrollFromPosY() to scroll to a given vertical position.")
    (set (rv layout.scrolling.enable_extra_decorations)
         (Im-gui.Checkbox ctx :Decoration
                          layout.scrolling.enable_extra_decorations))
    (set (rv layout.scrolling.enable_track)
         (Im-gui.Checkbox ctx :Track layout.scrolling.enable_track))
    (Im-gui.PushItemWidth ctx 100)
    (Im-gui.SameLine ctx 140)
    (set (rv layout.scrolling.track_item)
         (Im-gui.DragInt ctx "##item" layout.scrolling.track_item 0.25 0 99
                         "Item = %d"))
    (when rv (set layout.scrolling.enable_track true))
    (var scroll-to-off (Im-gui.Button ctx "Scroll Offset"))
    (Im-gui.SameLine ctx 140)
    (set (rv layout.scrolling.scroll_to_off_px)
         (Im-gui.DragDouble ctx "##off" layout.scrolling.scroll_to_off_px 1 0
                            FLT_MAX "+%.0f px"))
    (when rv (set scroll-to-off true))
    (var scroll-to-pos (Im-gui.Button ctx "Scroll To Pos"))
    (Im-gui.SameLine ctx 140)
    (set (rv layout.scrolling.scroll_to_pos_px)
         (Im-gui.DragDouble ctx "##pos" layout.scrolling.scroll_to_pos_px 1
                            (- 10) FLT_MAX "X/Y = %.0f px"))
    (when rv (set scroll-to-pos true))
    (Im-gui.PopItemWidth ctx)
    (when (or scroll-to-off scroll-to-pos)
      (set layout.scrolling.enable_track false))
    (local names [:Top "25%" :Center "75%" :Bottom])
    (local item-spacing-x
           (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemSpacing)))
    (var child-w (/ (- (Im-gui.GetContentRegionAvail ctx) (* 4 item-spacing-x))
                    (length names)))
    (local child-flags (or (and layout.scrolling.enable_extra_decorations
                                (Im-gui.WindowFlags_MenuBar))
                           (Im-gui.WindowFlags_None)))
    (when (< child-w 1) (set child-w 1))
    (Im-gui.PushID ctx "##VerticalScrolling")
    (each [i name (ipairs names)]
      (when (> i 1) (Im-gui.SameLine ctx))
      (Im-gui.BeginGroup ctx)
      (Im-gui.Text ctx name)
      (if (Im-gui.BeginChild ctx i child-w 200 true child-flags)
          (do
            (when (Im-gui.BeginMenuBar ctx) (Im-gui.Text ctx :abc)
              (Im-gui.EndMenuBar ctx))
            (when scroll-to-off
              (Im-gui.SetScrollY ctx layout.scrolling.scroll_to_off_px))
            (when scroll-to-pos
              (Im-gui.SetScrollFromPosY ctx
                                        (+ (select 2
                                                   (Im-gui.GetCursorStartPos ctx))
                                           layout.scrolling.scroll_to_pos_px)
                                        (* (- i 1) 0.25)))
            (for [item 0 99]
              (if (and layout.scrolling.enable_track
                       (= item layout.scrolling.track_item))
                  (do
                    (Im-gui.TextColored ctx 4294902015
                                        (: "Item %d" :format item))
                    (Im-gui.SetScrollHereY ctx (* (- i 1) 0.25)))
                  (Im-gui.Text ctx (: "Item %d" :format item))))
            (local scroll-y (Im-gui.GetScrollY ctx))
            (local scroll-max-y (Im-gui.GetScrollMaxY ctx))
            (Im-gui.EndChild ctx)
            (Im-gui.Text ctx (: "%.0f/%.0f" :format scroll-y scroll-max-y)))
          (Im-gui.Text ctx :N/A))
      (Im-gui.EndGroup ctx))
    (Im-gui.PopID ctx)
    (Im-gui.Spacing ctx)
    (demo.HelpMarker "Use SetScrollHereX() or SetScrollFromPosX() to scroll to a given horizontal position.

Because the clipping rectangle of most window hides half worth of WindowPadding on the left/right, using SetScrollFromPosX(+1) will usually result in clipped text whereas the equivalent SetScrollFromPosY(+1) wouldn't.")
    (Im-gui.PushID ctx "##HorizontalScrolling")
    (local scrollbar-size
           (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ScrollbarSize)))
    (local window-padding-y
           (select 2 (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_WindowPadding))))
    (local child-height (+ (Im-gui.GetTextLineHeight ctx) scrollbar-size
                           (* window-padding-y 2)))
    (var child-flags (Im-gui.WindowFlags_HorizontalScrollbar))
    (when layout.scrolling.enable_extra_decorations
      (set child-flags
           (bor child-flags (Im-gui.WindowFlags_AlwaysVerticalScrollbar))))
    (each [i name (ipairs names)]
      (var (scroll-x scroll-max-x) (values 0 0))
      (when (Im-gui.BeginChild ctx i (- 100) child-height true child-flags)
        (when scroll-to-off
          (Im-gui.SetScrollX ctx layout.scrolling.scroll_to_off_px))
        (when scroll-to-pos
          (Im-gui.SetScrollFromPosX ctx
                                    (+ (Im-gui.GetCursorStartPos ctx)
                                       layout.scrolling.scroll_to_pos_px)
                                    (* (- i 1) 0.25)))
        (for [item 0 99]
          (when (> item 0) (Im-gui.SameLine ctx))
          (if (and layout.scrolling.enable_track
                   (= item layout.scrolling.track_item))
              (do
                (Im-gui.TextColored ctx 4294902015 (: "Item %d" :format item))
                (Im-gui.SetScrollHereX ctx (* (- i 1) 0.25)))
              (Im-gui.Text ctx (: "Item %d" :format item))))
        (set scroll-x (Im-gui.GetScrollX ctx))
        (set scroll-max-x (Im-gui.GetScrollMaxX ctx))
        (Im-gui.EndChild ctx))
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx (: "%s\n%.0f/%.0f" :format name scroll-x scroll-max-x))
      (Im-gui.Spacing ctx))
    (Im-gui.PopID ctx)
    (demo.HelpMarker "Horizontal scrolling for a window is enabled via the ImGuiWindowFlags_HorizontalScrollbar flag.

You may want to also explicitly specify content width by using SetNextWindowContentWidth() before Begin().")
    (set (rv layout.scrolling.lines)
         (Im-gui.SliderInt ctx :Lines layout.scrolling.lines 1 15))
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FrameRounding) 3)
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) 2 1)
    (local scrolling-child-width (+ (* (Im-gui.GetFrameHeightWithSpacing ctx) 7)
                                    30))
    (var (scroll-x scroll-max-x) (values 0 0))
    (when (Im-gui.BeginChild ctx :scrolling 0 scrolling-child-width true
                             (Im-gui.WindowFlags_HorizontalScrollbar))
      (for [line 0 (- layout.scrolling.lines 1)]
        (local num-buttons (+ 10
                              (or (and (not= (band line 1) 0) (* line 9))
                                  (* line 3))))
        (for [n 0 (- num-buttons 1)]
          (when (> n 0) (Im-gui.SameLine ctx))
          (Im-gui.PushID ctx (+ n (* line 1000)))
          (var label nil)
          (if (= (% n 15) 0) (set label :FizzBuzz)
              (= (% n 3) 0) (set label :Fizz)
              (= (% n 5) 0) (set label :Buzz)
              (set label (tostring n)))
          (local hue (* n 0.05))
          (Im-gui.PushStyleColor ctx (Im-gui.Col_Button) (demo.HSV hue 0.6 0.6))
          (Im-gui.PushStyleColor ctx (Im-gui.Col_ButtonHovered)
                                 (demo.HSV hue 0.7 0.7))
          (Im-gui.PushStyleColor ctx (Im-gui.Col_ButtonActive)
                                 (demo.HSV hue 0.8 0.8))
          (Im-gui.Button ctx label (+ 40 (* (math.sin (+ line n)) 20)) 0)
          (Im-gui.PopStyleColor ctx 3)
          (Im-gui.PopID ctx)))
      (set scroll-x (Im-gui.GetScrollX ctx))
      (set scroll-max-x (Im-gui.GetScrollMaxX ctx))
      (Im-gui.EndChild ctx))
    (Im-gui.PopStyleVar ctx 2)
    (var scroll-x-delta 0)
    (Im-gui.SmallButton ctx "<<")
    (when (Im-gui.IsItemActive ctx)
      (set scroll-x-delta (* (- 0 (Im-gui.GetDeltaTime ctx)) 1000)))
    (Im-gui.SameLine ctx)
    (Im-gui.Text ctx "Scroll from code")
    (Im-gui.SameLine ctx)
    (Im-gui.SmallButton ctx ">>")
    (when (Im-gui.IsItemActive ctx)
      (set scroll-x-delta (* (Im-gui.GetDeltaTime ctx) 1000)))
    (Im-gui.SameLine ctx)
    (Im-gui.Text ctx (: "%.0f/%.0f" :format scroll-x scroll-max-x))
    (when (not= scroll-x-delta 0)
      (when (Im-gui.BeginChild ctx :scrolling)
        (Im-gui.SetScrollX ctx (+ (Im-gui.GetScrollX ctx) scroll-x-delta))
        (Im-gui.EndChild ctx)))
    (Im-gui.Spacing ctx)
    (set (rv layout.scrolling.show_horizontal_contents_size_demo_window)
         (Im-gui.Checkbox ctx "Show Horizontal contents size demo window"
                          layout.scrolling.show_horizontal_contents_size_demo_window))
    (when layout.scrolling.show_horizontal_contents_size_demo_window
      (when (not layout.horizontal_window)
        (set layout.horizontal_window
             {:contents_size_x 300
              :explicit_content_size false
              :show_button true
              :show_child false
              :show_columns true
              :show_h_scrollbar true
              :show_tab_bar true
              :show_text_wrapped false
              :show_tree_nodes true}))
      (when layout.horizontal_window.explicit_content_size
        (Im-gui.SetNextWindowContentSize ctx
                                         layout.horizontal_window.contents_size_x
                                         0))
      (set (rv layout.scrolling.show_horizontal_contents_size_demo_window)
           (Im-gui.Begin ctx "Horizontal contents size demo window" true
                         (or (and layout.horizontal_window.show_h_scrollbar
                                  (Im-gui.WindowFlags_HorizontalScrollbar))
                             (Im-gui.WindowFlags_None))))
      (when rv
        (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_ItemSpacing) 2 0)
        (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) 2 0)
        (demo.HelpMarker "Test of different widgets react and impact the work rectangle growing when horizontal scrolling is enabled.

Use 'Metrics->Tools->Show windows rectangles' to visualize rectangles.")
        (set (rv layout.horizontal_window.show_h_scrollbar)
             (Im-gui.Checkbox ctx :H-scrollbar
                              layout.horizontal_window.show_h_scrollbar))
        (set (rv layout.horizontal_window.show_button)
             (Im-gui.Checkbox ctx :Button layout.horizontal_window.show_button))
        (set (rv layout.horizontal_window.show_tree_nodes)
             (Im-gui.Checkbox ctx "Tree nodes"
                              layout.horizontal_window.show_tree_nodes))
        (set (rv layout.horizontal_window.show_text_wrapped)
             (Im-gui.Checkbox ctx "Text wrapped"
                              layout.horizontal_window.show_text_wrapped))
        (set (rv layout.horizontal_window.show_columns)
             (Im-gui.Checkbox ctx :Columns
                              layout.horizontal_window.show_columns))
        (set (rv layout.horizontal_window.show_tab_bar)
             (Im-gui.Checkbox ctx "Tab bar"
                              layout.horizontal_window.show_tab_bar))
        (set (rv layout.horizontal_window.show_child)
             (Im-gui.Checkbox ctx :Child layout.horizontal_window.show_child))
        (set (rv layout.horizontal_window.explicit_content_size)
             (Im-gui.Checkbox ctx "Explicit content size"
                              layout.horizontal_window.explicit_content_size))
        (Im-gui.Text ctx
                     (: "Scroll %.1f/%.1f %.1f/%.1f" :format
                        (Im-gui.GetScrollX ctx) (Im-gui.GetScrollMaxX ctx)
                        (Im-gui.GetScrollY ctx) (Im-gui.GetScrollMaxY ctx)))
        (when layout.horizontal_window.explicit_content_size
          (Im-gui.SameLine ctx)
          (Im-gui.SetNextItemWidth ctx 100)
          (set (rv layout.horizontal_window.contents_size_x)
               (Im-gui.DragDouble ctx "##csx"
                                  layout.horizontal_window.contents_size_x))
          (local (x y) (Im-gui.GetCursorScreenPos ctx))
          (local draw-list (Im-gui.GetWindowDrawList ctx))
          (Im-gui.DrawList_AddRectFilled draw-list x y (+ x 10) (+ y 10)
                                         4294967295)
          (Im-gui.DrawList_AddRectFilled draw-list
                                         (- (+ x
                                               layout.horizontal_window.contents_size_x)
                                            10)
                                         y
                                         (+ x
                                            layout.horizontal_window.contents_size_x)
                                         (+ y 10) 4294967295)
          (Im-gui.Dummy ctx 0 10))
        (Im-gui.PopStyleVar ctx 2)
        (Im-gui.Separator ctx)
        (when layout.horizontal_window.show_button
          (Im-gui.Button ctx "this is a 300-wide button" 300 0))
        (when layout.horizontal_window.show_tree_nodes
          (when (Im-gui.TreeNode ctx "this is a tree node")
            (when (Im-gui.TreeNode ctx "another one of those tree node...")
              (Im-gui.Text ctx "Some tree contents")
              (Im-gui.TreePop ctx))
            (Im-gui.TreePop ctx))
          (Im-gui.CollapsingHeader ctx :CollapsingHeader true))
        (when layout.horizontal_window.show_text_wrapped
          (Im-gui.TextWrapped ctx
                              "This text should automatically wrap on the edge of the work rectangle."))
        (when layout.horizontal_window.show_columns
          (Im-gui.Text ctx "Tables:")
          (when (Im-gui.BeginTable ctx :table 4 (Im-gui.TableFlags_Borders))
            (for [n 0 3]
              (Im-gui.TableNextColumn ctx)
              (Im-gui.Text ctx
                           (: "Width %.2f" :format
                              (Im-gui.GetContentRegionAvail ctx))))
            (Im-gui.EndTable ctx)))
        (when (and layout.horizontal_window.show_tab_bar
                   (Im-gui.BeginTabBar ctx :Hello))
          (when (Im-gui.BeginTabItem ctx :OneOneOne) (Im-gui.EndTabItem ctx))
          (when (Im-gui.BeginTabItem ctx :TwoTwoTwo) (Im-gui.EndTabItem ctx))
          (when (Im-gui.BeginTabItem ctx :ThreeThreeThree)
            (Im-gui.EndTabItem ctx))
          (when (Im-gui.BeginTabItem ctx :FourFourFour) (Im-gui.EndTabItem ctx))
          (Im-gui.EndTabBar ctx))
        (when layout.horizontal_window.show_child
          (when (Im-gui.BeginChild ctx :child 0 0 true) (Im-gui.EndChild ctx)))
        (Im-gui.End ctx)))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Clipping)
    (when (not layout.clipping)
      (set layout.clipping {:offset [30 30] :size [100 100]}))
    (set-forcibly! (rv s1 s2)
                   (Im-gui.DragDouble2 ctx :size (. layout.clipping.size 1)
                                       (. layout.clipping.size 2) 0.5 1 200
                                       "%.0f"))
    (tset layout.clipping.size 1 s1)
    (tset layout.clipping.size 2 s2)
    (Im-gui.TextWrapped ctx "(Click and drag to scroll)")
    (demo.HelpMarker "(Left) Using ImGui_PushClipRect():
Will alter ImGui hit-testing logic + DrawList rendering.
(use this if you want your clipping rectangle to affect interactions)

(Center) Using ImGui_DrawList_PushClipRect():
Will alter DrawList rendering only.
(use this as a shortcut if you are only using DrawList calls)

(Right) Using ImGui_DrawList_AddText() with a fine ClipRect:
Will alter only this specific ImGui_DrawList_AddText() rendering.
This is often used internally to avoid altering the clipping rectangle and minimize draw calls.")
    (for [n 0 2]
      (when (> n 0) (Im-gui.SameLine ctx))
      (Im-gui.PushID ctx n)
      (Im-gui.InvisibleButton ctx "##canvas"
                              (table.unpack layout.clipping.size))
      (when (and (Im-gui.IsItemActive ctx)
                 (Im-gui.IsMouseDragging ctx (Im-gui.MouseButton_Left)))
        (local mouse-delta [(Im-gui.GetMouseDelta ctx)])
        (tset layout.clipping.offset 1
              (+ (. layout.clipping.offset 1) (. mouse-delta 1)))
        (tset layout.clipping.offset 2
              (+ (. layout.clipping.offset 2) (. mouse-delta 2))))
      (Im-gui.PopID ctx)
      (when (Im-gui.IsItemVisible ctx)
        (local (p0-x p0-y) (Im-gui.GetItemRectMin ctx))
        (local (p1-x p1-y) (Im-gui.GetItemRectMax ctx))
        (local text-str "Line 1 hello\nLine 2 clip me!")
        (local text-pos
               [(+ p0-x (. layout.clipping.offset 1))
                (+ p0-y (. layout.clipping.offset 2))])
        (local draw-list (Im-gui.GetWindowDrawList ctx))
        (if (= n 0) (do
                      (Im-gui.PushClipRect ctx p0-x p0-y p1-x p1-y true)
                      (Im-gui.DrawList_AddRectFilled draw-list p0-x p0-y p1-x
                                                     p1-y 1515878655)
                      (Im-gui.DrawList_AddText draw-list (. text-pos 1)
                                               (. text-pos 2) 4294967295
                                               text-str)
                      (Im-gui.PopClipRect ctx)) (= n 1)
            (do
              (Im-gui.DrawList_PushClipRect draw-list p0-x p0-y p1-x p1-y true)
              (Im-gui.DrawList_AddRectFilled draw-list p0-x p0-y p1-x p1-y
                                             1515878655)
              (Im-gui.DrawList_AddText draw-list (. text-pos 1) (. text-pos 2)
                                       4294967295 text-str)
              (Im-gui.DrawList_PopClipRect draw-list)) (= n 2)
            (let [clip-rect [p0-x p0-y p1-x p1-y]]
              (Im-gui.DrawList_AddRectFilled draw-list p0-x p0-y p1-x p1-y
                                             1515878655)
              (Im-gui.DrawList_AddTextEx draw-list (Im-gui.GetFont ctx)
                                         (Im-gui.GetFontSize ctx) (. text-pos 1)
                                         (. text-pos 2) 4294967295 text-str 0
                                         (table.unpack clip-rect))))))
    (Im-gui.TreePop ctx)))

(fn demo.ShowDemoWindowPopups []
  (when (not (Im-gui.CollapsingHeader ctx "Popups & Modal windows"))
    (lua "return "))
  (var rv nil)
  (when (Im-gui.TreeNode ctx :Popups)
    (when (not popups.popups)
      (set popups.popups
           {:selected_fish (- 1) :toggles [true false false false false]}))
    (Im-gui.TextWrapped ctx
                        "When a popup is active, it inhibits interacting with windows that are behind the popup. Clicking outside the popup closes it.")
    (local names [:Bream :Haddock :Mackerel :Pollock :Tilefish])
    (when (Im-gui.Button ctx :Select..) (Im-gui.OpenPopup ctx :my_select_popup))
    (Im-gui.SameLine ctx)
    (Im-gui.Text ctx (or (. names popups.popups.selected_fish) :<None>))
    (when (Im-gui.BeginPopup ctx :my_select_popup)
      (Im-gui.SeparatorText ctx :Aquarium)
      (each [i fish (ipairs names)]
        (when (Im-gui.Selectable ctx fish) (set popups.popups.selected_fish i)))
      (Im-gui.EndPopup ctx))
    (when (Im-gui.Button ctx :Toggle..) (Im-gui.OpenPopup ctx :my_toggle_popup))
    (when (Im-gui.BeginPopup ctx :my_toggle_popup)
      (each [i fish (ipairs names)]
        (set-forcibly! (rv ti)
                       (Im-gui.MenuItem ctx fish "" (. popups.popups.toggles i)))
        (tset popups.popups.toggles i ti))
      (when (Im-gui.BeginMenu ctx :Sub-menu) (Im-gui.MenuItem ctx "Click me")
        (Im-gui.EndMenu ctx))
      (Im-gui.Separator ctx)
      (Im-gui.Text ctx "Tooltip here")
      (when (Im-gui.IsItemHovered ctx)
        (Im-gui.SetTooltip ctx "I am a tooltip over a popup"))
      (when (Im-gui.Button ctx "Stacked Popup")
        (Im-gui.OpenPopup ctx "another popup"))
      (when (Im-gui.BeginPopup ctx "another popup")
        (each [i fish (ipairs names)]
          (set-forcibly! (rv ti)
                         (Im-gui.MenuItem ctx fish ""
                                          (. popups.popups.toggles i)))
          (tset popups.popups.toggles i ti))
        (when (Im-gui.BeginMenu ctx :Sub-menu) (Im-gui.MenuItem ctx "Click me")
          (when (Im-gui.Button ctx "Stacked Popup")
            (Im-gui.OpenPopup ctx "another popup"))
          (when (Im-gui.BeginPopup ctx "another popup")
            (Im-gui.Text ctx "I am the last one here.")
            (Im-gui.EndPopup ctx))
          (Im-gui.EndMenu ctx))
        (Im-gui.EndPopup ctx))
      (Im-gui.EndPopup ctx))
    (when (Im-gui.Button ctx "With a menu..")
      (Im-gui.OpenPopup ctx :my_file_popup))
    (when (Im-gui.BeginPopup ctx :my_file_popup (Im-gui.WindowFlags_MenuBar))
      (when (Im-gui.BeginMenuBar ctx)
        (when (Im-gui.BeginMenu ctx :File) (demo.ShowExampleMenuFile)
          (Im-gui.EndMenu ctx))
        (when (Im-gui.BeginMenu ctx :Edit) (Im-gui.MenuItem ctx :Dummy)
          (Im-gui.EndMenu ctx))
        (Im-gui.EndMenuBar ctx))
      (Im-gui.Text ctx "Hello from popup!")
      (Im-gui.Button ctx "This is a dummy button..")
      (Im-gui.EndPopup ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Context menus")
    (when (not popups.context)
      (set popups.context {:name :Label1 :selected 0 :value 0.5}))
    (demo.HelpMarker "\"Context\" functions are simple helpers to associate a Popup to a given Item or Window identifier.")
    (let [names [:Label1 :Label2 :Label3 :Label4 :Label5]]
      (each [n name (ipairs names)]
        (when (Im-gui.Selectable ctx name (= popups.context.selected n))
          (set popups.context.selected n))
        (when (Im-gui.BeginPopupContextItem ctx)
          (set popups.context.selected n)
          (Im-gui.Text ctx (: "This a popup for \"%s\"!" :format name))
          (when (Im-gui.Button ctx :Close) (Im-gui.CloseCurrentPopup ctx))
          (Im-gui.EndPopup ctx))
        (when (Im-gui.IsItemHovered ctx)
          (Im-gui.SetTooltip ctx "Right-click to open popup"))))
    (do
      (demo.HelpMarker "Text() elements don't have stable identifiers so we need to provide one.")
      (Im-gui.Text ctx (: "Value = %.6f <-- (1) right-click this text" :format
                          popups.context.value))
      (when (Im-gui.BeginPopupContextItem ctx "my popup")
        (when (Im-gui.Selectable ctx "Set to zero")
          (set popups.context.value 0))
        (when (Im-gui.Selectable ctx "Set to PI")
          (set popups.context.value 3.141592))
        (Im-gui.SetNextItemWidth ctx (- FLT_MIN))
        (set (rv popups.context.value)
             (Im-gui.DragDouble ctx "##Value" popups.context.value 0.1 0 0))
        (Im-gui.EndPopup ctx))
      (Im-gui.Text ctx "(2) Or right-click this text")
      (Im-gui.OpenPopupOnItemClick ctx "my popup"
                                   (Im-gui.PopupFlags_MouseButtonRight))
      (when (Im-gui.Button ctx "(3) Or click this button")
        (Im-gui.OpenPopup ctx "my popup")))
    (do
      (demo.HelpMarker "Showcase using a popup ID linked to item ID, with the item having a changing label + stable ID using the ### operator.")
      (Im-gui.Button ctx (: "Button: %s###Button" :format popups.context.name))
      (when (Im-gui.BeginPopupContextItem ctx) (Im-gui.Text ctx "Edit name:")
        (set (rv popups.context.name)
             (Im-gui.InputText ctx "##edit" popups.context.name))
        (when (Im-gui.Button ctx :Close) (Im-gui.CloseCurrentPopup ctx))
        (Im-gui.EndPopup ctx))
      (Im-gui.SameLine ctx)
      (Im-gui.Text ctx "(<-- right-click here)"))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx :Modals)
    (when (not popups.modal)
      (set popups.modal {:color 1723007104
                         :dont_ask_me_next_time false
                         :item 1}))
    (Im-gui.TextWrapped ctx
                        "Modal windows are like popups but the user cannot close them by clicking outside.")
    (when (Im-gui.Button ctx :Delete..) (Im-gui.OpenPopup ctx :Delete?))
    (local center [(Im-gui.Viewport_GetCenter (Im-gui.GetWindowViewport ctx))])
    (Im-gui.SetNextWindowPos ctx (. center 1) (. center 2)
                             (Im-gui.Cond_Appearing) 0.5 0.5)
    (when (Im-gui.BeginPopupModal ctx :Delete? nil
                                  (Im-gui.WindowFlags_AlwaysAutoResize))
      (Im-gui.Text ctx "All those beautiful files will be deleted.
This operation cannot be undone!")
      (Im-gui.Separator ctx)
      (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) 0 0)
      (set (rv popups.modal.dont_ask_me_next_time)
           (Im-gui.Checkbox ctx "Don't ask me next time"
                            popups.modal.dont_ask_me_next_time))
      (Im-gui.PopStyleVar ctx)
      (when (Im-gui.Button ctx :OK 120 0) (Im-gui.CloseCurrentPopup ctx))
      (Im-gui.SetItemDefaultFocus ctx)
      (Im-gui.SameLine ctx)
      (when (Im-gui.Button ctx :Cancel 120 0) (Im-gui.CloseCurrentPopup ctx))
      (Im-gui.EndPopup ctx))
    (when (Im-gui.Button ctx "Stacked modals..")
      (Im-gui.OpenPopup ctx "Stacked 1"))
    (when (Im-gui.BeginPopupModal ctx "Stacked 1" nil
                                  (Im-gui.WindowFlags_MenuBar))
      (when (Im-gui.BeginMenuBar ctx)
        (when (Im-gui.BeginMenu ctx :File)
          (when (Im-gui.MenuItem ctx "Some menu item") nil)
          (Im-gui.EndMenu ctx))
        (Im-gui.EndMenuBar ctx))
      (Im-gui.Text ctx
                   "Hello from Stacked The First
Using style.Colors[ImGuiCol_ModalWindowDimBg] behind it.")
      (set (rv popups.modal.item)
           (Im-gui.Combo ctx :Combo popups.modal.item
                         "aaaa\000bbbb\000cccc\000dddd\000eeee\000"))
      (set (rv popups.modal.color)
           (Im-gui.ColorEdit4 ctx :color popups.modal.color))
      (when (Im-gui.Button ctx "Add another modal..")
        (Im-gui.OpenPopup ctx "Stacked 2"))
      (local unused-open true)
      (when (Im-gui.BeginPopupModal ctx "Stacked 2" unused-open)
        (Im-gui.Text ctx "Hello from Stacked The Second!")
        (when (Im-gui.Button ctx :Close) (Im-gui.CloseCurrentPopup ctx))
        (Im-gui.EndPopup ctx))
      (when (Im-gui.Button ctx :Close) (Im-gui.CloseCurrentPopup ctx))
      (Im-gui.EndPopup ctx))
    (Im-gui.TreePop ctx))
  (when (Im-gui.TreeNode ctx "Menus inside a regular window")
    (Im-gui.TextWrapped ctx
                        "Below we are testing adding menu items to a regular window. It's rather unusual but should work!")
    (Im-gui.Separator ctx)
    (Im-gui.MenuItem ctx "Menu item" :CTRL+M)
    (when (Im-gui.BeginMenu ctx "Menu inside a regular window")
      (demo.ShowExampleMenuFile)
      (Im-gui.EndMenu ctx))
    (Im-gui.Separator ctx)
    (Im-gui.TreePop ctx)))

(local My-item-column-iD_ID 4)

(local My-item-column-iD_Name 5)

(local My-item-column-iD_Quantity 6)

(local My-item-column-iD_Description 7)

(fn demo.CompareTableItems [a b]
  (for [next-id 0 math.huge]
    (local (ok col-user-id col-idx sort-order sort-direction)
           (Im-gui.TableGetColumnSortSpecs ctx next-id))
    (when (not ok) (lua :break))
    (var key nil)
    (if (= col-user-id My-item-column-iD_ID) (set key :id)
        (= col-user-id My-item-column-iD_Name) (set key :name)
        (= col-user-id My-item-column-iD_Quantity) (set key :quantity)
        (= col-user-id My-item-column-iD_Description) (set key :name)
        (error "unknown user column ID"))
    (local is-ascending (= sort-direction (Im-gui.SortDirection_Ascending)))
    (if (< (. a key) (. b key))
        (let [___antifnl_rtn_1___ is-ascending]
          (lua "return ___antifnl_rtn_1___")) (> (. a key) (. b key))
        (let [___antifnl_rtn_1___ (not is-ascending)]
          (lua "return ___antifnl_rtn_1___"))))
  (< a.id b.id))

(fn demo.PushStyleCompact []
  (let [(frame-padding-x frame-padding-y) (Im-gui.GetStyleVar ctx
                                                              (Im-gui.StyleVar_FramePadding))
        (item-spacing-x item-spacing-y) (Im-gui.GetStyleVar ctx
                                                            (Im-gui.StyleVar_ItemSpacing))]
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) frame-padding-x
                         (math.floor (* frame-padding-y 0.6)))
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_ItemSpacing) item-spacing-x
                         (math.floor (* item-spacing-y 0.6)))))

(fn demo.PopStyleCompact [] (Im-gui.PopStyleVar ctx 2))

(fn demo.EditTableSizingFlags [flags]
  (let [policies [{:name :Default
                   :tooltip "Use default sizing policy:
- ImGuiTableFlags_SizingFixedFit if ScrollX is on or if host window has ImGuiWindowFlags_AlwaysAutoResize.
- ImGuiTableFlags_SizingStretchSame otherwise."
                   :value (Im-gui.TableFlags_None)}
                  {:name :ImGuiTableFlags_SizingFixedFit
                   :tooltip "Columns default to _WidthFixed (if resizable) or _WidthAuto (if not resizable), matching contents width."
                   :value (Im-gui.TableFlags_SizingFixedFit)}
                  {:name :ImGuiTableFlags_SizingFixedSame
                   :tooltip "Columns are all the same width, matching the maximum contents width.
Implicitly disable ImGuiTableFlags_Resizable and enable ImGuiTableFlags_NoKeepColumnsVisible."
                   :value (Im-gui.TableFlags_SizingFixedSame)}
                  {:name :ImGuiTableFlags_SizingStretchProp
                   :tooltip "Columns default to _WidthStretch with weights proportional to their widths."
                   :value (Im-gui.TableFlags_SizingStretchProp)}
                  {:name :ImGuiTableFlags_SizingStretchSame
                   :tooltip "Columns default to _WidthStretch with same weights."
                   :value (Im-gui.TableFlags_SizingStretchSame)}]
        sizing-mask (bor (Im-gui.TableFlags_SizingFixedFit)
                         (Im-gui.TableFlags_SizingFixedSame)
                         (Im-gui.TableFlags_SizingStretchProp)
                         (Im-gui.TableFlags_SizingStretchSame))]
    (var idx 1)
    (while (< idx (length policies))
      (when (= (. (. policies idx) :value) (band flags sizing-mask))
        (lua :break))
      (set idx (+ idx 1)))
    (var preview-text "")
    (when (<= idx (length policies))
      (set preview-text (. (. policies idx) :name))
      (when (> idx 1)
        (set preview-text (preview-text:sub (+ (: :ImGuiTableFlags :len) 1)))))
    (when (Im-gui.BeginCombo ctx "Sizing Policy" preview-text)
      (each [n policy (ipairs policies)]
        (when (Im-gui.Selectable ctx policy.name (= idx n))
          (set-forcibly! flags
                         (bor (band flags (bnot sizing-mask)) policy.value))))
      (Im-gui.EndCombo ctx))
    (Im-gui.SameLine ctx)
    (Im-gui.TextDisabled ctx "(?)")
    (when (Im-gui.IsItemHovered ctx)
      (Im-gui.BeginTooltip ctx)
      (Im-gui.PushTextWrapPos ctx (* (Im-gui.GetFontSize ctx) 50))
      (each [m policy (ipairs policies)]
        (Im-gui.Separator ctx)
        (Im-gui.Text ctx (: "%s:" :format policy.name))
        (Im-gui.Separator ctx)
        (local indent-spacing
               (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_IndentSpacing)))
        (Im-gui.SetCursorPosX ctx
                              (+ (Im-gui.GetCursorPosX ctx)
                                 (* indent-spacing 0.5)))
        (Im-gui.Text ctx policy.tooltip))
      (Im-gui.PopTextWrapPos ctx)
      (Im-gui.EndTooltip ctx))
    flags))

(fn demo.EditTableColumnsFlags [flags]
  (let [rv nil
        width-mask (bor (Im-gui.TableColumnFlags_WidthStretch)
                        (Im-gui.TableColumnFlags_WidthFixed))]
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_Disabled flags
                                         (Im-gui.TableColumnFlags_Disabled)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Master disable flag (also hide from context menu)")
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_DefaultHide flags
                                         (Im-gui.TableColumnFlags_DefaultHide)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_DefaultSort flags
                                         (Im-gui.TableColumnFlags_DefaultSort)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_WidthStretch flags
                                         (Im-gui.TableColumnFlags_WidthStretch)))
    (when rv
      (set-forcibly! flags
                     (band flags
                           (bnot (^ width-mask
                                    (Im-gui.TableColumnFlags_WidthStretch))))))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_WidthFixed flags
                                         (Im-gui.TableColumnFlags_WidthFixed)))
    (when rv
      (set-forcibly! flags
                     (band flags
                           (bnot (^ width-mask
                                    (Im-gui.TableColumnFlags_WidthFixed))))))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoResize flags
                                         (Im-gui.TableColumnFlags_NoResize)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoReorder flags
                                         (Im-gui.TableColumnFlags_NoReorder)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoHide flags
                                         (Im-gui.TableColumnFlags_NoHide)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoClip flags
                                         (Im-gui.TableColumnFlags_NoClip)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoSort flags
                                         (Im-gui.TableColumnFlags_NoSort)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoSortAscending flags
                                         (Im-gui.TableColumnFlags_NoSortAscending)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoSortDescending flags
                                         (Im-gui.TableColumnFlags_NoSortDescending)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoHeaderLabel flags
                                         (Im-gui.TableColumnFlags_NoHeaderLabel)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_NoHeaderWidth flags
                                         (Im-gui.TableColumnFlags_NoHeaderWidth)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_PreferSortAscending flags
                                         (Im-gui.TableColumnFlags_PreferSortAscending)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_PreferSortDescending flags
                                         (Im-gui.TableColumnFlags_PreferSortDescending)))
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_IndentEnable flags
                                         (Im-gui.TableColumnFlags_IndentEnable)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Default for column 0")
    (set-forcibly! (rv flags)
                   (Im-gui.CheckboxFlags ctx :_IndentDisable flags
                                         (Im-gui.TableColumnFlags_IndentDisable)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Default for column >0")
    flags))

(fn demo.ShowTableColumnsStatusFlags [flags]
  (Im-gui.CheckboxFlags ctx :_IsEnabled flags
                        (Im-gui.TableColumnFlags_IsEnabled))
  (Im-gui.CheckboxFlags ctx :_IsVisible flags
                        (Im-gui.TableColumnFlags_IsVisible))
  (Im-gui.CheckboxFlags ctx :_IsSorted flags (Im-gui.TableColumnFlags_IsSorted))
  (Im-gui.CheckboxFlags ctx :_IsHovered flags
                        (Im-gui.TableColumnFlags_IsHovered)))

(fn demo.ShowDemoWindowTables []
  (when (not (Im-gui.CollapsingHeader ctx :Tables)) (lua "return "))
  (var rv nil)
  (local TEXT_BASE_WIDTH (Im-gui.CalcTextSize ctx :A))
  (local TEXT_BASE_HEIGHT (Im-gui.GetTextLineHeightWithSpacing ctx))
  (Im-gui.PushID ctx :Tables)
  (var open-action (- 1))
  (when (Im-gui.Button ctx "Open all") (set open-action 1))
  (Im-gui.SameLine ctx)
  (when (Im-gui.Button ctx "Close all") (set open-action 0))
  (Im-gui.SameLine ctx)
  (when (= tables.disable_indent nil) (set tables.disable_indent false))
  (set (rv tables.disable_indent)
       (Im-gui.Checkbox ctx "Disable tree indentation" tables.disable_indent))
  (Im-gui.SameLine ctx)
  (demo.HelpMarker "Disable the indenting of tree nodes so demo tables can use the full window width.")
  (Im-gui.Separator ctx)
  (when tables.disable_indent
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_IndentSpacing) 0))

  (fn Do-open-action []
    (when (not= open-action (- 1))
      (Im-gui.SetNextItemOpen ctx (not= open-action 0))))

  (Do-open-action)
  (when (Im-gui.TreeNode ctx :Basic)
    (demo.HelpMarker "Using TableNextRow() + calling TableSetColumnIndex() _before_ each cell, in a loop.")
    (when (Im-gui.BeginTable ctx :table1 3)
      (for [row 0 3]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Row %d Column %d" :format row column))))
      (Im-gui.EndTable ctx))
    (demo.HelpMarker "Using TableNextRow() + calling TableNextColumn() _before_ each cell, manually.")
    (when (Im-gui.BeginTable ctx :table2 3)
      (for [row 0 3] (Im-gui.TableNextRow ctx) (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx (: "Row %d" :format row))
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx "Some contents")
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx :123.456))
      (Im-gui.EndTable ctx))
    (demo.HelpMarker "Only using TableNextColumn(), which tends to be convenient for tables where every cell contains the same type of contents.
This is also more similar to the old NextColumn() function of the Columns API, and provided to facilitate the Columns->Tables API transition.")
    (when (Im-gui.BeginTable ctx :table3 3)
      (for [item 0 13] (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx (: "Item %d" :format item)))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Borders, background")
    (when (not tables.borders_bg)
      (set tables.borders_bg
           {:contents_type 0
            :display_headers false
            :flags (bor (Im-gui.TableFlags_Borders) (Im-gui.TableFlags_RowBg))}))
    (demo.PushStyleCompact)
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_RowBg
                               tables.borders_bg.flags (Im-gui.TableFlags_RowBg)))
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Borders
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_Borders)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "ImGuiTableFlags_Borders
 = ImGuiTableFlags_BordersInnerV
 | ImGuiTableFlags_BordersOuterV
 | ImGuiTableFlags_BordersInnerV
 | ImGuiTableFlags_BordersOuterH")
    (Im-gui.Indent ctx)
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersH
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersH)))
    (Im-gui.Indent ctx)
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterH
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersOuterH)))
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerH
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersInnerH)))
    (Im-gui.Unindent ctx)
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersV)))
    (Im-gui.Indent ctx)
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersOuterV)))
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersInnerV)))
    (Im-gui.Unindent ctx)
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuter
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersOuter)))
    (set (rv tables.borders_bg.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInner
                               tables.borders_bg.flags
                               (Im-gui.TableFlags_BordersInner)))
    (Im-gui.Unindent ctx)
    (Im-gui.AlignTextToFramePadding ctx)
    (Im-gui.Text ctx "Cell contents:")
    (Im-gui.SameLine ctx)
    (set (rv tables.borders_bg.contents_type)
         (Im-gui.RadioButtonEx ctx :Text tables.borders_bg.contents_type 0))
    (Im-gui.SameLine ctx)
    (set (rv tables.borders_bg.contents_type)
         (Im-gui.RadioButtonEx ctx :FillButton tables.borders_bg.contents_type
                               1))
    (set (rv tables.borders_bg.display_headers)
         (Im-gui.Checkbox ctx "Display headers"
                          tables.borders_bg.display_headers))
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table1 3 tables.borders_bg.flags)
      (when tables.borders_bg.display_headers
        (Im-gui.TableSetupColumn ctx :One)
        (Im-gui.TableSetupColumn ctx :Two)
        (Im-gui.TableSetupColumn ctx :Three)
        (Im-gui.TableHeadersRow ctx))
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2]
          (Im-gui.TableSetColumnIndex ctx column)
          (local buf (: "Hello %d,%d" :format column row))
          (if (= tables.borders_bg.contents_type 0) (Im-gui.Text ctx buf)
              (= tables.borders_bg.contents_type 1) (Im-gui.Button ctx buf
                                                                   (- FLT_MIN) 0))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Resizable, stretch")
    (when (not tables.resz_stretch)
      (set tables.resz_stretch
           {:flags (bor (Im-gui.TableFlags_SizingStretchSame)
                        (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_BordersOuter)
                        (Im-gui.TableFlags_BordersV)
                        (Im-gui.TableFlags_ContextMenuInBody))}))
    (demo.PushStyleCompact)
    (set (rv tables.resz_stretch.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.resz_stretch.flags
                               (Im-gui.TableFlags_Resizable)))
    (set (rv tables.resz_stretch.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                               tables.resz_stretch.flags
                               (Im-gui.TableFlags_BordersV)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Using the _Resizable flag automatically enables the _BordersInnerV flag as well, this is why the resize borders are still showing when unchecking this.")
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table1 3 tables.resz_stretch.flags)
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Hello %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Resizable, fixed")
    (when (not tables.resz_fixed)
      (set tables.resz_fixed
           {:flags (bor (Im-gui.TableFlags_SizingFixedFit)
                        (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_BordersOuter)
                        (Im-gui.TableFlags_BordersV)
                        (Im-gui.TableFlags_ContextMenuInBody))}))
    (demo.HelpMarker "Using _Resizable + _SizingFixedFit flags.
Fixed-width columns generally makes more sense if you want to use horizontal scrolling.

Double-click a column border to auto-fit the column to its contents.")
    (demo.PushStyleCompact)
    (set (rv tables.resz_fixed.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                               tables.resz_fixed.flags
                               (Im-gui.TableFlags_NoHostExtendX)))
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table1 3 tables.resz_fixed.flags)
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Hello %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Resizable, mixed")
    (when (not tables.resz_mixed)
      (set tables.resz_mixed
           {:flags (bor (Im-gui.TableFlags_SizingFixedFit)
                        (Im-gui.TableFlags_RowBg) (Im-gui.TableFlags_Borders)
                        (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_Reorderable)
                        (Im-gui.TableFlags_Hideable))}))
    (demo.HelpMarker "Using TableSetupColumn() to alter resizing policy on a per-column basis.

When combining Fixed and Stretch columns, generally you only want one, maybe two trailing columns to use _WidthStretch.")
    (when (Im-gui.BeginTable ctx :table1 3 tables.resz_mixed.flags)
      (Im-gui.TableSetupColumn ctx :AAA (Im-gui.TableColumnFlags_WidthFixed))
      (Im-gui.TableSetupColumn ctx :BBB (Im-gui.TableColumnFlags_WidthFixed))
      (Im-gui.TableSetupColumn ctx :CCC (Im-gui.TableColumnFlags_WidthStretch))
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2]
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx
                       (: "%s %d,%d" :format
                          (or (and (= column 2) :Stretch) :Fixed) column row))))
      (Im-gui.EndTable ctx))
    (when (Im-gui.BeginTable ctx :table2 6 tables.resz_mixed.flags)
      (Im-gui.TableSetupColumn ctx :AAA (Im-gui.TableColumnFlags_WidthFixed))
      (Im-gui.TableSetupColumn ctx :BBB (Im-gui.TableColumnFlags_WidthFixed))
      (Im-gui.TableSetupColumn ctx :CCC
                               (bor (Im-gui.TableColumnFlags_WidthFixed)
                                    (Im-gui.TableColumnFlags_DefaultHide)))
      (Im-gui.TableSetupColumn ctx :DDD (Im-gui.TableColumnFlags_WidthStretch))
      (Im-gui.TableSetupColumn ctx :EEE (Im-gui.TableColumnFlags_WidthStretch))
      (Im-gui.TableSetupColumn ctx :FFF
                               (bor (Im-gui.TableColumnFlags_WidthStretch)
                                    (Im-gui.TableColumnFlags_DefaultHide)))
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 5]
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "%s %d,%d" :format
                              (or (and (>= column 3) :Stretch) :Fixed) column
                              row))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Reorderable, hideable, with headers")
    (when (not tables.reorder)
      (set tables.reorder
           {:flags (bor (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_Reorderable)
                        (Im-gui.TableFlags_Hideable)
                        (Im-gui.TableFlags_BordersOuter)
                        (Im-gui.TableFlags_BordersV))}))
    (demo.HelpMarker "Click and drag column headers to reorder columns.

Right-click on a header to open a context menu.")
    (demo.PushStyleCompact)
    (set (rv tables.reorder.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.reorder.flags
                               (Im-gui.TableFlags_Resizable)))
    (set (rv tables.reorder.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Reorderable
                               tables.reorder.flags
                               (Im-gui.TableFlags_Reorderable)))
    (set (rv tables.reorder.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Hideable
                               tables.reorder.flags (Im-gui.TableFlags_Hideable)))
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table1 3 tables.reorder.flags)
      (Im-gui.TableSetupColumn ctx :One)
      (Im-gui.TableSetupColumn ctx :Two)
      (Im-gui.TableSetupColumn ctx :Three)
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 5]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Hello %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (when (Im-gui.BeginTable ctx :table2 3
                             (bor tables.reorder.flags
                                  (Im-gui.TableFlags_SizingFixedFit))
                             0 0)
      (Im-gui.TableSetupColumn ctx :One)
      (Im-gui.TableSetupColumn ctx :Two)
      (Im-gui.TableSetupColumn ctx :Three)
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 5]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Fixed %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx :Padding)
    (when (not tables.padding)
      (set tables.padding {:cell_padding [0 0]
                           :flags1 (Im-gui.TableFlags_BordersV)
                           :flags2 (bor (Im-gui.TableFlags_Borders)
                                        (Im-gui.TableFlags_RowBg))
                           :show_headers false
                           :show_widget_frame_bg true
                           :text_bufs {}})
      (for [i 1 (* 3 5)] (tset tables.padding.text_bufs i "edit me")))
    (demo.HelpMarker "We often want outer padding activated when any using features which makes the edges of a column visible:
e.g.:
- BorderOuterV
- any form of row selection
Because of this, activating BorderOuterV sets the default to PadOuterX. Using PadOuterX or NoPadOuterX you can override the default.

Actual padding values are using style.CellPadding.

In this demo we don't show horizontal borders to emphasize how they don't affect default horizontal padding.")
    (demo.PushStyleCompact)
    (set (rv tables.padding.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_PadOuterX
                               tables.padding.flags1
                               (Im-gui.TableFlags_PadOuterX)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Enable outer-most padding (default if ImGuiTableFlags_BordersOuterV is set)")
    (set (rv tables.padding.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoPadOuterX
                               tables.padding.flags1
                               (Im-gui.TableFlags_NoPadOuterX)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Disable outer-most padding (default if ImGuiTableFlags_BordersOuterV is not set)")
    (set (rv tables.padding.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoPadInnerX
                               tables.padding.flags1
                               (Im-gui.TableFlags_NoPadInnerX)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off)")
    (set (rv tables.padding.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                               tables.padding.flags1
                               (Im-gui.TableFlags_BordersOuterV)))
    (set (rv tables.padding.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                               tables.padding.flags1
                               (Im-gui.TableFlags_BordersInnerV)))
    (set (rv tables.padding.show_headers)
         (Im-gui.Checkbox ctx :show_headers tables.padding.show_headers))
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table_padding 3 tables.padding.flags1)
      (when tables.padding.show_headers (Im-gui.TableSetupColumn ctx :One)
        (Im-gui.TableSetupColumn ctx :Two)
        (Im-gui.TableSetupColumn ctx :Three)
        (Im-gui.TableHeadersRow ctx))
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2]
          (Im-gui.TableSetColumnIndex ctx column)
          (if (= row 0)
              (Im-gui.Text ctx
                           (: "Avail %.2f" :format
                              (Im-gui.GetContentRegionAvail ctx)))
              (let [buf (: "Hello %d,%d" :format column row)]
                (Im-gui.Button ctx buf (- FLT_MIN) 0)))))
      (Im-gui.EndTable ctx))
    (demo.HelpMarker "Setting style.CellPadding to (0,0) or a custom value.")
    (demo.PushStyleCompact)
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Borders
                               tables.padding.flags2 (Im-gui.TableFlags_Borders)))
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersH
                               tables.padding.flags2
                               (Im-gui.TableFlags_BordersH)))
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                               tables.padding.flags2
                               (Im-gui.TableFlags_BordersV)))
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInner
                               tables.padding.flags2
                               (Im-gui.TableFlags_BordersInner)))
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuter
                               tables.padding.flags2
                               (Im-gui.TableFlags_BordersOuter)))
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_RowBg tables.padding.flags2
                               (Im-gui.TableFlags_RowBg)))
    (set (rv tables.padding.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.padding.flags2
                               (Im-gui.TableFlags_Resizable)))
    (set (rv tables.padding.show_widget_frame_bg)
         (Im-gui.Checkbox ctx :show_widget_frame_bg
                          tables.padding.show_widget_frame_bg))
    (set-forcibly! (rv cp1 cp2)
                   (Im-gui.SliderDouble2 ctx :CellPadding
                                         (. tables.padding.cell_padding 1)
                                         (. tables.padding.cell_padding 2) 0 10
                                         "%.0f"))
    (tset tables.padding.cell_padding 1 cp1)
    (tset tables.padding.cell_padding 2 cp2)
    (demo.PopStyleCompact)
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_CellPadding)
                         (table.unpack tables.padding.cell_padding))
    (when (Im-gui.BeginTable ctx :table_padding_2 3 tables.padding.flags2)
      (when (not tables.padding.show_widget_frame_bg)
        (Im-gui.PushStyleColor ctx (Im-gui.Col_FrameBg) 0))
      (for [cell 1 (* 3 5)]
        (Im-gui.TableNextColumn ctx)
        (Im-gui.SetNextItemWidth ctx (- FLT_MIN))
        (Im-gui.PushID ctx cell)
        (set-forcibly! (rv tbc)
                       (Im-gui.InputText ctx "##cell"
                                         (. tables.padding.text_bufs cell)))
        (tset tables.padding.text_bufs cell tbc)
        (Im-gui.PopID ctx))
      (when (not tables.padding.show_widget_frame_bg)
        (Im-gui.PopStyleColor ctx))
      (Im-gui.EndTable ctx))
    (Im-gui.PopStyleVar ctx)
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Sizing policies")
    (when (not tables.sz_policies)
      (set tables.sz_policies {:column_count 3
                               :contents_type 0
                               :flags1 (bor (Im-gui.TableFlags_BordersV)
                                            (Im-gui.TableFlags_BordersOuterH)
                                            (Im-gui.TableFlags_RowBg)
                                            (Im-gui.TableFlags_ContextMenuInBody))
                               :flags2 (bor (Im-gui.TableFlags_ScrollY)
                                            (Im-gui.TableFlags_Borders)
                                            (Im-gui.TableFlags_RowBg)
                                            (Im-gui.TableFlags_Resizable))
                               :sizing_policy_flags [(Im-gui.TableFlags_SizingFixedFit)
                                                     (Im-gui.TableFlags_SizingFixedSame)
                                                     (Im-gui.TableFlags_SizingStretchProp)
                                                     (Im-gui.TableFlags_SizingStretchSame)]
                               :text_buf ""}))
    (demo.PushStyleCompact)
    (set (rv tables.sz_policies.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.sz_policies.flags1
                               (Im-gui.TableFlags_Resizable)))
    (set (rv tables.sz_policies.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                               tables.sz_policies.flags1
                               (Im-gui.TableFlags_NoHostExtendX)))
    (demo.PopStyleCompact)
    (each [table-n sizing-flags (ipairs tables.sz_policies.sizing_policy_flags)]
      (Im-gui.PushID ctx table-n)
      (Im-gui.SetNextItemWidth ctx (* TEXT_BASE_WIDTH 30))
      (set-forcibly! sizing-flags (demo.EditTableSizingFlags sizing-flags))
      (tset tables.sz_policies.sizing_policy_flags table-n sizing-flags)
      (when (Im-gui.BeginTable ctx :table1 3
                               (bor sizing-flags tables.sz_policies.flags1))
        (for [row 0 2] (Im-gui.TableNextRow ctx) (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx "Oh dear")
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx "Oh dear")
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx "Oh dear"))
        (Im-gui.EndTable ctx))
      (when (Im-gui.BeginTable ctx :table2 3
                               (bor sizing-flags tables.sz_policies.flags1))
        (for [row 0 2] (Im-gui.TableNextRow ctx) (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx :AAAA)
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx :BBBBBBBB)
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx :CCCCCCCCCCCC))
        (Im-gui.EndTable ctx))
      (Im-gui.PopID ctx))
    (Im-gui.Spacing ctx)
    (Im-gui.Text ctx :Advanced)
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "This section allows you to interact and see the effect of various sizing policies depending on whether Scroll is enabled and the contents of your columns.")
    (demo.PushStyleCompact)
    (Im-gui.PushID ctx :Advanced)
    (Im-gui.PushItemWidth ctx (* TEXT_BASE_WIDTH 30))
    (set tables.sz_policies.flags2
         (demo.EditTableSizingFlags tables.sz_policies.flags2))
    (set (rv tables.sz_policies.contents_type)
         (Im-gui.Combo ctx :Contents tables.sz_policies.contents_type
                       "Show width\000Short Text\000Long Text\000Button\000Fill Button\000InputText\000"))
    (when (= tables.sz_policies.contents_type 4) (Im-gui.SameLine ctx)
      (demo.HelpMarker "Be mindful that using right-alignment (e.g. size.x = -FLT_MIN) creates a feedback loop where contents width can feed into auto-column width can feed into contents width."))
    (set (rv tables.sz_policies.column_count)
         (Im-gui.DragInt ctx :Columns tables.sz_policies.column_count 0.1 1 64
                         "%d" (Im-gui.SliderFlags_AlwaysClamp)))
    (set (rv tables.sz_policies.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.sz_policies.flags2
                               (Im-gui.TableFlags_Resizable)))
    (set (rv tables.sz_policies.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_PreciseWidths
                               tables.sz_policies.flags2
                               (Im-gui.TableFlags_PreciseWidths)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
    (set (rv tables.sz_policies.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                               tables.sz_policies.flags2
                               (Im-gui.TableFlags_ScrollX)))
    (set (rv tables.sz_policies.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                               tables.sz_policies.flags2
                               (Im-gui.TableFlags_ScrollY)))
    (set (rv tables.sz_policies.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoClip
                               tables.sz_policies.flags2
                               (Im-gui.TableFlags_NoClip)))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.PopID ctx)
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table2 tables.sz_policies.column_count
                             tables.sz_policies.flags2 0 (* TEXT_BASE_HEIGHT 7))
      (for [cell 1 (* 10 tables.sz_policies.column_count)]
        (Im-gui.TableNextColumn ctx)
        (local column (Im-gui.TableGetColumnIndex ctx))
        (local row (Im-gui.TableGetRowIndex ctx))
        (Im-gui.PushID ctx cell)
        (local label (: "Hello %d,%d" :format column row))
        (local contents-type tables.sz_policies.contents_type)
        (if (= contents-type 1) (Im-gui.Text ctx label) (= contents-type 2)
            (Im-gui.Text ctx (: "Some %s text %d,%d\nOver two lines.." :format
                                (or (and (= column 0) :long) :longeeer) column
                                row)) (= contents-type 0)
            (Im-gui.Text ctx
                         (: "W: %.1f" :format
                            (Im-gui.GetContentRegionAvail ctx)))
            (= contents-type 3) (Im-gui.Button ctx label) (= contents-type 4)
            (Im-gui.Button ctx label (- FLT_MIN) 0) (= contents-type 5)
            (do
              (Im-gui.SetNextItemWidth ctx (- FLT_MIN))
              (set (rv tables.sz_policies.text_buf)
                   (Im-gui.InputText ctx "##" tables.sz_policies.text_buf))))
        (Im-gui.PopID ctx))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Vertical scrolling, with clipping")
    (when (not tables.vertical)
      (set tables.vertical
           {:flags (bor (Im-gui.TableFlags_ScrollY) (Im-gui.TableFlags_RowBg)
                        (Im-gui.TableFlags_BordersOuter)
                        (Im-gui.TableFlags_BordersV)
                        (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_Reorderable)
                        (Im-gui.TableFlags_Hideable))}))
    (demo.HelpMarker "Here we activate ScrollY, which will create a child window container to allow hosting scrollable contents.

We also demonstrate using ImGuiListClipper to virtualize the submission of many items.")
    (demo.PushStyleCompact)
    (set (rv tables.vertical.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                               tables.vertical.flags (Im-gui.TableFlags_ScrollY)))
    (demo.PopStyleCompact)
    (local outer-size [0 (* TEXT_BASE_HEIGHT 8)])
    (when (Im-gui.BeginTable ctx :table_scrolly 3 tables.vertical.flags
                             (table.unpack outer-size))
      (Im-gui.TableSetupScrollFreeze ctx 0 1)
      (Im-gui.TableSetupColumn ctx :One (Im-gui.TableColumnFlags_None))
      (Im-gui.TableSetupColumn ctx :Two (Im-gui.TableColumnFlags_None))
      (Im-gui.TableSetupColumn ctx :Three (Im-gui.TableColumnFlags_None))
      (Im-gui.TableHeadersRow ctx)
      (local clipper (Im-gui.CreateListClipper ctx))
      (Im-gui.ListClipper_Begin clipper 1000)
      (while (Im-gui.ListClipper_Step clipper)
        (local (display-start display-end)
               (Im-gui.ListClipper_GetDisplayRange clipper))
        (for [row display-start (- display-end 1)]
          (Im-gui.TableNextRow ctx)
          (for [column 0 2] (Im-gui.TableSetColumnIndex ctx column)
            (Im-gui.Text ctx (: "Hello %d,%d" :format column row)))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Horizontal scrolling")
    (when (not tables.horizontal)
      (set tables.horizontal {:flags1 (bor (Im-gui.TableFlags_ScrollX)
                                           (Im-gui.TableFlags_ScrollY)
                                           (Im-gui.TableFlags_RowBg)
                                           (Im-gui.TableFlags_BordersOuter)
                                           (Im-gui.TableFlags_BordersV)
                                           (Im-gui.TableFlags_Resizable)
                                           (Im-gui.TableFlags_Reorderable)
                                           (Im-gui.TableFlags_Hideable))
                              :flags2 (bor (Im-gui.TableFlags_SizingStretchSame)
                                           (Im-gui.TableFlags_ScrollX)
                                           (Im-gui.TableFlags_ScrollY)
                                           (Im-gui.TableFlags_BordersOuter)
                                           (Im-gui.TableFlags_RowBg)
                                           (Im-gui.TableFlags_ContextMenuInBody))
                              :freeze_cols 1
                              :freeze_rows 1
                              :inner_width 1000}))
    (demo.HelpMarker "When ScrollX is enabled, the default sizing policy becomes ImGuiTableFlags_SizingFixedFit, as automatically stretching columns doesn't make much sense with horizontal scrolling.

Also note that as of the current version, you will almost always want to enable ScrollY along with ScrollX,because the container window won't automatically extend vertically to fix contents (this may be improved in future versions).")
    (demo.PushStyleCompact)
    (set (rv tables.horizontal.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.horizontal.flags1
                               (Im-gui.TableFlags_Resizable)))
    (set (rv tables.horizontal.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                               tables.horizontal.flags1
                               (Im-gui.TableFlags_ScrollX)))
    (set (rv tables.horizontal.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                               tables.horizontal.flags1
                               (Im-gui.TableFlags_ScrollY)))
    (Im-gui.SetNextItemWidth ctx (Im-gui.GetFrameHeight ctx))
    (set (rv tables.horizontal.freeze_cols)
         (Im-gui.DragInt ctx :freeze_cols tables.horizontal.freeze_cols 0.2 0 9
                         nil (Im-gui.SliderFlags_NoInput)))
    (Im-gui.SetNextItemWidth ctx (Im-gui.GetFrameHeight ctx))
    (set (rv tables.horizontal.freeze_rows)
         (Im-gui.DragInt ctx :freeze_rows tables.horizontal.freeze_rows 0.2 0 9
                         nil (Im-gui.SliderFlags_NoInput)))
    (demo.PopStyleCompact)
    (local outer-size [0 (* TEXT_BASE_HEIGHT 8)])
    (when (Im-gui.BeginTable ctx :table_scrollx 7 tables.horizontal.flags1
                             (table.unpack outer-size))
      (Im-gui.TableSetupScrollFreeze ctx tables.horizontal.freeze_cols
                                     tables.horizontal.freeze_rows)
      (Im-gui.TableSetupColumn ctx "Line #" (Im-gui.TableColumnFlags_NoHide))
      (Im-gui.TableSetupColumn ctx :One)
      (Im-gui.TableSetupColumn ctx :Two)
      (Im-gui.TableSetupColumn ctx :Three)
      (Im-gui.TableSetupColumn ctx :Four)
      (Im-gui.TableSetupColumn ctx :Five)
      (Im-gui.TableSetupColumn ctx :Six)
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 19]
        (Im-gui.TableNextRow ctx)
        (for [column 0 6]
          (when (or (Im-gui.TableSetColumnIndex ctx column) (= column 0))
            (if (= column 0) (Im-gui.Text ctx (: "Line %d" :format row))
                (Im-gui.Text ctx (: "Hello world %d,%d" :format column row))))))
      (Im-gui.EndTable ctx))
    (Im-gui.Spacing ctx)
    (Im-gui.Text ctx "Stretch + ScrollX")
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Showcase using Stretch columns + ScrollX together: this is rather unusual and only makes sense when specifying an 'inner_width' for the table!
Without an explicit value, inner_width is == outer_size.x and therefore using Stretch columns + ScrollX together doesn't make sense.")
    (demo.PushStyleCompact)
    (Im-gui.PushID ctx :flags3)
    (Im-gui.PushItemWidth ctx (* TEXT_BASE_WIDTH 30))
    (set (rv tables.horizontal.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                               tables.horizontal.flags2
                               (Im-gui.TableFlags_ScrollX)))
    (set (rv tables.horizontal.inner_width)
         (Im-gui.DragDouble ctx :inner_width tables.horizontal.inner_width 1 0
                            FLT_MAX "%.1f"))
    (Im-gui.PopItemWidth ctx)
    (Im-gui.PopID ctx)
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table2 7 tables.horizontal.flags2
                             (. outer-size 1) (. outer-size 2)
                             tables.horizontal.inner_width)
      (for [cell 1 (* 20 7)]
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx
                     (: "Hello world %d,%d" :format
                        (Im-gui.TableGetColumnIndex ctx)
                        (Im-gui.TableGetRowIndex ctx))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Columns flags")
    (when (not tables.col_flags)
      (set tables.col_flags
           {:columns [{:flags (Im-gui.TableColumnFlags_DefaultSort)
                       :flags_out 0
                       :name :One}
                      {:flags (Im-gui.TableColumnFlags_None)
                       :flags_out 0
                       :name :Two}
                      {:flags (Im-gui.TableColumnFlags_DefaultHide)
                       :flags_out 0
                       :name :Three}]}))
    (when (Im-gui.BeginTable ctx :table_columns_flags_checkboxes
                             (length tables.col_flags.columns)
                             (Im-gui.TableFlags_None))
      (demo.PushStyleCompact)
      (each [i column (ipairs tables.col_flags.columns)]
        (Im-gui.TableNextColumn ctx)
        (Im-gui.PushID ctx i)
        (Im-gui.AlignTextToFramePadding ctx)
        (Im-gui.Text ctx (: "'%s'" :format column.name))
        (Im-gui.Spacing ctx)
        (Im-gui.Text ctx "Input flags:")
        (set column.flags (demo.EditTableColumnsFlags column.flags))
        (Im-gui.Spacing ctx)
        (Im-gui.Text ctx "Output flags:")
        (Im-gui.BeginDisabled ctx)
        (demo.ShowTableColumnsStatusFlags column.flags_out)
        (Im-gui.EndDisabled ctx)
        (Im-gui.PopID ctx))
      (demo.PopStyleCompact)
      (Im-gui.EndTable ctx))
    (local flags
           (bor (Im-gui.TableFlags_SizingFixedFit) (Im-gui.TableFlags_ScrollX)
                (Im-gui.TableFlags_ScrollY) (Im-gui.TableFlags_RowBg)
                (Im-gui.TableFlags_BordersOuter) (Im-gui.TableFlags_BordersV)
                (Im-gui.TableFlags_Resizable) (Im-gui.TableFlags_Reorderable)
                (Im-gui.TableFlags_Hideable) (Im-gui.TableFlags_Sortable)))
    (local outer-size [0 (* TEXT_BASE_HEIGHT 9)])
    (when (Im-gui.BeginTable ctx :table_columns_flags
                             (length tables.col_flags.columns) flags
                             (table.unpack outer-size))
      (each [i column (ipairs tables.col_flags.columns)]
        (Im-gui.TableSetupColumn ctx column.name column.flags))
      (Im-gui.TableHeadersRow ctx)
      (each [i column (ipairs tables.col_flags.columns)]
        (set column.flags_out (Im-gui.TableGetColumnFlags ctx (- i 1))))
      (local indent-step (/ TEXT_BASE_WIDTH 2))
      (for [row 0 7]
        (Im-gui.Indent ctx indent-step)
        (Im-gui.TableNextRow ctx)
        (for [column 0 (- (length tables.col_flags.columns) 1)]
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx
                       (: "%s %s" :format
                          (or (and (= column 0) :Indented) :Hello)
                          (Im-gui.TableGetColumnName ctx column)))))
      (Im-gui.Unindent ctx (* indent-step 8))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Columns widths")
    (when (not tables.col_widths)
      (set tables.col_widths
           {:flags1 (Im-gui.TableFlags_Borders)
            :flags2 (Im-gui.TableFlags_None)}))
    (demo.HelpMarker "Using TableSetupColumn() to setup default width.")
    (demo.PushStyleCompact)
    (set (rv tables.col_widths.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                               tables.col_widths.flags1
                               (Im-gui.TableFlags_Resizable)))
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table1 3 tables.col_widths.flags1)
      (Im-gui.TableSetupColumn ctx :one (Im-gui.TableColumnFlags_WidthFixed)
                               100)
      (Im-gui.TableSetupColumn ctx :two (Im-gui.TableColumnFlags_WidthFixed)
                               200)
      (Im-gui.TableSetupColumn ctx :three (Im-gui.TableColumnFlags_WidthFixed))
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 3]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2]
          (Im-gui.TableSetColumnIndex ctx column)
          (if (= row 0)
              (Im-gui.Text ctx
                           (: "(w: %5.1f)" :format
                              (Im-gui.GetContentRegionAvail ctx)))
              (Im-gui.Text ctx (: "Hello %d,%d" :format column row)))))
      (Im-gui.EndTable ctx))
    (demo.HelpMarker "Using TableSetupColumn() to setup explicit width.

Unless _NoKeepColumnsVisible is set, fixed columns with set width may still be shrunk down if there's not enough space in the host.")
    (demo.PushStyleCompact)
    (set (rv tables.col_widths.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoKeepColumnsVisible
                               tables.col_widths.flags2
                               (Im-gui.TableFlags_NoKeepColumnsVisible)))
    (set (rv tables.col_widths.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                               tables.col_widths.flags2
                               (Im-gui.TableFlags_BordersInnerV)))
    (set (rv tables.col_widths.flags2)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                               tables.col_widths.flags2
                               (Im-gui.TableFlags_BordersOuterV)))
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table2 4 tables.col_widths.flags2)
      (Im-gui.TableSetupColumn ctx "" (Im-gui.TableColumnFlags_WidthFixed) 100)
      (Im-gui.TableSetupColumn ctx "" (Im-gui.TableColumnFlags_WidthFixed)
                               (* TEXT_BASE_WIDTH 15))
      (Im-gui.TableSetupColumn ctx "" (Im-gui.TableColumnFlags_WidthFixed)
                               (* TEXT_BASE_WIDTH 30))
      (Im-gui.TableSetupColumn ctx "" (Im-gui.TableColumnFlags_WidthFixed)
                               (* TEXT_BASE_WIDTH 15))
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 3]
          (Im-gui.TableSetColumnIndex ctx column)
          (if (= row 0)
              (Im-gui.Text ctx
                           (: "(w: %5.1f)" :format
                              (Im-gui.GetContentRegionAvail ctx)))
              (Im-gui.Text ctx (: "Hello %d,%d" :format column row)))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Nested tables")
    (demo.HelpMarker "This demonstrates embedding a table into another table cell.")
    (local flags (bor (Im-gui.TableFlags_Borders) (Im-gui.TableFlags_Resizable)
                      (Im-gui.TableFlags_Reorderable)
                      (Im-gui.TableFlags_Hideable)))
    (when (Im-gui.BeginTable ctx :table_nested1 2 flags)
      (Im-gui.TableSetupColumn ctx :A0)
      (Im-gui.TableSetupColumn ctx :A1)
      (Im-gui.TableHeadersRow ctx)
      (Im-gui.TableNextColumn ctx)
      (Im-gui.Text ctx "A0 Row 0")
      (local rows-height (* TEXT_BASE_HEIGHT 2))
      (when (Im-gui.BeginTable ctx :table_nested2 2 flags)
        (Im-gui.TableSetupColumn ctx :B0)
        (Im-gui.TableSetupColumn ctx :B1)
        (Im-gui.TableHeadersRow ctx)
        (Im-gui.TableNextRow ctx (Im-gui.TableRowFlags_None) rows-height)
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx "B0 Row 0")
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx "B0 Row 1")
        (Im-gui.TableNextRow ctx (Im-gui.TableRowFlags_None) rows-height)
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx "B1 Row 0")
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx "B1 Row 1")
        (Im-gui.EndTable ctx))
      (Im-gui.TableNextColumn ctx)
      (Im-gui.Text ctx "A0 Row 1")
      (Im-gui.TableNextColumn ctx)
      (Im-gui.Text ctx "A1 Row 0")
      (Im-gui.TableNextColumn ctx)
      (Im-gui.Text ctx "A1 Row 1")
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Row height")
    (demo.HelpMarker "You can pass a 'min_row_height' to TableNextRow().

Rows are padded with 'ImGui_StyleVar_CellPadding.y' on top and bottom, so effectively the minimum row height will always be >= 'ImGui_StyleVar_CellPadding.y * 2.0'.

We cannot honor a _maximum_ row height as that would require a unique clipping rectangle per row.")
    (when (Im-gui.BeginTable ctx :table_row_height 1
                             (bor (Im-gui.TableFlags_BordersOuter)
                                  (Im-gui.TableFlags_BordersInnerV)))
      (for [row 0 9] (local min-row-height (* TEXT_BASE_HEIGHT 0.3 row))
        (Im-gui.TableNextRow ctx (Im-gui.TableRowFlags_None) min-row-height)
        (Im-gui.TableNextColumn ctx)
        (Im-gui.Text ctx (: "min_row_height = %.2f" :format min-row-height)))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Outer size")
    (when (not tables.outer_sz)
      (set tables.outer_sz
           {:flags (bor (Im-gui.TableFlags_Borders)
                        (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_ContextMenuInBody)
                        (Im-gui.TableFlags_RowBg)
                        (Im-gui.TableFlags_SizingFixedFit)
                        (Im-gui.TableFlags_NoHostExtendX))}))
    (Im-gui.Text ctx "Using NoHostExtendX and NoHostExtendY:")
    (demo.PushStyleCompact)
    (set (rv tables.outer_sz.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                               tables.outer_sz.flags
                               (Im-gui.TableFlags_NoHostExtendX)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Make outer width auto-fit to columns, overriding outer_size.x value.

Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
    (set (rv tables.outer_sz.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendY
                               tables.outer_sz.flags
                               (Im-gui.TableFlags_NoHostExtendY)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).

Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
    (demo.PopStyleCompact)
    (local outer-size [0 (* TEXT_BASE_HEIGHT 5.5)])
    (when (Im-gui.BeginTable ctx :table1 3 tables.outer_sz.flags
                             (table.unpack outer-size))
      (for [row 0 9]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx (: "Cell %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (Im-gui.SameLine ctx)
    (Im-gui.Text ctx :Hello!)
    (Im-gui.Spacing ctx)
    (local flags (bor (Im-gui.TableFlags_Borders) (Im-gui.TableFlags_RowBg)))
    (Im-gui.Text ctx "Using explicit size:")
    (when (Im-gui.BeginTable ctx :table2 3 flags (* TEXT_BASE_WIDTH 30) 0)
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2] (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx (: "Cell %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (Im-gui.SameLine ctx)
    (when (Im-gui.BeginTable ctx :table3 3 flags (* TEXT_BASE_WIDTH 30) 0)
      (for [row 0 2]
        (Im-gui.TableNextRow ctx 0 (* TEXT_BASE_HEIGHT 1.5))
        (for [column 0 2] (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx (: "Cell %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Background color")
    (when (not tables.bg_col)
      (set tables.bg_col {:cell_bg_type 1
                          :flags (Im-gui.TableFlags_RowBg)
                          :row_bg_target 1
                          :row_bg_type 1}))
    (demo.PushStyleCompact)
    (set (rv tables.bg_col.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Borders tables.bg_col.flags
                               (Im-gui.TableFlags_Borders)))
    (set (rv tables.bg_col.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_RowBg tables.bg_col.flags
                               (Im-gui.TableFlags_RowBg)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "ImGuiTableFlags_RowBg automatically sets RowBg0 to alternative colors pulled from the Style.")
    (set (rv tables.bg_col.row_bg_type)
         (Im-gui.Combo ctx "row bg type" tables.bg_col.row_bg_type
                       "None\000Red\000Gradient\000"))
    (set (rv tables.bg_col.row_bg_target)
         (Im-gui.Combo ctx "row bg target" tables.bg_col.row_bg_target
                       "RowBg0\000RowBg1\000"))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "Target RowBg0 to override the alternating odd/even colors,
Target RowBg1 to blend with them.")
    (set (rv tables.bg_col.cell_bg_type)
         (Im-gui.Combo ctx "cell bg type" tables.bg_col.cell_bg_type
                       "None\000Blue\000"))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "We are colorizing cells to B1->C2 here.")
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table1 5 tables.bg_col.flags)
      (for [row 0 5]
        (Im-gui.TableNextRow ctx)
        (when (not= tables.bg_col.row_bg_type 0)
          (var row-bg-color nil)
          (if (= tables.bg_col.row_bg_type 1) (set row-bg-color 3008187814)
              (do
                (set row-bg-color 858993574)
                (set row-bg-color
                     (+ row-bg-color (lshift (demo.round (* row 0.1 255)) 24)))))
          (Im-gui.TableSetBgColor ctx
                                  (+ (Im-gui.TableBgTarget_RowBg0)
                                     tables.bg_col.row_bg_target)
                                  row-bg-color))
        (for [column 0 4]
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx
                       (: "%c%c" :format (+ (string.byte :A) row)
                          (+ (string.byte :0) column)))
          (when (and (and (and (and (>= row 1) (<= row 2)) (>= column 1))
                          (<= column 2))
                     (= tables.bg_col.cell_bg_type 1))
            (Im-gui.TableSetBgColor ctx (Im-gui.TableBgTarget_CellBg)
                                    1296937894))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Tree view")
    (local flags
           (bor (Im-gui.TableFlags_BordersV) (Im-gui.TableFlags_BordersOuterH)
                (Im-gui.TableFlags_Resizable) (Im-gui.TableFlags_RowBg)))
    (when (Im-gui.BeginTable ctx :3ways 3 flags)
      (Im-gui.TableSetupColumn ctx :Name (Im-gui.TableColumnFlags_NoHide))
      (Im-gui.TableSetupColumn ctx :Size (Im-gui.TableColumnFlags_WidthFixed)
                               (* TEXT_BASE_WIDTH 12))
      (Im-gui.TableSetupColumn ctx :Type (Im-gui.TableColumnFlags_WidthFixed)
                               (* TEXT_BASE_WIDTH 18))
      (Im-gui.TableHeadersRow ctx)
      (local nodes [{:child_count 3
                     :child_idx 1
                     :name :Root
                     :size (- 1)
                     :type :Folder}
                    {:child_count 2
                     :child_idx 4
                     :name :Music
                     :size (- 1)
                     :type :Folder}
                    {:child_count 3
                     :child_idx 6
                     :name :Textures
                     :size (- 1)
                     :type :Folder}
                    {:child_count (- 1)
                     :child_idx (- 1)
                     :name :desktop.ini
                     :size 1024
                     :type "System file"}
                    {:child_count (- 1)
                     :child_idx (- 1)
                     :name :File1_a.wav
                     :size 123000
                     :type "Audio file"}
                    {:child_count (- 1)
                     :child_idx (- 1)
                     :name :File1_b.wav
                     :size 456000
                     :type "Audio file"}
                    {:child_count (- 1)
                     :child_idx (- 1)
                     :name :Image001.png
                     :size 203128
                     :type "Image file"}
                    {:child_count (- 1)
                     :child_idx (- 1)
                     :name "Copy of Image001.png"
                     :size 203256
                     :type "Image file"}
                    {:child_count (- 1)
                     :child_idx (- 1)
                     :name "Copy of Image001 (Final2).png"
                     :size 203512
                     :type "Image file"}])

      (fn Display-node [node]
        (Im-gui.TableNextRow ctx)
        (Im-gui.TableNextColumn ctx)
        (local is-folder (> node.child_count 0))
        (if is-folder (let [open (Im-gui.TreeNode ctx node.name
                                                  (Im-gui.TreeNodeFlags_SpanFullWidth))]
                        (Im-gui.TableNextColumn ctx)
                        (Im-gui.TextDisabled ctx "--")
                        (Im-gui.TableNextColumn ctx)
                        (Im-gui.Text ctx node.type)
                        (when open
                          (for [child-n 1 node.child_count]
                            (Display-node (. nodes (+ node.child_idx child-n))))
                          (Im-gui.TreePop ctx)))
            (do
              (Im-gui.TreeNode ctx node.name
                               (bor (Im-gui.TreeNodeFlags_Leaf)
                                    (Im-gui.TreeNodeFlags_Bullet)
                                    (Im-gui.TreeNodeFlags_NoTreePushOnOpen)
                                    (Im-gui.TreeNodeFlags_SpanFullWidth)))
              (Im-gui.TableNextColumn ctx)
              (Im-gui.Text ctx (: "%d" :format node.size))
              (Im-gui.TableNextColumn ctx)
              (Im-gui.Text ctx node.type))))

      (Display-node (. nodes 1))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Item width")
    (when (not tables.item_width) (set tables.item_width {:dummy_d 0}))
    (demo.HelpMarker "Showcase using PushItemWidth() and how it is preserved on a per-column basis.

Note that on auto-resizing non-resizable fixed columns, querying the content width for e.g. right-alignment doesn't make sense.")
    (when (Im-gui.BeginTable ctx :table_item_width 3
                             (Im-gui.TableFlags_Borders))
      (Im-gui.TableSetupColumn ctx :small)
      (Im-gui.TableSetupColumn ctx :half)
      (Im-gui.TableSetupColumn ctx :right-align)
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 2]
        (Im-gui.TableNextRow ctx)
        (when (= row 0)
          (Im-gui.TableSetColumnIndex ctx 0)
          (Im-gui.PushItemWidth ctx (* TEXT_BASE_WIDTH 3))
          (Im-gui.TableSetColumnIndex ctx 1)
          (Im-gui.PushItemWidth ctx
                                (- 0 (* (Im-gui.GetContentRegionAvail ctx) 0.5)))
          (Im-gui.TableSetColumnIndex ctx 2)
          (Im-gui.PushItemWidth ctx (- FLT_MIN)))
        (Im-gui.PushID ctx row)
        (Im-gui.TableSetColumnIndex ctx 0)
        (set (rv tables.item_width.dummy_d)
             (Im-gui.SliderDouble ctx :double0 tables.item_width.dummy_d 0 1))
        (Im-gui.TableSetColumnIndex ctx 1)
        (set (rv tables.item_width.dummy_d)
             (Im-gui.SliderDouble ctx :double1 tables.item_width.dummy_d 0 1))
        (Im-gui.TableSetColumnIndex ctx 2)
        (set (rv tables.item_width.dummy_d)
             (Im-gui.SliderDouble ctx "##double2" tables.item_width.dummy_d 0 1))
        (Im-gui.PopID ctx))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Custom headers")
    (when (not tables.headers)
      (set tables.headers {:column_selected [false false false]}))
    (local COLUMNS_COUNT 3)
    (when (Im-gui.BeginTable ctx :table_custom_headers COLUMNS_COUNT
                             (bor (Im-gui.TableFlags_Borders)
                                  (Im-gui.TableFlags_Reorderable)
                                  (Im-gui.TableFlags_Hideable)))
      (Im-gui.TableSetupColumn ctx :Apricot)
      (Im-gui.TableSetupColumn ctx :Banana)
      (Im-gui.TableSetupColumn ctx :Cherry)
      (Im-gui.TableNextRow ctx (Im-gui.TableRowFlags_Headers))
      (for [column 0 (- COLUMNS_COUNT 1)]
        (Im-gui.TableSetColumnIndex ctx column)
        (local column-name (Im-gui.TableGetColumnName ctx column))
        (Im-gui.PushID ctx column)
        (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) 0 0)
        (set-forcibly! (rv cs1)
                       (Im-gui.Checkbox ctx "##checkall"
                                        (. tables.headers.column_selected
                                           (+ column 1))))
        (tset tables.headers.column_selected (+ column 1) cs1)
        (Im-gui.PopStyleVar ctx)
        (Im-gui.SameLine ctx 0
                         (Im-gui.GetStyleVar ctx
                                             (Im-gui.StyleVar_ItemInnerSpacing)))
        (Im-gui.TableHeader ctx column-name)
        (Im-gui.PopID ctx))
      (for [row 0 4]
        (Im-gui.TableNextRow ctx)
        (for [column 0 2]
          (local buf (: "Cell %d,%d" :format column row))
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Selectable ctx buf
                             (. tables.headers.column_selected (+ column 1)))))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Context menus")
    (when (not tables.ctx_menus)
      (set tables.ctx_menus
           {:flags1 (bor (Im-gui.TableFlags_Resizable)
                         (Im-gui.TableFlags_Reorderable)
                         (Im-gui.TableFlags_Hideable)
                         (Im-gui.TableFlags_Borders)
                         (Im-gui.TableFlags_ContextMenuInBody))}))
    (demo.HelpMarker "By default, right-clicking over a TableHeadersRow()/TableHeader() line will open the default context-menu.
Using ImGuiTableFlags_ContextMenuInBody we also allow right-clicking over columns body.")
    (demo.PushStyleCompact)
    (set (rv tables.ctx_menus.flags1)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ContextMenuInBody
                               tables.ctx_menus.flags1
                               (Im-gui.TableFlags_ContextMenuInBody)))
    (demo.PopStyleCompact)
    (local COLUMNS_COUNT 3)
    (when (Im-gui.BeginTable ctx :table_context_menu COLUMNS_COUNT
                             tables.ctx_menus.flags1)
      (Im-gui.TableSetupColumn ctx :One)
      (Im-gui.TableSetupColumn ctx :Two)
      (Im-gui.TableSetupColumn ctx :Three)
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 3]
        (Im-gui.TableNextRow ctx)
        (for [column 0 (- COLUMNS_COUNT 1)]
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Cell %d,%d" :format column row))))
      (Im-gui.EndTable ctx))
    (demo.HelpMarker "Demonstrate mixing table context menu (over header), item context button (over button) and custom per-colum context menu (over column body).")
    (local flags2
           (bor (Im-gui.TableFlags_Resizable)
                (Im-gui.TableFlags_SizingFixedFit)
                (Im-gui.TableFlags_Reorderable) (Im-gui.TableFlags_Hideable)
                (Im-gui.TableFlags_Borders)))
    (when (Im-gui.BeginTable ctx :table_context_menu_2 COLUMNS_COUNT flags2)
      (Im-gui.TableSetupColumn ctx :One)
      (Im-gui.TableSetupColumn ctx :Two)
      (Im-gui.TableSetupColumn ctx :Three)
      (Im-gui.TableHeadersRow ctx)
      (for [row 0 3]
        (Im-gui.TableNextRow ctx)
        (for [column 0 (- COLUMNS_COUNT 1)]
          (Im-gui.TableSetColumnIndex ctx column)
          (Im-gui.Text ctx (: "Cell %d,%d" :format column row))
          (Im-gui.SameLine ctx)
          (Im-gui.PushID ctx (+ (* row COLUMNS_COUNT) column))
          (Im-gui.SmallButton ctx "..")
          (when (Im-gui.BeginPopupContextItem ctx)
            (Im-gui.Text ctx
                         (: "This is the popup for Button(\"..\") in Cell %d,%d"
                            :format column row))
            (when (Im-gui.Button ctx :Close) (Im-gui.CloseCurrentPopup ctx))
            (Im-gui.EndPopup ctx))
          (Im-gui.PopID ctx)))
      (var hovered-column (- 1))
      (for [column 0 COLUMNS_COUNT]
        (Im-gui.PushID ctx column)
        (when (not= (band (Im-gui.TableGetColumnFlags ctx column)
                          (Im-gui.TableColumnFlags_IsHovered))
                    0)
          (set hovered-column column))
        (when (and (and (= hovered-column column)
                        (not (Im-gui.IsAnyItemHovered ctx)))
                   (Im-gui.IsMouseReleased ctx 1))
          (Im-gui.OpenPopup ctx :MyPopup))
        (when (Im-gui.BeginPopup ctx :MyPopup)
          (if (= column COLUMNS_COUNT)
              (Im-gui.Text ctx
                           "This is a custom popup for unused space after the last column.")
              (Im-gui.Text ctx
                           (: "This is a custom popup for Column %d" :format
                              column)))
          (when (Im-gui.Button ctx :Close) (Im-gui.CloseCurrentPopup ctx))
          (Im-gui.EndPopup ctx))
        (Im-gui.PopID ctx))
      (Im-gui.EndTable ctx)
      (Im-gui.Text ctx (: "Hovered column: %d" :format hovered-column)))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx "Synced instances")
    (when (not tables.synced)
      (set tables.synced
           {:flags (bor (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_Reorderable)
                        (Im-gui.TableFlags_Hideable) (Im-gui.TableFlags_Borders)
                        (Im-gui.TableFlags_SizingFixedFit)
                        (Im-gui.TableFlags_NoSavedSettings))}))
    (demo.HelpMarker "Multiple tables with the same identifier will share their settings, width, visibility, order etc.")
    (set (rv tables.synced.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY tables.synced.flags
                               (Im-gui.TableFlags_ScrollY)))
    (set (rv tables.synced.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_SizingFixedFit
                               tables.synced.flags
                               (Im-gui.TableFlags_SizingFixedFit)))
    (for [n 0 2]
      (local buf (: "Synced Table %d" :format n))
      (local open
             (Im-gui.CollapsingHeader ctx buf nil
                                      (Im-gui.TreeNodeFlags_DefaultOpen)))
      (when (and open (Im-gui.BeginTable ctx :Table 3 tables.synced.flags 0
                                         (* (Im-gui.GetTextLineHeightWithSpacing ctx)
                                            5)))
        (Im-gui.TableSetupColumn ctx :One)
        (Im-gui.TableSetupColumn ctx :Two)
        (Im-gui.TableSetupColumn ctx :Three)
        (Im-gui.TableHeadersRow ctx)
        (local cell-count (or (and (= n 1) 27) 9))
        (for [cell 0 cell-count] (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx (: "this cell %d" :format cell)))
        (Im-gui.EndTable ctx)))
    (Im-gui.TreePop ctx))
  (local template-items-names [:Banana
                               :Apple
                               :Cherry
                               :Watermelon
                               :Grapefruit
                               :Strawberry
                               :Mango
                               :Kiwi
                               :Orange
                               :Pineapple
                               :Blueberry
                               :Plum
                               :Coconut
                               :Pear
                               :Apricot])
  (Do-open-action)
  (when (Im-gui.TreeNode ctx :Sorting)
    (when (not tables.sorting)
      (set tables.sorting {:flags (bor (Im-gui.TableFlags_Resizable)
                                       (Im-gui.TableFlags_Reorderable)
                                       (Im-gui.TableFlags_Hideable)
                                       (Im-gui.TableFlags_Sortable)
                                       (Im-gui.TableFlags_SortMulti)
                                       (Im-gui.TableFlags_RowBg)
                                       (Im-gui.TableFlags_BordersOuter)
                                       (Im-gui.TableFlags_BordersV)
                                       (Im-gui.TableFlags_ScrollY))
                           :items {}})
      (for [n 0 49]
        (local template-n (% n (length template-items-names)))
        (local item {:id n
                     :name (. template-items-names (+ template-n 1))
                     :quantity (% (- (* n n) n) 20)})
        (table.insert tables.sorting.items item)))
    (demo.PushStyleCompact)
    (set (rv tables.sorting.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_SortMulti
                               tables.sorting.flags
                               (Im-gui.TableFlags_SortMulti)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
    (set (rv tables.sorting.flags)
         (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_SortTristate
                               tables.sorting.flags
                               (Im-gui.TableFlags_SortTristate)))
    (Im-gui.SameLine ctx)
    (demo.HelpMarker "When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
    (demo.PopStyleCompact)
    (when (Im-gui.BeginTable ctx :table_sorting 4 tables.sorting.flags 0
                             (* TEXT_BASE_HEIGHT 15) 0)
      (Im-gui.TableSetupColumn ctx :ID
                               (bor (Im-gui.TableColumnFlags_DefaultSort)
                                    (Im-gui.TableColumnFlags_WidthFixed))
                               0 My-item-column-iD_ID)
      (Im-gui.TableSetupColumn ctx :Name (Im-gui.TableColumnFlags_WidthFixed) 0
                               My-item-column-iD_Name)
      (Im-gui.TableSetupColumn ctx :Action
                               (bor (Im-gui.TableColumnFlags_NoSort)
                                    (Im-gui.TableColumnFlags_WidthFixed))
                               0 My-item-column-iD_Action)
      (Im-gui.TableSetupColumn ctx :Quantity
                               (bor (Im-gui.TableColumnFlags_PreferSortDescending)
                                    (Im-gui.TableColumnFlags_WidthStretch))
                               0 My-item-column-iD_Quantity)
      (Im-gui.TableSetupScrollFreeze ctx 0 1)
      (Im-gui.TableHeadersRow ctx)
      (when (Im-gui.TableNeedSort ctx)
        (table.sort tables.sorting.items demo.CompareTableItems))
      (local clipper (Im-gui.CreateListClipper ctx))
      (Im-gui.ListClipper_Begin clipper (length tables.sorting.items))
      (while (Im-gui.ListClipper_Step clipper)
        (local (display-start display-end)
               (Im-gui.ListClipper_GetDisplayRange clipper))
        (for [row-n display-start (- display-end 1)]
          (local item (. tables.sorting.items (+ row-n 1)))
          (Im-gui.PushID ctx item.id)
          (Im-gui.TableNextRow ctx)
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx (: "%04d" :format item.id))
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx item.name)
          (Im-gui.TableNextColumn ctx)
          (Im-gui.SmallButton ctx :None)
          (Im-gui.TableNextColumn ctx)
          (Im-gui.Text ctx (: "%d" :format item.quantity))
          (Im-gui.PopID ctx)))
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Do-open-action)
  (when (Im-gui.TreeNode ctx :Advanced)
    (when (not tables.advanced)
      (set tables.advanced
           {:contents_type 5
            :flags (bor (Im-gui.TableFlags_Resizable)
                        (Im-gui.TableFlags_Reorderable)
                        (Im-gui.TableFlags_Hideable)
                        (Im-gui.TableFlags_Sortable)
                        (Im-gui.TableFlags_SortMulti) (Im-gui.TableFlags_RowBg)
                        (Im-gui.TableFlags_Borders) (Im-gui.TableFlags_ScrollX)
                        (Im-gui.TableFlags_ScrollY)
                        (Im-gui.TableFlags_SizingFixedFit))
            :freeze_cols 1
            :freeze_rows 1
            :inner_width_with_scroll 0
            :items {}
            :items_count (* (length template-items-names) 2)
            :items_need_sort false
            :outer_size_enabled true
            :outer_size_value [0 (* TEXT_BASE_HEIGHT 12)]
            :row_min_height 0
            :show_headers true
            :show_wrapped_text false}))
    (when (Im-gui.TreeNode ctx :Options)
      (demo.PushStyleCompact)
      (Im-gui.PushItemWidth ctx (* TEXT_BASE_WIDTH 28))
      (when (Im-gui.TreeNode ctx "Features:" (Im-gui.TreeNodeFlags_DefaultOpen))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_Resizable)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Reorderable
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_Reorderable)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Hideable
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_Hideable)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_Sortable
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_Sortable)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoSavedSettings
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoSavedSettings)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ContextMenuInBody
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_ContextMenuInBody)))
        (Im-gui.TreePop ctx))
      (when (Im-gui.TreeNode ctx "Decorations:"
                             (Im-gui.TreeNodeFlags_DefaultOpen))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_RowBg
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_RowBg)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_BordersV)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_BordersOuterV)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_BordersInnerV)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersH
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_BordersH)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterH
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_BordersOuterH)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerH
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_BordersInnerH)))
        (Im-gui.TreePop ctx))
      (when (Im-gui.TreeNode ctx "Sizing:" (Im-gui.TreeNodeFlags_DefaultOpen))
        (set tables.advanced.flags
             (demo.EditTableSizingFlags tables.advanced.flags))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "In the Advanced demo we override the policy of each column so those table-wide settings have less effect that typical.")
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoHostExtendX)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Make outer width auto-fit to columns, overriding outer_size.x value.

Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendY
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoHostExtendY)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).

Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoKeepColumnsVisible
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoKeepColumnsVisible)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Only available if ScrollX is disabled.")
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_PreciseWidths
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_PreciseWidths)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoClip
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoClip)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ScrollFreeze options.")
        (Im-gui.TreePop ctx))
      (when (Im-gui.TreeNode ctx "Padding:" (Im-gui.TreeNodeFlags_DefaultOpen))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_PadOuterX
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_PadOuterX)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoPadOuterX
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoPadOuterX)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_NoPadInnerX
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_NoPadInnerX)))
        (Im-gui.TreePop ctx))
      (when (Im-gui.TreeNode ctx "Scrolling:"
                             (Im-gui.TreeNodeFlags_DefaultOpen))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_ScrollX)))
        (Im-gui.SameLine ctx)
        (Im-gui.SetNextItemWidth ctx (Im-gui.GetFrameHeight ctx))
        (set (rv tables.advanced.freeze_cols)
             (Im-gui.DragInt ctx :freeze_cols tables.advanced.freeze_cols 0.2 0
                             9 nil (Im-gui.SliderFlags_NoInput)))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_ScrollY)))
        (Im-gui.SameLine ctx)
        (Im-gui.SetNextItemWidth ctx (Im-gui.GetFrameHeight ctx))
        (set (rv tables.advanced.freeze_rows)
             (Im-gui.DragInt ctx :freeze_rows tables.advanced.freeze_rows 0.2 0
                             9 nil (Im-gui.SliderFlags_NoInput)))
        (Im-gui.TreePop ctx))
      (when (Im-gui.TreeNode ctx "Sorting:" (Im-gui.TreeNodeFlags_DefaultOpen))
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_SortMulti
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_SortMulti)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
        (set (rv tables.advanced.flags)
             (Im-gui.CheckboxFlags ctx :ImGuiTableFlags_SortTristate
                                   tables.advanced.flags
                                   (Im-gui.TableFlags_SortTristate)))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
        (Im-gui.TreePop ctx))
      (when (Im-gui.TreeNode ctx "Other:" (Im-gui.TreeNodeFlags_DefaultOpen))
        (set (rv tables.advanced.show_headers)
             (Im-gui.Checkbox ctx :show_headers tables.advanced.show_headers))
        (set (rv tables.advanced.show_wrapped_text)
             (Im-gui.Checkbox ctx :show_wrapped_text
                              tables.advanced.show_wrapped_text))
        (set-forcibly! (rv osv1 osv2)
                       (Im-gui.DragDouble2 ctx "##OuterSize"
                                           (table.unpack tables.advanced.outer_size_value)))
        (tset tables.advanced.outer_size_value 1 osv1)
        (tset tables.advanced.outer_size_value 2 osv2)
        (Im-gui.SameLine ctx 0
                         (Im-gui.GetStyleVar ctx
                                             (Im-gui.StyleVar_ItemInnerSpacing)))
        (set (rv tables.advanced.outer_size_enabled)
             (Im-gui.Checkbox ctx :outer_size
                              tables.advanced.outer_size_enabled))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "If scrolling is disabled (ScrollX and ScrollY not set):
- The table is output directly in the parent window.
- OuterSize.x < 0.0 will right-align the table.
- OuterSize.x = 0.0 will narrow fit the table unless there are any Stretch columns.
- OuterSize.y then becomes the minimum size for the table, which will extend vertically if there are more rows (unless NoHostExtendY is set).")
        (set (rv tables.advanced.inner_width_with_scroll)
             (Im-gui.DragDouble ctx "inner_width (when ScrollX active)"
                                tables.advanced.inner_width_with_scroll 1 0
                                FLT_MAX))
        (set (rv tables.advanced.row_min_height)
             (Im-gui.DragDouble ctx :row_min_height
                                tables.advanced.row_min_height 1 0 FLT_MAX))
        (Im-gui.SameLine ctx)
        (demo.HelpMarker "Specify height of the Selectable item.")
        (set (rv tables.advanced.items_count)
             (Im-gui.DragInt ctx :items_count tables.advanced.items_count 0.1 0
                             9999))
        (set (rv tables.advanced.contents_type)
             (Im-gui.Combo ctx "items_type (first column)"
                           tables.advanced.contents_type
                           "Text\000Button\000SmallButton\000FillButton\000Selectable\000Selectable (span row)\000"))
        (Im-gui.TreePop ctx))
      (Im-gui.PopItemWidth ctx)
      (demo.PopStyleCompact)
      (Im-gui.Spacing ctx)
      (Im-gui.TreePop ctx))
    (when (not= (length tables.advanced.items) tables.advanced.items_count)
      (set tables.advanced.items {})
      (for [n 0 (- tables.advanced.items_count 1)]
        (local template-n (% n (length template-items-names)))
        (local item
               {:id n
                :name (. template-items-names (+ template-n 1))
                :quantity (or (and (= template-n 3) 10)
                              (or (and (= template-n 4) 20) 0))})
        (table.insert tables.advanced.items item)))
    (local inner-width-to-use (or (and (not= (band tables.advanced.flags
                                                   (Im-gui.TableFlags_ScrollX))
                                             0)
                                       tables.advanced.inner_width_with_scroll)
                                  0))
    (var (w h) (values 0 0))
    (when tables.advanced.outer_size_enabled
      (set (w h) (table.unpack tables.advanced.outer_size_value)))
    (when (Im-gui.BeginTable ctx :table_advanced 6 tables.advanced.flags w h
                             inner-width-to-use)
      (Im-gui.TableSetupColumn ctx :ID
                               (bor (Im-gui.TableColumnFlags_DefaultSort)
                                    (Im-gui.TableColumnFlags_WidthFixed)
                                    (Im-gui.TableColumnFlags_NoHide))
                               0 My-item-column-iD_ID)
      (Im-gui.TableSetupColumn ctx :Name (Im-gui.TableColumnFlags_WidthFixed) 0
                               My-item-column-iD_Name)
      (Im-gui.TableSetupColumn ctx :Action
                               (bor (Im-gui.TableColumnFlags_NoSort)
                                    (Im-gui.TableColumnFlags_WidthFixed))
                               0 My-item-column-iD_Action)
      (Im-gui.TableSetupColumn ctx :Quantity
                               (Im-gui.TableColumnFlags_PreferSortDescending) 0
                               My-item-column-iD_Quantity)
      (Im-gui.TableSetupColumn ctx :Description
                               (or (and (not= (band tables.advanced.flags
                                                    (Im-gui.TableFlags_NoHostExtendX))
                                              0)
                                        0)
                                   (Im-gui.TableColumnFlags_WidthStretch))
                               0 My-item-column-iD_Description)
      (Im-gui.TableSetupColumn ctx :Hidden
                               (bor (Im-gui.TableColumnFlags_DefaultHide)
                                    (Im-gui.TableColumnFlags_NoSort)))
      (Im-gui.TableSetupScrollFreeze ctx tables.advanced.freeze_cols
                                     tables.advanced.freeze_rows)
      (local (specs-dirty has-specs) (Im-gui.TableNeedSort ctx))
      (when (and has-specs (or specs-dirty tables.advanced.items_need_sort))
        (table.sort tables.advanced.items demo.CompareTableItems)
        (set tables.advanced.items_need_sort false))
      (local sorts-specs-using-quantity
             (not= (band (Im-gui.TableGetColumnFlags ctx 3)
                         (Im-gui.TableColumnFlags_IsSorted))
                   0))
      (when tables.advanced.show_headers (Im-gui.TableHeadersRow ctx))
      (Im-gui.PushButtonRepeat ctx true)
      (local clipper (Im-gui.CreateListClipper ctx))
      (Im-gui.ListClipper_Begin clipper (length tables.advanced.items))
      (while (Im-gui.ListClipper_Step clipper)
        (local (display-start display-end)
               (Im-gui.ListClipper_GetDisplayRange clipper))
        (for [row-n display-start (- display-end 1)]
          (local item (. tables.advanced.items (+ row-n 1)))
          (Im-gui.PushID ctx item.id)
          (Im-gui.TableNextRow ctx (Im-gui.TableRowFlags_None)
                               tables.advanced.row_min_height)
          (Im-gui.TableSetColumnIndex ctx 0)
          (local label (: "%04d" :format item.id))
          (local contents-type tables.advanced.contents_type)
          (if (= contents-type 0) (Im-gui.Text ctx label) (= contents-type 1)
              (Im-gui.Button ctx label) (= contents-type 2)
              (Im-gui.SmallButton ctx label) (= contents-type 3)
              (Im-gui.Button ctx label (- FLT_MIN) 0)
              (or (= contents-type 4) (= contents-type 5))
              (let [selectable-flags (or (and (= contents-type 5)
                                              (bor (Im-gui.SelectableFlags_SpanAllColumns)
                                                   (Im-gui.SelectableFlags_AllowItemOverlap)))
                                         (Im-gui.SelectableFlags_None))]
                (when (Im-gui.Selectable ctx label item.is_selected
                                         selectable-flags 0
                                         tables.advanced.row_min_height)
                  (if (Im-gui.IsKeyDown ctx (Im-gui.Mod_Ctrl))
                      (set item.is_selected (not item.is_selected))
                      (each [_ it (ipairs tables.advanced.items)]
                        (set it.is_selected (= it item)))))))
          (when (Im-gui.TableSetColumnIndex ctx 1) (Im-gui.Text ctx item.name))
          (when (Im-gui.TableSetColumnIndex ctx 2)
            (when (Im-gui.SmallButton ctx :Chop)
              (set item.quantity (+ item.quantity 1)))
            (when (and sorts-specs-using-quantity
                       (Im-gui.IsItemDeactivated ctx))
              (set tables.advanced.items_need_sort true))
            (Im-gui.SameLine ctx)
            (when (Im-gui.SmallButton ctx :Eat)
              (set item.quantity (- item.quantity 1)))
            (when (and sorts-specs-using-quantity
                       (Im-gui.IsItemDeactivated ctx))
              (set tables.advanced.items_need_sort true)))
          (when (Im-gui.TableSetColumnIndex ctx 3)
            (Im-gui.Text ctx (: "%d" :format item.quantity)))
          (Im-gui.TableSetColumnIndex ctx 4)
          (if tables.advanced.show_wrapped_text
              (Im-gui.TextWrapped ctx "Lorem ipsum dolor sit amet")
              (Im-gui.Text ctx "Lorem ipsum dolor sit amet"))
          (when (Im-gui.TableSetColumnIndex ctx 5) (Im-gui.Text ctx :1234))
          (Im-gui.PopID ctx)))
      (Im-gui.PopButtonRepeat ctx)
      (Im-gui.EndTable ctx))
    (Im-gui.TreePop ctx))
  (Im-gui.PopID ctx)
  (when tables.disable_indent (Im-gui.PopStyleVar ctx)))

(fn demo.ShowDemoWindowInputs []
  (var rv nil)
  (when (Im-gui.CollapsingHeader ctx "Inputs & Focus")
    (Im-gui.SetNextItemOpen ctx true (Im-gui.Cond_Once))
    (when (Im-gui.TreeNode ctx :Inputs)
      (demo.HelpMarker "This is a simplified view. See more detailed input state:
- in 'Tools->Metrics/Debugger->Inputs'.
- in 'Tools->Debug Log->IO'.")
      (if (Im-gui.IsMousePosValid ctx)
          (Im-gui.Text ctx
                       (: "Mouse pos: (%g, %g)" :format
                          (Im-gui.GetMousePos ctx)))
          (Im-gui.Text ctx "Mouse pos: <INVALID>"))
      (Im-gui.Text ctx (: "Mouse delta: (%g, %g)" :format
                          (Im-gui.GetMouseDelta ctx)))
      (local buttons 4)
      (Im-gui.Text ctx "Mouse down:")
      (for [button 0 buttons]
        (when (Im-gui.IsMouseDown ctx button)
          (local duration (Im-gui.GetMouseDownDuration ctx button))
          (Im-gui.SameLine ctx)
          (Im-gui.Text ctx (: "b%d (%.02f secs)" :format button duration))))
      (Im-gui.Text ctx (: "Mouse wheel: %.1f %.1f" :format
                          (Im-gui.GetMouseWheel ctx)))
      (Im-gui.Text ctx "Keys down:")
      (each [key name (demo.EachEnum :Key)]
        (when (Im-gui.IsKeyDown ctx key)
          (local duration (Im-gui.GetKeyDownDuration ctx key))
          (Im-gui.SameLine ctx)
          (Im-gui.Text ctx (: "\"%s\" %d (%.02f secs)" :format name key
                              duration))))
      (Im-gui.Text ctx (: "Keys mods: %s%s%s%s" :format
                          (or (and (Im-gui.IsKeyDown ctx (Im-gui.Mod_Ctrl))
                                   "CTRL ") "")
                          (or (and (Im-gui.IsKeyDown ctx (Im-gui.Mod_Shift))
                                   "SHIFT ") "")
                          (or (and (Im-gui.IsKeyDown ctx (Im-gui.Mod_Alt))
                                   "ALT ") "")
                          (or (and (Im-gui.IsKeyDown ctx (Im-gui.Mod_Super))
                                   "SUPER ") "")))
      (Im-gui.Text ctx "Chars queue:")
      (for [next-id 0 math.huge]
        (local (rv c) (Im-gui.GetInputQueueCharacter ctx next-id))
        (when (not rv) (lua :break))
        (Im-gui.SameLine ctx)
        (Im-gui.Text ctx (: "'%s' (0x%04X)" :format (utf8.char c) c)))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "WantCapture override")
      (when (not misc.capture_override)
        (set misc.capture_override {:keyboard (- 1) :mouse (- 1)}))
      (demo.HelpMarker "SetNextFrameWantCaptureXXX instructs ReaImGui how to route inputs.

Capturing the keyboard allows receiving input from REAPER's global scope.

Hovering the colored canvas will call SetNextFrameWantCaptureXXX.")
      (local capture-override-desc [:None "Set to false" "Set to true"])
      (Im-gui.SetNextItemWidth ctx (* (Im-gui.GetFontSize ctx) 15))
      (set (rv misc.capture_override.keyboard)
           (Im-gui.SliderInt ctx "SetNextFrameWantCaptureKeyboard() on hover"
                             misc.capture_override.keyboard (- 1) 1
                             (. capture-override-desc
                                (+ misc.capture_override.keyboard 2))
                             (Im-gui.SliderFlags_AlwaysClamp)))
      (Im-gui.ColorButton ctx "##panel" 2988028671
                          (bor (Im-gui.ColorEditFlags_NoTooltip)
                               (Im-gui.ColorEditFlags_NoDragDrop))
                          128 96)
      (when (and (Im-gui.IsItemHovered ctx)
                 (not= misc.capture_override.keyboard (- 1)))
        (Im-gui.SetNextFrameWantCaptureKeyboard ctx
                                                (= misc.capture_override.keyboard
                                                   1)))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Mouse Cursors")
      (local current (Im-gui.GetMouseCursor ctx))
      (each [cursor name (demo.EachEnum :MouseCursor)]
        (when (= cursor current)
          (Im-gui.Text ctx (: "Current mouse cursor = %d: %s" :format current
                              name))
          (lua :break)))
      (Im-gui.Text ctx "Hover to see mouse cursors:")
      (each [i name (demo.EachEnum :MouseCursor)]
        (local label (: "Mouse cursor %d: %s" :format i name))
        (Im-gui.Bullet ctx)
        (Im-gui.Selectable ctx label false)
        (when (Im-gui.IsItemHovered ctx) (Im-gui.SetMouseCursor ctx i)))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx :Tabbing)
      (when (not misc.tabbing) (set misc.tabbing {:buf :hello}))
      (Im-gui.Text ctx
                   "Use TAB/SHIFT+TAB to cycle through keyboard editable fields.")
      (set (rv misc.tabbing.buf) (Im-gui.InputText ctx :1 misc.tabbing.buf))
      (set (rv misc.tabbing.buf) (Im-gui.InputText ctx :2 misc.tabbing.buf))
      (set (rv misc.tabbing.buf) (Im-gui.InputText ctx :3 misc.tabbing.buf))
      (Im-gui.PushAllowKeyboardFocus ctx false)
      (set (rv misc.tabbing.buf)
           (Im-gui.InputText ctx "4 (tab skip)" misc.tabbing.buf))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Item won't be cycled through when using TAB or Shift+Tab.")
      (Im-gui.PopAllowKeyboardFocus ctx)
      (set (rv misc.tabbing.buf) (Im-gui.InputText ctx :5 misc.tabbing.buf))
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx "Focus from code")
      (when (not misc.focus)
        (set misc.focus {:buf "click on a button to set focus" :d3 [0 0 0]}))
      (local focus-1 (Im-gui.Button ctx "Focus on 1"))
      (Im-gui.SameLine ctx)
      (local focus-2 (Im-gui.Button ctx "Focus on 2"))
      (Im-gui.SameLine ctx)
      (local focus-3 (Im-gui.Button ctx "Focus on 3"))
      (var has-focus 0)
      (when focus-1 (Im-gui.SetKeyboardFocusHere ctx))
      (set (rv misc.focus.buf) (Im-gui.InputText ctx :1 misc.focus.buf))
      (when (Im-gui.IsItemActive ctx) (set has-focus 1))
      (when focus-2 (Im-gui.SetKeyboardFocusHere ctx))
      (set (rv misc.focus.buf) (Im-gui.InputText ctx :2 misc.focus.buf))
      (when (Im-gui.IsItemActive ctx) (set has-focus 2))
      (Im-gui.PushAllowKeyboardFocus ctx false)
      (when focus-3 (Im-gui.SetKeyboardFocusHere ctx))
      (set (rv misc.focus.buf)
           (Im-gui.InputText ctx "3 (tab skip)" misc.focus.buf))
      (when (Im-gui.IsItemActive ctx) (set has-focus 3))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Item won't be cycled through when using TAB or Shift+Tab.")
      (Im-gui.PopAllowKeyboardFocus ctx)
      (if (> has-focus 0) (Im-gui.Text ctx
                                       (: "Item with focus: %d" :format
                                          has-focus))
          (Im-gui.Text ctx "Item with focus: <none>"))
      (var focus-ahead (- 1))
      (when (Im-gui.Button ctx "Focus on X") (set focus-ahead 0))
      (Im-gui.SameLine ctx)
      (when (Im-gui.Button ctx "Focus on Y") (set focus-ahead 1))
      (Im-gui.SameLine ctx)
      (when (Im-gui.Button ctx "Focus on Z") (set focus-ahead 2))
      (when (not= focus-ahead (- 1))
        (Im-gui.SetKeyboardFocusHere ctx focus-ahead))
      (set-forcibly! (rv d31 d32 d33)
                     (Im-gui.SliderDouble3 ctx :Float3 (. misc.focus.d3 1)
                                           (. misc.focus.d3 2)
                                           (. misc.focus.d3 3) 0 1))
      (tset misc.focus.d3 1 d31)
      (tset misc.focus.d3 2 d32)
      (tset misc.focus.d3 3 d33)
      (Im-gui.TextWrapped ctx
                          "NB: Cursor & selection are preserved when refocusing last used item in code.")
      (Im-gui.TreePop ctx))
    (when (Im-gui.TreeNode ctx :Dragging)
      (Im-gui.TextWrapped ctx
                          "You can use GetMouseDragDelta(0) to query for the dragged amount on any widget.")
      (for [button 0 2]
        (Im-gui.Text ctx (: "IsMouseDragging(%d):" :format button))
        (Im-gui.Text ctx
                     (: "  w/ default threshold: %s," :format
                        (Im-gui.IsMouseDragging ctx button)))
        (Im-gui.Text ctx
                     (: "  w/ zero threshold: %s," :format
                        (Im-gui.IsMouseDragging ctx button 0)))
        (Im-gui.Text ctx
                     (: "  w/ large threshold: %s," :format
                        (Im-gui.IsMouseDragging ctx button 20))))
      (Im-gui.Button ctx "Drag Me")
      (when (Im-gui.IsItemActive ctx)
        (local draw-list (Im-gui.GetForegroundDrawList ctx))
        (local mouse-pos [(Im-gui.GetMousePos ctx)])
        (local click-pos [(Im-gui.GetMouseClickedPos ctx 0)])
        (local color (Im-gui.GetColor ctx (Im-gui.Col_Button)))
        (Im-gui.DrawList_AddLine draw-list (. click-pos 1) (. click-pos 2)
                                 (. mouse-pos 1) (. mouse-pos 2) color 4))
      (local value-raw
             [(Im-gui.GetMouseDragDelta ctx 0 0 (Im-gui.MouseButton_Left) 0)])
      (local value-with-lock-threshold
             [(Im-gui.GetMouseDragDelta ctx 0 0 (Im-gui.MouseButton_Left))])
      (local mouse-delta [(Im-gui.GetMouseDelta ctx)])
      (Im-gui.Text ctx "GetMouseDragDelta(0):")
      (Im-gui.Text ctx
                   (: "  w/ default threshold: (%.1f, %.1f)" :format
                      (table.unpack value-with-lock-threshold)))
      (Im-gui.Text ctx (: "  w/ zero threshold: (%.1f, %.1f)" :format
                          (table.unpack value-raw)))
      (Im-gui.Text ctx (: "GetMouseDelta() (%.1f, %.1f)" :format
                          (table.unpack mouse-delta)))
      (Im-gui.TreePop ctx))))

(fn demo.GetStyleData []
  (let [data {:colors {} :vars {}}
        vec2 [:ButtonTextAlign
              :SelectableTextAlign
              :CellPadding
              :ItemSpacing
              :ItemInnerSpacing
              :FramePadding
              :WindowPadding
              :WindowMinSize
              :WindowTitleAlign
              :SeparatorTextAlign
              :SeparatorTextPadding]]
    (each [i name (demo.EachEnum :StyleVar)]
      (local rv [(Im-gui.GetStyleVar ctx i)])
      (var is-vec2 false)
      (each [_ vec2-name (ipairs vec2)]
        (when (= vec2-name name) (set is-vec2 true) (lua :break)))
      (tset data.vars i (or (and is-vec2 rv) (. rv 1))))
    (each [i (demo.EachEnum :Col)]
      (tset data.colors i (Im-gui.GetStyleColor ctx i)))
    data))

(fn demo.CopyStyleData [source target]
  (each [i value (pairs source.vars)]
    (if (= (type value) :table) (tset target.vars i [(table.unpack value)])
        (tset target.vars i value)))
  (each [i value (pairs source.colors)] (tset target.colors i value)))

(fn demo.PushStyle []
  (when app.style_editor
    (set app.style_editor.push_count (+ app.style_editor.push_count 1))
    (each [i value (pairs app.style_editor.style.vars)]
      (if (= (type value) :table)
          (Im-gui.PushStyleVar ctx i (table.unpack value))
          (Im-gui.PushStyleVar ctx i value)))
    (each [i value (pairs app.style_editor.style.colors)]
      (Im-gui.PushStyleColor ctx i value))))

(fn demo.PopStyle []
  (when (and app.style_editor (> app.style_editor.push_count 0))
    (set app.style_editor.push_count (- app.style_editor.push_count 1))
    (Im-gui.PopStyleColor ctx (length (. cache :Col)))
    (Im-gui.PopStyleVar ctx (length (. cache :StyleVar)))))

(fn demo.ShowStyleEditor []
  (var rv nil)
  (when (not app.style_editor)
    (set app.style_editor
         {:output_dest 0
          :output_only_modified true
          :push_count 0
          :ref (demo.GetStyleData)
          :style (demo.GetStyleData)}))
  (Im-gui.PushItemWidth ctx (* (Im-gui.GetWindowWidth ctx) 0.5))
  (local (Frame-rounding Grab-rounding)
         (values (Im-gui.StyleVar_FrameRounding) (Im-gui.StyleVar_GrabRounding)))
  (set-forcibly! (rv vfr)
                 (Im-gui.SliderDouble ctx :FrameRounding
                                      (. app.style_editor.style.vars
                                         Frame-rounding)
                                      0 12 "%.0f"))
  (tset app.style_editor.style.vars Frame-rounding vfr)
  (when rv
    (tset app.style_editor.style.vars Grab-rounding
          (. app.style_editor.style.vars Frame-rounding)))
  (local borders [:WindowBorder :FrameBorder :PopupBorder])
  (each [i name (ipairs borders)]
    (local ___var___ ((. Im-gui (: "StyleVar_%sSize" :format name))))
    (var enable (> (. app.style_editor.style.vars ___var___) 0))
    (when (> i 1) (Im-gui.SameLine ctx))
    (set (rv enable) (Im-gui.Checkbox ctx name enable))
    (when rv
      (tset app.style_editor.style.vars ___var___ (or (and enable 1) 0))))
  (when (Im-gui.Button ctx "Save Ref")
    (demo.CopyStyleData app.style_editor.style app.style_editor.ref))
  (Im-gui.SameLine ctx)
  (when (Im-gui.Button ctx "Revert Ref")
    (demo.CopyStyleData app.style_editor.ref app.style_editor.style))
  (Im-gui.SameLine ctx)
  (demo.HelpMarker "Save/Revert in local non-persistent storage. Default Colors definition are not affected. Use \"Export\" below to save them somewhere.")

  (fn export [enum-name func-suffix cur-table ref-table is-equal format-value]
    (var (lines name-maxlen) (values {} 0))
    (each [i name (demo.EachEnum enum-name)]
      (when (or (not app.style_editor.output_only_modified)
                (not (is-equal (. cur-table i) (. ref-table i))))
        (table.insert lines [name (. cur-table i)])
        (set name-maxlen (math.max name-maxlen (name:len)))))
    (if (= app.style_editor.output_dest 0) (Im-gui.LogToClipboard ctx)
        (Im-gui.LogToTTY ctx))
    (each [_ line (ipairs lines)]
      (local pad (string.rep " " (- name-maxlen (: (. line 1) :len))))
      (Im-gui.LogText ctx
                      (: "ImGui.Push%s(ctx, ImGui.%s_%s(),%s %s)\n" :format
                         func-suffix enum-name (. line 1) pad
                         (format-value (. line 2)))))
    (if (= (length lines) 1)
        (Im-gui.LogText ctx (: "\nImGui.Pop%s(ctx)\n" :format func-suffix))
        (> (length lines) 1)
        (Im-gui.LogText ctx (: "\nImGui.Pop%s(ctx, %d)\n" :format func-suffix
                               (length lines))))
    (Im-gui.LogFinish ctx))

  (when (Im-gui.Button ctx "Export Vars")
    (export :StyleVar :StyleVar app.style_editor.style.vars
            app.style_editor.ref.vars
            (fn [a b]
              (if (= (type a) :table)
                  (and (= (. a 1) (. b 1)) (= (. a 2) (. b 2))) (= a b)))
            (fn [val]
              (if (= (type val) :table) (: "%g, %g" :format (table.unpack val))
                  (: "%g" :format val)))))
  (Im-gui.SameLine ctx)
  (when (Im-gui.Button ctx "Export Colors")
    (export :Col :StyleColor app.style_editor.style.colors
            app.style_editor.ref.colors (fn [a b] (= a b))
            (fn [val] (: "0x%08X" :format (band val 4294967295)))))
  (Im-gui.SameLine ctx)
  (Im-gui.SetNextItemWidth ctx 120)
  (set (rv app.style_editor.output_dest)
       (Im-gui.Combo ctx "##output_type" app.style_editor.output_dest
                     "To Clipboard\000To TTY\000"))
  (Im-gui.SameLine ctx)
  (set (rv app.style_editor.output_only_modified)
       (Im-gui.Checkbox ctx "Only Modified"
                        app.style_editor.output_only_modified))
  (Im-gui.Separator ctx)
  (when (Im-gui.BeginTabBar ctx "##tabs" (Im-gui.TabBarFlags_None))
    (when (Im-gui.BeginTabItem ctx :Sizes)
      (fn slider [varname min max format]
        (let [func (. Im-gui (.. :StyleVar_ varname))]
          (assert func (: "%s is not exposed as a StyleVar" :format varname))
          (local ___var___ (func))
          (if (= (type (. app.style_editor.style.vars ___var___)) :table)
              (let [(rv val1 val2) (Im-gui.SliderDouble2 ctx varname
                                                         (. (. app.style_editor.style.vars
                                                               ___var___)
                                                            1)
                                                         (. (. app.style_editor.style.vars
                                                               ___var___)
                                                            2)
                                                         min max format)]
                (when rv
                  (tset app.style_editor.style.vars ___var___ [val1 val2])))
              (let [(rv val) (Im-gui.SliderDouble ctx varname
                                                  (. app.style_editor.style.vars
                                                     ___var___)
                                                  min max format)]
                (when rv (tset app.style_editor.style.vars ___var___ val))))))

      (Im-gui.SeparatorText ctx :Main)
      (slider :WindowPadding 0 20 "%.0f")
      (slider :FramePadding 0 20 "%.0f")
      (slider :CellPadding 0 20 "%.0f")
      (slider :ItemSpacing 0 20 "%.0f")
      (slider :ItemInnerSpacing 0 20 "%.0f")
      (slider :IndentSpacing 0 30 "%.0f")
      (slider :ScrollbarSize 1 20 "%.0f")
      (slider :GrabMinSize 1 20 "%.0f")
      (Im-gui.SeparatorText ctx :Borders)
      (slider :WindowBorderSize 0 1 "%.0f")
      (slider :ChildBorderSize 0 1 "%.0f")
      (slider :PopupBorderSize 0 1 "%.0f")
      (slider :FrameBorderSize 0 1 "%.0f")
      (Im-gui.SeparatorText ctx :Rounding)
      (slider :WindowRounding 0 12 "%.0f")
      (slider :ChildRounding 0 12 "%.0f")
      (slider :FrameRounding 0 12 "%.0f")
      (slider :PopupRounding 0 12 "%.0f")
      (slider :ScrollbarRounding 0 12 "%.0f")
      (slider :GrabRounding 0 12 "%.0f")
      (slider :TabRounding 0 12 "%.0f")
      (Im-gui.SeparatorText ctx :Widgets)
      (slider :WindowTitleAlign 0 1 "%.2f")
      (slider :ButtonTextAlign 0 1 "%.2f")
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Alignment applies when a button is larger than its text content.")
      (slider :SelectableTextAlign 0 1 "%.2f")
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Alignment applies when a selectable is larger than its text content.")
      (slider :SeparatorTextBorderSize 0 10 "%.0f")
      (slider :SeparatorTextAlign 0 1 "%.2f")
      (slider :SeparatorTextPadding 0 40 "%.0f")
      (Im-gui.EndTabItem ctx))
    (when (Im-gui.BeginTabItem ctx :Colors)
      (when (not app.style_editor.colors)
        (set app.style_editor.colors
             {:alpha_flags (Im-gui.ColorEditFlags_None)
              :filter {:inst nil :text ""}}))
      (when (not (Im-gui.ValidatePtr app.style_editor.colors.filter.inst
                                     :ImGui_TextFilter*))
        (set app.style_editor.colors.filter.inst
             (Im-gui.CreateTextFilter app.style_editor.colors.filter.text)))
      (when (Im-gui.TextFilter_Draw app.style_editor.colors.filter.inst ctx
                                    "Filter colors"
                                    (* (Im-gui.GetFontSize ctx) 16))
        (set app.style_editor.colors.filter.text
             (Im-gui.TextFilter_Get app.style_editor.colors.filter.inst)))
      (when (Im-gui.RadioButton ctx :Opaque
                                (= app.style_editor.colors.alpha_flags
                                   (Im-gui.ColorEditFlags_None)))
        (set app.style_editor.colors.alpha_flags (Im-gui.ColorEditFlags_None)))
      (Im-gui.SameLine ctx)
      (when (Im-gui.RadioButton ctx :Alpha
                                (= app.style_editor.colors.alpha_flags
                                   (Im-gui.ColorEditFlags_AlphaPreview)))
        (set app.style_editor.colors.alpha_flags
             (Im-gui.ColorEditFlags_AlphaPreview)))
      (Im-gui.SameLine ctx)
      (when (Im-gui.RadioButton ctx :Both
                                (= app.style_editor.colors.alpha_flags
                                   (Im-gui.ColorEditFlags_AlphaPreviewHalf)))
        (set app.style_editor.colors.alpha_flags
             (Im-gui.ColorEditFlags_AlphaPreviewHalf)))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "In the color list:
Left-click on color square to open color picker,
Right-click to open edit options menu.")
      (when (Im-gui.BeginChild ctx "##colors" 0 0 true
                               (bor (Im-gui.WindowFlags_AlwaysVerticalScrollbar)
                                    (Im-gui.WindowFlags_AlwaysHorizontalScrollbar)
                                    0))
        (Im-gui.PushItemWidth ctx (- 160))
        (local inner-spacing
               (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemInnerSpacing)))
        (each [i name (demo.EachEnum :Col)]
          (when (Im-gui.TextFilter_PassFilter app.style_editor.colors.filter.inst
                                              name)
            (Im-gui.PushID ctx i)
            (set-forcibly! (rv ci)
                           (Im-gui.ColorEdit4 ctx "##color"
                                              (. app.style_editor.style.colors
                                                 i)
                                              (bor (Im-gui.ColorEditFlags_AlphaBar)
                                                   app.style_editor.colors.alpha_flags)))
            (tset app.style_editor.style.colors i ci)
            (when (not= (. app.style_editor.style.colors i)
                        (. app.style_editor.ref.colors i))
              (Im-gui.SameLine ctx 0 inner-spacing)
              (when (Im-gui.Button ctx :Save)
                (tset app.style_editor.ref.colors i
                      (. app.style_editor.style.colors i)))
              (Im-gui.SameLine ctx 0 inner-spacing)
              (when (Im-gui.Button ctx :Revert)
                (tset app.style_editor.style.colors i
                      (. app.style_editor.ref.colors i))))
            (Im-gui.SameLine ctx 0 inner-spacing)
            (Im-gui.Text ctx name)
            (Im-gui.PopID ctx)))
        (Im-gui.PopItemWidth ctx)
        (Im-gui.EndChild ctx))
      (Im-gui.EndTabItem ctx))
    (when (Im-gui.BeginTabItem ctx :Rendering)
      (Im-gui.PushItemWidth ctx (* (Im-gui.GetFontSize ctx) 8))
      (local (Alpha Disabled-alpha)
             (values (Im-gui.StyleVar_Alpha) (Im-gui.StyleVar_DisabledAlpha)))
      (set-forcibly! (rv v-a)
                     (Im-gui.DragDouble ctx "Global Alpha"
                                        (. app.style_editor.style.vars Alpha)
                                        0.005 0.2 1 "%.2f"))
      (tset app.style_editor.style.vars Alpha v-a)
      (set-forcibly! (rv v-dA)
                     (Im-gui.DragDouble ctx "Disabled Alpha"
                                        (. app.style_editor.style.vars
                                           Disabled-alpha)
                                        0.005 0 1 "%.2f"))
      (tset app.style_editor.style.vars Disabled-alpha v-dA)
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "Additional alpha multiplier for disabled items (multiply over current value of Alpha).")
      (Im-gui.PopItemWidth ctx)
      (Im-gui.EndTabItem ctx))
    (Im-gui.EndTabBar ctx))
  (Im-gui.PopItemWidth ctx))

(fn demo.ShowUserGuide []
  (Im-gui.BulletText ctx "Double-click on title bar to collapse window.")
  (Im-gui.BulletText ctx "Click and drag on lower corner to resize window
(double-click to auto fit window to its contents).")
  (Im-gui.BulletText ctx
                     "CTRL+Click on a slider or drag box to input value as text.")
  (Im-gui.BulletText ctx
                     "TAB/SHIFT+TAB to cycle through keyboard editable fields.")
  (Im-gui.BulletText ctx "CTRL+Tab to select a window.")
  (Im-gui.BulletText ctx "While inputing text:\n")
  (Im-gui.Indent ctx)
  (Im-gui.BulletText ctx "CTRL+Left/Right to word jump.")
  (Im-gui.BulletText ctx "CTRL+A or double-click to select all.")
  (Im-gui.BulletText ctx "CTRL+X/C/V to use clipboard cut/copy/paste.")
  (Im-gui.BulletText ctx "CTRL+Z,CTRL+Y to undo/redo.")
  (Im-gui.BulletText ctx "ESCAPE to revert.")
  (Im-gui.Unindent ctx)
  (Im-gui.BulletText ctx "With keyboard navigation enabled:")
  (Im-gui.Indent ctx)
  (Im-gui.BulletText ctx "Arrow keys to navigate.")
  (Im-gui.BulletText ctx "Space to activate a widget.")
  (Im-gui.BulletText ctx "Return to input text into a widget.")
  (Im-gui.BulletText ctx
                     "Escape to deactivate a widget, close popup, exit child window.")
  (Im-gui.BulletText ctx "Alt to jump to the menu layer of a window.")
  (Im-gui.Unindent ctx))

(fn demo.ShowExampleMenuFile []
  (var rv nil)
  (Im-gui.MenuItem ctx "(demo menu)" nil false false)
  (when (Im-gui.MenuItem ctx :New) nil)
  (when (Im-gui.MenuItem ctx :Open :Ctrl+O) nil)
  (when (Im-gui.BeginMenu ctx "Open Recent")
    (Im-gui.MenuItem ctx :fish_hat.c)
    (Im-gui.MenuItem ctx :fish_hat.inl)
    (Im-gui.MenuItem ctx :fish_hat.h)
    (when (Im-gui.BeginMenu ctx :More..) (Im-gui.MenuItem ctx :Hello)
      (Im-gui.MenuItem ctx :Sailor)
      (when (Im-gui.BeginMenu ctx :Recurse..) (demo.ShowExampleMenuFile)
        (Im-gui.EndMenu ctx))
      (Im-gui.EndMenu ctx))
    (Im-gui.EndMenu ctx))
  (when (Im-gui.MenuItem ctx :Save :Ctrl+S) nil)
  (when (Im-gui.MenuItem ctx "Save As..") nil)
  (Im-gui.Separator ctx)
  (when (Im-gui.BeginMenu ctx :Options)
    (set (rv demo.menu.enabled)
         (Im-gui.MenuItem ctx :Enabled "" demo.menu.enabled))
    (when (Im-gui.BeginChild ctx :child 0 60 true)
      (for [i 0 9] (Im-gui.Text ctx (: "Scrolling Text %d" :format i)))
      (Im-gui.EndChild ctx))
    (set (rv demo.menu.f) (Im-gui.SliderDouble ctx :Value demo.menu.f 0 1))
    (set (rv demo.menu.f) (Im-gui.InputDouble ctx :Input demo.menu.f 0.1))
    (set (rv demo.menu.n)
         (Im-gui.Combo ctx :Combo demo.menu.n "Yes\000No\000Maybe\000"))
    (Im-gui.EndMenu ctx))
  (when (Im-gui.BeginMenu ctx :Colors)
    (local sz (Im-gui.GetTextLineHeight ctx))
    (local draw-list (Im-gui.GetWindowDrawList ctx))
    (each [i name (demo.EachEnum :Col)]
      (local (x y) (Im-gui.GetCursorScreenPos ctx))
      (Im-gui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz)
                                     (Im-gui.GetColor ctx i))
      (Im-gui.Dummy ctx sz sz)
      (Im-gui.SameLine ctx)
      (Im-gui.MenuItem ctx name))
    (Im-gui.EndMenu ctx))
  (when (Im-gui.BeginMenu ctx :Options)
    (set (rv demo.menu.b) (Im-gui.Checkbox ctx :SomeOption demo.menu.b))
    (Im-gui.EndMenu ctx))
  (when (Im-gui.BeginMenu ctx :Disabled false) (error "never called"))
  (when (Im-gui.MenuItem ctx :Checked nil true) nil)
  (Im-gui.Separator ctx)
  (when (Im-gui.MenuItem ctx :Quit :Alt+F4) nil))

(local Example-app-log {})

(fn Example-app-log.new [self ctx]
  (let [instance {:auto_scroll true
                  : ctx
                  :filter {:inst nil :text ""}
                  :lines {}}]
    (set self.__index self)
    (setmetatable instance self)))

(fn Example-app-log.clear [self] (set self.lines {}))

(fn Example-app-log.add_log [self fmt ...]
  (let [text (fmt:format ...)]
    (each [line (text:gmatch "[^\r\n]+")] (table.insert self.lines line))))

(fn Example-app-log.draw [self title p-open]
  (var (rv p-open) (Im-gui.Begin self.ctx title p-open))
  (when (not rv)
    (let [___antifnl_rtn_1___ p-open] (lua "return ___antifnl_rtn_1___")))
  (when (not (Im-gui.ValidatePtr self.filter.inst :ImGui_TextFilter*))
    (set self.filter.inst (Im-gui.CreateTextFilter self.filter.text)))
  (when (Im-gui.BeginPopup self.ctx :Options)
    (set (rv self.auto_scroll)
         (Im-gui.Checkbox self.ctx :Auto-scroll self.auto_scroll))
    (Im-gui.EndPopup self.ctx))
  (when (Im-gui.Button self.ctx :Options) (Im-gui.OpenPopup self.ctx :Options))
  (Im-gui.SameLine self.ctx)
  (local clear (Im-gui.Button self.ctx :Clear))
  (Im-gui.SameLine self.ctx)
  (local copy (Im-gui.Button self.ctx :Copy))
  (Im-gui.SameLine self.ctx)
  (when (Im-gui.TextFilter_Draw self.filter.inst ctx :Filter (- 100))
    (set self.filter.text (Im-gui.TextFilter_Get self.filter.inst)))
  (Im-gui.Separator self.ctx)
  (when (Im-gui.BeginChild self.ctx :scrolling 0 0 false
                           (Im-gui.WindowFlags_HorizontalScrollbar))
    (when clear (self:clear))
    (when copy (Im-gui.LogToClipboard self.ctx))
    (Im-gui.PushStyleVar self.ctx (Im-gui.StyleVar_ItemSpacing) 0 0)
    (if (Im-gui.TextFilter_IsActive self.filter.inst)
        (each [line-no line (ipairs self.lines)]
          (when (Im-gui.TextFilter_PassFilter self.filter.inst line)
            (Im-gui.Text ctx line)))
        (let [clipper (Im-gui.CreateListClipper self.ctx)]
          (Im-gui.ListClipper_Begin clipper (length self.lines))
          (while (Im-gui.ListClipper_Step clipper)
            (local (display-start display-end)
                   (Im-gui.ListClipper_GetDisplayRange clipper))
            (for [line-no display-start (- display-end 1)]
              (Im-gui.Text self.ctx (. self.lines (+ line-no 1)))))
          (Im-gui.ListClipper_End clipper)))
    (Im-gui.PopStyleVar self.ctx)
    (when (and self.auto_scroll
               (>= (Im-gui.GetScrollY self.ctx) (Im-gui.GetScrollMaxY self.ctx)))
      (Im-gui.SetScrollHereY self.ctx 1))
    (Im-gui.EndChild self.ctx))
  (Im-gui.End self.ctx)
  p-open)

(fn demo.ShowExampleAppLog []
  (when (not app.log) (set app.log (Example-app-log:new ctx))
    (set app.log.counter 0))
  (Im-gui.SetNextWindowSize ctx 500 400 (Im-gui.Cond_FirstUseEver))
  (local (rv open) (Im-gui.Begin ctx "Example: Log" true))
  (when (not rv) (lua "return open"))
  (when (Im-gui.SmallButton ctx "[Debug] Add 5 entries")
    (local categories [:info :warn :error])
    (local words [:Bumfuzzled
                  :Cattywampus
                  :Snickersnee
                  :Abibliophobia
                  :Absquatulate
                  :Nincompoop
                  :Pauciloquent])
    (for [n 0 (- 5 1)]
      (local category (. categories (+ (% app.log.counter (length categories))
                                       1)))
      (local word (. words (+ (% app.log.counter (length words)) 1)))
      (app.log:add_log "[%05d] [%s] Hello, current time is %.1f, here's a word: '%s'
" (Im-gui.GetFrameCount ctx) category
                       (Im-gui.GetTime ctx) word)
      (set app.log.counter (+ app.log.counter 1))))
  (Im-gui.End ctx)
  (app.log:draw "Example: Log")
  open)

(fn demo.ShowExampleAppLayout []
  (when (not app.layout) (set app.layout {:selected 0}))
  (Im-gui.SetNextWindowSize ctx 500 440 (Im-gui.Cond_FirstUseEver))
  (var (rv open) (Im-gui.Begin ctx "Example: Simple layout" true
                               (Im-gui.WindowFlags_MenuBar)))
  (when (not rv) (lua "return open"))
  (when (Im-gui.BeginMenuBar ctx)
    (when (Im-gui.BeginMenu ctx :File)
      (when (Im-gui.MenuItem ctx :Close :Ctrl+W) (set open false))
      (Im-gui.EndMenu ctx))
    (Im-gui.EndMenuBar ctx))
  (when (Im-gui.BeginChild ctx "left pane" 150 0 true)
    (for [i 0 (- 100 1)]
      (when (Im-gui.Selectable ctx (: "MyObject %d" :format i)
                               (= app.layout.selected i))
        (set app.layout.selected i)))
    (Im-gui.EndChild ctx))
  (Im-gui.SameLine ctx)
  (Im-gui.BeginGroup ctx)
  (when (Im-gui.BeginChild ctx "item view" 0
                           (- (Im-gui.GetFrameHeightWithSpacing ctx)))
    (Im-gui.Text ctx (: "MyObject: %d" :format app.layout.selected))
    (Im-gui.Separator ctx)
    (when (Im-gui.BeginTabBar ctx "##Tabs" (Im-gui.TabBarFlags_None))
      (when (Im-gui.BeginTabItem ctx :Description)
        (Im-gui.TextWrapped ctx
                            "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ")
        (Im-gui.EndTabItem ctx))
      (when (Im-gui.BeginTabItem ctx :Details)
        (Im-gui.Text ctx "ID: 0123456789")
        (Im-gui.EndTabItem ctx))
      (Im-gui.EndTabBar ctx))
    (Im-gui.EndChild ctx))
  (when (Im-gui.Button ctx :Revert) nil)
  (Im-gui.SameLine ctx)
  (when (Im-gui.Button ctx :Save) nil)
  (Im-gui.EndGroup ctx)
  (Im-gui.End ctx)
  open)

(fn demo.ShowPlaceholderObject [prefix uid]
  (let [rv nil]
    (Im-gui.PushID ctx uid)
    (Im-gui.TableNextRow ctx)
    (Im-gui.TableSetColumnIndex ctx 0)
    (Im-gui.AlignTextToFramePadding ctx)
    (local node-open
           (Im-gui.TreeNodeEx ctx :Object (: "%s_%u" :format prefix uid)))
    (Im-gui.TableSetColumnIndex ctx 1)
    (Im-gui.Text ctx "my sailor is rich")
    (when node-open
      (for [i 0 (- (length app.property_editor.placeholder_members) 1)]
        (Im-gui.PushID ctx i)
        (if (< i 2) (demo.ShowPlaceholderObject :Child 424242)
            (do
              (Im-gui.TableNextRow ctx)
              (Im-gui.TableSetColumnIndex ctx 0)
              (Im-gui.AlignTextToFramePadding ctx)
              (local flags
                     (bor (Im-gui.TreeNodeFlags_Leaf)
                          (Im-gui.TreeNodeFlags_NoTreePushOnOpen)
                          (Im-gui.TreeNodeFlags_Bullet)))
              (Im-gui.TreeNodeEx ctx :Field (: "Field_%d" :format i) flags)
              (Im-gui.TableSetColumnIndex ctx 1)
              (Im-gui.SetNextItemWidth ctx (- FLT_MIN))
              (if (>= i 5) (do
                             (set-forcibly! (rv pmi)
                                            (Im-gui.InputDouble ctx "##value"
                                                                (. app.property_editor.placeholder_members
                                                                   i)
                                                                1))
                             (tset app.property_editor.placeholder_members i
                                   pmi))
                  (do
                    (set-forcibly! (rv pmi)
                                   (Im-gui.DragDouble ctx "##value"
                                                      (. app.property_editor.placeholder_members
                                                         i)
                                                      0.01))
                    (tset app.property_editor.placeholder_members i pmi)))))
        (Im-gui.PopID ctx))
      (Im-gui.TreePop ctx))
    (Im-gui.PopID ctx)))

(fn demo.ShowExampleAppPropertyEditor []
  (when (not app.property_editor)
    (set app.property_editor {:placeholder_members [0 0 1 3.1416 100 999 0 0]}))
  (Im-gui.SetNextWindowSize ctx 430 450 (Im-gui.Cond_FirstUseEver))
  (local (rv open) (Im-gui.Begin ctx "Example: Property editor" true))
  (when (not rv) (lua "return open"))
  (demo.HelpMarker "This example shows how you may implement a property editor using two columns.
All objects/fields data are dummies here.
Remember that in many simple cases, you can use ImGui.SameLine(xxx) to position
your cursor horizontally instead of using the Columns() API.")
  (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_FramePadding) 2 2)
  (when (Im-gui.BeginTable ctx :split 2
                           (bor (Im-gui.TableFlags_BordersOuter)
                                (Im-gui.TableFlags_Resizable)))
    (for [obj-i 0 (- 4 1)] (demo.ShowPlaceholderObject :Object obj-i))
    (Im-gui.EndTable ctx))
  (Im-gui.PopStyleVar ctx)
  (Im-gui.End ctx)
  open)

(fn demo.ShowExampleAppLongText []
  (when (not app.long_text) (set app.long_text {:lines 0 :log "" :test_type 0}))
  (Im-gui.SetNextWindowSize ctx 520 600 (Im-gui.Cond_FirstUseEver))
  (var (rv open) (Im-gui.Begin ctx "Example: Long text display" true))
  (when (not rv) (lua "return open"))
  (Im-gui.Text ctx "Printing unusually long amount of text.")
  (set (rv app.long_text.test_type)
       (Im-gui.Combo ctx "Test type" app.long_text.test_type
                     "Single call to Text()\000Multiple calls to Text(), clipped\000Multiple calls to Text(), not clipped (slow)\000"))
  (Im-gui.Text ctx
               (: "Buffer contents: %d lines, %d bytes" :format
                  app.long_text.lines (app.long_text.log:len)))
  (when (Im-gui.Button ctx :Clear) (set app.long_text.log "")
    (set app.long_text.lines 0))
  (Im-gui.SameLine ctx)
  (when (Im-gui.Button ctx "Add 1000 lines")
    (var new-lines "")
    (for [i 0 (- 1000 1)]
      (set new-lines (.. new-lines (: "%i The quick brown fox jumps over the lazy dog
" :format (+ app.long_text.lines i)))))
    (set app.long_text.log (.. app.long_text.log new-lines))
    (set app.long_text.lines (+ app.long_text.lines 1000)))
  (when (Im-gui.BeginChild ctx :Log)
    (if (= app.long_text.test_type 0) (Im-gui.Text ctx app.long_text.log)
        (= app.long_text.test_type 1)
        (do
          (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_ItemSpacing) 0 0)
          (local clipper (Im-gui.CreateListClipper ctx))
          (Im-gui.ListClipper_Begin clipper app.long_text.lines)
          (while (Im-gui.ListClipper_Step clipper)
            (local (display-start display-end)
                   (Im-gui.ListClipper_GetDisplayRange clipper))
            (for [i display-start (- display-end 1)]
              (Im-gui.Text ctx (: "%i The quick brown fox jumps over the lazy dog"
                                  :format i))))
          (Im-gui.PopStyleVar ctx)) (= app.long_text.test_type 2)
        (do
          (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_ItemSpacing) 0 0)
          (for [i 0 app.long_text.lines]
            (Im-gui.Text ctx (: "%i The quick brown fox jumps over the lazy dog"
                                :format i)))
          (Im-gui.PopStyleVar ctx)))
    (Im-gui.EndChild ctx))
  (Im-gui.End ctx)
  open)

(fn demo.ShowExampleAppAutoResize []
  (when (not app.auto_resize) (set app.auto_resize {:lines 10}))
  (var (rv open)
       (Im-gui.Begin ctx "Example: Auto-resizing window" true
                     (Im-gui.WindowFlags_AlwaysAutoResize)))
  (when (not rv) (lua "return open"))
  (Im-gui.Text ctx
               "Window will resize every-frame to the size of its content.
Note that you probably don't want to query the window size to
output your content because that would create a feedback loop.")
  (set (rv app.auto_resize.lines)
       (Im-gui.SliderInt ctx "Number of lines" app.auto_resize.lines 1 20))
  (for [i 1 app.auto_resize.lines]
    (Im-gui.Text ctx (: "%sThis is line %d" :format (: " " :rep (* i 4)) i)))
  (Im-gui.End ctx)
  open)

(fn demo.ShowExampleAppConstrainedResize []
  (when (not app.constrained_resize)
    (set app.constrained_resize
         {:auto_resize false :display_lines 10 :type 0 :window_padding true}))
  (when (= app.constrained_resize.type 0)
    (Im-gui.SetNextWindowSizeConstraints ctx 100 100 500 500))
  (when (= app.constrained_resize.type 1)
    (Im-gui.SetNextWindowSizeConstraints ctx 100 100 FLT_MAX FLT_MAX))
  (when (= app.constrained_resize.type 2)
    (Im-gui.SetNextWindowSizeConstraints ctx (- 1) 0 (- 1) FLT_MAX))
  (when (= app.constrained_resize.type 3)
    (Im-gui.SetNextWindowSizeConstraints ctx 0 (- 1) FLT_MAX (- 1)))
  (when (= app.constrained_resize.type 4)
    (Im-gui.SetNextWindowSizeConstraints ctx 400 (- 1) 500 (- 1)))
  (when (not app.constrained_resize.window_padding)
    (Im-gui.PushStyleVar ctx (Im-gui.StyleVar_WindowPadding) 0 0))
  (local window-flags (or (and app.constrained_resize.auto_resize
                               (Im-gui.WindowFlags_AlwaysAutoResize))
                          0))
  (local (visible open) (Im-gui.Begin ctx "Example: Constrained Resize" true
                                      window-flags))
  (when (not app.constrained_resize.window_padding) (Im-gui.PopStyleVar ctx))
  (when (not visible) (lua "return open"))
  (if (Im-gui.IsKeyDown ctx (Im-gui.Mod_Shift))
      (let [(avail-size-w avail-size-h) (Im-gui.GetContentRegionAvail ctx)
            (pos-x pos-y) (Im-gui.GetCursorScreenPos ctx)]
        (Im-gui.ColorButton ctx :viewport 2134081535
                            (bor (Im-gui.ColorEditFlags_NoTooltip)
                                 (Im-gui.ColorEditFlags_NoDragDrop))
                            avail-size-w avail-size-h)
        (Im-gui.SetCursorScreenPos ctx (+ pos-x 10) (+ pos-y 10))
        (Im-gui.Text ctx (: "%.2f x %.2f" :format avail-size-w avail-size-h)))
      (do
        (Im-gui.Text ctx "(Hold SHIFT to display a dummy viewport)")
        (when (Im-gui.IsWindowDocked ctx)
          (Im-gui.Text ctx
                       "Warning: Sizing Constraints won't work if the window is docked!"))
        (when (Im-gui.Button ctx "Set 200x200")
          (Im-gui.SetWindowSize ctx 200 200))
        (Im-gui.SameLine ctx)
        (when (Im-gui.Button ctx "Set 500x500")
          (Im-gui.SetWindowSize ctx 500 500))
        (Im-gui.SameLine ctx)
        (when (Im-gui.Button ctx "Set 800x200")
          (Im-gui.SetWindowSize ctx 800 200))
        (Im-gui.SetNextItemWidth ctx (* (Im-gui.GetFontSize ctx) 20))
        (set-forcibly! (rv app.constrained_resize.type)
                       (Im-gui.Combo ctx :Constraint
                                     app.constrained_resize.type
                                     "Between 100x100 and 500x500\000At least 100x100\000Resize vertical only\000Resize horizontal only\000Width Between 400 and 500\000"))
        (Im-gui.SetNextItemWidth ctx (* (Im-gui.GetFontSize ctx) 20))
        (set-forcibly! (rv app.constrained_resize.display_lines)
                       (Im-gui.DragInt ctx :Lines
                                       app.constrained_resize.display_lines 0.2
                                       1 100))
        (set-forcibly! (rv app.constrained_resize.auto_resize)
                       (Im-gui.Checkbox ctx :Auto-resize
                                        app.constrained_resize.auto_resize))
        (set-forcibly! (rv app.constrained_resize.window_padding)
                       (Im-gui.Checkbox ctx "Window padding"
                                        app.constrained_resize.window_padding))
        (for [i 1 app.constrained_resize.display_lines]
          (Im-gui.Text ctx
                       (: "%sHello, sailor! Making this line long enough for the example."
                          :format (: " " :rep (* i 4)))))))
  (Im-gui.End ctx)
  open)

(fn demo.ShowExampleAppSimpleOverlay []
  (when (not app.simple_overlay) (set app.simple_overlay {:location 0}))
  (var window-flags (bor (Im-gui.WindowFlags_NoDecoration)
                         (Im-gui.WindowFlags_NoDocking)
                         (Im-gui.WindowFlags_AlwaysAutoResize)
                         (Im-gui.WindowFlags_NoSavedSettings)
                         (Im-gui.WindowFlags_NoFocusOnAppearing)
                         (Im-gui.WindowFlags_NoNav)))
  (if (>= app.simple_overlay.location 0)
      (let [PAD 10
            viewport (Im-gui.GetMainViewport ctx)
            (work-pos-x work-pos-y) (Im-gui.Viewport_GetWorkPos viewport)
            (work-size-w work-size-h) (Im-gui.Viewport_GetWorkSize viewport)]
        (var (window-pos-x window-pos-y window-pos-pivot-x window-pos-pivot-y)
             nil)
        (set window-pos-x (or (and (not= (band app.simple_overlay.location 1) 0)
                                   (- (+ work-pos-x work-size-w) PAD))
                              (+ work-pos-x PAD)))
        (set window-pos-y (or (and (not= (band app.simple_overlay.location 2) 0)
                                   (- (+ work-pos-y work-size-h) PAD))
                              (+ work-pos-y PAD)))
        (set window-pos-pivot-x (or (and (not= (band app.simple_overlay.location
                                                     1)
                                               0)
                                         1)
                                    0))
        (set window-pos-pivot-y (or (and (not= (band app.simple_overlay.location
                                                     2)
                                               0)
                                         1)
                                    0))
        (Im-gui.SetNextWindowPos ctx window-pos-x window-pos-y
                                 (Im-gui.Cond_Always) window-pos-pivot-x
                                 window-pos-pivot-y)
        (set window-flags (bor window-flags (Im-gui.WindowFlags_NoMove))))
      (= app.simple_overlay.location (- 2))
      (let [(center-x center-y) (Im-gui.Viewport_GetCenter (Im-gui.GetMainViewport ctx))]
        (Im-gui.SetNextWindowPos ctx center-x center-y (Im-gui.Cond_Always) 0.5
                                 0.5)
        (set window-flags (bor window-flags (Im-gui.WindowFlags_NoMove)))))
  (Im-gui.SetNextWindowBgAlpha ctx 0.35)
  (var (rv open) (Im-gui.Begin ctx "Example: Simple overlay" true window-flags))
  (when (not rv) (lua "return open"))
  (Im-gui.Text ctx "Simple overlay\n(right-click to change position)")
  (Im-gui.Separator ctx)
  (if (Im-gui.IsMousePosValid ctx)
      (Im-gui.Text ctx (: "Mouse Position: (%.1f,%.1f)" :format
                          (Im-gui.GetMousePos ctx)))
      (Im-gui.Text ctx "Mouse Position: <invalid>"))
  (when (Im-gui.BeginPopupContextWindow ctx)
    (when (Im-gui.MenuItem ctx :Custom nil
                           (= app.simple_overlay.location (- 1)))
      (set app.simple_overlay.location (- 1)))
    (when (Im-gui.MenuItem ctx :Center nil
                           (= app.simple_overlay.location (- 2)))
      (set app.simple_overlay.location (- 2)))
    (when (Im-gui.MenuItem ctx :Top-left nil (= app.simple_overlay.location 0))
      (set app.simple_overlay.location 0))
    (when (Im-gui.MenuItem ctx :Top-right nil (= app.simple_overlay.location 1))
      (set app.simple_overlay.location 1))
    (when (Im-gui.MenuItem ctx :Bottom-left nil
                           (= app.simple_overlay.location 2))
      (set app.simple_overlay.location 2))
    (when (Im-gui.MenuItem ctx :Bottom-right nil
                           (= app.simple_overlay.location 3))
      (set app.simple_overlay.location 3))
    (when (Im-gui.MenuItem ctx :Close) (set open false))
    (Im-gui.EndPopup ctx))
  (Im-gui.End ctx)
  open)

(fn demo.ShowExampleAppFullscreen []
  (when (not app.fullscreen)
    (set app.fullscreen {:flags (bor (Im-gui.WindowFlags_NoDecoration)
                                     (Im-gui.WindowFlags_NoMove)
                                     (Im-gui.WindowFlags_NoSavedSettings))
                         :use_work_area true}))
  (local viewport (Im-gui.GetMainViewport ctx))
  (local get-viewport-pos (or (and app.fullscreen.use_work_area
                                   Im-gui.Viewport_GetWorkPos)
                              Im-gui.Viewport_GetPos))
  (local get-viewport-size
         (or (and app.fullscreen.use_work_area Im-gui.Viewport_GetWorkSize)
             Im-gui.Viewport_GetSize))
  (Im-gui.SetNextWindowPos ctx (get-viewport-pos viewport))
  (Im-gui.SetNextWindowSize ctx (get-viewport-size viewport))
  (var (rv open) (Im-gui.Begin ctx "Example: Fullscreen window" true
                               app.fullscreen.flags))
  (when (not rv) (lua "return open"))
  (set (rv app.fullscreen.use_work_area)
       (Im-gui.Checkbox ctx "Use work area instead of main area"
                        app.fullscreen.use_work_area))
  (Im-gui.SameLine ctx)
  (demo.HelpMarker "Main Area = entire viewport,
Work Area = entire viewport minus sections used by the main menu bars, task bars etc.

Enable the main-menu bar in Examples menu to see the difference.")
  (set (rv app.fullscreen.flags)
       (Im-gui.CheckboxFlags ctx :ImGuiWindowFlags_NoBackground
                             app.fullscreen.flags
                             (Im-gui.WindowFlags_NoBackground)))
  (set (rv app.fullscreen.flags)
       (Im-gui.CheckboxFlags ctx :ImGuiWindowFlags_NoDecoration
                             app.fullscreen.flags
                             (Im-gui.WindowFlags_NoDecoration)))
  (Im-gui.Indent ctx)
  (set (rv app.fullscreen.flags)
       (Im-gui.CheckboxFlags ctx :ImGuiWindowFlags_NoTitleBar
                             app.fullscreen.flags
                             (Im-gui.WindowFlags_NoTitleBar)))
  (set (rv app.fullscreen.flags)
       (Im-gui.CheckboxFlags ctx :ImGuiWindowFlags_NoCollapse
                             app.fullscreen.flags
                             (Im-gui.WindowFlags_NoCollapse)))
  (set (rv app.fullscreen.flags)
       (Im-gui.CheckboxFlags ctx :ImGuiWindowFlags_NoScrollbar
                             app.fullscreen.flags
                             (Im-gui.WindowFlags_NoScrollbar)))
  (Im-gui.Unindent ctx)
  (when (Im-gui.Button ctx "Close this window") (set open false))
  (Im-gui.End ctx)
  open)

(fn demo.ShowExampleAppWindowTitles []
  (let [viewport (Im-gui.GetMainViewport ctx)
        base-pos [(Im-gui.Viewport_GetPos viewport)]]
    (Im-gui.SetNextWindowPos ctx (+ (. base-pos 1) 100) (+ (. base-pos 2) 100)
                             (Im-gui.Cond_FirstUseEver))
    (when (Im-gui.Begin ctx "Same title as another window##1")
      (Im-gui.Text ctx
                   "This is window 1.
My title is the same as window 2, but my identifier is unique.")
      (Im-gui.End ctx))
    (Im-gui.SetNextWindowPos ctx (+ (. base-pos 1) 100) (+ (. base-pos 2) 200)
                             (Im-gui.Cond_FirstUseEver))
    (when (Im-gui.Begin ctx "Same title as another window##2")
      (Im-gui.Text ctx
                   "This is window 2.
My title is the same as window 1, but my identifier is unique.")
      (Im-gui.End ctx))
    (Im-gui.SetNextWindowPos ctx (+ (. base-pos 1) 100) (+ (. base-pos 2) 300)
                             (Im-gui.Cond_FirstUseEver))
    (global spinners ["|" "/" "-" "\\"])
    (local spinner (band (math.floor (/ (Im-gui.GetTime ctx) 0.25)) 3))
    (when (Im-gui.Begin ctx
                        (: "Animated title %s %d###AnimatedTitle" :format
                           (. spinners (+ spinner 1)) (Im-gui.GetFrameCount ctx)))
      (Im-gui.Text ctx "This window has a changing title.")
      (Im-gui.End ctx))))

(fn demo.ShowExampleAppCustomRendering []
  (when (not app.rendering)
    (set app.rendering {:adding_line false
                        :circle_segments_override false
                        :circle_segments_override_v 12
                        :col 4294928127
                        :curve_segments_override false
                        :curve_segments_override_v 8
                        :draw_bg true
                        :draw_fg true
                        :ngon_sides 6
                        :opt_enable_context_menu true
                        :opt_enable_grid true
                        :points {}
                        :scrolling [0 0]
                        :sz 36
                        :thickness 3}))
  (var (rv open) (Im-gui.Begin ctx "Example: Custom rendering" true))
  (when (not rv) (lua "return open"))
  (when (Im-gui.BeginTabBar ctx "##TabBar")
    (when (Im-gui.BeginTabItem ctx :Primitives)
      (Im-gui.PushItemWidth ctx (* (- (Im-gui.GetFontSize ctx)) 15))
      (local draw-list (Im-gui.GetWindowDrawList ctx))
      (Im-gui.Text ctx :Gradients)
      (local gradient-size
             [(Im-gui.CalcItemWidth ctx) (Im-gui.GetFrameHeight ctx)])
      (local p0 [(Im-gui.GetCursorScreenPos ctx)])
      (local p1 [(+ (. p0 1) (. gradient-size 1))
                 (+ (. p0 2) (. gradient-size 2))])
      (local col-a (Im-gui.GetColorEx ctx 255))
      (local col-b (Im-gui.GetColorEx ctx 4294967295))
      (Im-gui.DrawList_AddRectFilledMultiColor draw-list (. p0 1) (. p0 2)
                                               (. p1 1) (. p1 2) col-a col-b
                                               col-b col-a)
      (Im-gui.InvisibleButton ctx "##gradient1" (. gradient-size 1)
                              (. gradient-size 2))
      (local p0 [(Im-gui.GetCursorScreenPos ctx)])
      (local p1 [(+ (. p0 1) (. gradient-size 1))
                 (+ (. p0 2) (. gradient-size 2))])
      (local col-a (Im-gui.GetColorEx ctx 16711935))
      (local col-b (Im-gui.GetColorEx ctx 4278190335))
      (Im-gui.DrawList_AddRectFilledMultiColor draw-list (. p0 1) (. p0 2)
                                               (. p1 1) (. p1 2) col-a col-b
                                               col-b col-a)
      (Im-gui.InvisibleButton ctx "##gradient2" (. gradient-size 1)
                              (. gradient-size 2))
      (local item-inner-spacing-x
             (Im-gui.GetStyleVar ctx (Im-gui.StyleVar_ItemInnerSpacing)))
      (Im-gui.Text ctx "All primitives")
      (set (rv app.rendering.sz)
           (Im-gui.DragDouble ctx :Size app.rendering.sz 0.2 2 100 "%.0f"))
      (set (rv app.rendering.thickness)
           (Im-gui.DragDouble ctx :Thickness app.rendering.thickness 0.05 1 8
                              "%.02f"))
      (set (rv app.rendering.ngon_sides)
           (Im-gui.SliderInt ctx "N-gon sides" app.rendering.ngon_sides 3 12))
      (set (rv app.rendering.circle_segments_override)
           (Im-gui.Checkbox ctx "##circlesegmentoverride"
                            app.rendering.circle_segments_override))
      (Im-gui.SameLine ctx 0 item-inner-spacing-x)
      (set (rv app.rendering.circle_segments_override_v)
           (Im-gui.SliderInt ctx "Circle segments override"
                             app.rendering.circle_segments_override_v 3 40))
      (when rv (set app.rendering.circle_segments_override true))
      (set (rv app.rendering.curve_segments_override)
           (Im-gui.Checkbox ctx "##curvessegmentoverride"
                            app.rendering.curve_segments_override))
      (Im-gui.SameLine ctx 0 item-inner-spacing-x)
      (set (rv app.rendering.curve_segments_override_v)
           (Im-gui.SliderInt ctx "Curves segments override"
                             app.rendering.curve_segments_override_v 3 40))
      (when rv (set app.rendering.curve_segments_override true))
      (set (rv app.rendering.col)
           (Im-gui.ColorEdit4 ctx :Color app.rendering.col))
      (local p [(Im-gui.GetCursorScreenPos ctx)])
      (local spacing 10)
      (local corners-tl-br
             (bor (Im-gui.DrawFlags_RoundCornersTopLeft)
                  (Im-gui.DrawFlags_RoundCornersBottomRight)))
      (local col app.rendering.col)
      (local sz app.rendering.sz)
      (local rounding (/ sz 5))
      (local circle-segments (or (and app.rendering.circle_segments_override
                                      app.rendering.circle_segments_override_v)
                                 0))
      (local curve-segments (or (and app.rendering.curve_segments_override
                                     app.rendering.curve_segments_override_v)
                                0))
      (var x (+ (. p 1) 4))
      (var y (+ (. p 2) 4))
      (for [n 1 2]
        (local th (or (and (= n 1) 1) app.rendering.thickness))
        (Im-gui.DrawList_AddNgon draw-list (+ x (* sz 0.5)) (+ y (* sz 0.5))
                                 (* sz 0.5) col app.rendering.ngon_sides th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddCircle draw-list (+ x (* sz 0.5)) (+ y (* sz 0.5))
                                   (* sz 0.5) col circle-segments th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddRect draw-list x y (+ x sz) (+ y sz) col 0
                                 (Im-gui.DrawFlags_None) th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddRect draw-list x y (+ x sz) (+ y sz) col rounding
                                 (Im-gui.DrawFlags_None) th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddRect draw-list x y (+ x sz) (+ y sz) col rounding
                                 corners-tl-br th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddTriangle draw-list (+ x (* sz 0.5)) y (+ x sz)
                                     (- (+ y sz) 0.5) x (- (+ y sz) 0.5) col th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddLine draw-list x y (+ x sz) y col th)
        (set x (+ x sz spacing))
        (Im-gui.DrawList_AddLine draw-list x y x (+ y sz) col th)
        (set x (+ x spacing))
        (Im-gui.DrawList_AddLine draw-list x y (+ x sz) (+ y sz) col th)
        (set x (+ x sz spacing))
        (local cp3 [[x (+ y (* sz 0.6))]
                    [(+ x (* sz 0.5)) (- y (* sz 0.4))]
                    [(+ x sz) (+ y sz)]])
        (Im-gui.DrawList_AddBezierQuadratic draw-list (. (. cp3 1) 1)
                                            (. (. cp3 1) 2) (. (. cp3 2) 1)
                                            (. (. cp3 2) 2) (. (. cp3 3) 1)
                                            (. (. cp3 3) 2) col th
                                            curve-segments)
        (set x (+ x sz spacing))
        (local cp4 [[x y]
                    [(+ x (* sz 1.3)) (+ y (* sz 0.3))]
                    [(- (+ x sz) (* sz 1.3)) (- (+ y sz) (* sz 0.3))]
                    [(+ x sz) (+ y sz)]])
        (Im-gui.DrawList_AddBezierCubic draw-list (. (. cp4 1) 1)
                                        (. (. cp4 1) 2) (. (. cp4 2) 1)
                                        (. (. cp4 2) 2) (. (. cp4 3) 1)
                                        (. (. cp4 3) 2) (. (. cp4 4) 1)
                                        (. (. cp4 4) 2) col th curve-segments)
        (set x (+ (. p 1) 4))
        (set y (+ y sz spacing)))
      (Im-gui.DrawList_AddNgonFilled draw-list (+ x (* sz 0.5))
                                     (+ y (* sz 0.5)) (* sz 0.5) col
                                     app.rendering.ngon_sides)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddCircleFilled draw-list (+ x (* sz 0.5))
                                       (+ y (* sz 0.5)) (* sz 0.5) col
                                       circle-segments)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz) col)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz) col 10)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz) col 10
                                     corners-tl-br)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddTriangleFilled draw-list (+ x (* sz 0.5)) y (+ x sz)
                                         (- (+ y sz) 0.5) x (- (+ y sz) 0.5) col)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddRectFilled draw-list x y (+ x sz)
                                     (+ y app.rendering.thickness) col)
      (set x (+ x sz spacing))
      (Im-gui.DrawList_AddRectFilled draw-list x y
                                     (+ x app.rendering.thickness) (+ y sz) col)
      (set x (+ x (* spacing 2)))
      (Im-gui.DrawList_AddRectFilled draw-list x y (+ x 1) (+ y 1) col)
      (set x (+ x sz))
      (Im-gui.DrawList_AddRectFilledMultiColor draw-list x y (+ x sz) (+ y sz)
                                               255 4278190335 4294902015
                                               16711935)
      (Im-gui.Dummy ctx (* (+ sz spacing) 10.2) (* (+ sz spacing) 3))
      (Im-gui.PopItemWidth ctx)
      (Im-gui.EndTabItem ctx))
    (when (Im-gui.BeginTabItem ctx :Canvas)
      (set (rv app.rendering.opt_enable_grid)
           (Im-gui.Checkbox ctx "Enable grid" app.rendering.opt_enable_grid))
      (set (rv app.rendering.opt_enable_context_menu)
           (Im-gui.Checkbox ctx "Enable context menu"
                            app.rendering.opt_enable_context_menu))
      (Im-gui.Text ctx "Mouse Left: drag to add lines,
Mouse Right: drag to scroll, click for context menu.")
      (local canvas-p0 [(Im-gui.GetCursorScreenPos ctx)])
      (local canvas-sz [(Im-gui.GetContentRegionAvail ctx)])
      (when (< (. canvas-sz 1) 50) (tset canvas-sz 1 50))
      (when (< (. canvas-sz 2) 50) (tset canvas-sz 2 50))
      (local canvas-p1
             [(+ (. canvas-p0 1) (. canvas-sz 1))
              (+ (. canvas-p0 2) (. canvas-sz 2))])
      (local mouse-pos [(Im-gui.GetMousePos ctx)])
      (local draw-list (Im-gui.GetWindowDrawList ctx))
      (Im-gui.DrawList_AddRectFilled draw-list (. canvas-p0 1) (. canvas-p0 2)
                                     (. canvas-p1 1) (. canvas-p1 2) 842150655)
      (Im-gui.DrawList_AddRect draw-list (. canvas-p0 1) (. canvas-p0 2)
                               (. canvas-p1 1) (. canvas-p1 2) 4294967295)
      (Im-gui.InvisibleButton ctx :canvas (. canvas-sz 1) (. canvas-sz 2)
                              (bor (Im-gui.ButtonFlags_MouseButtonLeft)
                                   (Im-gui.ButtonFlags_MouseButtonRight)))
      (local is-hovered (Im-gui.IsItemHovered ctx))
      (local is-active (Im-gui.IsItemActive ctx))
      (local origin
             [(+ (. canvas-p0 1) (. app.rendering.scrolling 1))
              (+ (. canvas-p0 2) (. app.rendering.scrolling 2))])
      (local mouse-pos-in-canvas
             [(- (. mouse-pos 1) (. origin 1))
              (- (. mouse-pos 2) (. origin 2))])
      (when (and (and is-hovered (not app.rendering.adding_line))
                 (Im-gui.IsMouseClicked ctx (Im-gui.MouseButton_Left)))
        (table.insert app.rendering.points mouse-pos-in-canvas)
        (table.insert app.rendering.points mouse-pos-in-canvas)
        (set app.rendering.adding_line true))
      (when app.rendering.adding_line
        (tset app.rendering.points (length app.rendering.points)
              mouse-pos-in-canvas)
        (when (not (Im-gui.IsMouseDown ctx (Im-gui.MouseButton_Left)))
          (set app.rendering.adding_line false)))
      (local mouse-threshold-for-pan
             (or (and app.rendering.opt_enable_context_menu (- 1)) 0))
      (when (and is-active
                 (Im-gui.IsMouseDragging ctx (Im-gui.MouseButton_Right)
                                         mouse-threshold-for-pan))
        (local mouse-delta [(Im-gui.GetMouseDelta ctx)])
        (tset app.rendering.scrolling 1
              (+ (. app.rendering.scrolling 1) (. mouse-delta 1)))
        (tset app.rendering.scrolling 2
              (+ (. app.rendering.scrolling 2) (. mouse-delta 2))))

      (fn remove-last-line [] (table.remove app.rendering.points)
        (table.remove app.rendering.points))

      (local drag-delta
             [(Im-gui.GetMouseDragDelta ctx 0 0 (Im-gui.MouseButton_Right))])
      (when (and (and app.rendering.opt_enable_context_menu
                      (= (. drag-delta 1) 0))
                 (= (. drag-delta 2) 0))
        (Im-gui.OpenPopupOnItemClick ctx :context
                                     (Im-gui.PopupFlags_MouseButtonRight)))
      (when (Im-gui.BeginPopup ctx :context)
        (when app.rendering.adding_line (remove-last-line)
          (set app.rendering.adding_line false))
        (when (Im-gui.MenuItem ctx "Remove one" nil false
                               (> (length app.rendering.points) 0))
          (remove-last-line))
        (when (Im-gui.MenuItem ctx "Remove all" nil false
                               (> (length app.rendering.points) 0))
          (set app.rendering.points {}))
        (Im-gui.EndPopup ctx))
      (Im-gui.DrawList_PushClipRect draw-list (. canvas-p0 1) (. canvas-p0 2)
                                    (. canvas-p1 1) (. canvas-p1 2) true)
      (when app.rendering.opt_enable_grid
        (local GRID_STEP 64)
        (var x (math.fmod (. app.rendering.scrolling 1) GRID_STEP))
        (while (< x (. canvas-sz 1))
          (Im-gui.DrawList_AddLine draw-list (+ (. canvas-p0 1) x)
                                   (. canvas-p0 2) (+ (. canvas-p0 1) x)
                                   (. canvas-p1 2) 3368601640)
          (set x (+ x GRID_STEP)))
        (var y (math.fmod (. app.rendering.scrolling 2) GRID_STEP))
        (while (< y (. canvas-sz 2))
          (Im-gui.DrawList_AddLine draw-list (. canvas-p0 1)
                                   (+ (. canvas-p0 2) y) (. canvas-p1 1)
                                   (+ (. canvas-p0 2) y) 3368601640)
          (set y (+ y GRID_STEP))))
      (var n 1)
      (while (< n (length app.rendering.points))
        (Im-gui.DrawList_AddLine draw-list
                                 (+ (. origin 1)
                                    (. (. app.rendering.points n) 1))
                                 (+ (. origin 2)
                                    (. (. app.rendering.points n) 2))
                                 (+ (. origin 1)
                                    (. (. app.rendering.points (+ n 1)) 1))
                                 (+ (. origin 2)
                                    (. (. app.rendering.points (+ n 1)) 2))
                                 4294902015 2)
        (set n (+ n 2)))
      (Im-gui.DrawList_PopClipRect draw-list)
      (Im-gui.EndTabItem ctx))
    (when (Im-gui.BeginTabItem ctx "BG/FG draw lists")
      (set (rv app.rendering.draw_bg)
           (Im-gui.Checkbox ctx "Draw in Background draw list"
                            app.rendering.draw_bg))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "The Background draw list will be rendered below every Dear ImGui windows.")
      (set (rv app.rendering.draw_fg)
           (Im-gui.Checkbox ctx "Draw in Foreground draw list"
                            app.rendering.draw_fg))
      (Im-gui.SameLine ctx)
      (demo.HelpMarker "The Foreground draw list will be rendered over every Dear ImGui windows.")
      (local window-pos [(Im-gui.GetWindowPos ctx)])
      (local window-size [(Im-gui.GetWindowSize ctx)])
      (local window-center
             [(+ (. window-pos 1) (* (. window-size 1) 0.5))
              (+ (. window-pos 2) (* (. window-size 2) 0.5))])
      (when app.rendering.draw_bg
        (Im-gui.DrawList_AddCircle (Im-gui.GetBackgroundDrawList ctx)
                                   (. window-center 1) (. window-center 2)
                                   (* (. window-size 1) 0.6) 4278190280 nil
                                   (+ 10 4)))
      (when app.rendering.draw_fg
        (Im-gui.DrawList_AddCircle (Im-gui.GetForegroundDrawList ctx)
                                   (. window-center 1) (. window-center 2)
                                   (* (. window-size 2) 0.6) 16711880 nil 10))
      (Im-gui.EndTabItem ctx))
    (Im-gui.EndTabBar ctx))
  (Im-gui.End ctx)
  open)

(local (public public-functions)
       (values {} [:ShowDemoWindow :ShowStyleEditor :PushStyle :PopStyle]))

(each [_ ___fn___ (ipairs public-functions)]
  (tset public ___fn___ (fn [user-ctx ...] (set ctx user-ctx)
                          ((. demo ___fn___) ...))))

public

