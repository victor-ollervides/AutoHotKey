#NoEnv
#SingleInstance, Force
; SendMode, Input
; SetBatchLines, -1
; SetWorkingDir, %A_ScriptDir%

;░ http://xahlee.info/mswin/autohotkey_toggle_maximize_window.html
; description: toggle maximize/restore current window

; Check if running as administrator, if not, restart with admin privileges
; if not A_IsAdmin
; {
;     Run *RunAs "%A_ScriptFullPath%"
;     ExitApp
; }

toggleMaxWindow()
{
    WinGet, WinState, MinMax, A
    if (WinState = 1)
    {
        WinRestore, A
    }
    else
    {
        WinMaximize, A
    }
}

+NumpadAdd::toggleMaxWindow()
+NumpadSub::WinMinimize, A
