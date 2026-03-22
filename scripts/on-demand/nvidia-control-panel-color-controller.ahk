;░ -------------------------------------------------------
;▓ Use it only if still using the old NVIDIA Control Panel
;░ -------------------------------------------------------

#SingleInstance force

; NVIDIA Control Panel
; ahk_class Afx:00007FF6685F0000:b:0000000000010003:0000000000000006:0000000000070BBF
; ahk_exe nvcplui.exe
; ahk_pid 22612
; ahk_id 68580
; ClassNN:	msctls_trackbar323

;░ 🔆 Brightness Slider ░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓
; F19::
; ^F21::
; ❌ ^NumpadMult:: if any app that gets input from text is on focus, it will write the multiplication symbol * at some point
; F24::
^Volume_Up::
    n := 321
    ControlSend, msctls_trackbar%n%, {Down}, NVIDIA Control Panel
return
; ❌ ^NumpadDiv:: if any app that gets input from text is on focus, it will write the division symbol /
^Volume_Down::
    n := 321
    ControlSend, msctls_trackbar%n%, {Up}, NVIDIA Control Panel
return

;░ 🌓 Contrast Slider ░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓
; ❌ limited multi-press capability, allowing only one press at a time. Requires the user to hold down the key for faster increments/decreses
; Media_Play_Pause:: ; ❌  Media_Prev|Next  or Volume_Down|Up works with a single press and holding down
; F24::
!Volume_Up::
    n := 322
    ControlSend, msctls_trackbar%n%, {Down}, NVIDIA Control Panel
return

; ❌ limited multi-press capability, allowing only one press at a time. Requires the user to hold down the key for faster increments/decreses
; Media_Stop:: ; ❌ Media_Next or Volume_Up works when the key is pressed and hold
; ScrollLock is mapped to F23 using PowerToys' Keyboard Manager
; F23::
!Volume_Down::
    n := 322
    ControlSend, msctls_trackbar%n%, {Up}, NVIDIA Control Panel
return

;░ 🌈 Gamma Slider ░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓
; F21::
; Media_Next::
Volume_Up::
    ; Run SndVol.exe WinWaitActive, Volume Mixer - Speakers (Realtek High Definition Audio),, 20
    ; Run SndVol.exe WinWaitActive, Volume Mixer - Analogue 1/2 (6- Audient iD14),, 20
    ; Run nvcplui.exe WinWaitActive, NVIDIA Control Panel,, 20
    n := 323
    ControlSend, msctls_trackbar%n%, {Down}{Down}{Down}{Down}{Down}, NVIDIA Control Panel
    ; ControlSend, msctls_trackbar%n%, {Down}, NVIDIA Control Panel
    return
; Run rundll32.exe WinWaitActive, Mouse Properties,, 20
; n = 321
; ControlSend, msctls_updown%n%, {Up}, Mouse Properties



; F20::
; Media_Prev::
Volume_Down::
    n := 323 ; msctls_trackbar = 323
    ControlSend, msctls_trackbar%n%, {Up}{Up}{Up}{Up}{Up}, NVIDIA Control Panel
    ; ControlSend, msctls_trackbar%n%, {Up}, NVIDIA Control Panel
return

;░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓░▓