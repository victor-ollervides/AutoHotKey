#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

; C:\V\Software\soundvolumeview-x64\SoundVolumeView.exe /Switch "6- Audient iD14\Device\Analogue 1/2\Capture"

; Initializing toggle variable
toggle := false

; Display sound toggle GUI...
; soundToggleBox(Device, symbols, color)
soundToggleBox(Device, color)
{
    WinExist(), soundToggleWin
    {
        Gui, destroy
    }
    Gui, +ToolWindow -Caption +0x400000 +alwaysontop
    ; Gui, Font, s12 cWhite, Segoe UI Emoji
    Gui, Font, s12 bold cblack, Operator Mono Lig
    ; Gui, Add, text, x8 y8, %symbols% %Device% %symbols%
    ; Gui,Add, text, x8 y8, Ux1F604 U+1F604
    Gui, Add, text, x8 y8, %Device%
    ; Gui, color, f07178 ; #f07178 red
    ; Gui, color, FFCB6B ; #FFCB6B yellow
    ; Gui, color, 89DDFF ; #89DDFF blue
    ; Gui, color, 82AAFF ; #82AAFF
    ; Gui, color, b367ff ; #b367ff
    Gui, color, %color%

    ; Gui, Add, text, x8 y8, Sound: U+1F604 🧪 [U+1F604]
    SysGet, screenx, 0
    SysGet, screeny, 1
    ; xpos:=screenx-275
    ; xpos:=screenx-225
    xpos:=screenx-400
    ypos:=screeny-150
    ; Gui, Show, NoActivate x%xpos% y%ypos% h30 w200, soundToggleWin
    Gui, Show, NoActivate x%xpos% y%ypos% h33 w700, soundToggleWin
    SetTimer,soundToggleClose, 5000
}
soundToggleClose:
    SetTimer,soundToggleClose, off
    Gui, destroy ; ░░░ 󱗾 uncomment when needed 󱗾 ░░░
Return

; Microphone/Input Muting...
; #z::
; AppsKey::
+F12::
    toggle := !toggle
    if toggle
    {
        ; Uses "SoundVolumeView.exe" to adjust volume.
        ; https://www.nirsoft.net/utils/sound_volume_view.html
        ; Download and place the SoundVolumeView.exe file in your c:\windows\system32\ folder.

        ; Name of the audio input device in your "sound control panel".
        ; Run c:\windows\system32\SoundVolumeView.exe /Mute "6- Audient iD14" ; ❌ Doesn't work

        ; Within the "SoundVolumeView.exe" application, copy the string found in the "Command-Line Friendly ID" column field of the Input Device and incorporate into the "/Switch" command.
        ; In the event that the specified command encounters any issues, verify that the "Command-Line Friendly ID" field from the Input Device remains unchanged.
        ; Please be aware that this identifier may undergo modifications with new device installations or if the operating system alters device names.

        ; Use the `Item ID` of the Input Device or use the pop-up menu option `Copy Mute-Unmute Command`, see the screenshot [toggle-microphone on-off SoundVolumeView copy mute-unmute command.jpg] for more information.
        Run "C:\V\Software\soundvolumeview-x64\SoundVolumeView.exe" /Switch "{0.0.1.00000000}.{25bb7751-6174-47d0-892b-67757d65d7d3}"
        ; Run "C:\V\Software\soundvolumeview-x64\SoundVolumeView.exe" /Switch "{0.0.1.00000000}.{2f1d14a2-5330-4906-9633-486c5d4ef6a4}"
        ; Run c:\windows\system32\SoundVolumeView.exe /Switch "3- Audient iD14\Device\Analogue 1/2\Capture"
        ; Command-Line Friendly ID: "6- Audient iD14\Device\Analogue 1/2\Capture" ; ❌ Old name
        ; Command-Line Friendly ID: "8- Audient iD14\Device\Analogue 1/2\Capture" ; ❌ Old name
        ; Command-Line Friendly ID: "3- Audient iD14\Device\Analogue 1/2\Capture" ; ❌ Old name

        ; soundToggleBox("Mic Muted", "||||||||||||", "f07178")
        ; soundToggleBox("MUTED", "||||||||||||", "f07178")
        soundToggleBox(" Mic OFF", "f07178") ; #f07178

        ; Plays a "on" beep once the microphone is muted
        ; Run c:\windows\system32\nircmd.exe beep 250 150 ;660 132
        ; sleep 20 ; Ensures the beeps are consective.
        ; Run c:\windows\system32\nircmd.exe beep 300 150 ;520 130

        ; SoundPlay "C:\V\Software\soundvolumeview-x64\beep-01a.wav"
    }
    else
    {
    	Run "C:\V\Software\soundvolumeview-x64\SoundVolumeView.exe" /Switch "{0.0.1.00000000}.{2f1d14a2-5330-4906-9633-486c5d4ef6a4}"
        soundToggleBox(" Mic ON", "88ff44") ; #dcff18#e0ff33#00ccff#caffa2#00ffd9#fffb00#FDD500#88ff44

        ; Plays an "off" beep once the microphone is unmuted
        ; Run c:\windows\system32\nircmd.exe beep 300 130 ;660 132
        ; sleep 50 ; Ensures the beeps are consective.
        ; Run c:\windows\system32\nircmd.exe beep 325 130; 660 132
    }
    sleep, 200 ; Creates a short pause letting the beeps play completely through.
Return
