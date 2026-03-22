; @Ahk2Exe-Base AutoHotkeyU64.exe
#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
#Warn

; Install mouse hook for reliable mouse button detection
#InstallMouseHook

; Admin check temporarily disabled for testing
if not A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

; Return

;░ Macros for the EPOMAKER RT100 Mechanical Keyboard
SetNumLockState, AlwaysOn

; ahk_exe Nuendo12.exe
; #IfWinActive, ahk_class SteinbergWindowClass
;     #Include %A_ScriptDir%\on-demand\Steinberg_Cubase_Nuendo_Macros.ahk
; #IfWinActive

; ; https://superuser.com/questions/255209/how-can-i-use-the-keyboard-to-simulate-mousewheel-scrolling-with-autohotkey
; ; ahk_exe Bitwig Studio.exe
; #IfWinActive, ahk_class bitwig
;     #Include %A_ScriptDir%\on-demand\bitwig-studio.ahk
; #IfWinActive

; ; VidPlayVSTv2 Window (Bitwig Video Player)
; ; #IfWinActive, ahk_exe BitwigPluginHost-X64-SSE41.exe
; #IfWinActive, ahk_class vpWrapperWin
;     #Include %A_ScriptDir%\on-demand\BitwigMacros-SentFrom-VidPlayVSTv2-VideoPlayer.ahk
; #IfWinActive

; #IfWinActive, ahk_class xjadeo
;     #Include %A_ScriptDir%\on-demand\BitwigMacros-SentFrom-XJadeo-VideoPlayer.ahk
; #IfWinActive

; #Include %A_ScriptDir%\on-demand\mic-mute-toggle-audient-id14.ahk
; #Include %A_ScriptDir%\on-demand\nvidia-control-panel-color-controller.ahk
; #Include %A_ScriptDir%\on-demand\persistent-mousewheel-remapper.ahk

; -----------------------------------------------------------------------------------------
; STARTUP SCRIPTS
; -----------------------------------------------------------------------------------------

; #Include %A_ScriptDir%\startup\window-split-manager.ahk ;▓ It only executes properly when launched as a standalone script.
#Include %A_ScriptDir%\startup\right-button-horizontal-drag-scrolling.ahk ;▓ It only executes properly when launched as a standalone script.
; #Include %A_ScriptDir%\startup\cycles-last-2-windows.ahk ;▓ It only executes properly when launched as a standalone script.
#Include %A_ScriptDir%\startup\global-keyboard-macros.ahk
#Include %A_ScriptDir%\startup\epomaker-RT100.ahk
#Include %A_ScriptDir%\startup\maximize-minimize-window.ahk
; #Include %A_ScriptDir%\startup\toggles-taskbar.ahk ;▓ It only executes properly when launched as a standalone script.
; #Include %A_ScriptDir%\startup\create-new-file.ahk
; #Include %A_ScriptDir%\startup\cycles-last-3-windows.ahk
; #Include %A_ScriptDir%\startup\file-explorer-sorting.ahk
; #Include %A_ScriptDir%\startup\numpad-as-mouse-controller.ahk
#Include %A_ScriptDir%\startup\app-launcher-and-switcher.ahk
