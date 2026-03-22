#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

; Track the last 3 windows and current position in the cycle
global windowCycle := []
global cyclePosition := 1

; --- Hotkey to cycle through the last 3 windows ---
; LAlt & CapsLock::
#CapsLock::
    WinGet, currentId, ID, A ; Get the currently active window

    ; Check if current window is already in our cycle
    currentInCycle := false
    currentPosition := 0
    Loop, % windowCycle.MaxIndex()
    {
        if (windowCycle[A_Index] = currentId) {
            currentInCycle := true
            currentPosition := A_Index
            break
        }
    }

    ; If current window is not in cycle, add it
    if (!currentInCycle) {
        ; Add current window to the cycle
        windowCycle.InsertAt(1, currentId)

        ; Keep only the last 3 windows
        while (windowCycle.MaxIndex() > 3) {
            windowCycle.Pop()
        }

        cyclePosition := 1
    } else {
        ; Current window is in cycle, update our position
        cyclePosition := currentPosition
    }

    ; Find the next valid window to switch to
    targetWindow := ""
    attempts := 0
    maxAttempts := windowCycle.MaxIndex()

    ; Try to find the next valid window in the cycle
    while (attempts < maxAttempts && targetWindow = "") {
        ; Move to next position with wraparound
        cyclePosition := cyclePosition + 1
        if (cyclePosition > windowCycle.MaxIndex()) {
            cyclePosition := 1
        }

        id := windowCycle[cyclePosition]

        ; Skip the current window and check if window exists
        if (id != currentId && WinExist("ahk_id " . id)) {
            targetWindow := id
        }

        attempts++
    }

    ; If we found a valid window, switch to it
    if (targetWindow != "") {
        ; Activate the window
        WinGet, winState, MinMax, ahk_id %targetWindow%
        if (winState = -1) { ; If minimized
            WinRestore, ahk_id %targetWindow%
        }
        WinActivate, ahk_id %targetWindow%
    }
Return