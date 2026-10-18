import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: root

  property bool open: false
  property bool _ready: false
  property bool previewMode: false
  property string activeCategory: "theme"
  property string searchQuery: ""
  property bool confirmResetAll: false

  // Auto-discovered system hardware paths
  property var discoveredHwmonSensors: []
  property var discoveredBacklights: []

  signal dismissed()

  Component.onCompleted: {
    Qt.callLater(() => { root._ready = true })
    hwmonProbeProc.running = true
    backlightProbeProc.running = true
  }

  // Probe available /sys/class/hwmon sensors with human-readable chip names
  Process {
    id: hwmonProbeProc
    command: [
      "sh", "-c",
      "for f in /sys/class/hwmon/hwmon*/temp*_input; do "
      + "[ -f \"$f\" ] || continue; "
      + "dir=$(dirname \"$f\"); "
      + "name=$(cat \"$dir/name\" 2>/dev/null || basename \"$dir\"); "
      + "val=$(cat \"$f\" 2>/dev/null || echo 0); "
      + "deg=$((val / 1000)); "
      + "printf '%s|%s (%d°C)\\n' \"$f\" \"$name\" \"$deg\"; "
      + "done"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n").filter(l => l.length > 0)
        const list = []
        for (const l of lines) {
          const idx = l.indexOf("|")
          if (idx > 0) {
            list.push({ value: l.substring(0, idx), label: l.substring(idx + 1) })
          }
        }
        root.discoveredHwmonSensors = list
      }
    }
  }

  // Probe available /sys/class/backlight devices
  Process {
    id: backlightProbeProc
    command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null || true"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n").filter(l => l.length > 0)
        const list = [{ label: "Auto-detect", value: "" }]
        for (const d of lines) {
          list.push({ label: d, value: d })
        }
        root.discoveredBacklights = list
      }
    }
  }

  // ── Navigation Categories ──
  readonly property var categories: [
    { id: "theme",         icon: "palette",        label: "Theme & Colors",      subtitle: "Material You schemes, contrast, seed color & wallpaper" },
    { id: "typography",    icon: "text_fields",    label: "Typography & General", subtitle: "Fonts, base text scale, terminal & screenshot command" },
    { id: "geometry",      icon: "rounded_corner", label: "Frame & Geometry",     subtitle: "Bar height, screen border, notch radii & layout spacing" },
    { id: "motion",        icon: "animation",      label: "Motion & Animation",   subtitle: "Transition durations, spring elasticity & motion toggle" },
    { id: "bar",           icon: "web_asset",      label: "Top Bar & Workspaces", subtitle: "Bar widgets, workspaces, clock format, tray & thresholds" },
    { id: "drawers",       icon: "dock_to_bottom", label: "Drawers & Popups",     subtitle: "Top drawer, control center, hot corner & quick sliders" },
    { id: "notifications", icon: "notifications",  label: "Notifications",        subtitle: "Do Not Disturb, popup timeouts, history limit & toast size" },
    { id: "widgets",       icon: "widgets",        label: "Widgets & Overlays",   subtitle: "Desktop clock, to-do list, app launcher & clipboard" },
    { id: "system",        icon: "settings_power", label: "Power & Hardware",     subtitle: "Power menu commands, CPU/GPU polling, sensors & backlight" }
  ]

  // ── Complete Declarative Configuration Schema ──
  readonly property var settingsSchema: [
    // 1. THEME & COLORS
    {
      key: "wallScheme", category: "theme", section: "Material You Palette Generation",
      title: "Color Scheme Variant", subtitle: "Matugen Material Design 3 tonal palette algorithm (-t)",
      icon: "style", type: "chips",
      presets: [
        { label: "Tonal Spot",  value: "scheme-tonal-spot" },
        { label: "Vibrant",     value: "scheme-vibrant" },
        { label: "Expressive",  value: "scheme-expressive" },
        { label: "Content",     value: "scheme-content" },
        { label: "Fidelity",    value: "scheme-fidelity" },
        { label: "Neutral",     value: "scheme-neutral" },
        { label: "Monochrome",  value: "scheme-monochrome" },
        { label: "Rainbow",     value: "scheme-rainbow" },
        { label: "Fruit Salad", value: "scheme-fruit-salad" }
      ]
    },
    {
      key: "matugenMode", category: "theme", section: "Material You Palette Generation",
      title: "Theme Polarity Mode", subtitle: "Target luminance mode when generating colors with Matugen (-m)",
      icon: "dark_mode", type: "chips",
      presets: [
        { label: "Dark Mode",  value: "dark" },
        { label: "Light Mode", value: "light" }
      ]
    },
    {
      key: "wallContrast", category: "theme", section: "Material You Palette Generation",
      title: "Palette Contrast Level", subtitle: "Adjust Material 3 tonal contrast from -1.0 (reduced) to +1.0 (high contrast)",
      icon: "contrast", type: "real", min: -1.0, max: 1.0, step: 0.05, decimals: 2, unit: ""
    },
    {
      key: "wallUseCustom", category: "theme", section: "Seed Color Selection",
      title: "Use Custom Hex Seed Color", subtitle: "Generate Material You palette from a custom hex color instead of wallpaper extraction",
      icon: "colorize", type: "bool"
    },
    {
      key: "wallSourceIndex", category: "theme", section: "Seed Color Selection",
      title: "Wallpaper Extracted Color Index", subtitle: "Which dominant color extracted from the wallpaper Matugen uses (--source-color-index)",
      icon: "filter_1", type: "chips",
      presets: [
        { label: "Auto (Primary)", value: 0 },
        { label: "Color 2",        value: 1 },
        { label: "Color 3",        value: 2 },
        { label: "Color 4",        value: 3 }
      ]
    },
    {
      key: "wallCustomColor", category: "theme", section: "Seed Color Selection",
      title: "Custom Seed Color (Hex)", subtitle: "6-digit hex color used when Custom Hex Seed Color is active (e.g. #6750a4)",
      icon: "tag", type: "color",
      presets: [
        { label: "M3 Purple",  value: "#6750a4" },
        { label: "Amber Gold", value: "#eec148" },
        { label: "Emerald",    value: "#2e7d32" },
        { label: "Ocean Blue", value: "#0061a4" },
        { label: "Crimson",    value: "#b3261e" },
        { label: "Teal",       value: "#006a6a" }
      ]
    },
    {
      key: "wallpaperDir", category: "theme", section: "Wallpaper Paths",
      title: "Wallpapers Directory", subtitle: "Folder recursively scanned by the Wallpaper Switcher",
      icon: "folder_open", type: "string"
    },
    {
      key: "currentWallpaperFile", category: "theme", section: "Wallpaper Paths",
      title: "Applied Wallpaper Cache Path", subtitle: "Target file where the active wallpaper is copied for Matugen/lockscreen use",
      icon: "image", type: "string"
    },

    // 2. TYPOGRAPHY & GENERAL
    {
      key: "font", category: "typography", section: "Typography",
      title: "Primary UI Font Family", subtitle: "Default typeface used across bars, drawers, notifications, and dialogs",
      icon: "font_download", type: "string",
      presets: [
        { label: "Maven Pro",             value: "Maven Pro" },
        { label: "JetBrainsMono NF",      value: "JetBrainsMono Nerd Font" },
        { label: "Maple Mono NF CN",      value: "Maple Mono NF CN" },
        { label: "Inter",                 value: "Inter" },
        { label: "Roboto",                value: "Roboto" },
        { label: "Noto Sans",             value: "Noto Sans" }
      ]
    },
    {
      key: "iconFont", category: "typography", section: "Typography",
      title: "Material Icon Font Family", subtitle: "Glyph font used by Icon components throughout the shell",
      icon: "emoji_symbols", type: "string",
      presets: [
        { label: "Material Symbols Rounded",  value: "Material Symbols Rounded" },
        { label: "Material Symbols Outlined", value: "Material Symbols Outlined" },
        { label: "Material Symbols Sharp",    value: "Material Symbols Sharp" },
        { label: "JetBrainsMono NF",          value: "JetBrainsMono Nerd Font" }
      ]
    },
    {
      key: "fontSize", category: "typography", section: "Typography",
      title: "Base UI Font Size", subtitle: "Standard font size for buttons, workspace indicators, and sliders",
      icon: "format_size", type: "int", min: 10, max: 22, step: 1, unit: "px"
    },
    {
      key: "terminal", category: "typography", section: "Shell Commands & Defaults",
      title: "Fallback Terminal Emulator", subtitle: "Used by App Launcher for terminal entries when $TERMINAL is unset",
      icon: "terminal", type: "string",
      presets: [
        { label: "alacritty", value: "alacritty" },
        { label: "kitty",     value: "kitty" },
        { label: "foot",      value: "foot" },
        { label: "wezterm",   value: "wezterm" },
        { label: "ghostty",   value: "ghostty" }
      ]
    },
    {
      key: "screenshotCmd", category: "typography", section: "Shell Commands & Defaults",
      title: "Screenshot Action Command", subtitle: "Shell command run when clicking the camera icon in the Top Drawer",
      icon: "photo_camera", type: "string",
      presets: [
        { label: "Hyprshot Region / Grim", value: "hyprshot -m region || grim" },
        { label: "Hyprshot Window",        value: "hyprshot -m window" },
        { label: "Hyprshot Output",        value: "hyprshot -m output" },
        { label: "Grim + Slurp Clipboard", value: "grim -g \"$(slurp)\" - | wl-copy" }
      ]
    },

    // 3. FRAME & GEOMETRY
    {
      key: "pillHeight", category: "geometry", section: "Top Bar & Exclusive Zone",
      title: "Top Bar Height (pillHeight)", subtitle: "Height of the top bar strip and default window reservation",
      icon: "height", type: "int", min: 26, max: 64, step: 2, unit: "px"
    },
    {
      key: "reserveTopSynced", category: "geometry", section: "Top Bar & Exclusive Zone",
      title: "Sync Top Exclusive Zone with Bar Height", subtitle: "Automatically match reserved top screen space to pillHeight",
      icon: "sync", type: "bool"
    },
    {
      key: "reserveTopCustom", category: "geometry", section: "Top Bar & Exclusive Zone",
      title: "Custom Top Exclusive Zone", subtitle: "Reserved top screen space when Sync Top Exclusive Zone is disabled",
      icon: "vertical_align_top", type: "int", min: 0, max: 80, step: 2, unit: "px"
    },
    {
      key: "border", category: "geometry", section: "Screen Frame & Corner Radii",
      title: "Screen Frame Border Thickness", subtitle: "Thickness of the surrounding screen frame on left, right, and bottom edges",
      icon: "border_outer", type: "int", min: 0, max: 20, step: 1, unit: "px"
    },
    {
      key: "borderRadius", category: "geometry", section: "Screen Frame & Corner Radii",
      title: "Screen Frame Inner Corner Radius", subtitle: "Rounding radius of the inner screen cutout corners",
      icon: "rounded_corner", type: "int", min: 0, max: 40, step: 2, unit: "px"
    },
    {
      key: "panelRadius", category: "geometry", section: "Screen Frame & Corner Radii",
      title: "Panel & Notch Ear Radius", subtitle: "Concave ear radius and primary corner rounding on drawers and popups",
      icon: "looks", type: "int", min: 8, max: 48, step: 2, unit: "px"
    },
    {
      key: "notchRadius", category: "geometry", section: "Screen Frame & Corner Radii",
      title: "Notch Convex Corner Radius", subtitle: "Inner corner radius of top/bottom/side NotchShape panels",
      icon: "crop_free", type: "int", min: 4, max: 36, step: 2, unit: "px"
    },
    {
      key: "earRadius", category: "geometry", section: "Screen Frame & Corner Radii",
      title: "Bar Pill Corner Radius", subtitle: "Corner radius of Top Bar pills (System Tray, CPU/Temp badge)",
      icon: "pill", type: "int", min: 4, max: 24, step: 1, unit: "px"
    },
    {
      key: "pad", category: "geometry", section: "Global Spacing & Padding",
      title: "Global Container Padding (pad)", subtitle: "Standard internal padding inside panels, drawers, and bars",
      icon: "padding", type: "int", min: 8, max: 32, step: 2, unit: "px"
    },
    {
      key: "gap", category: "geometry", section: "Global Spacing & Padding",
      title: "Global Element Gap (gap)", subtitle: "Standard spacing between adjacent layout elements",
      icon: "space_bar", type: "int", min: 4, max: 20, step: 1, unit: "px"
    },

    // 4. MOTION & ANIMATIONS
    {
      key: "animationsEnabled", category: "motion", section: "Animation Engine",
      title: "Enable Shell Animations", subtitle: "Master switch for smooth spring and bezier transitions across all panels",
      icon: "motion_photos_on", type: "bool"
    },
    {
      key: "durFast", category: "motion", section: "Transition Durations",
      title: "Fast Animation Duration", subtitle: "Used for hover states, color transitions, and micro-interactions",
      icon: "bolt", type: "int", min: 40, max: 500, step: 10, unit: "ms"
    },
    {
      key: "durNormal", category: "motion", section: "Transition Durations",
      title: "Normal Animation Duration", subtitle: "Used for drawer slides, notch expansions, and modal open/close",
      icon: "speed", type: "int", min: 80, max: 800, step: 10, unit: "ms"
    },
    {
      key: "durSlow", category: "motion", section: "Transition Durations",
      title: "Slow Animation Duration", subtitle: "Used for slider percentage readouts and ambient transitions",
      icon: "hourglass_bottom", type: "int", min: 150, max: 1200, step: 25, unit: "ms"
    },
    {
      key: "springOvershoot", category: "motion", section: "Bezier Spring Physics",
      title: "Spring Overshoot Elasticity", subtitle: "Control point Y1 of Global.spring ([0.28, overshoot, 0.22, 1.0]) — 1.0 is no bounce",
      icon: "waves", type: "real", min: 1.0, max: 2.2, step: 0.05, decimals: 2, unit: "x"
    },

    // 5. TOP BAR & WORKSPACES
    {
      key: "barShowWorkspaces", category: "bar", section: "Bar Module Visibility",
      title: "Show Workspaces on Bar", subtitle: "Display Hyprland workspace pills on the left side of the top bar",
      icon: "view_carousel", type: "bool"
    },
    {
      key: "barShowClock", category: "bar", section: "Bar Module Visibility",
      title: "Show Centered Clock on Bar", subtitle: "Display the clock in the center of the top bar",
      icon: "schedule", type: "bool"
    },
    {
      key: "barShowSystemTray", category: "bar", section: "Bar Module Visibility",
      title: "Show System Tray on Bar", subtitle: "Display collapsible system tray icons on the right side of the top bar",
      icon: "dock", type: "bool"
    },
    {
      key: "barShowCpuInfo", category: "bar", section: "Bar Module Visibility",
      title: "Show CPU & Temperature Pill", subtitle: "Display live processor load and temperature on the top bar",
      icon: "memory", type: "bool"
    },
    {
      key: "barShowVolume", category: "bar", section: "Bar Module Visibility",
      title: "Show Volume Indicator", subtitle: "Display PipeWire audio volume and mute status on the top bar",
      icon: "volume_up", type: "bool"
    },
    {
      key: "barShowBattery", category: "bar", section: "Bar Module Visibility",
      title: "Show Battery Indicator", subtitle: "Display UPower battery icon and percentage on the top bar",
      icon: "battery_full", type: "bool"
    },
    {
      key: "barRightSpacing", category: "bar", section: "Bar Module Visibility",
      title: "Right Bar Group Spacing", subtitle: "Horizontal spacing between System Tray, CPU, Volume, and Battery",
      icon: "format_letter_spacing", type: "int", min: 4, max: 28, step: 2, unit: "px"
    },
    {
      key: "wsMinSlots", category: "bar", section: "Workspaces Indicator",
      title: "Minimum Workspace Slots", subtitle: "Always show at least this many numbered workspaces (1..N)",
      icon: "filter_4", type: "int", min: 1, max: 10, step: 1, unit: ""
    },
    {
      key: "wsSpacing", category: "bar", section: "Workspaces Indicator",
      title: "Workspace Pill Spacing", subtitle: "Gap between individual workspace indicator tiles",
      icon: "view_column", type: "int", min: 2, max: 20, step: 1, unit: "px"
    },
    {
      key: "wsShowSpecial", category: "bar", section: "Workspaces Indicator",
      title: "Show Special Workspaces (Scratchpads)", subtitle: "Display active Hyprland special:* workspaces next to regular workspaces",
      icon: "auto_awesome_mosaic", type: "bool"
    },
    {
      key: "barClockFormat", category: "bar", section: "Top Bar Clock",
      title: "Clock Time Format", subtitle: "Qt date/time format string for the top bar clock",
      icon: "access_time", type: "string",
      presets: [
        { label: "24h (HH:mm)",       value: "HH:mm" },
        { label: "12h (hh:mm)",       value: "hh:mm" },
        { label: "12h AM/PM",         value: "hh:mm AP" },
        { label: "With Seconds",      value: "HH:mm:ss" },
        { label: "Day + Time",        value: "ddd HH:mm" }
      ]
    },
    {
      key: "barClockFontSize", category: "bar", section: "Top Bar Clock",
      title: "Bar Clock Font Size", subtitle: "Font size of the centered time readout in the top bar",
      icon: "text_increase", type: "int", min: 11, max: 24, step: 1, unit: "px"
    },
    {
      key: "barClockShowDate", category: "bar", section: "Top Bar Clock",
      title: "Show Date Next to Bar Clock", subtitle: "Display a secondary formatted date label beside the time",
      icon: "calendar_today", type: "bool"
    },
    {
      key: "barClockDateFormat", category: "bar", section: "Top Bar Clock",
      title: "Bar Clock Date Format", subtitle: "Qt date format string shown when Show Date Next to Bar Clock is enabled",
      icon: "event", type: "string",
      presets: [
        { label: "ddd dd MMM",      value: "ddd dd MMM" },
        { label: "MMM d",           value: "MMM d" },
        { label: "dddd, d MMM",     value: "dddd, d MMM" },
        { label: "yyyy-MM-dd",      value: "yyyy-MM-dd" }
      ]
    },
    {
      key: "trayStartExpanded", category: "bar", section: "System Tray",
      title: "Expand System Tray by Default", subtitle: "Start the system tray pill in its expanded state on shell startup",
      icon: "unfold_more", type: "bool"
    },
    {
      key: "trayIconSize", category: "bar", section: "System Tray",
      title: "System Tray Icon Size", subtitle: "Width and height of each tray icon in pixels",
      icon: "apps", type: "int", min: 14, max: 28, step: 2, unit: "px"
    },
    {
      key: "trayIconSpacing", category: "bar", section: "System Tray",
      title: "System Tray Icon Spacing", subtitle: "Horizontal gap between icons inside the expanded tray",
      icon: "linear_scale", type: "int", min: 2, max: 16, step: 1, unit: "px"
    },
    {
      key: "barShowCpuTemp", category: "bar", section: "CPU, Volume & Battery",
      title: "Show CPU Temperature in Bar Pill", subtitle: "Include live °C readout next to CPU usage percentage",
      icon: "device_thermostat", type: "bool"
    },
    {
      key: "cpuWarnThreshold", category: "bar", section: "CPU, Volume & Battery",
      title: "CPU Usage Warning Threshold", subtitle: "Highlight CPU usage in error red above this percentage",
      icon: "warning", type: "int", min: 50, max: 100, step: 5, unit: "%"
    },
    {
      key: "tempWarnThreshold", category: "bar", section: "CPU, Volume & Battery",
      title: "CPU Temperature Warning Threshold", subtitle: "Highlight temperature in error red above this value (Bar & Top Drawer)",
      icon: "local_fire_department", type: "int", min: 50, max: 105, step: 5, unit: "°C"
    },
    {
      key: "volumeWheelStep", category: "bar", section: "CPU, Volume & Battery",
      title: "Volume Scroll Wheel Step", subtitle: "Fraction of volume adjusted per mouse wheel notch on the bar icon",
      icon: "tune", type: "real", min: 0.01, max: 0.20, step: 0.01, decimals: 2, unit: ""
    },
    {
      key: "batteryAlwaysShow", category: "bar", section: "CPU, Volume & Battery",
      title: "Force Show Battery on Desktop", subtitle: "Show the battery indicator even if UPower does not report a laptop battery",
      icon: "battery_unknown", type: "bool"
    },
    {
      key: "batteryHighThreshold", category: "bar", section: "CPU, Volume & Battery",
      title: "Battery High Color Threshold", subtitle: "Charge % at or above which battery uses Primary color",
      icon: "battery_charging_full", type: "int", min: 60, max: 100, step: 5, unit: "%"
    },
    {
      key: "batteryMedThreshold", category: "bar", section: "CPU, Volume & Battery",
      title: "Battery Medium Color Threshold", subtitle: "Charge % at or above which battery uses Tertiary color",
      icon: "battery_4_bar", type: "int", min: 30, max: 80, step: 5, unit: "%"
    },
    {
      key: "batteryLowThreshold", category: "bar", section: "CPU, Volume & Battery",
      title: "Battery Low Warning Threshold", subtitle: "Charge % below which battery switches to critical error container color",
      icon: "battery_alert", type: "int", min: 5, max: 40, step: 5, unit: "%"
    },

    // 6. DRAWERS & POPUPS
    {
      key: "topDrawerEnabled", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Enable Top Drawer on Clock Hover", subtitle: "Open the top dashboard notch when hovering the bar clock",
      icon: "vertical_align_bottom", type: "bool"
    },
    {
      key: "topDrawerWidth", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Top Drawer Content Width", subtitle: "Inner viewport width of the top drawer dashboard",
      icon: "swap_horiz", type: "int", min: 480, max: 860, step: 10, unit: "px"
    },
    {
      key: "topDrawerHeight", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Top Drawer Content Height", subtitle: "Inner viewport height of the top drawer dashboard",
      icon: "swap_vert", type: "int", min: 360, max: 680, step: 10, unit: "px"
    },
    {
      key: "topDrawerGridGap", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Top Drawer Grid Spacing", subtitle: "Gap between cards, tiles, and sliders inside the top drawer",
      icon: "grid_on", type: "int", min: 6, max: 20, step: 2, unit: "px"
    },
    {
      key: "topDrawerCardRadius", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Top Drawer Card Corner Radius", subtitle: "Rounding radius for tiles, media card, and system stats card",
      icon: "rounded_corner", type: "int", min: 8, max: 32, step: 2, unit: "px"
    },
    {
      key: "topDrawerHideDelay", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Top Drawer Hover Close Delay", subtitle: "Grace time before the top drawer starts closing after pointer leaves",
      icon: "timer", type: "int", min: 50, max: 1000, step: 50, unit: "ms"
    },
    {
      key: "mprisIgnoredPlayers", category: "drawers", section: "Top Media & Quick Settings Drawer",
      title: "Ignored MPRIS Players", subtitle: "Comma-separated player names ignored by MediaPanel (e.g. Blanket)",
      icon: "music_off", type: "string",
      presets: [
        { label: "Blanket", value: "Blanket" },
        { label: "Blanket, firefox", value: "Blanket, firefox" },
        { label: "None", value: "" }
      ]
    },
    {
      key: "controlCenterEnabled", category: "drawers", section: "Right Control Center & Hot Corner",
      title: "Enable Bottom-Right Hot Corner", subtitle: "Open the Control Center side panel when hovering the bottom-right corner",
      icon: "ads_click", type: "bool"
    },
    {
      key: "controlCenterWidth", category: "drawers", section: "Right Control Center & Hot Corner",
      title: "Control Center Content Width", subtitle: "Width of the notification & quick settings side panel",
      icon: "view_sidebar", type: "int", min: 320, max: 560, step: 10, unit: "px"
    },
    {
      key: "controlCenterHideDelay", category: "drawers", section: "Right Control Center & Hot Corner",
      title: "Control Center Hover Close Delay", subtitle: "Grace time before Control Center closes after pointer leaves",
      icon: "timer", type: "int", min: 50, max: 1000, step: 50, unit: "ms"
    },
    {
      key: "hotCornerSize", category: "drawers", section: "Right Control Center & Hot Corner",
      title: "Hot Corner Trigger Area Size", subtitle: "Width and height of the bottom-right hot corner hover zone",
      icon: "aspect_ratio", type: "int", min: 8, max: 60, step: 4, unit: "px"
    },
    {
      key: "quickSlidersEnabled", category: "drawers", section: "Right-Edge Quick Sliders Popup",
      title: "Enable Right-Edge Quick Sliders", subtitle: "Open vertical volume & brightness sliders when hovering the right screen edge",
      icon: "tune", type: "bool"
    },
    {
      key: "quickSlidersHeight", category: "drawers", section: "Right-Edge Quick Sliders Popup",
      title: "Individual Quick Slider Height", subtitle: "Vertical height of each slider inside the right-edge popup",
      icon: "height", type: "int", min: 100, max: 260, step: 10, unit: "px"
    },
    {
      key: "quickSlidersWidth", category: "drawers", section: "Right-Edge Quick Sliders Popup",
      title: "Quick Slider Thickness", subtitle: "Width of the vertical volume and brightness slider tracks",
      icon: "line_weight", type: "int", min: 28, max: 64, step: 2, unit: "px"
    },
    {
      key: "quickSlidersSpacing", category: "drawers", section: "Right-Edge Quick Sliders Popup",
      title: "Quick Sliders Vertical Gap", subtitle: "Spacing between the volume and brightness sliders",
      icon: "space_bar", type: "int", min: 4, max: 28, step: 2, unit: "px"
    },
    {
      key: "quickSlidersTriggerWidth", category: "drawers", section: "Right-Edge Quick Sliders Popup",
      title: "Right-Edge Hover Strip Extra Width", subtitle: "Additional hover trigger width beyond the screen border thickness",
      icon: "border_right", type: "int", min: 1, max: 16, step: 1, unit: "px"
    },

    // 7. NOTIFICATIONS
    {
      key: "notifDoNotDisturb", category: "notifications", section: "Do Not Disturb & Urgency",
      title: "Do Not Disturb (Focus Mode)", subtitle: "Silence incoming toast popups while keeping notifications in history",
      icon: "do_not_disturb_on", type: "bool"
    },
    {
      key: "notifAllowCriticalInDnd", category: "notifications", section: "Do Not Disturb & Urgency",
      title: "Allow Critical Notifications in DND", subtitle: "Show popup toasts for critical urgency notifications even when DND is on",
      icon: "priority_high", type: "bool"
    },
    {
      key: "notifDefaultTimeout", category: "notifications", section: "Toast Popups & History",
      title: "Default Popup Timeout", subtitle: "How long notification toasts stay on screen before auto-expiring",
      icon: "av_timer", type: "int", min: 1000, max: 15000, step: 500, unit: "ms"
    },
    {
      key: "notifHistoryLimit", category: "notifications", section: "Toast Popups & History",
      title: "Notification History Limit", subtitle: "Maximum number of past notifications retained in the Control Center",
      icon: "history", type: "int", min: 10, max: 200, step: 10, unit: "items"
    },
    {
      key: "notifToastWidth", category: "notifications", section: "Toast Popups & History",
      title: "Notification Toast Width", subtitle: "Width of incoming top-right notification popup cards",
      icon: "width_normal", type: "int", min: 260, max: 480, step: 10, unit: "px"
    },

    // 8. DESKTOP WIDGETS & OVERLAYS
    {
      key: "desktopClockEnabled", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Enable Desktop Clock Widget", subtitle: "Render the large stacked clock and date on the background layer",
      icon: "wallpaper", type: "bool"
    },
    {
      key: "desktopClock24h", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Use 24-Hour Format on Desktop Clock", subtitle: "Display hours in 00–23 format instead of 01–12",
      icon: "24mp", type: "bool"
    },
    {
      key: "desktopClockFont", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Desktop Clock Digits Font", subtitle: "Display typeface for the large stacked hour and minute digits",
      icon: "font_download", type: "string",
      presets: [
        { label: "Changa One",          value: "Changa One" },
        { label: "Rowdies Light",       value: "Rowdies Light" },
        { label: "Maven Pro",           value: "Maven Pro" },
        { label: "JetBrainsMono NF",    value: "JetBrainsMono Nerd Font" }
      ]
    },
    {
      key: "desktopClockFontSize", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Desktop Clock Digits Size", subtitle: "Font size of the large hour and minute numbers",
      icon: "format_size", type: "int", min: 80, max: 360, step: 10, unit: "px"
    },
    {
      key: "desktopClockDateFont", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Desktop Clock Date Font", subtitle: "Typeface used for the date line beneath the clock digits",
      icon: "text_fields", type: "string",
      presets: [
        { label: "Rowdies Light",       value: "Rowdies Light" },
        { label: "Changa One",          value: "Changa One" },
        { label: "Maven Pro",           value: "Maven Pro" },
        { label: "Maple Mono NF CN",    value: "Maple Mono NF CN" }
      ]
    },
    {
      key: "desktopClockDateSize", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Desktop Clock Date Font Size", subtitle: "Font size of the desktop date subtitle",
      icon: "text_increase", type: "int", min: 14, max: 56, step: 2, unit: "px"
    },
    {
      key: "desktopClockDateFormat", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Desktop Clock Date Format", subtitle: "Qt date format string for the desktop clock subtitle",
      icon: "calendar_month", type: "string",
      presets: [
        { label: "dddd, d MMMM yyyy", value: "dddd, d MMMM yyyy" },
        { label: "ddd, MMM d, yyyy",  value: "ddd, MMM d, yyyy" },
        { label: "d MMMM yyyy",       value: "d MMMM yyyy" }
      ]
    },
    {
      key: "desktopClockMargins", category: "widgets", section: "Desktop Wallpaper Clock",
      title: "Desktop Clock Left Margin", subtitle: "Distance from the left screen edge in pixels",
      icon: "margin", type: "int", min: 0, max: 120, step: 5, unit: "px"
    },
    {
      key: "todoEnabled", category: "widgets", section: "Desktop To-Do List Widget",
      title: "Enable Desktop To-Do List", subtitle: "Show the floating bottom-right task list widget on the desktop",
      icon: "checklist", type: "bool"
    },
    {
      key: "todoFont", category: "widgets", section: "Desktop To-Do List Widget",
      title: "To-Do List Font Family", subtitle: "Font used inside the To-Do List widget",
      icon: "font_download", type: "string",
      presets: [
        { label: "Maple Mono NF CN", value: "Maple Mono NF CN" },
        { label: "Maven Pro",        value: "Maven Pro" },
        { label: "JetBrainsMono NF", value: "JetBrainsMono Nerd Font" }
      ]
    },
    {
      key: "todoWidth", category: "widgets", section: "Desktop To-Do List Widget",
      title: "To-Do List Width", subtitle: "Width of the floating To-Do List card",
      icon: "swap_horiz", type: "int", min: 260, max: 640, step: 20, unit: "px"
    },
    {
      key: "todoHeight", category: "widgets", section: "Desktop To-Do List Widget",
      title: "To-Do List Height", subtitle: "Height of the floating To-Do List card",
      icon: "swap_vert", type: "int", min: 240, max: 700, step: 20, unit: "px"
    },
    {
      key: "todoMargins", category: "widgets", section: "Desktop To-Do List Widget",
      title: "To-Do List Screen Margin", subtitle: "Offset from the bottom-right screen edges",
      icon: "margin", type: "int", min: 0, max: 60, step: 5, unit: "px"
    },
    {
      key: "todoBgOpacity", category: "widgets", section: "Desktop To-Do List Widget",
      title: "To-Do List Surface Opacity", subtitle: "Background translucency of the To-Do List card",
      icon: "opacity", type: "real", min: 0.20, max: 1.00, step: 0.05, decimals: 2, unit: ""
    },
    {
      key: "launcherWidth", category: "widgets", section: "App Launcher & Clipboard Popups",
      title: "App Launcher Width", subtitle: "Width of the top-anchored application launcher notch",
      icon: "apps", type: "int", min: 500, max: 1200, step: 25, unit: "px"
    },
    {
      key: "launcherHeight", category: "widgets", section: "App Launcher & Clipboard Popups",
      title: "App Launcher Height", subtitle: "Height of the application launcher notch",
      icon: "height", type: "int", min: 280, max: 700, step: 20, unit: "px"
    },
    {
      key: "launcherMaxResults", category: "widgets", section: "App Launcher & Clipboard Popups",
      title: "App Launcher Max Results", subtitle: "Maximum application entries shown at once",
      icon: "format_list_numbered", type: "int", min: 5, max: 50, step: 5, unit: "apps"
    },
    {
      key: "clipboardWidth", category: "widgets", section: "App Launcher & Clipboard Popups",
      title: "Clipboard Manager Width", subtitle: "Width of the bottom-anchored clipboard history notch",
      icon: "content_paste", type: "int", min: 450, max: 1000, step: 25, unit: "px"
    },
    {
      key: "clipboardHeight", category: "widgets", section: "App Launcher & Clipboard Popups",
      title: "Clipboard Manager Height", subtitle: "Height of the clipboard history notch",
      icon: "height", type: "int", min: 300, max: 750, step: 25, unit: "px"
    },
    {
      key: "clipboardMaxResults", category: "widgets", section: "App Launcher & Clipboard Popups",
      title: "Clipboard Max Entries", subtitle: "Maximum cliphist entries loaded when searching clipboard",
      icon: "history", type: "int", min: 50, max: 1000, step: 50, unit: "items"
    },
    {
      key: "wallpaperPanelWidth", category: "widgets", section: "Wallpaper Switcher Geometry",
      title: "Wallpaper Switcher Width", subtitle: "Width of the bottom-anchored wallpaper picker notch",
      icon: "panorama_horizontal", type: "int", min: 800, max: 1800, step: 30, unit: "px"
    },
    {
      key: "wallpaperPanelHeight", category: "widgets", section: "Wallpaper Switcher Geometry",
      title: "Wallpaper Switcher Height", subtitle: "Height of the wallpaper picker notch",
      icon: "height", type: "int", min: 380, max: 750, step: 20, unit: "px"
    },
    {
      key: "wallpaperThumbWidth", category: "widgets", section: "Wallpaper Switcher Geometry",
      title: "Wallpaper Thumbnail Width", subtitle: "Width of each wallpaper preview card",
      icon: "photo_size_select_large", type: "int", min: 180, max: 450, step: 10, unit: "px"
    },
    {
      key: "wallpaperThumbHeight", category: "widgets", section: "Wallpaper Switcher Geometry",
      title: "Wallpaper Thumbnail Height", subtitle: "Height of each wallpaper preview card",
      icon: "photo_size_select_actual", type: "int", min: 110, max: 300, step: 10, unit: "px"
    },
    {
      key: "wallpaperThumbSpacing", category: "widgets", section: "Wallpaper Switcher Geometry",
      title: "Wallpaper Thumbnail Spacing", subtitle: "Horizontal gap between wallpaper preview cards",
      icon: "space_bar", type: "int", min: 6, max: 32, step: 2, unit: "px"
    },

    // 9. POWER & SYSTEM HARDWARE
    {
      key: "powerMenuWidth", category: "system", section: "Power Menu",
      title: "Power Menu Width", subtitle: "Width of the bottom power menu notch",
      icon: "power_settings_new", type: "int", min: 420, max: 840, step: 20, unit: "px"
    },
    {
      key: "powerMenuHeight", category: "system", section: "Power Menu",
      title: "Power Menu Height", subtitle: "Height of the bottom power menu notch",
      icon: "height", type: "int", min: 120, max: 240, step: 10, unit: "px"
    },
    {
      key: "lockCmd", category: "system", section: "Power Menu",
      title: "Lock Screen Command", subtitle: "Executed when selecting Lock (key: L) in the Power Menu",
      icon: "lock", type: "string",
      presets: [
        { label: "hyprlock",  value: "hyprlock" },
        { label: "swaylock",  value: "swaylock -f" },
        { label: "loginctl",  value: "loginctl lock-session" }
      ]
    },
    {
      key: "logoutCmd", category: "system", section: "Power Menu",
      title: "Logout Command", subtitle: "Executed when selecting Logout (key: O) in the Power Menu",
      icon: "logout", type: "string",
      presets: [
        { label: "Hyprland Exit", value: "hyprctl dispatch exit" },
        { label: "uwsm stop",     value: "uwsm stop" },
        { label: "loginctl",      value: "loginctl terminate-user $USER" }
      ]
    },
    {
      key: "rebootCmd", category: "system", section: "Power Menu",
      title: "Reboot Command", subtitle: "Executed when selecting Reboot (key: R) in the Power Menu",
      icon: "autorenew", type: "string",
      presets: [
        { label: "reboot",           value: "reboot" },
        { label: "systemctl reboot", value: "systemctl reboot" }
      ]
    },
    {
      key: "shutdownCmd", category: "system", section: "Power Menu",
      title: "Shutdown Command", subtitle: "Executed when selecting Shutdown (key: S) in the Power Menu",
      icon: "power_settings_new", type: "string",
      presets: [
        { label: "shutdown now",       value: "shutdown now" },
        { label: "systemctl poweroff", value: "systemctl poweroff" }
      ]
    },
    {
      key: "statsPollInterval", category: "system", section: "Hardware Telemetry & Sensors",
      title: "System Stats Polling Interval", subtitle: "How frequently CPU, RAM, and temperature sensors are sampled",
      icon: "update", type: "int", min: 500, max: 10000, step: 250, unit: "ms"
    },
    {
      key: "cpuTempHwmonPath", category: "system", section: "Hardware Telemetry & Sensors",
      title: "CPU Temperature Sensor Path", subtitle: "Sysfs hwmon path read by SystemStatsService for CPU temperature",
      icon: "thermostat", type: "string",
      presets: root.discoveredHwmonSensors.length > 0
        ? root.discoveredHwmonSensors
        : [
            { label: "hwmon5/temp1", value: "/sys/class/hwmon/hwmon5/temp1_input" },
            { label: "hwmon0/temp1", value: "/sys/class/hwmon/hwmon0/temp1_input" },
            { label: "hwmon1/temp1", value: "/sys/class/hwmon/hwmon1/temp1_input" },
            { label: "hwmon2/temp1", value: "/sys/class/hwmon/hwmon2/temp1_input" },
            { label: "hwmon3/temp1", value: "/sys/class/hwmon/hwmon3/temp1_input" },
            { label: "hwmon4/temp1", value: "/sys/class/hwmon/hwmon4/temp1_input" }
          ]
    },
    {
      key: "pollGpu", category: "system", section: "Hardware Telemetry & Sensors",
      title: "Poll NVIDIA GPU Telemetry", subtitle: "Query nvidia-smi for GPU utilization and temperature",
      icon: "developer_board", type: "bool"
    },
    {
      key: "backlightDevice", category: "system", section: "Backlight & Display Brightness",
      title: "Backlight Sysfs Device", subtitle: "Device in /sys/class/backlight controlled by BrightnessService (empty = auto)",
      icon: "brightness_6", type: "string",
      presets: root.discoveredBacklights.length > 0
        ? root.discoveredBacklights
        : [
            { label: "Auto-detect",     value: "" },
            { label: "intel_backlight", value: "intel_backlight" },
            { label: "amdgpu_bl0",      value: "amdgpu_bl0" },
            { label: "amdgpu_bl1",      value: "amdgpu_bl1" },
            { label: "acpi_video0",     value: "acpi_video0" }
          ]
    },
    {
      key: "brightnessPollInterval", category: "system", section: "Backlight & Display Brightness",
      title: "Brightness Fallback Poll Interval", subtitle: "Slow polling interval for drivers without sysfs inotify events",
      icon: "timelapse", type: "int", min: 500, max: 10000, step: 250, unit: "ms"
    }
  ]

  // ── Filtered & Grouped Settings for Active View ──
  readonly property var activeCategoryObj: {
    for (let i = 0; i < categories.length; i++) {
      if (categories[i].id === root.activeCategory) return categories[i]
    }
    return categories[0]
  }

  readonly property var visibleSections: {
    const q = root.searchQuery.trim().toLowerCase()
    const isSearching = q.length > 0
    const filtered = root.settingsSchema.filter(item => {
      if (!isSearching) return item.category === root.activeCategory
      return item.title.toLowerCase().includes(q)
        || item.subtitle.toLowerCase().includes(q)
        || item.section.toLowerCase().includes(q)
        || item.key.toLowerCase().includes(q)
    })

    const groups = []
    const map = {}
    for (let i = 0; i < filtered.length; i++) {
      const it = filtered[i]
      const secName = isSearching
        ? (root.categories.find(c => c.id === it.category)?.label + "  •  " + it.section)
        : it.section
      if (!map[secName]) {
        map[secName] = { title: secName, items: [] }
        groups.push(map[secName])
      }
      map[secName].items.push(it)
    }
    return groups
  }

  function resetActiveCategory(): void {
    const keys = root.settingsSchema
      .filter(it => it.category === root.activeCategory)
      .map(it => it.key)
    Global.resetKeys(keys)
  }

  // ── Window Setup ──
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true
  color: "transparent"
  visible: open || hideDelay.running

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "settings-app"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Timer {
    id: hideDelay
    interval: Global.dur.normal
    onTriggered: {
      if (!root.open) root.dismissed()
    }
  }

  onOpenChanged: {
    if (open) {
      hideDelay.stop()
      confirmResetAll = false
      hwmonProbeProc.running = true
      backlightProbeProc.running = true
      Qt.callLater(() => windowCard.forceActiveFocus())
    } else {
      hideDelay.restart()
    }
  }

  function show(): void { open = true }
  function hide(): void { open = false }
  function toggle(): void { if (open) hide(); else show() }

  // ── Scrim Backdrop inside Screen Frame ──
  Rectangle {
    anchors {
      fill: parent
      topMargin: Global.pillHeight
      leftMargin: Global.border
      rightMargin: Global.border
      bottomMargin: Global.border
    }
    radius: Global.borderRadius
    color: Qt.rgba(Theme.m3scrim.r, Theme.m3scrim.g, Theme.m3scrim.b, root.previewMode ? 0.04 : 0.42)
    opacity: (root.open && root._ready) ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Global.dur.normal; easing.type: Easing.OutCubic }
    }
    Behavior on color {
      ColorAnimation { duration: Global.dur.fast }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.hide()
    }
  }

  // ── Main Material You Settings Window Card ──
  Rectangle {
    id: windowCard
    focus: root.open
    clip: true

    readonly property int targetWidth: Math.min(1080, parent.width - Global.border * 2 - 48)
    readonly property int targetHeight: Math.min(720, parent.height - Global.pillHeight - Global.border - 48)

    width: targetWidth
    height: targetHeight
    anchors.centerIn: parent
    anchors.verticalCenterOffset: Math.round((Global.pillHeight - Global.border) / 2)

    radius: Global.panelRadius
    color: Theme.m3surface_container_low
    border.width: 1
    border.color: Theme.m3outline_variant

    opacity: (root.open && root._ready) ? (root.previewMode ? 0.88 : 1.0) : 0.0
    scale: (root.open && root._ready) ? (root.previewMode ? 0.96 : 1.0) : 0.92

    Behavior on opacity {
      NumberAnimation { duration: Global.dur.normal; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
      Anim { curve: Global.spring }
    }
    Behavior on radius {
      Anim {}
    }

    Keys.onPressed: (event) => {
      if (event.key === Qt.Key_Escape) {
        if (searchField.activeFocus && root.searchQuery !== "") {
          root.searchQuery = ""
          windowCard.forceActiveFocus()
        } else {
          root.hide()
        }
        event.accepted = true
      } else if ((event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) || event.key === Qt.Key_Slash) {
        searchField.forceActiveFocus()
        event.accepted = true
      }
    }

    // Prevent clicks inside the window from closing the backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: windowCard.forceActiveFocus()
    }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // ════════════════════════════════════════════════════════════════
      // LEFT NAVIGATION RAIL / SIDEBAR (Material Design 3 Navigation Drawer)
      // ════════════════════════════════════════════════════════════════
      Rectangle {
        Layout.preferredWidth: 264
        Layout.fillHeight: true
        color: Theme.m3surface_container

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 16
          spacing: 12

          // ── App Brand Header ──
          RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            spacing: 12

            Rectangle {
              Layout.preferredWidth: 42
              Layout.preferredHeight: 42
              radius: 14
              color: Theme.m3primary_container

              Icon {
                anchors.centerIn: parent
                text: "tune"
                font.pixelSize: 24
                color: Theme.m3on_primary_container
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Label {
                text: "Boom Settings"
                font.pixelSize: 18
                font.bold: true
                color: Theme.m3on_surface
              }

              Label {
                text: "Material You Config"
                font.pixelSize: 12
                color: Theme.m3on_surface_variant
              }
            }
          }

          // ── M3 Search Bar ──
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 21
            color: Theme.m3surface_container_highest
            border.width: searchField.activeFocus ? 2 : 0
            border.color: Theme.m3primary

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 10
              spacing: 8

              Icon {
                text: "search"
                font.pixelSize: 19
                color: searchField.activeFocus ? Theme.m3primary : Theme.m3on_surface_variant
              }

              TextInput {
                id: searchField
                Layout.fillWidth: true
                font.family: Global.font
                font.pixelSize: 13
                color: Theme.m3on_surface
                selectionColor: Theme.m3primary
                selectedTextColor: Theme.m3on_primary
                clip: true
                text: root.searchQuery
                onTextChanged: root.searchQuery = text

                Keys.onEscapePressed: {
                  root.searchQuery = ""
                  windowCard.forceActiveFocus()
                }

                Label {
                  visible: searchField.text === ""
                  text: "Search settings..."
                  font.pixelSize: 13
                  color: Theme.m3on_surface_variant
                  opacity: 0.7
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Rectangle {
                visible: root.searchQuery !== ""
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: clearSearchMouse.containsMouse ? Theme.m3surface_bright : "transparent"

                Icon {
                  anchors.centerIn: parent
                  text: "close"
                  font.pixelSize: 15
                  color: Theme.m3on_surface_variant
                }

                MouseArea {
                  id: clearSearchMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.searchQuery = ""
                    windowCard.forceActiveFocus()
                  }
                }
              }
            }
          }

          // ── Navigation Category Pills ──
          ListView {
            id: navList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            model: root.categories

            delegate: Rectangle {
              id: navPill
              required property var modelData
              readonly property bool selected: root.searchQuery === "" && root.activeCategory === modelData.id

              width: ListView.view.width
              height: 46
              radius: 23
              color: selected
                ? Theme.m3secondary_container
                : (navMouse.containsMouse ? Theme.m3surface_container_high : "transparent")

              Behavior on color {
                ColorAnimation { duration: Global.dur.fast }
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 12

                Icon {
                  text: navPill.modelData.icon
                  font.pixelSize: 20
                  color: navPill.selected ? Theme.m3on_secondary_container : Theme.m3on_surface_variant
                }

                Label {
                  Layout.fillWidth: true
                  text: navPill.modelData.label
                  font.pixelSize: 13
                  font.weight: navPill.selected ? 600 : 500
                  color: navPill.selected ? Theme.m3on_secondary_container : Theme.m3on_surface
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: navMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.searchQuery = ""
                  root.activeCategory = navPill.modelData.id
                  settingsScroll.contentY = 0
                }
              }
            }
          }

          // Divider
          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.m3outline_variant
            opacity: 0.5
          }

          // ── Reset All to Defaults Button (with 2-step confirmation) ──
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 20
            color: root.confirmResetAll
              ? Theme.m3error_container
              : (resetAllMouse.containsMouse ? Theme.m3surface_container_highest : Theme.m3surface_container_high)

            Behavior on color {
              ColorAnimation { duration: Global.dur.fast }
            }

            RowLayout {
              anchors.centerIn: parent
              spacing: 8

              Icon {
                text: root.confirmResetAll ? "warning" : "restart_alt"
                font.pixelSize: 18
                color: root.confirmResetAll ? Theme.m3on_error_container : Theme.m3on_surface_variant
              }

              Label {
                text: root.confirmResetAll ? "Confirm Reset All?" : "Reset All Defaults"
                font.pixelSize: 12
                font.weight: 600
                color: root.confirmResetAll ? Theme.m3on_error_container : Theme.m3on_surface_variant
              }
            }

            MouseArea {
              id: resetAllMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.confirmResetAll) {
                  Global.resetAll()
                  root.confirmResetAll = false
                } else {
                  root.confirmResetAll = true
                  confirmResetTimer.restart()
                }
              }
            }

            Timer {
              id: confirmResetTimer
              interval: 3500
              onTriggered: root.confirmResetAll = false
            }
          }
        }
      }

      // Vertical Separator
      Rectangle {
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        color: Theme.m3outline_variant
        opacity: 0.4
      }

      // ════════════════════════════════════════════════════════════════
      // RIGHT CONTENT VIEWPORT
      // ════════════════════════════════════════════════════════════════
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        // ── Top Sticky Content Header Bar ──
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 76
          color: Theme.m3surface_container_low

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 24
            spacing: 14

            Rectangle {
              Layout.preferredWidth: 44
              Layout.preferredHeight: 44
              radius: 14
              color: Theme.m3secondary_container

              Icon {
                anchors.centerIn: parent
                text: root.searchQuery !== "" ? "manage_search" : root.activeCategoryObj.icon
                font.pixelSize: 22
                color: Theme.m3on_secondary_container
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Label {
                text: root.searchQuery !== ""
                  ? ("Search results for \"" + root.searchQuery + "\"")
                  : root.activeCategoryObj.label
                font.pixelSize: 20
                font.bold: true
                color: Theme.m3on_surface
                elide: Text.ElideRight
              }

              Label {
                text: root.searchQuery !== ""
                  ? "Showing matching parameters across all configuration files"
                  : root.activeCategoryObj.subtitle
                font.pixelSize: 12
                color: Theme.m3on_surface_variant
                elide: Text.ElideRight
              }
            }

            // Peek / Live Desktop Preview Mode Toggle Pill
            Rectangle {
              Layout.preferredHeight: 36
              implicitWidth: peekRow.implicitWidth + 24
              radius: 18
              color: root.previewMode
                ? Theme.m3tertiary_container
                : (peekMouse.containsMouse ? Theme.m3surface_container_highest : Theme.m3surface_container_high)

              Behavior on color {
                ColorAnimation { duration: Global.dur.fast }
              }

              RowLayout {
                id: peekRow
                anchors.centerIn: parent
                spacing: 6

                Icon {
                  text: root.previewMode ? "visibility" : "visibility_off"
                  font.pixelSize: 17
                  color: root.previewMode ? Theme.m3on_tertiary_container : Theme.m3on_surface_variant
                }

                Label {
                  text: root.previewMode ? "Peeking Desktop" : "Peek Desktop"
                  font.pixelSize: 12
                  font.weight: 600
                  color: root.previewMode ? Theme.m3on_tertiary_container : Theme.m3on_surface_variant
                }
              }

              MouseArea {
                id: peekMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.previewMode = !root.previewMode
              }
            }

            // Reset Category Button
            Rectangle {
              visible: root.searchQuery === ""
              Layout.preferredHeight: 36
              implicitWidth: resetCatRow.implicitWidth + 24
              radius: 18
              color: resetCatMouse.containsMouse ? Theme.m3surface_container_highest : Theme.m3surface_container_high

              RowLayout {
                id: resetCatRow
                anchors.centerIn: parent
                spacing: 6

                Icon {
                  text: "history"
                  font.pixelSize: 17
                  color: Theme.m3on_surface_variant
                }

                Label {
                  text: "Reset Page"
                  font.pixelSize: 12
                  font.weight: 600
                  color: Theme.m3on_surface_variant
                }
              }

              MouseArea {
                id: resetCatMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetActiveCategory()
              }
            }

            // Close Window Button
            Rectangle {
              Layout.preferredWidth: 36
              Layout.preferredHeight: 36
              radius: 18
              color: closeWinMouse.containsMouse ? Theme.m3error_container : Theme.m3surface_container_high

              Behavior on color {
                ColorAnimation { duration: Global.dur.fast }
              }

              Icon {
                anchors.centerIn: parent
                text: "close"
                font.pixelSize: 19
                color: closeWinMouse.containsMouse ? Theme.m3on_error_container : Theme.m3on_surface
              }

              MouseArea {
                id: closeWinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.hide()
              }
            }
          }
        }

        // Header Divider
        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Theme.m3outline_variant
          opacity: 0.4
        }

        // ── Scrollable Settings Body ──
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          Flickable {
            id: settingsScroll
            anchors.fill: parent
            contentWidth: width
            contentHeight: contentCol.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 5000

            ColumnLayout {
              id: contentCol
              width: settingsScroll.width - 56
              x: 28
              y: 20
              spacing: 20

              // ────────────────────────────────────────────────────────
              // SPECIAL HERO CARD 1: Material You Palette Swatch & Actions (Theme Page)
              // ────────────────────────────────────────────────────────
              Rectangle {
                visible: root.searchQuery === "" && root.activeCategory === "theme"
                Layout.fillWidth: true
                implicitHeight: themeHeroCol.implicitHeight + 36
                radius: 22
                color: Theme.m3surface_container

                ColumnLayout {
                  id: themeHeroCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.margins: 18
                  spacing: 14

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Icon {
                      text: "auto_awesome"
                      font.pixelSize: 22
                      color: Theme.m3primary
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 2

                      Label {
                        text: "Active Material You (M3) Dynamic Palette"
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.m3on_surface
                      }

                      Label {
                        text: Global.wallLast !== ""
                          ? ("Wallpaper: " + Global.wallLast.split("/").pop())
                          : "Live tokens from common/Theme.qml"
                        font.pixelSize: 12
                        color: Theme.m3on_surface_variant
                        elide: Text.ElideMiddle
                      }
                    }

                    // Open Wallpaper Switcher Button
                    Rectangle {
                      Layout.preferredHeight: 36
                      implicitWidth: openWallRow.implicitWidth + 24
                      radius: 18
                      color: openWallMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_highest

                      RowLayout {
                        id: openWallRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                          text: "wallpaper"
                          font.pixelSize: 17
                          color: Theme.m3on_surface
                        }

                        Label {
                          text: "Wallpaper Picker"
                          font.pixelSize: 12
                          font.weight: 600
                          color: Theme.m3on_surface
                        }
                      }

                      MouseArea {
                        id: openWallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          root.hide()
                          Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "show"])
                        }
                      }
                    }

                    // Re-run Matugen Now Button
                    Rectangle {
                      Layout.preferredHeight: 36
                      implicitWidth: applyMatRow.implicitWidth + 26
                      radius: 18
                      color: applyMatMouse.containsMouse ? Qt.darker(Theme.m3primary, 1.08) : Theme.m3primary
                      opacity: Global.matugenApplying ? 0.6 : 1.0

                      RowLayout {
                        id: applyMatRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                          text: "sync"
                          font.pixelSize: 17
                          color: Theme.m3on_primary
                        }

                        Label {
                          text: Global.matugenApplying ? "Applying..." : "Apply Theme Now"
                          font.pixelSize: 12
                          font.bold: true
                          color: Theme.m3on_primary
                        }
                      }

                      MouseArea {
                        id: applyMatMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !Global.matugenApplying
                        onClicked: Global.regenerateMatugenTheme()
                      }
                    }
                  }

                  // Live Color Token Swatch Strip
                  GridLayout {
                    Layout.fillWidth: true
                    columns: 6
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                      model: [
                        { name: "Primary",            bg: Theme.m3primary,             fg: Theme.m3on_primary },
                        { name: "Primary Container",  bg: Theme.m3primary_container,   fg: Theme.m3on_primary_container },
                        { name: "Secondary",          bg: Theme.m3secondary,           fg: Theme.m3on_secondary },
                        { name: "Secondary Cont.",    bg: Theme.m3secondary_container, fg: Theme.m3on_secondary_container },
                        { name: "Tertiary",           bg: Theme.m3tertiary,            fg: Theme.m3on_tertiary },
                        { name: "Tertiary Cont.",     bg: Theme.m3tertiary_container,  fg: Theme.m3on_tertiary_container },
                        { name: "Surface",            bg: Theme.m3surface,             fg: Theme.m3on_surface },
                        { name: "Surface High",       bg: Theme.m3surface_container_high, fg: Theme.m3on_surface },
                        { name: "Surface Bright",     bg: Theme.m3surface_bright,      fg: Theme.m3on_surface },
                        { name: "Outline",            bg: Theme.m3outline,             fg: Theme.m3surface },
                        { name: "Error",              bg: Theme.m3error,               fg: Theme.m3on_error },
                        { name: "Error Container",    bg: Theme.m3error_container,     fg: Theme.m3on_error_container }
                      ]

                      delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 12
                        color: modelData.bg
                        border.width: 1
                        border.color: Qt.rgba(Theme.m3outline.r, Theme.m3outline.g, Theme.m3outline.b, 0.25)

                        ColumnLayout {
                          anchors.fill: parent
                          anchors.margins: 6
                          spacing: 0

                          Label {
                            Layout.fillWidth: true
                            text: modelData.name
                            font.pixelSize: 10
                            font.bold: true
                            color: modelData.fg
                            elide: Text.ElideRight
                          }

                          Label {
                            Layout.fillWidth: true
                            text: modelData.bg.toString().toUpperCase()
                            font.pixelSize: 10
                            color: modelData.fg
                            opacity: 0.8
                          }
                        }
                      }
                    }
                  }
                }
              }

              // ────────────────────────────────────────────────────────
              // SPECIAL HERO CARD 2: Interactive Spring & Motion Tester (Motion Page)
              // ────────────────────────────────────────────────────────
              Rectangle {
                id: motionHeroCard
                visible: root.searchQuery === "" && root.activeCategory === "motion"
                Layout.fillWidth: true
                implicitHeight: 96
                radius: 22
                color: Theme.m3surface_container

                property bool toggledPos: false

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 18
                  spacing: 16

                  ColumnLayout {
                    Layout.preferredWidth: 240
                    spacing: 2

                    Label {
                      text: "Interactive Spring Playground"
                      font.pixelSize: 15
                      font.bold: true
                      color: Theme.m3on_surface
                    }

                    Label {
                      text: "Click Test to preview Global.spring & Global.dur.normal"
                      font.pixelSize: 12
                      color: Theme.m3on_surface_variant
                    }
                  }

                  Rectangle {
                    id: springTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 24
                    color: Theme.m3surface_container_highest

                    Rectangle {
                      width: 84
                      height: 36
                      radius: 18
                      anchors.verticalCenter: parent.verticalCenter
                      x: motionHeroCard.toggledPos ? (springTrack.width - width - 8) : 8
                      color: Theme.m3primary

                      Behavior on x {
                        Anim { curve: Global.spring }
                      }

                      Icon {
                        anchors.centerIn: parent
                        text: "auto_awesome_motion"
                        font.pixelSize: 18
                        color: Theme.m3on_primary
                      }
                    }
                  }

                  Rectangle {
                    Layout.preferredHeight: 40
                    implicitWidth: 110
                    radius: 20
                    color: testAnimMouse.containsMouse ? Qt.darker(Theme.m3primary, 1.08) : Theme.m3primary

                    Label {
                      anchors.centerIn: parent
                      text: "Test Spring"
                      font.pixelSize: 13
                      font.bold: true
                      color: Theme.m3on_primary
                    }

                    MouseArea {
                      id: testAnimMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: motionHeroCard.toggledPos = !motionHeroCard.toggledPos
                    }
                  }
                }
              }

              // ────────────────────────────────────────────────────────
              // SPECIAL HERO CARD 3: Notification Test & History Actions (Notifications Page)
              // ────────────────────────────────────────────────────────
              Rectangle {
                visible: root.searchQuery === "" && root.activeCategory === "notifications"
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 22
                color: Theme.m3surface_container

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 18
                  spacing: 14

                  Icon {
                    text: "notifications_active"
                    font.pixelSize: 22
                    color: Theme.m3primary
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                      text: "Notification Server Diagnostics"
                      font.pixelSize: 15
                      font.bold: true
                      color: Theme.m3on_surface
                    }

                    Label {
                      text: NotificationService.historyCount + " notifications in history  •  "
                        + (NotificationService.doNotDisturb ? "Do Not Disturb is ON" : "Popups active")
                      font.pixelSize: 12
                      color: Theme.m3on_surface_variant
                    }
                  }

                  Rectangle {
                    Layout.preferredHeight: 36
                    implicitWidth: clearHistRow.implicitWidth + 24
                    radius: 18
                    color: clearHistMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_highest
                    opacity: NotificationService.hasHistory ? 1.0 : 0.45

                    RowLayout {
                      id: clearHistRow
                      anchors.centerIn: parent
                      spacing: 6

                      Icon {
                        text: "delete_sweep"
                        font.pixelSize: 17
                        color: Theme.m3on_surface
                      }

                      Label {
                        text: "Clear History"
                        font.pixelSize: 12
                        font.weight: 600
                        color: Theme.m3on_surface
                      }
                    }

                    MouseArea {
                      id: clearHistMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      enabled: NotificationService.hasHistory
                      cursorShape: Qt.PointingHandCursor
                      onClicked: NotificationService.clearHistory()
                    }
                  }

                  Rectangle {
                    Layout.preferredHeight: 36
                    implicitWidth: testNotifRow.implicitWidth + 24
                    radius: 18
                    color: testNotifMouse.containsMouse ? Qt.darker(Theme.m3primary, 1.08) : Theme.m3primary

                    RowLayout {
                      id: testNotifRow
                      anchors.centerIn: parent
                      spacing: 6

                      Icon {
                        text: "send"
                        font.pixelSize: 16
                        color: Theme.m3on_primary
                      }

                      Label {
                        text: "Send Test Toast"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.m3on_primary
                      }
                    }

                    MouseArea {
                      id: testNotifMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        Quickshell.execDetached([
                          "notify-send",
                          "-a", "Boom Settings",
                          "Material You Notification",
                          "Toast width: " + Global.notifToastWidth + "px • Timeout: " + Global.notifDefaultTimeout + "ms"
                        ])
                      }
                    }
                  }
                }
              }

              // ────────────────────────────────────────────────────────
              // DECLARATIVE SECTIONS & SETTING CARDS
              // ────────────────────────────────────────────────────────
              Repeater {
                model: root.visibleSections

                delegate: ColumnLayout {
                  id: sectionGroup
                  required property var modelData
                  Layout.fillWidth: true
                  spacing: 10

                  // Section Title Label
                  Label {
                    Layout.leftMargin: 6
                    text: sectionGroup.modelData.title
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.m3primary
                  }

                  // Section Card Container
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: sectionItemsCol.implicitHeight + 16
                    radius: 22
                    color: Theme.m3surface_container

                    ColumnLayout {
                      id: sectionItemsCol
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.margins: 8
                      spacing: 4

                      Repeater {
                        model: sectionGroup.modelData.items

                        delegate: Rectangle {
                          id: settingRow
                          required property var modelData
                          required property int index

                          readonly property string propKey: modelData.key
                          readonly property var currentVal: Global[propKey]
                          readonly property var defaultVal: Global.defaults[propKey]
                          readonly property bool modified: {
                            if (defaultVal === undefined) return false
                            if (typeof defaultVal === "number") {
                              return Math.abs(Number(currentVal) - Number(defaultVal)) > 0.0005
                            }
                            return currentVal !== defaultVal
                          }
                          readonly property bool hasPresets: (modelData.presets && modelData.presets.length > 0)

                          Layout.fillWidth: true
                          implicitHeight: rowMainCol.implicitHeight + 24
                          radius: 16
                          color: rowHover.hovered ? Theme.m3surface_container_high : "transparent"

                          Behavior on color {
                            ColorAnimation { duration: Global.dur.fast }
                          }

                          HoverHandler {
                            id: rowHover
                          }

                          ColumnLayout {
                            id: rowMainCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            // Top Line: Icon + Title/Subtitle + Reset Button + Control
                            RowLayout {
                              Layout.fillWidth: true
                              spacing: 14

                              // Leading Icon Badge
                              Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 12
                                color: settingRow.modified
                                  ? Theme.m3primary_container
                                  : Theme.m3surface_container_highest

                                Icon {
                                  anchors.centerIn: parent
                                  text: settingRow.modelData.icon || "tune"
                                  font.pixelSize: 20
                                  color: settingRow.modified
                                    ? Theme.m3on_primary_container
                                    : Theme.m3on_surface_variant
                                }
                              }

                              // Title & Description
                              ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                  spacing: 8

                                  Label {
                                    text: settingRow.modelData.title
                                    font.pixelSize: 14
                                    font.weight: 600
                                    color: Theme.m3on_surface
                                  }

                                  // Modified Badge
                                  Rectangle {
                                    visible: settingRow.modified
                                    implicitWidth: modLbl.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: 9
                                    color: Theme.m3secondary_container

                                    Label {
                                      id: modLbl
                                      anchors.centerIn: parent
                                      text: "Modified"
                                      font.pixelSize: 10
                                      font.bold: true
                                      color: Theme.m3on_secondary_container
                                    }
                                  }
                                }

                                Label {
                                  Layout.fillWidth: true
                                  text: settingRow.modelData.subtitle
                                  font.pixelSize: 12
                                  color: Theme.m3on_surface_variant
                                  wrapMode: Text.WordWrap
                                }
                              }

                              // Per-Setting Reset to Default Button
                              Rectangle {
                                visible: settingRow.modified
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 16
                                color: resetItemMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_highest

                                Icon {
                                  anchors.centerIn: parent
                                  text: "restart_alt"
                                  font.pixelSize: 17
                                  color: Theme.m3primary
                                }

                                MouseArea {
                                  id: resetItemMouse
                                  anchors.fill: parent
                                  hoverEnabled: true
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: Global.resetKey(settingRow.propKey)
                                }
                              }

                              // ── CONTROL TYPE 0: Active Chip Readout Badge (chips) ──
                              Rectangle {
                                visible: settingRow.modelData.type === "chips"
                                Layout.preferredHeight: 30
                                implicitWidth: activeChipBadgeLbl.implicitWidth + 22
                                radius: 10
                                color: Theme.m3secondary_container

                                Label {
                                  id: activeChipBadgeLbl
                                  anchors.centerIn: parent
                                  text: {
                                    const presets = settingRow.modelData.presets ?? []
                                    for (let i = 0; i < presets.length; i++) {
                                      if (presets[i].value === settingRow.currentVal) return presets[i].label
                                    }
                                    return String(settingRow.currentVal ?? "")
                                  }
                                  font.pixelSize: 12
                                  font.bold: true
                                  color: Theme.m3on_secondary_container
                                }
                              }

                              // ── CONTROL TYPE 1: Material 3 Switch (bool) ──
                              Rectangle {
                                visible: settingRow.modelData.type === "bool"
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 30
                                radius: 15
                                color: Boolean(settingRow.currentVal)
                                  ? Theme.m3primary
                                  : Theme.m3surface_container_highest
                                border.width: Boolean(settingRow.currentVal) ? 0 : 2
                                border.color: Theme.m3outline

                                Behavior on color {
                                  ColorAnimation { duration: Global.dur.fast }
                                }

                                Rectangle {
                                  id: switchThumb
                                  readonly property bool checked: Boolean(settingRow.currentVal)
                                  width: checked ? 22 : 16
                                  height: checked ? 22 : 16
                                  radius: height / 2
                                  anchors.verticalCenter: parent.verticalCenter
                                  x: checked ? (parent.width - width - 4) : 7
                                  color: checked ? Theme.m3on_primary : Theme.m3outline

                                  Behavior on x {
                                    Anim {}
                                  }
                                  Behavior on width {
                                    Anim {}
                                  }
                                  Behavior on height {
                                    Anim {}
                                  }

                                  Icon {
                                    visible: switchThumb.checked
                                    anchors.centerIn: parent
                                    text: "check"
                                    font.pixelSize: 14
                                    color: Theme.m3primary
                                  }
                                }

                                MouseArea {
                                  anchors.fill: parent
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: Global[settingRow.propKey] = !Boolean(settingRow.currentVal)
                                }
                              }

                              // ── CONTROL TYPE 2: Numeric Slider + Stepper + Value Pill (int / real) ──
                              RowLayout {
                                visible: settingRow.modelData.type === "int" || settingRow.modelData.type === "real"
                                spacing: 8

                                // Decrement Button (-)
                                Rectangle {
                                  Layout.preferredWidth: 30
                                  Layout.preferredHeight: 30
                                  radius: 15
                                  color: decMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_highest

                                  Icon {
                                    anchors.centerIn: parent
                                    text: "remove"
                                    font.pixelSize: 16
                                    color: Theme.m3on_surface
                                  }

                                  MouseArea {
                                    id: decMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                      const st = settingRow.modelData.step ?? 1
                                      const mn = settingRow.modelData.min ?? 0
                                      const next = Math.max(mn, Number(settingRow.currentVal) - st)
                                      Global[settingRow.propKey] = settingRow.modelData.type === "int"
                                        ? Math.round(next)
                                        : Math.round(next * 100) / 100
                                    }
                                  }
                                }

                                // M3 Slider Track
                                Slider {
                                  id: numSlider
                                  Layout.preferredWidth: 160
                                  Layout.preferredHeight: 28
                                  from: settingRow.modelData.min ?? 0
                                  to: settingRow.modelData.max ?? 100
                                  showPercentage: false
                                  trackColor: Theme.m3surface_container_highest
                                  fillColor: Theme.m3primary
                                  onMoved: (v) => {
                                    const st = settingRow.modelData.step ?? 1
                                    const mn = settingRow.modelData.min ?? 0
                                    const mx = settingRow.modelData.max ?? 100
                                    const snapped = mn + Math.round((v - mn) / st) * st
                                    const clamped = Math.max(mn, Math.min(mx, snapped))
                                    Global[settingRow.propKey] = settingRow.modelData.type === "int"
                                      ? Math.round(clamped)
                                      : Math.round(clamped * 100) / 100
                                  }

                                  Binding {
                                    target: numSlider
                                    property: "value"
                                    value: Number(settingRow.currentVal ?? 0)
                                  }
                                }

                                // Increment Button (+)
                                Rectangle {
                                  Layout.preferredWidth: 30
                                  Layout.preferredHeight: 30
                                  radius: 15
                                  color: incMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_highest

                                  Icon {
                                    anchors.centerIn: parent
                                    text: "add"
                                    font.pixelSize: 16
                                    color: Theme.m3on_surface
                                  }

                                  MouseArea {
                                    id: incMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                      const st = settingRow.modelData.step ?? 1
                                      const mx = settingRow.modelData.max ?? 100
                                      const next = Math.min(mx, Number(settingRow.currentVal) + st)
                                      Global[settingRow.propKey] = settingRow.modelData.type === "int"
                                        ? Math.round(next)
                                        : Math.round(next * 100) / 100
                                    }
                                  }
                                }

                                // Value Readout Badge
                                Rectangle {
                                  Layout.preferredWidth: 74
                                  Layout.preferredHeight: 30
                                  radius: 10
                                  color: Theme.m3secondary_container

                                  Label {
                                    anchors.centerIn: parent
                                    text: {
                                      const v = Number(settingRow.currentVal ?? 0)
                                      const dec = settingRow.modelData.decimals ?? 0
                                      const formatted = settingRow.modelData.type === "real" ? v.toFixed(dec) : Math.round(v) + ""
                                      const u = settingRow.modelData.unit ?? ""
                                      return formatted + (u !== "" ? " " + u : "")
                                    }
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.m3on_secondary_container
                                  }
                                }
                              }

                              // ── CONTROL TYPE 3: Text / Color Input Field (string / color) ──
                              RowLayout {
                                visible: settingRow.modelData.type === "string" || settingRow.modelData.type === "color"
                                spacing: 8

                                // Live Color Swatch when type === "color"
                                Rectangle {
                                  visible: settingRow.modelData.type === "color"
                                  Layout.preferredWidth: 28
                                  Layout.preferredHeight: 28
                                  radius: 14
                                  color: String(settingRow.currentVal || "#6750a4")
                                  border.width: 1
                                  border.color: Theme.m3outline
                                }

                                Rectangle {
                                  Layout.preferredWidth: settingRow.modelData.type === "color" ? 140 : 250
                                  Layout.preferredHeight: 36
                                  radius: 12
                                  color: Theme.m3surface_container_highest
                                  border.width: strInput.activeFocus ? 2 : 1
                                  border.color: strInput.activeFocus ? Theme.m3primary : Theme.m3outline_variant

                                  TextInput {
                                    id: strInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: Global.font
                                    font.pixelSize: 13
                                    color: Theme.m3on_surface
                                    selectionColor: Theme.m3primary
                                    selectedTextColor: Theme.m3on_primary
                                    selectByMouse: true
                                    clip: true
                                    text: String(settingRow.currentVal ?? "")

                                    function commitValue(): void {
                                      if (settingRow.modelData.type === "color") {
                                        const m = /^#?([0-9a-fA-F]{6})$/.exec(text.trim())
                                        if (m) {
                                          Global[settingRow.propKey] = "#" + m[1].toLowerCase()
                                          Global.wallUseCustom = true
                                        } else {
                                          text = String(settingRow.currentVal ?? "")
                                        }
                                      } else {
                                        Global[settingRow.propKey] = text
                                      }
                                    }

                                    onAccepted: {
                                      commitValue()
                                      windowCard.forceActiveFocus()
                                    }
                                    onEditingFinished: commitValue()
                                    Keys.onEscapePressed: {
                                      text = String(settingRow.currentVal ?? "")
                                      windowCard.forceActiveFocus()
                                    }
                                  }
                                }
                              }
                            }

                            // ── Second Line: M3 Selection / Preset Chips (when presets exist) ──
                            Flow {
                              visible: settingRow.hasPresets
                              Layout.fillWidth: true
                              Layout.leftMargin: 52
                              spacing: 8

                              Repeater {
                                model: settingRow.modelData.presets ?? []

                                delegate: Rectangle {
                                  id: presetChip
                                  required property var modelData
                                  readonly property bool isSelected: settingRow.currentVal === modelData.value

                                  height: 30
                                  implicitWidth: chipInnerRow.implicitWidth + 22
                                  radius: isSelected ? 10 : 15
                                  color: isSelected
                                    ? Theme.m3secondary_container
                                    : (presetMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_highest)
                                  border.width: isSelected ? 0 : 1
                                  border.color: Theme.m3outline_variant

                                  Behavior on radius {
                                    Anim {}
                                  }
                                  Behavior on color {
                                    ColorAnimation { duration: Global.dur.fast }
                                  }

                                  RowLayout {
                                    id: chipInnerRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Rectangle {
                                      visible: settingRow.modelData.type === "color"
                                      Layout.preferredWidth: 12
                                      Layout.preferredHeight: 12
                                      radius: 6
                                      color: settingRow.modelData.type === "color" ? String(presetChip.modelData.value) : "transparent"
                                      border.width: 1
                                      border.color: Theme.m3outline
                                    }

                                    Icon {
                                      visible: presetChip.isSelected && settingRow.modelData.type !== "color"
                                      text: "check"
                                      font.pixelSize: 15
                                      color: Theme.m3on_secondary_container
                                    }

                                    Label {
                                      text: presetChip.modelData.label
                                      font.pixelSize: 12
                                      font.weight: presetChip.isSelected ? 600 : 500
                                      color: presetChip.isSelected
                                        ? Theme.m3on_secondary_container
                                        : Theme.m3on_surface_variant
                                    }
                                  }

                                  MouseArea {
                                    id: presetMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                      Global[settingRow.propKey] = presetChip.modelData.value
                                      if (settingRow.propKey === "wallSourceIndex") {
                                        Global.wallUseCustom = false
                                      } else if (settingRow.propKey === "wallCustomColor") {
                                        Global.wallUseCustom = true
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // Empty Search State
              ColumnLayout {
                visible: root.visibleSections.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 60
                spacing: 10

                Icon {
                  Layout.alignment: Qt.AlignHCenter
                  text: "search_off"
                  font.pixelSize: 44
                  color: Theme.m3on_surface_variant
                }

                Label {
                  Layout.alignment: Qt.AlignHCenter
                  text: "No settings match \"" + root.searchQuery + "\""
                  font.pixelSize: 16
                  font.bold: true
                  color: Theme.m3on_surface
                }

                Label {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Try searching for font, clock, radius, border, notification, or wallpaper"
                  font.pixelSize: 13
                  color: Theme.m3on_surface_variant
                }
              }
            }
          }

          // Custom Material You Scrollbar Indicator (no QtQuick.Controls dependency)
          Rectangle {
            visible: settingsScroll.contentHeight > settingsScroll.height
            anchors.right: parent.right
            anchors.rightMargin: 6
            width: 5
            radius: 2.5
            color: Theme.m3outline_variant
            opacity: 0.7
            y: Math.max(8, Math.min(parent.height - height - 8, settingsScroll.visibleArea.yPosition * parent.height))
            height: Math.max(32, settingsScroll.visibleArea.heightRatio * parent.height)
          }
        }
      }
    }
  }
}
