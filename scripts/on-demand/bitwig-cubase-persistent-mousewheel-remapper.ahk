; Sets up a persistent AHK script that listens for the WheelUp event. When the WheelUp event is detected, it sends the key combination Alt + WheelUp/WheelDown.

#Persistent
#InstallMouseHook
#UseHook
SetTitleMatchMode, 2

#IfWinActive, ahk_class bitwig
    WheelUp::
        ; Send, !{WheelUp}!{WheelUp} ;!{WheelUp}
        Send, !{WheelUp}
    Return

    WheelDown::
        ; Send, !{WheelDown}!{WheelDown} ;!{WheelDown}
        Send, !{WheelDown}
    Return
#IfWinActive

; #IfWinActive, ahk_class vpWrapperWin
#IfWinActive, ahk_exe BitwigPluginHost-X64-SSE41.exe ; VidPlayVSTv2 Window
    WheelUp::
        Send, !{WheelUp}!{WheelUp} ;!{WheelUp}
    ; Send {AltDown}
    ; Send {WheelUp}{WheelUp}{WheelUp}
    ; Send {AltUp}
    Return

    WheelDown::
        Send, !{WheelDown}!{WheelDown} ;!{WheelDown}
    Return
#IfWinActive

; ahk_class SteinbergWindowClass
; ahk_exe Nuendo12.exe
#IfWinActive, ahk_class SteinbergWindowClass
    WheelDown::
        Send, +{WheelUp} ; +{WheelUp}
    Return

    WheelUp::
        Send, +{WheelDown} ; +{WheelDown}
    Return
#IfWinActive