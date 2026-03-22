#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#SingleInstance force

;ControlSend ( "WindowName", "", "{s down}"[, flag])
;ControlSend, [ Control, Keys, WinTitle, WinText, ExcludeTitle, ExcludeText]

; WORKING ON mpv.net WINDOW
;ControlSend,,{space},1-code-setup.mp4 - mpv.net
; F1::ControlSend, , {space}, ahk_exe mpvnet.exe
; F2::ControlSend, , {left}, ahk_exe mpvnet.exe
; F3::ControlSend, , {right}, ahk_exe mpvnet.exe

; !`::ControlSend, , {space}, ahk_exe mpvnet.exe
; !1::ControlSend, , {left}, ahk_exe mpvnet.exe
; !2::ControlSend, , {right}, ahk_exe mpvnet.exe

; #if (getKeyState("F23", "P"))
;   F23::return

;   ; Redragon K585 RGB
;   Space::ControlSend, , {space}, ahk_exe mpv.exe
;   F1::ControlSend, ,+{left}, ahk_exe mpv.exe
;   g::ControlSend, , +{left}, ahk_exe mpv.exe
;   b::ControlSend, , +{right}, ahk_exe mpv.exe
;   a::ControlSend, , a, ahk_exe mpv.exe

;   ; LENOVO SK-8825
;   ; NumpadEnter::ControlSend, , {space}, ahk_exe mpv.exe
;   ; Numpad0::ControlSend, , +{left}, ahk_exe mpv.exe
;   ; NumpadDot::ControlSend, , +{right}, ahk_exe mpv.exe
;   ; NumpadAdd::ControlSend, , +{left}, ahk_exe mpv.exe
; #if
;   ;Done with F23

; #IfWinActive ahk_exe mpv.exe
    ; NumpadAdd::Send !v
    ; NumpadSub::Send !v
    ; +Space::Send {space}
; #IfWinActive

#IfWinActive ahk_exe code.exe
    ; Pause the video
    +Space::ControlSend, , {space}, ahk_exe mpv.exe
    ; +Space::ControlSend, , {space}, ahk_exe Bitwig Studio.exe

    ; ^NumpadEnter::ControlSend, , v, ahk_exe mpv.exe
    ; +NumpadEnter::ControlSend, , !v, ahk_exe mpv.exe

    ; +down::ControlSend, , +{down}, ahk_exe mpv.exe

    ; Backward one relative second
    +z::ControlSend, , +{left}, ahk_exe mpv.exe
    ; Forward one relative second
    +x::ControlSend, , +{right}, ahk_exe mpv.exe
#IfWinActive

; Backwards a few seconds
; +z::ControlSend, , +{left}, ahk_exe mpv.exe
; +z::ControlSend, , !{left}, ahk_exe mpv.exe
; +z::ControlSend, , {left}{left}, ahk_exe mpv.exe
; +z::ControlSend, , {NumpadDot}, ahk_exe mpv.exe

; Backwards one second
; +x::ControlSend, , {left}, ahk_exe mpv.exe
; NumpadSub::ControlSend, , {left}, ahk_exe mpv.exe
; +NumpadSub::ControlSend, , {right}, ahk_exe mpv.exe
; !+z::ControlSend, , {left}, ahk_exe mpv.exe

; Inverts the Alpha Channel
; +a::ControlSend, , a, ahk_exe mpv.exe
;Numpad0::ControlSend, , {space}, ahk_exe mpv.exe

; Shows/Hides the subtitles/captions
; NumpadAdd::ControlSend, , v, ahk_exe mpv.exe

;NumpadDot::ControlSend, , +{left}, ahk_exe mpv.exe
;!NumpadEnter::ControlSend, , +{space}, ahk_exe mpv.exe
