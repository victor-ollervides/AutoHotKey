;░ http://xahlee.info/mswin/autohotkey_key_notations.html
; Key Syntax
;░ ctrl  ^
;░ alt   !
;░ shift +
;░ win   #

#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#Warn ; Enable warnings to assist with detecting common errors.

; #Requires AutoHotkey v1.1
; MsgBox %A_AhkVersion%
; #Requires AutoHotkey v2.0-
; MsgBox A_AhkVersion

; Alt::Return ;Disables the key alt when it's pressed alone
#IfWinActive ahk_exe explorer.exe

; How can I disable the behavior where pressing F1 in File Explorer opens Microsoft Edge?
F1::Return
#IfWinActive

#IfWinActive ahk_exe mpv.exe
; NumpadAdd::Send !v
; NumpadSub::Send !v
; +Space::Send {space}
#IfWinActive

;Closes Program/Window
;^q::Send !{F4}
; !q::Send !{F4} ; ❌ Never use Alt + Q
; #q::Send !{F4}
LWin & q::Send !{F4}

; ░ https://www.autohotkey.com/board/topic/94400-modifying-altesc-to-not-skip-minimized-windows/#entry594847
LAlt & Esc::
    Send {Alt down}{Esc}{Alt Up}
    WinGet, MMX, MinMax, A
    IfEqual MMX,-1, WinRestore A
return

; Numpad6::Numpad5
; Numpad4::Numpad5

; +NumpadEnter::Send +{DEL}
; ^NumpadEnter::Send ^{DEL}
; +^NumpadEnter::Send ^{BackSpace}

; ^+NumpadEnter::Send +{DEL}
; +NumpadEnter::Send ^{DEL}
#NumpadEnter::Send ^{DEL}
; ^NumpadEnter::Send ^{BackSpace}

; +^NumpadEnter::Send +{DEL}
; +NumpadEnter::Send ^{DEL}

; !RShift::Send ^{Backspace}
; ^RShift::Send ^{Backspace}
; LShift & ,::Send ^{BackSpace}
; LShift & RShift::Send {DEL}
; LShift & RCtrl::Send {BackSpace}
; LCtrl & RShift::Send ^{DEL}
; LCtrl & RShift::Send ^{BackSpace}
; LCtrl & RCtrl::Send ^{BackSpace}
; LCtrl & RCtrl::Send ^{DEL}

; 💜 Ctrl + Tab: activates the tab-switching functionality, allowing you to cycle through your open tabs or applications.
; LCtrl & RCtrl::Send {AltDown}{Tab}{AltUp}

; ❌ Avoid using this setting, as it causes conflicts in XYplorer when renaming files or folders—specifically when using the Ctrl+Backspace shortcut to delete words.
; ▓ LCtrl & RCtrl::Send !{Tab}
; ▓ LControl & RControl::Send !{Tab}

; -> macro/command to push an empty space while cursor is in place
#IfWinActive, ahk_exe Obsidian.exe
    ^+Space::Send {space}{left}
#IfWinActive
#IfWinActive, ahk_exe Code.exe
    ^+Space::Send {space}{left}
#IfWinActive
#IfWinActive, ahk_exe Kiro.exe
    ^+Space::Send {space}{left}
#IfWinActive
#IfWinActive, ahk_exe Code - Insiders.exe
    ^+Space::Send {space}{left}
#IfWinActive

#IfWinActive, ahk_exe Zed.exe
; ^+Enter::Send {HOME}{ENTER}{UP}
^+Enter::Send {END}{ENTER}!{UP}
^Enter::Send {END}{ENTER}
#IfWinActive

#IfWinActive, ahk_exe BitwigStudioApp.exe
; MPV Video Reload Hotkey
; Press q to reload video in mpv-helper
q::
{
    Run, "C:\Program Files\VstPlugins\reload-mpv.exe", , Hide
    return
}
#IfWinActive

; ^CapsLock::
;     WinGetPos, , , WinWidth, WinHeight, A ; Get the position of the active window
;     MouseMove, WinWidth / 2, WinHeight / 2 ; Move the cursor to the center of the active window
; return

^#!t::
    Send {TEXT}``````ts
    Send {Enter}
    Send {TEXT}``````
return

; ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
; ░ https://github.com/randyrants/sharpkeys
; ░ https://superuser.com/questions/151304/prevent-windows-key-from-opening-start-menu-in-windows-7
; -> The following AutoHotkey script will disable the Win key activating the start menu
; -> for both left and right ⊞ Win keys in Windows 10.
; ~LWin Up:: return
; ~RWin Up:: return

; LWin & vk07::return
; LWin::return
; RWin & vk07::return
; RWin::return

; ░ https://www.autohotkey.com/docs/v1/lib/_MenuMaskKey.htm
; ❌ Do not use this, it messes up the Windows key functionality in combination with other keys
; ~LWin::Send {Blind}{vkE8} ❌
; ~RWin::Send {Blind}{vkE8} ❌
; ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

; ^+!UP::Send {PgUp}
; ^+!DOWN::Send {PgDn}

; emoji := {manShrugging: "{U+1F937}{U+200D}{U+2642}{U+FE0F}"} ; Add more!
; F3::Send % emoji["manShrugging"]
; LWin & k::Send {U+2714} ;{U+1F937}{U+200D}{U+2642}{U+FE0F}

; ✖ Heavy Multiplication X Emoji (cross)
; HTML-code	&#10006
; ░ https://unicode-table.com/en/2716/
; Left Windows + X
; LWin & x::Send {U+2716}

; ❌ Cross Mark Emoji
; cross, x, ex, ex mark, multiplication sign
; ░ https://unicode-table.com/en/274C/
; Left Windows + Z
; LWin & z::Send {U+274C}

; ░ https://symbl.cc/en/2044/
; ░ https://www.compart.com/en/unicode/U+2044
; Unicode Character “⁄” (U+2044)
; Fraction Slash ⁄. General Punctuation.
; The symbol “Fraction Slash” is included in the “General punctuation” subblock of the “General Punctuation” block and was approved as part of Unicode version 1.1 in 1993.
^#!NumpadDiv::Send {U+2044}
; https://www.compart.com/en/unicode/U+FE68
^#\::Send ﹨ ; {U+FE68}
; https://www.compart.com/en/unicode/U+FF3C
^#!\::Send ＼

^#!;::Send ：

#z::Click Left
#x::Click Right
#c::Send {AppsKey}
#s::Send {Esc}

; ░ https://symbl.cc/en/2014/
; Name:	Em Dash
; Category:	Pd / Punctuation, dash
; Unicode Character `—` (U+2014)
; +^#!NumpadSub::Send {U+2014}
; — is a punctuation mark used to indicate a break in thought or a shift in tone within a sentence. It is often used to set off parenthetical information or to create emphasis. The symbol “Em Dash” is included in the “Dashes” subblock of the “General Punctuation” block and was approved as part of Unicode version 1.1 in 1993.

; ░ https://symbl.cc/en/2015/
; Name:	Horizontal Bar
; Category:	Dash Punctuation
; Unicode Character `―` (U+2015)
; ― is a punctuation mark used to indicate a break in thought or a shift in tone within a sentence. It is often used to set off parenthetical information or to create emphasis. The symbol “Horizontal Bar” is included in the “Dashes” subblock of the “General Punctuation” block and was approved as part of Unicode version 1.1 in 1993.

; ░ https://symbl.cc/en/2500/
; ░ https://www.compart.com/en/unicode/U+2500
; Name:	Box Drawings Light Horizontal
; Unicode Character `─` (U+2500)
; ─ U+2500 is a box-drawing character used to create horizontal lines in text-based user interfaces. It is often used in combination with other box-drawing characters to create borders and dividers. The symbol “Box Drawings Light Horizontal” is included in the “Box Drawing” block and was approved as part of Unicode version 1.1 in 1993.

+#NumpadSub::Send — ; {U+2014} - Em Dash
^#NumpadSub::Send ― ; {U+2015} - Horizontal Bar
#!NumpadSub::Send ─ ; {U+2500} - Box Drawings Light Horizontal
^#!NumpadSub::Send ⸺ ; {U+2E3A} - Two-Em Dash

; ░ https://symbl.cc/en/2E3A/
; ░ https://unicode-explorer.com/c/2E3A
; ░ https://www.compart.com/en/unicode/U+2E3A
; Unicode Name:     Two-Em Dash
; Unicode Number:   U+2E3A
; Unicode character `⸺`
; Unicode Block:    Supplemental Punctuation
; Unicode Subblock:	Dashes
; Unicode Version: 	6.1 (2012)
; The symbol “Two-Em Dash” is included in the “Dashes” subblock of the “Supplemental Punctuation” block and was approved as part of Unicode version 6.1 in 2012.

; ░ https://www.compart.com/en/unicode/U+276F
; Name:	    Heavy Right-Pointing Angle Quotation Mark Ornament
; Number:   U+276F
; Character `❯`
; Version:	3.2 (March 2002)
; Category:	Close Punctuation (Pe)
; Character is Mirrored:	Yes , ❮ (U+276E)
; +^!Right::Send {U+276F}
; +^!Left::Send {U+276E}
^!+>::Send {U+276F} ; ❯
^!+<::Send {U+276E} ; ❮

;░ https://www.compart.com/en/unicode/U+279C
^#!>::Send ➜ ; ➜ {U+279C}
^#>::Send → ;

;░ https://www.symbolspy.com/arrow-symbol.html
; ^#!>::Send ⇝ ; ⇝

^#!<::Send ◀️ ; ◀️

; ░ https://www.compart.com/en/unicode/U+2192
; →

; ✝ U+271D ✝ Latin Cross Emoji (christian cross)
; ✟ U+271F ✟ Outlined Latin Cross -> HTML-code &#10015 -> CSS-code \271F
; ✜ U+271C ✜
; ░ https://unicode-table.com/en/271D/
; Hourglass Emoji ⌛
; ░ https://unicode-table.com/en/231B/
; LWin & t::Send {U+271F}
; LWin & t::Send {U+231B}

; 💎💠⚔️
^#d::Send 📍
#!x::Send ❌
#!c::Send ✔️ ;✔️ {U+2714}
; ^#!c::Send ⚰️ ;⚰️ {U+26B0}
; ^#x::Send ✖
; ^#n::Send 👑 ; {U+1F451}

; represents a Shinto shrine in Japan. It typically depicts a traditional Japanese shrine with a torii gate, a curved roof, and a red and white color scheme.
; The torii gate is a symbolic structure that marks the entrance to the sacred space of the shrine.
^#!s::Send ⛩️ ; {U+26E9}
^#m::Send 🍄 ; {U+1F344}
^#l::Send ⚡  ; {U+26A1}
; 🥇 {U+1F947}
; 🍓 {U+1F353}

; 🥎 softball
; ░ https://symbl.cc/en/1F94E/
; Softball is a type of ball, which resembles a basket ball a little bit, but differs in terms of size (it's bigger) and colour (it's yellow).
; The symbol “Softball” is included in the “Miscellaneous symbols” subblock of the “Supplemental Symbols and Pictographs” block and was approved as part of Unicode version 11.0 in 2018. In 2018, it was also approved as an Emoji in version 11.0 and added to the “Sport” subcategory of the “Activities” category.
; Unicode Name      Softball
; Unicode Number    U+1F94E
; Plane 	        1: Supplementary Multilingual Plane
; Unicode Block     Supplemental Symbols and Pictographs
; Unicode Subblock 	Miscellaneous symbols
; Unicode Version 	11.0 (2018)
; Emoji Version 	11.0 (2018)
; Emoji Category 	Activities
; Emoji Subcategory Sport
; Emoji Name 	    Softball
; ^#s::Send {U+1F94E}
^#s::Send <!-- ░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░░▒▓▒░ -->

; 🔥
; ░ https://symbl.cc/en/1F525
^#f::Send {U+1F525}

; 🧪 Test Tube Emoji
; ░ https://symbl.cc/en/1F9EA/
RWin & t::Send {U+1F9EA}

; 🥖 Baguette Bread Emoji
; ░ https://unicode-table.com/en/1F956/
; ⭕ Left Windows + S
; LWin & s::Send {U+1F956}

; ^+!e::ExitApp
; RCtrl & Esc::ExitApp

; End of auto-execute section
; Return

; Clean exit with optional exit code
; ExitApp [, ExitCode]
