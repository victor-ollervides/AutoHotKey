#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

#IfWinActive, ahk_class CabinetWClass

    ; #SingleInstance
    ; #Requires Autohotkey v2.0

    ; Variables
    ; flag := {} ; Use an associative array to store the sorting flags for different properties
    ; flag["System.ItemNameDisplay"] = 0
    flag := ["System.ItemNameDisplay", "System.DateModified", "System.ItemTypeText"]
    ; MsgBox % flag[1]
    ; MsgBox % SubStr( flag[1], 1, StrLen(flag[1]))
    ; MsgBox % SubStr( flag[1], 1, 1)

    ; !1::SortFiles("System.ItemNameDisplay") ; Alt + 1 hotkey for sorting by name
    ; !2::SortFiles("System.DateModified") ; Alt + 2 hotkey for sorting by DateModified
    ; !3::SortFiles("System.ItemTypeText") ; Alt + 3 hotkey for sorting by Type

    !1::SortFiles(1, flag) ; Alt + 1 hotkey for sorting by name
    !2::SortFiles(2, flag) ; Alt + 2 hotkey for sorting by DateModified
    !3::SortFiles(3, flag) ; Alt + 3 hotkey for sorting by Type

    SortFiles(sortProperty, flag)
    {
        ; MsgBox % SubStr( flag[sortProperty], 1, 1)

        WinGet, hWnd, ID, A
        oShell := ComObjCreate("Shell.Application")
        for oWin in oShell.Windows
        {
            if (oWin.HWND = hWnd)
            {
                if (SubStr( flag[sortProperty], 1, 1) = "-" || SubStr( flag[sortProperty], 1, 1) = "+") ;|| SubStr( flag[sortProperty], 1, 1) != "+"
                {
                    ; MsgBox % "IF " . flag[sortProperty]
                    oWin.Document.SortColumns := "prop:" . flag[sortProperty] . ";"
                    flag[sortProperty] := SubStr( flag[sortProperty], 2, StrLen(flag[sortProperty]))
                    ; MsgBox % flag[sortProperty]
                }
                else
                {
                    ; MsgBox % "ELSE " . flag[sortProperty]
                    ; MsgBox, % oWin.Document.SortColumns ; show current sort columns
                    oWin.Document.SortColumns := "prop:" . flag[sortProperty] . ";"
                    if( sortProperty = 2) {
                        sign := "+"
                    } else {
                        sign := "-"
                    }

                    flag[sortProperty] := sign . flag[sortProperty]
                }
                break
            }
        }
        oShell := "" ; Release the COM object
    }

#IfWinActive
