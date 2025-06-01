#SingleInstance Force

; ============================================================================
; COMMAND LINE ARGUMENTS
; ============================================================================

; Check for -silent flag
SilentMode := false
for index, param in A_Args {
    if (param = "-silent" || param = "/silent") {
        SilentMode := true
        break
    }
}

; ============================================================================
; CONFIGURATION
; ============================================================================

; Process names (without .exe extension)
LauncherProcess := "Bethesda.net_Launcher"
GameProcess := "eso64"

; Timeout in minutes before closing launcher (when game is not running)
TimeoutMinutes := 30
ForceCloseTimeoutSeconds := 10

; Enable logging (creates a log file)
EnableLogging := true

; ============================================================================
; SCRIPT VARIABLES - DO NOT MODIFY
; ============================================================================

LauncherStartTime := 0
GameLastSeen := 0
IsGameRunning := false
IsLauncherRunning := false
CheckInterval := 10000  ; Check every 10 seconds
LogFile := A_ScriptDir . "\launcher_monitor.log"

; Create system tray menu
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Status", ShowStatus)
A_TrayMenu.Add("Configure", Configure)
A_TrayMenu.Add("View Log", ViewLog)
A_TrayMenu.Add()
A_TrayMenu.Add("Reload Script", ReloadScript)
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "Show Status"
A_IconTip := "Steam Launcher Monitor"

; Initialize
InitializeScript()

; Main timer
SetTimer(CheckProcesses, CheckInterval)

; ============================================================================
; MAIN MONITORING LOGIC
; ============================================================================

CheckProcesses() {
    CurrentTime := A_TickCount

    ; Check if launcher is running
    LauncherPID := ProcessExist(LauncherProcess . ".exe")

    ; Check if game is running
    GamePID := ProcessExist(GameProcess . ".exe")

    ; Update launcher status
    if (LauncherPID > 0) {
        if (!IsLauncherRunning) {
            global IsLauncherRunning := true
            global LauncherStartTime := CurrentTime
            LogMessage("Launcher detected: " . LauncherProcess . ".exe (PID: " . LauncherPID . ")")
        }
    } else {
        if (IsLauncherRunning) {
            global IsLauncherRunning := false
            global LauncherStartTime := 0
            LogMessage("Launcher closed: " . LauncherProcess . ".exe")
        }
    }

    ; Update game status
    if (GamePID > 0) {
        if (!IsGameRunning) {
            global IsGameRunning := true
            global GameLastSeen := CurrentTime
            LogMessage("Game detected: " . GameProcess . ".exe (PID: " . GamePID . ")")
        } else {
            global GameLastSeen := CurrentTime
        }
    } else {
        if (IsGameRunning) {
            global IsGameRunning := false
            LogMessage("Game closed: " . GameProcess . ".exe")
        }
    }

    ; Check if we need to close the launcher
    if (IsLauncherRunning && !IsGameRunning && LauncherStartTime > 0) {
        TimeRunning := (CurrentTime - LauncherStartTime) / 1000 / 60  ; Convert to minutes
        TimeoutThreshold := TimeoutMinutes

        ; If game was running recently, use that as the start time for timeout
        if (GameLastSeen > 0) {
            TimeSinceGame := (CurrentTime - GameLastSeen) / 1000 / 60
            if (TimeSinceGame >= TimeoutThreshold) {
                CloseLauncher()
            }
        } else if (TimeRunning >= TimeoutThreshold) {
            CloseLauncher()
        }
    }

    ; Update tray tip with current status
    UpdateTrayTip()
}

; ============================================================================
; FUNCTIONS
; ============================================================================

CloseLauncher() {
    LogMessage("Timeout reached! Closing launcher: " . LauncherProcess . ".exe")

    ; Try graceful close first
    try {
        WinClose("ahk_exe " . LauncherProcess . ".exe")
        Sleep(ForceCloseTimeoutSeconds * 1000)
    }

    ; Force close if still running
    if (ProcessExist(LauncherProcess . ".exe")) {
        ProcessClose(LauncherProcess . ".exe")
        LogMessage("Force closed launcher: " . LauncherProcess . ".exe")
    }

    ; Reset variables
    global IsLauncherRunning := false
    global LauncherStartTime := 0
    global GameLastSeen := 0

    ; Show notification
    TrayTip("Launcher closed due to inactivity timeout", "Steam Launcher Monitor", "Iconi Mute")
}

LogMessage(Message) {
    if (!EnableLogging)
        return

    TimeStamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    LogEntry := TimeStamp . " - " . Message . "`n"
    FileAppend(LogEntry, LogFile)
}

UpdateTrayTip() {
    Status := "Monitoring: " . LauncherProcess . " / " . GameProcess
    if (IsLauncherRunning) {
        Status .= "`nLauncher: Running"
        if (LauncherStartTime > 0) {
            TimeRunning := (A_TickCount - LauncherStartTime) / 1000 / 60
            Status .= " (" . Round(TimeRunning, 1) . "m)"
        }
    } else {
        Status .= "`nLauncher: Not running"
    }

    if (IsGameRunning) {
        Status .= "`nGame: Running"
    } else {
        Status .= "`nGame: Not running"
        if (GameLastSeen > 0) {
            TimeSince := (A_TickCount - GameLastSeen) / 1000 / 60
            Status .= " (" . Round(TimeSince, 1) . "m ago)"
        }
    }

    A_IconTip := Status
}

; ============================================================================
; GUI AND USER INTERACTION
; ============================================================================

ShowStatus(*) {
    CurrentTime := A_TickCount

    StatusText := "Steam Launcher Monitor Status`n"
    StatusText .= "================================`n`n"
    StatusText .= "Configuration:`n"
    StatusText .= "  Launcher Process: " . LauncherProcess . ".exe`n"
    StatusText .= "  Game Process: " . GameProcess . ".exe`n"
    StatusText .= "  Timeout: " . TimeoutMinutes . " minutes`n`n"

    StatusText .= "Current Status:`n"
    if (IsLauncherRunning) {
        TimeRunning := (CurrentTime - LauncherStartTime) / 1000 / 60
        StatusText .= "  Launcher: Running (" . Round(TimeRunning, 1) . " minutes)`n"
    } else {
        StatusText .= "  Launcher: Not running`n"
    }

    if (IsGameRunning) {
        StatusText .= "  Game: Running`n"
    } else {
        StatusText .= "  Game: Not running`n"
        if (GameLastSeen > 0) {
            TimeSince := (CurrentTime - GameLastSeen) / 1000 / 60
            StatusText .= "  Last seen: " . Round(TimeSince, 1) . " minutes ago`n"
        }
    }

    MsgBox(StatusText, "Steam Launcher Monitor")
}

Configure(*) {
    ConfigGui := Gui("+Resize", "Configure Launcher Monitor")
    ConfigGui.Add("Text", , "Launcher Process Name (without .exe):")
    EditLauncher := ConfigGui.Add("Edit", "w200 vNewLauncher", LauncherProcess)
    ConfigGui.Add("Text", , "Game Process Name (without .exe):")
    EditGame := ConfigGui.Add("Edit", "w200 vNewGame", GameProcess)
    ConfigGui.Add("Text", , "Timeout (minutes):")
    EditTimeout := ConfigGui.Add("Edit", "w200 vNewTimeout", TimeoutMinutes)
    ConfigGui.Add("Text", , "Force Close Timeout (seconds):")
    EditForceTimeout := ConfigGui.Add("Edit", "w200 vNewForceTimeout", ForceCloseTimeoutSeconds)
    CheckLogging := ConfigGui.Add("Checkbox", "vNewLogging" . (EnableLogging ? " Checked" : ""), "Enable Logging")
    ConfigGui.Add("Button", "w100", "Save").OnEvent("Click", SaveConfig)
    ConfigGui.Add("Button", "x+10 w100", "Cancel").OnEvent("Click", (*) => ConfigGui.Destroy())
    ConfigGui.Show()

    SaveConfig(*) {
        global LauncherProcess := EditLauncher.Text
        global GameProcess := EditGame.Text
        global TimeoutMinutes := Integer(EditTimeout.Text)
        global ForceCloseTimeoutSeconds := Integer(EditForceTimeout.Text)
        global EnableLogging := CheckLogging.Value

        ; Save to INI file
        IniWrite(LauncherProcess, A_ScriptDir . "\config.ini", "Settings", "LauncherProcess")
        IniWrite(GameProcess, A_ScriptDir . "\config.ini", "Settings", "GameProcess")
        IniWrite(TimeoutMinutes, A_ScriptDir . "\config.ini", "Settings", "TimeoutMinutes")
        IniWrite(ForceCloseTimeoutSeconds, A_ScriptDir . "\config.ini", "Settings", "ForceCloseTimeoutSeconds")
        IniWrite(EnableLogging, A_ScriptDir . "\config.ini", "Settings", "EnableLogging")

        LogMessage("Configuration updated - Launcher: " . LauncherProcess . ", Game: " . GameProcess . ", Timeout: " . TimeoutMinutes . "m, Force Close: " . ForceCloseTimeoutSeconds . "s")
        MsgBox("Settings have been saved and will take effect immediately.", "Configuration Saved")
        ConfigGui.Destroy()
    }
}

ViewLog(*) {
    if (FileExist(LogFile)) {
        Run("notepad.exe `"" . LogFile . "`"")
    } else {
        MsgBox("No log file found. Logging may be disabled or no events have occurred yet.", "Log File")
    }
}

ReloadScript(*) {
    Reload()
}

InitializeScript() {
    ; Load configuration from INI file if it exists
    ConfigFile := A_ScriptDir . "\config.ini"
    if (FileExist(ConfigFile)) {
        LoadedLauncher := IniRead(ConfigFile, "Settings", "LauncherProcess", LauncherProcess)
        LoadedGame := IniRead(ConfigFile, "Settings", "GameProcess", GameProcess)
        LoadedTimeout := IniRead(ConfigFile, "Settings", "TimeoutMinutes", TimeoutMinutes)
        LoadedForceTimeout := IniRead(ConfigFile, "Settings", "ForceCloseTimeoutSeconds", ForceCloseTimeoutSeconds)
        LoadedLogging := IniRead(ConfigFile, "Settings", "EnableLogging", EnableLogging)

        if (LoadedLauncher != "") {
            global LauncherProcess := LoadedLauncher
            global GameProcess := LoadedGame
            global TimeoutMinutes := Integer(LoadedTimeout)
            global ForceCloseTimeoutSeconds := Integer(LoadedForceTimeout)
            global EnableLogging := Integer(LoadedLogging)
        }
    }

    LogMessage("Script started - Monitoring " . LauncherProcess . ".exe and " . GameProcess . ".exe")

    ; Show initial configuration reminder if using defaults
    if (LauncherProcess = "YourLauncherName") {
        MsgBox("Please right-click the system tray icon and select `"Configure`" to set your launcher and game process names.", "Configuration Required")
    }

    ; Show startup notification (unless in silent mode)
    if (!SilentMode) {
        TrayTip("Steam Launcher Monitor started", "Monitoring " . LauncherProcess . ".exe and " . GameProcess . ".exe", "Iconi Mute")
    }
}

ExitScript(*) {
    LogMessage("Script terminated by user")
    ExitApp()
}

; ============================================================================
; HOTKEYS (Optional)
; ============================================================================

; Ctrl+Alt+S to show status
^!s::ShowStatus()

; Ctrl+Alt+C to configure
^!c::Configure()
