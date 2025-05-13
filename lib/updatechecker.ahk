#NoEnv
#SingleInstance, force
SetWorkingDir %A_ScriptDir%

main() {
    documentsPath := A_MyDocuments ; Standard Windows Documents folder
    exePath := documentsPath "\MultiScope.exe"
    downloadUrl := "https://github.com/cresqnt-sys/MultiScope/releases/latest/download/MultiScope.exe"

    ; Attempt to download the file to the Documents folder
    UrlDownloadToFile, % downloadUrl, % exePath
    if (ErrorLevel) {
        MsgBox, 48,, % "There was a problem downloading MultiScope to your Documents folder.`nPlease check your internet connection and the release URL: " . downloadUrl
        ExitApp
    }

    ; Inform user of successful download
    MsgBox, 64, Download Complete, MultiScope.exe has been downloaded to your Documents folder:`n%exePath%

    ; Exit the update checker script
    ExitApp
}

main()
 