#NoEnv
#SingleInstance, Force
SendMode, Input
; SetBatchLines, -1
; SetWorkingDir, %A_ScriptDir%

; Check if running as administrator, if not, restart with admin privileges
; if not A_IsAdmin
; {
;     Run *RunAs "%A_ScriptFullPath%"
;     ExitApp
; }

; Initialize an array to store the last activated window IDs
global lastTwoWindows := [] ; Will store the last few windows for cycling

; --- Get the initial active window and pre-populate ---
WinGet, currentActiveId, ID, A
if (currentActiveId) {
    lastTwoWindows.Push(currentActiveId)
}

; --- Hook to detect window activation ---
Gui +LastFound
hWnd := WinExist()
DllCall("RegisterShellHookWindow", "UInt", hWnd)
OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK"), "ShellHookMsg")
Return ; Auto-execute section ends here

ShellHookMsg(wParam, lParam) {
    global lastTwoWindows

    if (wParam = 4 || wParam = 32772) {
        activeId := lParam
        if (activeId = 0) ; Sometimes returns 0, ignore
            return

        ; Remove the new active window ID if it already exists to avoid duplicates and keep order
        Loop, % lastTwoWindows.MaxIndex()
        {
            if (lastTwoWindows[A_Index] = activeId)
            {
                lastTwoWindows.RemoveAt(A_Index)
                Break
            }
        }

        ; Add the new active window ID to the beginning of the array
        lastTwoWindows.InsertAt(1, activeId)
        while (lastTwoWindows.MaxIndex() > 5)
        {
            lastTwoWindows.Pop()
        }
    }
}

; --- Hotkey to cycle through the windows ---
; LAlt & Esc::
LAlt & CapsLock::
    global lastTwoWindows

    WinGet, currentId, ID, A ; Get the currently active window

    ; Find the next window to switch to
    targetWindowId := ""

    ; Look for the next valid window in our history that's not the current one
    Loop, % lastTwoWindows.MaxIndex()
    {
        id := lastTwoWindows[A_Index]
        ; Skip the current window and check if the window still exists
        if (id != currentId && WinExist("ahk_id " . id)) {
            targetWindowId := id
            break
        }
    }

    ; If we found a target window, activate it
    if (targetWindowId != "") {
        WinGet, winState, MinMax, ahk_id %targetWindowId%
        if (winState = -1) { ; If minimized
            WinRestore, ahk_id %targetWindowId%
        }
        WinActivate, ahk_id %targetWindowId%
    }
Return