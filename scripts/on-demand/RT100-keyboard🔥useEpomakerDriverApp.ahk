;░ Macros for the EPOMAKER RT100 Mechanical Keyboard

;❯❯ Prefer using the `EPOMAKER Driver` software rather than this script, as it offers more features and greater reliability.
;❯❯ This script is kept as a reference for the key remappings configured in the EPOMAKER Driver layers, in case they need to be recreated in the future.

#Warn
#NoEnv
#SingleInstance, Force
SendMode, Input
; SetBatchLines, -1
; SetWorkingDir, %A_ScriptDir%

SetNumLockState, AlwaysOn ; Ensure NumLock is always on, Comment this line out when including the script in script-master.ahk.

Delete::Send {NumLock}
~NumLock::Send {Del}
~+NumLock::Send +{Del}
~!NumLock::Send ^{Del}
~^NumLock::Send ^{Del}

'::Send {HOME}
+'::Send +{HOME}
^'::Send ^{HOME}
^+'::Send ^+{HOME}
!'::Send !{HOME} ; used in MPV Player: 'ALT+HOME', 'ab-loop-set-sub',

/::Send {END}
+/::Send +{END}
^/::Send ^{END}
^+/::Send ^+{END}

; --- not used anymore ---
; ------------------------
; ^!+NumpadSub::Send {PrintScreen}
; +BackSpace::Send +{Delete}

; LShift & RShift::Send +{HOME}
; LShift & RCtrl::Send +{END}
; LCtrl & RShift::Send {HOME}
; LCtrl & RCtrl::Send {END}

; \::Send {Del}
; +\::Send +{Del}
; ^\::Send ^{Del}

; \::Send {Enter}
; +\::Send +{Enter}
; ^\::Send ^{Enter}
; ^+\::Send ^+{Enter}