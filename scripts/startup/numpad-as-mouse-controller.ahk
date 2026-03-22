;░ based on this script https://www.autohotkey.com/docs/v1/scripts/index.htm#NumpadMouse
;░ This script makes mousing with your keyboard almost as easy as using a real mouse (maybe even easier for some tasks). It supports up to five mouse buttons and the turning of the mouse wheel. It also features customizable movement speed, acceleration, and "axis inversion".

; Using Keyboard Numpad as a Mouse -- by deguix
; https://www.autohotkey.com
; This script makes mousing with your keyboard almost as easy
; as using a real mouse (maybe even easier for some tasks).
; It supports up to five mouse buttons and the turning of the
; mouse wheel.  It also features customizable movement speed,
; acceleration, and "axis inversion".

/*
|------------------------------------------------------------|
|Using Keyboard Numpad as a Mouse                            |
|------------------------------------------------------------|
|                                                            |
|    This script is an example of use of AutoHotkey. It uses |
| the remapping of numpad keys of a keyboard to transform it |
| into a mouse. Some features are the acceleration which     |
| enables you to increase the mouse movement when holding    |
| a key for a long time, and the rotation which makes the    |
| numpad mouse to "turn". I.e. NumpadDown as NumpadUp        |
| and vice-versa. See the list of keys used below:           |
|                                                            |
|------------------------------------------------------------|
| Keys                  | Description                        |
|------------------------------------------------------------|
| Ctrl+Win+Alt+X        | Toggle mouse functionality on/off. |
|-----------------------|------------------------------------|
| Numpad0               | Left mouse button click.           |
| Numpad5               | Middle mouse button click.         |
| NumpadDot             | Right mouse button click.          |
| NumpadDiv/NumpadMult  | X1/X2 mouse button click. (Win 2k+)|
| a/x                   | Moves up/down the mouse wheel.     |
|                       |                                    |
|-----------------------|------------------------------------|
| NumpadHome  (7)       | diagonal up+left                   |
| NumpadEnd   (1)       | diagonal down+left                 |
| NumpadPgUp  (9)       | diagonal up+right                  |
| NumpadPgDn  (3)       | diagonal down+right                |
| NumpadUp    (8)       | up                                 |
| NumpadDown  (2)       | down                               |
| NumpadLeft  (4)       | left                               |
| NumpadRight (6)       | right                              |
|------------------------------------------------------------|
| * = These options are affected by the mouse wheel speed    |
| adjusted on Control Panel. If you don't have a mouse with  |
| wheel, the default is 3 +/- lines per option button press. |
o------------------------------------------------------------o
*/

;START OF CONFIG SECTION

#SingleInstance force
#MaxHotkeysPerInterval 500

; Using the keyboard hook to implement the Numpad hotkeys prevents
; them from interfering with the generation of ANSI characters such
; as à.  This is because AutoHotkey generates such characters
; by holding down ALT and sending a series of Numpad keystrokes.
; Hook hotkeys are smart enough to ignore such keystrokes.
#UseHook

MouseSpeed := 5
MouseAccelerationSpeed := 15
MouseMaxSpeed := 50

;Mouse wheel speed is also set on Control Panel. As that
;will affect the normal mouse behavior, the real speed of
;these three below are times the normal mouse wheel speed.
MouseWheelSpeed := 1
MouseWheelAccelerationSpeed := 1
MouseWheelMaxSpeed := 500     ; 5

MouseRotationAngle := 0

; Variable to track manual toggle state
MouseFunctionalityEnabled := false

;END OF CONFIG SECTION

;This is needed or key presses would faulty send their natural
;actions. Like NumpadDiv would send sometimes "/" to the
;screen.
#InstallKeybdHook

Temp := 0
Temp2 := 0

MouseRotationAnglePart := MouseRotationAngle
;Divide by 45º because MouseMove only supports whole numbers,
;and changing the mouse rotation to a number lesser than 45º
;could make strange movements.
;
;For example: 22.5º when pressing NumpadUp:
;  First it would move upwards until the speed
;  to the side reaches 1.
MouseRotationAnglePart /= 45

MouseCurrentAccelerationSpeed := 0
MouseCurrentSpeed := MouseSpeed

MouseWheelCurrentAccelerationSpeed := 0
MouseWheelCurrentSpeed := MouseSpeed

SetKeyDelay, -1
SetMouseDelay, -1

Hotkey, *Numpad0, ButtonLeftClick
Hotkey, *NumpadIns, ButtonLeftClickIns
Hotkey, *Numpad5, ButtonMiddleClick
Hotkey, *NumpadClear, ButtonMiddleClickClear
Hotkey, *NumpadDot, ButtonRightClick
Hotkey, *NumpadDel, ButtonRightClickDel
Hotkey, *NumpadDiv, ButtonX1Click
Hotkey, *NumpadMult, ButtonX2Click

Hotkey, *a, ButtonWheelUp
Hotkey, *x, ButtonWheelDown

Hotkey, *NumpadUp, ButtonUp
Hotkey, *NumpadDown, ButtonDown
Hotkey, *NumpadLeft, ButtonLeft
Hotkey, *NumpadRight, ButtonRight
Hotkey, *NumpadHome, ButtonUpLeft
Hotkey, *NumpadEnd, ButtonUpRight
Hotkey, *NumpadPgUp, ButtonDownLeft
Hotkey, *NumpadPgDn, ButtonDownRight

; Initialize with mouse functionality disabled by default
Gosub, DisableMouseFunctionality
return

;Manual toggle hotkey - only way to activate mouse functionality
^#!m::
    MouseFunctionalityEnabled := !MouseFunctionalityEnabled
    if (MouseFunctionalityEnabled) {
        Gosub, EnableMouseFunctionality
        ToolTip, Numpad Mouse: ON
    } else {
        Gosub, DisableMouseFunctionality
        ToolTip, Numpad Mouse: OFF
    }
    SetTimer, RemoveToggleToolTip, 1500
return

RemoveToggleToolTip:
    SetTimer, RemoveToggleToolTip, Off
    ToolTip
return

EnableMouseFunctionality:
    Hotkey, *Numpad0, On
    Hotkey, *NumpadIns, On
    Hotkey, *Numpad5, On
    Hotkey, *NumpadClear, On
    Hotkey, *NumpadDot, On
    Hotkey, *NumpadDel, On
    Hotkey, *NumpadDiv, On
    Hotkey, *NumpadMult, On

    Hotkey, *a, On
    Hotkey, *x, On

    Hotkey, *NumpadUp, On
    Hotkey, *NumpadDown, On
    Hotkey, *NumpadLeft, On
    Hotkey, *NumpadRight, On
    Hotkey, *NumpadHome, On
    Hotkey, *NumpadEnd, On
    Hotkey, *NumpadPgUp, On
    Hotkey, *NumpadPgDn, On
return

DisableMouseFunctionality:
    Hotkey, *Numpad0, Off
    Hotkey, *NumpadIns, Off
    Hotkey, *Numpad5, Off
    Hotkey, *NumpadClear, Off
    Hotkey, *NumpadDot, Off
    Hotkey, *NumpadDel, Off
    Hotkey, *NumpadDiv, Off
    Hotkey, *NumpadMult, Off

    Hotkey, *a, Off
    Hotkey, *x, Off

    Hotkey, *NumpadUp, Off
    Hotkey, *NumpadDown, Off
    Hotkey, *NumpadLeft, Off
    Hotkey, *NumpadRight, Off
    Hotkey, *NumpadHome, Off
    Hotkey, *NumpadEnd, Off
    Hotkey, *NumpadPgUp, Off
    Hotkey, *NumpadPgDn, Off
return

;Mouse click support

ButtonLeftClick:
    already_down_state := GetKeyState("LButton")
    If (already_down_state)
        return
    Button2 := "Numpad0"
    ButtonClick := "Left"
    Goto ButtonClickStart
ButtonLeftClickIns:
    already_down_state := GetKeyState("LButton")
    If (already_down_state)
        return
    Button2 := "NumpadIns"
    ButtonClick := "Left"
    Goto ButtonClickStart

ButtonMiddleClick:
    already_down_state := GetKeyState("MButton")
    If (already_down_state)
        return
    Button2 := "Numpad5"
    ButtonClick := "Middle"
    Goto ButtonClickStart
ButtonMiddleClickClear:
    already_down_state := GetKeyState("MButton")
    If (already_down_state)
        return
    Button2 := "NumpadClear"
    ButtonClick := "Middle"
    Goto ButtonClickStart

ButtonRightClick:
    already_down_state := GetKeyState("RButton")
    If (already_down_state)
        return
    Button2 := "NumpadDot"
    ButtonClick := "Right"
    Goto ButtonClickStart
ButtonRightClickDel:
    already_down_state := GetKeyState("RButton")
    If (already_down_state)
        return
    Button2 := "NumpadDel"
    ButtonClick := "Right"
    Goto ButtonClickStart

ButtonX1Click:
    already_down_state := GetKeyState("XButton1")
    If (already_down_state)
        return
    Button2 := "NumpadDiv"
    ButtonClick := "X1"
    Goto ButtonClickStart

ButtonX2Click:
    already_down_state := GetKeyState("XButton2")
    If (already_down_state)
        return
    Button2 := "NumpadMult"
    ButtonClick := "X2"
    Goto ButtonClickStart

ButtonClickStart:
    MouseClick, %ButtonClick%,,, 1, 0, D
    SetTimer, ButtonClickEnd, 10
return

ButtonClickEnd:
    kclickstate := GetKeyState(Button2, "P")
    if (kclickstate)
        return

    SetTimer, ButtonClickEnd, Off
    MouseClick, %ButtonClick%,,, 1, 0, U
return

;Mouse movement support

ButtonUp:
ButtonDown:
ButtonLeft:
ButtonRight:
ButtonUpLeft:
ButtonUpRight:
ButtonDownLeft:
ButtonDownRight:
    If (Button <> 0)
    {
        If (!InStr(A_ThisHotkey, Button))
        {
            MouseCurrentAccelerationSpeed := 0
            MouseCurrentSpeed := MouseSpeed
        }
    }
    Button := StrReplace(A_ThisHotkey, "*")

ButtonAccelerationStart:
    If (MouseAccelerationSpeed >= 1)
    {
        If (MouseMaxSpeed > MouseCurrentSpeed)
        {
            Temp := 0.001
            Temp *= MouseAccelerationSpeed
            MouseCurrentAccelerationSpeed += Temp
            MouseCurrentSpeed += MouseCurrentAccelerationSpeed
        }
    }

    ;MouseRotationAngle convertion to speed of button direction
    {
        MouseCurrentSpeedToDirection := MouseRotationAngle
        MouseCurrentSpeedToDirection /= 90.0
        Temp := MouseCurrentSpeedToDirection

        if (Temp >= 0)
        {
            if (Temp < 1)
            {
                MouseCurrentSpeedToDirection := 1
                MouseCurrentSpeedToDirection -= Temp
                Goto EndMouseCurrentSpeedToDirectionCalculation
            }
        }
        if (Temp >= 1)
        {
            if (Temp < 2)
            {
                MouseCurrentSpeedToDirection := 0
                Temp -= 1
                MouseCurrentSpeedToDirection -= Temp
                Goto EndMouseCurrentSpeedToDirectionCalculation
            }
        }
        if (Temp >= 2)
        {
            if (Temp < 3)
            {
                MouseCurrentSpeedToDirection := -1
                Temp -= 2
                MouseCurrentSpeedToDirection += Temp
                Goto EndMouseCurrentSpeedToDirectionCalculation
            }
        }
        if (Temp >= 3)
        {
            if (Temp < 4)
            {
                MouseCurrentSpeedToDirection := 0
                Temp -= 3
                MouseCurrentSpeedToDirection += Temp
                Goto EndMouseCurrentSpeedToDirectionCalculation
            }
        }
    }
EndMouseCurrentSpeedToDirectionCalculation:

    ;MouseRotationAngle convertion to speed of 90 degrees to right
    {
        MouseCurrentSpeedToSide := MouseRotationAngle
        MouseCurrentSpeedToSide /= 90.0
        Temp := MouseCurrentSpeedToSide
        Temp := Mod(Temp, 4)

        if (Temp >= 0)
        {
            if (Temp < 1)
            {
                MouseCurrentSpeedToSide := 0
                MouseCurrentSpeedToSide += Temp
                Goto EndMouseCurrentSpeedToSideCalculation
            }
        }
        if (Temp >= 1)
        {
            if (Temp < 2)
            {
                MouseCurrentSpeedToSide := 1
                Temp -= 1
                MouseCurrentSpeedToSide -= Temp
                Goto EndMouseCurrentSpeedToSideCalculation
            }
        }
        if (Temp >= 2)
        {
            if (Temp < 3)
            {
                MouseCurrentSpeedToSide := 0
                Temp -= 2
                MouseCurrentSpeedToSide -= Temp
                Goto EndMouseCurrentSpeedToSideCalculation
            }
        }
        if (Temp >= 3)
        {
            if (Temp < 4)
            {
                MouseCurrentSpeedToSide := -1
                Temp -= 3
                MouseCurrentSpeedToSide += Temp
                Goto EndMouseCurrentSpeedToSideCalculation
            }
        }
    }
EndMouseCurrentSpeedToSideCalculation:

    MouseCurrentSpeedToDirection *= MouseCurrentSpeed
    MouseCurrentSpeedToSide *= MouseCurrentSpeed

    Temp := MouseRotationAnglePart
    Temp := Mod(Temp, 2)

    If (Button = "NumpadUp")
    {
        if (Temp = 1)
        {
            MouseCurrentSpeedToSide *= 2
            MouseCurrentSpeedToDirection *= 2
        }

        MouseCurrentSpeedToDirection *= -1
        MouseMove, %MouseCurrentSpeedToSide%, %MouseCurrentSpeedToDirection%, 0, R
    }
    else if (Button = "NumpadDown")
    {
        if (Temp = 1)
        {
            MouseCurrentSpeedToSide *= 2
            MouseCurrentSpeedToDirection *= 2
        }

        MouseCurrentSpeedToSide *= -1
        MouseMove, %MouseCurrentSpeedToSide%, %MouseCurrentSpeedToDirection%, 0, R
    }
    else if (Button = "NumpadLeft")
    {
        if (Temp = 1)
        {
            MouseCurrentSpeedToSide *= 2
            MouseCurrentSpeedToDirection *= 2
        }

        MouseCurrentSpeedToSide *= -1
        MouseCurrentSpeedToDirection *= -1

        MouseMove, %MouseCurrentSpeedToDirection%, %MouseCurrentSpeedToSide%, 0, R
    }
    else if (Button = "NumpadRight")
    {
        if (Temp = 1)
        {
            MouseCurrentSpeedToSide *= 2
            MouseCurrentSpeedToDirection *= 2
        }

        MouseMove, %MouseCurrentSpeedToDirection%, %MouseCurrentSpeedToSide%, 0, R
    }
    else if (Button = "NumpadHome")
    {
        Temp := MouseCurrentSpeedToDirection
        Temp -= MouseCurrentSpeedToSide
        Temp *= -1
        Temp2 := MouseCurrentSpeedToDirection
        Temp2 += MouseCurrentSpeedToSide
        Temp2 *= -1
        MouseMove, %Temp%, %Temp2%, 0, R
    }
    else if (Button = "NumpadPgUp")
    {
        Temp := MouseCurrentSpeedToDirection
        Temp += MouseCurrentSpeedToSide
        Temp2 := MouseCurrentSpeedToDirection
        Temp2 -= MouseCurrentSpeedToSide
        Temp2 *= -1
        MouseMove, %Temp%, %Temp2%, 0, R
    }
    else if (Button = "NumpadEnd")
    {
        Temp := MouseCurrentSpeedToDirection
        Temp += MouseCurrentSpeedToSide
        Temp *= -1
        Temp2 := MouseCurrentSpeedToDirection
        Temp2 -= MouseCurrentSpeedToSide
        MouseMove, %Temp%, %Temp2%, 0, R
    }
    else if (Button = "NumpadPgDn")
    {
        Temp := MouseCurrentSpeedToDirection
        Temp -= MouseCurrentSpeedToSide
        Temp2 := MouseCurrentSpeedToDirection
        Temp2 += MouseCurrentSpeedToSide
        MouseMove, %Temp%, %Temp2%, 0, R
    }

    SetTimer, ButtonAccelerationEnd, 10
return

ButtonAccelerationEnd:
    kstate := GetKeyState(Button, "P")
    if (kstate)
        Goto ButtonAccelerationStart

    SetTimer, ButtonAccelerationEnd, Off
    MouseCurrentAccelerationSpeed := 0
    MouseCurrentSpeed := MouseSpeed
    Button := 0
return

;Mouse wheel movement support

ButtonWheelUp:
ButtonWheelDown:

    If (Button <> 0)
    {
        If (Button <> A_ThisHotkey)
        {
            MouseWheelCurrentAccelerationSpeed := 0
            MouseWheelCurrentSpeed := MouseWheelSpeed
        }
    }
    Button := StrReplace(A_ThisHotkey, "*")

ButtonWheelAccelerationStart:
    If (MouseWheelAccelerationSpeed >= 1)
    {
        If (MouseWheelMaxSpeed > MouseWheelCurrentSpeed)
        {
            Temp := 0.001
            Temp *= MouseWheelAccelerationSpeed
            MouseWheelCurrentAccelerationSpeed += Temp
            MouseWheelCurrentSpeed += MouseWheelCurrentAccelerationSpeed
        }
    }

    If (Button = "a")
        ;░ https://www.autohotkey.com/docs/v1/lib/MouseClick.htm
        ;DownOrUp
        ; If blank or omitted, each click consists of a down-event followed by an up-event. Otherwise, specify one of the following letters:
        ;     D: Press the mouse button down but do not release it (i.e. generate a down-event).
        ;     U: Release the mouse button (i.e. generate an up-event).
        ;MouseClick, Button ,X,Y, ClickCount              , Speed, DownOrUp, Relative
        MouseClick, WheelUp, , , %MouseWheelCurrentSpeed%, 0    , D
    else if (Button = "x")
        MouseClick, WheelDown,,, %MouseWheelCurrentSpeed%, 0, D

    SetTimer, ButtonWheelAccelerationEnd, 0     ; 100
return

ButtonWheelAccelerationEnd:
    kstate := GetKeyState(Button, "P")
    if (kstate)
        Goto ButtonWheelAccelerationStart

    MouseWheelCurrentAccelerationSpeed := 0
    MouseWheelCurrentSpeed := MouseWheelSpeed
    Button := 0
return
