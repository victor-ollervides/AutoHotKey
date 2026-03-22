; #NoEnv
; #SingleInstance, Force
; SendMode, Input
; SetBatchLines, -1
; SetWorkingDir, %A_ScriptDir%

; LShift & LButton::Send !{LButton}
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
;❌ RAlt & Right::MouseClick, WheelDown,,, 1, 1, D ;

; In Bitwig, preferably use NumpadSub/Numpad- and NumpadAdd/Numpad+ to zoom in and out on the timeline.
LWin & Up::Send, ^{WheelUp}
LWin & Down::Send, ^{WheelDown}

space::
    ControlFocus, , ahk_exe Bitwig Studio.exe
    ControlSend, , {space}, ahk_exe Bitwig Studio.exe
return

; ^WheelUp::Send {AltUp}{CtrlDown}{WheelUp}
; ^WheelDown::Send {AltUp}{CtrlDown}{WheelDown}

; WheelUp::Send {AltDown}{WheelUp}
; WheelDown::Send {AltDown}{WheelUp}

; WheelUp::Send !{WheelUp}
; WheelDown::Send !{WheelDown}

left::
a::
    ControlFocus, , ahk_exe Bitwig Studio.exe
    ControlSend, , {Left}, ahk_exe Bitwig Studio.exe ;❯❯ use when needed
return

s::Send !{LButton} ; use when needed

right::
d::
    ControlFocus, , ahk_exe Bitwig Studio.exe
    ControlSend, , {Right}, ahk_exe Bitwig Studio.exe ;❯❯ use when needed
return

c:: ; Send {LButton}{c}
x::
    Send {LButton}
    ; BlockInput On
    Send {c}
    ; BlockInput Off
    sleep 100
return

; a::Send !{Click}
; !Left::Send {Left}
; !Right::Send {Right}
PgDn::Send {Left}
PgUp::Send {Right}