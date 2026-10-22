;═══════════════════════════════════════════════════════════════════════════════
;  Keyboard to Mouse Button Mapping
;═══════════════════════════════════════════════════════════════════════════════
;  Maps keyboard keys to mouse buttons:
;    z  →  Left Mouse Button
;    x  →  Right Mouse Button
;
;  Toggle: Ctrl+Win+Alt+M
;═══════════════════════════════════════════════════════════════════════════════

;START OF CONFIG SECTION

#SingleInstance Force
#MaxHotkeysPerInterval 500
#InstallKeybdHook
#UseHook

SetKeyDelay, -1
SetMouseDelay, -1

; Track toggle state (disabled by default)
MouseFunctionalityEnabled := false

;END OF CONFIG SECTION

; Register hotkeys (disabled by default)
Hotkey, *z, ButtonLeftClick
Hotkey, *x, ButtonRightClick

Gosub, DisableMouseFunctionality
return

;═══════════════════════════════════════════════════════════════════════════════
;  Toggle Hotkey: Ctrl+Win+Alt+M
;═══════════════════════════════════════════════════════════════════════════════
^#!m::
    MouseFunctionalityEnabled := !MouseFunctionalityEnabled
    if (MouseFunctionalityEnabled) {
        Gosub, EnableMouseFunctionality
        ToolTip, Keyboard Mouse: ON
    } else {
        Gosub, DisableMouseFunctionality
        ToolTip, Keyboard Mouse: OFF
    }
    SetTimer, RemoveToggleToolTip, 1500
return

RemoveToggleToolTip:
    SetTimer, RemoveToggleToolTip, Off
    ToolTip
return

;═══════════════════════════════════════════════════════════════════════════════
;  Enable/Disable Functions
;═══════════════════════════════════════════════════════════════════════════════

EnableMouseFunctionality:
    Hotkey, *z, On
    Hotkey, *x, On
return

DisableMouseFunctionality:
    Hotkey, *z, Off
    Hotkey, *x, Off
return

;═══════════════════════════════════════════════════════════════════════════════
;  Mouse Click Handlers
;═══════════════════════════════════════════════════════════════════════════════

ButtonLeftClick:
    already_down_state := GetKeyState("LButton")
    If (already_down_state)
        return
    Button2 := "z"
    ButtonClick := "Left"
    Goto ButtonClickStart

ButtonRightClick:
    already_down_state := GetKeyState("RButton")
    If (already_down_state)
        return
    Button2 := "x"
    ButtonClick := "Right"
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
