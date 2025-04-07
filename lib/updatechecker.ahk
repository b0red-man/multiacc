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
    FileRead, fullver, %A_Temp%\newver.txt
    FileDelete, %A_Temp%\newver.txt
    versions := StrSplit(fullver, ":")
    newVer := versions[1]
    threadVer := versions[2]
    if (newVer > curVer || threadVer > curVer) {
        MsgBox, 68,, % "An update is avaliable, would you like the macro to automatically install it? `nAll your settings will be saved."
        IfMsgBox, Yes
            downloadFiles(fullver)
        IfMsgBox, No
            ExitApp
    }
    ExitApp
}
main()
