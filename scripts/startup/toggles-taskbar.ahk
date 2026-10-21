#NoEnv
#SingleInstance, Force
; SendMode, Input
; SetBatchLines, -1
; SetWorkingDir, %A_ScriptDir%

;░ https://www.autohotkey.com/boards/viewtopic.php?t=84587

; toggle taskbar on and off using hot key

WinGet, Transparent, Transparent, ahk_class Shell_TrayWnd
; ^+!q:: ; ToggleTaskbar()
; #^+c::
; #^+Down::

#^+!z::
    ; To disable the Ctrl + Shift + Alt + Win (Hyper) shortcut that triggers Office/Microsoft 365 web pages, you can block the command via a Windows Registry fix.
    ; Run the following command as administrator to nullify the shortcut target:
    ; REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32
    ; If Transparent
    If Transparent := !Transparent
    {
        ; MsgBox IF %Transparent%
        WinSet, Transparent, 0, ahk_class Shell_TrayWnd
    }
    Else
    {
        ; MsgBox ELSE %Transparent%
        WinSet, Transparent, 255, ahk_class Shell_TrayWnd
        WinSet, TransColor, OFF, ahk_class Shell_TrayWnd
        WinSet, Transparent, OFF, ahk_class Shell_TrayWnd
        WinSet, Redraw, , ahk_class Shell_TrayWndn
    }
Return
