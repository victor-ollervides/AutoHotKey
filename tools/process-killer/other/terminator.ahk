#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

; Exit All AutoHotkey Scripts
; This script will terminate all running AutoHotkey scripts except itself

; Hotkey: Ctrl+Alt+X to exit all AHK scripts
; ^!x::
#!x::
    ;░ AHK v1: Get list of all running processes
    for objProcess in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'AutoHotkeyU64.exe'")
    {
        ; Get the PID of the current script to avoid terminating itself
        Process, Exist
        CurrentPID := ErrorLevel

        ; If this is not the current script, terminate it
        if (objProcess.ProcessId != CurrentPID)
        {
            Process, Close, % objProcess.ProcessId
        }
    }

    ;░ AHK v2 - check for AutoHotkey64.exe (64-bit version)
    for objProcess in ComObjGet("winmgmts:").ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'AutoHotkey64.exe'")
    {
        ; Get the PID of the current script to avoid terminating itself
        Process, Exist
        CurrentPID := ErrorLevel

        ; If this is not the current script, terminate it
        if (objProcess.ProcessId != CurrentPID)
        {
            Process, Close, % objProcess.ProcessId
        }
    }

    ; Show confirmation message
    TrayTip, AutoHotkey Scripts, All AutoHotkey scripts have been terminated, 3, 1

    ; Wait a moment then exit this script too
    Sleep, 2000
    ExitApp
return

; Alternative hotkey: Win+Alt+X for extra convenience
; #!x::
;     Gosub, ^!x
; return

; Tray menu option to exit all scripts
Menu, Tray, Add, Exit All AHK Scripts, ExitAllScripts
Menu, Tray, Add  ; separator
; Menu, Tray, Add, Exit This Script Only, ExitThisScript

ExitAllScripts:
    Gosub, #!x
return

; ExitThisScript:
;     ExitApp
; return
