#NoEnv
#SingleInstance, force
SetWorkingDir %A_ScriptDir%
global mainPath := StrReplace(A_ScriptFullPath, "\lib\updatechecker.ahk", "\main.ahk")
global threadPath := A_ScriptDir "\thread.ahk"
global versionPath := A_ScriptDir "\version.txt"
downloadFiles(newVer) {
    UrlDownloadToFile, https://raw.githubusercontent.com/b0red-man/multiacc/refs/heads/main/main.ahk, % mainPath
    UrlDownloadToFile, https://raw.githubusercontent.com/b0red-man/multiacc/refs/heads/main/lib/thread.ahk, % threadPath
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
    FileRead, gitVer, %A_Temp%\newver.txt
    FileDelete, %A_Temp%\newver.txt
    installVer := StrSplit(curVer, ":") ; [1] = main.ahk, [2] = thread.ahk
    gitVers := StrSplit(gitVer, ":") ; [3] = update message (changelog)
    updMsg := gitVers[3]
    ; msgbox % "github ver: " gitVer "`ninstalled ver:" curVer "`nmsg: " updMsg
    if (installVer[1] < gitVers[1] || installVer[2] < gitVers[2]) {
        MsgBox, 68,, % "An update is avaliable, would you like the macro to automatically install it? `nAll your settings will be saved.`nChanges: " updMsg
        IfMsgBox, Yes
            downloadFiles(gitVer)
        IfMsgBox, No
            ExitApp
    }
    ExitApp
}
main()
