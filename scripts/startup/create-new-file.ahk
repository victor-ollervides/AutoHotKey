#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

;░ https://gist.github.com/aubricus/1148174
;░ https://github.com/syon/ahk/blob/master/NewFile/NewFile.ahk

; In Windows Explorer, pressing Ctrl+Alt+N opens an AHK input window where you can type a filename, then creates a new file in the current directory.
; The script uses its own directory as the working directory by default; to create the file in the active folder, you need to extract the full path from the current window.

;░ Alt+N = !SC031::

; Only run when Windows Explorer or Desktop is active
#IfWinActive ahk_class CabinetWClass
^!n::
#IfWinActive ahk_class ExploreWClass
^!n::
#IfWinActive ahk_class Progman
^!n::
#IfWinActive ahk_class WorkerW
^!n::

    ; get full path from open explorer window
    WinGetText, FullPath, A

    ; split up result (returns paths seperated by newlines)
    StringSplit, PathArray, FullPath, `n

	; Find line with backslash which is the path
	Loop, %PathArray0%
    {
        StringGetPos, pos, PathArray%a_index%, \
        if (pos > 0) {
            FullPath:= PathArray%a_index%
            break
        }
    }

    ; clean up result
    FullPath := RegExReplace(FullPath, "(^.+?: )", "")
	StringReplace, FullPath, FullPath, `r, , all

    ; change working directory
    SetWorkingDir, %FullPath%

    ; an error occurred with the SetWorkingDir directive
    If ErrorLevel
        Return

    ; Display input box for filename
    InputBox, UserInput, New File, , , 400, 100, , , , ,

    ; User pressed cancel
    If ErrorLevel
        Return

    ; Create file
    FileAppend, , %UserInput%

    ; Open the file in the appropriate editor
    ;Run %UserInput%

    Return

#IfWinActive
