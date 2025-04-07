#Requires AutoHotkey v1.1
#NoEnv
#MaxMem, 1024 ; this is a bit dangerous, fuck it
#SingleInstance, off
global sortedFiles := []
global iniPath := A_ScriptDir "\config.ini"
global oldbiome = ""
global logPath := "C:\Users\" A_UserName "\AppData\Local\Roblox\logs"
global biomes:={"WINDY":0x9ae5ff,"RAINY":0x027cbd,"SNOWY":0xDceff9,"SANDSTORM":0x8F7057,"HELL":0xff4719,"STARFALL":0x011ab7,"CORRUPTION":0x6d32a8,"NULL":0x838383,"GLITCHED":0xbfff00,"DREAMSPACE":0xea9dda}
/*
args[1] = Account
args[2] = PSLink
args[3] = Alt. Webhook
*/
global args := StrSplit(A_Args[1], ":::")
win() { ; makes a unique window title to use with main.ahk
    name := "thread0xF" . args[1]
    Gui, main:new
    Gui, -Caption +Owner
    Gui, Show, x1 y%A_ScreenHeight% h1 w1, % name
}
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
getWebhookfromUser(user) {
    return args[3]?args[3]:read("URL")
}
sendBiomeMsg(biome,start,account) {
    if (biome) {
        link := args[2]
        con := link?"-# **PS Link:** " . link:"**No Link Provided**"
        ddV := read(biome . "dropdown")
        FormatTime, t,, HH:mm:ss
        footer := t . ", Account: " . account
        color := biomes[biome]
        url := getWebhookfromUser(account)
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
                webhookPost({content: con, embedTitle: title, embedColor: color, embedFooter: footer},url)
            } else {
                if (biome) {
                    title := "Biome Ended | " . biome
                    webhookPost({embedTitle: title, embedColor: color, embedFooter: footer},url)
                }
            }
        }
    }
}
class detect {
    getRPCMsg(filePath) {
        FileRead, file, % filePath
        ;VarSetCapacity(msg, 2147483648) gives msg max 2gb ram (doesnt actually use 2gb)
        msg :=  SubStr(file, InStr(file, "[BloxstrapRPC]",1000, 0))
        msg := SubStr(msg, 1, InStr(msg, "}}}",, 0)+2)
        return msg
    }
    getBiome(msg) {
        str = ","
        biome := SubStr(msg, InStr(msg, "largeImage")+26)
        return StrReplace(SubStr(biome, 1,InStr(biome,str)-1),A_Space)
    }
}
biomeTick() {
    ; msgbox % "old biome: " oldBiome
    acc := args[1]
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
    oldBiome := biome
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
webhookPost(data := 0, url := 0){ ; from dolphsol
    data := data ? data : {}
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
    try {
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
}
read(option) {
    IniRead, out, % iniPath, Main, % option
    return out
}
win()
updateLogs()
SetTimer, biomeTick, 250
SetTimer, updateLogs, 180000
Return
updateLogs:
    updateLogs()
biomeTick:
    biomeTick()
