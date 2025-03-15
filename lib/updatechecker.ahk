#NoEnv
SetWorkingDir %A_ScriptDir%
FileRead, curVer, %A_ScriptDir%\version.txt
msgbox % curVer