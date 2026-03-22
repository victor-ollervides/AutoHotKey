#Warn ; Enable warnings to assist with detecting common errors.
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force
SendMode, Input ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir, %A_ScriptDir%; Ensures a consistent starting directory.

; This AutoHotKey script is a hotkey-based window management tool that allows you to move and resize windows using the numeric keypad in combination with the Windows key (LWin) and/or the right Windows key (RWin).
; The script supports multiple monitors and automatically detects the number of monitors present.

; LEFT_OFFSET := 11
OFFSET := 11
; This line retrieves the number of monitors (screens) attached to the system and stores it in the variable Mo. The parameter 80 (SM_CMONITORS) specifies the system metric used to determine the number of monitors.
SysGet, Mo, 80 ;Number of monitors
; This initiates a loop that will iterate Mo times, where Mo is the number of monitors retrieved in the previous step.
Loop, % Mo
{ ;capture the MonitorWorkAreas of your monitors
    ; This line assigns the current loop index (1-based) to the variable n. It is used to differentiate between different monitors in the loop.
    n := A_Index
    ; This line captures the work area (excluding taskbars and other toolbars) of the monitor indicated by the current loop index and stores it in variables such as Mo1, Mo2, etc., depending on the number of monitors.
    SysGet, Mo%n%, MonitorWorkArea, %n%
    ; These lines calculate and store the width and height of the monitor's work area using the Right, Left, Bottom, and Top properties obtained in the previous step.
    Mo%n%Width := Mo%n%Right - Mo%n%Left
    Mo%n%Height := Mo%n%Bottom - Mo%n%Top
}
; This indicates the end of the loop and the completion of the script's setup.
Return

; After the setup, the script defines a series of hotkey combinations that allow you to move and resize windows on the active monitor using the numeric keypad and Windows key combinations. Here's how the hotkeys work:
#If (LR := GetKeyState("LWin")) Or (LR := Min(Mo, 2 * GetKeyState("RWin")))
    ; moves the active window to the top-left quadrant of the monitor's work area (top-left quarter).
    #Numpad1::WinMove, A,, Mo%LR%Left - OFFSET, (Mo%LR%Top + Mo%LR%Height // 2) - 1, (Mo%LR%Width // 2) + (OFFSET*2), (Mo%LR%Height // 2) + OFFSET
    ; moves the active window to the bottom half of the monitor's work area.
    #Numpad2::WinMove, A,, Mo%LR%Left - OFFSET, (Mo%LR%Top + Mo%LR%Height // 2) - 1, Mo%LR%Right + (OFFSET*2), (Mo%LR%Bottom // 2) + OFFSET
    ; moves the active window to the bottom-right quadrant of the monitor's work area (bottom-right quarter).
    #Numpad3::WinMove, A,, ((Mo%LR%Left + (Mo%LR%Width // 2)) - (OFFSET)), (Mo%LR%Top + (Mo%LR%Height // 2)) - 1, ((Mo%LR%Width // 2) + (OFFSET*2)), ((Mo%LR%Height // 2) + OFFSET)
    ; moves the active window to the left half of the monitor's work area.
    #Numpad4::WinMove, A,, (Mo%LR%Left - OFFSET), (Mo%LR%Top), ((Mo%LR%Width // 2) + (OFFSET*2)+1), (Mo%LR%Height + OFFSET-1)
    #!Numpad4::WinMove, A,, (Mo%LR%Left - OFFSET), (Mo%LR%Top), ((Mo%LR%Width // 2) + (OFFSET*2)+1), (Mo%LR%Height - 150)

    ; maximizes the active window to fill the entire monitor's work area.
    !#Numpad5::
        WinMove, A,,Mo%LR%Left,Mo%LR%Top,Mo%LR%Width,Mo%LR%Height
        WinMaximize, A
    Return

    ; the script now calculates the position to center the active window on the current monitor.
    ; It uses the WinGetPos function to obtain the current window position and size,
    ; and then calculates the new position (MonX and MonY) to center the window within the monitor's work area.
    #Numpad5::
        WinGetPos, WinX, WinY, WinWidth, WinHeight, A
        MonX := Mo%LR%Left + (Mo%LR%Width - WinWidth) // 2
        MonY := Mo%LR%Top + (Mo%LR%Height - WinHeight) // 2
        WinMove, A,, MonX, MonY
    Return

    ; #Numpad0:WinMove, A,, 0 - 12,          0,         800, 400
    ; #Numpad0:WinMove, A,, Mo%LR%Left - 12, Mo%LR%Top, 1465, 400
    ; #Numpad0:WinMove, A,, Mo%LR%Left - 12, Mo%LR%Top + 1750, 3000, 600

    ;❯❯ WinMove, ${WinTitle}, ${WinText}, ${X}, ${Y}, ${[Width}, ${Height}, ${ExcludeTitle}, ${ExcludeText]}
    ; SHORTCUT::WinMove, A,, X===Mo%LR%Left, Y===Mo%LR%Top, Width===Mo%LR%Width===Mo%LR%Right, Height===Mo%LR%Height===Mo%LR%Bottom
    ; The following lines are identical, Width === Right, Height === Bottom
    ; #Numpad0:WinMove, A,, Mo%LR%Left, Mo%LR%Top, Mo%LR%Width, Mo%LR%Height
    ; #Numpad0:WinMove, A,, Mo%LR%Left, Mo%LR%Top, Mo%LR%Right, Mo%LR%Bottom

    ; Calls WinMove only for monitor one (Mo1)
    ; #Numpad0:WinMove, A,, -12, 1620, 3000, 552
    #Numpad0::WinMove, A,, -OFFSET-1, 1620, (3840 + (OFFSET*2)+2), 540+OFFSET+1 ;2160 / 4 = 540 * 3 = 1620

    ;░ This is used in Bitwig Studio to conceal parts of the interface that are not relevant to my workflow.
    ; !#Numpad2:WinMove, A,, -OFFSET, (Mo%LR%Height - (Mo%LR%Height // 4)), (Mo%LR%Right + (OFFSET*2)), (Mo%LR%Bottom // 4) +OFFSET
    ; !#Numpad2::WinMove, A,, -OFFSET, (Mo%LR%Height - (Mo%LR%Height // 4)), (Mo%LR%Width + (OFFSET*2)), (Mo%LR%Height // 4) +OFFSET
    ; !#Numpad2::WinMove, A,, -OFFSET, (Mo%LR%Height - (Mo%LR%Height // 5.2)), (Mo%LR%Width + (OFFSET*2)), (Mo%LR%Height // 3.3) +OFFSET
    ; !#Numpad2::WinMove, A,, -OFFSET, (Mo%LR%Height - (Mo%LR%Height // 5.2)), (Mo%LR%Width + (OFFSET*2)), (Mo%LR%Height // 2) +OFFSET
    !#Numpad2::WinMove, A,, -OFFSET, (Mo%LR%Height - (Mo%LR%Height // 5.2)), (Mo%LR%Width + (OFFSET*2)), (Mo%LR%Height) +OFFSET

    ;░ This is used with video playback tools such as Nuendo 12 Video Player, XJadeo, or VidPlayVSTv2
    ;░ (the Bitwig Video Player VST window) for proper window handling or display adjustments.
    ; !#Numpad8::WinMove, A,, Mo%LR%Left, Mo%LR%Top, Mo%LR%Width, Mo%LR%Height // 1.120 ; 1.117
    ; !#Numpad8::WinMove, A,, Mo%LR%Left - 20, Mo%LR%Top - 60, Mo%LR%Width + 60, Mo%LR%Height // 1.08
    !#Numpad8::WinMove, A,, Mo%LR%Left - 20, Mo%LR%Top - 60, Mo%LR%Width + 60, Mo%LR%Height // 1.040    ; 1.24 │ 1.15

    ;░ TODO: Reasign. Used for Edge browser when reading a PDF Book with Dark Mode enabled
    #!Numpad7::WinMove, A,, (-OFFSET-1), (0), ((Mo%LR%Width // 2) + 200), (((Mo%LR%Height // 4) * 3) + 150)
    ; !#Numpad4::WinMove, A,, (-OFFSET-1), (400), ((Mo%LR%Width // 2) + 150), (((Mo%LR%Height // 4) * 3) + 150)


    ; moves the active window to the right half of the monitor's work area.
    #Numpad6::WinMove, A,, ((Mo%LR%Left + (Mo%LR%Width // 2)) - (OFFSET-1)) , (Mo%LR%Top), ((Mo%LR%Width // 2) + (OFFSET*2)), (Mo%LR%Height + OFFSET-1)
    ;░ Used in Bitwig Studio to selectively hide unwanted interface sections
    #!Numpad6::WinMove, A,, ((Mo%LR%Left + (Mo%LR%Width // 2)) - (OFFSET-1)) , (Mo%LR%Top), ((Mo%LR%Width // 2) + (OFFSET*2)), (Mo%LR%Height - 150)

    ; moves the active window to the top-left quarter of the monitor's work area (top-left quarter).
    #Numpad7::WinMove, A,, Mo%LR%Left - OFFSET, Mo%LR%Top, ((Mo%LR%Width // 2) + (OFFSET*2)), ((Mo%LR%Height // 2) + OFFSET+1)

    ; moves the active window to the top half of the monitor's work area.
    #Numpad8::WinMove, A,, Mo%LR%Left - OFFSET, Mo%LR%Top, Mo%LR%Width + (OFFSET*2), (Mo%LR%Height // 2) + OFFSET+1

    ; moves the active window to the top-right quadrant of the monitor's work area (top-right quarter).
    #Numpad9::WinMove, A,, ((Mo%LR%Left + (Mo%LR%Width // 2)) - (OFFSET)), (Mo%LR%Top), ((Mo%LR%Width // 2) + (OFFSET*2)), ((Mo%LR%Height // 2) + OFFSET+1)

    ; 1024x768 — Arch Linux in Hyper-V VM at 200% scaling (Windows 10 host)
    ^#Numpad1::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width // 2) + (138), (Mo%LR%Height // 2) + 544

    ; 1024x1024 — Arch Linux in Hyper-V VM at 200% scaling (Windows 10 host)
    ^#Numpad2::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width) - 1270, (Mo%LR%Height) - 24

    ; 1920x1080 - Arch Linux in Hyper-V VM at 193% scaling (Windows 10 host)
    ^#Numpad6::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width) - 125, (Mo%LR%Height) + 12

    ; 1920x1080 - Arch Linux in Hyper-V VM at 194% scaling (Windows 10 host)
    ^#Numpad7::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width) - 106, (Mo%LR%Height) + 23

    ; 1920x1080 - Arch Linux in Hyper-V VM at 195% scaling (Windows 10 host)
    ^#Numpad8::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width) - 89, (Mo%LR%Height) + 75

    ; 1920x1080 ❌ Arch Linux in Hyper-V VM at 199% scaling (Windows 10 host). The bottom of the window is clipped regardless of how many pixels are added to Mo%LR%Height
    ; !#Numpad9::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width) + 10, (Mo%LR%Height) + 200

    ; 1920x1080 ❌ Arch Linux in Hyper-V VM at 200% scaling (Windows 10 host). The bottom of the window is clipped regardless of how many pixels are added to Mo%LR%Height
    ^#Numpad9::WinMove, A,, Mo%LR%Left - 5, (Mo%LR%Top) - 83, (Mo%LR%Width) - 10, (Mo%LR%Height) + 100
#If
