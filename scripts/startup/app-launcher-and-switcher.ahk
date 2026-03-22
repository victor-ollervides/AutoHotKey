#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1

; User-specific paths (avoids hardcoding USERNAME)
userLocalAppData := "C:\Users\" . A_UserName . "\AppData\Local"
; SetWorkingDir, %A_ScriptDir%
#Warn ; Enable warnings to assist with detecting common errors.

; Check if running as administrator, if not, restart with admin privileges
; if not A_IsAdmin
; {
;     Run *RunAs "%A_ScriptFullPath%"
;     ExitApp
; }

; Check if running as administrator, if not, restart with admin privileges
; if not A_IsAdmin
; {
;     Run *RunAs "%A_ScriptFullPath%"
;     ExitApp
; }

; "C:\V\Software\PC Equalizer Free\PCEqualizer.exe"
; "C:\Program Files\Firefox Developer Edition\firefox.exe"

; ❯❯ NOT USED
launchOrSwitchJDownloader()
{
    ; DetectHiddenWindows, Off
    Process, Exist, JDownloader2.exe
    status := %ErrorLevel%

    if (status = 0)
    {
        Run userLocalAppData . "\JDownloader 2.0\JDownloader2.exe"
    }
    if WinActive("ahk_exe JDownloader2.exe")
    {
        ; msgbox, "IF" ;WinActive("ahk_class SunAwtFrame")
        ; WinMinimize, ahk_class SunAwtFrame
        WinMinimize, ahk_exe JDownloader2.exe
    }
    ; else if WinExist("ahk_class SunAwtFrame")
    else if WinExist("ahk_exe JDownloader2.exe")
    {
        ; WinActivateBottom, ahk_class SunAwtFrame
        WinActivateBottom, ahk_exe JDownloader2.exe
    }
    Return
}

; ahk_class Qt5158QWindowIcon
; ahk_exe qbittorrent.exe
; ahk_pid 21292
; ahk_id 67658
; ❯❯ NOT USED
launchOrSwitchQBittorrent()
{
    DetectHiddenWindows, Off
    Process, Exist, qbittorrent.exe
    status := %ErrorLevel%

    if (status = 0)
    {
        Run "C:\Program Files\qbittorrent\qbittorrent.exe"
    }
    if WinActive("ahk_exe qbittorrent.exe")
    {
        ; WinMinimize, ahk_class SunAwtFrame
        WinMinimize, ahk_exe qbittorrent.exe
    }
    ; else if WinExist("ahk_class SunAwtFrame")
    else if WinExist("ahk_exe qbittorrent.exe")
    {
        ; WinActivateBottom, ahk_class SunAwtFrame
        WinActivateBottom, ahk_exe qbittorrent.exe
    }

    Return
}

launchOrSwitchBitwig()
{
    DetectHiddenWindows, Off
    Process, Exist, "Bitwig Studio.exe"
    status := %ErrorLevel%

    if (status = 0)
    {
        Run "C:\V\Bitwig Studio\6.0\Bitwig Studio.exe"
    }
    if WinActive("ahk_class bitwig")
    {
        WinMinimize, ahk_class bitwig
    }
    else if WinExist("ahk_class bitwig")
    {
        WinActivateBottom, ahk_class bitwig
    }

    Return
}

; Ctrl+Shift+D - Open Display Settings
; ^+d::
;     Run, ms-settings:display
; return

; Ctrl+Shift+N - Open NVIDIA Control Panel/App
; ^+n::
;     ; Try to open NVIDIA App first
;     Run, "C:\Program Files\NVIDIA Corporation\NVIDIA App\CEF\NVIDIA App.exe"
;     Sleep, 1000
;     ; If that fails, try NVIDIA Control Panel
;     if WinExist("NVIDIA App") {
;         WinActivate
;     }
; else {
;     Run, nvcplui.exe
; }
; return

; Helper function to find the correct NVIDIA Control Panel path
getNvidiaControlPanelPath()
{
    ; Base path for WindowsApps
    basePath := "C:\Program Files\WindowsApps"

    ; Search for NVIDIA Control Panel directory
    Loop, Files, %basePath%\NVIDIACorp.NVIDIAControlPanel_*_x64__56jybvy8sckqj, D
    {
        testPath := A_LoopFileFullPath . "\nvcplui.exe"
        if FileExist(testPath)
            return testPath
    }

    ; Fallback to hardcoded path if dynamic search fails
    return "C:\Program Files\WindowsApps\NVIDIACorp.NVIDIAControlPanel_8.1.968.0_x64__56jybvy8sckqj\nvcplui.exe"
}

; ❯❯ NOT USED
launchOrSwitch_NvidiaControlPanel()
{
    nvPath := getNvidiaControlPanelPath()
    launchOrSwitchApp("nvcplui.exe", nvPath, true)
    Return
}

; ❯❯ NOT USED
launchOrSwitch_NvidiaApp()
{
    if WinActive("ahk_exe NVIDIA App.exe")
    {
        WinMinimize, ahk_exe NVIDIA App.exe
    }
    else if WinExist("ahk_exe NVIDIA App.exe")
    {
        WinActivateBottom, ahk_exe NVIDIA App.exe
    }
    Else
    {
        Run "C:\Program Files\NVIDIA Corporation\NVIDIA App\CEF\NVIDIA App.exe"
    }

    Return
}

launchOrSwitchApp(appName, appPath, minimizeIfMulipleWindows := true, windowClass := "")
{
    ; If no specific window class is provided, use exe name as default
    app := windowClass ? "ahk_class " . windowClass : "ahk_exe " . appName

    ; Check if process exists
    Process, Exist, %appName%
    appRunning := ErrorLevel

    ; Check if any window exists
    if WinExist(app)
    {
        ; Get count of windows
        WinGet, appCount, Count, %app%

        ; If the app is already active, handle cycling
        if WinActive(app)
        {
            ; Store the current active window ID
            WinGet, currentWinId, ID, A
            ; msgbox, "currentWinId: " %currentWinId%

            ; If there are multiple windows
            if (appCount > 1)
            {
                ; msgbox, "appCount: " %appCount%
                ; Move current window to bottom
                if(minimizeIfMulipleWindows == true)
                {
                    WinSet, Bottom,, ahk_id %currentWinId%
                    WinActivate, %app%
                }
                else ; and activate the next window
                {
                    WinActivateBottom, %app%
                    ; WinActivate, %app%
                    ; WinRestore, %app%
                }
            }
            else ; Only one window exists, minimize or restore it
            {
                ;░ https://www.autohotkey.com/docs/v1/lib/WinGet.htm#MinMax
                ; MinMax: Retrieves the minimized/maximized state for a window.
                ; WinGet, OutputVar, MinMax , WinTitle, WinText, ExcludeTitle, ExcludeText
                ; -1: The window is minimized.
                ; 1: The window is maximized.
                ; 0: The window is neither minimized nor maximized. Normal state.
                WinGet, state, MinMax, ahk_id %currentWinId%

                if (state = 0 || state = 1)
                    WinMinimize, ahk_id %currentWinId%
                ; WinMinimize, ahk_exe JDownloader2.exe
                else if (state = -1) ; Minimized
                    WinRestore, ahk_id %currentWinId%
                ; WinActivateBottom, ahk_exe %currentWinId%

            }
        }
        else
        {
            ; App exists but is inactive, bring it to foreground
            WinActivate, %app%
        }
    }
    else if (appRunning)
    {
        ; App is running but no visible window – attempt to restore
        WinGet, oStyle, Style, %app%
        if !(oStyle & 0x10000000) ; Check if WS_VISIBLE is missing
            WinShow, %app%
        else
            Run, %appPath%  ; Fallback to launching app
    }
    else
    {
        ; No process running, so launch it
        Run, %appPath%
    }
    Return
}

moveMouseAtCenterOfActiveApp(sleepTime = 0, a = 2, b = 2) {
    ; Send #0 ; Presses Windows key + 0
    ; WinWaitActive, ahk_class Shell_TrayWnd ; Wait for the taskbar to become active again
    Sleep sleepTime ; Wait for a short moment for the application to open completely
    WinGetPos, , , width, height, a ; Get the position of the active window
    MouseMove, width / a, height / b ; Move the cursor to the center of the active window
    ; MouseMove, 2000, -1990 ; Move the cursor to the center of the active window
}

; AHK v2
; ^Numpad0::Send("^#0")
; ^Numpad1::Send("^#1")
; ^Numpad2::Send("^#2")
; ^Numpad3::Send("^#3")
; ^Numpad4::Send("^#4")
; ^Numpad5::Send("^#5")
; ^Numpad6::Send("^#6")
; ^Numpad7::Send("^#7")
; ^Numpad8::Send("^#8")
; ^Numpad9::Send("^#9")

; Win + [0-9] : Switch between opened windows
^Numpad0::Send ^#0
^Numpad1::Send ^#1
^Numpad2::Send ^#2
^Numpad3::Send ^#3
^Numpad4::Send ^#4
^Numpad5::Send ^#5
^Numpad6::Send ^#6
^Numpad7::Send ^#7
^Numpad8::Send ^#8
^Numpad9::Send ^#9`

#c::launchOrSwitchApp("Code.exe", "C:\Program Files\Microsoft VS Code\Code.exe", true)

; !`::launchOrSwitchApp("explorer.exe", "C:\Windows\SysWOW64\explorer.exe", ??true) ; ❌ not working with false
!`::Send ^#6 ; -> Switches between Windows Explorer folders
; !+??`::Send ??^#6 ; ❌ Cycles backward through Windows Explorer folders

; #0::Send ^#0
; #1::Send ^#1
; #2::Send ^#2
; #3::Send ^#3
; #4::Send ^#4
; #5::Send ^#5
; #6::Send ^#6
; #7::Send ^#7
; #8::Send ^#8
; #9::Send ^#9

;❌ Avoid using `LCtrl & Numpad(0–9)`. If a macro is bound to `^!Numpad8` (e.g., `launchOrSwitch_NvidiaApp`), it will never be triggered because `LCtrl & Numpad8` has higher priority and fires first.
; LCtrl & Numpad0::Send ^#0
; LCtrl & Numpad1::Send ^#1
; LCtrl & Numpad2::Send ^#2
; LCtrl & Numpad3::Send ^#3
; LCtrl & Numpad4::Send ^#4
; LCtrl & Numpad5::Send ^#5
; LCtrl & Numpad6::Send ^#6
; LCtrl & Numpad7::Send ^#7
; LCtrl & Numpad8::Send ^#8
; LCtrl & Numpad9::Send ^#9

; ; NumpadClear::Send ^#5
; ; LCtrl & Numpad5::Send ^#5
; ; RCtrl & Numpad5::Send #5

+#x::launchOrSwitchApp("WindowsTerminal.exe", "C:\Program Files\WindowsApps\Microsoft.WindowsTerminalPreview_1.24.2812.0_x64__8wekyb3d8bbwe\WindowsTerminal.exe", true)
#Enter::launchOrSwitchApp("WindowsTerminal.exe", "C:\Program Files\WindowsApps\Microsoft.WindowsTerminalPreview_1.24.2812.0_x64__8wekyb3d8bbwe\WindowsTerminal.exe", true)

; a::launchOrSwitchMPVPlayer()
NumpadIns::launchOrSwitchApp("mpv.exe", "C:\Program Files\mpv\mpv.exe", true)
^NumpadIns::launchOrSwitchApp("mpv.exe", "C:\Program Files\mpv\mpv.exe", false)

^!+F11::launchOrSwitchApp("JDownloader2.exe", "C:\V\Software\JDownloader 2\JDownloader2.exe", true)
; ^!+F11::launchOrSwitchJDownloader()
; ^Media_Prev::launchOrSwitchJDownloader()
; ^#Numpad9::launchOrSwitchJDownloader()
; !#Numpad3::launchOrSwitchJDownloader()

^!+F12::launchOrSwitchApp("qbittorrent.exe", "C:\Program Files\qbittorrent\qbittorrent.exe", false)
; ^!F12::launchOrSwitchQBittorrent()
; ^Media_Next::launchOrSwitchQBittorrent()
; ^#Numpad4::launchOrSwitchQBittorrent()
; !#Numpad4::launchOrSwitchQBittorrent()
; ScrollLock::launchOrSwitchQBittorrent()

^!Numpad0::
    launchOrSwitchBitwig()
    ; launchOrSwitchApp("Bitwig Studio.exe", "C:\V\Bitwig Studio\6.0\Bitwig Studio.exe")
; moveMouseAtCenterOfActiveApp(0, 2, 2.5)
; moveMouseAtCenterOfActiveApp(0, 1.818, 2)
; moveMouseAtCenterOfActiveApp(0, 1.818, 3.25)
return

; ^NumpadDown::launchOrSwitchApp("azuredatastudio.exe", "C:\Program Files\Azure Data Studio", false)
^!Numpad2::launchOrSwitchApp("azuredatastudio.exe", "C:\Program Files\Azure Data Studio", false)

^!Numpad3::
    launchOrSwitchApp("msedge.exe", "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", false)
; moveMouseAtCenterOfActiveApp()
return

; NumpadPgup::launchOrSwitch_NvidiaControlPanel()
; ^!Numpad8::launchOrSwitch_NvidiaApp()
^!Numpad9::launchOrSwitchApp("NVIDIA App.exe", "C:\Program Files\NVIDIA Corporation\NVIDIA App\CEF\NVIDIA App.exe", true)

; - Numpad_OFF: NumpadLeft
; * Numpad_ON: Shift + Numpad4
; ^NumpadLeft::launchOrSwitchApp("firefox.exe", "C:\Program Files\Mozilla Firefox\firefox.exe", true)
^!Numpad4::launchOrSwitchApp("firefox.exe", "C:\Program Files\Mozilla Firefox\firefox.exe", true)

; Avoid using NumpadClear — it prevents MPV from recognizing the KP_BEGIN key,
; which is needed for the "Reset zoom/pan" function.
^!Numpad5::launchOrSwitchApp("chrome.exe", userLocalAppData . "\Google\Chrome SxS\Application\chrome.exe", true)

; RCtrl & Numpad6::launchOrSwitchApp("vivaldi.exe", userLocalAppData . "\Vivaldi\Application\vivaldi.exe", true)

; ^NumpadUp: Ctrl + Shift + Numpad8
; ^NumpadUp::launchOrSwitchApp( "Obsidian.exe", "C:\Program Files\Obsidian\Obsidian.exe", false)
; ^!Numpad8::launchOrSwitchApp( "Obsidian.exe", "C:\Program Files\Obsidian\Obsidian.exe", false)

;▓ DO NOT USE -> 🔳 White Flash When Opening
; F24::launchOrSwitchApp("sublime_text.exe", "C:\Program Files\Sublime Text\sublime_text.exe", true)

;▓ SNAGIT:  Sometimes it works, sometimes it doesn't.
; ^!Numpad8::launchOrSwitchSnagitEditor()
