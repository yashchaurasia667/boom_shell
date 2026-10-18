pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // ── Settings App Window Control Signals ──
  signal toggleSettings()
  signal showSettings()
  signal hideSettings()

  // ── 1. General & Typography ──
  property string font: "Maven Pro"
  property string iconFont: "Material Symbols Rounded"
  property int fontSize: 14
  property string terminal: "alacritty"
  property string screenshotCmd: "hyprshot -m region || grim"

  // ── 2. Screen Frame & Geometry ──
  property int pillHeight: 38
  property bool reserveTopSynced: true
  property int reserveTopCustom: 38
  readonly property int reserveTop: root.reserveTopSynced ? root.pillHeight : root.reserveTopCustom
  property int gap: 8
  property int pad: 16
  property int panelRadius: 28
  property int border: 4
  property int borderRadius: 18
  property int earRadius: 10
  property int notchRadius: 16

  // ── 3. Motion & Animations ──
  property bool animationsEnabled: true
  property int durFast: 140
  property int durNormal: 280
  property int durSlow: 450
  property real springOvershoot: 1.55

  readonly property var spring: [0.28, root.springOvershoot, 0.22, 1.0, 1, 1]
  readonly property var smooth: [0.16, 1, 0.3, 1, 1, 1]
  readonly property var standard: [0.2, 0, 0, 1, 1, 1]
  readonly property var emphasized: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
  readonly property var dur: ({
    fast: root.animationsEnabled ? root.durFast : 0,
    normal: root.animationsEnabled ? root.durNormal : 0,
    slow: root.animationsEnabled ? root.durSlow : 0
  })

  // ── 4. Top Bar & Workspaces ──
  property bool barShowWorkspaces: true
  property bool barShowClock: true
  property bool barShowSystemTray: true
  property bool barShowCpuInfo: true
  property bool barShowVolume: true
  property bool barShowBattery: true
  property int barRightSpacing: 12

  property int wsMinSlots: 4
  property int wsSpacing: 10
  property bool wsShowSpecial: true

  property string barClockFormat: "HH:mm"
  property int barClockFontSize: 16
  property bool barClockShowDate: false
  property string barClockDateFormat: "ddd dd MMM"

  property int trayIconSize: 20
  property int trayIconSpacing: 8
  property bool trayStartExpanded: false

  property bool barShowCpuTemp: true
  property int cpuWarnThreshold: 90
  property int tempWarnThreshold: 85

  property real volumeWheelStep: 0.05

  property bool batteryAlwaysShow: false
  property int batteryHighThreshold: 90
  property int batteryMedThreshold: 50
  property int batteryLowThreshold: 20

  // ── 5. Drawers, Popups & Control Center ──
  property bool topDrawerEnabled: true
  property int topDrawerWidth: 618
  property int topDrawerHeight: 460
  property int topDrawerGridGap: 10
  property int topDrawerCardRadius: 20
  property int topDrawerHideDelay: 250
  property string mprisIgnoredPlayers: "Blanket"

  property bool controlCenterEnabled: true
  property int controlCenterWidth: 400
  property int controlCenterHideDelay: 200
  property int hotCornerSize: 20

  property bool quickSlidersEnabled: true
  property int quickSlidersHeight: 150
  property int quickSlidersWidth: 40
  property int quickSlidersSpacing: 12
  property int quickSlidersTriggerWidth: 4

  // ── 6. Notifications ──
  property int notifDefaultTimeout: 5000
  property int notifHistoryLimit: 50
  property bool notifAllowCriticalInDnd: false
  property bool notifDoNotDisturb: false
  property int notifToastWidth: 340

  // ── 7. Desktop Widgets & Overlays ──
  property bool desktopClockEnabled: true
  property string desktopClockFont: "Changa One"
  property int desktopClockFontSize: 220
  property string desktopClockDateFont: "Rowdies Light"
  property int desktopClockDateSize: 28
  property int desktopClockMargins: 20
  property bool desktopClock24h: false
  property string desktopClockDateFormat: "dddd, d MMMM yyyy"

  property bool todoEnabled: true
  property string todoFont: "Maple Mono NF CN"
  property int todoWidth: 400
  property int todoHeight: 400
  property int todoMargins: 10
  property real todoBgOpacity: 0.75

  property int launcherWidth: 800
  property int launcherHeight: 400
  property int launcherMaxResults: 10

  property int clipboardWidth: 650
  property int clipboardHeight: 450
  property int clipboardMaxResults: 500

  // ── 8. Wallpaper Switcher & Matugen ──
  property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wall"
  property string currentWallpaperFile: "/opt/wal.png"
  property int wallpaperPanelWidth: 1290
  property int wallpaperPanelHeight: 500
  property int wallpaperThumbWidth: 300
  property int wallpaperThumbHeight: 188
  property int wallpaperThumbSpacing: 14
  property string matugenMode: "dark"

  property string wallScheme: "scheme-tonal-spot"
  property real wallContrast: 0.0
  property string wallLast: ""
  property int wallSourceIndex: 0
  property bool wallUseCustom: false
  property string wallCustomColor: "#6750a4"

  // ── 9. Power Menu & System Hardware ──
  property int powerMenuWidth: 580
  property int powerMenuHeight: 150
  property string lockCmd: "hyprlock"
  property string logoutCmd: "hyprctl dispatch exit"
  property string rebootCmd: "reboot"
  property string shutdownCmd: "shutdown now"

  property int statsPollInterval: 2000
  property string cpuTempHwmonPath: "/sys/class/hwmon/hwmon5/temp1_input"
  property bool pollGpu: false

  property string backlightDevice: ""
  property int brightnessPollInterval: 2000

  // ── Persistent Shell Configuration (~/.config/quickshell/settings.conf) ──
  Settings {
    id: prefs
    location: "file://" + Quickshell.env("HOME") + "/.config/quickshell/settings.conf"
    category: "ShellSettings"

    property alias font: root.font
    property alias iconFont: root.iconFont
    property alias fontSize: root.fontSize
    property alias terminal: root.terminal
    property alias screenshotCmd: root.screenshotCmd

    property alias pillHeight: root.pillHeight
    property alias reserveTopSynced: root.reserveTopSynced
    property alias reserveTopCustom: root.reserveTopCustom
    property alias gap: root.gap
    property alias pad: root.pad
    property alias panelRadius: root.panelRadius
    property alias border: root.border
    property alias borderRadius: root.borderRadius
    property alias earRadius: root.earRadius
    property alias notchRadius: root.notchRadius

    property alias animationsEnabled: root.animationsEnabled
    property alias durFast: root.durFast
    property alias durNormal: root.durNormal
    property alias durSlow: root.durSlow
    property alias springOvershoot: root.springOvershoot

    property alias barShowWorkspaces: root.barShowWorkspaces
    property alias barShowClock: root.barShowClock
    property alias barShowSystemTray: root.barShowSystemTray
    property alias barShowCpuInfo: root.barShowCpuInfo
    property alias barShowVolume: root.barShowVolume
    property alias barShowBattery: root.barShowBattery
    property alias barRightSpacing: root.barRightSpacing

    property alias wsMinSlots: root.wsMinSlots
    property alias wsSpacing: root.wsSpacing
    property alias wsShowSpecial: root.wsShowSpecial

    property alias barClockFormat: root.barClockFormat
    property alias barClockFontSize: root.barClockFontSize
    property alias barClockShowDate: root.barClockShowDate
    property alias barClockDateFormat: root.barClockDateFormat

    property alias trayIconSize: root.trayIconSize
    property alias trayIconSpacing: root.trayIconSpacing
    property alias trayStartExpanded: root.trayStartExpanded

    property alias barShowCpuTemp: root.barShowCpuTemp
    property alias cpuWarnThreshold: root.cpuWarnThreshold
    property alias tempWarnThreshold: root.tempWarnThreshold

    property alias volumeWheelStep: root.volumeWheelStep

    property alias batteryAlwaysShow: root.batteryAlwaysShow
    property alias batteryHighThreshold: root.batteryHighThreshold
    property alias batteryMedThreshold: root.batteryMedThreshold
    property alias batteryLowThreshold: root.batteryLowThreshold

    property alias topDrawerEnabled: root.topDrawerEnabled
    property alias topDrawerWidth: root.topDrawerWidth
    property alias topDrawerHeight: root.topDrawerHeight
    property alias topDrawerGridGap: root.topDrawerGridGap
    property alias topDrawerCardRadius: root.topDrawerCardRadius
    property alias topDrawerHideDelay: root.topDrawerHideDelay
    property alias mprisIgnoredPlayers: root.mprisIgnoredPlayers

    property alias controlCenterEnabled: root.controlCenterEnabled
    property alias controlCenterWidth: root.controlCenterWidth
    property alias controlCenterHideDelay: root.controlCenterHideDelay
    property alias hotCornerSize: root.hotCornerSize

    property alias quickSlidersEnabled: root.quickSlidersEnabled
    property alias quickSlidersHeight: root.quickSlidersHeight
    property alias quickSlidersWidth: root.quickSlidersWidth
    property alias quickSlidersSpacing: root.quickSlidersSpacing
    property alias quickSlidersTriggerWidth: root.quickSlidersTriggerWidth

    property alias notifDefaultTimeout: root.notifDefaultTimeout
    property alias notifHistoryLimit: root.notifHistoryLimit
    property alias notifAllowCriticalInDnd: root.notifAllowCriticalInDnd
    property alias notifDoNotDisturb: root.notifDoNotDisturb
    property alias notifToastWidth: root.notifToastWidth

    property alias desktopClockEnabled: root.desktopClockEnabled
    property alias desktopClockFont: root.desktopClockFont
    property alias desktopClockFontSize: root.desktopClockFontSize
    property alias desktopClockDateFont: root.desktopClockDateFont
    property alias desktopClockDateSize: root.desktopClockDateSize
    property alias desktopClockMargins: root.desktopClockMargins
    property alias desktopClock24h: root.desktopClock24h
    property alias desktopClockDateFormat: root.desktopClockDateFormat

    property alias todoEnabled: root.todoEnabled
    property alias todoFont: root.todoFont
    property alias todoWidth: root.todoWidth
    property alias todoHeight: root.todoHeight
    property alias todoMargins: root.todoMargins
    property alias todoBgOpacity: root.todoBgOpacity

    property alias launcherWidth: root.launcherWidth
    property alias launcherHeight: root.launcherHeight
    property alias launcherMaxResults: root.launcherMaxResults

    property alias clipboardWidth: root.clipboardWidth
    property alias clipboardHeight: root.clipboardHeight
    property alias clipboardMaxResults: root.clipboardMaxResults

    property alias wallpaperDir: root.wallpaperDir
    property alias currentWallpaperFile: root.currentWallpaperFile
    property alias wallpaperPanelWidth: root.wallpaperPanelWidth
    property alias wallpaperPanelHeight: root.wallpaperPanelHeight
    property alias wallpaperThumbWidth: root.wallpaperThumbWidth
    property alias wallpaperThumbHeight: root.wallpaperThumbHeight
    property alias wallpaperThumbSpacing: root.wallpaperThumbSpacing
    property alias matugenMode: root.matugenMode

    property alias powerMenuWidth: root.powerMenuWidth
    property alias powerMenuHeight: root.powerMenuHeight
    property alias lockCmd: root.lockCmd
    property alias logoutCmd: root.logoutCmd
    property alias rebootCmd: root.rebootCmd
    property alias shutdownCmd: root.shutdownCmd

    property alias statsPollInterval: root.statsPollInterval
    property alias cpuTempHwmonPath: root.cpuTempHwmonPath
    property alias pollGpu: root.pollGpu

    property alias backlightDevice: root.backlightDevice
    property alias brightnessPollInterval: root.brightnessPollInterval
  }

  // ── Persistent Wallpaper & Matugen Config (~/.config/quickshell/wallpaper.conf) ──
  Settings {
    id: wallPrefs
    location: "file://" + Quickshell.env("HOME") + "/.config/quickshell/wallpaper.conf"
    category: "Wallpaper"

    property alias scheme: root.wallScheme
    property alias contrast: root.wallContrast
    property alias last: root.wallLast
    property alias sourceIndex: root.wallSourceIndex
    property alias useCustom: root.wallUseCustom
    property alias customColor: root.wallCustomColor
  }

  // ── Default Values Map & Reset Helpers ──
  readonly property var defaults: ({
    font: "Maven Pro",
    iconFont: "Material Symbols Rounded",
    fontSize: 14,
    terminal: "alacritty",
    screenshotCmd: "hyprshot -m region || grim",

    pillHeight: 38,
    reserveTopSynced: true,
    reserveTopCustom: 38,
    gap: 8,
    pad: 16,
    panelRadius: 28,
    border: 4,
    borderRadius: 18,
    earRadius: 10,
    notchRadius: 16,

    animationsEnabled: true,
    durFast: 140,
    durNormal: 280,
    durSlow: 450,
    springOvershoot: 1.55,

    barShowWorkspaces: true,
    barShowClock: true,
    barShowSystemTray: true,
    barShowCpuInfo: true,
    barShowVolume: true,
    barShowBattery: true,
    barRightSpacing: 12,

    wsMinSlots: 4,
    wsSpacing: 10,
    wsShowSpecial: true,

    barClockFormat: "HH:mm",
    barClockFontSize: 16,
    barClockShowDate: false,
    barClockDateFormat: "ddd dd MMM",

    trayIconSize: 20,
    trayIconSpacing: 8,
    trayStartExpanded: false,

    barShowCpuTemp: true,
    cpuWarnThreshold: 90,
    tempWarnThreshold: 85,

    volumeWheelStep: 0.05,

    batteryAlwaysShow: false,
    batteryHighThreshold: 90,
    batteryMedThreshold: 50,
    batteryLowThreshold: 20,

    topDrawerEnabled: true,
    topDrawerWidth: 618,
    topDrawerHeight: 460,
    topDrawerGridGap: 10,
    topDrawerCardRadius: 20,
    topDrawerHideDelay: 250,
    mprisIgnoredPlayers: "Blanket",

    controlCenterEnabled: true,
    controlCenterWidth: 400,
    controlCenterHideDelay: 200,
    hotCornerSize: 20,

    quickSlidersEnabled: true,
    quickSlidersHeight: 150,
    quickSlidersWidth: 40,
    quickSlidersSpacing: 12,
    quickSlidersTriggerWidth: 4,

    notifDefaultTimeout: 5000,
    notifHistoryLimit: 50,
    notifAllowCriticalInDnd: false,
    notifDoNotDisturb: false,
    notifToastWidth: 340,

    desktopClockEnabled: true,
    desktopClockFont: "Changa One",
    desktopClockFontSize: 220,
    desktopClockDateFont: "Rowdies Light",
    desktopClockDateSize: 28,
    desktopClockMargins: 20,
    desktopClock24h: false,
    desktopClockDateFormat: "dddd, d MMMM yyyy",

    todoEnabled: true,
    todoFont: "Maple Mono NF CN",
    todoWidth: 400,
    todoHeight: 400,
    todoMargins: 10,
    todoBgOpacity: 0.75,

    launcherWidth: 800,
    launcherHeight: 400,
    launcherMaxResults: 10,

    clipboardWidth: 650,
    clipboardHeight: 450,
    clipboardMaxResults: 500,

    wallpaperDir: Quickshell.env("HOME") + "/Pictures/wall",
    currentWallpaperFile: "/opt/wal.png",
    wallpaperPanelWidth: 1290,
    wallpaperPanelHeight: 500,
    wallpaperThumbWidth: 300,
    wallpaperThumbHeight: 188,
    wallpaperThumbSpacing: 14,
    matugenMode: "dark",

    wallScheme: "scheme-tonal-spot",
    wallContrast: 0.0,
    wallSourceIndex: 0,
    wallUseCustom: false,
    wallCustomColor: "#6750a4",

    powerMenuWidth: 580,
    powerMenuHeight: 150,
    lockCmd: "hyprlock",
    logoutCmd: "hyprctl dispatch exit",
    rebootCmd: "reboot",
    shutdownCmd: "shutdown now",

    statsPollInterval: 2000,
    cpuTempHwmonPath: "/sys/class/hwmon/hwmon5/temp1_input",
    pollGpu: false,

    backlightDevice: "",
    brightnessPollInterval: 2000
  })

  function isModified(key: string): bool {
    if (!(key in defaults)) return false
    const cur = root[key]
    const def = defaults[key]
    if (typeof def === "number") {
      return Math.abs(cur - def) > 0.0005
    }
    return cur !== def
  }

  function resetKey(key: string): void {
    if (key in defaults) {
      root[key] = defaults[key]
    }
  }

  function resetKeys(keys: var): void {
    for (let i = 0; i < keys.length; i++) {
      resetKey(keys[i])
    }
  }

  function resetAll(): void {
    const keys = Object.keys(defaults)
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i]
      root[k] = defaults[k]
    }
  }

  // ── Shared Matugen Re-apply Process ──
  property bool matugenApplying: false

  Process {
    id: matugenProc
    property string targetPath: ""
    command: [
      "sh", "-c",
      "case \"$5\" in "
      + "hex:*) matugen color hex \"${5#hex:}\" -m \"$6\" -t \"$2\" --contrast=\"$3\" ;; "
      + "*) img=\"$1\"; [ -f \"$img\" ] || img=\"$4\"; "
      + "if [ -f \"$img\" ]; then matugen image \"$img\" -m \"$6\" -t \"$2\" --contrast=\"$3\" --source-color-index \"${5#idx:}\"; fi ;; "
      + "esac",
      "sh",
      matugenProc.targetPath || root.wallLast,
      root.wallScheme,
      root.wallContrast.toFixed(2),
      root.currentWallpaperFile,
      root.wallUseCustom ? "hex:" + root.wallCustomColor : "idx:" + root.wallSourceIndex,
      root.matugenMode
    ]
    onExited: {
      root.matugenApplying = false
    }
  }

  function regenerateMatugenTheme(): void {
    if (root.matugenApplying) return
    root.matugenApplying = true
    matugenProc.targetPath = root.wallLast
    matugenProc.running = true
  }
}
