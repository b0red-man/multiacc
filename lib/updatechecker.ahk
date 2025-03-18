#NoEnv
#SingleInstance, force
SetWorkingDir %A_ScriptDir%
global mainPath := StrReplace(A_ScriptFullPath, "\lib\updatechecker.ahk", "\main.ahk")
global versionPath := A_ScriptDir "\version.txt"
downloadMain(newVer) {
    UrlDownloadToFile, https://raw.githubusercontent.com/b0red-man/multiacc/refs/heads/main/main.ahk, % mainPath
    if (ErrorLevel) {
        MsgBox, 48,, % "There was a problem updating the macro.`nPlease check your internet connection and try again."
        ExitApp
    }
    FileDelete, % versionPath
    FileAppend, % newVer, % versionPath
    Run, % mainPath
    ; MsgBox % "Macro Updated Succesfully!"
}
main() {
    FileRead, curVer, %A_ScriptDir%\version.txt
    UrlDownloadToFile, https://raw.githubusercontent.com/b0red-man/multiacc/refs/heads/main/lib/version.txt, %A_Temp%\newver.txt
    FileRead, newVer, %A_Temp%\newver.txt
    FileDelete, %A_Temp%\newver.txt
    if (newVer > curVer) {
        MsgBox, 68,, % "An update is avaliable, would you like the macro to automatically install it? `nAll your settings will be saved."
        IfMsgBox, Yes
            downloadMain(newVer)
        IfMsgBox, No
            ExitApp
    }
    ExitApp
}
main()
