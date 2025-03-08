#NoEnv
SendMode Input
CoordMode, ToolTip, Screen
CoordMode, Mouse, Screen
SetWorkingDir %A_ScriptDir%
#SingleInstance, force
global started := 0
global oldBiomes := []
global sortedFiles := []
global logPath := "C:\Users\" A_UserName "\AppData\Local\Roblox\logs"
global iniPath := A_ScriptDir "\config.ini"
global biomes:={"WINDY":0x9ae5ff,"RAINY":0x027cbd,"SNOWY":0xDceff9,"SANDSTORM":0x8F7057,"HELL":0xff4719,"STARFALL":0x011ab7,"CORRUPTION":0x6d32a8,"NULL":0x838383,"GLITCHED":0xbfff00,"DREAMSPACE":0xea9dda}
getUsername(logFile) {
    FileRead, file, % logFile
    file := SubStr(file, InStr(file, "load failed in Players.")+23)
    file := SubStr(file, 1, InStr(file, ".")-1)
    return file
}
updateLogs() {
    sorter := new FileSorter()
    sortedFiles := sorter.SortFiles(logPath)  ; Now returns the sorted array
}
removeClick(ctrlID) {
    distance:=25
    len := StrSplit(read("Clicks"), "|")
    num := SubStr(ctrlID, 12)
    len.RemoveAt(num)
    newSettings:=""
    for i,v in len {
        newSettings .= v
        if (i!=len.Length()) {
            newSettings .= "|"
        }
    }
    IniWrite, % newSettings, % iniPath, Main, Clicks
    WinGetPos, x, y,,,Click Manager
    Gui, click:Destroy
    Ui.click(x,y)
}
getPSLinkfromUser(user) {
    arr := StrSplit(read("accounts"), "||||")
    for _,v in arr {
        sub := StrSplit(v, ":::")
        if (sub[1] = user) {
            return sub[2]
        }
    }
    return 0
}
getLogFilefromUser(user) {
    for _,v in sortedFiles {
        file := v.path
        u:=getUsername(file)
        if (u = user) {
            return file
        }
    }
}
class detect {
    getRPCMsg(filePath) {
        FileRead, file, % filePath
        msg :=  SubStr(file, InStr(file, "[BloxstrapRPC]",, 0))
        msg := SubStr(msg, 1, InStr(msg, "}}}",, 0)+2)
        return msg
    }
    getBiome(msg) {
        str = ","
        biome := SubStr(msg, InStr(msg, "largeImage")+26)
        return SubStr(biome, 1,InStr(biome,str)-1)
    }
}
sendBiomeMsg(biome,start,account) {
    link := getPSLinkfromUser(account)
    con := link?"-# **PS Link:** " . link:"**No Link Provided**"
    ddV := read(biome . "dropdown")
    FormatTime, t,, HH:mm:ss
    footer := t . ", Account: " . account
    color := biomes[biome]
    if (ddV != "None") {
        if (start) {
            title := "Biome Started | " . biome
            if (ddv = "Ping") {
                if (biome = "Glitched" || biome = "Dreamspace") {
                    id := read(biome . "ID")?read(biome . "ID"):read("UserID")
                } else {
                    id := read("UserID")
                }
                con .= " <@" . id . ">"
            }
            webhookPost({content: con, embedTitle: title, embedColor: color, embedFooter: footer})
        } else {
            if (biome) {
                title := "Biome Ended | " . biome
                webhookPost({embedTitle: title, embedColor: color, embedFooter: footer})
            }
        }
    }
}
biomeTick() {
    arr := StrSplit(read("accounts"), "||||")
    Loop, % arr.Length() {
        sub := strsplit(arr[A_Index],":::")
        acc := sub[1]
        oldbiome:=oldBiomes[A_Index]
        file := getLogFilefromUser(acc)
        biome := detect.getBiome(detect.getRPCMsg(file))
        if (biome != oldBiome) {
            if (read("BiomeEnd")&&oldBiome!="Normal") {
                sendBiomeMsg(oldBiome,0,acc)
            }
            if (biome != "Normal") {
                sendBiomeMsg(biome,1,acc)
            }
        }
        oldBiomes[A_Index] := biome
    }
}
read(option) {
    IniRead, out, % iniPath, Main, % option
    return out
}
clickSave() {
    GuiControlGet, val,, clickEnable
    IniWrite, % val, % iniPath, Main, ClickEnabled
    len := StrSplit(read("Clicks"), "|").Length()
    str := ""
    Loop, % len {
        GuiControlGet, v1,, x%A_Index%
        GuiControlGet, v2,, y%A_Index%
        str := str . v1 . ":" . v2
        if (A_Index!=len) {
            str := str . "|"
        }
    }
    IniWrite, % str, % iniPath, Main, Clicks
}
accountRemove(ctrlID) {
    accountSave()
    num := substr(ctrlId, 14)
    arr := StrSplit(read("accounts"), "||||")
    arr.RemoveAt(num)
    str:=""
    for i,v in arr {
        str .= v
        if (i!=arr.Length()) {
            str .= "||||"
        }
    }
    IniWrite, % str, % iniPath, Main, Accounts
    WinGetPos, x, y,,,Account Settings
    Gui, account:Destroy
    Ui.account(x,y)
}
accountSave() {
    i := StrSplit(read("accounts"), "||||").Length()
    str := ""
    Loop, % i {
        GuiControlGet, acc,, % "Account" . A_Index
        GuiControlGet, link,, % "PSLink" . A_Index
        str .= acc . ":::" . link
        if (A_Index!=i) {
            str .= "||||"
        }
    }
    IniWrite, % str, % iniPath, Main, Accounts
}
biomeSave() {
    set2:=["BiomeEnd","GlitchedID","DreamspaceID"]
    for i,v in biomes {
        GuiControlGet, temp,, %i%DropDown
        IniWrite, % temp, % iniPath, Main, %i%DropDown
    }
    for _,v in set2 {
        GuiControlGet, temp,, % v
        IniWrite, % temp, % iniPath, Main, % v
    }
}
global settings:=["URL","UserID"]
mainLoad() {
    for i,v in settings {
        GuiControl,, % v, % read(v)
    }
}
biomeLoad() {
    set2:=["BiomeEnd","GlitchedID","DreamspaceID"]
    for i,v in biomes {
        cID := i . "DropDown"
        val := read(cID)
        GuiControl, Choose, % cID, % val
    }
    for _,v in set2 {
        GuiControl,, % v, % read(v)
    }
}
mainSave() {
    global
    for i,v in settings {
        GuiControlGet, val,, %v%
        IniWrite, % val, % iniPath, Main, % v
    }
}
addClick() {
    global
    distance:=25
    offset:=68
    val := read("Clicks")
    new := val?val . "|0:0":"0:0"
    IniWrite, % new, % iniPath, Main, Clicks
    i := StrSplit(read("Clicks"), "|").Length()
    y:=(i*distance)+offset
    bY:=y-2
    Gui click:Add, Edit, y%y% x15 h20 w55 vx%i% Number
    Gui click:Add, UpDown, Range0-10000 0x80 vx1%i%
    Gui click:Add, Edit, y%y% x85 h20 w55 vy%i% Number
    Gui click:Add, UpDown, Range0-10000 0x80 vy1%i%
    GuiControl,, click:x%i%, 0
    GuiControl,, click:y%i%, 0
    Gui click:Add, Button, y%by% h24 w60 x148 vClickRemove%i% gClickRemove, % "Remove"
    Gui, click:Show, AutoSize
}
addAccount() {
    accountSave()
    i := StrSplit(read("accounts"), "||||").Length()
    new := i? read("accounts") . "||||:::" : ":::"
    IniWrite, % new, % iniPath, Main, Accounts
    WinGetPos, x,y,,,Account Settings
    Gui, account:Destroy
    ui.account(x,y)
}
; CreateFormData() by tmplinshi, AHK Topic: https://autohotkey.com/boards/viewtopic.php?t=7647
; Thanks to Coco: https://autohotkey.com/boards/viewtopic.php?p=41731#p41731
; Modified version by SKAN, 09/May/2016
; Rewritten by iseahound in September 2022

CreateFormData(ByRef retData, ByRef retHeader, objParam) {
	New CreateFormData(retData, retHeader, objParam)
}

Class CreateFormData {

    __New(ByRef retData, ByRef retHeader, objParam) {

        Local CRLF := "`r`n", i, k, v, str, pvData
        ; Create a random Boundary
        Local Boundary := this.RandomBoundary()
        Local BoundaryLine := "------------------------------" . Boundary

        ; Create an IStream backed with movable memory.
        hData := DllCall("GlobalAlloc", "uint", 0x2, "uptr", 0, "ptr")
        DllCall("ole32\CreateStreamOnHGlobal", "ptr", hData, "int", False, "ptr*", pStream:=0, "uint")
        this.pStream := pStream

        ; Loop input paramters
        For k, v in objParam
        {
            If IsObject(v) {
                For i, FileName in v
                {
                    str := BoundaryLine . CRLF
                        . "Content-Disposition: form-data; name=""" . k . """; filename=""" . FileName . """" . CRLF
                        . "Content-Type: " . this.MimeType(FileName) . CRLF . CRLF

                    this.StrPutUTF8( str )
                    this.LoadFromFile( Filename )
                    this.StrPutUTF8( CRLF )

                }
            } Else {
                str := BoundaryLine . CRLF
                    . "Content-Disposition: form-data; name=""" . k """" . CRLF . CRLF
                    . v . CRLF
                this.StrPutUTF8( str )
            }
        }

        this.StrPutUTF8( BoundaryLine . "--" . CRLF )

        this.pStream := ObjRelease(pStream) ; Should be 0.
        pData := DllCall("GlobalLock", "ptr", hData, "ptr")
        size := DllCall("GlobalSize", "ptr", pData, "uptr")

        ; Create a bytearray and copy data in to it.
        retData := ComObjArray( 0x11, size ) ; Create SAFEARRAY = VT_ARRAY|VT_UI1
        pvData  := NumGet( ComObjValue( retData ), 8 + A_PtrSize , "ptr" )
        DllCall( "RtlMoveMemory", "Ptr", pvData, "Ptr", pData, "Ptr", size )

        DllCall("GlobalUnlock", "ptr", hData)
        DllCall("GlobalFree", "Ptr", hData, "Ptr")                   ; free global memory

        retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
    }

    StrPutUTF8( str ) {
        length := StrPut(str, "UTF-8") - 1 ; remove null terminator
        VarSetCapacity(utf8, length)
        StrPut(str, &utf8, length, "UTF-8")
        DllCall("shlwapi\IStream_Write", "ptr", this.pStream, "ptr", &utf8, "uint", length, "uint")
    }

    LoadFromFile( filepath ) {
        DllCall("shlwapi\SHCreateStreamOnFileEx"
                    ,   "wstr", filepath
                    ,   "uint", 0x0             ; STGM_READ
                    ,   "uint", 0x80            ; FILE_ATTRIBUTE_NORMAL
                    ,    "int", False           ; fCreate is ignored when STGM_CREATE is set.
                    ,    "ptr", 0               ; pstmTemplate (reserved)
                    ,   "ptr*", pFileStream:=0
                    ,   "uint")
        DllCall("shlwapi\IStream_Size", "ptr", pFileStream, "uint64*", size:=0, "uint")
        DllCall("shlwapi\IStream_Copy", "ptr", pFileStream , "ptr", this.pStream, "uint", size, "uint")
        ObjRelease(pFileStream)
    }

    RandomBoundary() {
        str := "0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
        Sort, str, D| Random
        str := StrReplace(str, "|")
        Return SubStr(str, 1, 12)
    }

    MimeType(FileName) {
        n := FileOpen(FileName, "r").ReadUInt()
        Return (n        = 0x474E5089) ? "image/png"
            :  (n        = 0x38464947) ? "image/gif"
            :  (n&0xFFFF = 0x4D42    ) ? "image/bmp"
            :  (n&0xFFFF = 0xD8FF    ) ? "image/jpeg"
            :  (n&0xFFFF = 0x4949    ) ? "image/tiff"
            :  (n&0xFFFF = 0x4D4D    ) ? "image/tiff"
            :  "application/octet-stream"
    }
}
webhookPost(data := 0){
    data := data ? data : {}

    url := read("URL")
    discordID := read("UserID")

    if (!url){
        return 0
    }

    if (data.pings){
        data.content := data.content ? data.content " <@" discordID ">" : "<@" discordID ">"
    }

    data.embedColor := data.embedColor + 0

    payload_json := "
		(LTrim Join
		{
			""content"": """ data.content """,
			""embeds"": [{
                " (data.embedAuthor ? """author"": {""name"": """ data.embedAuthor """" (data.embedAuthorImage ? ",""icon_url"": """ data.embedAuthorImage """" : "") "}," : "") "
                " (data.embedTitle ? """title"": """ data.embedTitle """," : "") "
				""description"": """ data.embedContent """,
                " (data.embedThumbnail ? """thumbnail"": {""url"": """ data.embedThumbnail """}," : "") "
                " (data.embedImage ? """image"": {""url"": """ data.embedImage """}," : "") "
                " (data.embedFooter ? """footer"": {""text"": """ data.embedFooter """}," : "") "
				""color"": """ (data.embedColor ? data.embedColor : 0) """
			}]
		}
		)"

    if ((!data.embedContent && !data.embedTitle) || data.noEmbed)
        payload_json := RegExReplace(payload_json, ",.*""embeds.*}]", "")
    

    objParam := {payload_json: payload_json}

    for i,v in (data.files ? data.files : []) {
        objParam["file" i] := [v]
    }

    CreateFormData(postdata,hdr_ContentType,objParam)

    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    WebRequest.Open("POST", url, true)
    WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
    WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
    WebRequest.SetRequestHeader("Pragma", "no-cache")
    WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
    WebRequest.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
    WebRequest.Send(postdata)
    WebRequest.WaitForResponse()
}
class UI {
    main() {
        global
        Gui, main:New
        Gui Add, Text, x8 y8, % "Webhook URL"
        Gui Add, Edit, y22 h20 x12 w140 vURL gsaveMain
        Gui Add, Text, x8 y45, % "User ID"
        Gui Add, Edit, y60 h20 x12 w140 vUserID gsaveMain
        Gui Add, Button, x8 y85 w144 h25 gAccountUI, % "Account Settings"
        Gui Add, Button, x155 y8 h60 w65 gBiomeUI, % "Biome Settings"
        Gui Add, Button, x155 y75 h60 w65 gClickUI, % "Click Settings"
        Gui Add, Button, x8 y113 h22 w70 gStart, % "F1 - Start"
        Gui Add, Button, x82 y113 h22 w70 gStop, % "F2 - Stop"
        Gui Font, s6
        Gui Add, Text, x11 y138, % "made by @b0red_man"
        Gui, Show
        mainLoad()
    }
    click(wx, wy) {
        global
        distance:=25
        offset:=88
        Gui, click:New
        Gui Add, Text, x8 y8, % "This is so your accounts don't disconnect."
        Gui Add, Button, x8 y23 h25 w100 gaddClick, % "Add Click"
        Gui Add, Button, x112 y23 h25 w100 gHighlightClicks, % "Highlight Clicks"
        Gui Add, Button, x8 y50 h23 w100 gClickGetPos, % "Get Mouse Pos"
        Gui Add, Button, x112 y50 h23 w100 gClickSave, % "Save Entries"
        Gui Add, Text, x40 y95, % "X"
        Gui Add, Text, x108 y95, % "Y"
        Gui Add, Checkbox, x11 y80 vClickEnable, % "Enable Clicks"
        GuiControl,, clickEnable, % read("ClickEnabled")
        arr := StrSplit(read("Clicks"), "|")
        for i,v in arr {
            y:=(i*distance)+offset
            bY:=y-2
            pos:=StrSplit(v, ":")
            Gui Add, Edit, y%y% x15 h20 w55 vx%i% Number
            Gui Add, UpDown, Range0-10000 0x80 vxU%i%
            Gui Add, Edit, y%y% x85 h20 w55 vy%i% Number
            Gui Add, UpDown, Range0-10000 0x80 vyU%i%
            GuiControl,, x%i%, % pos[1]
            GuiControl,, y%i%, % pos[2]
            Gui Add, Button, y%by% h24 w60 x148 vClickRemove%i% gClickRemove, % "Remove"
        }
        Gui, Show, x%wx% y%wy%, Click Manager
    }
    biome() {
        global
        distance:=25
        offset:=150
        Gui, biome:new
        Gui Add, Checkbox, x8 y8 vBiomeEnd, % "Biome End Messages"
        Gui Add, Text, x8, % "Glitch Ping ID:"
        Gui Add, Edit, x12 h20 y42 vGlitchedID
        Gui Add, Text, x8, % "Dreamspace Ping ID:"
        Gui Add, Edit, x12 h20 y82 vDreamspaceID
        Gui Add, Text, x8, % "* if blank, userid will be used"
        Gui Add, Button, x8 y125 h20 w140 gBiomeSave, % "Save Settings"
        for i,v in biomes {
            y:=((A_Index-1)*distance) + offset
            StringLower, name, % i, T
            Gui Add, Text, x8 y%y%, % name ": "
            ddY:=y-3
            Gui Add, DropDownList, x90 y%ddY% w60 v%i%DropDown, None|Msg|Ping
        }
        Gui Show
        biomeLoad()
    }
    account(ux,uy) {
        global
        distance:=25
        offset:=30
        Gui, account:new
        Gui Add, button, x8 y8 h24 w100 gAccountAdd, % "Add Account"
        Gui Add, button, x112 y8 h24 w100 gAccountSave, % "Save"
        Gui Add, Text, x30 y35, % "Username"
        Gui Add, Text, x170 y35, % "PS Link"
        arr := StrSplit(read("Accounts"), "||||")
        for i,v in arr {
            if (v) {
                y := (i*distance)+offset
                sub := StrSplit(v, ":::")
                Gui Add, Edit, x15 h20 w80 y%y% vAccount%i%, % sub[1]
                Gui Add, Edit, x110 h20 w160 y%y% vPSLink%i%, % sub[2]
                Gui Add, Button, h20 y%y% w70 x275 vAccountRemove%i% gAccountRemove, % "Remove"
            }
        }
        Gui, Show, x%ux% y%uy%, % "Account Settings"
    }
}
highlightClicks() {
    clickSave()
    arr := StrSplit(read("Clicks"), "|")
    for i,v in arr {
        pos:=StrSplit(v, ":")
        ToolTip, % i, % pos[1], % pos[2], % i
        SetTimer, RemoveToolTip, -7500
    }
}
runClicks() {
    if (read("ClickEnabled")) {
        arr := StrSplit(read("Clicks"), "|")
        for i,v in arr {
            subArr := StrSplit(v, ":")
            sleep, 100
            MouseMove, % subArr[1], % subArr[2]
            Sleep, 100
            Loop, 3 {
                Click
            }
        }
    }
}
class FileSorter {
    SortFiles(folderPath) {
        files := this.LoadFiles(folderPath)
        if (files.MaxIndex() > 0) {
            this.BubbleSort(files)
        }
        return files  ; Return the sorted array
    }

    LoadFiles(folderPath) {
        fileList := []  ; Create a new array for files
        Loop, %folderPath%\*.log, 0, 0  ; Only search for .log files
        {
            fileName := A_LoopFileName
            if (SubStr(fileName, -7, 4) = "last" && InStr(fileName, "player") && A_Now-A_LoopFileTimeModified<=10000000)  ; Filtering criteria
            {
                fileList.Push({Name: fileName, Path: A_LoopFileFullPath, ModTime: A_LoopFileTimeModified})
            }
        }
        return fileList
    }

    BubbleSort(ByRef files) {
        n := files.MaxIndex()
        ; Outer loop to traverse each file
        Loop, % n {
            ; Inner loop to compare each file with the next
            Loop, % n - A_Index {
                i := A_Index
                j := A_Index + 1
                if (files[i].ModTime < files[j].ModTime) {  ; Sort newest first
                    this.Swap(files, i, j)
                }
            }
        }
    }

    Swap(ByRef files, i, j) {
        temp := files[i]
        files[i] := files[j]
        files[j] := temp
    }
}
start() {
    if (!started) {
        updateLogs()
        FormatTime, t,, HH:mm:ss
        webhookPost({embedTitle:"Macro Started", embedFooter:t, embedColor:0x273586})
        SetTimer, biomeTick, 500
        SetTimer, updateLogs, 60000
        SetTimer, runClicks, 3000
    }
    started:=1
}
stop() {
    if(started) {
        FormatTime, t,, HH:mm:ss
        webhookPost({embedTitle:"Macro Stopped", embedFooter:t, embedColor:0x273586})
        SetTimer, biomeTick, Off
        SetTimer, updateLogs, Off
        SetTimer, runClicks, Off
    }
    started:=0
}
UI.main()
Return
ClickUI:
    ui.click(A_ScreenWidth/2, A_ScreenHeight/2)
Return
BiomeUI:
    ui.biome()
Return
accountUI:
    ui.account(A_ScreenWidth/2, A_ScreenHeight/2)
Return
highlightClicks:
    highlightClicks()
Return
RemoveToolTip:
    Loop 20 {
        ToolTip, , , , % A_Index
    }
return
AddClick:
    addClick()
Return
AccountAdd:
    addAccount()
Return
clickGuiClose:
    clickSave()
    Gui, click:Destroy
Return
biomeGuiClose:
    biomeSave()
    Gui, biome:Destroy
Return
accountGUiClose:
    accountSave()
    Gui, account:destroy
Return
mainGuiClose:
    mainSave()
    ExitApp
Return
saveMain:
    mainSave()
Return
clickSave:
    clickSave()
Return
biomeSave:
    biomeSave()
Return
accountSave:
    accountSave()
Return
ClickRemove:
    removeClick(A_GuiControl)
Return
AccountRemove:
    accountRemove(A_GuiControl)
Return
ClickGetPos:
    MsgBox % "After Clicking 'OK', right click where you want to get the position"
    KeyWait, RButton, D
    MouseGetPos, x, y
    MsgBox % "X: " x ", Y: " y
Return
biomeTick:
    biomeTick()
Return
updateLogs:
    updateLogs()
Return
runClicks:
    runClicks()
Return
start:
    start()
Return
stop:
    stop()
F1::Goto, start
F2::Goto, stop