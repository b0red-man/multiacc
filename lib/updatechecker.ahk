#NoEnv
SetWorkingDir %A_ScriptDir%
mainPath := StrReplace(A_ScriptDir, "\lib", "\main.ahk")
FileRead, curVer, %A_ScriptDir%\version.txt
UrlDownloadToFile, https://raw.githubusercontent.com/b0red-man/multiacc/refs/heads/main/lib/version.txt, %A_Temp%\newver.txt
FileRead, newVer, %A_Temp%\newver.txt
if (newVer > curVer) {
    FileDelete, % mainPath
    UrlDownloadToFile, https://raw.githubusercontent.com/b0red-man/multiacc/refs/heads/main/main.ahk, % mainPath
}
