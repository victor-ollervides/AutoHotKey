; #NoEnv
; #SingleInstance, Force
; SendMode, Input
; SetBatchLines, -1
; SetWorkingDir, %A_ScriptDir%

Up::
    ControlFocus, , ahk_exe msedge.exe
    ControlClick,, ahk_exe msedge.exe,,WheelUp
return

Down::
    ControlFocus, , ahk_exe msedge.exe
    ControlClick,, ahk_exe msedge.exe,,WheelDown
return

+!x::Send !{LButton}

!Left::MouseClick, WheelUp,,, 3, 1, D
!Right::MouseClick, WheelDown,,, 3, 1, D

+Left::
    Send {AltDown}
    MouseClick, WheelUp,,, 1, 1, D
    Send {AltUp}
return

+Right::
    Send {AltDown}
    MouseClick, WheelDown,,, 1, 1, D
    Send {AltUp}
return

;❯❯ Bitwig only scrolls horizontally through the timeline using the Left Alt and Mouse Wheel

;❌ LWin & Left::
;     Send {AltDown}
;     MouseClick, WheelUp,,, 1, 1, D
;     Send {AltUp}
; return
;❌ LWin & Right::
;     Send {AltDown}
;     MouseClick, WheelDown,,, 1, 1, D
;     Send {AltUp}
; return

; In Bitwig, preferably use NumpadSub/Numpad- (Minus) and NumpadAdd/Numpad+ (Plus) to zoom in and out on the timeline.
LWin & Up::Send, ^{WheelUp}
LWin & Down::Send, ^{WheelDown}

; NumpadEnter::Send {space}

; ^WheelUp::Send {AltUp}{CtrlDown}{WheelUp}
; ^WheelDown::Send {AltUp}{CtrlDown}{WheelDown}

; WheelUp::Send {AltDown}{WheelUp}
; WheelDown::Send {AltDown}{WheelUp}

; WheelUp::Send !{WheelUp}
; WheelDown::Send !{WheelDown}

; ❯❯ use when needed ❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯

; a::Send {Left}
; s::Send {Right}
; d::Send !{LButton}

a::Send {Left}
s::Send !{LButton}
d::Send {Right}
; c::
x::
    Send {LButton}
    ; BlockInput On
    Send {c}
    ; BlockInput Off
    sleep 100
return
; ❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯❯

;░ Mouse Left Button => Alt + Left Click
; LButton::Send !{Click}
;░ Alt + Mouse Left Button => Left Click
; !LButton::Send {LButton}
; a::Send !{Click}
; !Left::Send {Left}
; !Right::Send {Right}
PgDn::Send {Left}
PgUp::Send {Right}