;; Lua/ReaImGui port of Dear ImGui's C++ demo code (v1.89.3)
;;
;;This file can be imported in other scripts to help during development:

(comment
(local demo
       (dofile (.. (reaper.GetResourcePath)
                   "/Scripts/ReaTeam Extensions/API/ReaImGui_Demo.lua")))

(local ctx (reaper.ImGui_CreateContext "My script"))

(fn loop []
  (demo.PushStyle ctx)
  (demo.ShowDemoWindow ctx)
  (when (reaper.ImGui_Begin ctx "Dear ImGui Style Editor")
    (demo.ShowStyleEditor ctx)
    (reaper.ImGui_End ctx))
  (demo.PopStyle ctx)
  (reaper.defer loop))

(reaper.defer loop)
  )

;; Index of this file:

;; [SECTION] Helpers
;; [SECTION] Demo Window / demo.ShowDemoWindow()
;; - demo.ShowDemoWindow()
;; - sub section: demo.ShowDemoWindowWidgets()
;; - sub section: demo.ShowDemoWindowLayout()
;; - sub section: demo.ShowDemoWindowPopups()
;; - sub section: demo.ShowDemoWindowTables()
;; - sub section: demo.ShowDemoWindowInputs()
;; [SECTION] Style Editor / demo.ShowStyleEditor()
;; [SECTION] User Guide / demo.ShowUserGuide()
;; [SECTION] Example App: Main Menu Bar / demo.ShowExampleAppMainMenuBar()
;; [SECTION] Example App: Debug Console / demo.ShowExampleAppConsole()
;; [SECTION] Example App: Debug Log / demo.ShowExampleAppLog()
;; [SECTION] Example App: Simple Layout / demo.ShowExampleAppLayout()
;; [SECTION] Example App: Property Editor / demo.ShowExampleAppPropertyEditor()
;; [SECTION] Example App: Long Text / demo.ShowExampleAppLongText()
;; [SECTION] Example App: Auto Resize / demo.ShowExampleAppAutoResize()
;; [SECTION] Example App: Constrained Resize / demo.ShowExampleAppConstrainedResize()
;; [SECTION] Example App: Simple overlay / demo.ShowExampleAppSimpleOverlay()
;; [SECTION] Example App: Fullscreen window / demo.ShowExampleAppFullscreen()
;; [SECTION] Example App: Manipulating window titles / demo.ShowExampleAppWindowTitles()
;; [SECTION] Example App: Custom Rendering using ImDrawList API / demo.ShowExampleAppCustomRendering()
;; [SECTION] Example App: Docking, DockSpace / demo.ShowExampleAppDockSpace()
;; [SECTION] Example App: Documents Handling / demo.ShowExampleAppDocuments()

(local ImGui
  (collect [name func (pairs reaper)]
    (let [name (name:match "^ImGui_(.+)$")]
      (when name (values name func)))))

(var ctx nil)

(local (FLT_MIN FLT_MAX) (ImGui.NumericLimits_Float))

(local (IMGUI_VERSION IMGUI_VERSION_NUM REAIMGUI_VERSION) (ImGui.GetVersion))

(local demo {:open true
             :menu {:b true :enabled true :f 0.5 :n 0}
             ;; Window flags (accessible from the "Configuration" section)
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
             ;; :no_bring_to_front false,
             :unsaved_document false})

(local show-app {;; Examples Apps (accessible from the "Examples" menu)
                 ;; :main_menu_bar false
                 ;; :dockspace false
                 :documents false
                 :console false
                 :log false
                 :layout false
                 :property_editor false
                 :long_text false
                 :auto_resize false
                 :constrained_resize false
                 :simple_overlay false
                 :fullscreen false
                 :window_titles false
                 :custom_rendering false

                 ;; Dear ImGui Tools/Apps (accessible from the "Tools" menu)
                 :metrics false
                 :debug_log false
                 :stack_tool false
                 :style_editor false
                 :about false})

(local config {})

(local widgets {})

(local layout {})

(local popups {})

(local tables {})

(local misc {})

(local app {})

(local cache {})

(fn demo.loop []
  (demo.PushStyle)
  (set demo.open (demo.ShowDemoWindow true))
  (demo.PopStyle)
  (when demo.open (reaper.defer demo.loop)))

(when (= (select 2 (reaper.get_action_context))
         (: (. (debug.getinfo 1 :S) :source) :sub 2))
  ;; show global storage in the IDE for convenience
  (set _G.demo demo)
  (set _G.widgets widgets)
  (set _G.layout layout)
  (set _G.popups popups)
  (set _G.tables tables)
  (set _G.misc misc)
  (set _G.app app)
  ;; hajime!
  (set ctx (ImGui.CreateContext "ReaImGui Demo" (ImGui.ConfigFlags_DockingEnable)))
  (reaper.defer demo.loop))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Helper to display a little (?) mark which shows a tooltip when hovered.
;; In your own code you may want to display an actual icon if you are using a merged icon fonts (see docs/FONTS.md)
(fn demo.HelpMarker [desc]
  (ImGui.TextDisabled ctx "(?)")
  (when (ImGui.IsItemHovered ctx (ImGui.HoveredFlags_DelayShort))
    (ImGui.BeginTooltip ctx)
    (ImGui.PushTextWrapPos ctx (* (ImGui.GetFontSize ctx) 35.0))
    (ImGui.Text ctx desc)
    (ImGui.PopTextWrapPos ctx)
    (ImGui.EndTooltip ctx)))

(fn demo.RgbaToArgb [rgba]
  (bor (band (rshift rgba 8) 0x00FFFFFF)
       (band (lshift rgba 24) 0xFF000000)))

(fn demo.ArgbToRgba [argb]
  (bor (band (lshift argb 8) 0xFFFFFF00)
       (band (rshift argb 24) 0xFF)))

(fn demo.round [n] (math.floor (+ n 0.5)))

(fn demo.clamp [v mn mx]
  (if (< v mn) mn
      (> v mx) mx
      v))

(fn demo.Link [url]
  (if (not reaper.CF_ShellExecute)
    (do (ImGui.Text ctx url)
      nil)
    (do (local color (ImGui.GetStyleColor ctx (ImGui.Col_CheckMark)))
      (ImGui.TextColored ctx color url)
      (if
        (ImGui.IsItemClicked ctx) (reaper.CF_ShellExecute url)
        (ImGui.IsItemHovered ctx) (ImGui.SetMouseCursor ctx (ImGui.MouseCursor_Hand))))))

(fn demo.HSV [h s v a]
  (let [(r g b) (ImGui.ColorConvertHSVtoRGB h s v)]
    (ImGui.ColorConvertDouble4ToU32 r g b (or a 1.0))))

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
    (when (. enum-cache i)
      (table.unpack (. enum-cache i)))))

(fn demo.DockName [dock-id]
  (if 
    (= dock-id 0) "Floating"
    (> dock-id 0) (: "ImGui docker %d" :format dock-id)
    ;; reaper.DockGetPosition was added in v6.02
    (do (local positions {0 :Bottom 1 :Left 2 :Top 3 :Right 4 :Floating})
      (local position (or (when reaper.DockGetPosition
                            (. positions (reaper.DockGetPosition (bnot dock-id))))
                          :Unknown))
      (: "REAPER docker %d (%s)" :format (- dock-id) position))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Demo Window / ShowDemoWindow()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ; ShowDemoWindowWidgets()
;; ; ShowDemoWindowLayout()
;; ; ShowDemoWindowPopups()
;; ; ShowDemoWindowTables()
;; ; ShowDemoWindowColumns()
;; ; ShowDemoWindowInputs()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(macro update-2nd [s f]
  `(do
     (var v1# nil)
     (set (v1# ,s) (let [,(sym "$") ,s] ,f))
     v1#))

(macro update-2nd-array [s i f]
  `(do
     (var v1# nil)
     (var v2# nil)
     (set (v1# v2#) (let [,(sym "$") (. ,s i)] ,f))
     (tset ,s ,i v2#)
     v1#))

(macro set-when-not [s v]
  `(when (not ,s) (set ,s ,v)))

;; Demonstrate most Dear ImGui features (this is big function!)
;; You may execute this function to experiment with the UI and understand what it does.
;; You may then search for keywords in the code when you are interested by a specific feature.

(fn demo.ShowDemoWindow [open]
  (var open open)

  ;; if show_app.main_menu_bar      then                               demo.ShowExampleAppMainMenuBar()       end
  ;; if show_app.dockspace          then show_app.dockspace          = demo.ShowExampleAppDockSpace()         end -- Process the Docking app first, as explicit DockSpace() nodes needs to be submitted early (read comments near the DockSpace function)
  (when show-app.documents          (set show-app.documents          (demo.ShowExampleAppDocuments))) ;; Process the Document app next, as it may also use a DockSpace()
  (when show-app.console            (set show-app.console            (demo.ShowExampleAppConsole)))
  (when show-app.log                (set show-app.log                (demo.ShowExampleAppLog)))
  (when show-app.layout             (set show-app.layout             (demo.ShowExampleAppLayout)))
  (when show-app.property_editor    (set show-app.property_editor    (demo.ShowExampleAppPropertyEditor)))
  (when show-app.long_text          (set show-app.long_text          (demo.ShowExampleAppLongText)))
  (when show-app.auto_resize        (set show-app.auto_resize        (demo.ShowExampleAppAutoResize)))
  (when show-app.constrained_resize (set show-app.constrained_resize (demo.ShowExampleAppConstrainedResize)))
  (when show-app.simple_overlay     (set show-app.simple_overlay     (demo.ShowExampleAppSimpleOverlay)))
  (when show-app.fullscreen         (set show-app.fullscreen         (demo.ShowExampleAppFullscreen)))
  (when show-app.window_titles                                       (demo.ShowExampleAppWindowTitles))
  (when show-app.custom_rendering   (set show-app.custom_rendering   (demo.ShowExampleAppCustomRendering)))

  (when show-app.metrics    (set show-app.metrics    (ImGui.ShowMetricsWindow   ctx show-app.metrics)))
  (when show-app.debug_log  (set show-app.debug_log  (ImGui.ShowDebugLogWindow  ctx show-app.debug_log)))
  (when show-app.stack_tool (set show-app.stack_tool (ImGui.ShowStackToolWindow ctx show-app.stack_tool)))
  (when show-app.about      (set show-app.about      (ImGui.ShowAboutWindow     ctx show-app.about)))
  (when show-app.style_editor
    (var rv nil)
    (set (rv show-app.style_editor) (ImGui.Begin ctx "Dear ImGui Style Editor" true))
    (when rv
      (demo.ShowStyleEditor)
      (ImGui.End ctx)))
  ;; Demonstrate the various window flags. Typically you would just use the default!
  (var window-flags (ImGui.WindowFlags_None))
  (when demo.no_titlebar      (set window-flags (bor window-flags (ImGui.WindowFlags_NoTitleBar))))
  (when demo.no_scrollbar     (set window-flags (bor window-flags (ImGui.WindowFlags_NoScrollbar))))
  (when (not demo.no_menu)    (set window-flags (bor window-flags (ImGui.WindowFlags_MenuBar))))
  (when demo.no_move          (set window-flags (bor window-flags (ImGui.WindowFlags_NoMove))))
  (when demo.no_resize        (set window-flags (bor window-flags (ImGui.WindowFlags_NoResize))))
  (when demo.no_collapse      (set window-flags (bor window-flags (ImGui.WindowFlags_NoCollapse))))
  (when demo.no_nav           (set window-flags (bor window-flags (ImGui.WindowFlags_NoNav))))
  (when demo.no_background    (set window-flags (bor window-flags (ImGui.WindowFlags_NoBackground))))
  ;; if demo.no_bring_to_front then window_flags = window_flags | ImGui.WindowFlags_NoBringToFrontOnFocus() end
  (when demo.no_docking       (set window-flags (bor window-flags (ImGui.WindowFlags_NoDocking))))
  (when demo.topmost          (set window-flags (bor window-flags (ImGui.WindowFlags_TopMost))))
  (when demo.unsaved_document (set window-flags (bor window-flags (ImGui.WindowFlags_UnsavedDocument))))
  (when demo.no_close         (set open false)) ;; disable the close button


  ;; We specify a default position/size in case there's no data in the .ini file.
  ;; We only do it to make the demo applications a little more welcoming, but typically this isn't required.
  (local main-viewport (ImGui.GetMainViewport ctx))
  (local work-pos [(ImGui.Viewport_GetWorkPos main-viewport)])
  (ImGui.SetNextWindowPos ctx
                          (+ (. work-pos 1) 20)
                          (+ (. work-pos 2) 20)
                          (ImGui.Cond_FirstUseEver))
  (ImGui.SetNextWindowSize ctx 550 680 (ImGui.Cond_FirstUseEver))

  (when demo.set_dock_id
    (ImGui.SetNextWindowDockID ctx demo.set_dock_id)
    (set demo.set_dock_id nil))

  ;; Main body of the Demo window starts here.
  (do
    (var rv nil)
    (set (rv open) (ImGui.Begin ctx "Dear ImGui Demo" open window-flags))
    ;; Early out if the window is collapsed
    (when (not rv) (lua "return open")))
  ;; Most "big" widgets share a common width settings by default. See 'Demo->Layout->Widgets Width' for details.

  ;; e.g. Use 2/3 of the space for widgets and 1/3 for labels (right align)
  ;;ImGui.PushItemWidth(ctx, -ImGui.GetWindowWidth(ctx) * 0.35)

  ;; e.g. Leave a fixed amount of width for labels (by passing a negative value), the rest goes to widgets.
  (ImGui.PushItemWidth ctx (* (ImGui.GetFontSize ctx) (- 12)))
  ;; Menu Bar
  (when (ImGui.BeginMenuBar ctx)
    (when (ImGui.BeginMenu ctx :Menu) (demo.ShowExampleMenuFile)
      (ImGui.EndMenu ctx))
    (when (ImGui.BeginMenu ctx :Examples)
      ;;(update-2nd show_app.main_menu_bar (ImGui.MenuItem ctx "Main menu bar" nil $ false))
      (update-2nd show-app.console            (ImGui.MenuItem ctx :Console nil $ false))
      (update-2nd show-app.log                (ImGui.MenuItem ctx :Log nil $))
      (update-2nd show-app.layout             (ImGui.MenuItem ctx "Simple layout" nil $))
      (update-2nd show-app.property_editor    (ImGui.MenuItem ctx "Property editor" nil $))
      (update-2nd show-app.long_text          (ImGui.MenuItem ctx "Long text display" nil $))
      (update-2nd show-app.auto_resize        (ImGui.MenuItem ctx "Auto-resizing window" nil $))
      (update-2nd show-app.constrained_resize (ImGui.MenuItem ctx "Constrained-resizing window" nil $))
      (update-2nd show-app.simple_overlay     (ImGui.MenuItem ctx "Simple overlay" nil $))
      (update-2nd show-app.fullscreen         (ImGui.MenuItem ctx "Fullscreen window" nil $))
      (update-2nd show-app.window_titles      (ImGui.MenuItem ctx "Manipulating window titles" nil $))
      (update-2nd show-app.custom_rendering   (ImGui.MenuItem ctx "Custom rendering" nil $))
      ;; _,show_app.dockspace =
      ;;   ImGui.MenuItem(ctx, 'Dockspace', nil, show_app.dockspace, false)
      (update-2nd show-app.documents          (ImGui.MenuItem ctx :Documents nil $ false))
      (ImGui.EndMenu ctx))
    ;; if ImGui.MenuItem(ctx, 'MenuItem') then end -- You can also use MenuItem() inside a menu bar!
    (when (ImGui.BeginMenu ctx :Tools)
      (update-2nd show-app.metrics      (ImGui.MenuItem ctx :Metrics/Debugger nil $))
      (update-2nd show-app.debug_log    (ImGui.MenuItem ctx "Debug Log" nil $))
      (update-2nd show-app.stack_tool   (ImGui.MenuItem ctx "Stack Tool" nil $))
      (update-2nd show-app.style_editor (ImGui.MenuItem ctx "Style Editor" nil $))
      (update-2nd show-app.about        (ImGui.MenuItem ctx "About Dear ImGui" nil $))
      (ImGui.EndMenu ctx))
    (when (ImGui.SmallButton ctx :Documentation)
      (local doc (: "%s/Data/reaper_imgui_doc.html" :format (reaper.GetResourcePath)))
      (if reaper.CF_ShellExecute
        (reaper.CF_ShellExecute doc)
        (reaper.MB doc "ReaImGui Documentation" 0)))
    (ImGui.EndMenuBar ctx))
  (ImGui.Text ctx (: "dear imgui says hello. (%s) (%d) (ReaImGui %s)" :format IMGUI_VERSION IMGUI_VERSION_NUM REAIMGUI_VERSION))
  (ImGui.Spacing ctx)
  (when (ImGui.CollapsingHeader ctx :Help)
    (ImGui.Text ctx "ABOUT THIS DEMO:")
    (ImGui.BulletText ctx "Sections below are demonstrating many aspects of the library.")
    (ImGui.BulletText ctx "The \"Examples\" menu above leads to more demo contents.")
    (ImGui.BulletText ctx (.. "The \"Tools\" menu above gives access to: About Box, Style Editor, "
                               "and Metrics/Debugger (general purpose Dear ImGui debugging tool)."))
    (ImGui.Separator ctx)
    (ImGui.Text ctx "PROGRAMMER GUIDE:")
    (ImGui.BulletText ctx "See the ShowDemoWindow() code in ReaImGui_Demo.lua. <- you are here!")
    ;; ImGui.BulletText(ctx, 'See comments in imgui.cpp.')
    (ImGui.BulletText ctx "See example scripts in the examples/ folder.")
    (ImGui.Indent ctx)
    (demo.Link "https://github.com/cfillion/reaimgui/tree/master/examples")
    (ImGui.Unindent ctx)
    (ImGui.BulletText ctx "Read the FAQ at ")
    (ImGui.SameLine ctx 0 0)
    (demo.Link "https://www.dearimgui.org/faq/")
    ;; ImGui.BulletText(ctx, "Set 'io.ConfigFlags |= NavEnableKeyboard' for keyboard controls.")
    ;; ImGui.BulletText(ctx, "Set 'io.ConfigFlags |= NavEnableGamepad' for gamepad controls.")
    (ImGui.Separator ctx)

    (ImGui.Text ctx "USER GUIDE:")
    (demo.ShowUserGuide))
  (when (ImGui.CollapsingHeader ctx :Configuration)
    (when (ImGui.TreeNode ctx "Configuration##2")
      (fn config-var-checkbox [name]
        (let [conf-var ((assert (. reaper (: "ImGui_%s" :format name))
                                "unknown var"))
              (rv val) (ImGui.Checkbox ctx name (ImGui.GetConfigVar ctx conf-var))]
          (when rv
            (ImGui.SetConfigVar ctx conf-var (if val 1 0)))))
      (set config.flags (ImGui.GetConfigVar ctx (ImGui.ConfigVar_Flags)))

      (ImGui.SeparatorText ctx :General)
      ;; ImGui.CheckboxFlags("io.ConfigFlags: NavEnableGamepad",     &io.ConfigFlags, ImGuiConfigFlags_NavEnableGamepad)
      ;; ImGui.SameLine(ctx); demo.HelpMarker("Enable gamepad controls. Require backend to set io.BackendFlags |= ImGuiBackendFlags_HasGamepad.\n\nRead instructions in imgui.cpp for details.")
      (update-2nd config.flags (ImGui.CheckboxFlags ctx :ConfigFlags_NavEnableKeyboard $ (ImGui.ConfigFlags_NavEnableKeyboard)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Enable keyboard controls.")
      ;; ImGui.CheckboxFlags("io.ConfigFlags: NavEnableGamepad",     &io.ConfigFlags, ImGuiConfigFlags_NavEnableGamepad)
      ;; ImGui.SameLine(ctx); demo.HelpMarker("Enable gamepad controls. Require backend to set io.BackendFlags |= ImGuiBackendFlags_HasGamepad.\n\nRead instructions in imgui.cpp for details.")
      (update-2nd config.flags (ImGui.CheckboxFlags ctx :ConfigFlags_NavEnableSetMousePos $ (ImGui.ConfigFlags_NavEnableSetMousePos)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Instruct navigation to move the mouse cursor.")
      (update-2nd config.flags (ImGui.CheckboxFlags ctx :ConfigFlags_NoMouse $ (ImGui.ConfigFlags_NoMouse)))
      (when (not= (band config.flags (ImGui.ConfigFlags_NoMouse)) 0)
        ;; The "NoMouse" option can get us stuck with a disabled mouse! Let's provide an alternative way to fix it:
        (when (< (% (ImGui.GetTime ctx) 0.40)
                 0.20)
          (ImGui.SameLine ctx)
          (ImGui.Text ctx "<<PRESS SPACE TO DISABLE>>"))
        (when (ImGui.IsKeyPressed ctx (ImGui.Key_Space))
          (set config.flags (band config.flags (bnot (ImGui.ConfigFlags_NoMouse))))))
      (update-2nd config.flags (ImGui.CheckboxFlags ctx :ConfigFlags_NoMouseCursorChange $ (ImGui.ConfigFlags_NoMouseCursorChange)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Instruct backend to not alter mouse cursor shape and visibility.")
      (update-2nd config.flags (ImGui.CheckboxFlags ctx :ConfigFlags_NoSavedSettings $ (ImGui.ConfigFlags_NoSavedSettings)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Globally disable loading and saving state to an .ini file")

      (update-2nd config.flags (ImGui.CheckboxFlags ctx :ConfigFlags_DockingEnable $ (ImGui.ConfigFlags_DockingEnable)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker 
        (format "Drag from window title bar or their tab to dock/undock. Hold SHIFT to %s docking.\n\nDrag from window menu button (upper-left button) to undock an entire node (all windows)."
                (if (ImGui.GetConfigVar ctx (ImGui.ConfigVar_DockingWithShift)) :enable :disable)))
      (when (not= 0 (band config.flags (ImGui.ConfigFlags_DockingEnable)))
        (ImGui.Indent ctx)
        (config-var-checkbox :ConfigVar_DockingNoSplit)
        (ImGui.SameLine ctx)
        (demo.HelpMarker "Simplified docking mode: disable window splitting, so docking is limited to merging multiple windows together into tab-bars.")
        (config-var-checkbox :ConfigVar_DockingWithShift)
        (ImGui.SameLine ctx)
        (demo.HelpMarker "Enable docking when holding Shift only (allow to drop in wider space, reduce visual noise)")
        ;; ImGui.Checkbox(ctx, 'io.ConfigDockingAlwaysTabBar', &io.ConfigDockingAlwaysTabBar)
        ;; ImGui.SameLine(ctx); demo.HelpMarker('Create a docking node and tab-bar on single floating windows.')
        (config-var-checkbox :ConfigVar_DockingTransparentPayload)
        (ImGui.SameLine ctx)
        (demo.HelpMarker "Make window or viewport transparent when docking and only display docking boxes on the target viewport.")
        (ImGui.Unindent ctx))
      ;; ImGui::CheckboxFlags("io.ConfigFlags: ViewportsEnable", &io.ConfigFlags, ImGuiConfigFlags_ViewportsEnable);
      ;; ImGui::SameLine(); HelpMarker("[beta] Enable beta multi-viewports support. See ImGuiPlatformIO for details.");
      ;; if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable)
      ;; {
      ;;     ImGui::Indent();
      ;;     ImGui::Checkbox("io.ConfigViewportsNoAutoMerge", &io.ConfigViewportsNoAutoMerge);
      ;;     ImGui::SameLine(); HelpMarker("Set to make all floating imgui windows always create their own viewport. Otherwise, they are merged into the main host viewports when overlapping it.");
      ;;     ImGui::Checkbox("io.ConfigViewportsNoTaskBarIcon", &io.ConfigViewportsNoTaskBarIcon);
      ;;     ImGui::SameLine(); HelpMarker("Toggling this at runtime is normally unsupported (most platform backends won't refresh the task bar icon state right away).");
      (config-var-checkbox :ConfigVar_ViewportsNoDecoration)
      ;;     ImGui::Checkbox("io.ConfigViewportsNoDefaultParent", &io.ConfigViewportsNoDefaultParent);
      ;;     ImGui::SameLine(); HelpMarker("Toggling this at runtime is normally unsupported (most platform backends won't refresh the parenting right away).");
      ;;     ImGui::Unindent();
      ;; }
      (config-var-checkbox :ConfigVar_InputTrickleEventQueue)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Enable input queue trickling: some types of events submitted during the same frame (e.g. button down + up) will be spread over multiple frames, improving interactions with low framerates.")
      ;; ImGui.Checkbox(ctx, 'io.MouseDrawCursor', &io.MouseDrawCursor)
      ;; ImGui.SameLine(ctx); HelpMarker('Instruct Dear ImGui to render a mouse cursor itself. Note that a mouse cursor rendered via your application GPU rendering path will feel more laggy than hardware cursor, but will be more in sync with your other visuals.\n\nSome desktop applications may use both kinds of cursors (e.g. enable software cursor only when resizing/dragging something).')

      (ImGui.SeparatorText ctx :Widgets)
      (config-var-checkbox :ConfigVar_InputTextCursorBlink)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Enable blinking cursor (optional as some users consider it to be distracting).")
      (config-var-checkbox :ConfigVar_InputTextEnterKeepActive)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Pressing Enter will keep item active and select contents (single-line only).")
      (config-var-checkbox :ConfigVar_DragClickToInputText)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving).")
      (config-var-checkbox :ConfigVar_WindowsResizeFromEdges)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Enable resizing of windows from their edges and from the lower-left corner.")
      (config-var-checkbox :ConfigVar_WindowsMoveFromTitleBarOnly)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Does not apply to windows without a title bar.")
      (config-var-checkbox :ConfigVar_MacOSXBehaviors)
      (ImGui.Text ctx "Also see Style->Rendering for rendering options.")

      (ImGui.SetConfigVar ctx (ImGui.ConfigVar_Flags) config.flags)
      (ImGui.TreePop ctx)
      (ImGui.Spacing ctx))

;;         if (ImGui.TreeNode("Backend Flags"))
;;         {
;;             HelpMarker(
;;                 "Those flags are set by the backends (imgui_impl_xxx files) to specify their capabilities.\n"
;;                 "Here we expose then as read-only fields to avoid breaking interactions with your backend.");
;;
;;             // Make a local copy to avoid modifying actual backend flags.
;;             // FIXME: We don't use BeginDisabled() to keep label bright, maybe we need a BeginReadonly() equivalent..
;;             ImGuiBackendFlags backend_flags = io.BackendFlags;
;;             ImGui::CheckboxFlags("io.BackendFlags: HasGamepad",             &backend_flags, ImGuiBackendFlags_HasGamepad);
;;             ImGui::CheckboxFlags("io.BackendFlags: HasMouseCursors",        &backend_flags, ImGuiBackendFlags_HasMouseCursors);
;;             ImGui::CheckboxFlags("io.BackendFlags: HasSetMousePos",         &backend_flags, ImGuiBackendFlags_HasSetMousePos);
;;             ImGui::CheckboxFlags("io.BackendFlags: PlatformHasViewports",   &backend_flags, ImGuiBackendFlags_PlatformHasViewports);
;;             ImGui::CheckboxFlags("io.BackendFlags: HasMouseHoveredViewport",&backend_flags, ImGuiBackendFlags_HasMouseHoveredViewport);
;;             ImGui::CheckboxFlags("io.BackendFlags: RendererHasVtxOffset",   &backend_flags, ImGuiBackendFlags_RendererHasVtxOffset);
;;             ImGui::CheckboxFlags("io.BackendFlags: RendererHasViewports",   &backend_flags, ImGuiBackendFlags_RendererHasViewports);
;;             ImGui.TreePop();
;;             ImGui.Spacing();
;;         }

    (when (ImGui.TreeNode ctx :Style)
      (demo.HelpMarker "The same contents can be accessed in 'Tools->Style Editor'.")
      (demo.ShowStyleEditor)
      (ImGui.TreePop ctx)
      (ImGui.Spacing ctx))
    (when (ImGui.TreeNode ctx :Capture/Logging)
      (set-when-not config.logging {:auto_open_depth 2})
      (demo.HelpMarker "The logging API redirects all text output so you can easily capture the content of a window or a block. Tree nodes can be automatically expanded.\nTry opening any of the contents below in this window and then click one of the \"Log To\" button.")
      (ImGui.PushID ctx :LogButtons)
      (let [log-to-tty (ImGui.Button ctx "Log To TTY")
            _ (ImGui.SameLine ctx)
            log-to-file (ImGui.Button ctx "Log To File")
            _ (ImGui.SameLine ctx)
            log-to-clipboard (ImGui.Button ctx "Log To Clipboard")
            _ (do
                (ImGui.SameLine ctx)
                (ImGui.PushAllowKeyboardFocus ctx false)
                (ImGui.SetNextItemWidth ctx 80)
                (update-2nd config.logging.auto_open_depth (ImGui.SliderInt ctx "Open Depth" $ 0 9))
                (ImGui.PopAllowKeyboardFocus ctx)
                (ImGui.PopID ctx))
            ;; Start logging at the end of the function so that the buttons don't appear in the log
            depth config.logging.auto_open_depth]
        (when log-to-tty (ImGui.LogToTTY ctx depth))
        (when log-to-file (ImGui.LogToFile ctx depth))
        (when log-to-clipboard (ImGui.LogToClipboard ctx depth)))

      (demo.HelpMarker "You can also call ImGui.LogText() to output directly to the log without a visual output.")
      (when (ImGui.Button ctx "Copy \"Hello, world!\" to clipboard")
        (ImGui.LogToClipboard ctx depth)
        (ImGui.LogText ctx "Hello, world!")
        (ImGui.LogFinish ctx))
      (ImGui.TreePop ctx)))

  (when (ImGui.CollapsingHeader ctx "Window options")
    (when (ImGui.BeginTable ctx :split 3)
      (ImGui.TableNextColumn ctx)
      (macro table-column! [ctx str fld]
        (assert-compile (sym? ctx))
        `(do (ImGui.TableNextColumn ,ctx)
           (set (_ ,fld) (ImGui.Checkbox ,ctx ,str ,fld))))
      (table-column! ctx "Always on top" demo.topmost)
      (table-column! ctx "No titlebar"   demo.no_titlebar)
      (table-column! ctx "No scrollbar"  demo.no_scrollbar)
      (table-column! ctx "No menu"       demo.no_menu)
      (table-column! ctx "No move"       demo.no_move)
      (table-column! ctx "No resize"     demo.no_resize)
      (table-column! ctx "No collapse"   demo.no_collapse)
      (table-column! ctx "No close"      demo.no_close)
      (table-column! ctx "No nav"        demo.no_nav)
      (table-column! ctx "No background" demo.no_background)
      ;;(table-column! ctx "No bring to front" demo.no_bring_to_front)
      (table-column! ctx "No docking" demo.no_docking)
      (table-column! ctx "Unsaved document" demo.unsaved_document)
      (ImGui.EndTable ctx))

    (local flags (ImGui.GetConfigVar ctx (ImGui.ConfigVar_Flags)))
    (local docking-disabled (or demo.no_docking
                                (= (band flags (ImGui.ConfigFlags_DockingEnable))
                                   0)))

    (ImGui.Spacing ctx)
    (when docking-disabled (ImGui.BeginDisabled ctx))

    (let [dock-id (ImGui.GetWindowDockID ctx)]
      (ImGui.AlignTextToFramePadding ctx)
      (ImGui.Text ctx "Dock in docker:")
      (ImGui.SameLine ctx)
      (ImGui.SetNextItemWidth ctx 222)
      (when (ImGui.BeginCombo ctx "##docker" (demo.DockName dock-id))
        (when (ImGui.Selectable ctx :Floating (= dock-id 0))
          (set demo.set_dock_id 0))
        (for [id (- 1) (- 16) (- 1)]
          (when (ImGui.Selectable ctx (demo.DockName id) (= dock-id id))
            (set demo.set_dock_id id)))
        (ImGui.EndCombo ctx)))

    (when docking-disabled
      (ImGui.SameLine ctx)
      (ImGui.Text ctx (: "Disabled via %s" :format (if demo.no_docking :WindowFlags :ConfigFlags)))
      (ImGui.EndDisabled ctx)))

  ;; All demo contents
  (demo.ShowDemoWindowWidgets)
  (demo.ShowDemoWindowLayout)
  (demo.ShowDemoWindowPopups)
  (demo.ShowDemoWindowTables)
  (demo.ShowDemoWindowInputs)

  ;; End of ShowDemoWindow()
  (ImGui.PopItemWidth ctx)
  (ImGui.End ctx)
  open)

(fn demo.ShowDemoWindowWidgets []
  (when (ImGui.CollapsingHeader ctx :Widgets)
    (when widgets.disable_all (ImGui.BeginDisabled ctx))
    (var rv nil)
    (when (ImGui.TreeNode ctx :Basic)
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
      (ImGui.SeparatorText ctx :General)
      (when (ImGui.Button ctx :Button)
        (set widgets.basic.clicked (+ widgets.basic.clicked 1)))
      (when (not= (band widgets.basic.clicked 1) 0) (ImGui.SameLine ctx)
        (ImGui.Text ctx "Thanks for clicking me!"))
      (update-2nd widgets.basic.check (ImGui.Checkbox ctx :checkbox $))
      (update-2nd widgets.basic.radio (ImGui.RadioButtonEx ctx "radio a" $ 0))
      (ImGui.SameLine ctx)
      (update-2nd widgets.basic.radio (ImGui.RadioButtonEx ctx "radio b" $ 1))
      (ImGui.SameLine ctx)
      (update-2nd widgets.basic.radio (ImGui.RadioButtonEx ctx "radio c" $ 2))
      (for [i 0 6]
        (when (> i 0) (ImGui.SameLine ctx))
        (ImGui.PushID ctx i)
        (ImGui.PushStyleColor ctx (ImGui.Col_Button)
                              (demo.HSV (/ i 7) 0.6 0.6 1))
        (ImGui.PushStyleColor ctx (ImGui.Col_ButtonHovered)
                              (demo.HSV (/ i 7) 0.7 0.7 1))
        (ImGui.PushStyleColor ctx (ImGui.Col_ButtonActive)
                              (demo.HSV (/ i 7) 0.8 0.8 1))
        (ImGui.Button ctx :Click)
        (ImGui.PopStyleColor ctx 3)
        (ImGui.PopID ctx))
      (ImGui.AlignTextToFramePadding ctx)
      (ImGui.Text ctx "Hold to repeat:")
      (ImGui.SameLine ctx)
      (local spacing (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemInnerSpacing)))
      (ImGui.PushButtonRepeat ctx true)
      (when (ImGui.ArrowButton ctx "##left" (ImGui.Dir_Left))
        (set widgets.basic.counter (- widgets.basic.counter 1)))
      (ImGui.SameLine ctx 0 spacing)
      (when (ImGui.ArrowButton ctx "##right" (ImGui.Dir_Right))
        (set widgets.basic.counter (+ widgets.basic.counter 1)))
      (ImGui.PopButtonRepeat ctx)
      (ImGui.SameLine ctx)
      (ImGui.Text ctx (: "%d" :format widgets.basic.counter))
      (do
        (ImGui.Text ctx "Tooltips:")
        (ImGui.SameLine ctx)
        (ImGui.Button ctx :Button)
        (when (ImGui.IsItemHovered ctx) (ImGui.SetTooltip ctx "I am a tooltip"))
        (ImGui.SameLine ctx)
        (ImGui.Button ctx :Fancy)
        (when (ImGui.IsItemHovered ctx)
          (ImGui.BeginTooltip ctx)
          (ImGui.Text ctx "I am a fancy tooltip")
          (ImGui.PlotLines ctx :Curve widgets.basic.tooltip)
          (ImGui.Text ctx
                      (: "Sin(time) = %f" :format
                         (math.sin (ImGui.GetTime ctx))))
          (ImGui.EndTooltip ctx))
        (ImGui.SameLine ctx)
        (ImGui.Button ctx :Delayed)
        (when (ImGui.IsItemHovered ctx (ImGui.HoveredFlags_DelayNormal))
          (ImGui.SetTooltip ctx "I am a tooltip with a delay."))
        (ImGui.SameLine ctx)
        (demo.HelpMarker "Tooltip are created by using the IsItemHovered() function over any kind of item."))
      (ImGui.LabelText ctx :label :Value)
      (ImGui.SeparatorText ctx :Inputs)
      (do
        (update-2nd widgets.basic.str0 (ImGui.InputText ctx "input text" $))
        (ImGui.SameLine ctx)
        (demo.HelpMarker "USER:
        Hold SHIFT or use mouse to select text.
        CTRL+Left/Right to word jump.
        CTRL+A or double-click to select all.
        CTRL+X,CTRL+C,CTRL+V clipboard.
        CTRL+Z,CTRL+Y undo/redo.
        ESCAPE to revert.

        ")
        (update-2nd widgets.basic.str1 (ImGui.InputTextWithHint ctx "input text (w/ hint)" "enter text here" $))
        (update-2nd widgets.basic.i0 (ImGui.InputInt ctx "input int" $))
        (update-2nd widgets.basic.d0 (ImGui.InputDouble ctx "input double" $ 0.01 1 "%.8f"))
        (update-2nd widgets.basic.d1 (ImGui.InputDouble ctx "input scientific" $ 0 0 "%e"))
        (ImGui.SameLine ctx)
        (demo.HelpMarker "You can input value using the scientific notation,
        e.g. \"1e+8\" becomes \"100000000\".")
        (ImGui.InputDoubleN ctx "input reaper.array" widgets.basic.vec4a))
(ImGui.SeparatorText ctx :Drags)
(do
  (set (rv widgets.basic.i1)
       (ImGui.DragInt ctx "drag int" widgets.basic.i1 1))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Click and drag to edit value.
  Hold SHIFT/ALT for faster/slower edit.
  Double-click or CTRL+click to input value.")
  (set (rv widgets.basic.i2)
       (ImGui.DragInt ctx "drag int 0..100" widgets.basic.i2 1 0 100
                      "%d%%" (ImGui.SliderFlags_AlwaysClamp)))
  (set (rv widgets.basic.d2)
       (ImGui.DragDouble ctx "drag double" widgets.basic.d2 0.005))
  (set (rv widgets.basic.d3)
       (ImGui.DragDouble ctx "drag small double" widgets.basic.d3 0.0001 0
                         0 "%.06f ns")))
(ImGui.SeparatorText ctx :Sliders)
(do
  (set (rv widgets.basic.i3)
       (ImGui.SliderInt ctx "slider int" widgets.basic.i3 (- 1) 3))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "CTRL+click to input value.")
  (set (rv widgets.basic.d4)
       (ImGui.SliderDouble ctx "slider double" widgets.basic.d4 0 1
                           "ratio = %.3f"))
  (set (rv widgets.basic.d5)
       (ImGui.SliderDouble ctx "slider double (log)" widgets.basic.d5
                           (- 10) 10 "%.4f"
                           (ImGui.SliderFlags_Logarithmic)))
  (set (rv widgets.basic.angle)
       (ImGui.SliderAngle ctx "slider angle" widgets.basic.angle))
  (local elements [:Fire :Earth :Air :Water])
  (local current-elem (or (. elements widgets.basic.elem) :Unknown))
  (set (rv widgets.basic.elem)
       (ImGui.SliderInt ctx "slider enum" widgets.basic.elem 1
                        (length elements) current-elem))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Using the format string parameter to display a name instead of the underlying integer."))
(ImGui.SeparatorText ctx :Selectors/Pickers)
(do
  (global foo widgets.basic.col1)
  (set (rv widgets.basic.col1)
       (ImGui.ColorEdit3 ctx "color 1" widgets.basic.col1))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Click on the color square to open a color picker.
  Click and hold to use drag and drop.
  Right-click on the color square to show options.
  CTRL+click on individual component to input value.")
  (set (rv widgets.basic.col2)
       (ImGui.ColorEdit4 ctx "color 2" widgets.basic.col2)))
(let [items "AAAA\000BBBB\000CCCC\000DDDD\000EEEE\000FFFF\000GGGG\000HHHH\000IIIIIII\000JJJJ\000KKKKKKK\000"]
  (set (rv widgets.basic.curitem)
       (ImGui.Combo ctx :combo widgets.basic.curitem items))
  (ImGui.SameLine ctx)
  (demo.HelpMarker (.. "Using the simplified one-liner Combo API here.\n"
                       "Refer to the \"Combo\" section below for an explanation of how to use the more flexible and general BeginCombo/EndCombo API.")))
(let [items "Apple\000Banana\000Cherry\000Kiwi\000Mango\000Orange\000Pineapple\000Strawberry\000Watermelon\000"]
  (set (rv widgets.basic.listcur)
       (ImGui.ListBox ctx "listbox\n(single select)" widgets.basic.listcur
                      items 4))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Using the simplified one-liner ListBox API here.
  Refer to the \"List boxes\" section below for an explanation of how to usethe more flexible and general BeginListBox/EndListBox API."))
(ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Trees)
  (when (not widgets.trees)
    (set widgets.trees {:align_label_with_current_x_position false
                        :base_flags (bor (ImGui.TreeNodeFlags_OpenOnArrow)
                                         (ImGui.TreeNodeFlags_OpenOnDoubleClick)
                                         (ImGui.TreeNodeFlags_SpanAvailWidth))
                        :selection_mask (lshift 1 2)
                        :test_drag_and_drop false}))
  (when (ImGui.TreeNode ctx "Basic trees")
    (for [i 0 4]
      (when (= i 0) (ImGui.SetNextItemOpen ctx true (ImGui.Cond_Once)))
      (when (ImGui.TreeNodeEx ctx i (: "Child %d" :format i))
        (ImGui.Text ctx "blah blah")
        (ImGui.SameLine ctx)
        (when (ImGui.SmallButton ctx :button) nil)
        (ImGui.TreePop ctx)))
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "Advanced, with Selectable nodes")
    (demo.HelpMarker "This is a more typical looking tree with selectable nodes.
    Click to select, CTRL+Click to toggle, click on arrows or double-click to open.")
    (set (rv widgets.trees.base_flags)
         (ImGui.CheckboxFlags ctx :ImGui_TreeNodeFlags_OpenOnArrow
                              widgets.trees.base_flags
                              (ImGui.TreeNodeFlags_OpenOnArrow)))
    (set (rv widgets.trees.base_flags)
         (ImGui.CheckboxFlags ctx :ImGui_TreeNodeFlags_OpenOnDoubleClick
                              widgets.trees.base_flags
                              (ImGui.TreeNodeFlags_OpenOnDoubleClick)))
    (set (rv widgets.trees.base_flags)
         (ImGui.CheckboxFlags ctx :ImGui_TreeNodeFlags_SpanAvailWidth
                              widgets.trees.base_flags
                              (ImGui.TreeNodeFlags_SpanAvailWidth)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Extend hit area to all available width instead of allowing more items to be laid out after the node.")
    (set (rv widgets.trees.base_flags)
         (ImGui.CheckboxFlags ctx :ImGuiTreeNodeFlags_SpanFullWidth
                              widgets.trees.base_flags
                              (ImGui.TreeNodeFlags_SpanFullWidth)))
    (set (rv widgets.trees.align_label_with_current_x_position)
         (ImGui.Checkbox ctx "Align label with current X position"
                         widgets.trees.align_label_with_current_x_position))
    (set (rv widgets.trees.test_drag_and_drop)
         (ImGui.Checkbox ctx "Test tree node as drag source"
                         widgets.trees.test_drag_and_drop))
    (ImGui.Text ctx :Hello!)
    (when widgets.trees.align_label_with_current_x_position
      (ImGui.Unindent ctx (ImGui.GetTreeNodeToLabelSpacing ctx)))
    (var node-clicked (- 1))
    (for [i 0 5]
      (var node-flags widgets.trees.base_flags)
      (local is-selected (not= (band widgets.trees.selection_mask
                                     (lshift 1 i))
                               0))
      (when is-selected
        (set node-flags (bor node-flags (ImGui.TreeNodeFlags_Selected))))
      (if (< i 3) (let [node-open (ImGui.TreeNodeEx ctx i
                                                    (: "Selectable Node %d"
                                                       :format i)
                                                    node-flags)]
                    (when (and (ImGui.IsItemClicked ctx)
                               (not (ImGui.IsItemToggledOpen ctx)))
                      (set node-clicked i))
                    (when (and widgets.trees.test_drag_and_drop
                               (ImGui.BeginDragDropSource ctx))
                      (ImGui.SetDragDropPayload ctx :_TREENODE nil 0)
                      (ImGui.Text ctx "This is a drag and drop source")
                      (ImGui.EndDragDropSource ctx))
                    (when node-open
                      (ImGui.BulletText ctx "Blah blah\nBlah Blah")
                      (ImGui.TreePop ctx)))
        (do
          (set node-flags
               (bor node-flags
                    (ImGui.TreeNodeFlags_Leaf)
                    (ImGui.TreeNodeFlags_NoTreePushOnOpen)))
          (ImGui.TreeNodeEx ctx i (: "Selectable Leaf %d" :format i)
                            node-flags)
          (when (and (ImGui.IsItemClicked ctx)
                     (not (ImGui.IsItemToggledOpen ctx)))
            (set node-clicked i))
          (when (and widgets.trees.test_drag_and_drop
                     (ImGui.BeginDragDropSource ctx))
            (ImGui.SetDragDropPayload ctx :_TREENODE nil 0)
            (ImGui.Text ctx "This is a drag and drop source")
            (ImGui.EndDragDropSource ctx)))))
    (when (not= node-clicked (- 1))
      (if (ImGui.IsKeyDown ctx (ImGui.Mod_Ctrl))
        (set widgets.trees.selection_mask
             (bxor widgets.trees.selection_mask (lshift 1 node-clicked)))
        (= (band widgets.trees.selection_mask (lshift 1 node-clicked)) 0)
        (set widgets.trees.selection_mask (lshift 1 node-clicked))))
    (when widgets.trees.align_label_with_current_x_position
      (ImGui.Indent ctx (ImGui.GetTreeNodeToLabelSpacing ctx)))
    (ImGui.TreePop ctx))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Collapsing Headers")
  (when (not widgets.cheads) (set widgets.cheads {:closable_group true}))
  (set (rv widgets.cheads.closable_group)
       (ImGui.Checkbox ctx "Show 2nd header" widgets.cheads.closable_group))
  (when (ImGui.CollapsingHeader ctx :Header nil (ImGui.TreeNodeFlags_None))
    (ImGui.Text ctx (: "IsItemHovered: %s" :format
                       (ImGui.IsItemHovered ctx)))
    (for [i 0 4] (ImGui.Text ctx (: "Some content %s" :format i))))
  (when widgets.cheads.closable_group
    (set (rv widgets.cheads.closable_group)
         (ImGui.CollapsingHeader ctx "Header with a close button" true))
    (when rv
      (ImGui.Text ctx
                  (: "IsItemHovered: %s" :format (ImGui.IsItemHovered ctx)))
      (for [i 0 4] (ImGui.Text ctx (: "More content %d" :format i)))))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Bullets) (ImGui.BulletText ctx "Bullet point 1")
  (ImGui.BulletText ctx "Bullet point 2\nOn multiple lines")
  (when (ImGui.TreeNode ctx "Tree node")
    (ImGui.BulletText ctx "Another bullet point")
    (ImGui.TreePop ctx))
  (ImGui.Bullet ctx)
  (ImGui.Text ctx "Bullet point 3 (two calls)")
  (ImGui.Bullet ctx)
  (ImGui.SmallButton ctx :Button)
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Text)
  (when (not widgets.text)
    (set widgets.text {:utf8 "日本語" :wrap_width 200}))
  (when (ImGui.TreeNode ctx "Colorful Text")
    (ImGui.TextColored ctx 4278255615 :Pink)
    (ImGui.TextColored ctx 4294902015 :Yellow)
    (ImGui.TextDisabled ctx :Disabled)
    (ImGui.SameLine ctx)
    (demo.HelpMarker "The TextDisabled color is stored in ImGuiStyle.")
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "Word Wrapping")
    (ImGui.TextWrapped ctx
                       (.. "This text should automatically wrap on the edge of the window. The current implementation "
                           "for text wrapping follows simple rules suitable for English and possibly other languages."))
    (ImGui.Spacing ctx)
    (set (rv widgets.text.wrap_width)
         (ImGui.SliderDouble ctx "Wrap width" widgets.text.wrap_width (- 20)
                             600 "%.0f"))
    (local draw-list (ImGui.GetWindowDrawList ctx))
    (for [n 0 1]
      (ImGui.Text ctx (: "Test paragraph %d:" :format n))
      (local (screen-x screen-y) (ImGui.GetCursorScreenPos ctx))
      (local (marker-min-x marker-min-y)
        (values (+ screen-x widgets.text.wrap_width) screen-y))
      (local (marker-max-x marker-max-y)
        (values (+ (+ screen-x widgets.text.wrap_width) 10)
                (+ screen-y (ImGui.GetTextLineHeight ctx))))
      (local (window-x window-y) (ImGui.GetCursorPos ctx))
      (ImGui.PushTextWrapPos ctx (+ window-x widgets.text.wrap_width))
      (if (= n 0)
        (ImGui.Text ctx
                    (: "The lazy dog is a good dog. This paragraph should fit within %.0f pixels. Testing a 1 character word. The quick brown fox jumps over the lazy dog."
                       :format widgets.text.wrap_width))
        (ImGui.Text ctx
                    "aaaaaaaa bbbbbbbb, c cccccccc,dddddddd. d eeeeeeee   ffffffff. gggggggg!hhhhhhhh"))
      (local (text-min-x text-min-y) (ImGui.GetItemRectMin ctx))
      (local (text-max-x text-max-y) (ImGui.GetItemRectMax ctx))
      (ImGui.DrawList_AddRect draw-list text-min-x text-min-y text-max-x
                              text-max-y 4294902015)
      (ImGui.DrawList_AddRectFilled draw-list marker-min-x marker-min-y
                                    marker-max-x marker-max-y 4278255615)
      (ImGui.PopTextWrapPos ctx))
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "UTF-8 Text")
    (ImGui.TextWrapped ctx
                       "CJK text cannot be rendered due to current limitations regarding font rasterization. It is however safe to copy & paste from/into another application.")
    (demo.Link "https://github.com/cfillion/reaimgui/issues/5")
    (ImGui.Spacing ctx)
    (ImGui.Text ctx "Hiragana: かきくけこ (kakikukeko)")
    (ImGui.Text ctx "Kanjis: 日本語 (nihongo)")
    (set (rv widgets.text.utf8)
         (ImGui.InputText ctx "UTF-8 input" widgets.text.utf8))
    (ImGui.TreePop ctx))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Images)
  (when (not widgets.images)
    (set widgets.images {:pressed_count 0 :use_text_color_for_tint false}))
  (when (not (ImGui.ValidatePtr widgets.images.bitmap :ImGui_Image*))
    (set widgets.images.bitmap
         (ImGui.CreateImageFromMem "\137PNG\r
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
    (ImGui.TextWrapped ctx "Hover the texture for a zoomed view!")
    (local (my-tex-w my-tex-h) (ImGui.Image_GetSize widgets.images.bitmap))
    (do
      (set (rv widgets.images.use_text_color_for_tint)
           (ImGui.Checkbox ctx "Use Text Color for Tint"
                            widgets.images.use_text_color_for_tint))
      (ImGui.Text ctx (: "%.0fx%.0f" :format my-tex-w my-tex-h))
      (local (pos-x pos-y) (ImGui.GetCursorScreenPos ctx))
      (local (uv-min-x uv-min-y) (values 0 0))
      (local (uv-max-x uv-max-y) (values 1 1))
      (local tint-col (or (and widgets.images.use_text_color_for_tint
                               (ImGui.GetStyleColor ctx (ImGui.Col_Text)))
                          4294967295))
      (local border-col (ImGui.GetStyleColor ctx (ImGui.Col_Border)))
      (ImGui.Image ctx widgets.images.bitmap my-tex-w my-tex-h uv-min-x
                    uv-min-y uv-max-x uv-max-y tint-col border-col)
      (when (ImGui.IsItemHovered ctx)
        (ImGui.BeginTooltip ctx)
        (local region-sz 32)
        (local (mouse-x mouse-y) (ImGui.GetMousePos ctx))
        (var region-x (- (- mouse-x pos-x) (* region-sz 0.5)))
        (var region-y (- (- mouse-y pos-y) (* region-sz 0.5)))
        (local zoom 4)
        (if (< region-x 0) (set region-x 0)
            (> region-x (- my-tex-w region-sz)) (set region-x
                                                     (- my-tex-w region-sz)))
        (if (< region-y 0) (set region-y 0)
            (> region-y (- my-tex-h region-sz)) (set region-y
                                                     (- my-tex-h region-sz)))
        (ImGui.Text ctx (: "Min: (%.2f, %.2f)" :format region-x region-y))
        (ImGui.Text ctx (: "Max: (%.2f, %.2f)" :format (+ region-x region-sz)
                            (+ region-y region-sz)))
        (local (uv0-x uv0-y)
               (values (/ region-x my-tex-w) (/ region-y my-tex-h)))
        (local (uv1-x uv1-y)
               (values (/ (+ region-x region-sz) my-tex-w)
                       (/ (+ region-y region-sz) my-tex-h)))
        (ImGui.Image ctx widgets.images.bitmap (* region-sz zoom)
                      (* region-sz zoom) uv0-x uv0-y uv1-x uv1-y tint-col
                      border-col)
        (ImGui.EndTooltip ctx)))
    (ImGui.TextWrapped ctx "And now some textured buttons...")
    (for [i 0 8]
      (when (> i 0)
        (ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) (- i 1) (- i 1)))
      (local (size-w size-h) (values 32 32))
      (local (uv0-x uv0-y) (values 0 0))
      (local (uv1-x uv1-y) (values (/ 32 my-tex-w) (/ 32 my-tex-h)))
      (local bg-col 255)
      (local tint-col 4294967295)
      (when (ImGui.ImageButton ctx i widgets.images.bitmap size-w size-h uv0-x
                                uv0-y uv1-x uv1-y bg-col tint-col)
        (set widgets.images.pressed_count (+ widgets.images.pressed_count 1)))
      (when (> i 0) (ImGui.PopStyleVar ctx))
      (ImGui.SameLine ctx))
    (ImGui.NewLine ctx)
    (ImGui.Text ctx (: "Pressed %d times." :format
                        widgets.images.pressed_count))
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx :Combo)
    (when (not widgets.combos)
      (set widgets.combos
           {:current_item1 1
            :current_item2 0
            :current_item3 (- 1)
            :flags (ImGui.ComboFlags_None)}))
    (set (rv widgets.combos.flags)
         (ImGui.CheckboxFlags ctx :ImGuiComboFlags_PopupAlignLeft
                               widgets.combos.flags
                               (ImGui.ComboFlags_PopupAlignLeft)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Only makes a difference if the popup is larger than the combo")
    (set (rv widgets.combos.flags)
         (ImGui.CheckboxFlags ctx :ImGuiComboFlags_NoArrowButton
                               widgets.combos.flags
                               (ImGui.ComboFlags_NoArrowButton)))
    (when rv
      (set widgets.combos.flags
           (band widgets.combos.flags (bnot (ImGui.ComboFlags_NoPreview)))))
    (set (rv widgets.combos.flags)
         (ImGui.CheckboxFlags ctx :ImGuiComboFlags_NoPreview
                               widgets.combos.flags
                               (ImGui.ComboFlags_NoPreview)))
    (when rv
      (set widgets.combos.flags
           (band widgets.combos.flags (bnot (ImGui.ComboFlags_NoArrowButton)))))
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
    (when (ImGui.BeginCombo ctx "combo 1" combo-preview-value
                             widgets.combos.flags)
      (each [i v (ipairs combo-items)]
        (local is-selected (= widgets.combos.current_item1 i))
        (when (ImGui.Selectable ctx (. combo-items i) is-selected)
          (set widgets.combos.current_item1 i))
        (when is-selected (ImGui.SetItemDefaultFocus ctx)))
      (ImGui.EndCombo ctx))
    (set combo-items "aaaa\000bbbb\000cccc\000dddd\000eeee\000")
    (set (rv widgets.combos.current_item2)
         (ImGui.Combo ctx "combo 2 (one-liner)" widgets.combos.current_item2
                       combo-items))
    (set (rv widgets.combos.current_item3)
         (ImGui.Combo ctx "combo 3 (out of range)"
                       widgets.combos.current_item3 combo-items))
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "List boxes")
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
    (when (ImGui.BeginListBox ctx "listbox 1")
      (each [n v (ipairs items)]
        (local is-selected (= widgets.lists.current_idx n))
        (when (ImGui.Selectable ctx v is-selected)
          (set widgets.lists.current_idx n))
        (when is-selected (ImGui.SetItemDefaultFocus ctx)))
      (ImGui.EndListBox ctx))
    (ImGui.Text ctx "Full-width:")
    (when (ImGui.BeginListBox ctx "##listbox 2" (- FLT_MIN)
                               (* 5 (ImGui.GetTextLineHeightWithSpacing ctx)))
      (each [n v (ipairs items)]
        (local is-selected (= widgets.lists.current_idx n))
        (when (ImGui.Selectable ctx v is-selected)
          (set widgets.lists.current_idx n))
        (when is-selected (ImGui.SetItemDefaultFocus ctx)))
      (ImGui.EndListBox ctx))
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx :Selectables)
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
    (when (ImGui.TreeNode ctx :Basic)
      (var b1 nil)
      (var b2 nil)
      (var b4 nil)
      (set-forcibly! (rv b1)
                     (ImGui.Selectable ctx "1. I am selectable"
                                        (. widgets.selectables.basic 1)))
      (tset widgets.selectables.basic 1 b1)
      (set-forcibly! (rv b2)
                     (ImGui.Selectable ctx "2. I am selectable"
                                        (. widgets.selectables.basic 2)))
      (tset widgets.selectables.basic 2 b2)
      (ImGui.Text ctx "(I am not selectable)")
      (set-forcibly! (rv b4)
                     (ImGui.Selectable ctx "4. I am selectable"
                                        (. widgets.selectables.basic 4)))
      (tset widgets.selectables.basic 4 b4)
      (when (ImGui.Selectable ctx "5. I am double clickable"
                               (. widgets.selectables.basic 5)
                               (ImGui.SelectableFlags_AllowDoubleClick))
        (when (ImGui.IsMouseDoubleClicked ctx 0)
          (tset widgets.selectables.basic 5
                (not (. widgets.selectables.basic 5)))))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Selection State: Single Selection")
      (for [i 0 4]
        (when (ImGui.Selectable ctx (: "Object %d" :format i)
                                 (= widgets.selectables.single i))
          (set widgets.selectables.single i)))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Selection State: Multiple Selection")
      (demo.HelpMarker "Hold CTRL and click to select multiple items.")
      (each [i sel (ipairs widgets.selectables.multiple)]
        (when (ImGui.Selectable ctx (: "Object %d" :format (- i 1)) sel)
          (when (not (ImGui.IsKeyDown ctx (ImGui.Mod_Ctrl)))
            (for [j 1 (length widgets.selectables.multiple)]
              (tset widgets.selectables.multiple j false)))
          (tset widgets.selectables.multiple i (not sel))))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Rendering more text into the same line")
      (var s1 nil)
      (var s2 nil)
      (var s3 nil)
      (set-forcibly! (rv s1)
                     (ImGui.Selectable ctx :main.c
                                        (. widgets.selectables.sameline 1)))
      (tset widgets.selectables.sameline 1 s1)
      (ImGui.SameLine ctx 300)
      (ImGui.Text ctx " 2,345 bytes")
      (set-forcibly! (rv s2)
                     (ImGui.Selectable ctx :Hello.cpp
                                        (. widgets.selectables.sameline 2)))
      (tset widgets.selectables.sameline 2 s2)
      (ImGui.SameLine ctx 300)
      (ImGui.Text ctx "12,345 bytes")
      (set-forcibly! (rv s3)
                     (ImGui.Selectable ctx :Hello.h
                                        (. widgets.selectables.sameline 3)))
      (tset widgets.selectables.sameline 3 s3)
      (ImGui.SameLine ctx 300)
      (ImGui.Text ctx " 2,345 bytes")
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "In columns")
      (when (ImGui.BeginTable ctx :split1 3
                               (bor (ImGui.TableFlags_Resizable)
                                    (ImGui.TableFlags_NoSavedSettings)
                                    (ImGui.TableFlags_Borders)))
        (each [i sel (ipairs widgets.selectables.columns)]
          (ImGui.TableNextColumn ctx)
          (var ci nil)
          (set-forcibly! (rv ci)
                         (ImGui.Selectable ctx (: "Item %d" :format (- i 1))
                                            sel))
          (tset widgets.selectables.columns i ci))
        (ImGui.EndTable ctx))
      (ImGui.Spacing ctx)
      (when (ImGui.BeginTable ctx :split2 3
                               (bor (ImGui.TableFlags_Resizable)
                                    (ImGui.TableFlags_NoSavedSettings)
                                    (ImGui.TableFlags_Borders)))
        (each [i sel (ipairs widgets.selectables.columns)]
          (ImGui.TableNextRow ctx)
          (ImGui.TableNextColumn ctx)
          (var ci nil)
          (set-forcibly! (rv ci)
                         (ImGui.Selectable ctx (: "Item %d" :format (- i 1))
                                            sel
                                            (ImGui.SelectableFlags_SpanAllColumns)))
          (tset widgets.selectables.columns i ci)
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx "Some other contents")
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx :123456))
        (ImGui.EndTable ctx))
      (ImGui.TreePop ctx))

    ;; Add in a bit of silly fun...
    (when (ImGui.TreeNode ctx :Grid)
      (var winning-state true) ;; If all cells are selected...
      (each [_ row (ipairs widgets.selectables.grid) &until (not winning-state)]
        (each [_ sel (ipairs row) &until (not winning-state)]
          (when (not sel)
            (set winning-state false))))
      (when winning-state
        (local time (ImGui.GetTime ctx))
        (ImGui.PushStyleVar ctx (ImGui.StyleVar_SelectableTextAlign)
                            (+ 0.5 (* 0.5 (math.cos (* time 2))))
                            (+ 0.5 (* 0.5 (math.sin (* time 3))))))
      (each [ri row (ipairs widgets.selectables.grid)]
        (each [ci col (ipairs row)]
          (when (> ci 1) (ImGui.SameLine ctx))
          (ImGui.PushID ctx (+ (* ri (length widgets.selectables.grid)) ci))
          (when (ImGui.Selectable ctx :Sailor col 0 50 50)
            ;; Toggle clicked cell + toggle neighbors
            (tset row ci (not (. row ci)))
            (when (> ci 1)
              (tset row (- ci 1) (not (. row (- ci 1)))))
            (when (< ci 4)
              (tset row (+ ci 1) (not (. row (+ ci 1)))))
            (when (> ri 1)
              (tset (. widgets.selectables.grid (- ri 1)) ci
                    (not (. widgets.selectables.grid (- ri 1) ci))))
            (when (< ri 4)
              (tset (. widgets.selectables.grid (+ ri 1)) ci
                    (not (. widgets.selectables.grid (+ ri 1) ci)))))
          (ImGui.PopID ctx)))
      (when winning-state (ImGui.PopStyleVar ctx))
      (ImGui.TreePop ctx))

    (when (ImGui.TreeNode ctx :Alignment)
      (demo.HelpMarker "By default, Selectables uses style.SelectableTextAlign but it can be overridden on a per-item basis using PushStyleVar(). You'll probably want to always keep your default situation to left-align otherwise it becomes difficult to layout multiple items on a same line")
      (for [y 1 3]
        (for [x 1 3]
          (local (align-x align-y) (values (/ (- x 1) 2) (/ (- y 1) 2)))
          (local name (: "(%.1f,%.1f)" :format align-x align-y))
          (when (> x 1) (ImGui.SameLine ctx))
          (ImGui.PushStyleVar ctx (ImGui.StyleVar_SelectableTextAlign)
                               align-x align-y)
          (local row (. widgets.selectables.align y))
          (let [(_ rx) (ImGui.Selectable ctx name (. row x)
                                         (ImGui.SelectableFlags_None) 80 80)]
            (tset row x rx))
          (ImGui.PopStyleVar ctx)))
      (ImGui.TreePop ctx))
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "Text Input")
    (when (not widgets.input)
      (set widgets.input {:buf ["" "" "" "" ""]
                          :flags (ImGui.InputTextFlags_AllowTabInput)
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

    (when (ImGui.TreeNode ctx "Multi-line Text Input")
      (update-2nd widgets.input.multiline.flags (ImGui.CheckboxFlags ctx :ImGuiInputTextFlags_ReadOnly $
                                                                     (ImGui.InputTextFlags_ReadOnly)))
      (update-2nd widgets.input.multiline.flags (ImGui.CheckboxFlags ctx :ImGuiInputTextFlags_AllowTabInput $
                                                                     (ImGui.InputTextFlags_AllowTabInput)))
      (update-2nd widgets.input.multiline.flags (ImGui.CheckboxFlags ctx :ImGuiInputTextFlags_CtrlEnterForNewLine $
                                                                     (ImGui.InputTextFlags_CtrlEnterForNewLine)))
      (update-2nd widgets.input.multiline.text
                  (ImGui.InputTextMultiline ctx "##source" $
                                            (- FLT_MIN) (* (ImGui.GetTextLineHeight ctx) 16)
                                            widgets.input.multiline.flags))
      (ImGui.TreePop ctx))

    (when (ImGui.TreeNode ctx "Filtered Text Input")
      ;; TODO
      ;; struct TextFilters
      ;; {
      ;;     // Return 0 (pass) if the character is 'i' or 'm' or 'g' or 'u' or 'i'
      ;;     static int FilterImGuiLetters(ImGuiInputTextCallbackData* data)
      ;;     {
      ;;         if (data->EventChar < 256 && strchr("imgui", (char)data->EventChar))
      ;;             return 0;
      ;;         return 1;
      ;;     }
      ;; };
      (update-2nd-array widgets.input.buf 1 (ImGui.InputText ctx :default $))
      (update-2nd-array widgets.input.buf 2 (ImGui.InputText ctx :decimal $ (ImGui.InputTextFlags_CharsDecimal)))
      (update-2nd-array widgets.input.buf 3
                        (ImGui.InputText ctx :hexadecimal $
                                         (bor (ImGui.InputTextFlags_CharsHexadecimal)
                                              (ImGui.InputTextFlags_CharsUppercase))))
      (update-2nd-array widgets.input.buf 4
                        (ImGui.InputText ctx :uppercase $
                                         (ImGui.InputTextFlags_CharsUppercase)))
      (update-2nd-array widgets.input.buf 5
                        (ImGui.InputText ctx "no blank" $
                                         (ImGui.InputTextFlags_CharsNoBlank)))
      ;; static char buf6[64] = ""; ImGui.InputText("\"imgui\" letters", buf6, 64, ImGuiInputTextFlags_CallbackCharFilter, TextFilters::FilterImGuiLetters)
      (ImGui.TreePop ctx))

    (when (ImGui.TreeNode ctx "Password Input")
      (update-2nd widgets.input.password (ImGui.InputText ctx :password $ (ImGui.InputTextFlags_Password)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Display all characters as '*'.
Disable clipboard cut and copy.
Disable logging.
")
      (update-2nd widgets.input.password (ImGui.InputTextWithHint ctx "password (w/ hint)" :<password> $ (ImGui.InputTextFlags_Password)))
      (update-2nd widgets.input.password (ImGui.InputText ctx "password (clear)" $))
      (ImGui.TreePop ctx))

;; TODO
;;         if (ImGui.TreeNode("Completion, History, Edit Callbacks"))
;;         {
;;             struct Funcs
;;             {
;;                 static int MyCallback(ImGuiInputTextCallbackData* data)
;;                 {
;;                     if (data->EventFlag == ImGuiInputTextFlags_CallbackCompletion)
;;                     {
;;                         data->InsertChars(data->CursorPos, "..");
;;                     }
;;                     else if (data->EventFlag == ImGuiInputTextFlags_CallbackHistory)
;;                     {
;;                         if (data->EventKey == ImGuiKey_UpArrow)
;;                         {
;;                             data->DeleteChars(0, data->BufTextLen);
;;                             data->InsertChars(0, "Pressed Up!");
;;                             data->SelectAll();
;;                         }
;;                         else if (data->EventKey == ImGuiKey_DownArrow)
;;                         {
;;                             data->DeleteChars(0, data->BufTextLen);
;;                             data->InsertChars(0, "Pressed Down!");
;;                             data->SelectAll();
;;                         }
;;                     }
;;                     else if (data->EventFlag == ImGuiInputTextFlags_CallbackEdit)
;;                     {
;;                         // Toggle casing of first character
;;                         char c = data->Buf[0];
;;                         if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) data->Buf[0] ^= 32;
;;                         data->BufDirty = true;
;;
;;                         // Increment a counter
;;                         int* p_int = (int*)data->UserData;
;;                         *p_int = *p_int + 1;
;;                     }
;;                     return 0;
;;                 }
;;             };
;;             static char buf1[64];
;;             ImGui.InputText("Completion", buf1, 64, ImGuiInputTextFlags_CallbackCompletion, Funcs::MyCallback);
;;             ImGui.SameLine(); HelpMarker("Here we append \"..\" each time Tab is pressed. See 'Examples>Console' for a more meaningful demonstration of using this callback.");
;;
;;             static char buf2[64];
;;             ImGui.InputText("History", buf2, 64, ImGuiInputTextFlags_CallbackHistory, Funcs::MyCallback);
;;             ImGui.SameLine(); HelpMarker("Here we replace and select text each time Up/Down are pressed. See 'Examples>Console' for a more meaningful demonstration of using this callback.");
;;
;;             static char buf3[64];
;;             static int edit_count = 0;
;;             ImGui.InputText("Edit", buf3, 64, ImGuiInputTextFlags_CallbackEdit, Funcs::MyCallback, (void*)&edit_count);
;;             ImGui.SameLine(); HelpMarker("Here we toggle the casing of the first character on every edit + count edits.");
;;             ImGui.SameLine(); ImGui.Text("(%d)", edit_count);
;;
;;             ImGui.TreePop();
;;         }
;;
;;         if (ImGui.TreeNode("Resize Callback"))
;;         {
;;             // To wire InputText() with std::string or any other custom string type,
;;             // you can use the ImGuiInputTextFlags_CallbackResize flag + create a custom ImGui_InputText() wrapper
;;             // using your preferred type. See misc/cpp/imgui_stdlib.h for an implementation of this using std::string.
;;             HelpMarker(
;;                 "Using ImGuiInputTextFlags_CallbackResize to wire your custom string type to InputText().\n\n"
;;                 "See misc/cpp/imgui_stdlib.h for an implementation of this for std::string.");
;;             struct Funcs
;;             {
;;                 static int MyResizeCallback(ImGuiInputTextCallbackData* data)
;;                 {
;;                     if (data->EventFlag == ImGuiInputTextFlags_CallbackResize)
;;                     {
;;                         ImVector<char>* my_str = (ImVector<char>*)data->UserData;
;;                         IM_ASSERT(my_str->begin() == data->Buf);
;;                         my_str->resize(data->BufSize); // NB: On resizing calls, generally data->BufSize == data->BufTextLen + 1
;;                         data->Buf = my_str->begin();
;;                     }
;;                     return 0;
;;                 }
;;
;;                 // Note: Because ImGui_ is a namespace you would typically add your own function into the namespace.
;;                 // For example, you code may declare a function 'ImGui_InputText(const char* label, MyString* my_str)'
;;                 static bool MyInputTextMultiline(const char* label, ImVector<char>* my_str, const ImVec2& size = ImVec2(0, 0), ImGuiInputTextFlags flags = 0)
;;                 {
;;                     IM_ASSERT((flags & ImGuiInputTextFlags_CallbackResize) == 0);
;;                     return ImGui.InputTextMultiline(label, my_str->begin(), (size_t)my_str->size(), size, flags | ImGuiInputTextFlags_CallbackResize, Funcs::MyResizeCallback, (void*)my_str);
;;                 }
;;             };
;;
;;             // For this demo we are using ImVector as a string container.
;;             // Note that because we need to store a terminating zero character, our size/capacity are 1 more
;;             // than usually reported by a typical string class.
;;             static ImVector<char> my_str;
;;             if (my_str.empty())
;;                 my_str.push_back(0);
;;             Funcs::MyInputTextMultiline("##MyStr", &my_str, ImVec2(-FLT_MIN, ImGui.GetTextLineHeight() * 16));
;;             ImGui.Text("Data: %p\nSize: %d\nCapacity: %d", (void*)my_str.begin(), my_str.size(), my_str.capacity());
;;             ImGui.TreePop();
;;         }
    (ImGui.TreePop ctx))

  (when (ImGui.TreeNode ctx :Tabs)
    (set-when-not widgets.tabs {:active [1 2 3]
                                :flags1 (ImGui.TabBarFlags_Reorderable)
                                :flags2 (bor (ImGui.TabBarFlags_AutoSelectNewTabs)
                                             (ImGui.TabBarFlags_Reorderable)
                                             (ImGui.TabBarFlags_FittingPolicyResizeDown))
                                :next_id 4
                                :opened [true true true true]
                                :show_leading_button true
                                :show_trailing_button true})
    (let [fitting-policy-mask (bor (ImGui.TabBarFlags_FittingPolicyResizeDown)
                                   (ImGui.TabBarFlags_FittingPolicyScroll))]
      (when (ImGui.TreeNode ctx :Basic)
        (when (ImGui.BeginTabBar ctx :MyTabBar (ImGui.TabBarFlags_None))
          (when (ImGui.BeginTabItem ctx :Avocado)
            (ImGui.Text ctx "This is the Avocado tab!\nblah blah blah blah blah")
            (ImGui.EndTabItem ctx))
          (when (ImGui.BeginTabItem ctx :Broccoli)
            (ImGui.Text ctx "This is the Broccoli tab!\nblah blah blah blah blah")
            (ImGui.EndTabItem ctx))
          (when (ImGui.BeginTabItem ctx :Cucumber)
            (ImGui.Text ctx "This is the Cucumber tab!\nblah blah blah blah blah")
            (ImGui.EndTabItem ctx))
          (ImGui.EndTabBar ctx))
        (ImGui.Separator ctx)
        (ImGui.TreePop ctx))

      (when (ImGui.TreeNode ctx "Advanced & Close Button")
        ;; Expose a couple of the available flags. In most cases you may just call BeginTabBar() with no flags (0).
        (update-2nd widgets.tabs.flags1 (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_Reorderable $ (ImGui.TabBarFlags_Reorderable)))
        (update-2nd widgets.tabs.flags1 (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_AutoSelectNewTabs $ (ImGui.TabBarFlags_AutoSelectNewTabs)))
        (update-2nd widgets.tabs.flags1 (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_TabListPopupButton $ (ImGui.TabBarFlags_TabListPopupButton)))
        (update-2nd widgets.tabs.flags1 (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_NoCloseWithMiddleMouseButton $ (ImGui.TabBarFlags_NoCloseWithMiddleMouseButton)))

        (when (= 0 (band widgets.tabs.flags1 fitting-policy-mask)) ;; was FittingPolicyDefault_
          (set widgets.tabs.flags1
               (bor widgets.tabs.flags1
                    (ImGui.TabBarFlags_FittingPolicyResizeDown))))
        (when (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyResizeDown
                                   widgets.tabs.flags1
                                   (ImGui.TabBarFlags_FittingPolicyResizeDown))
          (set widgets.tabs.flags1
               (bor (band widgets.tabs.flags1 (bnot fitting-policy-mask))
                    (ImGui.TabBarFlags_FittingPolicyResizeDown))))
        (when (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyScroll
                                   widgets.tabs.flags1
                                   (ImGui.TabBarFlags_FittingPolicyScroll))
          (set widgets.tabs.flags1
               (bor (band widgets.tabs.flags1 (bnot fitting-policy-mask))
                    (ImGui.TabBarFlags_FittingPolicyScroll))))

        ;; Tab Bar
        (let [names [:Artichoke :Beetroot :Celery :Daikon]]
          (each [n opened (ipairs widgets.tabs.opened)]
            (when (> n 1)
              (ImGui.SameLine ctx))
            (let [(_ on) (ImGui.Checkbox ctx (. names n) opened)]
              (tset widgets.tabs.opened n on)))

          ;; Passing a bool* to BeginTabItem() is similar to passing one to Begin():
          ;; the underlying bool will be set to false when the tab is closed.
          (when (ImGui.BeginTabBar ctx :MyTabBar widgets.tabs.flags1)
            (each [n opened (ipairs widgets.tabs.opened)]
              (when opened
                (let [(_ on) (ImGui.BeginTabItem ctx (. names n) true (ImGui.TabItemFlags_None))]
                  (tset widgets.tabs.opened n on))
                (when rv
                  (ImGui.Text ctx (: "This is the %s tab!" :format (. names n)))
                  (when (= 0 (band n 1))
                    (ImGui.Text ctx "I am an odd tab."))
                  (ImGui.EndTabItem ctx))))
            (ImGui.EndTabBar ctx))
          (ImGui.Separator ctx)
          (ImGui.TreePop ctx)))

      (when (ImGui.TreeNode ctx "TabItemButton & Leading/Trailing flags")
        ;; TabItemButton() and Leading/Trailing flags are distinct features which we will demo together.
        ;; (It is possible to submit regular tabs with Leading/Trailing flags, or TabItemButton tabs without Leading/Trailing flags...
        ;; but they tend to make more sense together)
        (update-2nd widgets.tabs.show_leading_button (ImGui.Checkbox ctx "Show Leading TabItemButton()" $))
        (update-2nd widgets.tabs.show_trailing_button (ImGui.Checkbox ctx "Show Trailing TabItemButton()" $))

        ;; Expose some other flags which are useful to showcase how they interact with Leading/Trailing tabs
        (update-2nd widgets.tabs.flags2 (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_TabListPopupButton $
                                                             (ImGui.TabBarFlags_TabListPopupButton)))
        (when (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyResizeDown
                                   widgets.tabs.flags2
                                   (ImGui.TabBarFlags_FittingPolicyResizeDown))
          (set widgets.tabs.flags2
               (bor (band widgets.tabs.flags2 (bnot fitting-policy-mask))
                    (ImGui.TabBarFlags_FittingPolicyResizeDown))))
        (when (ImGui.CheckboxFlags ctx :ImGuiTabBarFlags_FittingPolicyScroll
                                   widgets.tabs.flags2
                                   (ImGui.TabBarFlags_FittingPolicyScroll))
          (set widgets.tabs.flags2
               (bor (band widgets.tabs.flags2 (bnot fitting-policy-mask))
                    (ImGui.TabBarFlags_FittingPolicyScroll))))

        ;; Demo a Leading TabItemButton(): click the '?' button to open a menu
        (when (ImGui.BeginTabBar ctx :MyTabBar widgets.tabs.flags2)
          (when widgets.tabs.show_leading_button
            (when (ImGui.TabItemButton ctx "?"
                                       (bor (ImGui.TabItemFlags_Leading)
                                            (ImGui.TabItemFlags_NoTooltip)))
              (ImGui.OpenPopup ctx :MyHelpMenu)))
          (when (ImGui.BeginPopup ctx :MyHelpMenu)
            (ImGui.Selectable ctx :Hello!)
            (ImGui.EndPopup ctx))

          ;; Demo Trailing Tabs: click the "+" button to add a new tab (in your app you may want to use a font icon instead of the "+")
          ;; Note that we submit it before the regular tabs, but because of the ImGuiTabItemFlags_Trailing flag it will always appear at the end.
          (when widgets.tabs.show_trailing_button
            (when (ImGui.TabItemButton ctx "+"
                                       (bor (ImGui.TabItemFlags_Trailing)
                                            (ImGui.TabItemFlags_NoTooltip)))
              ;; add new tab
              (table.insert widgets.tabs.active widgets.tabs.next_id)
              (set widgets.tabs.next_id (+ 1 widgets.tabs.next_id))))

          ;; Submit our regular tabs
          (var n 1)
          (while (<= n (length widgets.tabs.active))
            (let [name (: "%04d" :format (- (. widgets.tabs.active n) 1))
                  (rv open) (ImGui.BeginTabItem ctx name true (ImGui.TabItemFlags_None))]
              (when rv
                (ImGui.Text ctx (: "This is the %s tab!" :format name))
                (ImGui.EndTabItem ctx))
              (if open
                (set n (+ n 1))
                (table.remove widgets.tabs.active n))))
          (ImGui.EndTabBar ctx))
        (ImGui.Separator ctx)
        (ImGui.TreePop ctx))
      (ImGui.TreePop ctx)))

  (when (ImGui.TreeNode ctx :Plotting)
    (local PLOT1-SIZE 90)
    (local plot2-funcs
           [#(math.sin (* $ 0.1)) ;;sin
            #(if (= (band $ 1) 1) 1.0 -1.0)]) ;;saw
    (set-when-not widgets.plots {:animate true
                                 :frame_times (reaper.new_array [0.6 0.1 1 0.5 0.92 0.1 0.2])
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

    (update-2nd widgets.plots.animate (ImGui.Checkbox ctx :Animate $))

    ;; Plot as lines and plot as histogram
    (ImGui.PlotLines ctx "Frame Times" widgets.plots.frame_times)
    (ImGui.PlotHistogram ctx :Histogram widgets.plots.frame_times 0 nil 0 1 0 80)

    ;; Fill an array of contiguous float values to plot
    (when (or (not widgets.plots.animate)
              (= 0 widgets.plots.plot1.refresh_time))
      (set widgets.plots.plot1.refresh_time (ImGui.GetTime ctx)))
    (while (< widgets.plots.plot1.refresh_time (ImGui.GetTime ctx)) ;; Create data at fixed 60 Hz rate for the demo
      (tset widgets.plots.plot1.data widgets.plots.plot1.offset
            (math.cos widgets.plots.plot1.phase))
      (set widgets.plots.plot1.offset
           (+ 1 (% widgets.plots.plot1.offset PLOT1-SIZE)))
      (set widgets.plots.plot1.phase
           (+ widgets.plots.plot1.phase (* 0.10 widgets.plots.plot1.offset)))
      (set widgets.plots.plot1.refresh_time
           (+ widgets.plots.plot1.refresh_time (/ 1.0 60.0))))

    ;; Plots can display overlay texts
    ;; (in this example, we will display an average value)
    (do
      (var average 0.0)
      (for [n 1 PLOT1-SIZE]
        (set average (+ average (. widgets.plots.plot1.data n))))
      (set average (/ average PLOT1-SIZE))

      (local overlay (: "avg %f" :format average))
      (ImGui.PlotLines ctx :Lines widgets.plots.plot1.data
                       (- widgets.plots.plot1.offset 1) overlay -1.0 1.0 0 80.0))

    (ImGui.SeparatorText ctx :Functions)
    (ImGui.SetNextItemWidth ctx (* (ImGui.GetFontSize ctx) 8))
    (let [func-changed (update-2nd widgets.plots.plot2.func (ImGui.Combo ctx :func $ "Sin\000Saw\000"))
          _ (ImGui.SameLine ctx)
          rv (update-2nd widgets.plots.plot2.size (ImGui.SliderInt ctx "Sample count" $ 1 400))]
      ;; Use functions to generate output
      (when (or func-changed rv widgets.plots.plot2.fill)
        (set widgets.plots.plot2.fill false)
        (set widgets.plots.plot2.data (reaper.new_array widgets.plots.plot2.size))
        (for [n 1 widgets.plots.plot2.size]
          (tset widgets.plots.plot2.data n
                ((. plot2-funcs (+ 1 widgets.plots.plot2.func)) (- n 1))))))

    (ImGui.PlotLines ctx :Lines widgets.plots.plot2.data 0 nil -1.0 1.0 0 80)
    (ImGui.PlotHistogram ctx :Histogram widgets.plots.plot2.data 0 nil -1.0 1.0 0 80)
    (ImGui.Separator ctx)

    ;; Animate a simple progress bar
    (when widgets.plots.animate
      (set widgets.plots.progress
           (+ widgets.plots.progress
              (* widgets.plots.progress_dir 0.4 (ImGui.GetDeltaTime ctx))))
      (if (>= widgets.plots.progress 1.1)
        (do
          (set widgets.plots.progress 1.1)
          (set widgets.plots.progress_dir
               (* -1 widgets.plots.progress_dir)))
        (<= widgets.plots.progress -0.1)
        (do
          (set widgets.plots.progress -0.1)
          (set widgets.plots.progress_dir
               (* -1 widgets.plots.progress_dir)))))

    ;; Typically we would use (-1.0,0.0) or (-FLT_MIN,0.0) to use all available width,
    ;; or (width,0.0) for a specified width. (0.0,0.0) uses ItemWidth.
    (ImGui.ProgressBar ctx widgets.plots.progress 0 0)
    (ImGui.SameLine ctx 0 (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemInnerSpacing)))
    (ImGui.Text ctx "Progress Bar")
    (let [progress-saturated (demo.clamp widgets.plots.progress 0 1)
          buf (: "%d/%d" :format (math.floor (* progress-saturated 1753)) 1753)] 
      (ImGui.ProgressBar ctx widgets.plots.progress 0 0 buf))
    (ImGui.TreePop ctx))

  (when (ImGui.TreeNode ctx "Color/Picker Widgets")
    (set-when-not widgets.colors {:alpha true
                                  :alpha_bar true
                                  :alpha_half_preview false
                                  :alpha_preview true
                                  :backup_color nil
                                  :display_mode 0
                                  :drag_and_drop true
                                  :hsva 0x3bffffff
                                  :no_border false
                                  :options_menu true
                                  :picker_mode 0
                                  :raw_hsv (reaper.new_array 4)
                                  :ref_color false
                                  :ref_color_rgba 0xff00ff80
                                  :rgba 0x72909ac8
                                  :saved_palette nil ;; filled later
                                  :side_preview true})

    ;; static bool hdr = false;
    (ImGui.SeparatorText ctx :Options)
    (update-2nd widgets.colors.alpha_preview (ImGui.Checkbox ctx "With Alpha Preview" $))
    (update-2nd widgets.colors.alpha_half_preview (ImGui.Checkbox ctx "With Half Alpha Preview" $))
    (update-2nd widgets.colors.drag_and_drop (ImGui.Checkbox ctx "With Drag and Drop" $))
    (update-2nd widgets.colors.options_menu (ImGui.Checkbox ctx "With Options Menu" $))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Right-click on the individual color widget to show options.")
    ;; ImGui.Checkbox("With HDR", &hdr); ImGui.SameLine(); HelpMarker("Currently all this does is to lift the 0..1 limits on dragging widgets.")
    (local misc-flags
      (bor ;;(widgets.colors.hdr and ImGui.ColorEditFlags_HDR() or 0) |
           (if widgets.colors.drag_and_drop 0 (ImGui.ColorEditFlags_NoDragDrop))
           (if
             widgets.colors.alpha_half_preview (ImGui.ColorEditFlags_AlphaPreviewHalf)
             widgets.colors.alpha_preview (ImGui.ColorEditFlags_AlphaPreview)
             0)
           (if widgets.colors.options_menu 0 (ImGui.ColorEditFlags_NoOptions))))

    (ImGui.SeparatorText ctx "Inline color editor")
    (ImGui.Text ctx "Color widget:")
    (ImGui.SameLine ctx)
    (demo.HelpMarker
      "Click on the color square to open a color picker.\n\z
       CTRL+click on individual component to input value.\n"))
    (var argb (demo.RgbaToArgb widgets.colors.rgba))
    (when (update-2nd argb (ImGui.ColorEdit3 ctx "MyColor##1" $ misc-flags))
      (set widgets.colors.rgba (demo.ArgbToRgba argb)))

    (ImGui.Text ctx "Color widget HSV with Alpha:")
    (update-2nd widgets.colors.rgba
                (ImGui.ColorEdit4 ctx "MyColor##2" $ (bor (ImGui.ColorEditFlags_DisplayHSV)
                                                          misc-flags)))

    (ImGui.Text ctx "Color widget with Float Display:")
    (update-2nd widgets.colors.rgba
                (ImGui.ColorEdit4 ctx "MyColor##2f" $ (bor (ImGui.ColorEditFlags_Float)
                                                           misc-flags)))

    (ImGui.Text ctx "Color button with Picker:")
    (ImGui.SameLine ctx)
    (demo.HelpMarker "With the ImGuiColorEditFlags_NoInputs flag you can hide all the slider/text inputs.
With the ImGuiColorEditFlags_NoLabel flag you can pass a non-empty label which will only be used for the tooltip and picker popup.")
    (update-2nd widgets.colors.rgba
                (ImGui.ColorEdit4 ctx "MyColor##3" $
                                  (bor (ImGui.ColorEditFlags_NoInputs)
                                       (ImGui.ColorEditFlags_NoLabel)
                                       misc-flags)))
    (ImGui.Text ctx "Color button with Custom Picker Popup:")

    ;; Generate a default palette. The palette will persist and can be edited.
    (when (not widgets.colors.saved_palette)
      (set widgets.colors.saved_palette {})
      (for [n 0 31]
        (table.insert widgets.colors.saved_palette (demo.HSV (/ n 31.0) 0.8 0.8))))
    (var open-popup (ImGui.ColorButton ctx "MyColor##3b" widgets.colors.rgba misc-flags))
    (ImGui.SameLine ctx 0 (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemInnerSpacing)))
    (set open-popup (or (ImGui.Button ctx :Palette) open-popup))
    (when open-popup (ImGui.OpenPopup ctx :mypicker)
      (set widgets.colors.backup_color widgets.colors.rgba))
    (when (ImGui.BeginPopup ctx :mypicker)
      (ImGui.Text ctx "MY CUSTOM COLOR PICKER WITH AN AMAZING PALETTE!")
      (ImGui.Separator ctx)
      (set (rv widgets.colors.rgba)
           (ImGui.ColorPicker4 ctx "##picker" widgets.colors.rgba
                                (bor misc-flags
                                     (ImGui.ColorEditFlags_NoSidePreview)
                                     (ImGui.ColorEditFlags_NoSmallPreview))))
      (ImGui.SameLine ctx)

      (ImGui.BeginGroup ctx) ;; Lock X position
      (ImGui.Text ctx :Current)
      (ImGui.ColorButton ctx "##current" widgets.colors.rgba
                         (bor (ImGui.ColorEditFlags_NoPicker)
                              (ImGui.ColorEditFlags_AlphaPreviewHalf))
                         60 40)
      (ImGui.Text ctx :Previous)
      (when (ImGui.ColorButton ctx "##previous" widgets.colors.backup_color
                               (bor (ImGui.ColorEditFlags_NoPicker)
                                    (ImGui.ColorEditFlags_AlphaPreviewHalf))
                               60 40)
        (set widgets.colors.rgba widgets.colors.backup_color))
      (ImGui.Separator ctx)
      (ImGui.Text ctx :Palette)
      (local palette-button-flags (bor (ImGui.ColorEditFlags_NoAlpha)
                                       (ImGui.ColorEditFlags_NoPicker)
                                       (ImGui.ColorEditFlags_NoTooltip)))
      (each [n c (ipairs widgets.colors.saved_palette)]
        (ImGui.PushID ctx n)
        (when (not= 0 (% (- n 1)
                         8))
          (ImGui.SameLine ctx 0 (select 2 (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemSpacing)))))

        (when (ImGui.ColorButton ctx "##palette" c palette-button-flags 20 20)
          (set widgets.colors.rgba
               (bor (lshift c 8) (band widgets.colors.rgba 255))))

        ;; Allow user to drop colors into each palette entry. Note that ColorButton() is already a
        ;; drag source by default, unless specifying the ImGuiColorEditFlags_NoDragDrop flag.
        (when (ImGui.BeginDragDropTarget ctx)
          (let [(rv drop-color) (ImGui.AcceptDragDropPayloadRGB ctx)
                _ (when rv (tset widgets.colors.saved_palette n drop-color))
                (rv drop-color) (ImGui.AcceptDragDropPayloadRGBA ctx)
                _ (when rv (tset widgets.colors.saved_palette n (rshift drop-color 8)))]
            (ImGui.EndDragDropTarget ctx)))

        (ImGui.PopID ctx))
      (ImGui.EndGroup ctx)
      (ImGui.EndPopup ctx))

    (ImGui.Text ctx "Color button only:")
    (update-2nd widgets.colors.no_border (ImGui.Checkbox ctx :ImGuiColorEditFlags_NoBorder $))
    (ImGui.ColorButton ctx "MyColor##3c" widgets.colors.rgba
                       (bor misc-flags
                            (if widgets.colors.no_border
                              (ImGui.ColorEditFlags_NoBorder)
                              0))
                       80 80)

    (ImGui.SeparatorText ctx "Color picker")
    (update-2nd widgets.colors.alpha (ImGui.Checkbox ctx "With Alpha" $))
    (update-2nd widgets.colors.alpha_bar (ImGui.Checkbox ctx "With Alpha Bar" $))
    (update-2nd widgets.colors.side_preview (ImGui.Checkbox ctx "With Side Preview" $))
    (when widgets.colors.side_preview
      (ImGui.SameLine ctx)
      (update-2nd widgets.colors.ref_color (ImGui.Checkbox ctx "With Ref Color" $))
      (when widgets.colors.ref_color
        (ImGui.SameLine ctx)
        (update-2nd widgets.colors.ref_color_rgba
                    (ImGui.ColorEdit4 ctx "##RefColor" $
                                      (bor (ImGui.ColorEditFlags_NoInputs)
                                           misc-flags)))))
    (update-2nd widgets.colors.display_mode
                (ImGui.Combo ctx "Display Mode" $
                             "Auto/Current\000None\000RGB Only\000HSV Only\000Hex Only\000"))
    (ImGui.SameLine ctx)
    (demo.HelpMarker
      "ColorEdit defaults to displaying RGB inputs if you don't specify a display mode, \z
       but the user can change it with a right-click on those inputs.\n\nColorPicker defaults to displaying RGB+HSV+Hex \z
       if you don't specify a display mode.\n\nYou can change the defaults using SetColorEditOptions().")
    (update-2nd widgets.colors.picker_mode
                (ImGui.Combo ctx "Picker Mode" $ "Auto/Current\000Hue bar + SV rect\000Hue wheel + SV triangle\000"))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "When not specified explicitly (Auto/Current mode), user can right-click the picker to change mode.")

    (var flags misc-flags)
    (when (not widgets.colors.alpha)
      (set flags (bor flags (ImGui.ColorEditFlags_NoAlpha))))
    (when widgets.colors.alpha_bar
      (set flags (bor flags (ImGui.ColorEditFlags_AlphaBar))))
    (when (not widgets.colors.side_preview)
      (set flags (bor flags (ImGui.ColorEditFlags_NoSidePreview))))
    (case widgets.colors.picker_mode
      1 (set flags (bor flags (ImGui.ColorEditFlags_PickerHueBar)))
      2 (set flags (bor flags (ImGui.ColorEditFlags_PickerHueWheel))))
    (case widgets.colors.display_mode
      1 (set flags (bor flags (ImGui.ColorEditFlags_NoInputs))) ;; Disable all RGB/HSV/Hex displays
      2 (set flags (bor flags (ImGui.ColorEditFlags_DisplayRGB))) ;; Override display mode
      3 (set flags (bor flags (ImGui.ColorEditFlags_DisplayHSV)))
      4 (set flags (bor flags (ImGui.ColorEditFlags_DisplayHex))))

    (var color (if widgets.colors.alpha
                 widgets.colors.rgba
                 (demo.RgbaToArgb widgets.colors.rgba)))
    (local ref-color
           (or (and widgets.colors.alpha widgets.colors.ref_color_rgba)
               (demo.RgbaToArgb widgets.colors.ref_color_rgba)))
    (when (update-2nd color (ImGui.ColorPicker4 ctx "MyColor##4" $ flags
                                                (when widgets.colors.ref_color
                                                  ref-color)))
      (set widgets.colors.rgba
           (if widgets.colors.alpha color (demo.ArgbToRgba color))))

    (ImGui.Text ctx "Set defaults in code:")
    (ImGui.SameLine ctx)
    (demo.HelpMarker "SetColorEditOptions() is designed to allow you to set boot-time default.
We don't have Push/Pop functions because you can force options on a per-widget basis if needed,and the user can change non-forced ones with the options menu.
We don't have a getter to avoidencouraging you to persistently save values that aren't forward-compatible.")
    (when (ImGui.Button ctx "Default: Uint8 + HSV + Hue Bar")
      (ImGui.SetColorEditOptions ctx
                                  (bor (ImGui.ColorEditFlags_Uint8)
                                       (ImGui.ColorEditFlags_DisplayHSV)
                                       (ImGui.ColorEditFlags_PickerHueBar))))
    (when (ImGui.Button ctx "Default: Float + Hue Wheel") ;; (NOTE: removed HDR for ReaImGui as we use uint32 for color i/o)
      (ImGui.SetColorEditOptions ctx
                                  (bor (ImGui.ColorEditFlags_Float)
                                       (ImGui.ColorEditFlags_PickerHueWheel))))

    ;; Always both a small version of both types of pickers (to make it more visible in the demo to people who are skimming quickly through it)
    (var color (demo.RgbaToArgb widgets.colors.rgba))
    (ImGui.Text ctx "Both types:")
    (local w (* (- (ImGui.GetContentRegionAvail ctx)
                   (select 2 (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemSpacing))))
                0.40))
    (ImGui.SetNextItemWidth ctx w)
    (when (update-2nd color
                      (ImGui.ColorPicker3 ctx "##MyColor##5" $
                                          (bor (ImGui.ColorEditFlags_PickerHueBar)
                                               (ImGui.ColorEditFlags_NoSidePreview)
                                               (ImGui.ColorEditFlags_NoInputs)
                                               (ImGui.ColorEditFlags_NoAlpha))))
      (set widgets.colors.rgba (demo.ArgbToRgba color)))
    (ImGui.SameLine ctx)
    (ImGui.SetNextItemWidth ctx w)
    (when (update-2nd color
                      (ImGui.ColorPicker3 ctx "##MyColor##6" $
                                          (bor (ImGui.ColorEditFlags_PickerHueWheel)
                                               (ImGui.ColorEditFlags_NoSidePreview)
                                               (ImGui.ColorEditFlags_NoInputs)
                                               (ImGui.ColorEditFlags_NoAlpha))))
      (set widgets.colors.rgba (demo.ArgbToRgba color)))

    ;; HSV encoded support (to avoid RGB<>HSV round trips and singularities when S==0 or V==0)
    (ImGui.Spacing ctx)
    (ImGui.Text ctx "HSV encoded colors")
    (ImGui.SameLine ctx)
    (demo.HelpMarker "By default, colors are given to ColorEdit and ColorPicker in RGB, but ImGuiColorEditFlags_InputHSV allows you to store colors as HSV and pass them to ColorEdit and ColorPicker as HSV. This comes with the added benefit that you can manipulate hue values with the picker even when saturation or value are zero.")
    (ImGui.Text ctx "Color widget with InputHSV:")
    (update-2nd widgets.colors.hsva (ImGui.ColorEdit4 ctx "HSV shown as RGB##1" $
                                                      (bor (ImGui.ColorEditFlags_DisplayRGB)
                                                           (ImGui.ColorEditFlags_InputHSV)
                                                           (ImGui.ColorEditFlags_Float))))
    (update-2nd widgets.colors.hsva (ImGui.ColorEdit4 ctx "HSV shown as HSV##1" $
                                                      (bor (ImGui.ColorEditFlags_DisplayHSV)
                                                           (ImGui.ColorEditFlags_InputHSV)
                                                           (ImGui.ColorEditFlags_Float))))
    (local raw-hsv widgets.colors.raw_hsv)
    (tset raw-hsv 1 (/ (band (rshift widgets.colors.hsva 24) 0xFF) 255.0)) ;; H
    (tset raw-hsv 2 (/ (band (rshift widgets.colors.hsva 16) 0xFF) 255.0)) ;; S
    (tset raw-hsv 3 (/ (band (rshift widgets.colors.hsva 8)  0xFF) 255.0)) ;; V
    (tset raw-hsv 4 (/ (band         widgets.colors.hsva     0xFF) 255.0)) ;; A
    (when (ImGui.DragDoubleN ctx "Raw HSV values" raw-hsv 0.01 0.0 1.0)
      (set widgets.colors.hsva
           (bor (-> (demo.round (* (. raw-hsv 1) 0xFF)) (lshift 24))
                (-> (demo.round (* (. raw-hsv 2) 0xFF)) (lshift 16))
                (-> (demo.round (* (. raw-hsv 3) 0xFF)) (lshift 8))
                (-> (demo.round (* (. raw-hsv 4) 0xFF))))))

    (ImGui.TreePop ctx))

  (when (ImGui.TreeNode ctx "Drag/Slider Flags")
    (when (not widgets.sliders)
      (set widgets.sliders {:drag_d 0.5
                            :drag_i 50
                            :flags (ImGui.SliderFlags_None)
                            :slider_d 0.5
                            :slider_i 50}))

    ;; Demonstrate using advanced flags for DragXXX and SliderXXX functions. Note that the flags are the same!
    (update-2nd widgets.sliders.flags
                (ImGui.CheckboxFlags ctx :ImGuiSliderFlags_AlwaysClamp $ (ImGui.SliderFlags_AlwaysClamp)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Always clamp value to min/max bounds (if any) when input manually with CTRL+Click.")
    (update-2nd widgets.sliders.flags
                (ImGui.CheckboxFlags ctx :ImGuiSliderFlags_Logarithmic $ (ImGui.SliderFlags_Logarithmic)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Enable logarithmic editing (more precision for small values).")
    (update-2nd widgets.sliders.flags
                (ImGui.CheckboxFlags ctx :ImGuiSliderFlags_NoRoundToFormat $ (ImGui.SliderFlags_NoRoundToFormat)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Disable rounding underlying value to match precision of the format string (e.g. %.3f values are rounded to those 3 digits).")
    (update-2nd widgets.sliders.flags
                (ImGui.CheckboxFlags ctx :ImGuiSliderFlags_NoInput $ (ImGui.SliderFlags_NoInput)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Disable CTRL+Click or Enter key allowing to input text directly into the widget.")


    ;; Drags
    (let [DBL_MIN 2.22507e-308
          DBL_MAX 1.79769e+308]
      (ImGui.Text ctx (: "Underlying double value: %f" :format widgets.sliders.drag_d))
      (update-2nd widgets.sliders.drag_d
                  (ImGui.DragDouble ctx "DragDouble (0 -> 1)" $ 0.005 0.0 1.0 "%.3f" widgets.sliders.flags))
      (update-2nd widgets.sliders.drag_d
                  (ImGui.DragDouble ctx "DragDouble (0 -> +inf)" $ 0.005 0.0 DBL_MAX "%.3f" widgets.sliders.flags))
      (update-2nd widgets.sliders.drag_d
                  (ImGui.DragDouble ctx "DragDouble (-inf -> 1)" $ 0.005 (- DBL_MAX) 1 "%.3f" widgets.sliders.flags))
      (update-2nd widgets.sliders.drag_d
                  (ImGui.DragDouble ctx "DragDouble (-inf -> +inf)" $ 0.005 (- DBL_MAX) DBL_MAX "%.3f" widgets.sliders.flags))
      (update-2nd widgets.sliders.drag_i
                  (ImGui.DragInt ctx "DragInt (0 -> 100)" $ 0.5 0 100 "%d" widgets.sliders.flags)))

    ;; Sliders
    (ImGui.Text ctx (: "Underlying float value: %f" :format widgets.sliders.slider_d))
    (update-2nd widgets.sliders.slider_d
                (ImGui.SliderDouble ctx "SliderDouble (0 -> 1)" $ 0 1 "%.3f" widgets.sliders.flags))
    (update-2nd widgets.sliders.slider_i
                (ImGui.SliderInt ctx "SliderInt (0 -> 100)" $ 0 100 "%d" widgets.sliders.flags))

    (ImGui.TreePop ctx))

  (when (ImGui.TreeNode ctx "Range Widgets")
    (set-when-not widgets.range {:begin_f 10.0
                                 :end_f 90.0
                                 :begin_i 100
                                 :end_i 1000})

    (set (_ widgets.range.begin_f widgets.range.end_f)
         (ImGui.DragFloatRange2 ctx "range float" widgets.range.begin_f
                                widgets.range.end_f 0.25 0 100 "Min: %.1f %%"
                                "Max: %.1f %%" (ImGui.SliderFlags_AlwaysClamp)))
    (set (_ widgets.range.begin_i widgets.range.end_i)
         (ImGui.DragIntRange2 ctx "range int" widgets.range.begin_i
                              widgets.range.end_i 5 0 1000 "Min: %d units"
                              "Max: %d units"))
    (set (_ widgets.range.begin_i widgets.range.end_i)
         (ImGui.DragIntRange2 ctx "range int (no bounds)"
                              widgets.range.begin_i widgets.range.end_i 5 0 0
                              "Min: %d units" "Max: %d units"))
    (ImGui.TreePop ctx))

;;     if (ImGui.TreeNode("Data Types"))
;;     {
;;         // DragScalar/InputScalar/SliderScalar functions allow various data types
;;         // - signed/unsigned
;;         // - 8/16/32/64-bits
;;         // - integer/float/double
;;         // To avoid polluting the public API with all possible combinations, we use the ImGuiDataType enum
;;         // to pass the type, and passing all arguments by pointer.
;;         // This is the reason the test code below creates local variables to hold "zero" "one" etc. for each type.
;;         // In practice, if you frequently use a given type that is not covered by the normal API entry points,
;;         // you can wrap it yourself inside a 1 line function which can take typed argument as value instead of void*,
;;         // and then pass their address to the generic function. For example:
;;         //   bool MySliderU64(const char *label, u64* value, u64 min = 0, u64 max = 0, const char* format = "%lld")
;;         //   {
;;         //      return SliderScalar(label, ImGuiDataType_U64, value, &min, &max, format);
;;         //   }
;;
;;         // Setup limits (as helper variables so we can take their address, as explained above)
;;         // Note: SliderScalar() functions have a maximum usable range of half the natural type maximum, hence the /2.
;;         #ifndef LLONG_MIN
;;         ImS64 LLONG_MIN = -9223372036854775807LL - 1;
;;         ImS64 LLONG_MAX = 9223372036854775807LL;
;;         ImU64 ULLONG_MAX = (2ULL * 9223372036854775807LL + 1);
;;         #endif
;;         const char    s8_zero  = 0,   s8_one  = 1,   s8_fifty  = 50, s8_min  = -128,        s8_max = 127;
;;         const ImU8    u8_zero  = 0,   u8_one  = 1,   u8_fifty  = 50, u8_min  = 0,           u8_max = 255;
;;         const short   s16_zero = 0,   s16_one = 1,   s16_fifty = 50, s16_min = -32768,      s16_max = 32767;
;;         const ImU16   u16_zero = 0,   u16_one = 1,   u16_fifty = 50, u16_min = 0,           u16_max = 65535;
;;         const ImS32   s32_zero = 0,   s32_one = 1,   s32_fifty = 50, s32_min = INT_MIN/2,   s32_max = INT_MAX/2,    s32_hi_a = INT_MAX/2 - 100,    s32_hi_b = INT_MAX/2;
;;         const ImU32   u32_zero = 0,   u32_one = 1,   u32_fifty = 50, u32_min = 0,           u32_max = UINT_MAX/2,   u32_hi_a = UINT_MAX/2 - 100,   u32_hi_b = UINT_MAX/2;
;;         const ImS64   s64_zero = 0,   s64_one = 1,   s64_fifty = 50, s64_min = LLONG_MIN/2, s64_max = LLONG_MAX/2,  s64_hi_a = LLONG_MAX/2 - 100,  s64_hi_b = LLONG_MAX/2;
;;         const ImU64   u64_zero = 0,   u64_one = 1,   u64_fifty = 50, u64_min = 0,           u64_max = ULLONG_MAX/2, u64_hi_a = ULLONG_MAX/2 - 100, u64_hi_b = ULLONG_MAX/2;
;;         const float   f32_zero = 0.f, f32_one = 1.f, f32_lo_a = -10000000000.0f, f32_hi_a = +10000000000.0f;
;;         const double  f64_zero = 0.,  f64_one = 1.,  f64_lo_a = -1000000000000000.0, f64_hi_a = +1000000000000000.0;
;;
;;         // State
;;         static char   s8_v  = 127;
;;         static ImU8   u8_v  = 255;
;;         static short  s16_v = 32767;
;;         static ImU16  u16_v = 65535;
;;         static ImS32  s32_v = -1;
;;         static ImU32  u32_v = (ImU32)-1;
;;         static ImS64  s64_v = -1;
;;         static ImU64  u64_v = (ImU64)-1;
;;         static float  f32_v = 0.123f;
;;         static double f64_v = 90000.01234567890123456789;
;;
;;         const float drag_speed = 0.2f;
;;         static bool drag_clamp = false;
;;         ImGui.SeparatorText("Drags");
;;         ImGui.Checkbox("Clamp integers to 0..50", &drag_clamp);
;;         ImGui.SameLine(); HelpMarker(
;;             "As with every widget in dear imgui, we never modify values unless there is a user interaction.\n"
;;             "You can override the clamping limits by using CTRL+Click to input a value.");
;;         ImGui.DragScalar("drag s8",        ImGuiDataType_S8,     &s8_v,  drag_speed, drag_clamp ? &s8_zero  : NULL, drag_clamp ? &s8_fifty  : NULL);
;;         ImGui.DragScalar("drag u8",        ImGuiDataType_U8,     &u8_v,  drag_speed, drag_clamp ? &u8_zero  : NULL, drag_clamp ? &u8_fifty  : NULL, "%u ms");
;;         ImGui.DragScalar("drag s16",       ImGuiDataType_S16,    &s16_v, drag_speed, drag_clamp ? &s16_zero : NULL, drag_clamp ? &s16_fifty : NULL);
;;         ImGui.DragScalar("drag u16",       ImGuiDataType_U16,    &u16_v, drag_speed, drag_clamp ? &u16_zero : NULL, drag_clamp ? &u16_fifty : NULL, "%u ms");
;;         ImGui.DragScalar("drag s32",       ImGuiDataType_S32,    &s32_v, drag_speed, drag_clamp ? &s32_zero : NULL, drag_clamp ? &s32_fifty : NULL);
;;         ImGui.DragScalar("drag s32 hex",   ImGuiDataType_S32,    &s32_v, drag_speed, drag_clamp ? &s32_zero : NULL, drag_clamp ? &s32_fifty : NULL, "0x%08X");
;;         ImGui.DragScalar("drag u32",       ImGuiDataType_U32,    &u32_v, drag_speed, drag_clamp ? &u32_zero : NULL, drag_clamp ? &u32_fifty : NULL, "%u ms");
;;         ImGui.DragScalar("drag s64",       ImGuiDataType_S64,    &s64_v, drag_speed, drag_clamp ? &s64_zero : NULL, drag_clamp ? &s64_fifty : NULL);
;;         ImGui.DragScalar("drag u64",       ImGuiDataType_U64,    &u64_v, drag_speed, drag_clamp ? &u64_zero : NULL, drag_clamp ? &u64_fifty : NULL);
;;         ImGui.DragScalar("drag float",     ImGuiDataType_Float,  &f32_v, 0.005f,  &f32_zero, &f32_one, "%f");
;;         ImGui.DragScalar("drag float log", ImGuiDataType_Float,  &f32_v, 0.005f,  &f32_zero, &f32_one, "%f", ImGuiSliderFlags_Logarithmic);
;;         ImGui.DragScalar("drag double",    ImGuiDataType_Double, &f64_v, 0.0005f, &f64_zero, NULL,     "%.10f grams");
;;         ImGui.DragScalar("drag double log",ImGuiDataType_Double, &f64_v, 0.0005f, &f64_zero, &f64_one, "0 < %.10f < 1", ImGuiSliderFlags_Logarithmic);
;;
;;         ImGui.SeparatorText("Sliders");
;;         ImGui.SliderScalar("slider s8 full",       ImGuiDataType_S8,     &s8_v,  &s8_min,   &s8_max,   "%d");
;;         ImGui.SliderScalar("slider u8 full",       ImGuiDataType_U8,     &u8_v,  &u8_min,   &u8_max,   "%u");
;;         ImGui.SliderScalar("slider s16 full",      ImGuiDataType_S16,    &s16_v, &s16_min,  &s16_max,  "%d");
;;         ImGui.SliderScalar("slider u16 full",      ImGuiDataType_U16,    &u16_v, &u16_min,  &u16_max,  "%u");
;;         ImGui.SliderScalar("slider s32 low",       ImGuiDataType_S32,    &s32_v, &s32_zero, &s32_fifty,"%d");
;;         ImGui.SliderScalar("slider s32 high",      ImGuiDataType_S32,    &s32_v, &s32_hi_a, &s32_hi_b, "%d");
;;         ImGui.SliderScalar("slider s32 full",      ImGuiDataType_S32,    &s32_v, &s32_min,  &s32_max,  "%d");
;;         ImGui.SliderScalar("slider s32 hex",       ImGuiDataType_S32,    &s32_v, &s32_zero, &s32_fifty, "0x%04X");
;;         ImGui.SliderScalar("slider u32 low",       ImGuiDataType_U32,    &u32_v, &u32_zero, &u32_fifty,"%u");
;;         ImGui.SliderScalar("slider u32 high",      ImGuiDataType_U32,    &u32_v, &u32_hi_a, &u32_hi_b, "%u");
;;         ImGui.SliderScalar("slider u32 full",      ImGuiDataType_U32,    &u32_v, &u32_min,  &u32_max,  "%u");
;;         ImGui.SliderScalar("slider s64 low",       ImGuiDataType_S64,    &s64_v, &s64_zero, &s64_fifty,"%I64d");
;;         ImGui.SliderScalar("slider s64 high",      ImGuiDataType_S64,    &s64_v, &s64_hi_a, &s64_hi_b, "%I64d");
;;         ImGui.SliderScalar("slider s64 full",      ImGuiDataType_S64,    &s64_v, &s64_min,  &s64_max,  "%I64d");
;;         ImGui.SliderScalar("slider u64 low",       ImGuiDataType_U64,    &u64_v, &u64_zero, &u64_fifty,"%I64u ms");
;;         ImGui.SliderScalar("slider u64 high",      ImGuiDataType_U64,    &u64_v, &u64_hi_a, &u64_hi_b, "%I64u ms");
;;         ImGui.SliderScalar("slider u64 full",      ImGuiDataType_U64,    &u64_v, &u64_min,  &u64_max,  "%I64u ms");
;;         ImGui.SliderScalar("slider float low",     ImGuiDataType_Float,  &f32_v, &f32_zero, &f32_one);
;;         ImGui.SliderScalar("slider float low log", ImGuiDataType_Float,  &f32_v, &f32_zero, &f32_one,  "%.10f", ImGuiSliderFlags_Logarithmic);
;;         ImGui.SliderScalar("slider float high",    ImGuiDataType_Float,  &f32_v, &f32_lo_a, &f32_hi_a, "%e");
;;         ImGui.SliderScalar("slider double low",    ImGuiDataType_Double, &f64_v, &f64_zero, &f64_one,  "%.10f grams");
;;         ImGui.SliderScalar("slider double low log",ImGuiDataType_Double, &f64_v, &f64_zero, &f64_one,  "%.10f", ImGuiSliderFlags_Logarithmic);
;;         ImGui.SliderScalar("slider double high",   ImGuiDataType_Double, &f64_v, &f64_lo_a, &f64_hi_a, "%e grams");
;;
;;         ImGui.SeparatorText("Sliders (reverse)");
;;         ImGui.SliderScalar("slider s8 reverse",    ImGuiDataType_S8,   &s8_v,  &s8_max,    &s8_min, "%d");
;;         ImGui.SliderScalar("slider u8 reverse",    ImGuiDataType_U8,   &u8_v,  &u8_max,    &u8_min, "%u");
;;         ImGui.SliderScalar("slider s32 reverse",   ImGuiDataType_S32,  &s32_v, &s32_fifty, &s32_zero, "%d");
;;         ImGui.SliderScalar("slider u32 reverse",   ImGuiDataType_U32,  &u32_v, &u32_fifty, &u32_zero, "%u");
;;         ImGui.SliderScalar("slider s64 reverse",   ImGuiDataType_S64,  &s64_v, &s64_fifty, &s64_zero, "%I64d");
;;         ImGui.SliderScalar("slider u64 reverse",   ImGuiDataType_U64,  &u64_v, &u64_fifty, &u64_zero, "%I64u ms");
;;
;;         static bool inputs_step = true;
;;         ImGui.SeparatorText("Inputs");
;;         ImGui.Checkbox("Show step buttons", &inputs_step);
;;         ImGui.InputScalar("input s8",      ImGuiDataType_S8,     &s8_v,  inputs_step ? &s8_one  : NULL, NULL, "%d");
;;         ImGui.InputScalar("input u8",      ImGuiDataType_U8,     &u8_v,  inputs_step ? &u8_one  : NULL, NULL, "%u");
;;         ImGui.InputScalar("input s16",     ImGuiDataType_S16,    &s16_v, inputs_step ? &s16_one : NULL, NULL, "%d");
;;         ImGui.InputScalar("input u16",     ImGuiDataType_U16,    &u16_v, inputs_step ? &u16_one : NULL, NULL, "%u");
;;         ImGui.InputScalar("input s32",     ImGuiDataType_S32,    &s32_v, inputs_step ? &s32_one : NULL, NULL, "%d");
;;         ImGui.InputScalar("input s32 hex", ImGuiDataType_S32,    &s32_v, inputs_step ? &s32_one : NULL, NULL, "%04X");
;;         ImGui.InputScalar("input u32",     ImGuiDataType_U32,    &u32_v, inputs_step ? &u32_one : NULL, NULL, "%u");
;;         ImGui.InputScalar("input u32 hex", ImGuiDataType_U32,    &u32_v, inputs_step ? &u32_one : NULL, NULL, "%08X");
;;         ImGui.InputScalar("input s64",     ImGuiDataType_S64,    &s64_v, inputs_step ? &s64_one : NULL);
;;         ImGui.InputScalar("input u64",     ImGuiDataType_U64,    &u64_v, inputs_step ? &u64_one : NULL);
;;         ImGui.InputScalar("input float",   ImGuiDataType_Float,  &f32_v, inputs_step ? &f32_one : NULL);
;;         ImGui.InputScalar("input double",  ImGuiDataType_Double, &f64_v, inputs_step ? &f64_one : NULL);
;;
;;         ImGui.TreePop();
;;     }

  (when (ImGui.TreeNode ctx "Multi-component Widgets")
    (set-when-not widgets.multi_component
                  {:vec4a (reaper.new_array [0.1 0.2 0.3 0.44])
                   :vec4d [0.1 0.2 0.3 0.44]
                   :vec4i [1 5 100 255]})
    (local vec4d widgets.multi_component.vec4d)
    (local vec4i widgets.multi_component.vec4i)
    (ImGui.SeparatorText ctx :2-wide)
    (var vec4d1 nil)
    (var vec4d2 nil)
    (var vec4d3 nil)
    (var vec4d4 nil)
    (var vec4i1 nil)
    (var vec4i2 nil)
    (var vec4i3 nil)
    (var vec4i4 nil)
    (set-forcibly! (_ vec4d1 vec4d2)
                   (ImGui.InputDouble2 ctx "input double2" (. vec4d 1)
                                        (. vec4d 2)))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (set-forcibly! (_ vec4d1 vec4d2)
                   (ImGui.DragDouble2 ctx "drag double2" (. vec4d 1)
                                       (. vec4d 2) 0.01 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (set-forcibly! (_ vec4d1 vec4d2)
                   (ImGui.SliderDouble2 ctx "slider double2" (. vec4d 1)
                                         (. vec4d 2) 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (set-forcibly! (_ vec4i1 vec4i2)
                   (ImGui.InputInt2 ctx "input int2" (. vec4i 1) (. vec4i 2)))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (set-forcibly! (_ vec4i1 vec4i2)
                   (ImGui.DragInt2 ctx "drag int2" (. vec4i 1) (. vec4i 2) 1 0
                                    255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (set-forcibly! (_ vec4i1 vec4i2)
                   (ImGui.SliderInt2 ctx "slider int2" (. vec4i 1) (. vec4i 2)
                                      0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)

    (ImGui.SeparatorText ctx :3-wide)
    (set-forcibly! (_ vec4d1 vec4d2 vec4d3)
                   (ImGui.InputDouble3 ctx "input double3" (. vec4d 1)
                                        (. vec4d 2) (. vec4d 3)))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (set-forcibly! (_ vec4d1 vec4d2 vec4d3)
                   (ImGui.DragDouble3 ctx "drag double3" (. vec4d 1)
                                       (. vec4d 2) (. vec4d 3) 0.01 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (set-forcibly! (_ vec4d1 vec4d2 vec4d3)
                   (ImGui.SliderDouble3 ctx "slider double3" (. vec4d 1)
                                         (. vec4d 2) (. vec4d 3) 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (set-forcibly! (_ vec4i1 vec4i2 vec4i3)
                   (ImGui.InputInt3 ctx "input int3" (. vec4i 1) (. vec4i 2)
                                     (. vec4i 3)))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (set-forcibly! (_ vec4i1 vec4i2 vec4i3)
                   (ImGui.DragInt3 ctx "drag int3" (. vec4i 1) (. vec4i 2)
                                    (. vec4i 3) 1 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (set-forcibly! (_ vec4i1 vec4i2 vec4i3)
                   (ImGui.SliderInt3 ctx "slider int3" (. vec4i 1) (. vec4i 2)
                                      (. vec4i 3) 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)

    (ImGui.SeparatorText ctx :4-wide)
    (set-forcibly! (_ vec4d1 vec4d2 vec4d3 vec4d4)
                   (ImGui.InputDouble4 ctx "input double4" (. vec4d 1)
                                        (. vec4d 2) (. vec4d 3) (. vec4d 4)))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (tset vec4d 4 vec4d4)
    (set-forcibly! (_ vec4d1 vec4d2 vec4d3 vec4d4)
                   (ImGui.DragDouble4 ctx "drag double4" (. vec4d 1)
                                       (. vec4d 2) (. vec4d 3) (. vec4d 4) 0.01
                                       0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (tset vec4d 4 vec4d4)
    (set-forcibly! (_ vec4d1 vec4d2 vec4d3 vec4d4)
                   (ImGui.SliderDouble4 ctx "slider double4" (. vec4d 1)
                                         (. vec4d 2) (. vec4d 3) (. vec4d 4) 0 1))
    (tset vec4d 1 vec4d1)
    (tset vec4d 2 vec4d2)
    (tset vec4d 3 vec4d3)
    (tset vec4d 4 vec4d4)
    (set-forcibly! (_ vec4i1 vec4i2 vec4i3 vec4i4)
                   (ImGui.InputInt4 ctx "input int4" (. vec4i 1) (. vec4i 2)
                                     (. vec4i 3) (. vec4i 4)))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (tset vec4i 4 vec4i4)
    (set-forcibly! (_ vec4i1 vec4i2 vec4i3 vec4i4)
                   (ImGui.DragInt4 ctx "drag int4" (. vec4i 1) (. vec4i 2)
                                    (. vec4i 3) (. vec4i 4) 1 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (tset vec4i 4 vec4i4)
    (set-forcibly! (_ vec4i1 vec4i2 vec4i3 vec4i4)
                   (ImGui.SliderInt4 ctx "slider int4" (. vec4i 1) (. vec4i 2)
                                      (. vec4i 3) (. vec4i 4) 0 255))
    (tset vec4i 1 vec4i1)
    (tset vec4i 2 vec4i2)
    (tset vec4i 3 vec4i3)
    (tset vec4i 4 vec4i4)
    (ImGui.Spacing ctx)

    (ImGui.InputDoubleN ctx "input reaper.array" widgets.multi_component.vec4a)
    (ImGui.DragDoubleN ctx "drag reaper.array" widgets.multi_component.vec4a 0.01 0.0 1.0)
    (ImGui.SliderDoubleN ctx "slider reaper.array" widgets.multi_component.vec4a 0.0 1.0)

    (ImGui.TreePop ctx))

  (when (ImGui.TreeNode ctx "Vertical Sliders")
    (set-when-not widgets.vsliders
                  {:int_value 0
                   :values  [0.0  0.6  0.35 0.9 0.70 0.20 0.0]
                   :values2 [0.20 0.80 0.40 0.25]})
    (let [spacing 4]
      (ImGui.PushStyleVar ctx (ImGui.StyleVar_ItemSpacing) spacing spacing)

      (update-2nd widgets.vsliders.int_value (ImGui.VSliderInt ctx "##int" 18 160 $ 0 5))
      (ImGui.SameLine ctx)

      (ImGui.PushID ctx :set1)
      (each [i v (ipairs widgets.vsliders.values)]
        (when (> i 1) (ImGui.SameLine ctx))
        (ImGui.PushID ctx i)
        (ImGui.PushStyleColor ctx (ImGui.Col_FrameBg)        (demo.HSV (/ (- i 1) 7.0) 0.5 0.5 1.0))
        (ImGui.PushStyleColor ctx (ImGui.Col_FrameBgHovered) (demo.HSV (/ (- i 1) 7.0) 0.6 0.5 1.0))
        (ImGui.PushStyleColor ctx (ImGui.Col_FrameBgActive)  (demo.HSV (/ (- i 1) 7.0) 0.7 0.5 1.0))
        (ImGui.PushStyleColor ctx (ImGui.Col_SliderGrab)     (demo.HSV (/ (- i 1) 7.0) 0.9 0.9 1.0))
        (let [(_ vi) (ImGui.VSliderDouble ctx "##v" 18 160 v 0 1 " ")]
          (tset widgets.vsliders.values i vi))
        (when (or (ImGui.IsItemActive ctx)
                  (ImGui.IsItemHovered ctx))
          (ImGui.SetTooltip ctx (: "%.3f" :format v)))
        (ImGui.PopStyleColor ctx 4)
        (ImGui.PopID ctx))
      (ImGui.PopID ctx)

      (ImGui.SameLine ctx)
      (ImGui.PushID ctx :set2)
      (let [rows 3
            small-slider-w 18 
            small-slider-h (/ (- 160 (* (- rows 1) spacing)) rows)] 
        (each [nx v2 (ipairs widgets.vsliders.values2)]
          (when (> nx 1) (ImGui.SameLine ctx))
          (ImGui.BeginGroup ctx)
          (for [ny 0 (- rows 1)]
            (ImGui.PushID ctx (+ (* nx rows) ny))
            (let [(rv v2) (ImGui.VSliderDouble ctx "##v" small-slider-w small-slider-h v2 0.0 1.0 " ")]
              (when rv (tset widgets.vsliders.values2 nx v2))
              (when (or (ImGui.IsItemActive ctx)
                        (ImGui.IsItemHovered ctx))
                (ImGui.SetTooltip ctx (: "%.3f" :format v2)))
              (ImGui.PopID ctx)))
          (ImGui.EndGroup ctx))
        (ImGui.PopID ctx))

      (ImGui.SameLine ctx)
      (ImGui.PushID ctx :set3)
      (for [i 1 4] (local v (. widgets.vsliders.values i))
        (when (> i 1) (ImGui.SameLine ctx))
        (ImGui.PushID ctx i)
        (ImGui.PushStyleVar ctx (ImGui.StyleVar_GrabMinSize) 40)
        (let [(_ vi) (ImGui.VSliderDouble ctx "##v" 40 160 v 0 1 "%.2f sec")]
          (tset widgets.vsliders.values i vi))
        (ImGui.PopStyleVar ctx)
        (ImGui.PopID ctx))
      (ImGui.PopID ctx)
      (ImGui.PopStyleVar ctx)
      (ImGui.TreePop ctx)))

  (when (ImGui.TreeNode ctx "Drag and Drop")
    (set-when-not widgets.dragdrop
                  {:color1 0xFF0033
                   :color2 0x66B30080
                   :files {}
                   :items ["Item One" "Item Two" "Item Three" "Item Four" "Item Five"]
                   :mode 0
                   :names [:Bobby :Beatrice :Betty :Brianna :Barry :Bernard :Bibi :Blaine :Bryn]})

    (when (ImGui.TreeNode ctx "Drag and drop in standard widgets")
      ;; ColorEdit widgets automatically act as drag source and drag target.
      ;; They are using standardized payload types accessible using
      ;; ImGui_AcceptDragDropPayloadRGB or ImGui_AcceptDragDropPayloadRGBA
      ;; to allow your own widgets to use colors in their drag and drop interaction.
      ;; Also see 'Demo->Widgets->Color/Picker Widgets->Palette' demo.
      (demo.HelpMarker "You can drag from the color squares.")
      (update-2nd widgets.dragdrop.color1 (ImGui.ColorEdit3 ctx "color 1" $))
      (update-2nd widgets.dragdrop.color2 (ImGui.ColorEdit4 ctx "color 2" $))
      (ImGui.TreePop ctx))

    (when (ImGui.TreeNode ctx "Drag and drop to copy/swap items")
      (let [mode-copy 0
            mode-move 1
            mode-swap 2]
        (when (ImGui.RadioButton ctx :Copy (= widgets.dragdrop.mode mode-copy))
          (set widgets.dragdrop.mode mode-copy))
        (ImGui.SameLine ctx)
        (when (ImGui.RadioButton ctx :Move (= widgets.dragdrop.mode mode-move))
          (set widgets.dragdrop.mode mode-move))
        (ImGui.SameLine ctx)
        (when (ImGui.RadioButton ctx :Swap (= widgets.dragdrop.mode mode-swap))
          (set widgets.dragdrop.mode mode-swap))
        (each [n name (ipairs widgets.dragdrop.names)]
          (ImGui.PushID ctx n)
          (when (not= (% (- n 1) 3) 0)
            (ImGui.SameLine ctx))
          (ImGui.Button ctx name 60 60)

          ;; Our buttons are both drag sources and drag targets here!
          (when (ImGui.BeginDragDropSource ctx (ImGui.DragDropFlags_None))
            ;; Set payload to carry the index of our item (could be anything)
            (ImGui.SetDragDropPayload ctx :DND_DEMO_CELL (tostring n))

            ;; Display preview (could be anything, e.g. when dragging an image we could decide to display
            ;; the filename and a small preview of the image, etc.)
            (case widgets.dragdrop.mode
              mode-copy (ImGui.Text ctx (: "Copy %s" :format name))
              mode-move (ImGui.Text ctx (: "Move %s" :format name))
              mode-swap (ImGui.Text ctx (: "Swap %s" :format name)))
            (ImGui.EndDragDropSource ctx))
          (when (ImGui.BeginDragDropTarget ctx)
            (let [(rv payload) (ImGui.AcceptDragDropPayload ctx :DND_DEMO_CELL)]
              (when rv
                (let [payload (tonumber payload)]
                  (case widgets.dragdrop.mode 
                    mode-copy (tset widgets.dragdrop.names n (. widgets.dragdrop.names payload))
                    mode-move (do 
                                (tset widgets.dragdrop.names n (. widgets.dragdrop.names payload))
                                (tset widgets.dragdrop.names payload ""))
                    mode-swap (do
                                (tset widgets.dragdrop.names n (. widgets.dragdrop.names payload))
                                (tset widgets.dragdrop.names payload name)))))
              (ImGui.EndDragDropTarget ctx)))
          (ImGui.PopID ctx))
        (ImGui.TreePop ctx)))

    (when (ImGui.TreeNode ctx "Drag to reorder items (simple)")
      ;; Simple reordering
      (demo.HelpMarker "We don't use the drag and drop api at all here! Instead we query when the item is held but not hovered, and order items accordingly.")
      (each [n item (ipairs widgets.dragdrop.items)]
        (ImGui.Selectable ctx item)

        (when (and (ImGui.IsItemActive ctx)
                   (not (ImGui.IsItemHovered ctx)))
          (let [mouse-delta (select 2 (ImGui.GetMouseDragDelta ctx (ImGui.MouseButton_Left)))
                n-next (+ n (or (and (< mouse-delta 0) (- 1)) 1))]
            (when (<= 1 n-next (length widgets.dragdrop.items))
              (tset widgets.dragdrop.items n (. widgets.dragdrop.items n-next))
              (tset widgets.dragdrop.items n-next item)
              (ImGui.ResetMouseDragDelta ctx (ImGui.MouseButton_Left))))))
      (ImGui.TreePop ctx))

    (when (ImGui.TreeNode ctx "Drag and drop files")
      (when (ImGui.BeginChildFrame ctx "##drop_files" (- FLT_MIN) 100)
        (if (= (length widgets.dragdrop.files) 0)
          (ImGui.Text ctx "Drag and drop files here...")
          (do
            (ImGui.Text ctx (: "Received %d file(s):" :format (length widgets.dragdrop.files)))
            (ImGui.SameLine ctx)
            (when (ImGui.SmallButton ctx :Clear)
              (set widgets.dragdrop.files {}))))
        (each [_ file (ipairs widgets.dragdrop.files)] (ImGui.Bullet ctx)
          (ImGui.TextWrapped ctx file))
        (ImGui.EndChildFrame ctx))

      (when (ImGui.BeginDragDropTarget ctx)
        (let [(rv count) (ImGui.AcceptDragDropPayloadFiles ctx)]
          (when rv
            (set widgets.dragdrop.files {})
            (for [i 0 (- count 1)]
              (let [(_ filename) (ImGui.GetDragDropPayloadFile ctx i)]
                (table.insert widgets.dragdrop.files filename))))
        (ImGui.EndDragDropTarget ctx)))

      (ImGui.TreePop ctx))

    (ImGui.TreePop ctx))

  (when (ImGui.TreeNode ctx "Querying Item Status (Edited/Active/Hovered etc.)")
    (set-when-not widgets.query_item
                  {:b false
                   :color 0xFF8000FF
                   :current 1
                   :d4a [1.0 0.5 0.0 1.0]
                   :item_type 1
                   :str ""})

    ;; Select an item type
    (set (rv widgets.query_item.item_type)
         (ImGui.Combo ctx "Item Type" widgets.query_item.item_type
                      "Text\0Button\0Button (w/ repeat)\0Checkbox\0SliderDouble\0\z
                      InputText\0InputTextMultiline\0InputDouble\0InputDouble3\0ColorEdit4\0\z
                      Selectable\0MenuItem\0TreeNode\0TreeNode (w/ double-click)\0Combo\0ListBox\0"))

    (ImGui.SameLine ctx)
    (demo.HelpMarker 
      "Testing how various types of items are interacting with the IsItemXXX \z
       functions. Note that the bool return value of most ImGui function is \z
       generally equivalent to calling ImGui.IsItemHovered().")

    (when widgets.query_item.item_disabled
      (ImGui.BeginDisabled ctx true))

    ;; Submit selected items so we can query their status in the code following it.
    (let [rv
          (case widgets.query_item.item_type
            ;; Testing text items with no identifier/interaction
            0 (ImGui.Text ctx "ITEM: Text")
            ;; Testing button
            1 (ImGui.Button ctx "ITEM: Button")
            ;; Testing button (with repeater)
            2 (let [_ (ImGui.PushButtonRepeat ctx true)
                    rv (ImGui.Button ctx "ITEM: Button")
                    _ (ImGui.PopButtonRepeat ctx)]
                rv)
            ;; Testing checkbox
            3 (update-2nd widgets.query_item.b (ImGui.Checkbox ctx "ITEM: Checkbox" $))
            ;; Testing basic item
            4 (let [(rv da41) (ImGui.SliderDouble ctx "ITEM: SliderDouble" (. widgets.query_item.d4a 1) 0 1)]
                (tset widgets.query_item.d4a 1 da41)
                rv)
            ;; Testing input text (which handles tabbing)
            5 (update-2nd widgets.query_item.str (ImGui.InputText ctx "ITEM: InputText" $))
            ;; Testing input text (which uses a child window)
            6 (update-2nd widgets.query_item.str (ImGui.InputTextMultiline ctx "ITEM: InputTextMultiline" $))
            ;; Testing +/- buttons on scalar input
            7 (let [(rv d4a1) (ImGui.InputDouble ctx "ITEM: InputDouble" (. widgets.query_item.d4a 1) 1)]
                (tset widgets.query_item.d4a 1 d4a1)
                rv)
            ;; Testing multi-component items (IsItemXXX flags are reported merged)
            8 (let [d4a widgets.query_item.d4a
                    (rv d4a1 d4a2 d4a3) (ImGui.InputDouble3 ctx "ITEM: InputDouble3" (. d4a 1) (. d4a 2) (. d4a 3))]
                (tset d4a 1 d4a1)
                (tset d4a 2 d4a2)
                (tset d4a 3 d4a3)
                rv)
            ;; Testing multi-component items (IsItemXXX flags are reported merged)
            9 (update-2nd widgets.query_item.color (ImGui.ColorEdit4 ctx "ITEM: ColorEdit" $))
            ;; Testing selectable item
            10 (ImGui.Selectable ctx "ITEM: Selectable")
            ;; Testing menu item (they use ImGuiButtonFlags_PressedOnRelease button policy)
            11 (ImGui.MenuItem ctx "ITEM: MenuItem")
            ;; Testing tree node
            12 (let [rv (ImGui.TreeNode ctx "ITEM: TreeNode")]
                 (when rv
                   (ImGui.TreePop ctx))
                 rv)
            ;; Testing tree node with ImGuiButtonFlags_PressedOnDoubleClick button policy.
            13 (ImGui.TreeNode ctx "ITEM: TreeNode w/ ImGuiTreeNodeFlags_OpenOnDoubleClick"
                               (bor (ImGui.TreeNodeFlags_OpenOnDoubleClick)
                                    (ImGui.TreeNodeFlags_NoTreePushOnOpen)))
            14 (update-2nd widgets.query_item.current (ImGui.Combo ctx "ITEM: Combo" $ "Apple\000Banana\000Cherry\000Kiwi\000"))
            15 (update-2nd widgets.query_item.current (ImGui.ListBox ctx "ITEM: ListBox" $ "Apple\000Banana\000Cherry\000Kiwi\000")))

          hovered-delay-none (ImGui.IsItemHovered ctx)
          hovered-delay-short (ImGui.IsItemHovered ctx (ImGui.HoveredFlags_DelayShort))
          hovered-delay-normal (ImGui.IsItemHovered ctx (ImGui.HoveredFlags_DelayNormal))]
      ;; Display the values of IsItemHovered() and other common item state functions.
      ;; Note that the ImGuiHoveredFlags_XXX flags can be combined.
      ;; Because BulletText is an item itself and that would affect the output of IsItemXXX functions,
      ;; we query every state in a single call to avoid storing them and to simplify the code.
      (ImGui.BulletText ctx (: "Return value = %s
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
GetItemRectSize() = (%.1f, %.1f)" :format
                             rv
                          (ImGui.IsItemFocused ctx) (ImGui.IsItemHovered ctx)
                          (ImGui.IsItemHovered ctx
                                                (ImGui.HoveredFlags_AllowWhenBlockedByPopup))
                          (ImGui.IsItemHovered ctx
                                                (ImGui.HoveredFlags_AllowWhenBlockedByActiveItem))
                          (ImGui.IsItemHovered ctx
                                                (ImGui.HoveredFlags_AllowWhenOverlapped))
                          (ImGui.IsItemHovered ctx
                                                (ImGui.HoveredFlags_AllowWhenDisabled))
                          (ImGui.IsItemHovered ctx
                                                (ImGui.HoveredFlags_RectOnly))
                          (ImGui.IsItemActive ctx) (ImGui.IsItemEdited ctx)
                          (ImGui.IsItemActivated ctx)
                          (ImGui.IsItemDeactivated ctx)
                          (ImGui.IsItemDeactivatedAfterEdit ctx)
                          (ImGui.IsItemVisible ctx) (ImGui.IsItemClicked ctx)
                          (ImGui.IsItemToggledOpen ctx)
                          (ImGui.GetItemRectMin ctx)
                          (select 2 (ImGui.GetItemRectMin ctx))
                          (ImGui.GetItemRectMax ctx)
                          (select 2 (ImGui.GetItemRectMax ctx))
                          (ImGui.GetItemRectSize ctx)
                          (select 2 (ImGui.GetItemRectSize ctx))))
    (ImGui.BulletText ctx (: "w/ Hovering Delay: None = %s, Fast = %s, Normal = %s"
                              :format hovered-delay-none hovered-delay-short
                              hovered-delay-normal)))
    (when widgets.query_item.item_disabled (ImGui.EndDisabled ctx))
    (ImGui.InputText ctx :unused "" (ImGui.InputTextFlags_ReadOnly))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "This widget is only here to be able to tab-out of the widgets above and see e.g. Deactivated() status.")
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "Querying Window Status (Focused/Hovered etc.)")
    (when (not widgets.query_window)
      (set widgets.query_window
           {:embed_all_inside_a_child_window false :test_window false}))
    (set (rv widgets.query_window.embed_all_inside_a_child_window)
         (ImGui.Checkbox ctx
                          "Embed everything inside a child window for testing _RootWindow flag."
                          widgets.query_window.embed_all_inside_a_child_window))
    (var visible true)
    (when widgets.query_window.embed_all_inside_a_child_window
      (set visible
           (ImGui.BeginChild ctx :outer_child 0
                              (* (ImGui.GetFontSize ctx) 20) true)))
    (when visible
      (ImGui.BulletText ctx
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
                            (ImGui.IsWindowFocused ctx)
                            (ImGui.IsWindowFocused ctx
                                                    (ImGui.FocusedFlags_ChildWindows))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_ChildWindows)
                                                         (ImGui.FocusedFlags_NoPopupHierarchy)))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_ChildWindows)
                                                         (ImGui.FocusedFlags_DockHierarchy)))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_ChildWindows)
                                                         (ImGui.FocusedFlags_RootWindow)))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_ChildWindows)
                                                         (ImGui.FocusedFlags_RootWindow)
                                                         (ImGui.FocusedFlags_NoPopupHierarchy)))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_ChildWindows)
                                                         (ImGui.FocusedFlags_RootWindow)
                                                         (ImGui.FocusedFlags_DockHierarchy)))
                            (ImGui.IsWindowFocused ctx
                                                    (ImGui.FocusedFlags_RootWindow))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_RootWindow)
                                                         (ImGui.FocusedFlags_NoPopupHierarchy)))
                            (ImGui.IsWindowFocused ctx
                                                    (bor (ImGui.FocusedFlags_RootWindow)
                                                         (ImGui.FocusedFlags_DockHierarchy)))
                            (ImGui.IsWindowFocused ctx
                                                    (ImGui.FocusedFlags_AnyWindow))))
      (ImGui.BulletText ctx
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
                            (ImGui.IsWindowHovered ctx)
                            (ImGui.IsWindowHovered ctx
                                                    (ImGui.HoveredFlags_AllowWhenBlockedByPopup))
                            (ImGui.IsWindowHovered ctx
                                                    (ImGui.HoveredFlags_AllowWhenBlockedByActiveItem))
                            (ImGui.IsWindowHovered ctx
                                                    (ImGui.HoveredFlags_ChildWindows))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_ChildWindows)
                                                         (ImGui.HoveredFlags_NoPopupHierarchy)))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_ChildWindows)
                                                         (ImGui.HoveredFlags_DockHierarchy)))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_ChildWindows)
                                                         (ImGui.HoveredFlags_RootWindow)))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_ChildWindows)
                                                         (ImGui.HoveredFlags_RootWindow)
                                                         (ImGui.HoveredFlags_NoPopupHierarchy)))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_ChildWindows)
                                                         (ImGui.HoveredFlags_RootWindow)
                                                         (ImGui.HoveredFlags_DockHierarchy)))
                            (ImGui.IsWindowHovered ctx
                                                    (ImGui.HoveredFlags_RootWindow))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_RootWindow)
                                                         (ImGui.HoveredFlags_NoPopupHierarchy)))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_RootWindow)
                                                         (ImGui.HoveredFlags_DockHierarchy)))
                            (ImGui.IsWindowHovered ctx
                                                    (bor (ImGui.HoveredFlags_ChildWindows)
                                                         (ImGui.HoveredFlags_AllowWhenBlockedByPopup)))
                            (ImGui.IsWindowHovered ctx
                                                    (ImGui.HoveredFlags_AnyWindow))))
      (when (ImGui.BeginChild ctx :child 0 50 true)
        (ImGui.Text ctx
                     "This is another child window for testing the _ChildWindows flag.")
        (ImGui.EndChild ctx))
      (when widgets.query_window.embed_all_inside_a_child_window
        (ImGui.EndChild ctx)))
    (set (rv widgets.query_window.test_window)
         (ImGui.Checkbox ctx
                          "Hovered/Active tests after Begin() for title bar testing"
                          widgets.query_window.test_window))
    (when widgets.query_window.test_window
      (set (rv widgets.query_window.test_window)
           (ImGui.Begin ctx "Title bar Hovered/Active tests" true))
      (when rv
        (when (ImGui.BeginPopupContextItem ctx)
          (when (ImGui.MenuItem ctx :Close)
            (set widgets.query_window.test_window false))
          (ImGui.EndPopup ctx))
        (ImGui.Text ctx (: "IsItemHovered() after begin = %s (== is title bar hovered)
IsItemActive() after begin = %s (== is window being clicked/moved)
" :format (ImGui.IsItemHovered ctx)
                            (ImGui.IsItemActive ctx)))
        (ImGui.End ctx)))
    (ImGui.TreePop ctx))
  (when widgets.disable_all (ImGui.EndDisabled ctx))
  (when (ImGui.TreeNode ctx "Disable block")
    (set (rv widgets.disable_all)
         (ImGui.Checkbox ctx "Disable entire section above"
                          widgets.disable_all))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Demonstrate using BeginDisabled()/EndDisabled() across this section.")
    (ImGui.TreePop ctx))
  (when (ImGui.TreeNode ctx "Text Filter")
    (when (not widgets.filtering) (set widgets.filtering {:inst nil :text ""}))
    (when (not (ImGui.ValidatePtr widgets.filtering.inst :ImGui_TextFilter*))
      (set widgets.filtering.inst
           (ImGui.CreateTextFilter widgets.filtering.text)))
    (demo.HelpMarker "Not a widget per-se, but ImGui_TextFilter is a helper to perform simple filtering on text strings.")
    (ImGui.Text ctx "Filter usage:
  \"\"         display all lines
  \"xxx\"      display lines containing \"xxx\"
  \"xxx,yyy\"  display lines containing \"xxx\" or \"yyy\"
  \"-xxx\"     hide lines containing \"xxx\"")
    (when (ImGui.TextFilter_Draw widgets.filtering.inst ctx)
      (set widgets.filtering.text
           (ImGui.TextFilter_Get widgets.filtering.inst)))
    (local lines [:aaa1.c
                  :bbb1.c
                  :ccc1.c
                  :aaa2.cpp
                  :bbb2.cpp
                  :ccc2.cpp
                  :abc.h
                  "hello, world"])
    (each [i line (ipairs lines)]
      (when (ImGui.TextFilter_PassFilter widgets.filtering.inst line)
        (ImGui.BulletText ctx line)))
    (ImGui.TreePop ctx)))

(fn demo.ShowDemoWindowLayout []
  (when (ImGui.CollapsingHeader ctx "Layout & Scrolling")
    (var rv nil)
    (when (ImGui.TreeNode ctx "Child windows")
      (when (not layout.child)
        (set layout.child {:disable_menu false
                           :disable_mouse_wheel false
                           :offset_x 0}))
      (ImGui.SeparatorText ctx "Child windows")
      (demo.HelpMarker "Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window.")
      (set (rv layout.child.disable_mouse_wheel)
           (ImGui.Checkbox ctx "Disable Mouse Wheel"
                           layout.child.disable_mouse_wheel))
      (set (rv layout.child.disable_menu)
           (ImGui.Checkbox ctx "Disable Menu" layout.child.disable_menu))
      (do
        (var window-flags (ImGui.WindowFlags_HorizontalScrollbar))
        (when layout.child.disable_mouse_wheel
          (set window-flags
               (bor window-flags (ImGui.WindowFlags_NoScrollWithMouse))))
        (when (ImGui.BeginChild ctx :ChildL
                                (* (ImGui.GetContentRegionAvail ctx) 0.5) 260
                                false window-flags)
          (for [i 0 99] (ImGui.Text ctx (: "%04d: scrollable region" :format i)))
          (ImGui.EndChild ctx)))
      (ImGui.SameLine ctx)
      (do
        (var window-flags (ImGui.WindowFlags_None))
        (when layout.child.disable_mouse_wheel
          (set window-flags
               (bor window-flags (ImGui.WindowFlags_NoScrollWithMouse))))
        (when (not layout.child.disable_menu)
          (set window-flags (bor window-flags (ImGui.WindowFlags_MenuBar))))
        (ImGui.PushStyleVar ctx (ImGui.StyleVar_ChildRounding) 5)
        (local visible (ImGui.BeginChild ctx :ChildR 0 260 true window-flags))
        (when visible
          (when (and (not layout.child.disable_menu) (ImGui.BeginMenuBar ctx))
            (when (ImGui.BeginMenu ctx :Menu) (demo.ShowExampleMenuFile)
              (ImGui.EndMenu ctx))
            (ImGui.EndMenuBar ctx))
          (when (ImGui.BeginTable ctx :split 2
                                  (bor (ImGui.TableFlags_Resizable)
                                       (ImGui.TableFlags_NoSavedSettings)))
            (for [i 0 99] (ImGui.TableNextColumn ctx)
              (ImGui.Button ctx (: "%03d" :format i) (- FLT_MIN) 0))
            (ImGui.EndTable ctx))
          (ImGui.EndChild ctx))
        (ImGui.PopStyleVar ctx))
      (ImGui.SeparatorText ctx :Misc/Advanced)
      (do
        (ImGui.SetNextItemWidth ctx (* (ImGui.GetFontSize ctx) 8))
        (set (rv layout.child.offset_x)
             (ImGui.DragInt ctx "Offset X" layout.child.offset_x 1 (- 1000) 1000))
        (ImGui.SetCursorPosX ctx
                             (+ (ImGui.GetCursorPosX ctx) layout.child.offset_x))
        (ImGui.PushStyleColor ctx (ImGui.Col_ChildBg) 4278190180)
        (local visible
          (ImGui.BeginChild ctx :Red 200 100 true (ImGui.WindowFlags_None)))
        (ImGui.PopStyleColor ctx)
        (when visible
          (for [n 0 49] (ImGui.Text ctx (: "Some test %d" :format n)))
          (ImGui.EndChild ctx))
        (local child-is-hovered (ImGui.IsItemHovered ctx))
        (local (child-rect-min-x child-rect-min-y) (ImGui.GetItemRectMin ctx))
        (local (child-rect-max-x child-rect-max-y) (ImGui.GetItemRectMax ctx))
        (ImGui.Text ctx (: "Hovered: %s" :format child-is-hovered))
        (ImGui.Text ctx
                    (: "Rect of child window is: (%.0f,%.0f) (%.0f,%.0f)"
                       :format child-rect-min-x child-rect-min-y child-rect-max-x
                       child-rect-max-y)))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Widgets Width")
      (when (not layout.width)
        (set layout.width {:d 0 :show_indented_items true}))
      (set (rv layout.width.show_indented_items)
           (ImGui.Checkbox ctx "Show indented items"
                           layout.width.show_indented_items))
      (ImGui.Text ctx "SetNextItemWidth/PushItemWidth(100)")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Fixed width.")
      (ImGui.PushItemWidth ctx 100)
      (set (rv layout.width.d) (ImGui.DragDouble ctx "float##1b" layout.width.d))
      (when layout.width.show_indented_items (ImGui.Indent ctx)
        (set (rv layout.width.d)
             (ImGui.DragDouble ctx "float (indented)##1b" layout.width.d))
        (ImGui.Unindent ctx))
      (ImGui.PopItemWidth ctx)
      (ImGui.Text ctx "SetNextItemWidth/PushItemWidth(-100)")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Align to right edge minus 100")
      (ImGui.PushItemWidth ctx (- 100))
      (set (rv layout.width.d) (ImGui.DragDouble ctx "float##2a" layout.width.d))
      (when layout.width.show_indented_items (ImGui.Indent ctx)
        (set (rv layout.width.d)
             (ImGui.DragDouble ctx "float (indented)##2b" layout.width.d))
        (ImGui.Unindent ctx))
      (ImGui.PopItemWidth ctx)
      (ImGui.Text ctx
                  "SetNextItemWidth/PushItemWidth(GetContentRegionAvail().x * 0.5)")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Half of available width.
      (~ right-cursor_pos)
      (works within a column set)")
      (ImGui.PushItemWidth ctx (* (ImGui.GetContentRegionAvail ctx) 0.5))
      (set (rv layout.width.d) (ImGui.DragDouble ctx "float##3a" layout.width.d))
      (when layout.width.show_indented_items (ImGui.Indent ctx)
        (set (rv layout.width.d)
             (ImGui.DragDouble ctx "float (indented)##3b" layout.width.d))
        (ImGui.Unindent ctx))
      (ImGui.PopItemWidth ctx)
      (ImGui.Text ctx
                  "SetNextItemWidth/PushItemWidth(-GetContentRegionAvail().x * 0.5)")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Align to right edge minus half")
      (ImGui.PushItemWidth ctx (* (- (ImGui.GetContentRegionAvail ctx)) 0.5))
      (set (rv layout.width.d) (ImGui.DragDouble ctx "float##4a" layout.width.d))
      (when layout.width.show_indented_items (ImGui.Indent ctx)
        (set (rv layout.width.d)
             (ImGui.DragDouble ctx "float (indented)##4b" layout.width.d))
        (ImGui.Unindent ctx))
      (ImGui.PopItemWidth ctx)
      (ImGui.Text ctx "SetNextItemWidth/PushItemWidth(-FLT_MIN)")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Align to right edge")
      (ImGui.PushItemWidth ctx (- FLT_MIN))
      (set (rv layout.width.d) (ImGui.DragDouble ctx "##float5a" layout.width.d))
      (when layout.width.show_indented_items (ImGui.Indent ctx)
        (set (rv layout.width.d)
             (ImGui.DragDouble ctx "float (indented)##5b" layout.width.d))
        (ImGui.Unindent ctx))
      (ImGui.PopItemWidth ctx)
      (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Basic Horizontal Layout")
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
  (ImGui.TextWrapped ctx
                     "(Use ImGui.SameLine() to keep adding items to the right of the preceding item)")
  (ImGui.Text ctx "Two items: Hello")
  (ImGui.SameLine ctx)
  (ImGui.TextColored ctx 4294902015 :Sailor)
  (ImGui.Text ctx "More spacing: Hello")
  (ImGui.SameLine ctx 0 20)
  (ImGui.TextColored ctx 4294902015 :Sailor)
  (ImGui.AlignTextToFramePadding ctx)
  (ImGui.Text ctx "Normal buttons")
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :Banana)
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :Apple)
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :Corniflower)
  (ImGui.Text ctx "Small buttons")
  (ImGui.SameLine ctx)
  (ImGui.SmallButton ctx "Like this one")
  (ImGui.SameLine ctx)
  (ImGui.Text ctx "can fit within a text block.")
  (ImGui.Text ctx :Aligned)
  (ImGui.SameLine ctx 150)
  (ImGui.Text ctx :x=150)
  (ImGui.SameLine ctx 300)
  (ImGui.Text ctx :x=300)
  (ImGui.Text ctx :Aligned)
  (ImGui.SameLine ctx 150)
  (ImGui.SmallButton ctx :x=150)
  (ImGui.SameLine ctx 300)
  (ImGui.SmallButton ctx :x=300)
  (set (rv layout.horizontal.c1)
       (ImGui.Checkbox ctx :My layout.horizontal.c1))
  (ImGui.SameLine ctx)
  (set (rv layout.horizontal.c2)
       (ImGui.Checkbox ctx :Tailor layout.horizontal.c2))
  (ImGui.SameLine ctx)
  (set (rv layout.horizontal.c3)
       (ImGui.Checkbox ctx :Is layout.horizontal.c3))
  (ImGui.SameLine ctx)
  (set (rv layout.horizontal.c4)
       (ImGui.Checkbox ctx :Rich layout.horizontal.c4))
  (ImGui.PushItemWidth ctx 80)
  (local items "AAAA\000BBBB\000CCCC\000DDDD\000")
  (set (rv layout.horizontal.item)
       (ImGui.Combo ctx :Combo layout.horizontal.item items))
  (ImGui.SameLine ctx)
  (set (rv layout.horizontal.d0)
       (ImGui.SliderDouble ctx :X layout.horizontal.d0 0 5))
  (ImGui.SameLine ctx)
  (set (rv layout.horizontal.d1)
       (ImGui.SliderDouble ctx :Y layout.horizontal.d1 0 5))
  (ImGui.SameLine ctx)
  (set (rv layout.horizontal.d2)
       (ImGui.SliderDouble ctx :Z layout.horizontal.d2 0 5))
  (ImGui.PopItemWidth ctx)
  (ImGui.PushItemWidth ctx 80)
  (ImGui.Text ctx "Lists:")
  (each [i sel (ipairs layout.horizontal.selection)]
    (when (> i 1) (ImGui.SameLine ctx))
    (ImGui.PushID ctx i)
    (set-forcibly! (rv si) (ImGui.ListBox ctx "" sel items))
    (tset layout.horizontal.selection i si)
    (ImGui.PopID ctx))
  (ImGui.PopItemWidth ctx)
  (local button-sz [40 40])
  (ImGui.Button ctx :A (table.unpack button-sz))
  (ImGui.SameLine ctx)
  (ImGui.Dummy ctx (table.unpack button-sz))
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :B (table.unpack button-sz))
  (ImGui.Text ctx "Manual wrapping:")
  (local item-spacing-x
    (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemSpacing)))
  (local buttons-count 20)
  (local window-visible-x2
    (+ (ImGui.GetWindowPos ctx) (ImGui.GetWindowContentRegionMax ctx)))
  (for [n 0 (- buttons-count 1)]
    (ImGui.PushID ctx n)
    (ImGui.Button ctx :Box (table.unpack button-sz))
    (local last-button-x2 (ImGui.GetItemRectMax ctx))
    (local next-button-x2 (+ (+ last-button-x2 item-spacing-x)
                             (. button-sz 1)))
    (when (and (< (+ n 1) buttons-count) (< next-button-x2 window-visible-x2))
      (ImGui.SameLine ctx))
    (ImGui.PopID ctx))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Groups)
  (when (not widgets.groups)
    (set widgets.groups {:values (reaper.new_array [0.5 0.2 0.8 0.6 0.25])}))
  (demo.HelpMarker "BeginGroup() basically locks the horizontal position for new line. EndGroup() bundles the whole group so that you can use \"item\" functions such as IsItemHovered()/IsItemActive() or SameLine() etc. on the whole group.")
  (ImGui.BeginGroup ctx)
  (ImGui.BeginGroup ctx)
  (ImGui.Button ctx :AAA)
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :BBB)
  (ImGui.SameLine ctx)
  (ImGui.BeginGroup ctx)
  (ImGui.Button ctx :CCC)
  (ImGui.Button ctx :DDD)
  (ImGui.EndGroup ctx)
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :EEE)
  (ImGui.EndGroup ctx)
  (when (ImGui.IsItemHovered ctx)
    (ImGui.SetTooltip ctx "First group hovered"))
  (local size [(ImGui.GetItemRectSize ctx)])
  (local item-spacing-x
    (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemSpacing)))
  (ImGui.PlotHistogram ctx "##values" widgets.groups.values 0 nil 0 1
                       (table.unpack size))
  (ImGui.Button ctx :ACTION (* (- (. size 1) item-spacing-x) 0.5) (. size 2))
  (ImGui.SameLine ctx)
  (ImGui.Button ctx :REACTION (* (- (. size 1) item-spacing-x) 0.5)
                (. size 2))
  (ImGui.EndGroup ctx)
  (ImGui.SameLine ctx)
  (ImGui.Button ctx "LEVERAGE\nBUZZWORD" (table.unpack size))
  (ImGui.SameLine ctx)
  (when (ImGui.BeginListBox ctx :List (table.unpack size))
    (ImGui.Selectable ctx :Selected true)
    (ImGui.Selectable ctx "Not Selected" false)
    (ImGui.EndListBox ctx))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Text Baseline Alignment")
  (do
    (ImGui.BulletText ctx "Text baseline:") (ImGui.SameLine ctx)
    (demo.HelpMarker "This is testing the vertical alignment that gets applied on text to keep it aligned with widgets. Lines only composed of text or \"small\" widgets use less vertical space than lines with framed widgets.")
    (ImGui.Indent ctx)
    (ImGui.Text ctx "KO Blahblah")
    (ImGui.SameLine ctx)
    (ImGui.Button ctx "Some framed item")
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Baseline of button will look misaligned with text..")
    (ImGui.AlignTextToFramePadding ctx)
    (ImGui.Text ctx "OK Blahblah")
    (ImGui.SameLine ctx)
    (ImGui.Button ctx "Some framed item")
    (ImGui.SameLine ctx)
    (demo.HelpMarker "We call AlignTextToFramePadding() to vertically align the text baseline by +FramePadding.y")
    (ImGui.Button ctx "TEST##1")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx :TEST)
    (ImGui.SameLine ctx)
    (ImGui.SmallButton ctx "TEST##2")
    (ImGui.AlignTextToFramePadding ctx)
    (ImGui.Text ctx "Text aligned to framed item")
    (ImGui.SameLine ctx)
    (ImGui.Button ctx "Item##1")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx :Item)
    (ImGui.SameLine ctx)
    (ImGui.SmallButton ctx "Item##2")
    (ImGui.SameLine ctx)
    (ImGui.Button ctx "Item##3")
    (ImGui.Unindent ctx))
  (ImGui.Spacing ctx)
  (do
    (ImGui.BulletText ctx "Multi-line text:") (ImGui.Indent ctx)
    (ImGui.Text ctx "One\nTwo\nThree")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx "Hello\nWorld")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx :Banana)
    (ImGui.Text ctx :Banana)
    (ImGui.SameLine ctx)
    (ImGui.Text ctx "Hello\nWorld")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx "One\nTwo\nThree")
    (ImGui.Button ctx "HOP##1")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx :Banana)
    (ImGui.SameLine ctx)
    (ImGui.Text ctx "Hello\nWorld")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx :Banana)
    (ImGui.Button ctx "HOP##2")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx "Hello\nWorld")
    (ImGui.SameLine ctx)
    (ImGui.Text ctx :Banana)
    (ImGui.Unindent ctx))
  (ImGui.Spacing ctx)
  (do
    (ImGui.BulletText ctx "Misc items:")
    (ImGui.Indent ctx)
    (ImGui.Button ctx :80x80 80 80)
    (ImGui.SameLine ctx)
    (ImGui.Button ctx :50x50 50 50)
    (ImGui.SameLine ctx)
    (ImGui.Button ctx "Button()")
    (ImGui.SameLine ctx)
    (ImGui.SmallButton ctx "SmallButton()")
    (local spacing
      (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemInnerSpacing)))
    (ImGui.Button ctx "Button##1")
    (ImGui.SameLine ctx 0 spacing)
    (when (ImGui.TreeNode ctx "Node##1")
      (for [i 0 5] (ImGui.BulletText ctx (: "Item %d.." :format i)))
      (ImGui.TreePop ctx))
    (ImGui.AlignTextToFramePadding ctx)
    (local node-open (ImGui.TreeNode ctx "Node##2"))
    (ImGui.SameLine ctx 0 spacing)
    (ImGui.Button ctx "Button##2")
    (when node-open
      (for [i 0 5] (ImGui.BulletText ctx (: "Item %d.." :format i)))
      (ImGui.TreePop ctx))
    (ImGui.Button ctx "Button##3")
    (ImGui.SameLine ctx 0 spacing)
    (ImGui.BulletText ctx "Bullet text")
    (ImGui.AlignTextToFramePadding ctx)
    (ImGui.BulletText ctx :Node)
    (ImGui.SameLine ctx 0 spacing)
    (ImGui.Button ctx "Button##4")
    (ImGui.Unindent ctx))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Scrolling)
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
       (ImGui.Checkbox ctx :Decoration
                       layout.scrolling.enable_extra_decorations))
  (set (rv layout.scrolling.enable_track)
       (ImGui.Checkbox ctx :Track layout.scrolling.enable_track))
  (ImGui.PushItemWidth ctx 100)
  (ImGui.SameLine ctx 140)
  (set (rv layout.scrolling.track_item)
       (ImGui.DragInt ctx "##item" layout.scrolling.track_item 0.25 0 99
                      "Item = %d"))
  (when rv (set layout.scrolling.enable_track true))
  (var scroll-to-off (ImGui.Button ctx "Scroll Offset"))
  (ImGui.SameLine ctx 140)
  (set (rv layout.scrolling.scroll_to_off_px)
       (ImGui.DragDouble ctx "##off" layout.scrolling.scroll_to_off_px 1 0
                         FLT_MAX "+%.0f px"))
  (when rv (set scroll-to-off true))
  (var scroll-to-pos (ImGui.Button ctx "Scroll To Pos"))
  (ImGui.SameLine ctx 140)
  (set (rv layout.scrolling.scroll_to_pos_px)
       (ImGui.DragDouble ctx "##pos" layout.scrolling.scroll_to_pos_px 1
                         (- 10) FLT_MAX "X/Y = %.0f px"))
  (when rv (set scroll-to-pos true))
  (ImGui.PopItemWidth ctx)
  (when (or scroll-to-off scroll-to-pos)
    (set layout.scrolling.enable_track false))
  (local names [:Top "25%" :Center "75%" :Bottom])
  (local item-spacing-x
    (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemSpacing)))
  (var child-w (/ (- (ImGui.GetContentRegionAvail ctx) (* 4 item-spacing-x))
                  (length names)))
  (local child-flags (or (and layout.scrolling.enable_extra_decorations
                              (ImGui.WindowFlags_MenuBar))
                         (ImGui.WindowFlags_None)))
  (when (< child-w 1) (set child-w 1))
  (ImGui.PushID ctx "##VerticalScrolling")
  (each [i name (ipairs names)]
    (when (> i 1) (ImGui.SameLine ctx))
    (ImGui.BeginGroup ctx)
    (ImGui.Text ctx name)
    (if (ImGui.BeginChild ctx i child-w 200 true child-flags)
      (do
        (when (ImGui.BeginMenuBar ctx) (ImGui.Text ctx :abc)
          (ImGui.EndMenuBar ctx))
        (when scroll-to-off
          (ImGui.SetScrollY ctx layout.scrolling.scroll_to_off_px))
        (when scroll-to-pos
          (ImGui.SetScrollFromPosY ctx
                                   (+ (select 2
                                              (ImGui.GetCursorStartPos ctx))
                                      layout.scrolling.scroll_to_pos_px)
                                   (* (- i 1) 0.25)))
        (for [item 0 99]
          (if (and layout.scrolling.enable_track
                   (= item layout.scrolling.track_item))
            (do
              (ImGui.TextColored ctx 4294902015
                                 (: "Item %d" :format item))
              (ImGui.SetScrollHereY ctx (* (- i 1) 0.25)))
            (ImGui.Text ctx (: "Item %d" :format item))))
        (local scroll-y (ImGui.GetScrollY ctx))
        (local scroll-max-y (ImGui.GetScrollMaxY ctx))
        (ImGui.EndChild ctx)
        (ImGui.Text ctx (: "%.0f/%.0f" :format scroll-y scroll-max-y)))
      (ImGui.Text ctx :N/A))
    (ImGui.EndGroup ctx))
  (ImGui.PopID ctx)
  (ImGui.Spacing ctx)
  (demo.HelpMarker "Use SetScrollHereX() or SetScrollFromPosX() to scroll to a given horizontal position.

  Because the clipping rectangle of most window hides half worth of WindowPadding on the left/right, using SetScrollFromPosX(+1) will usually result in clipped text whereas the equivalent SetScrollFromPosY(+1) wouldn't.")
  (ImGui.PushID ctx "##HorizontalScrolling")
  (local scrollbar-size
    (ImGui.GetStyleVar ctx (ImGui.StyleVar_ScrollbarSize)))
  (local window-padding-y
    (select 2 (ImGui.GetStyleVar ctx (ImGui.StyleVar_WindowPadding))))
  (local child-height (+ (+ (ImGui.GetTextLineHeight ctx) scrollbar-size)
                         (* window-padding-y 2)))
  (var child-flags (ImGui.WindowFlags_HorizontalScrollbar))
  (when layout.scrolling.enable_extra_decorations
    (set child-flags
         (bor child-flags (ImGui.WindowFlags_AlwaysVerticalScrollbar))))
  (each [i name (ipairs names)]
    (var (scroll-x scroll-max-x) (values 0 0))
    (when (ImGui.BeginChild ctx i (- 100) child-height true child-flags)
      (when scroll-to-off
        (ImGui.SetScrollX ctx layout.scrolling.scroll_to_off_px))
      (when scroll-to-pos
        (ImGui.SetScrollFromPosX ctx
                                 (+ (ImGui.GetCursorStartPos ctx)
                                    layout.scrolling.scroll_to_pos_px)
                                 (* (- i 1) 0.25)))
      (for [item 0 99]
        (when (> item 0) (ImGui.SameLine ctx))
        (if (and layout.scrolling.enable_track
                 (= item layout.scrolling.track_item))
          (do
            (ImGui.TextColored ctx 4294902015 (: "Item %d" :format item))
            (ImGui.SetScrollHereX ctx (* (- i 1) 0.25)))
          (ImGui.Text ctx (: "Item %d" :format item))))
      (set scroll-x (ImGui.GetScrollX ctx))
      (set scroll-max-x (ImGui.GetScrollMaxX ctx))
      (ImGui.EndChild ctx))
    (ImGui.SameLine ctx)
    (ImGui.Text ctx (: "%s\n%.0f/%.0f" :format name scroll-x scroll-max-x))
    (ImGui.Spacing ctx))
(ImGui.PopID ctx)
(demo.HelpMarker "Horizontal scrolling for a window is enabled via the ImGuiWindowFlags_HorizontalScrollbar flag.

You may want to also explicitly specify content width by using SetNextWindowContentWidth() before Begin().")
(set (rv layout.scrolling.lines)
     (ImGui.SliderInt ctx :Lines layout.scrolling.lines 1 15))
(ImGui.PushStyleVar ctx (ImGui.StyleVar_FrameRounding) 3)
(ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) 2 1)
(local scrolling-child-width (+ (* (ImGui.GetFrameHeightWithSpacing ctx) 7)
                                30))
(var (scroll-x scroll-max-x) (values 0 0))
(when (ImGui.BeginChild ctx :scrolling 0 scrolling-child-width true
                        (ImGui.WindowFlags_HorizontalScrollbar))
  (for [line 0 (- layout.scrolling.lines 1)]
    (local num-buttons (+ 10
                          (or (and (not= (band line 1) 0) (* line 9))
                              (* line 3))))
    (for [n 0 (- num-buttons 1)]
      (when (> n 0) (ImGui.SameLine ctx))
      (ImGui.PushID ctx (+ n (* line 1000)))
      (var label nil)
      (if (= (% n 15) 0) (set label :FizzBuzz)
        (= (% n 3) 0) (set label :Fizz)
        (= (% n 5) 0) (set label :Buzz)
        (set label (tostring n)))
      (local hue (* n 0.05))
      (ImGui.PushStyleColor ctx (ImGui.Col_Button) (demo.HSV hue 0.6 0.6))
      (ImGui.PushStyleColor ctx (ImGui.Col_ButtonHovered)
                            (demo.HSV hue 0.7 0.7))
      (ImGui.PushStyleColor ctx (ImGui.Col_ButtonActive)
                            (demo.HSV hue 0.8 0.8))
      (ImGui.Button ctx label (+ 40 (* (math.sin (+ line n)) 20)) 0)
      (ImGui.PopStyleColor ctx 3)
      (ImGui.PopID ctx)))
  (set scroll-x (ImGui.GetScrollX ctx))
  (set scroll-max-x (ImGui.GetScrollMaxX ctx))
  (ImGui.EndChild ctx))
(ImGui.PopStyleVar ctx 2)
(var scroll-x-delta 0)
(ImGui.SmallButton ctx "<<")
(when (ImGui.IsItemActive ctx)
  (set scroll-x-delta (* (- 0 (ImGui.GetDeltaTime ctx)) 1000)))
(ImGui.SameLine ctx)
(ImGui.Text ctx "Scroll from code")
(ImGui.SameLine ctx)
(ImGui.SmallButton ctx ">>")
(when (ImGui.IsItemActive ctx)
  (set scroll-x-delta (* (ImGui.GetDeltaTime ctx) 1000)))
(ImGui.SameLine ctx)
(ImGui.Text ctx (: "%.0f/%.0f" :format scroll-x scroll-max-x))
(when (not= scroll-x-delta 0)
  (when (ImGui.BeginChild ctx :scrolling)
    (ImGui.SetScrollX ctx (+ (ImGui.GetScrollX ctx) scroll-x-delta))
    (ImGui.EndChild ctx)))
(ImGui.Spacing ctx)
(set (rv layout.scrolling.show_horizontal_contents_size_demo_window)
     (ImGui.Checkbox ctx "Show Horizontal contents size demo window"
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
    (ImGui.SetNextWindowContentSize ctx
                                    layout.horizontal_window.contents_size_x
                                    0))
  (set (rv layout.scrolling.show_horizontal_contents_size_demo_window)
       (ImGui.Begin ctx "Horizontal contents size demo window" true
                    (or (and layout.horizontal_window.show_h_scrollbar
                             (ImGui.WindowFlags_HorizontalScrollbar))
                        (ImGui.WindowFlags_None))))
  (when rv
    (ImGui.PushStyleVar ctx (ImGui.StyleVar_ItemSpacing) 2 0)
    (ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) 2 0)
    (demo.HelpMarker "Test of different widgets react and impact the work rectangle growing when horizontal scrolling is enabled.

    Use 'Metrics->Tools->Show windows rectangles' to visualize rectangles.")
    (set (rv layout.horizontal_window.show_h_scrollbar)
         (ImGui.Checkbox ctx :H-scrollbar
                         layout.horizontal_window.show_h_scrollbar))
    (set (rv layout.horizontal_window.show_button)
         (ImGui.Checkbox ctx :Button layout.horizontal_window.show_button))
    (set (rv layout.horizontal_window.show_tree_nodes)
         (ImGui.Checkbox ctx "Tree nodes"
                         layout.horizontal_window.show_tree_nodes))
    (set (rv layout.horizontal_window.show_text_wrapped)
         (ImGui.Checkbox ctx "Text wrapped"
                         layout.horizontal_window.show_text_wrapped))
    (set (rv layout.horizontal_window.show_columns)
         (ImGui.Checkbox ctx :Columns
                         layout.horizontal_window.show_columns))
    (set (rv layout.horizontal_window.show_tab_bar)
         (ImGui.Checkbox ctx "Tab bar"
                         layout.horizontal_window.show_tab_bar))
    (set (rv layout.horizontal_window.show_child)
         (ImGui.Checkbox ctx :Child layout.horizontal_window.show_child))
    (set (rv layout.horizontal_window.explicit_content_size)
         (ImGui.Checkbox ctx "Explicit content size"
                         layout.horizontal_window.explicit_content_size))
    (ImGui.Text ctx
                (: "Scroll %.1f/%.1f %.1f/%.1f" :format
                   (ImGui.GetScrollX ctx) (ImGui.GetScrollMaxX ctx)
                   (ImGui.GetScrollY ctx) (ImGui.GetScrollMaxY ctx)))
    (when layout.horizontal_window.explicit_content_size
      (ImGui.SameLine ctx)
      (ImGui.SetNextItemWidth ctx 100)
      (set (rv layout.horizontal_window.contents_size_x)
           (ImGui.DragDouble ctx "##csx"
                             layout.horizontal_window.contents_size_x))
      (local (x y) (ImGui.GetCursorScreenPos ctx))
      (local draw-list (ImGui.GetWindowDrawList ctx))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x 10) (+ y 10)
                                    4294967295)
      (ImGui.DrawList_AddRectFilled draw-list
                                    (- (+ x
                                          layout.horizontal_window.contents_size_x)
                                       10)
                                    y
                                    (+ x
                                       layout.horizontal_window.contents_size_x)
                                    (+ y 10) 4294967295)
      (ImGui.Dummy ctx 0 10))
    (ImGui.PopStyleVar ctx 2)
    (ImGui.Separator ctx)
    (when layout.horizontal_window.show_button
      (ImGui.Button ctx "this is a 300-wide button" 300 0))
    (when layout.horizontal_window.show_tree_nodes
      (when (ImGui.TreeNode ctx "this is a tree node")
        (when (ImGui.TreeNode ctx "another one of those tree node...")
          (ImGui.Text ctx "Some tree contents")
          (ImGui.TreePop ctx))
        (ImGui.TreePop ctx))
      (ImGui.CollapsingHeader ctx :CollapsingHeader true))
    (when layout.horizontal_window.show_text_wrapped
      (ImGui.TextWrapped ctx
                         "This text should automatically wrap on the edge of the work rectangle."))
    (when layout.horizontal_window.show_columns
      (ImGui.Text ctx "Tables:")
      (when (ImGui.BeginTable ctx :table 4 (ImGui.TableFlags_Borders))
        (for [n 0 3]
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx
                      (: "Width %.2f" :format
                         (ImGui.GetContentRegionAvail ctx))))
        (ImGui.EndTable ctx)))
    (when (and layout.horizontal_window.show_tab_bar
               (ImGui.BeginTabBar ctx :Hello))
      (when (ImGui.BeginTabItem ctx :OneOneOne) (ImGui.EndTabItem ctx))
      (when (ImGui.BeginTabItem ctx :TwoTwoTwo) (ImGui.EndTabItem ctx))
      (when (ImGui.BeginTabItem ctx :ThreeThreeThree)
        (ImGui.EndTabItem ctx))
      (when (ImGui.BeginTabItem ctx :FourFourFour) (ImGui.EndTabItem ctx))
      (ImGui.EndTabBar ctx))
    (when layout.horizontal_window.show_child
      (when (ImGui.BeginChild ctx :child 0 0 true) (ImGui.EndChild ctx)))
    (ImGui.End ctx)))
(ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Clipping)
  (when (not layout.clipping)
    (set layout.clipping {:offset [30 30] :size [100 100]}))
  (set-forcibly! (rv s1 s2)
                 (ImGui.DragDouble2 ctx :size (. layout.clipping.size 1)
                                    (. layout.clipping.size 2) 0.5 1 200
                                    "%.0f"))
  (tset layout.clipping.size 1 s1)
  (tset layout.clipping.size 2 s2)
  (ImGui.TextWrapped ctx "(Click and drag to scroll)")
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
    (when (> n 0) (ImGui.SameLine ctx))
    (ImGui.PushID ctx n)
    (ImGui.InvisibleButton ctx "##canvas"
                           (table.unpack layout.clipping.size))
    (when (and (ImGui.IsItemActive ctx)
               (ImGui.IsMouseDragging ctx (ImGui.MouseButton_Left)))
      (local mouse-delta [(ImGui.GetMouseDelta ctx)])
      (tset layout.clipping.offset 1
            (+ (. layout.clipping.offset 1) (. mouse-delta 1)))
      (tset layout.clipping.offset 2
            (+ (. layout.clipping.offset 2) (. mouse-delta 2))))
    (ImGui.PopID ctx)
    (when (ImGui.IsItemVisible ctx)
      (local (p0-x p0-y) (ImGui.GetItemRectMin ctx))
      (local (p1-x p1-y) (ImGui.GetItemRectMax ctx))
      (local text-str "Line 1 hello\nLine 2 clip me!")
      (local text-pos
        [(+ p0-x (. layout.clipping.offset 1))
         (+ p0-y (. layout.clipping.offset 2))])
      (local draw-list (ImGui.GetWindowDrawList ctx))
      (if (= n 0) (do
                    (ImGui.PushClipRect ctx p0-x p0-y p1-x p1-y true)
                    (ImGui.DrawList_AddRectFilled draw-list p0-x p0-y p1-x
                                                  p1-y 1515878655)
                    (ImGui.DrawList_AddText draw-list (. text-pos 1)
                                            (. text-pos 2) 4294967295
                                            text-str)
                    (ImGui.PopClipRect ctx)) (= n 1)
        (do
          (ImGui.DrawList_PushClipRect draw-list p0-x p0-y p1-x p1-y true)
          (ImGui.DrawList_AddRectFilled draw-list p0-x p0-y p1-x p1-y
                                        1515878655)
          (ImGui.DrawList_AddText draw-list (. text-pos 1) (. text-pos 2)
                                  4294967295 text-str)
          (ImGui.DrawList_PopClipRect draw-list)) (= n 2)
        (let [clip-rect [p0-x p0-y p1-x p1-y]]
          (ImGui.DrawList_AddRectFilled draw-list p0-x p0-y p1-x p1-y
                                        1515878655)
          (ImGui.DrawList_AddTextEx draw-list (ImGui.GetFont ctx)
                                    (ImGui.GetFontSize ctx) (. text-pos 1)
                                    (. text-pos 2) 4294967295 text-str 0
                                    (table.unpack clip-rect))))))
  (ImGui.TreePop ctx))
)
  )

(fn demo.ShowDemoWindowPopups []
  (when (ImGui.CollapsingHeader ctx "Popups & Modal windows")
    (var rv nil)
    (when (ImGui.TreeNode ctx :Popups)
      (when (not popups.popups)
        (set popups.popups
             {:selected_fish (- 1) :toggles [true false false false false]}))
      (ImGui.TextWrapped ctx
                         "When a popup is active, it inhibits interacting with windows that are behind the popup. Clicking outside the popup closes it.")
      (local names [:Bream :Haddock :Mackerel :Pollock :Tilefish])
      (when (ImGui.Button ctx :Select..) (ImGui.OpenPopup ctx :my_select_popup))
      (ImGui.SameLine ctx)
      (ImGui.Text ctx (or (. names popups.popups.selected_fish) :<None>))
      (when (ImGui.BeginPopup ctx :my_select_popup)
        (ImGui.SeparatorText ctx :Aquarium)
        (each [i fish (ipairs names)]
          (when (ImGui.Selectable ctx fish) (set popups.popups.selected_fish i)))
        (ImGui.EndPopup ctx))
      (when (ImGui.Button ctx :Toggle..) (ImGui.OpenPopup ctx :my_toggle_popup))
      (when (ImGui.BeginPopup ctx :my_toggle_popup)
        (each [i fish (ipairs names)]
          (set-forcibly! (rv ti)
                         (ImGui.MenuItem ctx fish "" (. popups.popups.toggles i)))
          (tset popups.popups.toggles i ti))
        (when (ImGui.BeginMenu ctx :Sub-menu) (ImGui.MenuItem ctx "Click me")
          (ImGui.EndMenu ctx))
        (ImGui.Separator ctx)
        (ImGui.Text ctx "Tooltip here")
        (when (ImGui.IsItemHovered ctx)
          (ImGui.SetTooltip ctx "I am a tooltip over a popup"))
        (when (ImGui.Button ctx "Stacked Popup")
          (ImGui.OpenPopup ctx "another popup"))
        (when (ImGui.BeginPopup ctx "another popup")
          (each [i fish (ipairs names)]
            (set-forcibly! (rv ti)
                           (ImGui.MenuItem ctx fish ""
                                           (. popups.popups.toggles i)))
            (tset popups.popups.toggles i ti))
          (when (ImGui.BeginMenu ctx :Sub-menu) (ImGui.MenuItem ctx "Click me")
            (when (ImGui.Button ctx "Stacked Popup")
              (ImGui.OpenPopup ctx "another popup"))
            (when (ImGui.BeginPopup ctx "another popup")
              (ImGui.Text ctx "I am the last one here.")
              (ImGui.EndPopup ctx))
            (ImGui.EndMenu ctx))
          (ImGui.EndPopup ctx))
        (ImGui.EndPopup ctx))
      (when (ImGui.Button ctx "With a menu..")
        (ImGui.OpenPopup ctx :my_file_popup))
      (when (ImGui.BeginPopup ctx :my_file_popup (ImGui.WindowFlags_MenuBar))
        (when (ImGui.BeginMenuBar ctx)
          (when (ImGui.BeginMenu ctx :File) (demo.ShowExampleMenuFile)
            (ImGui.EndMenu ctx))
          (when (ImGui.BeginMenu ctx :Edit) (ImGui.MenuItem ctx :Dummy)
            (ImGui.EndMenu ctx))
          (ImGui.EndMenuBar ctx))
        (ImGui.Text ctx "Hello from popup!")
        (ImGui.Button ctx "This is a dummy button..")
        (ImGui.EndPopup ctx))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Context menus")
      (when (not popups.context)
        (set popups.context {:name :Label1 :selected 0 :value 0.5}))
      (demo.HelpMarker "\"Context\" functions are simple helpers to associate a Popup to a given Item or Window identifier.")
      (let [names [:Label1 :Label2 :Label3 :Label4 :Label5]]
        (each [n name (ipairs names)]
          (when (ImGui.Selectable ctx name (= popups.context.selected n))
            (set popups.context.selected n))
          (when (ImGui.BeginPopupContextItem ctx)
            (set popups.context.selected n)
            (ImGui.Text ctx (: "This a popup for \"%s\"!" :format name))
            (when (ImGui.Button ctx :Close) (ImGui.CloseCurrentPopup ctx))
            (ImGui.EndPopup ctx))
          (when (ImGui.IsItemHovered ctx)
            (ImGui.SetTooltip ctx "Right-click to open popup"))))
      (do
        (demo.HelpMarker "Text() elements don't have stable identifiers so we need to provide one.")
        (ImGui.Text ctx (: "Value = %.6f <-- (1) right-click this text" :format
                           popups.context.value))
        (when (ImGui.BeginPopupContextItem ctx "my popup")
          (when (ImGui.Selectable ctx "Set to zero")
            (set popups.context.value 0))
          (when (ImGui.Selectable ctx "Set to PI")
            (set popups.context.value 3.141592))
          (ImGui.SetNextItemWidth ctx (- FLT_MIN))
          (set (rv popups.context.value)
               (ImGui.DragDouble ctx "##Value" popups.context.value 0.1 0 0))
          (ImGui.EndPopup ctx))
        (ImGui.Text ctx "(2) Or right-click this text")
        (ImGui.OpenPopupOnItemClick ctx "my popup"
                                    (ImGui.PopupFlags_MouseButtonRight))
        (when (ImGui.Button ctx "(3) Or click this button")
          (ImGui.OpenPopup ctx "my popup")))
      (do
        (demo.HelpMarker "Showcase using a popup ID linked to item ID, with the item having a changing label + stable ID using the ### operator.")
        (ImGui.Button ctx (: "Button: %s###Button" :format popups.context.name))
        (when (ImGui.BeginPopupContextItem ctx) (ImGui.Text ctx "Edit name:")
          (set (rv popups.context.name)
               (ImGui.InputText ctx "##edit" popups.context.name))
          (when (ImGui.Button ctx :Close) (ImGui.CloseCurrentPopup ctx))
          (ImGui.EndPopup ctx))
        (ImGui.SameLine ctx)
        (ImGui.Text ctx "(<-- right-click here)"))
      (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx :Modals)
  (when (not popups.modal)
    (set popups.modal {:color 1723007104
                       :dont_ask_me_next_time false
                       :item 1}))
  (ImGui.TextWrapped ctx
                     "Modal windows are like popups but the user cannot close them by clicking outside.")
  (when (ImGui.Button ctx :Delete..) (ImGui.OpenPopup ctx :Delete?))
  (local center [(ImGui.Viewport_GetCenter (ImGui.GetWindowViewport ctx))])
  (ImGui.SetNextWindowPos ctx (. center 1) (. center 2)
                          (ImGui.Cond_Appearing) 0.5 0.5)
  (when (ImGui.BeginPopupModal ctx :Delete? nil
                               (ImGui.WindowFlags_AlwaysAutoResize))
    (ImGui.Text ctx "All those beautiful files will be deleted.
    This operation cannot be undone!")
    (ImGui.Separator ctx)
    (ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) 0 0)
    (set (rv popups.modal.dont_ask_me_next_time)
         (ImGui.Checkbox ctx "Don't ask me next time"
                         popups.modal.dont_ask_me_next_time))
    (ImGui.PopStyleVar ctx)
    (when (ImGui.Button ctx :OK 120 0) (ImGui.CloseCurrentPopup ctx))
    (ImGui.SetItemDefaultFocus ctx)
    (ImGui.SameLine ctx)
    (when (ImGui.Button ctx :Cancel 120 0) (ImGui.CloseCurrentPopup ctx))
    (ImGui.EndPopup ctx))
  (when (ImGui.Button ctx "Stacked modals..")
    (ImGui.OpenPopup ctx "Stacked 1"))
  (when (ImGui.BeginPopupModal ctx "Stacked 1" nil
                               (ImGui.WindowFlags_MenuBar))
    (when (ImGui.BeginMenuBar ctx)
      (when (ImGui.BeginMenu ctx :File)
        (when (ImGui.MenuItem ctx "Some menu item") nil)
        (ImGui.EndMenu ctx))
      (ImGui.EndMenuBar ctx))
    (ImGui.Text ctx
                "Hello from Stacked The First
                Using style.Colors[ImGuiCol_ModalWindowDimBg] behind it.")
    (set (rv popups.modal.item)
         (ImGui.Combo ctx :Combo popups.modal.item
                      "aaaa\000bbbb\000cccc\000dddd\000eeee\000"))
    (set (rv popups.modal.color)
         (ImGui.ColorEdit4 ctx :color popups.modal.color))
    (when (ImGui.Button ctx "Add another modal..")
      (ImGui.OpenPopup ctx "Stacked 2"))
    (local unused-open true)
    (when (ImGui.BeginPopupModal ctx "Stacked 2" unused-open)
      (ImGui.Text ctx "Hello from Stacked The Second!")
      (when (ImGui.Button ctx :Close) (ImGui.CloseCurrentPopup ctx))
      (ImGui.EndPopup ctx))
    (when (ImGui.Button ctx :Close) (ImGui.CloseCurrentPopup ctx))
    (ImGui.EndPopup ctx))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Menus inside a regular window")
  (ImGui.TextWrapped ctx
                     "Below we are testing adding menu items to a regular window. It's rather unusual but should work!")
  (ImGui.Separator ctx)
  (ImGui.MenuItem ctx "Menu item" :CTRL+M)
  (when (ImGui.BeginMenu ctx "Menu inside a regular window")
    (demo.ShowExampleMenuFile)
    (ImGui.EndMenu ctx))
  (ImGui.Separator ctx)
  (ImGui.TreePop ctx))
)
  )

(local My-item-column-iD_ID 4)

(local My-item-column-iD_Name 5)

(local My-item-column-iD_Quantity 6)

(local My-item-column-iD_Description 7)

(fn demo.CompareTableItems [a b]
  (for [next-id 0 math.huge]
    (local (ok col-user-id col-idx sort-order sort-direction)
           (ImGui.TableGetColumnSortSpecs ctx next-id))
    (when (not ok) (lua :break))
    (var key nil)
    (if (= col-user-id My-item-column-iD_ID) (set key :id)
        (= col-user-id My-item-column-iD_Name) (set key :name)
        (= col-user-id My-item-column-iD_Quantity) (set key :quantity)
        (= col-user-id My-item-column-iD_Description) (set key :name)
        (error "unknown user column ID"))
    (local is-ascending (= sort-direction (ImGui.SortDirection_Ascending)))
    (if (< (. a key) (. b key))
        (let [___antifnl_rtn_1___ is-ascending]
          (lua "return ___antifnl_rtn_1___")) (> (. a key) (. b key))
        (let [___antifnl_rtn_1___ (not is-ascending)]
          (lua "return ___antifnl_rtn_1___"))))
  (< a.id b.id))

(fn demo.PushStyleCompact []
  (let [(frame-padding-x frame-padding-y) (ImGui.GetStyleVar ctx
                                                              (ImGui.StyleVar_FramePadding))
        (item-spacing-x item-spacing-y) (ImGui.GetStyleVar ctx
                                                            (ImGui.StyleVar_ItemSpacing))]
    (ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) frame-padding-x
                         (math.floor (* frame-padding-y 0.6)))
    (ImGui.PushStyleVar ctx (ImGui.StyleVar_ItemSpacing) item-spacing-x
                         (math.floor (* item-spacing-y 0.6)))))

(fn demo.PopStyleCompact [] (ImGui.PopStyleVar ctx 2))

(fn demo.EditTableSizingFlags [flags]
  (let [policies [{:name :Default
                   :tooltip "Use default sizing policy:
- ImGuiTableFlags_SizingFixedFit if ScrollX is on or if host window has ImGuiWindowFlags_AlwaysAutoResize.
- ImGuiTableFlags_SizingStretchSame otherwise."
                   :value (ImGui.TableFlags_None)}
                  {:name :ImGuiTableFlags_SizingFixedFit
                   :tooltip "Columns default to _WidthFixed (if resizable) or _WidthAuto (if not resizable), matching contents width."
                   :value (ImGui.TableFlags_SizingFixedFit)}
                  {:name :ImGuiTableFlags_SizingFixedSame
                   :tooltip "Columns are all the same width, matching the maximum contents width.
Implicitly disable ImGuiTableFlags_Resizable and enable ImGuiTableFlags_NoKeepColumnsVisible."
                   :value (ImGui.TableFlags_SizingFixedSame)}
                  {:name :ImGuiTableFlags_SizingStretchProp
                   :tooltip "Columns default to _WidthStretch with weights proportional to their widths."
                   :value (ImGui.TableFlags_SizingStretchProp)}
                  {:name :ImGuiTableFlags_SizingStretchSame
                   :tooltip "Columns default to _WidthStretch with same weights."
                   :value (ImGui.TableFlags_SizingStretchSame)}]
        sizing-mask (bor (ImGui.TableFlags_SizingFixedFit)
                         (ImGui.TableFlags_SizingFixedSame)
                         (ImGui.TableFlags_SizingStretchProp)
                         (ImGui.TableFlags_SizingStretchSame))]
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
    (when (ImGui.BeginCombo ctx "Sizing Policy" preview-text)
      (each [n policy (ipairs policies)]
        (when (ImGui.Selectable ctx policy.name (= idx n))
          (set-forcibly! flags
                         (bor (band flags (bnot sizing-mask)) policy.value))))
      (ImGui.EndCombo ctx))
    (ImGui.SameLine ctx)
    (ImGui.TextDisabled ctx "(?)")
    (when (ImGui.IsItemHovered ctx)
      (ImGui.BeginTooltip ctx)
      (ImGui.PushTextWrapPos ctx (* (ImGui.GetFontSize ctx) 50))
      (each [m policy (ipairs policies)]
        (ImGui.Separator ctx)
        (ImGui.Text ctx (: "%s:" :format policy.name))
        (ImGui.Separator ctx)
        (local indent-spacing
               (ImGui.GetStyleVar ctx (ImGui.StyleVar_IndentSpacing)))
        (ImGui.SetCursorPosX ctx
                              (+ (ImGui.GetCursorPosX ctx)
                                 (* indent-spacing 0.5)))
        (ImGui.Text ctx policy.tooltip))
      (ImGui.PopTextWrapPos ctx)
      (ImGui.EndTooltip ctx))
    flags))

(fn demo.EditTableColumnsFlags [flags]
  (let [rv nil
        width-mask (bor (ImGui.TableColumnFlags_WidthStretch)
                        (ImGui.TableColumnFlags_WidthFixed))]
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_Disabled flags
                                         (ImGui.TableColumnFlags_Disabled)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Master disable flag (also hide from context menu)")
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_DefaultHide flags
                                         (ImGui.TableColumnFlags_DefaultHide)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_DefaultSort flags
                                         (ImGui.TableColumnFlags_DefaultSort)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_WidthStretch flags
                                         (ImGui.TableColumnFlags_WidthStretch)))
    (when rv
      (set-forcibly! flags
                     (band flags
                           (bnot (^ width-mask
                                    (ImGui.TableColumnFlags_WidthStretch))))))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_WidthFixed flags
                                         (ImGui.TableColumnFlags_WidthFixed)))
    (when rv
      (set-forcibly! flags
                     (band flags
                           (bnot (^ width-mask
                                    (ImGui.TableColumnFlags_WidthFixed))))))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoResize flags
                                         (ImGui.TableColumnFlags_NoResize)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoReorder flags
                                         (ImGui.TableColumnFlags_NoReorder)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoHide flags
                                         (ImGui.TableColumnFlags_NoHide)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoClip flags
                                         (ImGui.TableColumnFlags_NoClip)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoSort flags
                                         (ImGui.TableColumnFlags_NoSort)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoSortAscending flags
                                         (ImGui.TableColumnFlags_NoSortAscending)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoSortDescending flags
                                         (ImGui.TableColumnFlags_NoSortDescending)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoHeaderLabel flags
                                         (ImGui.TableColumnFlags_NoHeaderLabel)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_NoHeaderWidth flags
                                         (ImGui.TableColumnFlags_NoHeaderWidth)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_PreferSortAscending flags
                                         (ImGui.TableColumnFlags_PreferSortAscending)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_PreferSortDescending flags
                                         (ImGui.TableColumnFlags_PreferSortDescending)))
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_IndentEnable flags
                                         (ImGui.TableColumnFlags_IndentEnable)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Default for column 0")
    (set-forcibly! (rv flags)
                   (ImGui.CheckboxFlags ctx :_IndentDisable flags
                                         (ImGui.TableColumnFlags_IndentDisable)))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Default for column >0")
    flags))

(fn demo.ShowTableColumnsStatusFlags [flags]
  (ImGui.CheckboxFlags ctx :_IsEnabled flags
                        (ImGui.TableColumnFlags_IsEnabled))
  (ImGui.CheckboxFlags ctx :_IsVisible flags
                        (ImGui.TableColumnFlags_IsVisible))
  (ImGui.CheckboxFlags ctx :_IsSorted flags (ImGui.TableColumnFlags_IsSorted))
  (ImGui.CheckboxFlags ctx :_IsHovered flags
                        (ImGui.TableColumnFlags_IsHovered)))

(fn demo.ShowDemoWindowTables []
  (when (ImGui.CollapsingHeader ctx :Tables)
    (var rv nil)
    (local TEXT_BASE_WIDTH (ImGui.CalcTextSize ctx :A))
    (local TEXT_BASE_HEIGHT (ImGui.GetTextLineHeightWithSpacing ctx))
    (ImGui.PushID ctx :Tables)
    (var open-action (- 1))
    (when (ImGui.Button ctx "Open all") (set open-action 1))
    (ImGui.SameLine ctx)
    (when (ImGui.Button ctx "Close all") (set open-action 0))
    (ImGui.SameLine ctx)
    (when (= tables.disable_indent nil) (set tables.disable_indent false))
    (set (rv tables.disable_indent)
         (ImGui.Checkbox ctx "Disable tree indentation" tables.disable_indent))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Disable the indenting of tree nodes so demo tables can use the full window width.")
    (ImGui.Separator ctx)
    (when tables.disable_indent
      (ImGui.PushStyleVar ctx (ImGui.StyleVar_IndentSpacing) 0))

    (fn Do-open-action []
      (when (not= open-action (- 1))
        (ImGui.SetNextItemOpen ctx (not= open-action 0))))

    (Do-open-action)
    (when (ImGui.TreeNode ctx :Basic)
      (demo.HelpMarker "Using TableNextRow() + calling TableSetColumnIndex() _before_ each cell, in a loop.")
      (when (ImGui.BeginTable ctx :table1 3)
        (for [row 0 3]
          (ImGui.TableNextRow ctx)
          (for [column 0 2] (ImGui.TableSetColumnIndex ctx column)
            (ImGui.Text ctx (: "Row %d Column %d" :format row column))))
        (ImGui.EndTable ctx))
      (demo.HelpMarker "Using TableNextRow() + calling TableNextColumn() _before_ each cell, manually.")
      (when (ImGui.BeginTable ctx :table2 3)
        (for [row 0 3] (ImGui.TableNextRow ctx) (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx (: "Row %d" :format row))
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx "Some contents")
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx :123.456))
        (ImGui.EndTable ctx))
      (demo.HelpMarker "Only using TableNextColumn(), which tends to be convenient for tables where every cell contains the same type of contents.
      This is also more similar to the old NextColumn() function of the Columns API, and provided to facilitate the Columns->Tables API transition.")
      (when (ImGui.BeginTable ctx :table3 3)
        (for [item 0 13] (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx (: "Item %d" :format item)))
        (ImGui.EndTable ctx))
      (ImGui.TreePop ctx))
    (Do-open-action)
    (when (ImGui.TreeNode ctx "Borders, background")
      (when (not tables.borders_bg)
        (set tables.borders_bg
             {:contents_type 0
              :display_headers false
              :flags (bor (ImGui.TableFlags_Borders) (ImGui.TableFlags_RowBg))}))
      (demo.PushStyleCompact)
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_RowBg
                                tables.borders_bg.flags (ImGui.TableFlags_RowBg)))
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Borders
                                tables.borders_bg.flags
                                (ImGui.TableFlags_Borders)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "ImGuiTableFlags_Borders
      = ImGuiTableFlags_BordersInnerV
      | ImGuiTableFlags_BordersOuterV
      | ImGuiTableFlags_BordersInnerV
      | ImGuiTableFlags_BordersOuterH")
      (ImGui.Indent ctx)
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersH
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersH)))
      (ImGui.Indent ctx)
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterH
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersOuterH)))
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerH
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersInnerH)))
      (ImGui.Unindent ctx)
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersV)))
      (ImGui.Indent ctx)
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersOuterV)))
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersInnerV)))
      (ImGui.Unindent ctx)
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuter
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersOuter)))
      (set (rv tables.borders_bg.flags)
           (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInner
                                tables.borders_bg.flags
                                (ImGui.TableFlags_BordersInner)))
      (ImGui.Unindent ctx)
      (ImGui.AlignTextToFramePadding ctx)
      (ImGui.Text ctx "Cell contents:")
      (ImGui.SameLine ctx)
      (set (rv tables.borders_bg.contents_type)
           (ImGui.RadioButtonEx ctx :Text tables.borders_bg.contents_type 0))
      (ImGui.SameLine ctx)
      (set (rv tables.borders_bg.contents_type)
           (ImGui.RadioButtonEx ctx :FillButton tables.borders_bg.contents_type
                                1))
      (set (rv tables.borders_bg.display_headers)
           (ImGui.Checkbox ctx "Display headers"
                           tables.borders_bg.display_headers))
      (demo.PopStyleCompact)
      (when (ImGui.BeginTable ctx :table1 3 tables.borders_bg.flags)
        (when tables.borders_bg.display_headers
          (ImGui.TableSetupColumn ctx :One)
          (ImGui.TableSetupColumn ctx :Two)
          (ImGui.TableSetupColumn ctx :Three)
          (ImGui.TableHeadersRow ctx))
        (for [row 0 4]
          (ImGui.TableNextRow ctx)
          (for [column 0 2]
            (ImGui.TableSetColumnIndex ctx column)
            (local buf (: "Hello %d,%d" :format column row))
            (if (= tables.borders_bg.contents_type 0) (ImGui.Text ctx buf)
              (= tables.borders_bg.contents_type 1) (ImGui.Button ctx buf
                                                                  (- FLT_MIN) 0))))
        (ImGui.EndTable ctx))
      (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Resizable, stretch")
  (when (not tables.resz_stretch)
    (set tables.resz_stretch
         {:flags (bor (ImGui.TableFlags_SizingStretchSame)
                      (ImGui.TableFlags_Resizable)
                      (ImGui.TableFlags_BordersOuter)
                      (ImGui.TableFlags_BordersV)
                      (ImGui.TableFlags_ContextMenuInBody))}))
  (demo.PushStyleCompact)
  (set (rv tables.resz_stretch.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.resz_stretch.flags
                            (ImGui.TableFlags_Resizable)))
  (set (rv tables.resz_stretch.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                            tables.resz_stretch.flags
                            (ImGui.TableFlags_BordersV)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Using the _Resizable flag automatically enables the _BordersInnerV flag as well, this is why the resize borders are still showing when unchecking this.")
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table1 3 tables.resz_stretch.flags)
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 2] (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "Hello %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Resizable, fixed")
  (when (not tables.resz_fixed)
    (set tables.resz_fixed
         {:flags (bor (ImGui.TableFlags_SizingFixedFit)
                      (ImGui.TableFlags_Resizable)
                      (ImGui.TableFlags_BordersOuter)
                      (ImGui.TableFlags_BordersV)
                      (ImGui.TableFlags_ContextMenuInBody))}))
  (demo.HelpMarker "Using _Resizable + _SizingFixedFit flags.
  Fixed-width columns generally makes more sense if you want to use horizontal scrolling.

  Double-click a column border to auto-fit the column to its contents.")
  (demo.PushStyleCompact)
  (set (rv tables.resz_fixed.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                            tables.resz_fixed.flags
                            (ImGui.TableFlags_NoHostExtendX)))
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table1 3 tables.resz_fixed.flags)
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 2] (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "Hello %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Resizable, mixed")
  (when (not tables.resz_mixed)
    (set tables.resz_mixed
         {:flags (bor (ImGui.TableFlags_SizingFixedFit)
                      (ImGui.TableFlags_RowBg)
                      (ImGui.TableFlags_Borders)
                      (ImGui.TableFlags_Resizable)
                      (ImGui.TableFlags_Reorderable)
                      (ImGui.TableFlags_Hideable))}))
  (demo.HelpMarker "Using TableSetupColumn() to alter resizing policy on a per-column basis.

  When combining Fixed and Stretch columns, generally you only want one, maybe two trailing columns to use _WidthStretch.")
  (when (ImGui.BeginTable ctx :table1 3 tables.resz_mixed.flags)
    (ImGui.TableSetupColumn ctx :AAA (ImGui.TableColumnFlags_WidthFixed))
    (ImGui.TableSetupColumn ctx :BBB (ImGui.TableColumnFlags_WidthFixed))
    (ImGui.TableSetupColumn ctx :CCC (ImGui.TableColumnFlags_WidthStretch))
    (ImGui.TableHeadersRow ctx)
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 2]
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx
                    (: "%s %d,%d" :format
                       (or (and (= column 2) :Stretch) :Fixed) column row))))
    (ImGui.EndTable ctx))
  (when (ImGui.BeginTable ctx :table2 6 tables.resz_mixed.flags)
    (ImGui.TableSetupColumn ctx :AAA (ImGui.TableColumnFlags_WidthFixed))
    (ImGui.TableSetupColumn ctx :BBB (ImGui.TableColumnFlags_WidthFixed))
    (ImGui.TableSetupColumn ctx :CCC
                            (bor (ImGui.TableColumnFlags_WidthFixed)
                                 (ImGui.TableColumnFlags_DefaultHide)))
    (ImGui.TableSetupColumn ctx :DDD (ImGui.TableColumnFlags_WidthStretch))
    (ImGui.TableSetupColumn ctx :EEE (ImGui.TableColumnFlags_WidthStretch))
    (ImGui.TableSetupColumn ctx :FFF
                            (bor (ImGui.TableColumnFlags_WidthStretch)
                                 (ImGui.TableColumnFlags_DefaultHide)))
    (ImGui.TableHeadersRow ctx)
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 5]
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "%s %d,%d" :format
                           (or (and (>= column 3) :Stretch) :Fixed) column
                           row))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Reorderable, hideable, with headers")
  (when (not tables.reorder)
    (set tables.reorder
         {:flags (bor (ImGui.TableFlags_Resizable)
                      (ImGui.TableFlags_Reorderable)
                      (ImGui.TableFlags_Hideable)
                      (ImGui.TableFlags_BordersOuter)
                      (ImGui.TableFlags_BordersV))}))
  (demo.HelpMarker "Click and drag column headers to reorder columns.

  Right-click on a header to open a context menu.")
  (demo.PushStyleCompact)
  (set (rv tables.reorder.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.reorder.flags
                            (ImGui.TableFlags_Resizable)))
  (set (rv tables.reorder.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Reorderable
                            tables.reorder.flags
                            (ImGui.TableFlags_Reorderable)))
  (set (rv tables.reorder.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Hideable
                            tables.reorder.flags (ImGui.TableFlags_Hideable)))
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table1 3 tables.reorder.flags)
    (ImGui.TableSetupColumn ctx :One)
    (ImGui.TableSetupColumn ctx :Two)
    (ImGui.TableSetupColumn ctx :Three)
    (ImGui.TableHeadersRow ctx)
    (for [row 0 5]
      (ImGui.TableNextRow ctx)
      (for [column 0 2] (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "Hello %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (when (ImGui.BeginTable ctx :table2 3
                          (bor tables.reorder.flags
                               (ImGui.TableFlags_SizingFixedFit))
                          0 0)
    (ImGui.TableSetupColumn ctx :One)
    (ImGui.TableSetupColumn ctx :Two)
    (ImGui.TableSetupColumn ctx :Three)
    (ImGui.TableHeadersRow ctx)
    (for [row 0 5]
      (ImGui.TableNextRow ctx)
      (for [column 0 2] (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "Fixed %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx :Padding)
  (when (not tables.padding)
    (set tables.padding {:cell_padding [0 0]
                         :flags1 (ImGui.TableFlags_BordersV)
                         :flags2 (bor (ImGui.TableFlags_Borders)
                                      (ImGui.TableFlags_RowBg))
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
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_PadOuterX
                            tables.padding.flags1
                            (ImGui.TableFlags_PadOuterX)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Enable outer-most padding (default if ImGuiTableFlags_BordersOuterV is set)")
  (set (rv tables.padding.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoPadOuterX
                            tables.padding.flags1
                            (ImGui.TableFlags_NoPadOuterX)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Disable outer-most padding (default if ImGuiTableFlags_BordersOuterV is not set)")
  (set (rv tables.padding.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoPadInnerX
                            tables.padding.flags1
                            (ImGui.TableFlags_NoPadInnerX)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off)")
  (set (rv tables.padding.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                            tables.padding.flags1
                            (ImGui.TableFlags_BordersOuterV)))
  (set (rv tables.padding.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                            tables.padding.flags1
                            (ImGui.TableFlags_BordersInnerV)))
  (set (rv tables.padding.show_headers)
       (ImGui.Checkbox ctx :show_headers tables.padding.show_headers))
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table_padding 3 tables.padding.flags1)
    (when tables.padding.show_headers (ImGui.TableSetupColumn ctx :One)
      (ImGui.TableSetupColumn ctx :Two)
      (ImGui.TableSetupColumn ctx :Three)
      (ImGui.TableHeadersRow ctx))
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 2]
        (ImGui.TableSetColumnIndex ctx column)
        (if (= row 0)
          (ImGui.Text ctx
                      (: "Avail %.2f" :format
                         (ImGui.GetContentRegionAvail ctx)))
          (let [buf (: "Hello %d,%d" :format column row)]
            (ImGui.Button ctx buf (- FLT_MIN) 0)))))
    (ImGui.EndTable ctx))
  (demo.HelpMarker "Setting style.CellPadding to (0,0) or a custom value.")
  (demo.PushStyleCompact)
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Borders
                            tables.padding.flags2 (ImGui.TableFlags_Borders)))
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersH
                            tables.padding.flags2
                            (ImGui.TableFlags_BordersH)))
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersV
                            tables.padding.flags2
                            (ImGui.TableFlags_BordersV)))
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInner
                            tables.padding.flags2
                            (ImGui.TableFlags_BordersInner)))
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuter
                            tables.padding.flags2
                            (ImGui.TableFlags_BordersOuter)))
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_RowBg tables.padding.flags2
                            (ImGui.TableFlags_RowBg)))
  (set (rv tables.padding.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.padding.flags2
                            (ImGui.TableFlags_Resizable)))
  (set (rv tables.padding.show_widget_frame_bg)
       (ImGui.Checkbox ctx :show_widget_frame_bg
                       tables.padding.show_widget_frame_bg))
  (set-forcibly! (rv cp1 cp2)
                 (ImGui.SliderDouble2 ctx :CellPadding
                                      (. tables.padding.cell_padding 1)
                                      (. tables.padding.cell_padding 2) 0 10
                                      "%.0f"))
(tset tables.padding.cell_padding 1 cp1)
(tset tables.padding.cell_padding 2 cp2)
(demo.PopStyleCompact)
(ImGui.PushStyleVar ctx (ImGui.StyleVar_CellPadding)
                    (table.unpack tables.padding.cell_padding))
(when (ImGui.BeginTable ctx :table_padding_2 3 tables.padding.flags2)
  (when (not tables.padding.show_widget_frame_bg)
    (ImGui.PushStyleColor ctx (ImGui.Col_FrameBg) 0))
  (for [cell 1 (* 3 5)]
    (ImGui.TableNextColumn ctx)
    (ImGui.SetNextItemWidth ctx (- FLT_MIN))
    (ImGui.PushID ctx cell)
    (set-forcibly! (rv tbc)
                   (ImGui.InputText ctx "##cell"
                                    (. tables.padding.text_bufs cell)))
    (tset tables.padding.text_bufs cell tbc)
    (ImGui.PopID ctx))
  (when (not tables.padding.show_widget_frame_bg)
    (ImGui.PopStyleColor ctx))
  (ImGui.EndTable ctx))
(ImGui.PopStyleVar ctx)
(ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Sizing policies")
  (when (not tables.sz_policies)
    (set tables.sz_policies {:column_count 3
                             :contents_type 0
                             :flags1 (bor (ImGui.TableFlags_BordersV)
                                          (ImGui.TableFlags_BordersOuterH)
                                          (ImGui.TableFlags_RowBg)
                                          (ImGui.TableFlags_ContextMenuInBody))
                             :flags2 (bor (ImGui.TableFlags_ScrollY)
                                          (ImGui.TableFlags_Borders)
                                          (ImGui.TableFlags_RowBg)
                                          (ImGui.TableFlags_Resizable))
                             :sizing_policy_flags [(ImGui.TableFlags_SizingFixedFit)
                                                   (ImGui.TableFlags_SizingFixedSame)
                                                   (ImGui.TableFlags_SizingStretchProp)
                                                   (ImGui.TableFlags_SizingStretchSame)]
                             :text_buf ""}))
  (demo.PushStyleCompact)
  (set (rv tables.sz_policies.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.sz_policies.flags1
                            (ImGui.TableFlags_Resizable)))
  (set (rv tables.sz_policies.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                            tables.sz_policies.flags1
                            (ImGui.TableFlags_NoHostExtendX)))
  (demo.PopStyleCompact)
  (each [table-n sizing-flags (ipairs tables.sz_policies.sizing_policy_flags)]
    (ImGui.PushID ctx table-n)
    (ImGui.SetNextItemWidth ctx (* TEXT_BASE_WIDTH 30))
    (set-forcibly! sizing-flags (demo.EditTableSizingFlags sizing-flags))
    (tset tables.sz_policies.sizing_policy_flags table-n sizing-flags)
    (when (ImGui.BeginTable ctx :table1 3
                            (bor sizing-flags tables.sz_policies.flags1))
      (for [row 0 2] (ImGui.TableNextRow ctx) (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx "Oh dear")
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx "Oh dear")
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx "Oh dear"))
      (ImGui.EndTable ctx))
    (when (ImGui.BeginTable ctx :table2 3
                            (bor sizing-flags tables.sz_policies.flags1))
      (for [row 0 2] (ImGui.TableNextRow ctx) (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx :AAAA)
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx :BBBBBBBB)
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx :CCCCCCCCCCCC))
      (ImGui.EndTable ctx))
    (ImGui.PopID ctx))
  (ImGui.Spacing ctx)
  (ImGui.Text ctx :Advanced)
  (ImGui.SameLine ctx)
  (demo.HelpMarker "This section allows you to interact and see the effect of various sizing policies depending on whether Scroll is enabled and the contents of your columns.")
  (demo.PushStyleCompact)
  (ImGui.PushID ctx :Advanced)
  (ImGui.PushItemWidth ctx (* TEXT_BASE_WIDTH 30))
  (set tables.sz_policies.flags2
       (demo.EditTableSizingFlags tables.sz_policies.flags2))
  (set (rv tables.sz_policies.contents_type)
       (ImGui.Combo ctx :Contents tables.sz_policies.contents_type
                    "Show width\000Short Text\000Long Text\000Button\000Fill Button\000InputText\000"))
  (when (= tables.sz_policies.contents_type 4) (ImGui.SameLine ctx)
    (demo.HelpMarker "Be mindful that using right-alignment (e.g. size.x = -FLT_MIN) creates a feedback loop where contents width can feed into auto-column width can feed into contents width."))
  (set (rv tables.sz_policies.column_count)
       (ImGui.DragInt ctx :Columns tables.sz_policies.column_count 0.1 1 64
                      "%d" (ImGui.SliderFlags_AlwaysClamp)))
  (set (rv tables.sz_policies.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.sz_policies.flags2
                            (ImGui.TableFlags_Resizable)))
  (set (rv tables.sz_policies.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_PreciseWidths
                            tables.sz_policies.flags2
                            (ImGui.TableFlags_PreciseWidths)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
  (set (rv tables.sz_policies.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                            tables.sz_policies.flags2
                            (ImGui.TableFlags_ScrollX)))
  (set (rv tables.sz_policies.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                            tables.sz_policies.flags2
                            (ImGui.TableFlags_ScrollY)))
  (set (rv tables.sz_policies.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoClip
                            tables.sz_policies.flags2
                            (ImGui.TableFlags_NoClip)))
  (ImGui.PopItemWidth ctx)
  (ImGui.PopID ctx)
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table2 tables.sz_policies.column_count
                          tables.sz_policies.flags2 0 (* TEXT_BASE_HEIGHT 7))
    (for [cell 1 (* 10 tables.sz_policies.column_count)]
      (ImGui.TableNextColumn ctx)
      (local column (ImGui.TableGetColumnIndex ctx))
      (local row (ImGui.TableGetRowIndex ctx))
      (ImGui.PushID ctx cell)
      (local label (: "Hello %d,%d" :format column row))
      (local contents-type tables.sz_policies.contents_type)
      (if (= contents-type 1) (ImGui.Text ctx label) (= contents-type 2)
        (ImGui.Text ctx (: "Some %s text %d,%d\nOver two lines.." :format
                           (or (and (= column 0) :long) :longeeer) column
                           row)) (= contents-type 0)
        (ImGui.Text ctx
                    (: "W: %.1f" :format
                       (ImGui.GetContentRegionAvail ctx)))
        (= contents-type 3) (ImGui.Button ctx label) (= contents-type 4)
        (ImGui.Button ctx label (- FLT_MIN) 0) (= contents-type 5)
        (do
          (ImGui.SetNextItemWidth ctx (- FLT_MIN))
          (set (rv tables.sz_policies.text_buf)
               (ImGui.InputText ctx "##" tables.sz_policies.text_buf))))
      (ImGui.PopID ctx))
    (ImGui.EndTable ctx))
(ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Vertical scrolling, with clipping")
  (when (not tables.vertical)
    (set tables.vertical
         {:flags (bor (ImGui.TableFlags_ScrollY)
                      (ImGui.TableFlags_RowBg)
                      (ImGui.TableFlags_BordersOuter)
                      (ImGui.TableFlags_BordersV)
                      (ImGui.TableFlags_Resizable)
                      (ImGui.TableFlags_Reorderable)
                      (ImGui.TableFlags_Hideable))}))
  (demo.HelpMarker "Here we activate ScrollY, which will create a child window container to allow hosting scrollable contents.

  We also demonstrate using ImGuiListClipper to virtualize the submission of many items.")
  (demo.PushStyleCompact)
  (set (rv tables.vertical.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                            tables.vertical.flags (ImGui.TableFlags_ScrollY)))
  (demo.PopStyleCompact)
  (local outer-size [0 (* TEXT_BASE_HEIGHT 8)])
  (when (ImGui.BeginTable ctx :table_scrolly 3 tables.vertical.flags
                          (table.unpack outer-size))
    (ImGui.TableSetupScrollFreeze ctx 0 1)
    (ImGui.TableSetupColumn ctx :One (ImGui.TableColumnFlags_None))
    (ImGui.TableSetupColumn ctx :Two (ImGui.TableColumnFlags_None))
    (ImGui.TableSetupColumn ctx :Three (ImGui.TableColumnFlags_None))
    (ImGui.TableHeadersRow ctx)
    (local clipper (ImGui.CreateListClipper ctx))
    (ImGui.ListClipper_Begin clipper 1000)
    (while (ImGui.ListClipper_Step clipper)
      (local (display-start display-end)
        (ImGui.ListClipper_GetDisplayRange clipper))
      (for [row display-start (- display-end 1)]
        (ImGui.TableNextRow ctx)
        (for [column 0 2] (ImGui.TableSetColumnIndex ctx column)
          (ImGui.Text ctx (: "Hello %d,%d" :format column row)))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Horizontal scrolling")
  (when (not tables.horizontal)
    (set tables.horizontal {:flags1 (bor (ImGui.TableFlags_ScrollX)
                                         (ImGui.TableFlags_ScrollY)
                                         (ImGui.TableFlags_RowBg)
                                         (ImGui.TableFlags_BordersOuter)
                                         (ImGui.TableFlags_BordersV)
                                         (ImGui.TableFlags_Resizable)
                                         (ImGui.TableFlags_Reorderable)
                                         (ImGui.TableFlags_Hideable))
                            :flags2 (bor (ImGui.TableFlags_SizingStretchSame)
                                         (ImGui.TableFlags_ScrollX)
                                         (ImGui.TableFlags_ScrollY)
                                         (ImGui.TableFlags_BordersOuter)
                                         (ImGui.TableFlags_RowBg)
                                         (ImGui.TableFlags_ContextMenuInBody))
                            :freeze_cols 1
                            :freeze_rows 1
                            :inner_width 1000}))
  (demo.HelpMarker "When ScrollX is enabled, the default sizing policy becomes ImGuiTableFlags_SizingFixedFit, as automatically stretching columns doesn't make much sense with horizontal scrolling.

  Also note that as of the current version, you will almost always want to enable ScrollY along with ScrollX,because the container window won't automatically extend vertically to fix contents (this may be improved in future versions).")
  (demo.PushStyleCompact)
  (set (rv tables.horizontal.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.horizontal.flags1
                            (ImGui.TableFlags_Resizable)))
  (set (rv tables.horizontal.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                            tables.horizontal.flags1
                            (ImGui.TableFlags_ScrollX)))
  (set (rv tables.horizontal.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY
                            tables.horizontal.flags1
                            (ImGui.TableFlags_ScrollY)))
  (ImGui.SetNextItemWidth ctx (ImGui.GetFrameHeight ctx))
  (set (rv tables.horizontal.freeze_cols)
       (ImGui.DragInt ctx :freeze_cols tables.horizontal.freeze_cols 0.2 0 9
                      nil (ImGui.SliderFlags_NoInput)))
  (ImGui.SetNextItemWidth ctx (ImGui.GetFrameHeight ctx))
  (set (rv tables.horizontal.freeze_rows)
       (ImGui.DragInt ctx :freeze_rows tables.horizontal.freeze_rows 0.2 0 9
                      nil (ImGui.SliderFlags_NoInput)))
  (demo.PopStyleCompact)
  (local outer-size [0 (* TEXT_BASE_HEIGHT 8)])
  (when (ImGui.BeginTable ctx :table_scrollx 7 tables.horizontal.flags1
                          (table.unpack outer-size))
    (ImGui.TableSetupScrollFreeze ctx tables.horizontal.freeze_cols
                                  tables.horizontal.freeze_rows)
    (ImGui.TableSetupColumn ctx "Line #" (ImGui.TableColumnFlags_NoHide))
    (ImGui.TableSetupColumn ctx :One)
    (ImGui.TableSetupColumn ctx :Two)
    (ImGui.TableSetupColumn ctx :Three)
    (ImGui.TableSetupColumn ctx :Four)
    (ImGui.TableSetupColumn ctx :Five)
    (ImGui.TableSetupColumn ctx :Six)
    (ImGui.TableHeadersRow ctx)
    (for [row 0 19]
      (ImGui.TableNextRow ctx)
      (for [column 0 6]
        (when (or (ImGui.TableSetColumnIndex ctx column) (= column 0))
          (if (= column 0) (ImGui.Text ctx (: "Line %d" :format row))
            (ImGui.Text ctx (: "Hello world %d,%d" :format column row))))))
    (ImGui.EndTable ctx))
  (ImGui.Spacing ctx)
  (ImGui.Text ctx "Stretch + ScrollX")
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Showcase using Stretch columns + ScrollX together: this is rather unusual and only makes sense when specifying an 'inner_width' for the table!
  Without an explicit value, inner_width is == outer_size.x and therefore using Stretch columns + ScrollX together doesn't make sense.")
  (demo.PushStyleCompact)
  (ImGui.PushID ctx :flags3)
  (ImGui.PushItemWidth ctx (* TEXT_BASE_WIDTH 30))
  (set (rv tables.horizontal.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX
                            tables.horizontal.flags2
                            (ImGui.TableFlags_ScrollX)))
  (set (rv tables.horizontal.inner_width)
       (ImGui.DragDouble ctx :inner_width tables.horizontal.inner_width 1 0
                         FLT_MAX "%.1f"))
  (ImGui.PopItemWidth ctx)
  (ImGui.PopID ctx)
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table2 7 tables.horizontal.flags2
                          (. outer-size 1) (. outer-size 2)
                          tables.horizontal.inner_width)
    (for [cell 1 (* 20 7)]
      (ImGui.TableNextColumn ctx)
      (ImGui.Text ctx
                  (: "Hello world %d,%d" :format
                     (ImGui.TableGetColumnIndex ctx)
                     (ImGui.TableGetRowIndex ctx))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Columns flags")
  (when (not tables.col_flags)
    (set tables.col_flags
         {:columns [{:flags (ImGui.TableColumnFlags_DefaultSort)
                     :flags_out 0
                     :name :One}
                    {:flags (ImGui.TableColumnFlags_None)
                     :flags_out 0
                     :name :Two}
                    {:flags (ImGui.TableColumnFlags_DefaultHide)
                     :flags_out 0
                     :name :Three}]}))
  (when (ImGui.BeginTable ctx :table_columns_flags_checkboxes
                          (length tables.col_flags.columns)
                          (ImGui.TableFlags_None))
    (demo.PushStyleCompact)
    (each [i column (ipairs tables.col_flags.columns)]
      (ImGui.TableNextColumn ctx)
      (ImGui.PushID ctx i)
      (ImGui.AlignTextToFramePadding ctx)
      (ImGui.Text ctx (: "'%s'" :format column.name))
      (ImGui.Spacing ctx)
      (ImGui.Text ctx "Input flags:")
      (set column.flags (demo.EditTableColumnsFlags column.flags))
      (ImGui.Spacing ctx)
      (ImGui.Text ctx "Output flags:")
      (ImGui.BeginDisabled ctx)
      (demo.ShowTableColumnsStatusFlags column.flags_out)
      (ImGui.EndDisabled ctx)
      (ImGui.PopID ctx))
    (demo.PopStyleCompact)
    (ImGui.EndTable ctx))
  (local flags (bor (ImGui.TableFlags_SizingFixedFit)
                    (ImGui.TableFlags_ScrollX)
                    (ImGui.TableFlags_ScrollY)
                    (ImGui.TableFlags_RowBg)
                    (ImGui.TableFlags_BordersOuter)
                    (ImGui.TableFlags_BordersV)
                    (ImGui.TableFlags_Resizable)
                    (ImGui.TableFlags_Reorderable)
                    (ImGui.TableFlags_Hideable)))
  (local outer-size [0 (* TEXT_BASE_HEIGHT 9)])
  (when (ImGui.BeginTable ctx :table_columns_flags
                          (length tables.col_flags.columns) flags
                          (table.unpack outer-size))
    (each [i column (ipairs tables.col_flags.columns)]
      (ImGui.TableSetupColumn ctx column.name column.flags))
    (ImGui.TableHeadersRow ctx)
    (each [i column (ipairs tables.col_flags.columns)]
      (set column.flags_out (ImGui.TableGetColumnFlags ctx (- i 1))))
    (local indent-step (/ TEXT_BASE_WIDTH 2))
    (for [row 0 7]
      (ImGui.Indent ctx indent-step)
      (ImGui.TableNextRow ctx)
      (for [column 0 (- (length tables.col_flags.columns) 1)]
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx
                    (: "%s %s" :format
                       (or (and (= column 0) :Indented) :Hello)
                       (ImGui.TableGetColumnName ctx column)))))
    (ImGui.Unindent ctx (* indent-step 8))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Columns widths")
  (when (not tables.col_widths)
    (set tables.col_widths
         {:flags1 (ImGui.TableFlags_Borders)
          :flags2 (ImGui.TableFlags_None)}))
  (demo.HelpMarker "Using TableSetupColumn() to setup default width.")
  (demo.PushStyleCompact)
  (set (rv tables.col_widths.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable
                            tables.col_widths.flags1
                            (ImGui.TableFlags_Resizable)))
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table1 3 tables.col_widths.flags1)
    (ImGui.TableSetupColumn ctx :one (ImGui.TableColumnFlags_WidthFixed)
                            100)
    (ImGui.TableSetupColumn ctx :two (ImGui.TableColumnFlags_WidthFixed)
                            200)
    (ImGui.TableSetupColumn ctx :three (ImGui.TableColumnFlags_WidthFixed))
    (ImGui.TableHeadersRow ctx)
    (for [row 0 3]
      (ImGui.TableNextRow ctx)
      (for [column 0 2]
        (ImGui.TableSetColumnIndex ctx column)
        (if (= row 0)
          (ImGui.Text ctx
                      (: "(w: %5.1f)" :format
                         (ImGui.GetContentRegionAvail ctx)))
          (ImGui.Text ctx (: "Hello %d,%d" :format column row)))))
    (ImGui.EndTable ctx))
  (demo.HelpMarker "Using TableSetupColumn() to setup explicit width.

  Unless _NoKeepColumnsVisible is set, fixed columns with set width may still be shrunk down if there's not enough space in the host.")
  (demo.PushStyleCompact)
  (set (rv tables.col_widths.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoKeepColumnsVisible
                            tables.col_widths.flags2
                            (ImGui.TableFlags_NoKeepColumnsVisible)))
  (set (rv tables.col_widths.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV
                            tables.col_widths.flags2
                            (ImGui.TableFlags_BordersInnerV)))
  (set (rv tables.col_widths.flags2)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV
                            tables.col_widths.flags2
                            (ImGui.TableFlags_BordersOuterV)))
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table2 4 tables.col_widths.flags2)
    (ImGui.TableSetupColumn ctx "" (ImGui.TableColumnFlags_WidthFixed) 100)
    (ImGui.TableSetupColumn ctx "" (ImGui.TableColumnFlags_WidthFixed)
                            (* TEXT_BASE_WIDTH 15))
    (ImGui.TableSetupColumn ctx "" (ImGui.TableColumnFlags_WidthFixed)
                            (* TEXT_BASE_WIDTH 30))
    (ImGui.TableSetupColumn ctx "" (ImGui.TableColumnFlags_WidthFixed)
                            (* TEXT_BASE_WIDTH 15))
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 3]
        (ImGui.TableSetColumnIndex ctx column)
        (if (= row 0)
          (ImGui.Text ctx
                      (: "(w: %5.1f)" :format
                         (ImGui.GetContentRegionAvail ctx)))
          (ImGui.Text ctx (: "Hello %d,%d" :format column row)))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Nested tables")
  (demo.HelpMarker "This demonstrates embedding a table into another table cell.")
  (local flags (bor (ImGui.TableFlags_Borders)
                    (ImGui.TableFlags_Resizable)
                    (ImGui.TableFlags_Reorderable)
                    (ImGui.TableFlags_Hideable)))
  (when (ImGui.BeginTable ctx :table_nested1 2 flags)
    (ImGui.TableSetupColumn ctx :A0)
    (ImGui.TableSetupColumn ctx :A1)
    (ImGui.TableHeadersRow ctx)
    (ImGui.TableNextColumn ctx)
    (ImGui.Text ctx "A0 Row 0")
    (local rows-height (* TEXT_BASE_HEIGHT 2))
    (when (ImGui.BeginTable ctx :table_nested2 2 flags)
      (ImGui.TableSetupColumn ctx :B0)
      (ImGui.TableSetupColumn ctx :B1)
      (ImGui.TableHeadersRow ctx)
      (ImGui.TableNextRow ctx (ImGui.TableRowFlags_None) rows-height)
      (ImGui.TableNextColumn ctx)
      (ImGui.Text ctx "B0 Row 0")
      (ImGui.TableNextColumn ctx)
      (ImGui.Text ctx "B0 Row 1")
      (ImGui.TableNextRow ctx (ImGui.TableRowFlags_None) rows-height)
      (ImGui.TableNextColumn ctx)
      (ImGui.Text ctx "B1 Row 0")
      (ImGui.TableNextColumn ctx)
      (ImGui.Text ctx "B1 Row 1")
      (ImGui.EndTable ctx))
    (ImGui.TableNextColumn ctx)
    (ImGui.Text ctx "A0 Row 1")
    (ImGui.TableNextColumn ctx)
    (ImGui.Text ctx "A1 Row 0")
    (ImGui.TableNextColumn ctx)
    (ImGui.Text ctx "A1 Row 1")
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Row height")
  (demo.HelpMarker "You can pass a 'min_row_height' to TableNextRow().

  Rows are padded with 'ImGui_StyleVar_CellPadding.y' on top and bottom, so effectively the minimum row height will always be >= 'ImGui_StyleVar_CellPadding.y * 2.0'.

  We cannot honor a _maximum_ row height as that would require a unique clipping rectangle per row.")
  (when (ImGui.BeginTable ctx :table_row_height 1
                          (bor (ImGui.TableFlags_BordersOuter)
                               (ImGui.TableFlags_BordersInnerV)))
    (for [row 0 9]
      (local min-row-height (* (* TEXT_BASE_HEIGHT 0.3) row))
      (ImGui.TableNextRow ctx (ImGui.TableRowFlags_None) min-row-height)
      (ImGui.TableNextColumn ctx)
      (ImGui.Text ctx (: "min_row_height = %.2f" :format min-row-height)))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Outer size")
  (when (not tables.outer_sz)
    (set tables.outer_sz
         {:flags (bor (ImGui.TableFlags_Borders)
                      (ImGui.TableFlags_Resizable)
                      (ImGui.TableFlags_ContextMenuInBody)
                      (ImGui.TableFlags_RowBg)
                      (ImGui.TableFlags_SizingFixedFit)
                      (ImGui.TableFlags_NoHostExtendX))}))
  (ImGui.Text ctx "Using NoHostExtendX and NoHostExtendY:")
  (demo.PushStyleCompact)
  (set (rv tables.outer_sz.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX
                            tables.outer_sz.flags
                            (ImGui.TableFlags_NoHostExtendX)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Make outer width auto-fit to columns, overriding outer_size.x value.

  Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
  (set (rv tables.outer_sz.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendY
                            tables.outer_sz.flags
                            (ImGui.TableFlags_NoHostExtendY)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).

  Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
  (demo.PopStyleCompact)
  (local outer-size [0 (* TEXT_BASE_HEIGHT 5.5)])
  (when (ImGui.BeginTable ctx :table1 3 tables.outer_sz.flags
                          (table.unpack outer-size))
    (for [row 0 9]
      (ImGui.TableNextRow ctx)
      (for [column 0 2] (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx (: "Cell %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (ImGui.SameLine ctx)
  (ImGui.Text ctx :Hello!)
  (ImGui.Spacing ctx)
  (local flags (bor (ImGui.TableFlags_Borders) (ImGui.TableFlags_RowBg)))
  (ImGui.Text ctx "Using explicit size:")
  (when (ImGui.BeginTable ctx :table2 3 flags (* TEXT_BASE_WIDTH 30) 0)
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 2] (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx (: "Cell %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (ImGui.SameLine ctx)
  (when (ImGui.BeginTable ctx :table3 3 flags (* TEXT_BASE_WIDTH 30) 0)
    (for [row 0 2]
      (ImGui.TableNextRow ctx 0 (* TEXT_BASE_HEIGHT 1.5))
      (for [column 0 2] (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx (: "Cell %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Background color")
  (when (not tables.bg_col)
    (set tables.bg_col {:cell_bg_type 1
                        :flags (ImGui.TableFlags_RowBg)
                        :row_bg_target 1
                        :row_bg_type 1}))
  (demo.PushStyleCompact)
  (set (rv tables.bg_col.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Borders tables.bg_col.flags
                            (ImGui.TableFlags_Borders)))
  (set (rv tables.bg_col.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_RowBg tables.bg_col.flags
                            (ImGui.TableFlags_RowBg)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "ImGuiTableFlags_RowBg automatically sets RowBg0 to alternative colors pulled from the Style.")
  (set (rv tables.bg_col.row_bg_type)
       (ImGui.Combo ctx "row bg type" tables.bg_col.row_bg_type
                    "None\000Red\000Gradient\000"))
  (set (rv tables.bg_col.row_bg_target)
       (ImGui.Combo ctx "row bg target" tables.bg_col.row_bg_target
                    "RowBg0\000RowBg1\000"))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Target RowBg0 to override the alternating odd/even colors,
  Target RowBg1 to blend with them.")
  (set (rv tables.bg_col.cell_bg_type)
       (ImGui.Combo ctx "cell bg type" tables.bg_col.cell_bg_type
                    "None\000Blue\000"))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "We are colorizing cells to B1->C2 here.")
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table1 5 tables.bg_col.flags)
    (for [row 0 5]
      (ImGui.TableNextRow ctx)
      (when (not= tables.bg_col.row_bg_type 0)
        (var row-bg-color nil)
        (if (= tables.bg_col.row_bg_type 1) (set row-bg-color 3008187814)
          (do
            (set row-bg-color 858993574)
            (set row-bg-color
                 (+ row-bg-color
                    (lshift (demo.round (* (* row 0.1) 255)) 24)))))
        (ImGui.TableSetBgColor ctx
                               (+ (ImGui.TableBgTarget_RowBg0)
                                  tables.bg_col.row_bg_target)
                               row-bg-color))
      (for [column 0 4]
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx
                    (: "%c%c" :format (+ (string.byte :A) row)
                       (+ (string.byte :0) column)))
        (when (and (and (and (and (>= row 1) (<= row 2)) (>= column 1))
                        (<= column 2))
                   (= tables.bg_col.cell_bg_type 1))
          (ImGui.TableSetBgColor ctx (ImGui.TableBgTarget_CellBg)
                                 1296937894))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Tree view")
  (local flags (bor (ImGui.TableFlags_BordersV)
                    (ImGui.TableFlags_BordersOuterH)
                    (ImGui.TableFlags_Resizable)
                    (ImGui.TableFlags_RowBg)))
  (when (ImGui.BeginTable ctx :3ways 3 flags)
    (ImGui.TableSetupColumn ctx :Name (ImGui.TableColumnFlags_NoHide))
    (ImGui.TableSetupColumn ctx :Size (ImGui.TableColumnFlags_WidthFixed)
                            (* TEXT_BASE_WIDTH 12))
    (ImGui.TableSetupColumn ctx :Type (ImGui.TableColumnFlags_WidthFixed)
                            (* TEXT_BASE_WIDTH 18))
    (ImGui.TableHeadersRow ctx)
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
      (ImGui.TableNextRow ctx)
      (ImGui.TableNextColumn ctx)
      (local is-folder (> node.child_count 0))
      (if is-folder (let [open (ImGui.TreeNode ctx node.name
                                               (ImGui.TreeNodeFlags_SpanFullWidth))]
                      (ImGui.TableNextColumn ctx)
                      (ImGui.TextDisabled ctx "--")
                      (ImGui.TableNextColumn ctx)
                      (ImGui.Text ctx node.type)
                      (when open
                        (for [child-n 1 node.child_count]
                          (Display-node (. nodes (+ node.child_idx child-n))))
                        (ImGui.TreePop ctx)))
        (do
          (ImGui.TreeNode ctx node.name
                          (bor (ImGui.TreeNodeFlags_Leaf)
                               (ImGui.TreeNodeFlags_Bullet)
                               (ImGui.TreeNodeFlags_NoTreePushOnOpen)
                               (ImGui.TreeNodeFlags_SpanFullWidth)))
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx (: "%d" :format node.size))
          (ImGui.TableNextColumn ctx)
          (ImGui.Text ctx node.type))))

    (Display-node (. nodes 1))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Item width")
  (when (not tables.item_width) (set tables.item_width {:dummy_d 0}))
  (demo.HelpMarker "Showcase using PushItemWidth() and how it is preserved on a per-column basis.

  Note that on auto-resizing non-resizable fixed columns, querying the content width for e.g. right-alignment doesn't make sense.")
  (when (ImGui.BeginTable ctx :table_item_width 3
                          (ImGui.TableFlags_Borders))
    (ImGui.TableSetupColumn ctx :small)
    (ImGui.TableSetupColumn ctx :half)
    (ImGui.TableSetupColumn ctx :right-align)
    (ImGui.TableHeadersRow ctx)
    (for [row 0 2]
      (ImGui.TableNextRow ctx)
      (when (= row 0)
        (ImGui.TableSetColumnIndex ctx 0)
        (ImGui.PushItemWidth ctx (* TEXT_BASE_WIDTH 3))
        (ImGui.TableSetColumnIndex ctx 1)
        (ImGui.PushItemWidth ctx
                             (- 0 (* (ImGui.GetContentRegionAvail ctx) 0.5)))
        (ImGui.TableSetColumnIndex ctx 2)
        (ImGui.PushItemWidth ctx (- FLT_MIN)))
      (ImGui.PushID ctx row)
      (ImGui.TableSetColumnIndex ctx 0)
      (set (rv tables.item_width.dummy_d)
           (ImGui.SliderDouble ctx :double0 tables.item_width.dummy_d 0 1))
      (ImGui.TableSetColumnIndex ctx 1)
      (set (rv tables.item_width.dummy_d)
           (ImGui.SliderDouble ctx :double1 tables.item_width.dummy_d 0 1))
      (ImGui.TableSetColumnIndex ctx 2)
      (set (rv tables.item_width.dummy_d)
           (ImGui.SliderDouble ctx "##double2" tables.item_width.dummy_d 0 1))
      (ImGui.PopID ctx))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Custom headers")
  (when (not tables.headers)
    (set tables.headers {:column_selected [false false false]}))
  (local COLUMNS_COUNT 3)
  (when (ImGui.BeginTable ctx :table_custom_headers COLUMNS_COUNT
                          (bor (ImGui.TableFlags_Borders)
                               (ImGui.TableFlags_Reorderable)
                               (ImGui.TableFlags_Hideable)))
    (ImGui.TableSetupColumn ctx :Apricot)
    (ImGui.TableSetupColumn ctx :Banana)
    (ImGui.TableSetupColumn ctx :Cherry)
    (ImGui.TableNextRow ctx (ImGui.TableRowFlags_Headers))
    (for [column 0 (- COLUMNS_COUNT 1)]
      (ImGui.TableSetColumnIndex ctx column)
      (local column-name (ImGui.TableGetColumnName ctx column))
      (ImGui.PushID ctx column)
      (ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) 0 0)
      (set-forcibly! (rv cs1)
                     (ImGui.Checkbox ctx "##checkall"
                                     (. tables.headers.column_selected
                                        (+ column 1))))
      (tset tables.headers.column_selected (+ column 1) cs1)
      (ImGui.PopStyleVar ctx)
      (ImGui.SameLine ctx 0
                      (ImGui.GetStyleVar ctx
                                         (ImGui.StyleVar_ItemInnerSpacing)))
      (ImGui.TableHeader ctx column-name)
      (ImGui.PopID ctx))
    (for [row 0 4]
      (ImGui.TableNextRow ctx)
      (for [column 0 2]
        (local buf (: "Cell %d,%d" :format column row))
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Selectable ctx buf
                          (. tables.headers.column_selected (+ column 1)))))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Context menus")
  (when (not tables.ctx_menus)
    (set tables.ctx_menus
         {:flags1 (bor (ImGui.TableFlags_Resizable)
                       (ImGui.TableFlags_Reorderable)
                       (ImGui.TableFlags_Hideable)
                       (ImGui.TableFlags_Borders)
                       (ImGui.TableFlags_ContextMenuInBody))}))
  (demo.HelpMarker "By default, right-clicking over a TableHeadersRow()/TableHeader() line will open the default context-menu.
  Using ImGuiTableFlags_ContextMenuInBody we also allow right-clicking over columns body.")
  (demo.PushStyleCompact)
  (set (rv tables.ctx_menus.flags1)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ContextMenuInBody
                            tables.ctx_menus.flags1
                            (ImGui.TableFlags_ContextMenuInBody)))
  (demo.PopStyleCompact)
  (local COLUMNS_COUNT 3)
  (when (ImGui.BeginTable ctx :table_context_menu COLUMNS_COUNT
                          tables.ctx_menus.flags1)
    (ImGui.TableSetupColumn ctx :One)
    (ImGui.TableSetupColumn ctx :Two)
    (ImGui.TableSetupColumn ctx :Three)
    (ImGui.TableHeadersRow ctx)
    (for [row 0 3]
      (ImGui.TableNextRow ctx)
      (for [column 0 (- COLUMNS_COUNT 1)]
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "Cell %d,%d" :format column row))))
    (ImGui.EndTable ctx))
  (demo.HelpMarker "Demonstrate mixing table context menu (over header), item context button (over button) and custom per-colum context menu (over column body).")
  (local flags2 (bor (ImGui.TableFlags_Resizable)
                     (ImGui.TableFlags_SizingFixedFit)
                     (ImGui.TableFlags_Reorderable)
                     (ImGui.TableFlags_Hideable)
                     (ImGui.TableFlags_Borders)))
  (when (ImGui.BeginTable ctx :table_context_menu_2 COLUMNS_COUNT flags2)
    (ImGui.TableSetupColumn ctx :One)
    (ImGui.TableSetupColumn ctx :Two)
    (ImGui.TableSetupColumn ctx :Three)
    (ImGui.TableHeadersRow ctx)
    (for [row 0 3]
      (ImGui.TableNextRow ctx)
      (for [column 0 (- COLUMNS_COUNT 1)]
        (ImGui.TableSetColumnIndex ctx column)
        (ImGui.Text ctx (: "Cell %d,%d" :format column row))
        (ImGui.SameLine ctx)
        (ImGui.PushID ctx (+ (* row COLUMNS_COUNT) column))
        (ImGui.SmallButton ctx "..")
        (when (ImGui.BeginPopupContextItem ctx)
          (ImGui.Text ctx
                      (: "This is the popup for Button(\"..\") in Cell %d,%d"
                         :format column row))
          (when (ImGui.Button ctx :Close) (ImGui.CloseCurrentPopup ctx))
          (ImGui.EndPopup ctx))
        (ImGui.PopID ctx)))
    (var hovered-column (- 1))
    (for [column 0 COLUMNS_COUNT]
      (ImGui.PushID ctx column)
      (when (not= (band (ImGui.TableGetColumnFlags ctx column)
                        (ImGui.TableColumnFlags_IsHovered))
                  0)
        (set hovered-column column))
      (when (and (and (= hovered-column column)
                      (not (ImGui.IsAnyItemHovered ctx)))
                 (ImGui.IsMouseReleased ctx 1))
        (ImGui.OpenPopup ctx :MyPopup))
      (when (ImGui.BeginPopup ctx :MyPopup)
        (if (= column COLUMNS_COUNT)
          (ImGui.Text ctx
                      "This is a custom popup for unused space after the last column.")
          (ImGui.Text ctx
                      (: "This is a custom popup for Column %d" :format
                         column)))
        (when (ImGui.Button ctx :Close) (ImGui.CloseCurrentPopup ctx))
        (ImGui.EndPopup ctx))
      (ImGui.PopID ctx))
    (ImGui.EndTable ctx)
    (ImGui.Text ctx (: "Hovered column: %d" :format hovered-column)))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx "Synced instances")
  (set-when-not tables.synced
                {:flags (bor (ImGui.TableFlags_Resizable)
                             (ImGui.TableFlags_Reorderable)
                             (ImGui.TableFlags_Hideable)
                             (ImGui.TableFlags_Borders)
                             (ImGui.TableFlags_SizingFixedFit)
                             (ImGui.TableFlags_NoSavedSettings))})
  (demo.HelpMarker "Multiple tables with the same identifier will share their settings, width, visibility, order etc.")
  (update-2nd tables.synced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY $ (ImGui.TableFlags_ScrollY)))
  (update-2nd tables.synced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_SizingFixedFit $ (ImGui.TableFlags_SizingFixedFit)))
  (for [n 0 2]
    (local buf (: "Synced Table %d" :format n))
    (local open
      (ImGui.CollapsingHeader ctx buf nil
                              (ImGui.TreeNodeFlags_DefaultOpen)))
    (when (and open (ImGui.BeginTable ctx :Table 3 tables.synced.flags 0
                                      (* (ImGui.GetTextLineHeightWithSpacing ctx)
                                         5)))
      (ImGui.TableSetupColumn ctx :One)
      (ImGui.TableSetupColumn ctx :Two)
      (ImGui.TableSetupColumn ctx :Three)
      (ImGui.TableHeadersRow ctx)
      (local cell-count (or (and (= n 1) 27) 9))
      (for [cell 0 cell-count] (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx (: "this cell %d" :format cell)))
      (ImGui.EndTable ctx)))
  (ImGui.TreePop ctx))
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
(when (ImGui.TreeNode ctx :Sorting)
  (when (not tables.sorting)
    (set tables.sorting {:flags (bor (ImGui.TableFlags_Resizable)
                                     (ImGui.TableFlags_Reorderable)
                                     (ImGui.TableFlags_Hideable)
                                     (ImGui.TableFlags_Sortable)
                                     (ImGui.TableFlags_SortMulti)
                                     (ImGui.TableFlags_RowBg)
                                     (ImGui.TableFlags_BordersOuter)
                                     (ImGui.TableFlags_BordersV)
                                     (ImGui.TableFlags_ScrollY))
                         :items {}})
    (for [n 0 49]
      (local template-n (% n (length template-items-names)))
      (local item {:id n
                   :name (. template-items-names (+ template-n 1))
                   :quantity (% (- (* n n) n) 20)})
      (table.insert tables.sorting.items item)))
  (demo.PushStyleCompact)
  (set (rv tables.sorting.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_SortMulti
                            tables.sorting.flags
                            (ImGui.TableFlags_SortMulti)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
  (set (rv tables.sorting.flags)
       (ImGui.CheckboxFlags ctx :ImGuiTableFlags_SortTristate
                            tables.sorting.flags
                            (ImGui.TableFlags_SortTristate)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
  (demo.PopStyleCompact)
  (when (ImGui.BeginTable ctx :table_sorting 4 tables.sorting.flags 0
                          (* TEXT_BASE_HEIGHT 15) 0)
    (ImGui.TableSetupColumn ctx :ID
                            (bor (ImGui.TableColumnFlags_DefaultSort)
                                 (ImGui.TableColumnFlags_WidthFixed))
                            0 My-item-column-iD_ID)
    (ImGui.TableSetupColumn ctx :Name (ImGui.TableColumnFlags_WidthFixed) 0
                            My-item-column-iD_Name)
    (ImGui.TableSetupColumn ctx :Action
                            (bor (ImGui.TableColumnFlags_NoSort)
                                 (ImGui.TableColumnFlags_WidthFixed))
                            0 My-item-column-iD_Action)
    (ImGui.TableSetupColumn ctx :Quantity
                            (bor (ImGui.TableColumnFlags_PreferSortDescending)
                                 (ImGui.TableColumnFlags_WidthStretch))
                            0 My-item-column-iD_Quantity)
    (ImGui.TableSetupScrollFreeze ctx 0 1)
    (ImGui.TableHeadersRow ctx)
    (when (ImGui.TableNeedSort ctx)
      (table.sort tables.sorting.items demo.CompareTableItems))
    (local clipper (ImGui.CreateListClipper ctx))
    (ImGui.ListClipper_Begin clipper (length tables.sorting.items))
    (while (ImGui.ListClipper_Step clipper)
      (local (display-start display-end)
        (ImGui.ListClipper_GetDisplayRange clipper))
      (for [row-n display-start (- display-end 1)]
        (local item (. tables.sorting.items (+ row-n 1)))
        (ImGui.PushID ctx item.id)
        (ImGui.TableNextRow ctx)
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx (: "%04d" :format item.id))
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx item.name)
        (ImGui.TableNextColumn ctx)
        (ImGui.SmallButton ctx :None)
        (ImGui.TableNextColumn ctx)
        (ImGui.Text ctx (: "%d" :format item.quantity))
        (ImGui.PopID ctx)))
    (ImGui.EndTable ctx))
  (ImGui.TreePop ctx))
(Do-open-action)
(when (ImGui.TreeNode ctx :Advanced)
  (set-when-not tables.advanced
                {:contents_type 5
                 :flags (bor (ImGui.TableFlags_Resizable)
                             (ImGui.TableFlags_Reorderable)
                             (ImGui.TableFlags_Hideable)
                             (ImGui.TableFlags_Sortable)
                             (ImGui.TableFlags_SortMulti)
                             (ImGui.TableFlags_RowBg)
                             (ImGui.TableFlags_Borders)
                             (ImGui.TableFlags_ScrollX)
                             (ImGui.TableFlags_ScrollY)
                             (ImGui.TableFlags_SizingFixedFit))
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
                 :show_wrapped_text false})
  (when (ImGui.TreeNode ctx :Options)
    (demo.PushStyleCompact)
    (ImGui.PushItemWidth ctx (* TEXT_BASE_WIDTH 28))
    (when (ImGui.TreeNode ctx "Features:" (ImGui.TreeNodeFlags_DefaultOpen))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Resizable $ (ImGui.TableFlags_Resizable)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Reorderable $ (ImGui.TableFlags_Reorderable)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Hideable $ (ImGui.TableFlags_Hideable)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_Sortable $ (ImGui.TableFlags_Sortable)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoSavedSettings $ (ImGui.TableFlags_NoSavedSettings)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ContextMenuInBody $ (ImGui.TableFlags_ContextMenuInBody)))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Decorations:"
                          (ImGui.TreeNodeFlags_DefaultOpen))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_RowBg $ (ImGui.TableFlags_RowBg)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersV $ (ImGui.TableFlags_BordersV)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterV $ (ImGui.TableFlags_BordersOuterV)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerV $ (ImGui.TableFlags_BordersInnerV)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersH $ (ImGui.TableFlags_BordersH)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersOuterH $ (ImGui.TableFlags_BordersOuterH)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_BordersInnerH $ (ImGui.TableFlags_BordersInnerH)))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Sizing:" (ImGui.TreeNodeFlags_DefaultOpen))
      (set tables.advanced.flags
           (demo.EditTableSizingFlags tables.advanced.flags))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "In the Advanced demo we override the policy of each column so those table-wide settings have less effect that typical.")
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendX $ (ImGui.TableFlags_NoHostExtendX)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Make outer width auto-fit to columns, overriding outer_size.x value.

      Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.")
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoHostExtendY $ (ImGui.TableFlags_NoHostExtendY)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit).

      Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.")
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoKeepColumnsVisible $ (ImGui.TableFlags_NoKeepColumnsVisible)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Only available if ScrollX is disabled.")
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_PreciseWidths $ (ImGui.TableFlags_PreciseWidths)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.")
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoClip $ (ImGui.TableFlags_NoClip)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ScrollFreeze options.")
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Padding:" (ImGui.TreeNodeFlags_DefaultOpen))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_PadOuterX $ (ImGui.TableFlags_PadOuterX)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoPadOuterX $ (ImGui.TableFlags_NoPadOuterX)))
      (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_NoPadInnerX $ (ImGui.TableFlags_NoPadInnerX)))
      (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Scrolling:"
                      (ImGui.TreeNodeFlags_DefaultOpen))
  (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollX $ (ImGui.TableFlags_ScrollX)))
  (ImGui.SameLine ctx)
  (ImGui.SetNextItemWidth ctx (ImGui.GetFrameHeight ctx))
  (update-2nd tables.advanced.freeze_cols (ImGui.DragInt ctx :freeze_cols $ 0.2 0 9 nil (ImGui.SliderFlags_NoInput)))
  (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_ScrollY $ (ImGui.TableFlags_ScrollY)))
  (ImGui.SameLine ctx)
  (ImGui.SetNextItemWidth ctx (ImGui.GetFrameHeight ctx))
  (set (rv tables.advanced.freeze_rows)
       (ImGui.DragInt ctx :freeze_rows tables.advanced.freeze_rows 0.2 0
                      9 nil (ImGui.SliderFlags_NoInput)))
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Sorting:" (ImGui.TreeNodeFlags_DefaultOpen))
  (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_SortMulti $ (ImGui.TableFlags_SortMulti)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "When sorting is enabled: hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).")
  (update-2nd tables.advanced.flags (ImGui.CheckboxFlags ctx :ImGuiTableFlags_SortTristate $ (ImGui.TableFlags_SortTristate)))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "When sorting is enabled: allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).")
  (ImGui.TreePop ctx))
(when (ImGui.TreeNode ctx "Other:" (ImGui.TreeNodeFlags_DefaultOpen))
  (update-2nd tables.advanced.show_headers (ImGui.Checkbox ctx :show_headers $))
  (update-2nd tables.advanced.show_wrapped_text (ImGui.Checkbox ctx :show_wrapped_text $))
  (set-forcibly! (rv osv1 osv2)
                 (ImGui.DragDouble2 ctx "##OuterSize"
                                    (table.unpack tables.advanced.outer_size_value)))
  (tset tables.advanced.outer_size_value 1 osv1)
  (tset tables.advanced.outer_size_value 2 osv2)
  (ImGui.SameLine ctx 0
                  (ImGui.GetStyleVar ctx
                                     (ImGui.StyleVar_ItemInnerSpacing)))
  (update-2nd tables.advanced.outer_size_enabled (ImGui.Checkbox ctx :outer_size $))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "If scrolling is disabled (ScrollX and ScrollY not set):
  - The table is output directly in the parent window.
  - OuterSize.x < 0.0 will right-align the table.
  - OuterSize.x = 0.0 will narrow fit the table unless there are any Stretch columns.
  - OuterSize.y then becomes the minimum size for the table, which will extend vertically if there are more rows (unless NoHostExtendY is set).")
  (update-2nd tables.advanced.inner_width_with_scroll (ImGui.DragDouble ctx "inner_width (when ScrollX active)" $ 1 0 FLT_MAX))
  (update-2nd tables.advanced.row_min_height (ImGui.DragDouble ctx :row_min_height $ 1 0 FLT_MAX))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Specify height of the Selectable item.")
  (update-2nd tables.advanced.items_count (ImGui.DragInt ctx :items_count $ 0.1 0 9999))
  (update-2nd tables.advanced.contents_type (ImGui.Combo ctx "items_type (first column)" $ "Text\000Button\000SmallButton\000FillButton\000Selectable\000Selectable (span row)\000"))
  (ImGui.TreePop ctx))
(ImGui.PopItemWidth ctx)
(demo.PopStyleCompact)
(ImGui.Spacing ctx)
(ImGui.TreePop ctx))
(when (not= (length tables.advanced.items) tables.advanced.items_count)
  (set tables.advanced.items {})
  (for [n 0 (- tables.advanced.items_count 1)]
    (let [template-n (% n (length template-items-names))
          item {:id n
                :name (. template-items-names (+ template-n 1))
                :quantity (or (and (= template-n 3) 10)
                              (or (and (= template-n 4) 20) 0))}]
      (table.insert tables.advanced.items item))))
(local inner-width-to-use (or (when (not= (band tables.advanced.flags
                                                (ImGui.TableFlags_ScrollX))
                                          0)
                                tables.advanced.inner_width_with_scroll)
                              0))
(var (w h) (values 0 0))
(when tables.advanced.outer_size_enabled
  (set (w h) (table.unpack tables.advanced.outer_size_value)))
(when (ImGui.BeginTable ctx :table_advanced 6 tables.advanced.flags w h
                        inner-width-to-use)
  (ImGui.TableSetupColumn ctx :ID
                          (bor (ImGui.TableColumnFlags_DefaultSort)
                               (ImGui.TableColumnFlags_WidthFixed)
                               (ImGui.TableColumnFlags_NoHide))
                          0 My-item-column-iD_ID)
  (ImGui.TableSetupColumn ctx :Name (ImGui.TableColumnFlags_WidthFixed) 0
                          My-item-column-iD_Name)
  (ImGui.TableSetupColumn ctx :Action
                          (bor (ImGui.TableColumnFlags_NoSort)
                               (ImGui.TableColumnFlags_WidthFixed))
                          0 My-item-column-iD_Action)
  (ImGui.TableSetupColumn ctx :Quantity
                          (ImGui.TableColumnFlags_PreferSortDescending) 0
                          My-item-column-iD_Quantity)
  (ImGui.TableSetupColumn ctx :Description
                          (or (and (not= (band tables.advanced.flags
                                               (ImGui.TableFlags_NoHostExtendX))
                                         0)
                                   0)
                              (ImGui.TableColumnFlags_WidthStretch))
                          0 My-item-column-iD_Description)
  (ImGui.TableSetupColumn ctx :Hidden
                          (bor (ImGui.TableColumnFlags_DefaultHide)
                               (ImGui.TableColumnFlags_NoSort)))
  (ImGui.TableSetupScrollFreeze ctx tables.advanced.freeze_cols
                                tables.advanced.freeze_rows)
  (local (specs-dirty has-specs) (ImGui.TableNeedSort ctx))
  (when (and has-specs (or specs-dirty tables.advanced.items_need_sort))
    (table.sort tables.advanced.items demo.CompareTableItems)
    (set tables.advanced.items_need_sort false))
  (local sorts-specs-using-quantity
    (not= (band (ImGui.TableGetColumnFlags ctx 3)
                (ImGui.TableColumnFlags_IsSorted))
          0))
  (when tables.advanced.show_headers (ImGui.TableHeadersRow ctx))
  (ImGui.PushButtonRepeat ctx true)
  (local clipper (ImGui.CreateListClipper ctx))
  (ImGui.ListClipper_Begin clipper (length tables.advanced.items))
  (while (ImGui.ListClipper_Step clipper)
    (local (display-start display-end)
      (ImGui.ListClipper_GetDisplayRange clipper))
    (for [row-n display-start (- display-end 1)]
      (local item (. tables.advanced.items (+ row-n 1)))
      (ImGui.PushID ctx item.id)
      (ImGui.TableNextRow ctx (ImGui.TableRowFlags_None)
                          tables.advanced.row_min_height)
      (ImGui.TableSetColumnIndex ctx 0)
      (local label (: "%04d" :format item.id))
      (local contents-type tables.advanced.contents_type)
      (if (= contents-type 0) (ImGui.Text ctx label) (= contents-type 1)
        (ImGui.Button ctx label) (= contents-type 2)
        (ImGui.SmallButton ctx label) (= contents-type 3)
        (ImGui.Button ctx label (- FLT_MIN) 0)
        (or (= contents-type 4) (= contents-type 5))
        (let [selectable-flags (or (and (= contents-type 5)
                                        (bor (ImGui.SelectableFlags_SpanAllColumns)
                                             (ImGui.SelectableFlags_AllowItemOverlap)))
                                   (ImGui.SelectableFlags_None))]
          (when (ImGui.Selectable ctx label item.is_selected
                                  selectable-flags 0
                                  tables.advanced.row_min_height)
            (if (ImGui.IsKeyDown ctx (ImGui.Mod_Ctrl))
              (set item.is_selected (not item.is_selected))
              (each [_ it (ipairs tables.advanced.items)]
                (set it.is_selected (= it item)))))))
      (when (ImGui.TableSetColumnIndex ctx 1) (ImGui.Text ctx item.name))
      (when (ImGui.TableSetColumnIndex ctx 2)
        (when (ImGui.SmallButton ctx :Chop)
          (set item.quantity (+ item.quantity 1)))
        (when (and sorts-specs-using-quantity
                   (ImGui.IsItemDeactivated ctx))
          (set tables.advanced.items_need_sort true))
        (ImGui.SameLine ctx)
        (when (ImGui.SmallButton ctx :Eat)
          (set item.quantity (- item.quantity 1)))
        (when (and sorts-specs-using-quantity
                   (ImGui.IsItemDeactivated ctx))
          (set tables.advanced.items_need_sort true)))
      (when (ImGui.TableSetColumnIndex ctx 3)
        (ImGui.Text ctx (: "%d" :format item.quantity)))
      (ImGui.TableSetColumnIndex ctx 4)
      (if tables.advanced.show_wrapped_text
        (ImGui.TextWrapped ctx "Lorem ipsum dolor sit amet")
        (ImGui.Text ctx "Lorem ipsum dolor sit amet"))
      (when (ImGui.TableSetColumnIndex ctx 5) (ImGui.Text ctx :1234))
      (ImGui.PopID ctx)))
  (ImGui.PopButtonRepeat ctx)
  (ImGui.EndTable ctx))
(ImGui.TreePop ctx))
(ImGui.PopID ctx)
(when tables.disable_indent (ImGui.PopStyleVar ctx))))

(fn demo.ShowDemoWindowInputs []
  (var rv nil)
  (when (ImGui.CollapsingHeader ctx "Inputs & Focus")
    (ImGui.SetNextItemOpen ctx true (ImGui.Cond_Once))
    (when (ImGui.TreeNode ctx :Inputs)
      (demo.HelpMarker "This is a simplified view. See more detailed input state:
- in 'Tools->Metrics/Debugger->Inputs'.
- in 'Tools->Debug Log->IO'.")
      (if (ImGui.IsMousePosValid ctx)
          (ImGui.Text ctx
                       (: "Mouse pos: (%g, %g)" :format
                          (ImGui.GetMousePos ctx)))
          (ImGui.Text ctx "Mouse pos: <INVALID>"))
      (ImGui.Text ctx (: "Mouse delta: (%g, %g)" :format
                          (ImGui.GetMouseDelta ctx)))
      (local buttons 4)
      (ImGui.Text ctx "Mouse down:")
      (for [button 0 buttons]
        (when (ImGui.IsMouseDown ctx button)
          (local duration (ImGui.GetMouseDownDuration ctx button))
          (ImGui.SameLine ctx)
          (ImGui.Text ctx (: "b%d (%.02f secs)" :format button duration))))
      (ImGui.Text ctx (: "Mouse wheel: %.1f %.1f" :format
                          (ImGui.GetMouseWheel ctx)))
      (ImGui.Text ctx "Keys down:")
      (each [key name (demo.EachEnum :Key)]
        (when (ImGui.IsKeyDown ctx key)
          (local duration (ImGui.GetKeyDownDuration ctx key))
          (ImGui.SameLine ctx)
          (ImGui.Text ctx (: "\"%s\" %d (%.02f secs)" :format name key
                              duration))))
      (ImGui.Text ctx (: "Keys mods: %s%s%s%s" :format
                          (or (and (ImGui.IsKeyDown ctx (ImGui.Mod_Ctrl))
                                   "CTRL ") "")
                          (or (and (ImGui.IsKeyDown ctx (ImGui.Mod_Shift))
                                   "SHIFT ") "")
                          (or (and (ImGui.IsKeyDown ctx (ImGui.Mod_Alt))
                                   "ALT ") "")
                          (or (and (ImGui.IsKeyDown ctx (ImGui.Mod_Super))
                                   "SUPER ") "")))
      (ImGui.Text ctx "Chars queue:")
      (for [next-id 0 math.huge]
        (local (rv c) (ImGui.GetInputQueueCharacter ctx next-id))
        (when (not rv) (lua :break))
        (ImGui.SameLine ctx)
        (ImGui.Text ctx (: "'%s' (0x%04X)" :format (utf8.char c) c)))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "WantCapture override")
      (when (not misc.capture_override)
        (set misc.capture_override {:keyboard (- 1) :mouse (- 1)}))
      (demo.HelpMarker "SetNextFrameWantCaptureXXX instructs ReaImGui how to route inputs.

Capturing the keyboard allows receiving input from REAPER's global scope.

Hovering the colored canvas will call SetNextFrameWantCaptureXXX.")
      (local capture-override-desc [:None "Set to false" "Set to true"])
      (ImGui.SetNextItemWidth ctx (* (ImGui.GetFontSize ctx) 15))
      (update-2nd misc.capture_override.keyboard
                  (ImGui.SliderInt ctx "SetNextFrameWantCaptureKeyboard() on hover" $ (- 1) 1
                                   (. capture-override-desc (+ $ 2)) (ImGui.SliderFlags_AlwaysClamp)))
      (ImGui.ColorButton ctx "##panel" 2988028671
                         (bor (ImGui.ColorEditFlags_NoTooltip)
                              (ImGui.ColorEditFlags_NoDragDrop))
                         128 96)
      (when (and (ImGui.IsItemHovered ctx)
                 (not= misc.capture_override.keyboard -1))
        (ImGui.SetNextFrameWantCaptureKeyboard ctx (= 1 misc.capture_override.keyboard)))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Mouse Cursors")
      (let [current (ImGui.GetMouseCursor ctx)]
        (each [cursor name (demo.EachEnum :MouseCursor)]
          (when (= cursor current)
            (ImGui.Text ctx (: "Current mouse cursor = %d: %s" :format current
                               name))
            (lua :break))))
      (ImGui.Text ctx "Hover to see mouse cursors:")
      (each [i name (demo.EachEnum :MouseCursor)]
        (let [label (: "Mouse cursor %d: %s" :format i name)]
          (ImGui.Bullet ctx)
          (ImGui.Selectable ctx label false)
          (when (ImGui.IsItemHovered ctx) (ImGui.SetMouseCursor ctx i))))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx :Tabbing)
      (set-when-not misc.tabbing {:buf :hello})
      (ImGui.Text ctx "Use TAB/SHIFT+TAB to cycle through keyboard editable fields.")
      (update-2nd misc.tabbing.buf (ImGui.InputText ctx :1 $))
      (update-2nd misc.tabbing.buf (ImGui.InputText ctx :2 $))
      (update-2nd misc.tabbing.buf (ImGui.InputText ctx :3 $))
      (ImGui.PushAllowKeyboardFocus ctx false)
      (update-2nd misc.tabbing.buf (ImGui.InputText ctx "4 (tab skip)" $))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Item won't be cycled through when using TAB or Shift+Tab.")
      (ImGui.PopAllowKeyboardFocus ctx)
      (update-2nd misc.tabbing.buf (ImGui.InputText ctx :5 $))
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx "Focus from code")
      (set-when-not misc.focus {:buf "click on a button to set focus" :d3 [0 0 0]})
      (local focus-1 (ImGui.Button ctx "Focus on 1"))
      (ImGui.SameLine ctx)
      (local focus-2 (ImGui.Button ctx "Focus on 2"))
      (ImGui.SameLine ctx)
      (local focus-3 (ImGui.Button ctx "Focus on 3"))
      (var has-focus 0)
      (when focus-1 (ImGui.SetKeyboardFocusHere ctx))
      (update-2nd misc.focus.buf (ImGui.InputText ctx :1 $))
      (when (ImGui.IsItemActive ctx) (set has-focus 1))
      (when focus-2 (ImGui.SetKeyboardFocusHere ctx))
      (update-2nd misc.focus.buf (ImGui.InputText ctx :2 $))
      (when (ImGui.IsItemActive ctx) (set has-focus 2))
      (ImGui.PushAllowKeyboardFocus ctx false)
      (when focus-3 (ImGui.SetKeyboardFocusHere ctx))
      (update-2nd misc.focus.buf (ImGui.InputText ctx "3 (tab skip)" $))
      (when (ImGui.IsItemActive ctx) (set has-focus 3))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Item won't be cycled through when using TAB or Shift+Tab.")
      (ImGui.PopAllowKeyboardFocus ctx)
      (if (> has-focus 0)
        (ImGui.Text ctx
                    (: "Item with focus: %d" :format
                       has-focus))
        (ImGui.Text ctx "Item with focus: <none>"))
      (var focus-ahead -1)
      (when (ImGui.Button ctx "Focus on X") (set focus-ahead 0))
      (ImGui.SameLine ctx)
      (when (ImGui.Button ctx "Focus on Y") (set focus-ahead 1))
      (ImGui.SameLine ctx)
      (when (ImGui.Button ctx "Focus on Z") (set focus-ahead 2))
      (when (not= -1 focus-ahead)
        (ImGui.SetKeyboardFocusHere ctx focus-ahead))
      (set-forcibly! (rv d31 d32 d33)
                     (ImGui.SliderDouble3 ctx :Float3
                                          (. misc.focus.d3 1)
                                          (. misc.focus.d3 2)
                                          (. misc.focus.d3 3)
                                          0 1))
      (tset misc.focus.d3 1 d31)
      (tset misc.focus.d3 2 d32)
      (tset misc.focus.d3 3 d33)
      (ImGui.TextWrapped ctx "NB: Cursor & selection are preserved when refocusing last used item in code.")
      (ImGui.TreePop ctx))
    (when (ImGui.TreeNode ctx :Dragging)
      (ImGui.TextWrapped ctx "You can use GetMouseDragDelta(0) to query for the dragged amount on any widget.")
      (for [button 0 2]
        (ImGui.Text ctx (: "IsMouseDragging(%d):" :format button))
        (ImGui.Text ctx (: "  w/ default threshold: %s," :format (ImGui.IsMouseDragging ctx button)))
        (ImGui.Text ctx (: "  w/ zero threshold: %s," :format (ImGui.IsMouseDragging ctx button 0)))
        (ImGui.Text ctx (: "  w/ large threshold: %s," :format (ImGui.IsMouseDragging ctx button 20))))
      (ImGui.Button ctx "Drag Me")
      (when (ImGui.IsItemActive ctx)
        (local draw-list (ImGui.GetForegroundDrawList ctx))
        (local mouse-pos [(ImGui.GetMousePos ctx)])
        (local click-pos [(ImGui.GetMouseClickedPos ctx 0)])
        (local color (ImGui.GetColor ctx (ImGui.Col_Button)))
        (ImGui.DrawList_AddLine draw-list (. click-pos 1) (. click-pos 2)
                                (. mouse-pos 1) (. mouse-pos 2) color 4))
      (local value-raw
             [(ImGui.GetMouseDragDelta ctx 0 0 (ImGui.MouseButton_Left) 0)])
      (local value-with-lock-threshold
             [(ImGui.GetMouseDragDelta ctx 0 0 (ImGui.MouseButton_Left))])
      (local mouse-delta [(ImGui.GetMouseDelta ctx)])
      (ImGui.Text ctx "GetMouseDragDelta(0):")
      (ImGui.Text ctx (: "  w/ default threshold: (%.1f, %.1f)" :format (table.unpack value-with-lock-threshold)))
      (ImGui.Text ctx (: "  w/ zero threshold: (%.1f, %.1f)" :format (table.unpack value-raw)))
      (ImGui.Text ctx (: "GetMouseDelta() (%.1f, %.1f)" :format (table.unpack mouse-delta)))
      (ImGui.TreePop ctx))))

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
      (let [rv [(ImGui.GetStyleVar ctx i)]]
        (var is-vec2 false)
        (each [_ vec2-name (ipairs vec2)]
          (when (= vec2-name name)
            (set is-vec2 true)
            (lua :break)))
        (tset data.vars i (if is-vec2 rv (. rv 1)))))
    (each [i (demo.EachEnum :Col)]
      (tset data.colors i (ImGui.GetStyleColor ctx i)))
    data))

(fn demo.CopyStyleData [source target]
  (each [i value (pairs source.vars)]
    (tset target.vars i (if (= (type value) :table)
                          [(table.unpack value)]
                          value)))
  (each [i value (pairs source.colors)]
    (tset target.colors i value)))

(fn demo.PushStyle []
  (when app.style_editor
    (set app.style_editor.push_count (+ app.style_editor.push_count 1))
    (each [i value (pairs app.style_editor.style.vars)]
      (ImGui.PushStyleVar ctx i (if (= :table (type value))
                                  (table.unpack value)
                                  value)))
    (each [i value (pairs app.style_editor.style.colors)]
      (ImGui.PushStyleColor ctx i value))))

(fn demo.PopStyle []
  (when (-?> app.style_editor (> 0))
    (set app.style_editor.push_count (- app.style_editor.push_count 1))
    (ImGui.PopStyleColor ctx (length (. cache :Col)))
    (ImGui.PopStyleVar ctx (length (. cache :StyleVar)))))

(fn demo.ShowStyleEditor []
  (var rv nil)
  (when (not app.style_editor)
    (set app.style_editor
         {:output_dest 0
          :output_only_modified true
          :push_count 0
          :ref (demo.GetStyleData)
          :style (demo.GetStyleData)}))
  (ImGui.PushItemWidth ctx (* (ImGui.GetWindowWidth ctx) 0.5))
  (local (Frame-rounding Grab-rounding)
         (values (ImGui.StyleVar_FrameRounding) (ImGui.StyleVar_GrabRounding)))
  (set-forcibly! (rv vfr)
                 (ImGui.SliderDouble ctx :FrameRounding
                                      (. app.style_editor.style.vars
                                         Frame-rounding)
                                      0 12 "%.0f"))
  (tset app.style_editor.style.vars Frame-rounding vfr)
  (when rv
    (tset app.style_editor.style.vars Grab-rounding
          (. app.style_editor.style.vars Frame-rounding)))
  (local borders [:WindowBorder :FrameBorder :PopupBorder])
  (each [i name (ipairs borders)]
    (local ___var___ ((. ImGui (: "StyleVar_%sSize" :format name))))
    (var enable (> (. app.style_editor.style.vars ___var___) 0))
    (when (> i 1) (ImGui.SameLine ctx))
    (set (rv enable) (ImGui.Checkbox ctx name enable))
    (when rv
      (tset app.style_editor.style.vars ___var___ (or (and enable 1) 0))))
  (when (ImGui.Button ctx "Save Ref")
    (demo.CopyStyleData app.style_editor.style app.style_editor.ref))
  (ImGui.SameLine ctx)
  (when (ImGui.Button ctx "Revert Ref")
    (demo.CopyStyleData app.style_editor.ref app.style_editor.style))
  (ImGui.SameLine ctx)
  (demo.HelpMarker "Save/Revert in local non-persistent storage. Default Colors definition are not affected. Use \"Export\" below to save them somewhere.")

  (fn export [enum-name func-suffix cur-table ref-table is-equal format-value]
    (var (lines name-maxlen) (values {} 0))
    (each [i name (demo.EachEnum enum-name)]
      (when (or (not app.style_editor.output_only_modified)
                (not (is-equal (. cur-table i) (. ref-table i))))
        (table.insert lines [name (. cur-table i)])
        (set name-maxlen (math.max name-maxlen (name:len)))))
    (if (= app.style_editor.output_dest 0) (ImGui.LogToClipboard ctx)
        (ImGui.LogToTTY ctx))
    (each [_ line (ipairs lines)]
      (local pad (string.rep " " (- name-maxlen (: (. line 1) :len))))
      (ImGui.LogText ctx
                      (: "ImGui.Push%s(ctx, ImGui.%s_%s(),%s %s)\n" :format
                         func-suffix enum-name (. line 1) pad
                         (format-value (. line 2)))))
    (if (= (length lines) 1)
        (ImGui.LogText ctx (: "\nImGui.Pop%s(ctx)\n" :format func-suffix))
        (> (length lines) 1)
        (ImGui.LogText ctx (: "\nImGui.Pop%s(ctx, %d)\n" :format func-suffix
                               (length lines))))
    (ImGui.LogFinish ctx))

  (when (ImGui.Button ctx "Export Vars")
    (export :StyleVar :StyleVar app.style_editor.style.vars
            app.style_editor.ref.vars
            (fn [a b]
              (if (= (type a) :table)
                  (and (= (. a 1) (. b 1)) (= (. a 2) (. b 2))) (= a b)))
            (fn [val]
              (if (= (type val) :table) (: "%g, %g" :format (table.unpack val))
                  (: "%g" :format val)))))
  (ImGui.SameLine ctx)
  (when (ImGui.Button ctx "Export Colors")
    (export :Col :StyleColor app.style_editor.style.colors
            app.style_editor.ref.colors (fn [a b] (= a b))
            (fn [val] (: "0x%08X" :format (band val 4294967295)))))
  (ImGui.SameLine ctx)
  (ImGui.SetNextItemWidth ctx 120)
  (set (rv app.style_editor.output_dest)
       (ImGui.Combo ctx "##output_type" app.style_editor.output_dest
                     "To Clipboard\000To TTY\000"))
  (ImGui.SameLine ctx)
  (set (rv app.style_editor.output_only_modified)
       (ImGui.Checkbox ctx "Only Modified"
                        app.style_editor.output_only_modified))
  (ImGui.Separator ctx)
  (when (ImGui.BeginTabBar ctx "##tabs" (ImGui.TabBarFlags_None))
    (when (ImGui.BeginTabItem ctx :Sizes)
      (fn slider [varname min max format]
        (let [func (. ImGui (.. :StyleVar_ varname))]
          (assert func (: "%s is not exposed as a StyleVar" :format varname))
          (local ___var___ (func))
          (if (= (type (. app.style_editor.style.vars ___var___)) :table)
              (let [(rv val1 val2) (ImGui.SliderDouble2 ctx varname
                                                         (. (. app.style_editor.style.vars
                                                               ___var___)
                                                            1)
                                                         (. (. app.style_editor.style.vars
                                                               ___var___)
                                                            2)
                                                         min max format)]
                (when rv
                  (tset app.style_editor.style.vars ___var___ [val1 val2])))
              (let [(rv val) (ImGui.SliderDouble ctx varname
                                                  (. app.style_editor.style.vars
                                                     ___var___)
                                                  min max format)]
                (when rv (tset app.style_editor.style.vars ___var___ val))))))

      (ImGui.SeparatorText ctx :Main)
      (slider :WindowPadding 0 20 "%.0f")
      (slider :FramePadding 0 20 "%.0f")
      (slider :CellPadding 0 20 "%.0f")
      (slider :ItemSpacing 0 20 "%.0f")
      (slider :ItemInnerSpacing 0 20 "%.0f")
      (slider :IndentSpacing 0 30 "%.0f")
      (slider :ScrollbarSize 1 20 "%.0f")
      (slider :GrabMinSize 1 20 "%.0f")
      (ImGui.SeparatorText ctx :Borders)
      (slider :WindowBorderSize 0 1 "%.0f")
      (slider :ChildBorderSize 0 1 "%.0f")
      (slider :PopupBorderSize 0 1 "%.0f")
      (slider :FrameBorderSize 0 1 "%.0f")
      (ImGui.SeparatorText ctx :Rounding)
      (slider :WindowRounding 0 12 "%.0f")
      (slider :ChildRounding 0 12 "%.0f")
      (slider :FrameRounding 0 12 "%.0f")
      (slider :PopupRounding 0 12 "%.0f")
      (slider :ScrollbarRounding 0 12 "%.0f")
      (slider :GrabRounding 0 12 "%.0f")
      (slider :TabRounding 0 12 "%.0f")
      (ImGui.SeparatorText ctx :Widgets)
      (slider :WindowTitleAlign 0 1 "%.2f")
      (slider :ButtonTextAlign 0 1 "%.2f")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Alignment applies when a button is larger than its text content.")
      (slider :SelectableTextAlign 0 1 "%.2f")
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Alignment applies when a selectable is larger than its text content.")
      (slider :SeparatorTextBorderSize 0 10 "%.0f")
      (slider :SeparatorTextAlign 0 1 "%.2f")
      (slider :SeparatorTextPadding 0 40 "%.0f")
      (ImGui.EndTabItem ctx))
    (when (ImGui.BeginTabItem ctx :Colors)
      (when (not app.style_editor.colors)
        (set app.style_editor.colors
             {:alpha_flags (ImGui.ColorEditFlags_None)
              :filter {:inst nil :text ""}}))
      (when (not (ImGui.ValidatePtr app.style_editor.colors.filter.inst
                                     :ImGui_TextFilter*))
        (set app.style_editor.colors.filter.inst
             (ImGui.CreateTextFilter app.style_editor.colors.filter.text)))
      (when (ImGui.TextFilter_Draw app.style_editor.colors.filter.inst ctx
                                    "Filter colors"
                                    (* (ImGui.GetFontSize ctx) 16))
        (set app.style_editor.colors.filter.text
             (ImGui.TextFilter_Get app.style_editor.colors.filter.inst)))
      (when (ImGui.RadioButton ctx :Opaque
                                (= app.style_editor.colors.alpha_flags
                                   (ImGui.ColorEditFlags_None)))
        (set app.style_editor.colors.alpha_flags (ImGui.ColorEditFlags_None)))
      (ImGui.SameLine ctx)
      (when (ImGui.RadioButton ctx :Alpha
                                (= app.style_editor.colors.alpha_flags
                                   (ImGui.ColorEditFlags_AlphaPreview)))
        (set app.style_editor.colors.alpha_flags
             (ImGui.ColorEditFlags_AlphaPreview)))
      (ImGui.SameLine ctx)
      (when (ImGui.RadioButton ctx :Both
                                (= app.style_editor.colors.alpha_flags
                                   (ImGui.ColorEditFlags_AlphaPreviewHalf)))
        (set app.style_editor.colors.alpha_flags
             (ImGui.ColorEditFlags_AlphaPreviewHalf)))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "In the color list:
Left-click on color square to open color picker,
Right-click to open edit options menu.")
      (when (ImGui.BeginChild ctx "##colors" 0 0 true
                               (bor (ImGui.WindowFlags_AlwaysVerticalScrollbar)
                                    (ImGui.WindowFlags_AlwaysHorizontalScrollbar)
                                    0))
        (ImGui.PushItemWidth ctx (- 160))
        (local inner-spacing
               (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemInnerSpacing)))
        (each [i name (demo.EachEnum :Col)]
          (when (ImGui.TextFilter_PassFilter app.style_editor.colors.filter.inst
                                              name)
            (ImGui.PushID ctx i)
            (set-forcibly! (rv ci)
                           (ImGui.ColorEdit4 ctx "##color"
                                              (. app.style_editor.style.colors
                                                 i)
                                              (bor (ImGui.ColorEditFlags_AlphaBar)
                                                   app.style_editor.colors.alpha_flags)))
            (tset app.style_editor.style.colors i ci)
            (when (not= (. app.style_editor.style.colors i)
                        (. app.style_editor.ref.colors i))
              (ImGui.SameLine ctx 0 inner-spacing)
              (when (ImGui.Button ctx :Save)
                (tset app.style_editor.ref.colors i
                      (. app.style_editor.style.colors i)))
              (ImGui.SameLine ctx 0 inner-spacing)
              (when (ImGui.Button ctx :Revert)
                (tset app.style_editor.style.colors i
                      (. app.style_editor.ref.colors i))))
            (ImGui.SameLine ctx 0 inner-spacing)
            (ImGui.Text ctx name)
            (ImGui.PopID ctx)))
        (ImGui.PopItemWidth ctx)
        (ImGui.EndChild ctx))
      (ImGui.EndTabItem ctx))
    (when (ImGui.BeginTabItem ctx :Rendering)
      (ImGui.PushItemWidth ctx (* (ImGui.GetFontSize ctx) 8))
      (local (Alpha Disabled-alpha)
             (values (ImGui.StyleVar_Alpha) (ImGui.StyleVar_DisabledAlpha)))
      (set-forcibly! (rv v-a)
                     (ImGui.DragDouble ctx "Global Alpha"
                                        (. app.style_editor.style.vars Alpha)
                                        0.005 0.2 1 "%.2f"))
      (tset app.style_editor.style.vars Alpha v-a)
      (set-forcibly! (rv v-dA)
                     (ImGui.DragDouble ctx "Disabled Alpha"
                                        (. app.style_editor.style.vars
                                           Disabled-alpha)
                                        0.005 0 1 "%.2f"))
      (tset app.style_editor.style.vars Disabled-alpha v-dA)
      (ImGui.SameLine ctx)
      (demo.HelpMarker "Additional alpha multiplier for disabled items (multiply over current value of Alpha).")
      (ImGui.PopItemWidth ctx)
      (ImGui.EndTabItem ctx))
    (ImGui.EndTabBar ctx))
  (ImGui.PopItemWidth ctx))

(fn demo.ShowUserGuide []
  (ImGui.BulletText ctx "Double-click on title bar to collapse window.")
  (ImGui.BulletText ctx "Click and drag on lower corner to resize window
(double-click to auto fit window to its contents).")
  (ImGui.BulletText ctx "CTRL+Click on a slider or drag box to input value as text.")
  (ImGui.BulletText ctx "TAB/SHIFT+TAB to cycle through keyboard editable fields.")
  (ImGui.BulletText ctx "CTRL+Tab to select a window.")
  (ImGui.BulletText ctx "While inputing text:\n")
  (ImGui.Indent ctx)
  (ImGui.BulletText ctx "CTRL+Left/Right to word jump.")
  (ImGui.BulletText ctx "CTRL+A or double-click to select all.")
  (ImGui.BulletText ctx "CTRL+X/C/V to use clipboard cut/copy/paste.")
  (ImGui.BulletText ctx "CTRL+Z,CTRL+Y to undo/redo.")
  (ImGui.BulletText ctx "ESCAPE to revert.")
  (ImGui.Unindent ctx)
  (ImGui.BulletText ctx "With keyboard navigation enabled:")
  (ImGui.Indent ctx)
  (ImGui.BulletText ctx "Arrow keys to navigate.")
  (ImGui.BulletText ctx "Space to activate a widget.")
  (ImGui.BulletText ctx "Return to input text into a widget.")
  (ImGui.BulletText ctx "Escape to deactivate a widget, close popup, exit child window.")
  (ImGui.BulletText ctx "Alt to jump to the menu layer of a window.")
  (ImGui.Unindent ctx))

(fn demo.ShowExampleMenuFile []
  (var rv nil)
  (ImGui.MenuItem ctx "(demo menu)" nil false false)
  (when (ImGui.MenuItem ctx :New) nil)
  (when (ImGui.MenuItem ctx :Open :Ctrl+O) nil)
  (when (ImGui.BeginMenu ctx "Open Recent")
    (ImGui.MenuItem ctx :fish_hat.c)
    (ImGui.MenuItem ctx :fish_hat.inl)
    (ImGui.MenuItem ctx :fish_hat.h)
    (when (ImGui.BeginMenu ctx :More..) (ImGui.MenuItem ctx :Hello)
      (ImGui.MenuItem ctx :Sailor)
      (when (ImGui.BeginMenu ctx :Recurse..) (demo.ShowExampleMenuFile)
        (ImGui.EndMenu ctx))
      (ImGui.EndMenu ctx))
    (ImGui.EndMenu ctx))
  (when (ImGui.MenuItem ctx :Save :Ctrl+S) nil)
  (when (ImGui.MenuItem ctx "Save As..") nil)
  (ImGui.Separator ctx)
  (when (ImGui.BeginMenu ctx :Options)
    (set (rv demo.menu.enabled)
         (ImGui.MenuItem ctx :Enabled "" demo.menu.enabled))
    (when (ImGui.BeginChild ctx :child 0 60 true)
      (for [i 0 9] (ImGui.Text ctx (: "Scrolling Text %d" :format i)))
      (ImGui.EndChild ctx))
    (set (rv demo.menu.f) (ImGui.SliderDouble ctx :Value demo.menu.f 0 1))
    (set (rv demo.menu.f) (ImGui.InputDouble ctx :Input demo.menu.f 0.1))
    (set (rv demo.menu.n)
         (ImGui.Combo ctx :Combo demo.menu.n "Yes\000No\000Maybe\000"))
    (ImGui.EndMenu ctx))
  (when (ImGui.BeginMenu ctx :Colors)
    (local sz (ImGui.GetTextLineHeight ctx))
    (local draw-list (ImGui.GetWindowDrawList ctx))
    (each [i name (demo.EachEnum :Col)]
      (local (x y) (ImGui.GetCursorScreenPos ctx))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz)
                                     (ImGui.GetColor ctx i))
      (ImGui.Dummy ctx sz sz)
      (ImGui.SameLine ctx)
      (ImGui.MenuItem ctx name))
    (ImGui.EndMenu ctx))
  (when (ImGui.BeginMenu ctx :Options)
    (set (rv demo.menu.b) (ImGui.Checkbox ctx :SomeOption demo.menu.b))
    (ImGui.EndMenu ctx))
  (when (ImGui.BeginMenu ctx :Disabled false) (error "never called"))
  (when (ImGui.MenuItem ctx :Checked nil true) nil)
  (ImGui.Separator ctx)
  (when (ImGui.MenuItem ctx :Quit :Alt+F4) nil))

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
    (each [line (text:gmatch "[^\r\n]+")]
      (table.insert self.lines line))))

(fn Example-app-log.draw [self title p-open]
  (let [(rv p-open) (ImGui.Begin self.ctx title p-open)]
    (when rv
      (when (not (ImGui.ValidatePtr self.filter.inst :ImGui_TextFilter*))
        (set self.filter.inst (ImGui.CreateTextFilter self.filter.text)))
      (when (ImGui.BeginPopup self.ctx :Options)
        (update-2nd self.auto_scroll (ImGui.Checkbox self.ctx :Auto-scroll $))
        (ImGui.EndPopup self.ctx))
      (when (ImGui.Button self.ctx :Options)
        (ImGui.OpenPopup self.ctx :Options))
      (ImGui.SameLine self.ctx)
      (local clear (ImGui.Button self.ctx :Clear))
      (ImGui.SameLine self.ctx)
      (local copy (ImGui.Button self.ctx :Copy))
      (ImGui.SameLine self.ctx)
      (when (ImGui.TextFilter_Draw self.filter.inst ctx :Filter (- 100))
        (set self.filter.text (ImGui.TextFilter_Get self.filter.inst)))
      (ImGui.Separator self.ctx)
      (when (ImGui.BeginChild self.ctx :scrolling 0 0 false (ImGui.WindowFlags_HorizontalScrollbar))
        (when clear (self:clear))
        (when copy (ImGui.LogToClipboard self.ctx))
        (ImGui.PushStyleVar self.ctx (ImGui.StyleVar_ItemSpacing) 0 0)
        (if (ImGui.TextFilter_IsActive self.filter.inst)
          (each [line-no line (ipairs self.lines)]
            (when (ImGui.TextFilter_PassFilter self.filter.inst line)
              (ImGui.Text ctx line)))
          (let [clipper (ImGui.CreateListClipper self.ctx)]
            (ImGui.ListClipper_Begin clipper (length self.lines))
            (while (ImGui.ListClipper_Step clipper)
              (local (display-start display-end)
                (ImGui.ListClipper_GetDisplayRange clipper))
              (for [line-no display-start (- display-end 1)]
                (ImGui.Text self.ctx (. self.lines (+ line-no 1)))))
            (ImGui.ListClipper_End clipper)))
        (ImGui.PopStyleVar self.ctx)
        (when (and self.auto_scroll
                   (>= (ImGui.GetScrollY self.ctx) (ImGui.GetScrollMaxY self.ctx)))
          (ImGui.SetScrollHereY self.ctx 1))
        (ImGui.EndChild self.ctx))
      (ImGui.End self.ctx))
    p-open))

(fn demo.ShowExampleAppLog []
  (when (not app.log)
    (set app.log (doto (Example-app-log:new ctx)
                   (tset :counter 0))))
  (ImGui.SetNextWindowSize ctx 500 400 (ImGui.Cond_FirstUseEver))
  (let [(rv open) (ImGui.Begin ctx "Example: Log" true)]
    (when rv
      (when (ImGui.SmallButton ctx "[Debug] Add 5 entries")
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
          " (ImGui.GetFrameCount ctx) category
                           (ImGui.GetTime ctx) word)
          (set app.log.counter (+ app.log.counter 1))))
      (ImGui.End ctx)
      (app.log:draw "Example: Log"))
    open))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Simple Layout / ShowExampleAppLayout()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate create a window with multiple child windows.
(fn demo.ShowExampleAppLayout []
  (set-when-not app.layout {:selected 0})
  (ImGui.SetNextWindowSize ctx 500 440 (ImGui.Cond_FirstUseEver))
  (var (rv open) (ImGui.Begin ctx "Example: Simple layout" true
                              (ImGui.WindowFlags_MenuBar)))
  (when rv
    (when (ImGui.BeginMenuBar ctx)
      (when (ImGui.BeginMenu ctx :File)
        (when (ImGui.MenuItem ctx :Close :Ctrl+W)
          (set open false))
        (ImGui.EndMenu ctx))
      (ImGui.EndMenuBar ctx))

    ;; Left
    (when (ImGui.BeginChild ctx "left pane" 150 0 true)
      (for [i 0 (- 100 1)]
        (when (ImGui.Selectable ctx (: "MyObject %d" :format i) (= app.layout.selected i))
          (set app.layout.selected i)))
      (ImGui.EndChild ctx))
    (ImGui.SameLine ctx)

    ;; Right
    (ImGui.BeginGroup ctx)
    (when (ImGui.BeginChild ctx "item view" 0 (- (ImGui.GetFrameHeightWithSpacing ctx)))
      (ImGui.Text ctx (: "MyObject: %d" :format app.layout.selected))
      (ImGui.Separator ctx)
      (when (ImGui.BeginTabBar ctx "##Tabs" (ImGui.TabBarFlags_None))
        (when (ImGui.BeginTabItem ctx :Description)
          (ImGui.TextWrapped ctx "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ")
          (ImGui.EndTabItem ctx))
        (when (ImGui.BeginTabItem ctx :Details)
          (ImGui.Text ctx "ID: 0123456789")
          (ImGui.EndTabItem ctx))
        (ImGui.EndTabBar ctx))
      (ImGui.EndChild ctx))
    (when (ImGui.Button ctx :Revert) :TODO)
    (ImGui.SameLine ctx)
    (when (ImGui.Button ctx :Save) :TODO)
    (ImGui.EndGroup ctx)
    (ImGui.End ctx))
  open)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Property Editor / ShowExampleAppPropertyEditor()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn demo.ShowPlaceholderObject [prefix uid]
  ;; Use object uid as identifier. Most commonly you could also use the object pointer as a base ID.
  (ImGui.PushID ctx uid)
  ;; Text and Tree nodes are less high than framed widgets, using AlignTextToFramePadding() we add vertical spacing to make the tree lines equal high.
  (ImGui.TableNextRow ctx)
  (ImGui.TableSetColumnIndex ctx 0)
  (ImGui.AlignTextToFramePadding ctx)
  (local node-open (ImGui.TreeNodeEx ctx :Object (: "%s_%u" :format prefix uid)))
  (ImGui.TableSetColumnIndex ctx 1)
  (ImGui.Text ctx "my sailor is rich")
  (when node-open
    (for [i 0 (- (length app.property_editor.placeholder_members) 1)]
      (ImGui.PushID ctx i) ;; Use field index as identifier.
      (if (< i 2) (demo.ShowPlaceholderObject :Child 424242)
        (do
          ;; Here we use a TreeNode to highlight on hover (we could use e.g. Selectable as well)
          (ImGui.TableNextRow ctx)
          (ImGui.TableSetColumnIndex ctx 0)
          (ImGui.AlignTextToFramePadding ctx)
          (let [flags (bor (ImGui.TreeNodeFlags_Leaf)
                           (ImGui.TreeNodeFlags_NoTreePushOnOpen)
                           (ImGui.TreeNodeFlags_Bullet))]
            (ImGui.TreeNodeEx ctx :Field (: "Field_%d" :format i) flags))
          (ImGui.TableSetColumnIndex ctx 1)
          (ImGui.SetNextItemWidth ctx (- FLT_MIN))
          (set-forcibly! (_ pmi)
                         (ImGui.DragDouble ctx "##value"
                                           (. app.property_editor.placeholder_members i)
                                           (if (>= i 5) 1 0.01)))
          (tset app.property_editor.placeholder_members i pmi)))
      (ImGui.PopID ctx))
    (ImGui.TreePop ctx))
  (ImGui.PopID ctx))

;; Demonstrate create a simple property editor.
(fn demo.ShowExampleAppPropertyEditor []
  (when (not app.property_editor)
    (set app.property_editor {:placeholder_members [0 0 1 3.1416 100 999 0 0]}))
  (ImGui.SetNextWindowSize ctx 430 450 (ImGui.Cond_FirstUseEver))
  (let [(rv open) (ImGui.Begin ctx "Example: Property editor" true)]
    (when rv
      (demo.HelpMarker "This example shows how you may implement a property editor using two columns.
      All objects/fields data are dummies here.
      Remember that in many simple cases, you can use ImGui.SameLine(xxx) to position
      your cursor horizontally instead of using the Columns() API.")
      (ImGui.PushStyleVar ctx (ImGui.StyleVar_FramePadding) 2 2)
      (when (ImGui.BeginTable ctx :split 2
                              (bor (ImGui.TableFlags_BordersOuter)
                                   (ImGui.TableFlags_Resizable)))

        ;; Iterate placeholder objects (all the same data)
        (for [obj-i 0 (- 4 1)]
          (demo.ShowPlaceholderObject :Object obj-i)
          ;; ImGui.Separator(ctx)
          )
        (ImGui.EndTable ctx))
      (ImGui.PopStyleVar ctx)
      (ImGui.End ctx))
    open))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Long Text / ShowExampleAppLongText()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate/test rendering huge amount of text, and the incidence of clipping.
(fn demo.ShowExampleAppLongText []
  (set-when-not app.long_text {:lines 0 :log "" :test_type 0})
  (ImGui.SetNextWindowSize ctx 520 600 (ImGui.Cond_FirstUseEver))
  (let [(rv open) (ImGui.Begin ctx "Example: Long text display" true)]
    (when rv
      (ImGui.Text ctx "Printing unusually long amount of text.")
      (update-2nd app.long_text.test_type
                  (ImGui.Combo ctx "Test type" $
                               "Single call to Text()\0\z
                                Multiple calls to Text(), clipped\0\z
                                Multiple calls to Text(), not clipped (slow)\0"))
      (ImGui.Text ctx (: "Buffer contents: %d lines, %d bytes" :format
                         app.long_text.lines (app.long_text.log:len)))
      (when (ImGui.Button ctx :Clear) (set app.long_text.log "")
        (set app.long_text.lines 0))
      (ImGui.SameLine ctx)
      (when (ImGui.Button ctx "Add 1000 lines")
        (var new-lines "")
        (for [i 0 (- 1000 1)]
          (set new-lines (.. new-lines (: "%i The quick brown fox jumps over the lazy dog
          " :format (+ app.long_text.lines i)))))
        (set app.long_text.log (.. app.long_text.log new-lines))
        (set app.long_text.lines (+ app.long_text.lines 1000)))
      (when (ImGui.BeginChild ctx :Log)
        (case app.long_text.test_type
          0
          ;; Single call to TextUnformatted() with a big buffer
          (ImGui.Text ctx app.long_text.log)

          1
          ;; Multiple calls to Text(), manually coarsely clipped - demonstrate how to use the ImGui_ListClipper helper.
          (do
            (ImGui.PushStyleVar ctx (ImGui.StyleVar_ItemSpacing) 0 0)
            (local clipper (ImGui.CreateListClipper ctx))
            (ImGui.ListClipper_Begin clipper app.long_text.lines)
            (while (ImGui.ListClipper_Step clipper)
              (local (display-start display-end)
                (ImGui.ListClipper_GetDisplayRange clipper))
              (for [i display-start (- display-end 1)]
                (ImGui.Text ctx (: "%i The quick brown fox jumps over the lazy dog"
                                   :format i))))
            (ImGui.PopStyleVar ctx))

          2
          ;; Multiple calls to Text(), not clipped (slow)
          (do
            (ImGui.PushStyleVar ctx (ImGui.StyleVar_ItemSpacing) 0 0)
            (for [i 0 app.long_text.lines]
              (ImGui.Text ctx (: "%i The quick brown fox jumps over the lazy dog"
                                 :format i)))
            (ImGui.PopStyleVar ctx)))
        (ImGui.EndChild ctx))
      (ImGui.End ctx))
    open))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Auto Resize / ShowExampleAppAutoResize()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate creating a window which gets auto-resized according to its content.
(fn demo.ShowExampleAppAutoResize []
  (set-when-not app.auto_resize {:lines 10})
  (let [(rv open) (ImGui.Begin ctx "Example: Auto-resizing window" true (ImGui.WindowFlags_AlwaysAutoResize))]
    (when rv
      (ImGui.Text ctx
                  "Window will resize every-frame to the size of its content.
                  Note that you probably don't want to query the window size to
                  output your content because that would create a feedback loop.")
      (update-2nd app.auto_resize.lines (ImGui.SliderInt ctx "Number of lines" $ 1 20))
      (for [i 1 app.auto_resize.lines]
        (ImGui.Text ctx (: "%sThis is line %d" :format (: " " :rep (* i 4)) i))) ;; Pad with space to extend size horizontally
      (ImGui.End ctx))
    open))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Constrained Resize / ShowExampleAppConstrainedResize()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate creating a window with custom resize constraints.
;; Note that size constraints currently don't work on a docked window.
(fn demo.ShowExampleAppConstrainedResize []
  ;; struct CustomConstraints
  ;; {
  ;;   // Helper functions to demonstrate programmatic constraints
  ;;   // FIXME: This doesn't take account of decoration size (e.g. title bar), library should make this easier.
  ;;   static void AspectRatio(ImGuiSizeCallbackData* data)    { float aspect_ratio = *(float*)data->UserData; data->DesiredSize.x = IM_MAX(data->CurrentSize.x, data->CurrentSize.y); data->DesiredSize.y = (float)(int)(data->DesiredSize.x / aspect_ratio); }
  ;;   static void Square(ImGuiSizeCallbackData* data)         { data->DesiredSize.x = data->DesiredSize.y = IM_MAX(data->CurrentSize.x, data->CurrentSize.y); }
  ;;   static void Step(ImGuiSizeCallbackData* data)           { float step = *(float*)data->UserData; data->DesiredSize = ImVec2((int)(data->CurrentSize.x / step + 0.5f) * step, (int)(data->CurrentSize.y / step + 0.5f) * step); }
  ;; };

  (set-when-not app.constrained_resize
                {:auto_resize false
                 :display_lines 10
                 :type 0 ;; imgui's demo defaults to 5 (aspect ratio)
                 :window_padding true})
  ;; Submit constraint
  ;; float aspect_ratio = 16.0f / 9.0f;
  ;; float fixed_step = 100.0f;
  (case app.constrained_resize.type 
    ;; Between 100x100 and 500x500
    0 (ImGui.SetNextWindowSizeConstraints ctx 100 100 500 500)
     ;; Width > 100, Height > 100
     1 (ImGui.SetNextWindowSizeConstraints ctx 100 100 FLT_MAX FLT_MAX)
     ;; Vertical only
     2 (ImGui.SetNextWindowSizeConstraints ctx -1 0 -1 FLT_MAX)
     ;; Horizontal only
     3 (ImGui.SetNextWindowSizeConstraints ctx 0 -1 FLT_MAX -1)
     ;; Width Between and 400 and 500
     4 (ImGui.SetNextWindowSizeConstraints ctx 400 -1 500 -1)
  ;; if app.constrained_resize.type == 5 then ImGui.SetNextWindowSizeConstraints(ctx,   0,   0, FLT_MAX, FLT_MAX, CustomConstraints::AspectRatio, (void*)&aspect_ratio);   // Aspect ratio
  ;; if app.constrained_resize.type == 6 then ImGui.SetNextWindowSizeConstraints(ctx,   0,   0, FLT_MAX, FLT_MAX, CustomConstraints::Square);                              // Always Square
  ;; if app.constrained_resize.type == 7 then ImGui.SetNextWindowSizeConstraints(ctx,   0,   0, FLT_MAX, FLT_MAX, CustomConstraints::Step, (void*)&fixed_step);            // Fixed Step
  )

  ;; Submit window
  (when (not app.constrained_resize.window_padding)
    (ImGui.PushStyleVar ctx (ImGui.StyleVar_WindowPadding) 0 0))
  (let [window-flags (if app.constrained_resize.auto_resize
                       (ImGui.WindowFlags_AlwaysAutoResize)
                       0)
        (visible open) (ImGui.Begin ctx "Example: Constrained Resize" true window-flags)]
    (when (not app.constrained_resize.window_padding)
      (ImGui.PopStyleVar ctx))
    (when visible
      (if (ImGui.IsKeyDown ctx (ImGui.Mod_Shift))
        ;; Display a dummy viewport (in your real app you would likely use ImageButton() to display a texture.
        (let [(avail-size-w avail-size-h) (ImGui.GetContentRegionAvail ctx)
              (pos-x pos-y) (ImGui.GetCursorScreenPos ctx)]
          (ImGui.ColorButton ctx :viewport 2134081535
                             (bor (ImGui.ColorEditFlags_NoTooltip)
                                  (ImGui.ColorEditFlags_NoDragDrop))
                             avail-size-w avail-size-h)
          (ImGui.SetCursorScreenPos ctx (+ pos-x 10) (+ pos-y 10))
          (ImGui.Text ctx (: "%.2f x %.2f" :format avail-size-w avail-size-h)))
        (do
          (ImGui.Text ctx "(Hold SHIFT to display a dummy viewport)")
          (when (ImGui.IsWindowDocked ctx)
            (ImGui.Text ctx
                        "Warning: Sizing Constraints won't work if the window is docked!"))
          (when (ImGui.Button ctx "Set 200x200")
            (ImGui.SetWindowSize ctx 200 200))
          (ImGui.SameLine ctx)
          (when (ImGui.Button ctx "Set 500x500")
            (ImGui.SetWindowSize ctx 500 500))
          (ImGui.SameLine ctx)
          (when (ImGui.Button ctx "Set 800x200")
            (ImGui.SetWindowSize ctx 800 200))
          (ImGui.SetNextItemWidth ctx (* (ImGui.GetFontSize ctx) 20))
          (update-2nd app.constrained_resize.type
                      (ImGui.Combo ctx :Constraint $
                                   "Between 100x100 and 500x500\0\z
                                   At least 100x100\0\z
                                   Resize vertical only\0\z
                                   Resize horizontal only\0\z
                                   Width Between 400 and 500\0"))

          ;;Custom: Aspect Ratio 16:9\0\z
          ;;Custom: Always Square\0\z
          ;;Custom: Fixed Steps (100)\0')
          (ImGui.SetNextItemWidth ctx (* (ImGui.GetFontSize ctx) 20))
          (update-2nd app.constrained_resize.display_lines (ImGui.DragInt ctx :Lines $ 0.2 1 100))
          (update-2nd app.constrained_resize.auto_resize (ImGui.Checkbox ctx :Auto-resize $))
          (update-2nd app.constrained_resize.window_padding (ImGui.Checkbox ctx "Window padding" $))
          (for [i 1 app.constrained_resize.display_lines]
            (ImGui.Text ctx (: "%sHello, sailor! Making this line long enough for the example."
                               :format (: " " :rep (* i 4)))))))
      (ImGui.End ctx))
    open))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Simple overlay / ShowExampleAppSimpleOverlay()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate creating a simple static window with no decoration
;; + a context;menu to choose which corner of the screen to use.
(fn demo.ShowExampleAppSimpleOverlay []
  (set-when-not app.simple_overlay {:location 0})
  (var window-flags (bor (ImGui.WindowFlags_NoDecoration)
                         (ImGui.WindowFlags_NoDocking)
                         (ImGui.WindowFlags_AlwaysAutoResize)
                         (ImGui.WindowFlags_NoSavedSettings)
                         (ImGui.WindowFlags_NoFocusOnAppearing)
                         (ImGui.WindowFlags_NoNav)))
  (if
    (>= app.simple_overlay.location 0)
    (let [PAD 10
          viewport (ImGui.GetMainViewport ctx)
          (work-pos-x work-pos-y) (ImGui.Viewport_GetWorkPos viewport) ;; Use work area to avoid menu-bar/task-bar, if any!
          (work-size-w work-size-h) (ImGui.Viewport_GetWorkSize viewport)
          window-pos-x (or (and (not= (band app.simple_overlay.location 1) 0)
                                (- (+ work-pos-x work-size-w) PAD))
                           (+ work-pos-x PAD))
          window-pos-y (or (and (not= (band app.simple_overlay.location 2) 0)
                                (- (+ work-pos-y work-size-h) PAD))
                           (+ work-pos-y PAD))
          window-pos-pivot-x (if (= 0 (band 1 app.simple_overlay.location))
                               0 1)
          window-pos-pivot-y (if (= 0 (band 2 app.simple_overlay.location))
                               0 1)]
      (ImGui.SetNextWindowPos ctx window-pos-x window-pos-y
                              (ImGui.Cond_Always) window-pos-pivot-x
                              window-pos-pivot-y)

      ;; ImGui::SetNextWindowViewport(viewport->ID) TODO?
      (set window-flags (bor window-flags (ImGui.WindowFlags_NoMove))))

    ;; Center window
    (= app.simple_overlay.location -2)
    (let [(center-x center-y) (ImGui.Viewport_GetCenter (ImGui.GetMainViewport ctx))]
      (ImGui.SetNextWindowPos ctx center-x center-y (ImGui.Cond_Always) 0.5
                              0.5)
      (set window-flags (bor window-flags (ImGui.WindowFlags_NoMove)))))

  (ImGui.SetNextWindowBgAlpha ctx 0.35) ;; Transparent background

  (var (rv open) (ImGui.Begin ctx "Example: Simple overlay" true window-flags))
  (when (not rv) (lua "return open"))
  (ImGui.Text ctx "Simple overlay\n(right-click to change position)")
  (ImGui.Separator ctx)
  (if (ImGui.IsMousePosValid ctx)
    (ImGui.Text ctx (: "Mouse Position: (%.1f,%.1f)" :format (ImGui.GetMousePos ctx)))
    (ImGui.Text ctx "Mouse Position: <invalid>"))
  (when (ImGui.BeginPopupContextWindow ctx)
    (when (ImGui.MenuItem ctx :Custom nil (= app.simple_overlay.location -1))
      (set app.simple_overlay.location -1))
    (when (ImGui.MenuItem ctx :Center nil (= app.simple_overlay.location -2))
      (set app.simple_overlay.location -2))
    (when (ImGui.MenuItem ctx :Top-left nil (= app.simple_overlay.location 0))
      (set app.simple_overlay.location 0))
    (when (ImGui.MenuItem ctx :Top-right nil (= app.simple_overlay.location 1))
      (set app.simple_overlay.location 1))
    (when (ImGui.MenuItem ctx :Bottom-left nil (= app.simple_overlay.location 2))
      (set app.simple_overlay.location 2))
    (when (ImGui.MenuItem ctx :Bottom-right nil (= app.simple_overlay.location 3))
      (set app.simple_overlay.location 3))
    (when (ImGui.MenuItem ctx :Close)
      (set open false))
    (ImGui.EndPopup ctx))
  (ImGui.End ctx)
  open)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Fullscreen window / ShowExampleAppFullscreen()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate creating a window covering the entire screen/viewport
(fn demo.ShowExampleAppFullscreen []
  (when (not app.fullscreen)
    (set app.fullscreen {:flags (bor (ImGui.WindowFlags_NoDecoration)
                                     (ImGui.WindowFlags_NoMove)
                                     (ImGui.WindowFlags_NoSavedSettings))
                         :use_work_area true}))
  ;; We demonstrate using the full viewport area or the work area (without menu-bars, task-bars etc.)
  ;; Based on your use case you may want one or the other.
  (local viewport (ImGui.GetMainViewport ctx))
  (local get-viewport-pos (if app.fullscreen.use_work_area
                            ImGui.Viewport_GetWorkPos
                            ImGui.Viewport_GetPos))
  (local get-viewport-size
         (or (and app.fullscreen.use_work_area ImGui.Viewport_GetWorkSize)
             ImGui.Viewport_GetSize))
  (ImGui.SetNextWindowPos ctx (get-viewport-pos viewport))
  (ImGui.SetNextWindowSize ctx (get-viewport-size viewport))
  (var (rv open) (ImGui.Begin ctx "Example: Fullscreen window" true app.fullscreen.flags))
  (when rv
    (set (rv app.fullscreen.use_work_area)
         (ImGui.Checkbox ctx "Use work area instead of main area"
                         app.fullscreen.use_work_area))
    (ImGui.SameLine ctx)
    (demo.HelpMarker "Main Area = entire viewport,
    Work Area = entire viewport minus sections used by the main menu bars, task bars etc.

    Enable the main-menu bar in Examples menu to see the difference.")
    (update-2nd app.fullscreen.flags (ImGui.CheckboxFlags ctx :ImGuiWindowFlags_NoBackground $ (ImGui.WindowFlags_NoBackground)))
    (update-2nd app.fullscreen.flags (ImGui.CheckboxFlags ctx :ImGuiWindowFlags_NoDecoration $ (ImGui.WindowFlags_NoDecoration)))
    (ImGui.Indent ctx)
    (update-2nd app.fullscreen.flags (ImGui.CheckboxFlags ctx :ImGuiWindowFlags_NoTitleBar $ (ImGui.WindowFlags_NoTitleBar)))
    (update-2nd app.fullscreen.flags (ImGui.CheckboxFlags ctx :ImGuiWindowFlags_NoCollapse $ (ImGui.WindowFlags_NoCollapse)))
    (update-2nd app.fullscreen.flags (ImGui.CheckboxFlags ctx :ImGuiWindowFlags_NoScrollbar $ (ImGui.WindowFlags_NoScrollbar)))
    (ImGui.Unindent ctx)
    (when (ImGui.Button ctx "Close this window")
      (set open false))
    (ImGui.End ctx))
  open)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Manipulating window titles / ShowExampleAppWindowTitles()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate the use of "##" and "###" in identifiers to manipulate ID generation.
;; This applies to all regular items as well.
;; Read FAQ section "How can I have multiple widgets with the same label?" for details.
(fn demo.ShowExampleAppWindowTitles []
  (let [viewport (ImGui.GetMainViewport ctx)
        base-pos [(ImGui.Viewport_GetPos viewport)]]
    ;; By default, Windows are uniquely identified by their title.
    ;; You can use the "##" and "###" markers to manipulate the display/ID.

    ;; Using "##" to display same title but have unique identifier.
    (ImGui.SetNextWindowPos ctx
                            (+ (. base-pos 1) 100)
                            (+ (. base-pos 2) 100)
                            (ImGui.Cond_FirstUseEver))
    (when (ImGui.Begin ctx "Same title as another window##1")
      (ImGui.Text ctx "This is window 1.
My title is the same as window 2, but my identifier is unique.")
      (ImGui.End ctx))
    (ImGui.SetNextWindowPos ctx
                            (+ (. base-pos 1) 100)
                            (+ (. base-pos 2) 200)
                            (ImGui.Cond_FirstUseEver))
    (when (ImGui.Begin ctx "Same title as another window##2")
      (ImGui.Text ctx "This is window 2.
My title is the same as window 1, but my identifier is unique.")
      (ImGui.End ctx))

    ;; Using "###" to display a changing title but keep a static identifier "AnimatedTitle"
    (ImGui.SetNextWindowPos ctx (+ (. base-pos 1) 100) (+ (. base-pos 2) 300)
                             (ImGui.Cond_FirstUseEver))
    (global spinners ["|" "/" "-" "\\"])
    (local spinner (-> (ImGui.GetTime ctx)
                       (/ 0.25)
                       math.floor
                       (band 3)))
    (when (ImGui.Begin ctx (: "Animated title %s %d###AnimatedTitle" :format
                              (. spinners (+ spinner 1)) (ImGui.GetFrameCount ctx)))
      (ImGui.Text ctx "This window has a changing title.")
      (ImGui.End ctx))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; [SECTION] Example App: Custom Rendering using ImDrawList API / ShowExampleAppCustomRendering()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Demonstrate using the low-level ImDrawList to draw custom shapes.
(fn demo.ShowExampleAppCustomRendering []
  (when (not app.rendering)
    (set app.rendering {:adding_line false
                        :circle_segments_override false
                        :circle_segments_override_v 12
                        :col 0xffff66ff
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
  (var (rv open) (ImGui.Begin ctx "Example: Custom rendering" true))
  (when (not rv) (lua "return open"))
  (when (ImGui.BeginTabBar ctx "##TabBar")
    (when (ImGui.BeginTabItem ctx :Primitives)
      (ImGui.PushItemWidth ctx (* (- (ImGui.GetFontSize ctx)) 15))
      (local draw-list (ImGui.GetWindowDrawList ctx))
      ;; Draw gradients
      ;; (note that those are currently exacerbating our sRGB/Linear issues)
      ;; Calling ImGui.GetColor[Ex]() multiplies the given colors by the current Style Alpha
      (ImGui.Text ctx :Gradients)
      (local gradient-size
             [(ImGui.CalcItemWidth ctx) (ImGui.GetFrameHeight ctx)])
      (local p0 [(ImGui.GetCursorScreenPos ctx)])
      (local p1 [(+ (. p0 1) (. gradient-size 1))
                 (+ (. p0 2) (. gradient-size 2))])
      (local col-a (ImGui.GetColorEx ctx 0x00FF00FF))
      (local col-b (ImGui.GetColorEx ctx 0xFF0000FF))
      (ImGui.DrawList_AddRectFilledMultiColor draw-list
                                              (. p0 1) (. p0 2)
                                              (. p1 1) (. p1 2)
                                              col-a col-b
                                              col-b col-a)
      (ImGui.InvisibleButton ctx "##gradient1" (. gradient-size 1) (. gradient-size 2))
      (local p0 [(ImGui.GetCursorScreenPos ctx)])
      (local p1 [(+ (. p0 1) (. gradient-size 1))
                 (+ (. p0 2) (. gradient-size 2))])
      (local col-a (ImGui.GetColorEx ctx 16711935))
      (local col-b (ImGui.GetColorEx ctx 4278190335))
      (ImGui.DrawList_AddRectFilledMultiColor draw-list (. p0 1) (. p0 2)
                                               (. p1 1) (. p1 2) col-a col-b
                                               col-b col-a)
      (ImGui.InvisibleButton ctx "##gradient2" (. gradient-size 1)
                              (. gradient-size 2))
      ;; Draw a bunch of primitives
      (local item-inner-spacing-x
             (ImGui.GetStyleVar ctx (ImGui.StyleVar_ItemInnerSpacing)))
      (ImGui.Text ctx "All primitives")
      (update-2nd app.rendering.sz (ImGui.DragDouble ctx :Size $ 0.2 2 100 "%.0f"))
      (update-2nd app.rendering.thickness (ImGui.DragDouble ctx :Thickness $ 0.05 1 8 "%.02f"))
      (update-2nd app.rendering.ngon_sides (ImGui.SliderInt ctx "N-gon sides" $ 3 12))
      (update-2nd app.rendering.circle_segments_override (ImGui.Checkbox ctx "##circlesegmentoverride" $))
      (ImGui.SameLine ctx 0 item-inner-spacing-x)
      (set (rv app.rendering.circle_segments_override_v)
           (ImGui.SliderInt ctx "Circle segments override"
                             app.rendering.circle_segments_override_v 3 40))
      (when rv (set app.rendering.circle_segments_override true))
      (update-2nd app.rendering.curve_segments_override (ImGui.Checkbox ctx "##curvessegmentoverride" $))
      (ImGui.SameLine ctx 0 item-inner-spacing-x)
      (set (rv app.rendering.curve_segments_override_v)
           (ImGui.SliderInt ctx "Curves segments override"
                             app.rendering.curve_segments_override_v 3 40))
      (when rv (set app.rendering.curve_segments_override true))
      (update-2nd app.rendering.col (ImGui.ColorEdit4 ctx :Color $))

      (local p [(ImGui.GetCursorScreenPos ctx)])
      (local spacing 10)
      (local corners-tl-br
             (bor (ImGui.DrawFlags_RoundCornersTopLeft)
                  (ImGui.DrawFlags_RoundCornersBottomRight)))
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
        ;; First line uses a thickness of 1.0, second line uses the configurable thickness
        (local th (or (and (= n 1) 1) app.rendering.thickness))
        ;; N-gon
        (ImGui.DrawList_AddNgon draw-list (+ x (* sz 0.5)) (+ y (* sz 0.5))
                                (* sz 0.5) col app.rendering.ngon_sides th)
        (set x (+ (+ x sz) spacing))
        ;; Circle
        (ImGui.DrawList_AddCircle draw-list (+ x (* sz 0.5)) (+ y (* sz 0.5))
                                   (* sz 0.5) col circle-segments th)
        (set x (+ (+ x sz) spacing))
        ;; Square
        (ImGui.DrawList_AddRect draw-list x y (+ x sz) (+ y sz) col 0
                                 (ImGui.DrawFlags_None) th)
        (set x (+ (+ x sz) spacing))
        ;; Square with all rounded corners
        (ImGui.DrawList_AddRect draw-list x y (+ x sz) (+ y sz) col rounding
                                 (ImGui.DrawFlags_None) th)
        (set x (+ (+ x sz) spacing))
        ;; Square with two rounded corners
        (ImGui.DrawList_AddRect draw-list x y (+ x sz) (+ y sz) col rounding
                                 corners-tl-br th)
        (set x (+ (+ x sz) spacing))
        ;; Triangle

        (ImGui.DrawList_AddTriangle draw-list (+ x (* sz 0.5)) y (+ x sz)
                                     (- (+ y sz) 0.5) x (- (+ y sz) 0.5) col th)
        (set x (+ (+ x sz) spacing))
        ;; ImGui.DrawList_AddTriangle(draw_list, x+sz*0.2, y, x, y+sz-0.5, x+sz*0.4, y+sz-0.5, col, th);      x = x + sz*0.4 + spacing -- Thin triangle
        ;; Horizontal line (note: drawing a filled rectangle will be faster!)
        (ImGui.DrawList_AddLine draw-list x y (+ x sz) y col th)
        (set x (+ (+ x sz) spacing))
        ;; Vertical line (note: drawing a filled rectangle will be faster!)
        (ImGui.DrawList_AddLine draw-list x y x (+ y sz) col th)
        (set x (+ x spacing))
        ;; Diagonal line
        (ImGui.DrawList_AddLine draw-list x y (+ x sz) (+ y sz) col th)
        (set x (+ (+ x sz) spacing))

        ;; Quadratic Bezier Curve (3 control points)
        (local cp3 [[x (+ y (* sz 0.6))]
                    [(+ x (* sz 0.5)) (- y (* sz 0.4))]
                    [(+ x sz) (+ y sz)]])
        (ImGui.DrawList_AddBezierQuadratic draw-list
                                           (. (. cp3 1) 1)
                                           (. (. cp3 1) 2)
                                           (. (. cp3 2) 1)
                                           (. (. cp3 2) 2)
                                           (. (. cp3 3) 1)
                                           (. (. cp3 3) 2) col th
                                           curve-segments)
        (set x (+ x sz spacing))

        ;; Cubic Bezier Curve (4 control points)
        (local cp4 [[x y]
                    [(+ x (* sz 1.3)) (+ y (* sz 0.3))]
                    [(- (+ x sz) (* sz 1.3)) (- (+ y sz) (* sz 0.3))]
                    [(+ x sz) (+ y sz)]])
        (ImGui.DrawList_AddBezierCubic draw-list 
                                       (. (. cp4 1) 1)
                                       (. (. cp4 1) 2)
                                       (. (. cp4 2) 1)
                                       (. (. cp4 2) 2)
                                       (. (. cp4 3) 1)
                                       (. (. cp4 3) 2)
                                       (. (. cp4 4) 1)
                                       (. (. cp4 4) 2) col th curve-segments)
        (set x (+ (. p 1) 4))
        (set y (+ (+ y sz) spacing)))
      (ImGui.DrawList_AddNgonFilled draw-list (+ x (* sz 0.5))
                                     (+ y (* sz 0.5)) (* sz 0.5) col
                                     app.rendering.ngon_sides)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddCircleFilled draw-list (+ x (* sz 0.5))
                                       (+ y (* sz 0.5)) (* sz 0.5) col
                                       circle-segments)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz) col)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz) col 10)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x sz) (+ y sz) col 10
                                     corners-tl-br)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddTriangleFilled draw-list (+ x (* sz 0.5)) y (+ x sz)
                                         (- (+ y sz) 0.5) x (- (+ y sz) 0.5) col)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x sz)
                                     (+ y app.rendering.thickness) col)
      (set x (+ (+ x sz) spacing))
      (ImGui.DrawList_AddRectFilled draw-list x y
                                     (+ x app.rendering.thickness) (+ y sz) col)
      (set x (+ x (* spacing 2)))
      (ImGui.DrawList_AddRectFilled draw-list x y (+ x 1) (+ y 1) col)
      (set x (+ x sz))
      (ImGui.DrawList_AddRectFilledMultiColor draw-list x y (+ x sz) (+ y sz)
                                               255 4278190335 4294902015
                                               16711935)
      (ImGui.Dummy ctx (* (+ sz spacing) 10.2) (* (+ sz spacing) 3))
      (ImGui.PopItemWidth ctx)
      (ImGui.EndTabItem ctx))
    (when (ImGui.BeginTabItem ctx :Canvas)
      (set (rv app.rendering.opt_enable_grid)
           (ImGui.Checkbox ctx "Enable grid" app.rendering.opt_enable_grid))
      (set (rv app.rendering.opt_enable_context_menu)
           (ImGui.Checkbox ctx "Enable context menu"
                            app.rendering.opt_enable_context_menu))
      (ImGui.Text ctx "Mouse Left: drag to add lines,
Mouse Right: drag to scroll, click for context menu.")
      (local canvas-p0 [(ImGui.GetCursorScreenPos ctx)])
      (local canvas-sz [(ImGui.GetContentRegionAvail ctx)])
      (when (< (. canvas-sz 1) 50) (tset canvas-sz 1 50))
      (when (< (. canvas-sz 2) 50) (tset canvas-sz 2 50))
      (local canvas-p1
             [(+ (. canvas-p0 1) (. canvas-sz 1))
              (+ (. canvas-p0 2) (. canvas-sz 2))])
      (local mouse-pos [(ImGui.GetMousePos ctx)])
      (local draw-list (ImGui.GetWindowDrawList ctx))
      (ImGui.DrawList_AddRectFilled draw-list (. canvas-p0 1) (. canvas-p0 2)
                                     (. canvas-p1 1) (. canvas-p1 2) 842150655)
      (ImGui.DrawList_AddRect draw-list (. canvas-p0 1) (. canvas-p0 2)
                               (. canvas-p1 1) (. canvas-p1 2) 4294967295)
      (ImGui.InvisibleButton ctx :canvas (. canvas-sz 1) (. canvas-sz 2)
                              (bor (ImGui.ButtonFlags_MouseButtonLeft)
                                   (ImGui.ButtonFlags_MouseButtonRight)))
      (local is-hovered (ImGui.IsItemHovered ctx))
      (local is-active (ImGui.IsItemActive ctx))
      (local origin
             [(+ (. canvas-p0 1) (. app.rendering.scrolling 1))
              (+ (. canvas-p0 2) (. app.rendering.scrolling 2))])
      (local mouse-pos-in-canvas
             [(- (. mouse-pos 1) (. origin 1))
              (- (. mouse-pos 2) (. origin 2))])
      (when (and (and is-hovered (not app.rendering.adding_line))
                 (ImGui.IsMouseClicked ctx (ImGui.MouseButton_Left)))
        (table.insert app.rendering.points mouse-pos-in-canvas)
        (table.insert app.rendering.points mouse-pos-in-canvas)
        (set app.rendering.adding_line true))
      (when app.rendering.adding_line
        (tset app.rendering.points (length app.rendering.points)
              mouse-pos-in-canvas)
        (when (not (ImGui.IsMouseDown ctx (ImGui.MouseButton_Left)))
          (set app.rendering.adding_line false)))
      (local mouse-threshold-for-pan
             (or (and app.rendering.opt_enable_context_menu (- 1)) 0))
      (when (and is-active
                 (ImGui.IsMouseDragging ctx (ImGui.MouseButton_Right)
                                         mouse-threshold-for-pan))
        (local mouse-delta [(ImGui.GetMouseDelta ctx)])
        (tset app.rendering.scrolling 1
              (+ (. app.rendering.scrolling 1) (. mouse-delta 1)))
        (tset app.rendering.scrolling 2
              (+ (. app.rendering.scrolling 2) (. mouse-delta 2))))

      (fn remove-last-line [] (table.remove app.rendering.points)
        (table.remove app.rendering.points))

      (local drag-delta
             [(ImGui.GetMouseDragDelta ctx 0 0 (ImGui.MouseButton_Right))])
      (when (and (and app.rendering.opt_enable_context_menu
                      (= (. drag-delta 1) 0))
                 (= (. drag-delta 2) 0))
        (ImGui.OpenPopupOnItemClick ctx :context
                                     (ImGui.PopupFlags_MouseButtonRight)))
      (when (ImGui.BeginPopup ctx :context)
        (when app.rendering.adding_line (remove-last-line)
          (set app.rendering.adding_line false))
        (when (ImGui.MenuItem ctx "Remove one" nil false
                               (> (length app.rendering.points) 0))
          (remove-last-line))
        (when (ImGui.MenuItem ctx "Remove all" nil false
                               (> (length app.rendering.points) 0))
          (set app.rendering.points {}))
        (ImGui.EndPopup ctx))
      (ImGui.DrawList_PushClipRect draw-list (. canvas-p0 1) (. canvas-p0 2)
                                    (. canvas-p1 1) (. canvas-p1 2) true)
      (when app.rendering.opt_enable_grid
        (local GRID_STEP 64)
        (var x (math.fmod (. app.rendering.scrolling 1) GRID_STEP))
        (while (< x (. canvas-sz 1))
          (ImGui.DrawList_AddLine draw-list (+ (. canvas-p0 1) x)
                                   (. canvas-p0 2) (+ (. canvas-p0 1) x)
                                   (. canvas-p1 2) 3368601640)
          (set x (+ x GRID_STEP)))
        (var y (math.fmod (. app.rendering.scrolling 2) GRID_STEP))
        (while (< y (. canvas-sz 2))
          (ImGui.DrawList_AddLine draw-list (. canvas-p0 1)
                                   (+ (. canvas-p0 2) y) (. canvas-p1 1)
                                   (+ (. canvas-p0 2) y) 3368601640)
          (set y (+ y GRID_STEP))))
      (var n 1)
      (while (< n (length app.rendering.points))
        (ImGui.DrawList_AddLine draw-list
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
      (ImGui.DrawList_PopClipRect draw-list)
      (ImGui.EndTabItem ctx))
    (when (ImGui.BeginTabItem ctx "BG/FG draw lists")
      (set (rv app.rendering.draw_bg)
           (ImGui.Checkbox ctx "Draw in Background draw list"
                            app.rendering.draw_bg))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "The Background draw list will be rendered below every Dear ImGui windows.")
      (set (rv app.rendering.draw_fg)
           (ImGui.Checkbox ctx "Draw in Foreground draw list"
                            app.rendering.draw_fg))
      (ImGui.SameLine ctx)
      (demo.HelpMarker "The Foreground draw list will be rendered over every Dear ImGui windows.")
      (local window-pos [(ImGui.GetWindowPos ctx)])
      (local window-size [(ImGui.GetWindowSize ctx)])
      (local window-center
             [(+ (. window-pos 1) (* (. window-size 1) 0.5))
              (+ (. window-pos 2) (* (. window-size 2) 0.5))])
      (when app.rendering.draw_bg
        (ImGui.DrawList_AddCircle (ImGui.GetBackgroundDrawList ctx)
                                   (. window-center 1) (. window-center 2)
                                   (* (. window-size 1) 0.6) 4278190280 nil
                                   (+ 10 4)))
      (when app.rendering.draw_fg
        (ImGui.DrawList_AddCircle (ImGui.GetForegroundDrawList ctx)
                                   (. window-center 1) (. window-center 2)
                                   (* (. window-size 2) 0.6) 16711880 nil 10))
      (ImGui.EndTabItem ctx))
    (ImGui.EndTabBar ctx))
  (ImGui.End ctx)
  open)

(collect [_ f (ipairs [:ShowDemoWindow :ShowStyleEditor :PushStyle :PopStyle])]
  f (fn [user-ctx ...]
      (set ctx user-ctx)
      ((. demo f) ...)))
